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
- [x] 7. **Write tests under `.claude/tests/061-delegation-stop/`** — DONE 2026-05-21. 9 scenario scripts + `run-all.sh` + `README.md`; suite runs 9/9 PASS.
  - Deviation from the plan's `fixtures/*.json` layout: payloads are generated **inline** per script (`jq -cn` / heredoc) rather than read from static fixture files. Reason: the `SubagentStop` payload's `agent_transcript_path` must point at a real file inside the per-run `mktemp` dir, which a static fixture path cannot encode. Inline generation also matches the existing Agent0 test convention — `secrets-scan` / `harness-sync` build inputs inline, no test dir uses a `fixtures/` subdir. Recorded in `notes.md` § Deviations.
  - Scripts: `01-normal-completion`, `02-edit-count`, `03-loop-budget`, `04-orphan-stop`, `05-malformed-payload`, `06-missing-sidecar`, `07-unwritable-log`, `08-shellcheck`, `09-settings-registration`.
- [x] 8. **Regression check** — DONE 2026-05-21. No `delegation-gate` test suite exists (noted at task 3), so there is no gate suite to regress against directly; the adjacent `parallel-edit-validation` suite (exercises the delegation post-edit-validate flow) runs 2/2 PASS. The new 061 suite runs 9/9 PASS. Note: there is no top-level `.claude/tests/run-all.sh` — each test dir carries its own orchestrator.
- [x] 9. Update `.claude/rules/delegation.md` — DONE 2026-05-19.
  - § Audit log restructured: two row shapes (dispatch + close), bridge mechanism documented, 3 example `jq` queries (pair, find loop-budget exhaustions, find orphans). 12-field dispatch + 13-field close row schemas listed inline.
  - § The 5-field handoff: untouched (parser doesn't expose `tool_use_id` to brief).
- [x] 10. **Manual end-to-end verification (happy path)** — DONE 2026-05-19. Dispatched "e2e-final" Explore (haiku); audit log tail has paired open+close rows joined by `tool_use_id: "toolu_018PMUwspakE2hZoArVyStUU"`. Close row records: `event: "subagent-stop"`, `agent_id: "ae57e5cc6f6de8796"`, `exit: "ok"`, `duration_ms: 1000`, `edit_count: 0`, `correlation: "tool_use_id"` (exact bridge worked, not heuristic fallback). Remaining e2e scenarios (with-edits, loop-budget, orphan-stop, missing-sidecar, malformed) covered by Task 7 fixture tests.

## Verification

- [x] **Scenario: dispatch row carries tool_use_id** — verified by code inspection (`delegation-gate.sh:42` extracts `.tool_use_id`, `:235` writes it to the audit row) + task 3's recorded e2e (`toolu_01HVJW3fCdpnSV13MdWMCwoB` observed in a real dispatch row).
- [x] **Scenario: sub-agent completes normally** — `01-normal-completion.sh`: close row has `event:"subagent-stop"`, `exit:"ok"`, `edit_count:0`, `correlation:"tool_use_id"`, numeric `duration_ms ≥ 1000`.
- [x] **Scenario: sub-agent makes edits** — `02-edit-count.sh`: transcript with 3 Edit + 1 Write `tool_use` blocks (plus Read/Bash decoys) → `edit_count:4`.
- [x] **Scenario: loop-budget exhaustion** — `03-loop-budget.sh`: `consecutive_failures` pre-seeded at `5` → `exit:"loop-budget-exceeded"`.
- [x] **Scenario: orphan stop (no dispatch row)** — `04-orphan-stop.sh`: unrelated dispatch row only → `correlation:"unmatched"`, `duration_ms:null`.
- [x] **Scenario: malformed payload** — `05-malformed-payload.sh`: empty stdin AND missing-`agent_id` payload both → exit 0, no row.
- [x] **Scenario: missing sidecar `.meta.json`** — `06-missing-sidecar.sh`: `tool_use_id:null`, fallback `correlation:"heuristic-session-type"`. Required a 1-line hook fix (`""` → `null`); see `notes.md` § Deviations.
- [x] **Scenario: unwritable log path** — `07-unwritable-log.sh`: write-stripped audit log → exit 0, no row (skips gracefully under uid 0).
- [x] `.claude/hooks/delegation-stop.sh` passes static analysis — `08-shellcheck.sh`. NOTE: shellcheck is not installed in the dev env, so the test degraded to `bash -n` (clean); it runs full shellcheck automatically wherever the binary is present.
- [x] `.claude/hooks/delegation-gate.sh` passes static analysis — same `08-shellcheck.sh` script + same shellcheck-absent caveat.
- [x] `.claude/settings.json` is valid JSON after edit — `09-settings-registration.sh`: `jq .` round-trips + `SubagentStop` → `delegation-stop.sh` registration asserted.
- [x] No pre-existing `delegation-gate` test suite exists to regress; adjacent `parallel-edit-validation` suite passes 2/2 (see task 8).

## Notes

- The hook is the audit-row closer, not a state machine. If a session crashes mid-dispatch, the dispatch row stays open — that's an accepted "leaked dispatch" state. A post-hoc cleanup query can grep for orphaned dispatches older than N hours and flag them.
- This spec deliberately does NOT add cost/token capture even though the hook is the natural surface. Spec 060 §A6 owns that; bundling would expand scope and delay the alta-priority audit-closing capacity.
- Pre-flight empirical work (2026-05-19) surfaced that mid-session hook registration in `.claude/settings.local.json` activated immediately — contradicting `.claude/rules/session-handoff.md`'s "Hooks only register on the next session". This is documented in `notes.md` § Tradeoffs as deferred follow-up; the memory at `.claude/memory/cc-platform-hooks.md` or the rule could use an update, but it's orthogonal to this spec's delivery.
- The `agent_id` (e.g. `aa02e24eb5ac149d1`) appears to be a 17-character hex-ish identifier; current pattern visible in `/home/goat/.claude/projects/-home-goat-Agent0/<session_id>/subagents/agent-*.jsonl` filenames. Don't assume a specific format — treat as opaque string per CC convention.
