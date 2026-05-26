# Hook chain latency

Optimization + regression discipline for the `PreToolUse(Bash)` hook chain. The chain is on the critical path of every Bash tool call the agent makes; cost there is user-perceived as "slow agent". This rule documents the budget, the bench tool that measures against it, and the discipline any new `PreToolUse(Bash)` hook must follow before merge.

The capacity ships in v1 as a baseline + check tool, not as a CI gate. The intent is "any contributor adding a Bash preflight runs the bench and adds their cell to the baseline, or has a documented reason not to" — not "CI fails the PR until …". Promotion to a CI gate is a follow-up if the optional discipline turns out to drift.

## Scope

In-scope:

- `PreToolUse(Bash)` hooks registered in `.claude/settings.json` — `governance-gate.sh`, `secrets-scan.sh`, `supply-chain-scan.sh`, `runtime-pre-mark.sh` at time of writing.
- The full chain's wall-clock p95 against a representative command set.
- Pre-jq raw-stdin fast-path probes inside hooks; `if`-field matcher narrowing in `settings.json`.

Out-of-scope (see the hook-chain-latency spec non-goals):

- `PostToolUse` / `PostToolUseFailure` hooks. Different chain, different perf profile, no user-perceptible-on-next-prompt cost.
- The native `.githooks/pre-commit` (gitleaks). Empirically ~33 ms; not the bottleneck.
- Claude Code's harness IPC. Out of our hands.
- `Edit|Write|MultiEdit` hook chain. If it surfaces as slow, scope a separate spec.

## Budget

**p95 ≤ 80 ms for fast-path Bash commands** (no-op, `ls`, `cat`, `echo`, `git status`, `git log`, `grep`).

Fast-path is defined as: a Bash command none of the four gates have a real reason to scrutinize. Under the current `if`-field narrowing (see § Optimization techniques below), `secrets-scan.sh` doesn't spawn unless the command shape contains `git commit`, and `supply-chain-scan.sh` doesn't spawn unless the shape contains a package-manager keyword. The chain on a true fast-path command therefore reduces to:

```
IPC floor (bash spawn + stdin pipe)   ~13 ms p95 on WSL2
+ governance-gate.sh fast-path        ~20 ms p95
+ runtime-pre-mark.sh fast-path       ~38 ms p95
= ~70 ms p95 chain on fast-path
```

Slow-path commands (those a gate exists to inspect — `git commit`, `npm install`, etc.) are NOT bounded by this budget. The gate runs its full logic — pattern matching, audit-row writing, override-marker parsing. Those costs are paid in service of the gate's contract.

The 80 ms target is empirical, not aspirational. It corresponds to ~3× improvement over the 2026-05-26 baseline (governance-gate 62 ms + secrets-scan 68 ms + supply-chain-scan 73 ms + runtime-pre-mark 35 ms = ~238 ms uncoordinated chain).

If a future Claude Code release lifts the WSL2 IPC floor or the harness changes its `if`-field semantics, the budget moves with concrete reasoning recorded in this section. Don't lower the budget unless measurement on the current floor proves room exists; don't raise it without measurement either.

## Bench tool

`.claude/tools/bench-hooks.sh` measures per-hook p50/p95 against a representative command set. Three modes:

```bash
# Capture / re-capture baseline. Writes .claude/.perf-baseline.json.
bash .claude/tools/bench-hooks.sh --baseline [--reps N]

# Check current hooks against committed baseline. Exits 2 on regression
# beyond tolerance (default 25%; override with --tolerance PCT or
# CLAUDE_HOOK_CHAIN_TOLERANCE_PCT env var).
bash .claude/tools/bench-hooks.sh --check [--reps N] [--tolerance PCT]

# Pure run — print results to stdout/stderr, no file IO. For ad-hoc inspection
# between optimization attempts.
bash .claude/tools/bench-hooks.sh [--reps N]
```

Default `--reps` is 100. The bench redirects `CLAUDE_PROJECT_DIR` to a per-run tmpdir so the hooks' own audit-log writes (`secrets-audit.jsonl`, `supply-chain-audit.jsonl`, `runtime-state/in-flight/`) never pollute the real project tree. Tmpdir is cleaned at exit.

Timing uses bash 5+'s `$EPOCHREALTIME` (microsecond precision built-in, no external timing tool). The bench requires bash 5+ and jq; it aborts with a clear error otherwise.

The bench invokes each hook directly with a synthetic stdin payload — bypassing Claude Code's harness, so the `if`-field narrowing isn't applied during the measurement. This is by design: the bench measures **intrinsic per-hook cost**, while the `if`-field benefit is a runtime characteristic that varies by command-shape distribution. The regression check catches drift in intrinsic cost; the runtime distribution drives the production p95.

## Baseline JSON shape

`.claude/.perf-baseline.json` is committed at the project root level (under `.claude/`). Shape:

```json
{
  "git_sha": "abc1234",
  "harness_version": "unknown",
  "os": "Linux 6.6.114.1-microsoft-standard-WSL2",
  "ts": "2026-05-26T20:55:14Z",
  "reps": 100,
  "cells": {
    "noop": {
      "noop": { "p50_ms": 9.0, "p95_ms": 13.5, "n": 100 },
      "ls":   { "p50_ms": 9.6, "p95_ms": 14.0, "n": 100 },
      "...":  { "..." : "..." }
    },
    "governance-gate.sh": { "...": "..." },
    "secrets-scan.sh":    { "...": "..." },
    "supply-chain-scan.sh": { "...": "..." },
    "runtime-pre-mark.sh":  { "...": "..." }
  }
}
```

`cells` is a 2-level object: outer key is the hook filename (or `"noop"` for the harness-IPC floor), inner key is the command label from the default command set. Each leaf is `{p50_ms, p95_ms, n}`. The schema is deliberately stable — `--check` reads `.cells[hook][cmd].p95_ms` directly; adding new cells is additive (existing entries unaffected); removing a cell that the current bench expects is a `null` and skipped on check.

`git_sha` is informational — the baseline corresponds to that commit's hooks. When hooks change in a PR, the baseline is expected to be re-captured in the same PR; the `--check` test catches the case where someone changed a hook and forgot.

## Optimization techniques

Three techniques applied in v1 (the hook-chain-latency spec implementation, 2026-05-26):

### 1. `if`-field matcher narrowing in `.claude/settings.json`

For hooks that only need to inspect a subset of Bash commands, use the per-handler `if` field with permission-rule syntax. Quoted from Claude Code docs:

> "The `if` condition `Bash(rm *)` matches because `rm -rf /tmp/build` is a subcommand matching `rm *`, so this handler spawns. If the command had been `npm test`, the `if` check would fail and `block-rm.sh` would never run, avoiding the process spawn overhead."

Applied to:

- `secrets-scan.sh` — narrows to `Bash(git commit *|git commit|*git commit *|*git commit)`. The hook itself short-circuits on non-`git commit` after `jq` parse anyway, but matcher-narrowing prevents the spawn outright — a free ~70 ms saving per non-commit Bash call.
- `supply-chain-scan.sh` — narrows to `Bash(npm *|pnpm *|yarn *|bun *|pip *|uv *|poetry *|pdm *|cargo *|go *|composer *)`. Same logic.

Not applied to:

- `governance-gate.sh` — destructive patterns can appear anywhere; can't narrow safely.
- `runtime-pre-mark.sh` — must run on every Bash to stamp the `started_at` timestamp.

### 2. Pre-jq raw-stdin probe (governance-gate.sh)

Before paying for `jq` parse, grep the raw JSON stdin for any keyword that could possibly trigger a block:

```bash
if ! printf '%s' "$INPUT" \
    | grep -qE 'rm[[:space:]]+-|--force|--no-verify|--hard|add[[:space:]]+...'; then
  exit 0
fi
```

The probe is **sufficient-but-not-necessary**: a probe-miss is a guaranteed no-block, so exit 0 is safe; a probe-hit (false positive) falls through to the existing full-regex path under `jq`, which makes the real decision. False negatives (a real block pattern with no keyword in the raw JSON) are impossible by construction — the keyword set IS the set of fragments any matching regex contains.

Reduction: governance-gate.sh noop p95 from ~62 ms → ~20 ms (-68%).

### 3. sed instead of jq for single-field extraction (runtime-pre-mark.sh)

Where a hook only needs one JSON field (`tool_use_id` for runtime-pre-mark), `sed` extraction is faster than a `jq -r` spawn:

```bash
TOOL_USE_ID="$(printf '%s' "$INPUT" \
  | sed -n 's/.*"tool_use_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1)"
```

JSON is key-order-independent and this regex finds the key wherever it appears. The hook falls back to `jq` if `sed` fails (defensive — fail-open posture is preserved).

Reduction: runtime-pre-mark.sh noop p95 from ~35 ms → ~26 ms (-24%).

## Adding a new PreToolUse(Bash) hook

The contract for any new `PreToolUse(Bash)` hook contributed to this project:

1. **Benchmark before merge.** `bash .claude/tools/bench-hooks.sh --baseline` to add the new hook's cells. Verify p95 against the budget on the default command set.
2. **Narrow with `if` if possible.** If the hook only inspects a subset of commands (anything narrower than "every Bash invocation"), declare an `if:` field on the hook handler in `.claude/settings.json`. Use permission-rule syntax: `Bash(<glob>|<glob>|...)`. Add a comment in `settings.json` near the new entry explaining why the pattern is sufficient.
3. **Pre-jq probe inside the hook body** for any hook that can't narrow at the matcher layer. Cheapest possible check first (grep against raw stdin), full logic only on probe-hit.
4. **Commit the updated baseline.** The PR adding the hook must also update `.claude/.perf-baseline.json` so the regression check stays calibrated.
5. **Avoid audit-row writes on the fast-path.** A `skip-*` audit row that fires on every Bash call adds ~5-10 ms (jq spawn × 2 for serialization + file write) — a real cost. Document the row's forensic value in the hook's rule before keeping it.

## Regression check

The dedicated test suite `.claude/tests/hook-chain-latency/` carries three scenarios:

- `01-baseline-exists.sh` — `.claude/.perf-baseline.json` parses and has expected fields/cells.
- `02-bench-check-passes.sh` — `bench-hooks.sh --check` exits 0 against the current hooks. A loose tolerance (50%) absorbs sample noise at the test's small N.
- `03-regression-fires.sh` — inject a 100 ms `sleep` into governance-gate.sh, run `--check` against the slow tree, expect exit non-zero with stderr naming the offending cell. Confirms the alarm fires.

Run via `bash .claude/tests/hook-chain-latency/run-all.sh`.

The check is not wired into a `pre-commit` hook or routine in v1. The intent is opt-in: a contributor changing a hook runs `--check` manually or adds the run-all invocation to their PR-merge ritual. Promotion to a routine (`.claude/routines/hook-chain-bench.md`) is a candidate follow-up if drift surfaces unprompted.

## Cross-references

- `.claude/rules/runtime-introspect.md` — sibling perf-observability rule; the runtime-pre-mark.sh hook this rule optimizes is owned by that capacity.
- `.claude/rules/secrets-scan.md` — secrets-scan.sh contract; the `if`-field narrowing here preserves it exactly because the hook body is unchanged.
- `.claude/rules/supply-chain.md` — supply-chain-scan.sh contract; same.
- `.claude/rules/delegation.md` — governance-gate.sh sits in the broader delegation/governance family; the pre-jq probe in governance-gate.sh is invisible to the gate's external contract.

## Gotchas

- **Sample noise is real.** Even at `--reps 100`, p95 measurements vary by ±5-10 ms run-to-run on WSL2 (Linux scheduler quanta, filesystem cache warmth, system load). The default `--tolerance 25%` is calibrated to absorb noise at typical N; lowering it requires raising N.
- **The bench measures intrinsic per-hook cost, not production chain p95.** `if`-field narrowing means hooks don't spawn on irrelevant commands in production; the bench always runs every hook. Production p95 will be lower than the bench's chain sum (because narrowing cuts the chain) — the gap is the optimization's actual value.
- **WSL2 fork+exec overhead is the floor.** Each `bash <hook>` subprocess pays ~3-5 ms more on WSL2 than on native Linux. The IPC noop cell quantifies this. Native-Linux forks of Agent0 will hit the budget more easily; the rule's 80 ms target assumes the WSL2 floor.
- **`if` field "always runs when the command is too complex to parse".** From the docs: the harness can't always parse `bash -c "..."` or other meta-shell shapes, and falls open by running the hook. This is the right semantic — false positives on complex shapes are safer than missed inspections — but it means the bench's reported p95 floor IS the worst case the production hook can hit.
- **The bench can be expensive itself.** 100 reps × 5 hooks × 10 commands × ~25 ms per cell = ~125 s for a single baseline run. Use lower `--reps` (20) for iteration; full N=100 for the locked baseline.
- **Pre-jq probes are not free.** `grep -qE` against a 200-byte JSON string costs ~3-5 ms. Worth it when the alternative is a 25-30 ms `jq` spawn, but not free. For hooks with very simple matchers, jq might be acceptable; measure before optimizing.
- **Hook source edits are user-facing audit trail.** The pre-jq probe added to `governance-gate.sh` is documented in the hook with a reference to this spec (`# Pre-jq fast-path probe (the hook-chain-latency spec-hook-chain-latency)`). Future maintainers can grep for the spec slug to understand why the probe exists.
- **`if`-field syntax accepts pipe-separated globs.** The exact glob shape is permission-rule syntax — see Claude Code's hooks + permissions docs. For supply-chain-scan, the obvious pattern `Bash(npm install *|pnpm install *|...)` would miss `npm i foo` and `pnpm add foo`; the broader `Bash(npm *|pnpm *|...)` catches all sub-commands and lets the hook decide. Trade-off: more hook spawns than strictly necessary, but no false negatives.
- **The bench's command set is synthetic.** A real-session distribution probe (instrumented `PostToolUse(Bash)` advisory hook logging command shapes) was scoped in the hook-chain-latency spec plan.md but deferred in v1 — the synthetic set covers the obvious shapes and the bench is honest about the gap. If the bench predicts wins that the user doesn't perceive, the synthetic set is wrong and the deferred work becomes the next priority.
