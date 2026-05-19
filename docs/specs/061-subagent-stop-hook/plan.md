# 061 — subagent-stop-hook — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

_Pre-flight (tasks 1 + 2 of original plan) completed 2026-05-19. Findings + design decisions in `notes.md` § Design decisions. The approach below incorporates the resolutions._

Two cooperating changes, both bash + jq, both fail-open:

1. **Extend `.claude/hooks/delegation-gate.sh`** to capture `tool_use_id` from PreToolUse(Agent) payload into the dispatch audit row (12th field). Cost: 2 lines (one `jq -r` extraction, one field in the `jq -n` call building the JSONL row). This is the prerequisite for exact dispatch↔stop correlation — without it, correlation degrades to a `(session_id, subagent_type, ts ordering)` heuristic that breaks under parallel same-type dispatches.

2. **New `.claude/hooks/delegation-stop.sh`** reads the `SubagentStop` payload, derives the per-sub-agent `.meta.json` sidecar path from `agent_transcript_path` (filename mapping: `agent-<id>.jsonl` → `agent-<id>.meta.json`), reads `toolUseId` from the sidecar, counts edits in `agent_transcript_path` JSONL (`jq` filter for `tool_use` blocks with `.name ∈ {Edit, Write, MultiEdit}`), reads loop-budget state from `.claude/.delegation-state/agents/<agent_id>/consecutive_failures` if present, computes `duration_ms` client-side by joining with the dispatch row (`(session_id, tool_use_id)` exact match via tail-grep on audit log), and appends the close row.

Order of operations:

1. **Extend the gate first** — `.claude/hooks/delegation-gate.sh`: add `TOOL_USE_ID="$(printf '%s' "$INPUT" | jq -r '.tool_use_id // ""')"` near other field extractions; add `--arg tool_use_id "$TOOL_USE_ID"` to the `jq -n` call; add `tool_use_id: $tool_use_id` to the schema. Verify existing tests still pass (they should — new field is additive).
2. **Update `.claude/rules/delegation.md`** § Audit log to list the new 12th field upfront, so the rule reflects the gate change atomically with its arrival.
3. **Write `.claude/hooks/delegation-stop.sh`**:
   - Stdin via `cat`, `jq` parse for `agent_id` / `session_id` / `agent_transcript_path` / `agent_type` / `last_assistant_message`
   - Derive sidecar: `META="${AGENT_TRANSCRIPT_PATH%.jsonl}.meta.json"`; `TOOL_USE_ID="$(jq -r '.toolUseId // ""' "$META")"`
   - Count edits: `EDIT_COUNT="$(jq -s '[.[] | select(.type=="assistant") | (.message // []) | (.[]? | select(type=="object" and .type=="tool_use" and (.name=="Edit" or .name=="Write" or .name=="MultiEdit")))] | length' "$AGENT_TRANSCRIPT_PATH")"` (verify schema during implementation — fallback to `0` on any error)
   - Read consecutive_failures: `FAILS=$(cat "$PROJECT_DIR/.claude/.delegation-state/agents/$AGENT_ID/consecutive_failures" 2>/dev/null || echo 0)`; if `$FAILS >= $BUDGET` → `EXIT="loop-budget-exceeded"`, else `EXIT="ok"`
   - Look up dispatch ts: tail-grep audit log for the matching dispatch row, parse `ts`, compute duration in ms via `date -d` epoch math
   - Build close row with `jq -n` (denormalised: agent_type, last_assistant_message_head [200 chars], agent_transcript_path)
   - Append with `flock` (mirror runtime-capture.sh pattern)
   - Fail-open on every error path: missing jq / unparseable payload / unwritable log / orphan stop → exit 0 silently
4. **Register in `.claude/settings.json`** under `SubagentStop` event surface.
5. **Tests** under `.claude/tests/<NNN>-delegation-stop/`:
   - Ok path: fixture pair (dispatch fixture + stop fixture); assert close row shape, correlation works
   - Loop-budget path: pre-seed state file with 5; close row records `exit: loop-budget-exceeded`
   - No-edits path: pure-research fixture (zero tool_use blocks); `edit_count: 0`
   - Orphan-stop path: stop without matching dispatch row; close row records `correlation: "unmatched"`, `duration_ms: null`
   - Malformed path: empty stdin / missing agent_id; exit 0, no row written
   - Gate-extension regression: existing dispatch tests pass with `tool_use_id` field present
6. **Update `.claude/rules/delegation.md`** § Audit log to fully document both rows (open + close), with an example `jq` query that joins them.

Hook is registered globally (not opt-in) — audit log overhead is one extra row per dispatch, negligible vs the value of termination data.

## Files to touch

**Create:**
- `.claude/hooks/delegation-stop.sh` — the hook implementation (bash, ~120 lines, modeled on `delegation-gate.sh` style + `runtime-capture.sh` flock pattern)
- `.claude/tests/<NNN>-delegation-stop/run.sh` — test harness (follows existing test layout)
- `.claude/tests/<NNN>-delegation-stop/fixtures/*.json` — sample payloads + matching dispatch rows + sidecar `.meta.json` fixtures

**Modify:**
- `.claude/hooks/delegation-gate.sh` — extend audit row with `tool_use_id` (12th field; 2-line patch); preserve all existing tests
- `.claude/settings.json` — register `SubagentStop` hook under `hooks` block
- `.claude/rules/delegation.md` § Audit log — list new 12th dispatch field (`tool_use_id`) + new close row event schema + example `jq` join query

**Untouched (pre-flight surfaced these were misdirections):**
- `.claude/hooks/session-track-edits.sh` — session-scoped tracker is wrong source for per-agent edit count; canonical source is `agent_transcript_path` JSONL

**Delete:** none

## Alternatives considered

### Modify the dispatch row in-place instead of appending a close row

Rejected because JSONL append-only is a load-bearing property for the audit log — multiple sessions write concurrently (via `flock`) and rewriting rows would require seek-and-replace plus locking semantics that bash doesn't handle well. Two rows correlated by `agent_id` keep the file strictly append-only and friendly to `jq -c .` streaming consumers.

### Use `PostToolUse(Agent)` instead of `SubagentStop`

Rejected because `PostToolUse(Agent)` fires when the `Agent` tool's invocation returns to the parent — for the parent, the Agent call is one tool. `SubagentStop` is the actual termination of the sub-agent's internal loop. They might fire at the same wall-clock moment for synchronous dispatches, but `SubagentStop` carries the sub-agent's internal state (loop iterations, final exit cause) that `PostToolUse(Agent)` does not. Use the event designed for the purpose.

### Wait for cost-observability spec (§A6) and bundle them

Rejected because A3 is "alta priority, S effort" while A6 is "média priority, S effort". Bundling forces alta to wait on média; ships nothing on its own. Cost can extend this row in a follow-up (the JSONL row is open-shape; adding `tokens_in`/`tokens_out`/`cost_usd` later is a one-line schema doc update).

### Skip the hook, parse session transcripts post-hoc instead

Rejected because session transcripts are not stable, are gated by Claude Code internal storage, and rotate. The hook is the canonical signal channel. Post-hoc parsing also can't observe loop-budget exhaustion at the right granularity.

## Risks and unknowns

_Pre-flight resolved Open Question #1 (`agent_id` presence), #2 (edit-count source), and #3 (denormalisation). Remaining risks below._

- **Risk: per-sub-agent transcript JSONL schema variance.** Probe-fire-3 was a trivial 3-line transcript (`user/attachment/assistant` with single text block); richer transcripts have nested tool_use content blocks. The `jq` filter needs empirical verification against a real sub-agent that made Edit calls. Mitigation: implement against a real dispatch (e.g. fire a tiny edit-making Explore call during testing), iterate the filter; fall back to `edit_count: null` on any jq error.
- **Risk: `.meta.json` sidecar may not exist for older transcripts.** If an old dispatch's sidecar was never written, the toolUseId bridge fails. Mitigation: sidecar absent → set `tool_use_id: null` in close row, fall back to `(session_id, agent_type, ts ordering)` heuristic for correlation (degraded but functional).
- **Risk: race condition on dispatch + stop firing across processes.** `flock` on the audit log handles append atomicity; but the lookup of dispatch `ts` (to compute `duration_ms`) might read a stale tail. Mitigation: tail-grep is best-effort; if dispatch row isn't found, append close row with `duration_ms: null` and `correlation: "unmatched"`.
- **Risk: `.claude/delegation-audit.jsonl` grows unbounded.** Adding a second row per dispatch doubles growth rate. Already gitignored. Not a regression — file was always going to need rotation eventually. Spec 060 §A6 cost-observability work or a separate rotation spec handles trimming.
- **Risk: `SubagentStop` event schema variance across CC versions.** Empirical capture done 2026-05-19; the field names (`agent_id`, `agent_transcript_path`) may evolve. Mitigation: parse with `// ""` guards; degrade gracefully when fields missing.
- **Risk: the gate-extension might conflict with parallel work on delegation.md.** Spec 062 (/goal skill) and spec 063 (worktree-isolation) both touch the same rule file. Mitigation: this spec lands first per priority order; 062/063 will rebase on top.
- **Unknown: does `SubagentStop` fire for sub-agents that crashed or were interrupted mid-work?** Probe-fire dispatches all completed normally. Behaviour under crash/interrupt isn't covered. Mitigation: if hook fails to find dispatch row → orphan path. If hook fires but `agent_transcript_path` is missing/empty → fail open, `edit_count: null`.

## Research / citations

- Claude Code hooks reference: https://thepromptshelf.dev/blog/claude-code-hooks-complete-reference-2026/ — confirms `SubagentStop` event exists; payload schema details require empirical capture (Open Question #1).
- Existing audit log pattern: `.claude/delegation-audit.jsonl` (current rows for shape reference).
- Hook style reference: `.claude/hooks/delegation-gate.sh` (validation), `.claude/hooks/post-edit-validate.sh` (post-event), `.claude/hooks/runtime-capture.sh` (JSONL append with `flock`).
