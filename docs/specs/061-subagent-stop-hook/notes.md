# 061 — subagent-stop-hook — notes

_Created 2026-05-19._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-19 — parent — empirical hook payload schema captured (resolves spec OQ #1)

Three probe-fire dispatches via Explore + haiku captured payload schemas for `PreToolUse(Agent)`, `SubagentStart`, and `SubagentStop`. Findings (canonical for this spec):

**Mid-session hook registration DID activate immediately**, contrary to `.claude/rules/session-handoff.md` ("Hooks only register on the next session"). Probes in `.claude/settings.local.json` fired on the same-session dispatches. Memory entry should be updated, but is orthogonal to this spec; leaving as observation.

**Payload schema matrix** (all three events share `session_id`, `transcript_path`, `cwd`):

| Field | `PreToolUse(Agent)` | `SubagentStart` | `SubagentStop` |
|---|---|---|---|
| `session_id` | ✓ | ✓ | ✓ |
| `tool_use_id` | ✓ `toolu_01...` | ✗ | ✗ |
| `agent_id` | ✗ | ✓ `aa02e24...` | ✓ same |
| `agent_type` (top-level) | ✗ | ✓ `"Explore"` | ✓ |
| `tool_input.subagent_type` | ✓ `"Explore"` | ✗ | ✗ |
| `tool_input.model` | ✓ when declared | ✗ | ✗ |
| `tool_input.prompt` | ✓ full prompt | ✗ | ✗ |
| `last_assistant_message` | ✗ | ✗ | ✓ (final text) |
| `agent_transcript_path` | ✗ | ✗ | ✓ per-sub-agent JSONL |
| `hook_event_name` | ✓ | ✓ | ✓ |
| `stop_hook_active` | ✗ | ✗ | ✓ bool |
| `permission_mode` | ✗ | ✗ | ✓ |
| `duration_ms` | ✗ | ✗ | ✗ |
| `exit_code` / status | ✗ | ✗ | ✗ |

**`tool_use_id` and `agent_id` are DISJOINT identifiers** that never appear in the same payload. The cleanest correlation bridge is via the per-sub-agent transcript's sidecar `.meta.json`:

```
<agent_transcript_path>          → ...subagents/agent-<agent_id>.jsonl
<agent_transcript_path>.meta.json → {
  "agentType": "Explore",
  "description": "...",
  "toolUseId": "toolu_01CdgjZAKbpEvqF9CxAwiRCK"   ← matches PreToolUse.tool_use_id
}
```

The `.meta.json` sidecar (filename derived: `.jsonl` → `.meta.json` adjacent) is the canonical bridge. At `SubagentStop` time we have `agent_id` + `agent_transcript_path`; read the sidecar → `toolUseId` → join with dispatch row if the gate also captured `tool_use_id`.

**Implication for `delegation-gate.sh` (this spec):** Must extend audit row to include `tool_use_id` (free — already available via `jq -r '.tool_use_id'`; just not currently extracted). Without this, dispatch↔stop correlation degrades to a `(session_id, subagent_type, ts ordering)` heuristic that breaks under parallel same-type dispatches.

**Implication for `delegation-stop.sh` (this spec):** The close row carries `agent_id` (primary) + `tool_use_id` (read from sidecar; secondary join key) + `agent_type` (denorm; matches dispatch row's `subagent_type`) + `session_id` (cross-row) + `last_assistant_message_head` (first 200 chars; denorm for self-contained jq queries) + `agent_transcript_path` (pointer for verbose forensics).

### 2026-05-19 — parent — edit-count source: per-sub-agent transcript JSONL (resolves spec OQ #2)

Originally considered using `.claude/.session-state/<session_id>/edited-files.txt` (populated by `session-track-edits.sh`), but that file is **session-scoped, not agent-scoped** — would conflate parent edits and all sub-agents' edits in the same session. Filtering by timeframe would be heuristic.

The per-sub-agent transcript (`<agent_transcript_path>`) is a JSONL with `{type, message}` entries. Sub-agent tool-use calls live in `assistant`-typed entries where `.message[]` contains `tool_use` content blocks with `.name ∈ {Edit, Write, MultiEdit}`. Counting them is deterministic and per-agent:

```bash
jq -s '[.[] | select(.type=="assistant") | .message[]?
       | select(.type=="tool_use" and (.name=="Edit" or .name=="Write" or .name=="MultiEdit"))]
       | length' "$AGENT_TRANSCRIPT_PATH"
```

(May need adjustment depending on actual JSONL nesting — `.message` is an array per the probe-fire-3 transcript; in richer transcripts it might be a list of mixed types. Empirical test required during implementation. Update plan if shape differs.)

This is BETTER than `session-track-edits.sh` for the per-sub-agent question; the spec's edit_count comes from here, not from the session-scoped tracker. `session-track-edits.sh` stays untouched.

### 2026-05-19 — parent — loop-budget detection: read existing per-agent state file

The delegation-gate.sh already creates `.claude/.delegation-state/agents/<agent_id>/consecutive_failures` when the post-edit validator hits a failure. The stop hook reads this at SubagentStop time:
- If `consecutive_failures >= CLAUDE_DELEGATION_LOOP_BUDGET` (default 5) → `exit: "loop-budget-exceeded"`
- Else → `exit: "ok"`

No new accumulator needed. Cleanup of the state dir can happen at the same time as the stop row write (delete on stop, since the agent is done — its budget is no longer relevant).

### 2026-05-19 — parent — `duration_ms` computed client-side, not harness-provided

Critical finding: `SubagentStop` payload does NOT carry `duration_ms`. Unlike `PostToolUse(Bash)` which carries harness-supplied wall-clock ms, the sub-agent lifecycle events offer no timing field. Computing duration requires:
- Dispatch row's `ts` (already written by gate)
- Stop row's `ts` (write at SubagentStop time)
- `duration_ms = (stop_ts - dispatch_ts) * 1000` via `date -d` epoch math

When the dispatch row can't be located (orphan stop — gate failed to write or audit log was rotated), `duration_ms: null` and `correlation: "unmatched"` in the close row.

### 2026-05-19 — parent — denormalize for self-contained jq queries (resolves spec OQ #3)

Memory pattern from `.claude/rules/runtime-introspect.md` (last-run.json is "self-sufficient"): close row carries `agent_type` (denorm of dispatch's `subagent_type`), short `last_assistant_message_head`, and `agent_transcript_path` pointer. This avoids requiring a join in 80% of forensic queries (`jq -c 'select(.event=="subagent-stop" and .exit=="loop-budget-exceeded")'` works standalone). Full join still available for richer questions.

## Deviations

### 2026-05-19 — parent — scope creep: delegation-gate.sh needs an unrelated extension to be useful

Original spec said the stop hook would be additive and not modify `delegation-gate.sh`. The empirical finding (PreToolUse has `tool_use_id` but doesn't record it) means the dispatch row schema needs extension for exact correlation. This is in-scope for spec 061 — the value of the stop hook is gated on having a correlation key. Adding `tool_use_id` to the gate is one extra `jq -r` and one extra audit-row field; cost is trivial.

Plan.md updated to reflect this: § Approach now starts with the gate extension, then the stop hook, then validator update for the consecutive_failures state path. Files to touch grew by one (`.claude/hooks/delegation-gate.sh`), but the patch is ~3 lines.

### 2026-05-21 — parent — test suite uses inline payload generation, not a `fixtures/` dir

tasks.md task 7 sketched a `fixtures/*.json` layout (one static JSON per scenario). Implementation diverged: each of the 9 scripts in `.claude/tests/061-delegation-stop/` generates its `SubagentStop` payload **inline** (`jq -cn` / heredoc). Reason: the payload's `agent_transcript_path` field must point at a real transcript file inside the per-run `mktemp` dir, and a static fixture cannot encode a path that does not exist until test time. Inline generation is also the established Agent0 test convention — `secrets-scan`, `harness-sync`, `parallel-edit-validation` all build inputs inline; no test dir uses a `fixtures/` subdir. The plan's literal layout was a pre-implementation sketch; the divergence is mechanical, not a design change.

### 2026-05-21 — parent — `tool_use_id: ""` → `null` hook fix surfaced by the missing-sidecar test

Writing `06-missing-sidecar.sh` against spec.md's contract ("close row records `tool_use_id: null`", stated three times across the spec) exposed an impl gap: `delegation-stop.sh` built the field with `jq --arg tool_use_id "$TOOL_USE_ID"`, which yields `""` (empty string) when no sidecar `.meta.json` supplies a `toolUseId` — not `null`. The happy-path e2e (task 10) never caught this because there `tool_use_id` is always non-empty. Fix: the jq object builder maps empty→null inline (`tool_use_id:(if $tool_use_id == "" then null else $tool_use_id end)`) — one line, no new subprocess, `--arg` unchanged. A genuine red→green: the spec is the contract, the test named the contracted behavior, the impl was corrected to match. `null` is also the more correct JSON semantics for an absent identifier than `""`.

## Tradeoffs

### 2026-05-19 — parent — left mid-session hook activation finding for a follow-up memory update, not this spec

The probe-fire dispatches surfaced that mid-session hook registration in `.claude/settings.local.json` activated immediately, which contradicts `.claude/rules/session-handoff.md` ("Hooks only register on the **next** session"). Did NOT spend cycles in this spec verifying whether this is (a) a specific behaviour of `settings.local.json` only, (b) a behaviour change in newer CC, (c) a misreading of the rule (which may refer only to `settings.json`, not `settings.local.json`). Memory entry update deferred — not load-bearing for 061's design. Accepted cost: rule text might still mislead the next developer. Mitigation: this notes.md entry documents the observation; whoever updates memory next can cite it.

## Open questions

_(spec.md § Open questions has been updated to mark OQ #1, #2, #3 as resolved by the design decisions above. No new open questions surfaced during pre-flight.)_
