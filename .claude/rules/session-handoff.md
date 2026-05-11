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

`.claude/.session-state/<session_id>/` holds two ephemeral markers per Claude Code session: `started-at` (touched by `SessionStart`) and `nagged` (touched by `Stop` when it blocks). Gitignored — do not commit. Spec 017 introduced the per-`session_id` subdir layout to isolate parallel sessions; before that, both markers lived directly under `.claude/.session-state/` and any SessionStart fire from any session would `rm -f` the shared `nagged` marker, leading to spurious re-blocks of unrelated sessions.

`session_id` comes from the stdin payload Claude Code passes to every hook (`$.session_id`). When absent (older payload shapes, future variants, manual fixtures), or when it contains characters outside `^[a-zA-Z0-9_-]+$`, both hooks fall to the literal subdir `unknown` — predictable degradation, no path traversal possible.

`SessionStart` also runs a best-effort cleanup at the end: `find .claude/.session-state -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +`. Crashed sessions leave orphan subdirs; this sweep removes them within a week without manual intervention. Cleanup failures are silenced — never block the hook.

## Parallel sessions and other start triggers

The "block at most once per session" guarantee is keyed on `session_id`. `session_id` persists through:

- **`/compact` (manual or auto-compact in 1M-context Opus)** — `source=compact` SessionStart fires, but the `session_id` is identical. So `<id>/nagged` survives the compaction; the agent isn't re-blocked unless `SESSION.md` becomes stale again relative to the touched `<id>/started-at`.
- **`/resume` of a paused conversation** — `source=resume`, same `session_id`, same nag state preserved.
- **Multiple concurrent Claude Code sessions in the same project** — each gets its own `session_id` and its own subdir. Session A's nag is never reset by Session B's SessionStart.

`session_id` is regenerated (fresh UUID) only on `source=startup` (new conversation) and after `/clear` (lifecycle reset). Those are the right moments for a fresh nag cycle.

## Cross-capacity dependency

`.claude/tools/probe.sh` (spec 011 runtime-introspect) reads `started-at` as the "session boundary" signal to detect stale snapshots. Post-017 it does NOT read a specific subdir — instead it scans `.claude/.session-state/*/started-at` and takes the maximum mtime as the conservative boundary. Single-session use: identical behavior to pre-017. Parallel sessions: `stale=true` may trigger earlier in the older session (a conservative false positive — agent re-runs the verifier, safe direction).
