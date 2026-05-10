# Session handoff

`.claude/SESSION.md` is the working handoff between Claude Code sessions. The harness enforces it via hooks in `.claude/settings.json`:

- **`SessionStart` hook** (`.claude/hooks/session-start.sh`) injects the current `SESSION.md` into context — so prior context is always present without anyone reading it manually.
- **`Stop` hook** (`.claude/hooks/session-stop.sh`) blocks once per session if the repo has uncommitted changes but `SESSION.md` was not updated. The block injects a reminder; you write the update and end the turn normally. Blocks at most once per session — no infinite loops.

## What to write in SESSION.md

Update before ending a session that touched the repo. Suggested sections (free-form prose, all optional):

- **Current state** — what's working, what's broken, what's in flight
- **WIP** — code/changes left mid-stream that need finishing next time
- **Next steps** — concrete tasks for the next session
- **Decisions & gotchas** — non-obvious choices made, traps discovered, things future-you would want to know

Keep it short and scan-able. The goal is a brief for the next session, not a journal. Replace stale content rather than appending — `git log` is the audit trail.

## What NOT to put here

- Code snippets that belong in actual source files
- Long narratives — keep entries terse
- Anything already captured in commit messages or CLAUDE.md

## Escape hatch

Set `CLAUDE_SKIP_SESSION_HOOKS=1` in the environment to disable Stop-hook enforcement (e.g., for quick Q&A sessions where no commit is intended). The SessionStart injection still runs.

## State files

`.claude/.session-state/` holds two ephemeral markers (`started-at`, `nagged`). Gitignored — do not commit.
