# 061 — subagent-stop-hook

_Created 2026-05-19._

**Status:** in-progress

## Intent

The delegation pipeline records `PreToolUse(Agent)` dispatches in `.claude/delegation-audit.jsonl` (11 fields per row: `ts`, `session_id`, `subagent_type`, `model`, `model_specified`, `formatted`, `override`, `advisory_emitted`, `advisory_kind`, `escalation_signals`, `task_summary`). The row is written at dispatch time and never closed — there is no termination event recorded. Post-hoc analysis cannot answer:

- How long did each sub-agent actually run?
- Did the sub-agent exit normally, or did the post-edit validator's loop-budget kick in?
- How many edits did the sub-agent make before stopping?
- Did this sub-agent block downstream work (long-running) or finish quickly?

Claude Code's `SubagentStop` hook event fires when a sub-agent task ends. This spec adds `.claude/hooks/delegation-stop.sh` that appends a sibling JSONL row keyed by the same `agent_id` (when available) or `session_id` + best-effort correlation, closing the open dispatch with termination metadata. Parent of the umbrella spec 060 (A3, top pick #1 by ROI).

## Acceptance criteria

- [ ] **Scenario: sub-agent completes normally**
  - **Given** a `PreToolUse(Agent)` audit row was appended by the delegation gate at dispatch (now also recording `tool_use_id` per spec resolution)
  - **When** `SubagentStop` fires for the same sub-agent invocation
  - **Then** a sibling JSONL row is appended to `.claude/delegation-audit.jsonl` with `event: "subagent-stop"`, `agent_id`, `tool_use_id` (read from per-sub-agent `.meta.json` sidecar), `agent_type`, `duration_ms` (close_ts − dispatch_ts client-computed), `exit: "ok"`, `edit_count` (counted from `agent_transcript_path` JSONL `tool_use` entries), `last_assistant_message_head` (200 chars), `agent_transcript_path`

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

- [ ] `.claude/hooks/delegation-stop.sh` exists, executable (`chmod +x`), follows the same bash conventions as `delegation-gate.sh` (jq with guarded `// empty`, no sticky `exec` redirects, fail-open on missing deps)

- [ ] `.claude/hooks/delegation-gate.sh` extended to capture `tool_use_id` in the dispatch row (one new `jq -r` call + one new audit field). Existing 11 fields preserved; `tool_use_id` becomes the 12th.

- [ ] `.claude/settings.json` registers the hook under the `SubagentStop` event surface

- [ ] Tests in `.claude/tests/` cover the four success scenarios + failure-safe path + orphan-stop (no matching dispatch row) + gate-extension regression (existing dispatch tests still pass with new field)

- [ ] `.claude/rules/delegation.md` § Audit log updated to reflect both the new dispatch field (`tool_use_id`) AND the new row event schema; § The 5-field handoff unchanged (the parser doesn't expose `tool_use_id` to the handoff brief — it's harness-internal)

## Non-goals

- Closing audit rows for the **parent** Claude Code main session (out of scope — parent has no `agent_id`)
- Capturing cost / token usage (separate gap §A6 in spec 060; may share infra later but not bundled here)
- Real-time dashboard of running sub-agents (violates `feedback_speculative_observability.md` rule-of-three)
- Modifying the open dispatch row in-place — termination is a **second JSONL row** correlated by `agent_id` so the audit log remains strictly append-only
- Per-edit event granularity (would explode log volume; aggregate `edit_count` is sufficient v1)

## Open questions

_All pre-flight unknowns resolved 2026-05-19 via empirical probe-fire of 3 hook events. See `notes.md` § Design decisions for full payload schemas and decision rationale._

- [x] ~~Does Claude Code's `SubagentStop` event payload reliably include the `agent_id` set in `PreToolUse(Agent)`?~~ **Resolved**: `SubagentStop` carries `agent_id` (top-level string), but `PreToolUse(Agent)` does NOT — it carries `tool_use_id` only. The two identifiers are disjoint. Bridge: per-sub-agent transcript sidecar `.meta.json` carries `toolUseId` matching PreToolUse's `tool_use_id`. The gate is extended to record `tool_use_id` in the dispatch row; the stop hook reads the sidecar to get both keys.
- [x] ~~Is `edit_count` reachable from existing state (`session-track-edits.sh`)?~~ **Resolved**: `session-track-edits.sh` is session-scoped, conflating parent + all sub-agents. Per-sub-agent transcript JSONL (`agent_transcript_path` from SubagentStop payload) is the canonical edit-count source — `jq` filter over `assistant.message[].tool_use` entries with `.name ∈ {Edit, Write, MultiEdit}`. Deterministic per-agent.
- [x] ~~Denormalize closing row, or require join?~~ **Resolved**: Denormalize. Close row carries `agent_type` (mirrors dispatch's `subagent_type`), `last_assistant_message_head` (200-char snippet), `agent_transcript_path` pointer. Mirrors `.claude/rules/runtime-introspect.md` § `last-run.json schema` self-sufficiency pattern.

No new open questions surfaced during pre-flight. Implementation can proceed against the locked design.

## Context / references

- Parent umbrella: `docs/specs/060-harness-gaps-2026/spec.md` § Gap matrix row A3
- `.claude/hooks/delegation-gate.sh` — the dispatch-side hook this complements
- `.claude/hooks/session-track-edits.sh` — possible source for `edit_count`
- `.claude/rules/delegation.md` § Audit log — schema doc to update
- `.claude/delegation-audit.jsonl` — the file being extended (currently 116302 bytes / hundreds of dispatches)
- Claude Code hooks reference: https://thepromptshelf.dev/blog/claude-code-hooks-complete-reference-2026/
