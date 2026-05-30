# 117 — remove-hook-chain-latency — tasks

_Generated from `plan.md` on 2026-05-29. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation — sever the one live cross-ref

- [x] 1. `.agent0/hooks/governance-gate.sh` — reword the line-41 comment to drop the `see .agent0/memory/hook-chain-latency.md` dead pointer; KEEP the probe body + CRITICAL INVARIANT verbatim.

## Implementation — delete files + crontab + regenerate

- [x] 2. `git rm` the bench tool, baseline, both memories, the routine, and the test suite dir (`.agent0/tools/bench-hooks.sh`, `.claude/.perf-baseline.json`, `.agent0/memory/hook-chain-latency.md`, `.agent0/memory/hook-chain-maintenance.md`, `.agent0/routines/hook-chain-bench.md`, `.claude/tests/hook-chain-latency/`).
- [x] 3. Remove the `hook-chain-bench` line from the crontab `AGENT0-ROUTINES` block (`crontab -l | grep -v 'run-routine.sh hook-chain-bench' | crontab -`); verify `cc-platform-audit` survives.
- [x] 4. `bash .agent0/tools/memory-project.sh` — regenerate `MEMORY.md` (drops the two deleted entries).

## Verification

- [x] 5. `ls` of all deleted paths → gone; `ls .claude/tests/hook-chain-latency` → gone. [spec: Scenarios 1, 2]
- [x] 6. `crontab -l` shows no `hook-chain-bench` line; `cc-platform-audit` line intact. [spec: Scenario 3]
- [x] 7. `governance-gate.sh` pre-jq probe + CRITICAL INVARIANT intact; no dead memory pointer. [spec: Scenario 4]
- [x] 8. `grep -n 'hook-chain' .agent0/memory/MEMORY.md` empty; projection ran clean. [spec: Scenario 5]
- [x] 9. Affected test suites green: governance-gate, secrets-scan, harness-sync, instruction-drift `run-all.sh`. [spec: Scenario 6]
- [x] 10. Repo-wide grep (capacity terms) outside `docs/specs/` → only the KEEP-listed `memory-placement.md` spec-096 narrative lines. [spec: final criteria]
- [x] 11. `spec.md` Status → `shipped`; outcome recorded; `notes.md` finalized.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
