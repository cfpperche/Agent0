# 061 — subagent-stop-hook — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. **Resolve Open Question #1: empirical payload capture.** Fire a no-op `Agent` dispatch with a `SubagentStop` hook configured to `cat > /tmp/subagent-stop-payload.json`. Inspect the JSON. Confirm presence/format of `agent_id` (or document the actual field name). Update `plan.md` § Approach with findings.
- [ ] 2. **Resolve Open Question #2: edit-count accounting.** Read `.claude/hooks/session-track-edits.sh`. Determine if per-agent edit counts already accumulate to a file under `.claude/.delegation-state/agents/<agent_id>/` or similar. If yes, document the file path and shape. If no, add a one-line append to `session-track-edits.sh` that bumps a counter per-agent — keep change minimal.
- [ ] 3. Write `.claude/hooks/delegation-stop.sh`:
  - Shebang + `set -euo pipefail`
  - Read stdin payload via `jq`
  - Extract `agent_id` / `session_id` / `tool_use_id`
  - Look up dispatch `ts` by tail-grep of `.claude/delegation-audit.jsonl` for matching `agent_id`
  - Compute `duration_ms`
  - Read `edit_count` from per-agent state (if available)
  - Read loop-budget state from `.claude/.delegation-state/agents/<agent_id>/consecutive_failures` (if present + ≥ budget, mark `exit: "loop-budget-exceeded"`)
  - Append close row via `flock` (mirror `runtime-capture.sh` pattern)
  - Fail-open on every error path: missing `jq`, missing `agent_id`, unwritable log, malformed payload → exit 0
- [ ] 4. `chmod +x .claude/hooks/delegation-stop.sh`
- [ ] 5. Register the hook in `.claude/settings.json`:
  ```json
  "SubagentStop": [
    { "hooks": [ { "type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/delegation-stop.sh" } ] }
  ]
  ```
- [ ] 6. Write tests under `.claude/tests/<NNN>-delegation-stop/`:
  - `run.sh` — orchestrator
  - `fixtures/ok.json` — normal completion payload
  - `fixtures/loop-budget.json` — loop-budget-exceeded payload + pre-seeded state file
  - `fixtures/no-edits.json` — pure-research payload
  - `fixtures/malformed.json` — missing `agent_id`
  - Each test pipes the fixture as stdin, runs the hook, asserts the tail row of an isolated audit log fixture
- [ ] 7. Update `.claude/rules/delegation.md` § Audit log — add the new row event schema, document the correlation key, add a sample `jq` query that joins open + close rows by `agent_id`
- [ ] 8. Run the full test suite: `bash .claude/tests/run-all.sh` (or equivalent) to confirm no regressions in delegation-gate tests

## Verification

- [ ] **Scenario: sub-agent completes normally** — dispatch a benign `Agent` call (e.g. Explore for "list files in .claude/rules/"); confirm `.claude/delegation-audit.jsonl` has two rows with matching `agent_id`, close row has `event: "subagent-stop"`, `exit: "ok"`, `duration_ms > 0`, `edit_count: 0`
- [ ] **Scenario: loop-budget exhaustion** — synthetically pre-seed `.claude/.delegation-state/agents/<id>/consecutive_failures` with `5` (the default budget) and a fake dispatch row, fire the hook with a matching payload; close row records `exit: "loop-budget-exceeded"`
- [ ] **Scenario: malformed payload** — fire the hook with empty stdin; exit code 0, no row written
- [ ] **Scenario: unwritable log path** — `chmod -w` the audit log, fire the hook; exit code 0, hook does not crash
- [ ] `.claude/hooks/delegation-stop.sh` passes shellcheck (no SC2086 unquoted glob, no SC2046 word-split, etc.)
- [ ] `.claude/settings.json` is valid JSON after edit (jq `.` round-trips)

## Notes

- The hook is the audit-row closer, not a state machine. If a session crashes mid-dispatch, the dispatch row stays open — that's an accepted "leaked dispatch" state. A post-hoc cleanup query can grep for orphaned dispatches older than N hours and flag them.
- This spec deliberately does NOT add cost/token capture even though the hook is the natural surface. Spec 060 §A6 owns that; bundling would expand scope and delay the alta-priority audit-closing capacity.
