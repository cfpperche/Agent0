---
name: Claude Code platform hooks
description: Canonical surface of 29 Claude Code hook events and the exit-zero PostToolUse gotcha; consult before designing any hook-based capacity
metadata:
  type: reference
---

The Claude Code hook system exposes **29 event names**, not the ~9 commonly cited. This memory captures the canonical surface, the event semantics (success vs failure), and the meta-lesson behind why this file exists.

Canonical source: <https://code.claude.com/docs/en/hooks> (verified 2026-05-11 via WebFetch).

## Meta-lesson — why this memory exists

**Agent0 spec 011 (runtime-introspect) was shipped with a foundational gap.** The capacity registered `runtime-capture.sh` on `PostToolUse(Bash)` assuming this would capture every Bash invocation. It does NOT: `PostToolUse` fires only on **tool success** (exit 0). For Bash, that means commands exiting non-zero — exactly the FAIL cases the agent most needs evidence for — are silently dropped by spec 011's design. The pyshrnk dogfood (2026-05-11) surfaced this empirically; the fix is to additionally register on `PostToolUseFailure(Bash)`.

The deeper lesson: before designing a new capacity that uses hooks, **read the canonical event list verbatim**. The author of spec 011 was operating with a partial mental model (~9 events) and never validated it against docs. Every future hook-based capacity in Agent0 (and forks) must do better.

## The 29 events

Quoted from the docs Hook lifecycle table:

| Event | Fires when |
| --- | --- |
| `SessionStart` | A new session begins (source: `startup`, `resume`, `clear`, `compact`) |
| `Setup` | Initial project setup |
| `UserPromptSubmit` | User submits a prompt |
| `UserPromptExpansion` | A user prompt gets expanded |
| `PreToolUse` | Before any tool call |
| `PermissionRequest` | A permission prompt is about to show |
| `PermissionDenied` | The user denied a permission |
| `PostToolUse` | **After a tool call succeeds** |
| `PostToolUseFailure` | **After a tool call fails** |
| `PostToolBatch` | After a batch of tool calls completes |
| `Notification` | A notification is being shown |
| `SubagentStart` | A sub-agent starts |
| `SubagentStop` | A sub-agent stops |
| `TaskCreated` | A task is created |
| `TaskCompleted` | A task completes |
| `Stop` | A turn ends |
| `StopFailure` | A turn ends with failure |
| `TeammateIdle` | A teammate session goes idle |
| `InstructionsLoaded` | Instructions get loaded |
| `ConfigChange` | Configuration changes |
| `CwdChanged` | Working directory changes |
| `FileChanged` | A file changes |
| `WorktreeCreate` | A worktree is created |
| `WorktreeRemove` | A worktree is removed |
| `PreCompact` | Before context compaction |
| `PostCompact` | After context compaction |
| `Elicitation` | An elicitation is requested |
| `ElicitationResult` | An elicitation completes |
| `SessionEnd` | The session ends |

Agent0 currently uses **8 of these 29**: `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, `PreCompact`. Spec 020 will add `PostToolUseFailure`. The remaining 21 are unused capacity surfaces.

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

## Cross-references

- `.claude/rules/runtime-introspect.md` — spec 011 capacity that uses `PreToolUse(Bash)` + `PostToolUse(Bash)`; spec 020 will add `PostToolUseFailure(Bash)`.
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
