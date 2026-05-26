# 094 — hook-chain-latency — plan

_Drafted from `spec.md` on 2026-05-26. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Three-phase plan: **measure first**, intervene with cheap low-risk wins informed by the baseline, validate with a regression bench. Defer the high-cost interventions (orchestrator consolidation, language port) until measurement proves the cheap interventions are insufficient. This shape reflects the spec's discipline: artifact size is not a scope/quality signal, baselines are.

**Phase 1 — Measure (no behavioral change).** Ship `.claude/tools/bench-hooks.sh` that runs each of the four `PreToolUse(Bash)` hooks in isolation + the full chain against a representative command set (no-op `:`, `ls`, `cat`, `echo`, `git status`, `git log -1`, `git commit -m '…'`, `npm install --dry-run`). N=100 reps per (hook × command) cell. Compute per-hook and per-command-class p50/p95. Emit human-readable + JSON output. Commit the captured baseline to `.claude/.perf-baseline.json` with harness configuration + git SHA + OS recorded. Also instrument **the next real session** (post-baseline) for ~1 hour to capture the actual command-shape distribution — the bench's synthetic set may not match the hot path the user actually triggers. Compare the two distributions; if they diverge sharply, re-weight the bench set.

**Phase 2 — Intervene (data-driven).** Based on Phase 1's per-hook cost decomposition, apply the cheapest interventions that move the fast-path p95 toward the budget. Two candidate moves, ordered by expected ROI from cheapest to most-disruptive:

1. **Tighten `matcher` fields in `.claude/settings.json` where Claude Code's harness allows** — if the harness supports payload-shape matchers (e.g. `Bash:*npm install*`-style narrowing), some hooks (`supply-chain-scan` → dep-install shapes; `secrets-scan` → `git commit` shapes) never fire at all on irrelevant commands. Phase 1's first sub-task is to verify what the matcher syntax actually accepts; the plan does NOT assume support without research. If matchers only filter on tool name (`Bash` vs `Edit`), intervention (1) is a no-op and Phase 2 skips to (2).
2. **Sharpen the existing short-circuit paths inside each hook** — all four hooks already follow `cat → jq → CMD → pattern-match → decide`. The dominant cost is the `jq` parse (one process per hook per call). Options to attack jq:
   - **(2a) Use the cheapest possible probe before jq** — fixed-prefix `grep` or `case` against the raw stdin to short-circuit on known-safe command shapes (e.g. `ls`, `cat`, `git status`, `echo`, etc.) before running `jq`. The fast path skips jq entirely; the slow path falls through to the existing jq-based logic. Per-hook cost reduction roughly proportional to fraction of fast-path commands × (jq parse cost + script logic). Bash-only; portable to all forks.
   - **(2b) Consolidate the four hooks into a single orchestrator** — pay one jq parse, dispatch in-process to four bash functions. This is intervention (b) from spec OQ2. Eliminates 3× the subprocess spawn + jq parse cost outright. Bigger refactor: settings.json wiring change; one file with four concerns; harder to extend; sync-harness merge becomes denser. Pay this cost only if (2a) + (1) don't hit budget.

**Phase 3 — Validate + regress.** Re-run `bench-hooks.sh`, compare against the new baseline, commit. Add `.claude/tests/hook-chain-latency/run-all.sh` that re-runs the bench in `--check` mode against the committed baseline and fails CI if any tracked p95 regresses by more than the budget tolerance (proposal: 25%). Document the discipline in a new short rule `.claude/rules/hook-chain-latency.md` (or a section in `runtime-introspect.md` — TBD in Phase 3 based on size). Any new `PreToolUse(Bash)` hook added to the project must be benchmarked + budgeted before merge.

**Deferred / out of v1:**

- **Language port (intervention (c) — bash → Go/Rust/Python binary).** Skipped entirely. Build step + deploy artifact + maintenance surface are large costs to pay before proving bash short-circuit isn't the answer. If Phase 3 leaves us still above budget, a separate spec scopes the port.
- **PostToolUse / Edit-chain optimization.** Per spec non-goals — different chain, different latency profile, not user-perceptible the same way. If a separate complaint surfaces, scaffold a sibling spec.
- **Orchestrator consolidation (2b) preempting (2a).** Only done if (2a) + (1) don't hit budget. The plan re-evaluates at the end of Phase 2a.

### Target budget proposal

**p95 ≤ 80 ms for fast-path Bash commands** (no-op, `ls`, `cat`, `git status`, `git log`, `echo`, `grep`). That's ~3× improvement over the ~250 ms perceived baseline. Achievable with (2a) + (1) per back-of-envelope: jq parse + bash subprocess spawn together cost ~25-35 ms per hook; eliminating 3 of 4 hook invocations via matcher narrowing (1) yields ~60-100 ms of saving; (2a) trims the remaining hook to ~15 ms via pre-jq probe. Defensible against the spec's acknowledgement that Claude Code harness IPC is out of our hands.

Budget is a Phase 2 proposal, NOT a Phase 1 commitment. If Phase 1 measurement shows the IPC overhead alone is >80 ms, the budget moves to ≤120 ms with explicit reasoning in the rule doc. The numbers ride on data, not aspiration.

## Files to touch

**Create:**

- `.claude/tools/bench-hooks.sh` — benchmark runner. CLI shape: `bench-hooks.sh [--baseline | --check] [--reps N] [--commands "<cmd1>,<cmd2>,...">]`. Default reps=100; default commands = the representative set from spec Scenario 1. Output: human-readable table to stdout + JSON to stderr (or vice-versa, TBD in implementation). Modes: `--baseline` writes results to `.claude/.perf-baseline.json`; `--check` reads the baseline, re-runs, fails non-zero if any tracked p95 exceeds baseline + tolerance.
- `.claude/.perf-baseline.json` — committed baseline. Shape: `{ git_sha, harness_version, os, ts, cells: { "<hook>": { "<command-class>": { p50_ms, p95_ms, n } } } }`. The shape is documented in the new rule.
- `.claude/rules/hook-chain-latency.md` — documents the budget, the bench tool, the tolerance, the new-hook discipline (any new `PreToolUse(Bash)` hook MUST run through `bench-hooks.sh --check` before merge). Cross-references `runtime-introspect.md` (sibling perf-observability rule).
- `.claude/tests/hook-chain-latency/run-all.sh` — regression runner; invokes `bench-hooks.sh --check`. Wired into the broader project test set via a follow-up commit (or via documentation only, depending on the test discipline shape).

**Modify (conditionally, based on Phase 1 results):**

- `.claude/settings.json` — tighten `matcher` patterns for Bash hooks IF the harness supports payload-shape matching. Likely candidates: `supply-chain-scan` matcher → dep-install command shapes; `secrets-scan` matcher → `git commit` shapes. Phase 1 verifies feasibility before any edit lands.
- `.claude/hooks/governance-gate.sh` (95 LOC) — add a pre-jq grep/case probe; the override-marker check is the natural fast-path identifier (no `# OVERRIDE:` AND command starts with a known-benign prefix → exit 0 without jq parse).
- `.claude/hooks/secrets-scan.sh` (387 LOC) — already short-circuits on non-`git commit` after the jq parse (line ~30, `skip-not-commit` decision); push the short-circuit BEFORE jq via raw-stdin pattern probe (`grep -q 'git commit' <<< "$INPUT"` or equivalent).
- `.claude/hooks/supply-chain-scan.sh` (458 LOC) — same pattern: raw-stdin probe for any of the 11 manager keywords (`npm`, `pnpm`, `yarn`, `bun`, `pip`, `uv`, `poetry`, `pdm`, `cargo`, `go`, plus `composer` if added later) before jq. Most calls (95%+ in real workloads) don't touch these.
- `.claude/hooks/runtime-pre-mark.sh` (48 LOC) — already minimal; verify Phase 1 shows it's not a hot spot. May not need touching.

**Delete:** nothing.

## Alternatives considered

### Skip the measure phase; ship intervention (2a) blindly

Rejected. Optimization without baseline data risks targeting the wrong thing — e.g. spending effort on supply-chain when governance-gate is actually the dominant cost, or vice-versa. The bench script is a small upfront investment (~50-100 LOC of bash) that informs every subsequent decision AND becomes the regression alarm for free. Skipping measurement also makes the spec's "regression alarm exists" acceptance criterion impossible to satisfy honestly.

### Replace bash with a Go/Rust binary as the v1 intervention (intervention c)

Rejected as v1 default. The perf headroom of bash short-circuit + matcher narrowing is unmeasured; jumping straight to a binary pre-commits to a build step, a deploy artifact (versioned binary in the repo or in CI), and a maintenance surface (cross-platform compilation, supply-chain on the binary itself). All real costs paid before proving bash is the floor. The deferral is conditional, not categorical — if Phase 3 numbers stay above budget, a separate spec scopes the port with concrete baseline-vs-port comparison data driving the decision.

### Consolidate all four hooks into one orchestrator as the v1 intervention (intervention b)

Rejected as v1 default for the same reason: it's the biggest single refactor in the candidate set and has not earned the cost. Bigger surface change (settings.json wiring, sync-harness merge implications, one file with four concerns), harder to roll back. Held as a Phase 2b fallback if (1) + (2a) don't move p95 enough. The discipline is: prove the cheap intervention is insufficient before paying for the expensive one.

### Set Claude Code permission mode to bypass and ignore the hook cost

Rejected (and orthogonal to this spec). Permission mode bypass affects permission prompts, not hook chain execution. Already addressed by spec 094-pre (`chore(harness-sync): drop permission-mode bypass from upstream settings`).

### Optimize the native `.githooks/pre-commit` (gitleaks)

Rejected per spec non-goal. Empirical measurement (2026-05-26 diagnostic) puts gitleaks at ~33 ms — not the bottleneck. The cost lives in the Claude Code harness preflight chain, not the native git hook.

### Build a routine to bench on schedule rather than a one-shot baseline

Deferred to a follow-up. A monthly `/routine` re-running `bench-hooks.sh --check` would catch drift over time (Claude Code harness updates, dependency drift, etc.). Not v1 — the spec's regression alarm requirement is satisfied by the on-demand `--check` mode; the routine is the cadence layer on top, scaffold-able as a 20-line `.claude/routines/hook-chain-bench.md` once v1 ships and proves the bench is stable.

## Risks and unknowns

- **Claude Code matcher syntax may not support payload-shape matching.** The plan's intervention (1) — tightening `.claude/settings.json` matchers — depends on the harness accepting patterns more specific than tool-name (e.g. `Bash:*git commit*`). Phase 1 must verify this before any edit lands; if the harness only filters on tool name, (1) is a no-op and Phase 2 collapses to (2a). Mitigation: research-before-proposing via Claude Code docs or empirical probe during Phase 1.
- **Pre-jq stdin probe is fragile against JSON-escaped payloads.** A command containing JSON-escape sequences (e.g. `bash -c "echo \"foo\""`) breaks naive `grep` extraction. Mitigation: design the probe to be a sufficient-but-not-necessary fast-path — when the probe matches a known-safe shape, exit 0; otherwise fall through to the existing jq path. False negatives (probe misses a safe command, jq handles it) are fine; false positives (probe exits 0 on a command the gate should have inspected) are unacceptable.
- **Phase 1's synthetic command set may not match real hot-path distribution.** A 50/50 split between `ls` and `git status` isn't what real sessions look like; if the bench reports great fast-path numbers but real workloads spend 80% of Bash calls on `git commit`-shapes (which all hit slow paths), the optimization wins are illusory. Mitigation: capture real distribution via 1-hour instrumented session (Phase 1 sub-task) and re-weight the bench set if synthetic ≠ real.
- **WSL2 fork+exec overhead may dominate the entire intervention budget.** This project's primary dev environment is WSL2 (Linux 6.6.114.1-microsoft-standard-WSL2 per the session env). WSL2 imposes ~3-5 ms extra per `fork+exec` vs native Linux. If 4 hooks × WSL2 spawn = ~30 ms floor, intervention (2a) wins are capped. Mitigation: document the bench machine + OS in the baseline JSON; ship the rule with a note that the budget assumes WSL2; native-Linux forks may hit budgets easier.
- **The bench script's own overhead may dominate hook cost on a noop.** A hook running in 5 ms measured by a bench script that imposes 50 ms framing per run is unmeasurable. Mitigation: bench script uses `time` (built-in) or `python -c "import time; ..."` for sub-ms timing, takes the median of N=100 runs, subtracts a no-hook baseline (run the chain with empty hooks to characterize harness IPC alone), reports deltas.
- **Tighter matchers (intervention 1) may break gate coverage for command shapes the matcher doesn't catch.** Example: `supply-chain-scan` matcher narrowed to `*(npm|pnpm|...)\s+(install|add)*` would miss `bash -c "npm install"` because the outer tool name is `Bash`, command starts with `bash`. Mitigation: every matcher change must be paired with a non-regression test in the gate's existing test suite (`.claude/tests/secrets-scan/`, `.claude/tests/supply-chain/`) covering edge cases.
- **Pre-Bash chain optimization may compound with PostToolUse cost the spec explicitly defers.** If Phase 2 reduces PreToolUse to 30 ms but PostToolUse stays at 200 ms, the user-perceived improvement is muted because the agent waits for both. The spec non-goal says PostToolUse is invisible to perceived responsiveness — true for the NEXT prompt readiness, but each Bash call's full round-trip includes both. Document the asymmetry in the rule; if the user complains post-shipping, that's the trigger for a sibling spec.
- **The "next real session" instrumentation in Phase 1 may capture an unrepresentative window.** A session dominated by `/sdd plan` writing markdown spends most time in Edit, not Bash — won't surface Bash hook cost. Mitigation: capture 2-3 sessions of mixed workload; report distribution variance, not single-session means.

## Research / citations

- `docs/specs/094-hook-chain-latency/spec.md` § Intent + § Acceptance criteria + § Open questions — drives the 3-phase structure, the 80 ms proposed budget, the intervention candidate set.
- `.claude/settings.json` lines 30-94 — current `PreToolUse(Bash)` chain registration; 4 hooks fire sequentially.
- `.claude/hooks/governance-gate.sh` (95 LOC), `.claude/hooks/secrets-scan.sh` (387 LOC), `.claude/hooks/supply-chain-scan.sh` (458 LOC), `.claude/hooks/runtime-pre-mark.sh` (48 LOC) — current implementations; the `INPUT=cat → CMD=jq` pattern is identical across all four, suggesting consolidation (2b) is mechanically straightforward if needed.
- `.claude/rules/secrets-scan.md`, `.claude/rules/supply-chain.md`, `.claude/rules/delegation.md`, `.claude/rules/runtime-introspect.md` — gate behavior contracts the optimization must preserve; the new rule cross-references these.
- `.claude/tests/secrets-scan/`, `.claude/tests/supply-chain/`, `.claude/tests/runtime-introspect/` — existing non-regression suites that must stay green after Phase 2.
- Empirical diagnostic (this session, 2026-05-26) — per-hook timing measurements (governance-gate ~unknown, secrets-scan ~44 ms, supply-chain-scan ~48 ms, propagation-advise ~20 ms reference); gitleaks scan internal 12.9 ms / wall 33 ms; perceived 150-300 ms per Bash call.
- Claude Code hook documentation (TBD — verify in Phase 1 what `matcher` field syntax accepts; the project's existing matchers are tool-name-only (`Bash`, `Edit|Write|MultiEdit`, `Agent`), so payload-shape matching is unverified).
- `.claude/rules/runtime-introspect.md` — sibling perf-observability rule; the new `hook-chain-latency.md` rule should reference it for the broader project posture on runtime measurement.
