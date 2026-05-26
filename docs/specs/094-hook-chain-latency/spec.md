# 094 — hook-chain-latency

_Created 2026-05-26._

**Status:** draft

## Intent

Cut the perceived latency of every `Bash` tool call in this project by optimizing the PreToolUse hook chain, without weakening any gate the project depends on. Empirical baseline (2026-05-26 diagnostic): four PreToolUse(Bash) hooks (`governance-gate.sh`, `secrets-scan.sh`, `supply-chain-scan.sh`, `runtime-pre-mark.sh`) run sequentially before every Bash invocation, each consuming ~20-50 ms of wall time even when the underlying command is a no-op like `ls` or `echo`. Combined with PostToolUse / PostToolUseFailure capture and Claude Code's own harness IPC, a typical `git status` or `git commit` round-trip costs the user ~150-300 ms of hook-chain overhead — and a 6-call workflow (add + commit + verify + add + commit + push) spends ~1-2 seconds in hooks before any real work happens. The native `.githooks/pre-commit` (gitleaks) is NOT the bottleneck: gitleaks scans the staged diff in ~33 ms (12.9 ms internal). The cost lives in the Claude Code harness preflight chain. This spec scopes the optimization: identify the dominant cost (subprocess spawn / jq parsing / library sourcing / regex over irrelevant input), measure the per-hook + per-command-class distribution, then apply the cheapest intervention that hits a target latency budget without removing or weakening any gate. The goal is mechanical responsiveness — making agent-driven workflows feel as fast as a human terminal — not architectural redesign.

## Acceptance criteria

- [ ] **Scenario: empirical baseline is captured and committed**
  - **Given** the current PreToolUse(Bash) chain on `main`
  - **When** a benchmark script is run against a representative command set (no-op `:`, `ls`, `git status`, `git log -1`, `git commit -m '…'`, `npm install --dry-run`, `cat file.md`)
  - **Then** per-hook and per-command-class p50/p95 latency numbers land in a committed artifact (e.g. `.claude/.perf-baseline.json` or equivalent) with the harness configuration + git SHA recorded, so future regressions can be detected by re-running the same script

- [ ] **Scenario: fast-path commands hit the target budget**
  - **Given** a "fast-path" Bash command (one that none of the four gates have a real reason to scrutinize — e.g. `ls`, `cat`, `git status`, `git log`, `echo`, `grep`)
  - **When** the optimized PreToolUse chain runs against it
  - **Then** the full chain completes within a documented p95 budget (target proposed in plan; OQ on the exact number) without any gate skipping its actual decision logic for the commands that DO need it

- [ ] **Scenario: slow-path gates still fire fully on their relevant commands**
  - **Given** a Bash command that one or more gates exist to inspect (`git commit`, `npm install`, `pip install`, an `Agent` dispatch, a destructive `rm -rf`, etc.)
  - **When** the optimized PreToolUse chain runs against it
  - **Then** every applicable gate executes its full check, emits its full advisory or block response, and the existing gate-behavior test suites (`secrets-scan`, `supply-chain`, `governance-gate` tests under `.claude/tests/`) pass with zero regressions

- [ ] **Scenario: hot-path command distribution is documented**
  - **Given** an instrumented session that logs every Bash invocation with command shape + which gates short-circuited vs ran
  - **When** the maintainer reviews the captured distribution after a real working session
  - **Then** the distribution names the top N command shapes by frequency and the gate-runtime they incur, so optimization effort targets the actual hot path rather than speculative cases

- [ ] **Scenario: regression alarm exists**
  - **Given** the benchmark script committed under acceptance criterion 1
  - **When** a future PR or routine re-runs it
  - **Then** a clear pass/fail signal is emitted (e.g. exit non-zero if p95 of any command class exceeds budget by >X%), enabling a routine or CI check to catch hook-perf regressions before they ship

- [ ] **Scenario: no behavioral regression in existing capacities**
  - **Given** the optimized PreToolUse chain
  - **When** the full project test suite runs (`bash .claude/tests/*/run-all.sh`)
  - **Then** every test passes with zero changes to the gate behavior — only timing changes are permitted, never gate-outcome changes

- [ ] The optimization documentation lives in `.claude/rules/hook-chain-latency.md` (or extends an existing rule), naming the target budget, the chosen optimization shape, and the maintenance discipline (any new PreToolUse hook must be benchmarked + budgeted).

- [ ] The benchmark script lives at `.claude/tools/bench-hooks.sh` (or similar), is executable, runs deterministically, and prints both human-readable and JSON output for the regression alarm.

## Non-goals

- **Removing or weakening any gate.** `governance-gate`, `secrets-scan` preflight, `supply-chain-scan`, and `runtime-pre-mark` exist for documented reasons (delegation discipline, secret-exfil prevention, dependency-install blocking, runtime introspect). The optimization must preserve all gate behavior; latency wins come from faster short-circuit on irrelevant commands, not from skipping checks on relevant ones.
- **Optimizing the native `.githooks/pre-commit` (gitleaks).** The diagnostic shows gitleaks is ~33 ms; not a real cost. Out of scope.
- **Optimizing PostToolUse / PostToolUseFailure hooks.** Those don't gate the next user prompt; their latency is invisible to perceived responsiveness. They may benefit from the same techniques applied to PreToolUse, but only as a follow-up if the user reports a separate complaint.
- **Reducing Claude Code harness IPC overhead.** That's controlled by the harness, not this repo. Out of our hands; measure it but don't try to optimize it.
- **Optimizing Edit / Write / MultiEdit hook chains.** Different chain, different perf profile, different commands (no shell spawn). If they're slow, scope a separate spec.
- **Replacing bash with another language as a forgone conclusion.** A language port is one possible intervention; the plan picks the intervention based on the baseline data, not in advance.
- **Adding new gates or expanding existing gate scope.** Scope-shrinking the existing gates is also out (see first non-goal). This is pure perf work.
- **Reordering the gate chain to "fail fast" semantically.** Order matters for correctness in some cases (e.g. governance before secrets); preserve the current order unless the plan can prove the change is behavior-preserving.

## Open questions

- [ ] **Target latency budget.** What p95 should the fast-path PreToolUse chain hit? Options: aggressive (≤ 50 ms), moderate (≤ 100 ms), conservative (≤ 150 ms — about 50% of current). The budget should be defensible against measured baseline + IPC overhead the harness adds; a too-aggressive budget that can't be hit without removing gates is worse than no budget.
- [ ] **Intervention shape.** Most likely candidates: (a) early short-circuit in each hook (cheap pattern match before any sourcing / parsing / regex), (b) consolidation into one orchestrator hook that dispatches in-process to function bodies (eliminates 3 of 4 subprocess spawns), (c) replace bash with a faster language (Go / Rust / Python) for the hot path, (d) tighter `matcher` fields in `settings.json` so hooks only register for the command classes they actually inspect (e.g. `secrets-scan` only fires on `Bash:*commit*`). Which to pick — and in what order — is plan work, but the OQ should resolve at least which approaches are on the table.
- [ ] **Acceptable complexity budget for the optimization itself.** A bash hook that short-circuits in 5 ms via a one-line regex is a 10x win at almost no complexity cost. A consolidated Go binary that hits 2 ms is a 50x win but adds a build step, a deploy artifact, and a maintenance surface. Where's the line — and who decides?
- [ ] **Should hot-path distribution be measured before the optimization, after, or both?** Measuring before targets effort accurately; measuring after validates the win against real workload, not synthetic benchmarks. Doing both costs an instrumented session round-trip but is the honest engineering posture. OQ on whether the cost is worth paying.
- [ ] **PostToolUse coverage decision.** Spec scopes PreToolUse only. If the post-hook chain (`runtime-capture-post.sh`, propagation-advise, etc.) also surfaces as user-perceptible latency once Pre is fast, do we extend this spec mid-flight or scaffold a sibling? Defer to plan time — note the question so a maintenance routine can catch it.

## Context / references

- `.claude/settings.json` — PreToolUse(Bash) matcher block; current chain registers 4 hooks (`governance-gate`, `secrets-scan` preflight, `supply-chain-scan`, `runtime-pre-mark`).
- `.claude/hooks/governance-gate.sh` — delegation governance gate (~unknown internal cost; measure).
- `.claude/hooks/secrets-scan.sh` — PreToolUse preflight that gates dangerous `git commit` compound shapes; NOT the gitleaks invocation. Measured ~44 ms against a noop command.
- `.claude/hooks/supply-chain-scan.sh` — blocks dependency-install commands across 11 managers. Measured ~48 ms against a noop command.
- `.claude/hooks/runtime-pre-mark.sh` — runtime-introspect pre-mark stamp. Measured cost TBD.
- `.claude/hooks/runtime-capture-pre.sh` — possible alternate name; verify during plan if both exist or only one.
- `.githooks/pre-commit` — native git hook running gitleaks; ~33 ms; NOT in scope.
- `.claude/rules/secrets-scan.md`, `.claude/rules/supply-chain.md`, `.claude/rules/delegation.md`, `.claude/rules/runtime-introspect.md` — the rules behind the four gates; preserve behavior.
- `.claude/tests/secrets-scan/`, `.claude/tests/supply-chain/`, `.claude/tests/runtime-introspect/` — gate-behavior test suites that must pass post-optimization.
- Conversation 2026-05-26 (this session, post-commit diagnostic) — the empirical data that motivated this spec: per-hook timings, gitleaks vs harness attribution, ~150-300 ms per-Bash-call overhead estimate.
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test; this spec passes that test because the user reported the latency complaint after observing it directly, not as speculative observability.
