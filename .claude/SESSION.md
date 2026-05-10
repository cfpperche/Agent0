# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Session-handoff infrastructure installed and tested:

- `.claude/SESSION.md` — this file (the handoff itself)
- `.claude/hooks/session-start.sh` — injects this file as additionalContext on every session start
- `.claude/hooks/session-stop.sh` — blocks once per session if repo has uncommitted changes but this file wasn't updated
- `.claude/rules/session-handoff.md` — protocol doc
- `.claude/settings.json` — hooks registered under `SessionStart` and `Stop`

Statusline runtime state moved from `.agent/runtime/` to `.claude/.runtime/` — the `.agent/` directory no longer exists in this project.

## WIP

Nothing in flight.

## Next steps

- User to decide whether to commit the changes (5 files: settings.json, .gitignore, statusline.mjs, plus new SESSION.md / hooks/ / rules/session-handoff.md).
- After committing, exit and re-enter Claude Code to confirm hooks fire end-to-end in a real session (current session was started before hooks were registered, so they don't fully apply here).

## Decisions & gotchas

- Hooks only activate on the **next** session start. Settings.json changes mid-session don't retro-register hooks.
- `.claude/.runtime/` and `.claude/.session-state/` are ephemeral runtime state — gitignored, never commit.
- Escape hatch: `CLAUDE_SKIP_SESSION_HOOKS=1` disables Stop-hook enforcement (useful for quick Q&A sessions).
- Stop hook detects "work happened" via `git status --porcelain` — purely conversational sessions (no file edits) won't trigger enforcement.
- Stop hook blocks at most once per session (tracked via `.claude/.session-state/nagged` marker reset at SessionStart).
- Statusline file `.claude/presence/statusline.mjs` is Apache-2.0 derived from agent-core (same author, cfpperche). Attribution comment retained at top of file; no runtime coupling to agent-core remains.
