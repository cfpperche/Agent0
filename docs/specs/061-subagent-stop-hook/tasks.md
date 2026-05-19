# 061 — subagent-stop-hook — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

_Pre-flight resolved 2026-05-19 via probe-fires of `PreToolUse(Agent)` + `SubagentStart` + `SubagentStop`. Tasks 1 + 2 marked DONE inline; design locked in `notes.md` § Design decisions; spec OQs all resolved._

- [x] 1. ~~Resolve Open Question #1: empirical payload capture.~~ **Resolved.** `SubagentStop` carries `agent_id` (top-level) but PreToolUse only carries `tool_use_id`. Bridge: per-sub-agent transcript sidecar `.meta.json.toolUseId`. Design: extend gate to record `tool_use_id`; stop hook reads sidecar.
- [x] 2. ~~Resolve Open Question #2: edit-count accounting.~~ **Resolved.** `session-track-edits.sh` is session-scoped (wrong granularity). Canonical source: `agent_transcript_path` JSONL → `jq` filter for `tool_use` blocks with name ∈ {Edit, Write, MultiEdit}. No new accumulator needed.
- [x] 3. **Extend `.claude/hooks/delegation-gate.sh`** to capture `tool_use_id` in dispatch audit row — DONE 2026-05-19.
  - Added at line 42: `TOOL_USE_ID="$(printf '%s' "$INPUT" | jq -r '.tool_use_id // ""')"`
  - Added to `jq -n` call: `--arg tool_use_id "$TOOL_USE_ID"` + schema field `tool_use_id:$tool_use_id`
  - Verified e2e: dispatch fired "gate-verify" Explore (haiku); tail of `.claude/delegation-audit.jsonl` now has `"tool_use_id":"toolu_01HVJW3fCdpnSV13MdWMCwoB"` adjacent to `session_id` — 12-field row.
  - **No delegation-gate test suite exists** (only `.claude/tests/{secrets-scan,supply-chain,...}` — gap noted in notes.md). Regression coverage = manual e2e only.
- [x] 4. **Write `.claude/hooks/delegation-stop.sh`** following the canonical pattern — DONE 2026-05-19 (174 lines, syntax OK):
  - Shebang + `set -uo pipefail` (NOT `-e` — fail-open requires graceful continuation)
  - `INPUT="$(cat 2>/dev/null || true)"`; bail on empty / missing jq
  - Extract: `AGENT_ID`, `SESSION_ID`, `AGENT_TYPE`, `AGENT_TRANSCRIPT_PATH`, `LAST_MSG` (head 200 chars), `STOP_HOOK_ACTIVE`
  - Derive sidecar: `META="${AGENT_TRANSCRIPT_PATH%.jsonl}.meta.json"`; `TOOL_USE_ID="$(jq -r '.toolUseId // ""' "$META" 2>/dev/null || echo "")"`
  - Count edits in transcript (verify jq expr against real transcript during dev): `EDIT_COUNT="$(jq -s '[.[] | select(.type=="assistant") | (.message // [])[]? | select(type=="object" and .type=="tool_use" and (.name=="Edit" or .name=="Write" or .name=="MultiEdit"))] | length' "$AGENT_TRANSCRIPT_PATH" 2>/dev/null || echo null)"`
  - Read loop-budget state: `FAILS="$(cat "$PROJECT_DIR/.claude/.delegation-state/agents/$AGENT_ID/consecutive_failures" 2>/dev/null || echo 0)"`; budget from `${CLAUDE_DELEGATION_LOOP_BUDGET:-5}`; if `$FAILS -ge $BUDGET` → `EXIT="loop-budget-exceeded"` else `EXIT="ok"`
  - Look up dispatch `ts` via tail-grep on `.claude/delegation-audit.jsonl` for matching `tool_use_id` (or fall back to `(session_id, subagent_type)` heuristic if `TOOL_USE_ID` empty); compute `DURATION_MS` via `date -d` epoch math; `null` on miss
  - Build close row with `jq -n`: `{ts, event: "subagent-stop", session_id, agent_id, tool_use_id, agent_type, exit, duration_ms, edit_count, last_assistant_message_head, agent_transcript_path, correlation}`
  - Append with `flock` (mirror runtime-capture.sh § Phase 6 atomic write pattern)
  - Fail-open everywhere: any error → exit 0 silently
- [x] 5. `chmod +x .claude/hooks/delegation-stop.sh` — DONE.
- [x] 6. Register the hook in `.claude/settings.json` under `hooks.SubagentStop` — DONE (inserted after `Stop` block). Validated JSON via `jq .`:
  ```json
  "SubagentStop": [
    { "hooks": [ { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/delegation-stop.sh" } ] }
  ]
  ```
- [ ] 7. Write tests under `.claude/tests/<NNN>-delegation-stop/`:
  - `run.sh` — orchestrator
  - `fixtures/ok.json` — normal completion payload (matches a fixture dispatch row + matching sidecar `.meta.json` + tiny transcript with 0 edits)
  - `fixtures/with-edits.json` — fixture transcript with 3 Edit + 1 Write tool_use blocks; assert `edit_count: 4`
  - `fixtures/loop-budget.json` — pre-seeded state file with `5`; assert `exit: "loop-budget-exceeded"`
  - `fixtures/orphan.json` — no matching dispatch row; assert `correlation: "unmatched"`, `duration_ms: null`
  - `fixtures/malformed.json` — missing `agent_id`; assert exit 0, no row written
  - `fixtures/missing-sidecar.json` — sidecar `.meta.json` not present; assert `tool_use_id: null`, fall-back correlation works
  - Each test pipes fixture as stdin, runs hook in isolated tmpdir with synthetic audit log, asserts tail row via `jq`
- [ ] 8. Verify gate-extension regression: run `bash .claude/tests/run-all.sh` (or whichever orchestrator exists); 100% pass required before declaring done.
- [ ] 9. Update `.claude/rules/delegation.md`:
  - § Audit log: list `tool_use_id` as 12th dispatch field; document close row event schema (12+ fields); add example `jq` join query
  - § The 5-field handoff: NO change (parser doesn't expose `tool_use_id` to brief — harness-internal)
- [x] 10. **Manual end-to-end verification (happy path)** — DONE 2026-05-19. Dispatched "e2e-final" Explore (haiku); audit log tail has paired open+close rows joined by `tool_use_id: "toolu_018PMUwspakE2hZoArVyStUU"`. Close row records: `event: "subagent-stop"`, `agent_id: "ae57e5cc6f6de8796"`, `exit: "ok"`, `duration_ms: 1000`, `edit_count: 0`, `correlation: "tool_use_id"` (exact bridge worked, not heuristic fallback). Remaining e2e scenarios (with-edits, loop-budget, orphan-stop, missing-sidecar, malformed) covered by Task 7 fixture tests.

## Verification

- [ ] **Scenario: dispatch row carries tool_use_id** — fire any Agent call; tail of `.claude/delegation-audit.jsonl` has `tool_use_id: "toolu_..."` (non-empty)
- [ ] **Scenario: sub-agent completes normally** — dispatch a benign read-only `Agent` call (e.g. Explore for "list files in .claude/rules/"); confirm audit log has two rows joined by `tool_use_id`, close row has `event: "subagent-stop"`, `exit: "ok"`, `duration_ms > 0`, `edit_count: 0`
- [ ] **Scenario: sub-agent makes edits** — dispatch an Agent that creates a tiny file; close row records `edit_count >= 1`; the edit-count count matches the actual number of Edit/Write/MultiEdit tool_use blocks in the agent's transcript
- [ ] **Scenario: loop-budget exhaustion** — pre-seed `.claude/.delegation-state/agents/<id>/consecutive_failures` with `5`; fire the hook with matching payload; close row records `exit: "loop-budget-exceeded"`
- [ ] **Scenario: orphan stop (no dispatch row)** — fire the hook with a SubagentStop payload whose `agent_id` has no matching dispatch row in audit log; close row records `correlation: "unmatched"`, `duration_ms: null`
- [ ] **Scenario: malformed payload** — fire the hook with empty stdin; exit 0, no row written
- [ ] **Scenario: missing sidecar `.meta.json`** — fire the hook with a payload whose `agent_transcript_path` exists but sidecar does not; close row records `tool_use_id: null`, fall-back correlation via `(session_id, subagent_type)` works
- [ ] **Scenario: unwritable log path** — `chmod -w` the audit log, fire the hook; exit 0, hook does not crash
- [ ] `.claude/hooks/delegation-stop.sh` passes shellcheck (no SC2086 unquoted glob, no SC2046 word-split, etc.)
- [ ] `.claude/hooks/delegation-gate.sh` passes shellcheck after extension (no new warnings vs baseline)
- [ ] `.claude/settings.json` is valid JSON after edit (jq `.` round-trips)
- [ ] All existing delegation-gate tests pass with new `tool_use_id` field present in dispatch rows

## Notes

- The hook is the audit-row closer, not a state machine. If a session crashes mid-dispatch, the dispatch row stays open — that's an accepted "leaked dispatch" state. A post-hoc cleanup query can grep for orphaned dispatches older than N hours and flag them.
- This spec deliberately does NOT add cost/token capture even though the hook is the natural surface. Spec 060 §A6 owns that; bundling would expand scope and delay the alta-priority audit-closing capacity.
- Pre-flight empirical work (2026-05-19) surfaced that mid-session hook registration in `.claude/settings.local.json` activated immediately — contradicting `.claude/rules/session-handoff.md`'s "Hooks only register on the next session". This is documented in `notes.md` § Tradeoffs as deferred follow-up; the memory at `.claude/memory/cc-platform-hooks.md` or the rule could use an update, but it's orthogonal to this spec's delivery.
- The `agent_id` (e.g. `aa02e24eb5ac149d1`) appears to be a 17-character hex-ish identifier; current pattern visible in `/home/goat/.claude/projects/-home-goat-Agent0/<session_id>/subagents/agent-*.jsonl` filenames. Don't assume a specific format — treat as opaque string per CC convention.
