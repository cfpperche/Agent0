# 061 — subagent-stop-hook

_Created 2026-05-19._

**Status:** draft

## Intent

The delegation pipeline records `PreToolUse(Agent)` dispatches in `.claude/delegation-audit.jsonl` (11 fields per row: `ts`, `session_id`, `subagent_type`, `model`, `model_specified`, `formatted`, `override`, `advisory_emitted`, `advisory_kind`, `escalation_signals`, `task_summary`). The row is written at dispatch time and never closed — there is no termination event recorded. Post-hoc analysis cannot answer:

- How long did each sub-agent actually run?
- Did the sub-agent exit normally, or did the post-edit validator's loop-budget kick in?
- How many edits did the sub-agent make before stopping?
- Did this sub-agent block downstream work (long-running) or finish quickly?

Claude Code's `SubagentStop` hook event fires when a sub-agent task ends. This spec adds `.claude/hooks/delegation-stop.sh` that appends a sibling JSONL row keyed by the same `agent_id` (when available) or `session_id` + best-effort correlation, closing the open dispatch with termination metadata. Parent of the umbrella spec 060 (A3, top pick #1 by ROI).

## Acceptance criteria

- [ ] **Scenario: sub-agent completes normally**
  - **Given** a `PreToolUse(Agent)` audit row was appended by the delegation gate at dispatch
  - **When** `SubagentStop` fires for the same sub-agent invocation
  - **Then** a sibling JSONL row is appended to `.claude/delegation-audit.jsonl` with `event: "subagent-stop"`, `agent_id` (or `session_id` fallback), `duration_ms` (now − dispatch_ts), `exit: "ok"`, `edit_count` (integer, from `session-track-edits.sh` accounting or fallback `0`)

- [ ] **Scenario: sub-agent stopped due to loop-budget exhaustion**
  - **Given** `.claude/.delegation-state/agents/<agent_id>` recorded `CLAUDE_DELEGATION_LOOP_BUDGET` consecutive validator failures
  - **When** `SubagentStop` fires
  - **Then** the closing row records `exit: "loop-budget-exceeded"` and `last_validator_exit: <int>`

- [ ] **Scenario: pure-research sub-agent (no edits)**
  - **Given** the dispatched sub-agent produced only a return text (no Edit/Write/MultiEdit calls)
  - **When** `SubagentStop` fires
  - **Then** the closing row records `exit: "ok"`, `edit_count: 0`

- [ ] **Scenario: failure-safe — missing dependencies or unparseable payload**
  - **Given** `jq` is absent, or the hook payload lacks expected fields, or the audit log path is non-writable
  - **When** the hook runs
  - **Then** it exits 0 silently; the harness continues; partial audit log degradation is acceptable

- [ ] **Scenario: parent-edit dispatch (no sub-agent — false positive)**
  - **Given** the harness fires `SubagentStop` for a non-Agent tool (defensive case)
  - **When** the hook parses the payload
  - **Then** it exits 0 without appending; no spurious rows

- [ ] `.claude/hooks/delegation-stop.sh` exists, executable (`chmod +x`), follows the same bash conventions as `delegation-gate.sh` (case-insensitive field parsing, jq with guarded `// empty`, no sticky `exec` redirects)

- [ ] `.claude/settings.json` registers the hook under the `SubagentStop` event surface

- [ ] Tests in `.claude/tests/` cover the four success scenarios + failure-safe path; existing test harness pattern from `delegation-gate.sh` tests is the template

- [ ] `.claude/rules/delegation.md` § Audit log updated to reflect the new row schema (event field, termination fields)

## Non-goals

- Closing audit rows for the **parent** Claude Code main session (out of scope — parent has no `agent_id`)
- Capturing cost / token usage (separate gap §A6 in spec 060; may share infra later but not bundled here)
- Real-time dashboard of running sub-agents (violates `feedback_speculative_observability.md` rule-of-three)
- Modifying the open dispatch row in-place — termination is a **second JSONL row** correlated by `agent_id` so the audit log remains strictly append-only
- Per-edit event granularity (would explode log volume; aggregate `edit_count` is sufficient v1)

## Open questions

- [ ] Does Claude Code's `SubagentStop` event payload reliably include the `agent_id` set in `PreToolUse(Agent)`? If not, fallback correlation is `session_id` + position-in-log heuristic. Verify against the live hook payload schema before locking `plan.md`.
- [ ] Is `edit_count` reachable from existing state (`.claude/hooks/session-track-edits.sh` writes per-edit; can we count rows in a per-agent file?) or do we need a new accumulator? Resolution: read the existing hook before designing.
- [ ] Should the closing row include the model identifier again (denormalized for query convenience) or stay normalized (require join with dispatch row by `agent_id`)? Denormalize — append-only logs benefit from self-contained rows for `jq` analysis.

## Context / references

- Parent umbrella: `docs/specs/060-harness-gaps-2026/spec.md` § Gap matrix row A3
- `.claude/hooks/delegation-gate.sh` — the dispatch-side hook this complements
- `.claude/hooks/session-track-edits.sh` — possible source for `edit_count`
- `.claude/rules/delegation.md` § Audit log — schema doc to update
- `.claude/delegation-audit.jsonl` — the file being extended (currently 116302 bytes / hundreds of dispatches)
- Claude Code hooks reference: https://thepromptshelf.dev/blog/claude-code-hooks-complete-reference-2026/
