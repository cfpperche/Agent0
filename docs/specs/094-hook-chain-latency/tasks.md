# 094 — hook-chain-latency — tasks

_Generated from `plan.md` on 2026-05-26. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Layer 0 — Research gate (precondition for Phase 2 intervention 1)

- [ ] 1. Verify what Claude Code's `matcher` field actually accepts in `.claude/settings.json` for `PreToolUse(Bash)` hooks. Check: does it support payload-shape patterns (`Bash:*git commit*`, `Bash:*npm install*`), or only tool-name regex (`Bash`, `Edit|Write|MultiEdit`)? Sources to consult: official CC hook docs (via `WebFetch` or `claude-code-guide` agent), the project's existing matchers (settings.json today uses only tool-name level), an empirical probe in a sandbox if docs are ambiguous. Record the finding inline in `plan.md § Approach` (under intervention 1) and in `notes.md` as a design decision. If matchers are tool-name-only, mark intervention (1) as skipped and proceed; subsequent tasks reference this decision.

### Layer 1 — Bench tooling (Phase 1)

- [ ] 2. Build `.claude/tools/bench-hooks.sh` per `plan.md § Files to touch`. CLI: `bench-hooks.sh [--baseline | --check] [--reps N] [--commands "<list>"]`. Default reps=100; default command set per spec Scenario 1 (no-op `:`, `ls`, `cat`, `echo`, `git status`, `git log -1`, `git commit -m '…'`, `npm install --dry-run`, `cat file.md`, `grep`). For each (hook × command-class) cell, time `bash <hook> <stdin-payload>` in tight loops, compute p50/p95, subtract a no-hook baseline (run with `cat` as the hook to characterize harness IPC + bash startup alone). Use `python3 -c "import time; ..."` for sub-ms timing or `printf '%.3f\n' $(echo ...)` arithmetic — `time` builtin is acceptable too. Output: human-readable table to stdout; JSON `{ git_sha, harness_version, os, ts, cells: { "<hook>": { "<command-class>": { p50_ms, p95_ms, n } } } }` to a path determined by mode.

- [ ] 3. Smoke-test `bench-hooks.sh` against a trivial no-op hook (e.g. write a temp `noop.sh` that just `exit 0`s). Verify the script produces sensible numbers (no-op hook should be ≤ 10 ms; if it reports 200 ms, the bench framework itself has overhead that dominates and must be fixed before running against real hooks).

### Layer 2 — Phase 1: capture baseline + real distribution

- [ ] 4. Run `bash .claude/tools/bench-hooks.sh --baseline` against the current main-branch hooks. Verify it writes `.claude/.perf-baseline.json` with all 4 hooks × representative command set cells populated. Sanity-check: numbers should align with the 2026-05-26 diagnostic in `spec.md § Intent` (secrets-scan-preflight ~44 ms on noop, supply-chain-scan ~48 ms, etc.) within ~30% variance.

- [ ] 5. Instrument the next real working session (~1 hour, mixed workload — at least one commit cycle, one editing session, one verification run) to capture the actual command-shape distribution. Simplest approach: a `PostToolUse(Bash)` advisory hook that appends `<command-first-token>` to a JSONL log; analyze post-session for shape distribution (`git`, `ls`, `cat`, `npm`, `bash -c`, etc.). Manual review of session transcript is acceptable as a fallback if the hook is too intrusive to wire up cleanly. Record distribution in `notes.md`.

- [ ] 6. Compare the synthetic command set used in task 4 against the real distribution from task 5. If they diverge sharply (e.g. real workload is 80% `git`-prefixed but synthetic was 50/50), re-weight the bench command list and re-run task 4 to refresh the baseline. Update `notes.md` with the comparison result.

- [ ] 7. Identify the dominant cost component per hook from the baseline data: jq parse cost, bash subprocess spawn, script logic, or a combination. This decision determines whether Phase 2a (pre-jq probe) is the right shape or whether (2b) consolidation is needed earlier. Document the finding in `notes.md`.

### Layer 3 — Phase 2a: pre-jq short-circuit

- [ ] 8. Apply pre-jq stdin probe to `.claude/hooks/governance-gate.sh`. Pattern: before the `INPUT=$(cat)` + `jq` parse at lines 21-23, add a fast probe — if stdin does NOT contain a `# OVERRIDE:` marker AND the command starts with a known-benign prefix (a small allowlist: `ls`, `cat`, `echo`, `git status`, `git log`, `grep`, `head`, `tail`, `wc`, `printf`), `exit 0` immediately. Otherwise fall through to the existing jq-based path. The probe is sufficient-but-not-necessary: false negatives (probe misses a safe command, full path handles it) are fine; false positives (probe exits 0 on a command needing inspection) are unacceptable.

- [ ] 9. Apply the same pre-jq probe to `.claude/hooks/secrets-scan.sh`. The script already short-circuits on non-`git commit` AFTER the jq parse; the optimization is to push that short-circuit BEFORE the jq via raw-stdin pattern (`grep -q '"command":"[^"]*git[[:space:]]*commit' <<<"$INPUT"` or equivalent). Falls through to the existing logic when the probe matches.

- [ ] 10. Apply the same pre-jq probe to `.claude/hooks/supply-chain-scan.sh`. Probe checks raw stdin for any of the 11 manager keywords (`npm`, `pnpm`, `yarn`, `bun`, `pip`, `uv`, `poetry`, `pdm`, `cargo`, `go`, `composer`); if none present, `exit 0` before jq. Falls through otherwise.

- [ ] 11. Inspect `.claude/hooks/runtime-pre-mark.sh` (48 LOC). If Layer 2 Phase 1 data shows it's a non-trivial cost (>10 ms p95 on fast-path), apply the pre-jq probe pattern. If it's already <10 ms, leave untouched and document "no change needed" in `notes.md`.

- [ ] 12. Re-run `bash .claude/tools/bench-hooks.sh` (without `--baseline` or `--check` flags — just read-only output) against the Phase 2a hooks. Compare the new numbers against the baseline captured in task 4. Document the delta per hook + per command class in `notes.md`. If fast-path p95 already meets the proposed ≤ 80 ms budget, skip Layer 4 and proceed to Layer 5. If not, continue.

### Layer 4 — Phase 2 intervention 1: matcher narrowing (CONDITIONAL — only if Layer 0 task 1 confirms harness support)

- [ ] 13. **Conditional on task 1's finding.** If Claude Code supports payload-shape matchers, tighten `.claude/settings.json` for the narrowest gates: `supply-chain-scan` matcher → pattern targeting the 11 dep-install command shapes; `secrets-scan` matcher → pattern targeting `git commit` shapes. `governance-gate` and `runtime-pre-mark` stay on `Bash` (they must inspect all commands). Use the narrowest pattern that still catches every legitimate command shape — err on the side of false-positives (gate fires unnecessarily) over false-negatives (gate misses a relevant command).

- [ ] 14. **Conditional on task 13.** Run the gate-behavior test suites against the narrowed matchers to verify zero regression: `bash .claude/tests/secrets-scan/run-all.sh`, `bash .claude/tests/supply-chain/run-all.sh`. Both must pass. If any test fails, the matcher narrowing is too aggressive — back out the narrowed matcher and document why in `notes.md`.

- [ ] 15. **Conditional on tasks 13-14.** Re-run `bench-hooks.sh` to capture the post-matcher-narrowing delta. Combined with Phase 2a in Layer 3, the fast-path p95 should now hit the proposed budget. If it does, skip Layer 5 and proceed to Layer 6. If not, continue.

### Layer 5 — Phase 2b: orchestrator consolidation (CONDITIONAL — only if budget still not met)

- [ ] 16. **Conditional on tasks 12 + 15 showing the budget is still unmet.** Decision gate: re-evaluate whether consolidation is worth the surface change vs accepting a relaxed budget. Document the decision in `notes.md`. If proceeding with consolidation, complete tasks 17-19; if accepting relaxed budget, document the new budget number with reasoning, skip to Layer 6.

- [ ] 17. **Conditional on task 16's decision = consolidate.** Build `.claude/hooks/_pretooluse-bash-orchestrator.sh` (or similar name). Single hook that runs ONE jq parse, then sources `.claude/hooks/lib/governance-gate.sh`, `lib/secrets-scan.sh`, `lib/supply-chain-scan.sh`, `lib/runtime-pre-mark.sh` as functions (refactor existing scripts into lib functions). Each lib function takes the parsed CMD as input and returns its exit-2 / exit-0 decision; orchestrator aggregates and exits with the worst (any exit 2 wins).

- [ ] 18. **Conditional on task 17.** Update `.claude/settings.json` `PreToolUse[Bash]` block to register ONE entry (the orchestrator) instead of four. The existing four entries are deleted.

- [ ] 19. **Conditional on tasks 17-18.** Run the gate-behavior test suites to verify zero regression: `bash .claude/tests/secrets-scan/run-all.sh`, `bash .claude/tests/supply-chain/run-all.sh`, `bash .claude/tests/runtime-introspect/run-all.sh`. All must pass. Update `notes.md` with the post-consolidation bench numbers.

### Layer 6 — Phase 3: validate + lock new baseline

- [ ] 20. Re-run `bash .claude/tools/bench-hooks.sh --baseline` to capture the post-Phase 2 numbers. This overwrites `.claude/.perf-baseline.json` with the new locked baseline. Verify all tracked cells are present and the new p95 numbers are at or below the agreed budget.

- [ ] 21. Build `.claude/tests/hook-chain-latency/run-all.sh` regression runner. Wraps `bash .claude/tools/bench-hooks.sh --check` with the project test-orchestrator pattern (mirror the shape of `.claude/tests/harness-sync/run-all.sh`). The `--check` mode reads `.claude/.perf-baseline.json`, re-runs the bench, fails non-zero if any tracked p95 exceeds baseline + tolerance (default 25%, configurable via env var `CLAUDE_HOOK_CHAIN_TOLERANCE_PCT`).

- [ ] 22. Verify the regression check fires correctly by artificial slowdown: temporarily insert `sleep 0.1` at the top of any hook, run `bash .claude/tests/hook-chain-latency/run-all.sh`, expect exit non-zero with a clear stderr message naming the offending hook + cell. Remove the sleep; re-run; expect exit 0.

- [ ] 23. Run all gate-behavior test suites to confirm zero behavioral regression from Phase 2 changes: `bash .claude/tests/secrets-scan/run-all.sh`, `bash .claude/tests/supply-chain/run-all.sh`, `bash .claude/tests/runtime-introspect/run-all.sh`, `bash .claude/tests/harness-sync/run-all.sh`, `bash .claude/tests/instruction-drift/run-all.sh`, `bash .claude/tests/runtime-capabilities/run-all.sh`. All must pass.

### Layer 7 — Documentation + close

- [ ] 24. Write `.claude/rules/hook-chain-latency.md`. Sections: §What (purpose + budget + scope — PreToolUse(Bash) only), §Budget (the agreed p95 number + tolerance + reasoning if changed from the proposed 80 ms), §Bench tool (how to run `bench-hooks.sh --baseline` / `--check`), §New hook discipline (any new PreToolUse(Bash) hook must be benchmarked + budgeted before merge; comment in `.claude/settings.json` references this rule), §Baseline JSON shape (schema + meaning of fields), §Cross-references (`runtime-introspect.md` as sibling perf rule).

- [ ] 25. Update `docs/specs/094-hook-chain-latency/spec.md`: flip `**Status:** draft` → `shipped`. Check off every `- [ ]` acceptance bullet to `- [x]` based on what tasks 1-24 actually delivered. If any acceptance bullet was not satisfied (e.g. matcher narrowing didn't apply because harness doesn't support it), DO NOT silently check it — instead, leave unchecked and document the why in `notes.md` and as a footnote in the spec.

## Verification

- [ ] 26. **Acceptance walk-through.** Walk every checklist bullet in `spec.md § Acceptance criteria` (6 scenarios + 2 static-fact bullets). Each must be satisfied by the diff this implementation produced, or explicitly documented as deferred/unsatisfied with reason.

- [ ] 27. **Dogfood verification.** Open a fresh interactive session in this repo. Run `git status`, `ls`, `cat CLAUDE.md`, `git log -1` in quick succession. The perceived latency per Bash call should be visibly faster than the pre-implementation experience. Document the subjective impression in `notes.md`. If the change is not perceivable, the budget is wrong or the bench is misleading — that's a Phase 3 finding worth surfacing.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
