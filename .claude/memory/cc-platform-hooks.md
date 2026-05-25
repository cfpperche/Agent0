---
name: Claude Code platform hooks
description: Canonical surface of 29 Claude Code hook events and the exit-zero PostToolUse
  gotcha; consult before designing any hook-based capacity
metadata:
  type: reference
  created_at: '2026-05-11T19:33:20-03:00'
  last_accessed: '2026-05-25'
  confirmed_count: 0
---

The Claude Code hook system exposes **29 event names**, not the ~9 commonly cited. This memory captures the canonical surface, the event semantics (success vs failure), and the meta-lesson behind why this file exists.

Canonical source: <https://code.claude.com/docs/en/hooks> (verified 2026-05-25 via cc-platform-audit routine — upstream lifecycle table enumerates exactly 29 events; the "32" narrative carried over from the 2026-05-19 audit was a count drift against an unchanged 29-row table, now reconciled. `PermissionDenied`, `TaskCreated`, `TaskCompleted` remain present and documented as in the 2026-05-19 snapshot).

## Meta-lesson — why this memory exists

**Agent0 spec 011 (runtime-introspect) was shipped with a foundational gap.** The capacity registered `runtime-capture.sh` on `PostToolUse(Bash)` assuming this would capture every Bash invocation. It does NOT: `PostToolUse` fires only on **tool success** (exit 0). For Bash, that means commands exiting non-zero — exactly the FAIL cases the agent most needs evidence for — are silently dropped by spec 011's design. The pyshrnk dogfood (2026-05-11) surfaced this empirically. **Spec 020 fixed it** by additionally registering `runtime-capture.sh` on `PostToolUseFailure(Bash)` AND teaching the hook the divergent payload shape that event uses (see § "Payload shape" below).

The deeper lesson: before designing a new capacity that uses hooks, **read the canonical event list verbatim**. The author of spec 011 was operating with a partial mental model (~9 events) and never validated it against docs. Every future hook-based capacity in Agent0 (and forks) must do better.

Second-order lesson from spec 020 itself: even with the right event registered, **payload shape across related events is NOT guaranteed to be identical**. Spec 020's plan-phase assumption ("`PostToolUseFailure` shape parity with `PostToolUse` — no documented reason to invent a different schema") was wrong. The dump-probe in Phase 3 was the cheap way to surface the divergence; the alternative (assume parity, ship, wait for downstream dogfood to break) would have wasted a fork-sync cycle. **When integrating with an unfamiliar event, write a dump-probe first.** Cost: ~5 min. Value: removes a class of "test passes locally, breaks in production" surprises.

## The 29 events

Quoted from the docs Hook lifecycle table (last audited 2026-05-25 via the cc-platform-audit routine):

| Event | Fires when |
| --- | --- |
| `SessionStart` | A new session begins (source: `startup`, `resume`, `clear`, `compact`) |
| `Setup` | Initial project setup |
| `UserPromptSubmit` | User submits a prompt |
| `UserPromptExpansion` | A user prompt gets expanded |
| `PreToolUse` | Before any tool call |
| `PermissionRequest` | A permission prompt is about to show |
| `PermissionDenied` | A permission was denied — returns a unique `retry` decision (only event of its kind; see § Non-obvious gotchas) |
| `PostToolUse` | **After a tool call succeeds** |
| `PostToolUseFailure` | **After a tool call fails** |
| `PostToolBatch` | After a batch of tool calls completes |
| `Notification` | A notification is being shown |
| `SubagentStart` | A sub-agent starts |
| `SubagentStop` | A sub-agent stops |
| `TaskCreated` | A managed-task is created (task management surface; can block via exit 2) |
| `TaskCompleted` | A managed-task completes (task management surface; can block via exit 2) |
| `Stop` | A turn ends |
| `StopFailure` | A turn ends with failure (output AND exit code are ignored — read-only logging surface) |
| `TeammateIdle` | A teammate session goes idle |
| `InstructionsLoaded` | Instructions get loaded |
| `ConfigChange` | Configuration changes (cannot block `policy_settings`) |
| `CwdChanged` | Working directory changes |
| `FileChanged` | A file changes (matcher = literal filenames, NOT tool name) |
| `WorktreeCreate` | A worktree is created (success = print path to stdout; any non-zero exit FAILS creation) |
| `WorktreeRemove` | A worktree is removed |
| `PreCompact` | Before context compaction |
| `PostCompact` | After context compaction |
| `Elicitation` | An elicitation is requested (uses form-driven `action` + `content` payload) |
| `ElicitationResult` | An elicitation completes (same form-driven shape) |
| `SessionEnd` | The session ends |

Agent0 currently uses **8 of these 29** (counted from `.claude/settings.json`):

- `PreToolUse` (5 matchers: governance-gate, secrets-scan, supply-chain-scan, runtime-pre-mark, delegation-gate)
- `PostToolUse` (5 matchers: post-edit-validate, secrets-advise, supply-chain-advise, session-track-edits, runtime-capture)
- `PostToolUseFailure` (runtime-capture, added by spec 020)
- `SessionStart` (4 hooks: session-start, reminders-readout, mcp-recipes-hint, routines-readout — spec 064)
- `Stop` (session-stop)
- `SubagentStop` (delegation-stop, added by spec 061)
- `PreCompact` (pre-compact)
- `InstructionsLoaded` (rule-load-debug, opt-in)

The remaining 21 are unused capacity surfaces. Notable underexplored ones: `WorktreeCreate`/`WorktreeRemove` (spec 063 territory), `TaskCreated`/`TaskCompleted` (potential hook surface for /goal + task tracking integrations), `Elicitation`/`ElicitationResult` (MCP form workflows), `FileChanged` (file-watcher capacity not yet built).

## Exit-code semantics for PostToolUse / PostToolUseFailure

- **`PostToolUse(Bash)`** fires only when the underlying Bash command exits **0**. Piping through `tail`/`cat`/`tee` absorbs a non-zero exit and the pipeline exits 0 — the hook fires for the pipeline.
- **`PostToolUseFailure(Bash)`** fires only when the underlying Bash command exits **non-zero**. The two events partition the outcome space; together they cover every Bash invocation.
- **Either hook firing exit 2** has different behavior: `PostToolUse` exit 2 can block downstream (matters for `Edit`/`Write`/`MultiEdit` consumers), but `PostToolUseFailure` cannot block (the tool already failed) — its stderr is just shown to the agent for context.

## Payload shape — events Agent0 currently uses

For all PreToolUse/PostToolUse/PostToolUseFailure events, stdin JSON includes:
- `session_id` — string, stable across `/resume` and `/compact`, regenerated on new sessions and `/clear`
- `transcript_path` — path to the conversation JSONL
- `tool_name` — string (e.g. `"Bash"`, `"Edit"`)
- `tool_input` — object, shape depends on tool
- `tool_response` — present on PostToolUse / PostToolUseFailure; shape varies by tool
- `tool_use_id` — unique per tool call; lets PreToolUse and PostToolUse correlate (used by `.claude/hooks/runtime-pre-mark.sh` for duration measurement)
- `duration_ms` — present on PostToolUse / PostToolUseFailure (real wall-clock ms, harness-provided)
- `effort` — object `{level: "low"|"medium"|"high"|"xhigh"|"max"}`, present on `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop` when the model supports effort levels (Opus 4.x family). Verified 2026-05-19 via cc-platform-audit second-run.
- `agent_id`, `agent_type` — present when running under `--agent` flag OR inside a sub-agent dispatched via the `Agent` tool. `agent_type` is the dispatched subagent name (e.g. `"Explore"`, `"general-purpose"`). Used by `.claude/hooks/delegation-gate.sh` for parent-vs-subagent attribution and by `.claude/hooks/session-track-edits.sh` to scope edits per actor.

For `SessionStart`, `Setup`, `CwdChanged`, `FileChanged`: also supports `CLAUDE_ENV_FILE` env-var bridging — hooks can write `KEY=value` lines to `$CLAUDE_ENV_FILE` for persistence across subsequent Bash command shells in the same session. Documented at canonical docs 2026-05-19; Agent0 does not currently use this mechanism but it's a candidate surface for cross-Bash-call state propagation.

**Bash `tool_response` shape (verified live-dogfood):**

```json
{
  "stdout": "...",
  "stderr": "...",
  "interrupted": false,
  "isImage": false,
  "noOutputExpected": false
}
```

**Note:** Claude Code's Bash `tool_response` does NOT include an `exit_code` field. Status inference is required (see `.claude/rules/runtime-introspect.md` § Inference heuristics and `.claude/hooks/runtime-capture.sh`).

**PostToolUseFailure(Bash) payload diverges (verified empirically 2026-05-11 by spec 020 dump-probe).** Under tool failure, the stdin payload to the hook script does NOT contain a `tool_response` field at all. Instead:

```json
{
  "session_id": "...",
  "transcript_path": "...",
  "cwd": "...",
  "permission_mode": "...",
  "hook_event_name": "PostToolUseFailure",
  "tool_name": "Bash",
  "tool_input": {"command": "...", "description": "..."},
  "tool_use_id": "...",
  "error": "<entire failure output as a single string — harness has already merged stdout+stderr+exit-code-line>",
  "is_interrupt": false,
  "duration_ms": 78
}
```

Key differences from `PostToolUse`:
- `tool_response` is **absent**
- Failure body is at top-level `.error` (single string, harness-merged)
- `is_interrupt` (boolean) replaces `tool_response.interrupted`
- `hook_event_name: "PostToolUseFailure"` is present — used by shared hook scripts to dispatch on event identity

`session_id`, `transcript_path`, `cwd`, `tool_name`, `tool_input`, `tool_use_id`, `duration_ms` carry over unchanged. `tool_use_id` correlates with the corresponding `PreToolUse` stamp — `runtime-pre-mark.sh`'s in-flight mark is read and removed correctly.

## Empirical: `InstructionsLoaded` intra-session dedup (rule-scope, not glob-scope)

Validated 2026-05-13 across Agent0 + shrnk-mono fork dogfood. Once a path-scoped rule loads in a session — via any matching glob — **subsequent reads of any file matching ANY of that rule's globs produce NO new `InstructionsLoaded` event**. The dedup is scoped to the rule (one event per session per rule), not to the specific glob that triggered the first load.

First-pass observation framed this as a multi-glob-on-same-rule quirk (e.g. `.claude/tools/probe.sh` is in BOTH `runtime-introspect.md`'s globs AND `rule-load-debug.md`'s globs; reading `probe.sh` after `runtime-pre-mark.sh` was already read fires only `rule-load-debug.md`'s event). Shrnk-mono Step 3d expanded the picture: editing `package.json` (matches `supply-chain.md`'s `**/package.json` glob) after an earlier batch read of `.claude/hooks/supply-chain-scan.sh` (matches `supply-chain.md`'s `supply-*.sh` glob) produced NO new path_glob_match row — even though the second trigger is a completely different file and a completely different glob within the same rule. Dedup is per-rule, period.

Implication for path-scoping validation playbooks:
- A trigger→rule mapping table is only fully exercisable in a fresh session per trigger.
- Multi-trigger dogfood reads (Step 2 style) work because the FIRST matching trigger per rule fires; subsequent matches dedupe silently.
- "Edit foo to verify it triggers rule X" only works if rule X hasn't already loaded this session. Prior reads / SessionStart-by-source-resume could have loaded it.

This is correct CC behavior (avoids audit-log inflation and context waste); not a regression. Documented also in `.claude/rules/rule-load-debug.md` § Gotchas.

## Cross-references

- `.claude/rules/runtime-introspect.md` — spec 011 capacity that uses `PreToolUse(Bash)` + `PostToolUse(Bash)`; spec 020 added `PostToolUseFailure(Bash)`.
- `.claude/rules/rule-load-debug.md` — uses `InstructionsLoaded`; opt-in observability for the dedup behavior documented in § Empirical above.
- `.claude/rules/secrets-scan.md` — uses `PreToolUse(Bash)` (preflight shape gate); doesn't depend on the success/failure split.
- `.claude/rules/supply-chain.md` — uses `PreToolUse(Bash)` (block) + `PostToolUse(Edit|Write|MultiEdit)` (advisory).
- `.claude/rules/delegation.md` — uses `PreToolUse(Agent)` + `PostToolUse(Edit|Write|MultiEdit)`.
- `.claude/rules/compaction-continuity.md` — uses `PreCompact` + `SessionStart` (with `source: "compact"`).
- `.claude/rules/session-handoff.md` — uses `SessionStart` + `Stop`.
- `.claude/rules/reminders.md` — uses `SessionStart`.

## How to use this memory

When you (agent or developer) are about to design a capacity that touches hook events:

1. Find the relevant event in the table above. If it's not in Agent0's "currently uses" list, you're entering new territory.
2. Read the canonical docs at <https://code.claude.com/docs/en/hooks> for the precise semantics — this memory captures the surface as of 2026-05-11, but the docs evolve. Trust the canonical source over this snapshot if they disagree.
3. Consider the success/failure split: does your hook need to fire on both? Most edit-validation hooks want both; most preflight hooks only care about `PreToolUse`.
4. Update this memory if you discover new event semantics, payload shapes, or behavior gaps. The next agent designing a hook capacity reads this first.
