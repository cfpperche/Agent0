# 181 — claude-exec-run-bounds — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Verify:** `bash .agent0/tests/claude-exec-skill/run-all.sh && bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/claude-exec`

## Implementation

- [x] 1. Extend the claude-exec test harness with a slow stub mode that can sleep, write partial output, and record argv without invoking the real Claude CLI.
- [x] 2. Add RED timeout coverage: a short `--timeout` kills the slow stub, exits with the timeout code, writes timeout metadata, preserves partial artifacts, and leaves no child process behind.
- [x] 3. Add RED budget/progress coverage: valid `--max-budget-usd` appears in recorded argv, malformed budgets fail before invocation, and a slow run emits at least one heartbeat to stderr after the progress interval.
- [x] 4. Update `claude-exec.sh` usage text and parser for `--timeout`, `--progress-interval`, and `--max-budget-usd`.
- [x] 5. Validate timeout/progress/budget inputs before creating success-looking run output beyond the normal run dir, using concise `claude-exec error:` messages for malformed values.
- [x] 6. Forward `--max-budget-usd` to the Claude argv and record `max_budget_usd` in `metadata.json` and `runs.jsonl`.
- [x] 7. Wrap child execution in a timeout-aware wait loop that emits progress heartbeats to stderr and records `timeout_seconds`, `progress_interval_seconds`, `timed_out`, and `elapsed_seconds`.
- [x] 8. Preserve existing output extraction for both `stdout.txt` JSON and `events.jsonl` stream-json; do not report success when Claude exits non-zero for budget, timeout, or any other failure.
- [x] 9. Update `SKILL.md` with new flag docs, failure semantics, and a recommended broad-review invocation that uses scoped prompts plus timeout/budget/streaming.
- [x] 10. Run the claude-exec suite and fix regressions without weakening spec-129 tests.

## Verification

- [x] `bash .agent0/tests/claude-exec-skill/run-all.sh` passes, including new timeout/budget/progress tests.
- [x] `bash -n .agent0/skills/claude-exec/scripts/claude-exec.sh` passes.
- [x] `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/claude-exec` passes.
- [x] One live smoke with the real Claude CLI uses a tiny prompt, explicit `--timeout`, explicit `--max-budget-usd`, and records either a successful result or a budget-exceeded non-success with clear metadata. Do not use a broad paid review as the smoke.
- [x] `docs/specs/181-claude-exec-run-bounds/spec.md` acceptance boxes are updated only after the corresponding checks are actually green.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
