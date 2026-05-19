# 061 — subagent-stop-hook — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Mirror the structure of `.claude/hooks/delegation-gate.sh`: bash, zero external dependencies beyond `jq`, fail-open on any error, append a single JSONL row to `.claude/delegation-audit.jsonl`. The hook reads the `SubagentStop` event payload from stdin (Claude Code hook convention), extracts `agent_id`/`session_id`/`tool_use_id`, computes `duration_ms` against the dispatch row's `ts` (looked up by `agent_id` via `jq` filter on the audit log tail), counts edits from `.claude/.delegation-state/agents/<agent_id>` if present, and writes the close row.

Order of operations:

1. Resolve hook payload schema empirically — fire a no-op `Agent` call, capture stdin payload to a scratch file, verify `agent_id` presence + format. This answers Open Question #1 before code is written.
2. Read `.claude/hooks/session-track-edits.sh` to determine how (or whether) per-agent edit counts are already accumulated. Resolution informs the `edit_count` source.
3. Write `delegation-stop.sh` following the canonical Agent0 hook shape: `set -euo pipefail`, `CLAUDE_PROJECT_DIR` resolution, `jq` payload parse with `// empty` guards, `flock`-protected append to JSONL.
4. Register in `.claude/settings.json` under `hooks.SubagentStop[].hooks[]` with `type: "command"` and `command: "bash $CLAUDE_PROJECT_DIR/.claude/hooks/delegation-stop.sh"`.
5. Tests in `.claude/tests/<NNN>-delegation-stop/` — pure-bash assertions piping fake stdin JSON, asserting JSONL row shape via `jq`. Mirror pattern from existing `delegation-gate` tests.
6. Update `.claude/rules/delegation.md` § Audit log: document the closing row schema, note the correlation key (`agent_id` → dispatch row), add an example `jq` query that joins open + close rows.

The hook is opt-in by default? **No — register globally.** The audit log is already opt-in by ignoring it; adding rows doesn't increase friction. Forks that disable the gate also disable this hook.

## Files to touch

**Create:**
- `.claude/hooks/delegation-stop.sh` — the hook implementation (bash, ~80 lines, modeled on `delegation-gate.sh` style)
- `.claude/tests/<NNN>-delegation-stop/run.sh` — test harness (follows existing test layout)
- `.claude/tests/<NNN>-delegation-stop/fixtures/*.json` — sample payloads (ok / loop-exceeded / no-edits / malformed)

**Modify:**
- `.claude/settings.json` — register `SubagentStop` hook (preserve existing array shape; structured merge per sync-harness conventions)
- `.claude/rules/delegation.md` § Audit log — extend schema doc with the new row event type + fields
- `.claude/hooks/session-track-edits.sh` — IF the open-question resolution requires it (adding a per-agent edit accumulator); ideally untouched

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

- **Risk: `SubagentStop` event schema variance.** The hook payload schema across Claude Code versions might change `agent_id` to `subagent_id` or similar. Mitigation: parse both, fall back gracefully, log unknown shape to stderr but exit 0.
- **Risk: race condition on dispatch + stop firing across processes.** `flock` on the audit log handles this for appends; but the lookup of dispatch `ts` (to compute `duration_ms`) might read a stale tail. Mitigation: tail-grep is best-effort; if dispatch row isn't found, append close row with `duration_ms: null` and `correlation: "unmatched"`.
- **Risk: `.claude/delegation-audit.jsonl` is gitignored AND grows unbounded.** Adding a second row per dispatch doubles growth rate. Not a regression — the file was already going to need rotation eventually. Spec 060 §A6 cost-observability work or a separate rotation spec handles trimming.
- **Unknown: does the parent's `Agent` tool call count `PreToolUse(Agent)` once even when the sub-agent makes multiple `Edit` calls internally?** Yes (verified from delegation-gate.sh design) — `PreToolUse(Agent)` is per-dispatch, not per-sub-agent-tool-use. `SubagentStop` is symmetric.

## Research / citations

- Claude Code hooks reference: https://thepromptshelf.dev/blog/claude-code-hooks-complete-reference-2026/ — confirms `SubagentStop` event exists; payload schema details require empirical capture (Open Question #1).
- Existing audit log pattern: `.claude/delegation-audit.jsonl` (current rows for shape reference).
- Hook style reference: `.claude/hooks/delegation-gate.sh` (validation), `.claude/hooks/post-edit-validate.sh` (post-event), `.claude/hooks/runtime-capture.sh` (JSONL append with `flock`).
