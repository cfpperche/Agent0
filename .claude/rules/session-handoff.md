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

`.claude/.session-state/<session_id>/` holds three ephemeral artifacts per Claude Code session: `started-at` (touched by `SessionStart`), `nagged` (touched by `Stop` when it blocks), and `start-porcelain.txt` (a snapshot of `git status --porcelain` captured by `SessionStart` — spec 023). Gitignored — do not commit. Spec 017 introduced the per-`session_id` subdir layout to isolate parallel sessions; before that, both markers lived directly under `.claude/.session-state/` and any SessionStart fire from any session would `rm -f` the shared `nagged` marker, leading to spurious re-blocks of unrelated sessions.

`session_id` comes from the stdin payload Claude Code passes to every hook (`$.session_id`). When absent (older payload shapes, future variants, manual fixtures), or when it contains characters outside `^[a-zA-Z0-9_-]+$`, both hooks fall to the literal subdir `unknown` — predictable degradation, no path traversal possible.

`SessionStart` also runs a best-effort cleanup at the end: `find .claude/.session-state -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +`. Crashed sessions leave orphan subdirs; this sweep removes them within a week without manual intervention. Cleanup failures are silenced — never block the hook. The porcelain snapshot rides inside the same subdir, so the 7-day sweep removes it atomically with the rest of the state — no separate TTL.

### Carryover discrimination (spec 023)

Pre-023 the Stop hook treated `git status --porcelain` returning non-empty as "this session has WIP that needs a SESSION.md handoff" — but the signal conflates three cases: real WIP, pre-existing carryover from prior sessions (already documented), and pure no-op sessions (greeting / Q&A / read-only Bash). Spec 023 closes the false-positive on cases (2)/(3): SessionStart writes `start-porcelain.txt` (best-effort — guarded by `git rev-parse --git-dir` plus `|| true` on the redirect; absent if git is unavailable or the filesystem is read-only); Stop compares the current porcelain against the snapshot via bash string equality before applying the SESSION.md mtime check. Byte-identical → nothing changed this session → exit 0 silently. Different → fall through to today's block-unless-SESSION-updated path.

Missing snapshot (older session that started before 023 landed, or git/fs failure at SessionStart) is the safe-fallback case: Stop skips the comparison and the original mtime-only logic runs. Same conservative posture as the rest of the session-state machinery.

`/compact` and `/resume` both fire `SessionStart` with the same `session_id`, so the snapshot is **overwritten** at compaction-resume time — the porcelain at that moment becomes the new baseline. Correct: pre-compact work should already be committed or noted in SESSION.md by then. `CLAUDE_SKIP_SESSION_HOOKS=1` short-circuits both hooks; no snapshot is written; the next session without the env var sees no snapshot → fallback.

## Parallel sessions and other start triggers

The "block at most once per session" guarantee is keyed on `session_id`. `session_id` persists through:

- **`/compact` (manual or auto-compact in 1M-context Opus)** — `source=compact` SessionStart fires, but the `session_id` is identical. So `<id>/nagged` survives the compaction; the agent isn't re-blocked unless `SESSION.md` becomes stale again relative to the touched `<id>/started-at`.
- **`/resume` of a paused conversation** — `source=resume`, same `session_id`, same nag state preserved.
- **Multiple concurrent Claude Code sessions in the same project** — each gets its own `session_id` and its own subdir. Session A's nag is never reset by Session B's SessionStart.

`session_id` is regenerated (fresh UUID) only on `source=startup` (new conversation) and after `/clear` (lifecycle reset). Those are the right moments for a fresh nag cycle.

## Parallel WIP coordination

When you intentionally open a second Claude Code session on the same project to work in parallel (e.g. spec curation in one session while another runs dogfood passes), use a `## Parallel WIP` block in `SESSION.md` to signal what each session owns. The block is the lightest possible coordination layer: zero new tooling, zero hooks, zero state files. SESSION.md is already auto-injected at SessionStart of every new session, so the signal reaches the next agent for free.

Shape:

```markdown
## Parallel WIP

- session opened 2026-05-12 11:00 — curating spec 021 browser-auth-workflow
  (touching `.claude/rules/mcp-recipes.md`, `.claude/rules/secrets-scan.md`,
  `docs/specs/021-*/`). Other sessions: defer these paths until this block
  is removed.
```

Conventions:

- **One bullet per active parallel session.** ISO date + short intent + path list + clear "defer" instruction.
- **The session opening parallel work writes the bullet.** Then commits SESSION.md immediately so the change is visible to the next session that starts. If the opener forgets, the user can do it themselves — same shape.
- **The session removes its bullet when work is committed and merged.** The bullet is a live claim, not a journal. Stale bullets are noise.
- **The block disappears entirely when no parallel work is in flight.** Don't keep an empty `## Parallel WIP` section as scaffolding.
- **Other sessions read SESSION.md (always auto-injected) and respect the block.** If you must edit a deferred path anyway (e.g. fixing a typo unrelated to the spec), say so in your commit message so the parallel-session owner can reconcile on merge.

When the convention is enough vs when it isn't:

- Two concurrent sessions, each on a different spec / different file area → convention covers it.
- Two concurrent sessions racing on the SAME file → convention is advisory; coordinate via the user or pause one session.
- More than two concurrent sessions → still works but the bullet count grows; if this becomes routine, that's the empirical signal to consider richer machinery (a follow-up spec). Don't pre-build.

This is deliberately a behavioural convention rather than a code-enforced one. Spec 017 (`session-state-isolation`) gave each session its own state directory; this convention closes the remaining gap (cross-session intent visibility) at zero code cost. If real-world use surfaces collisions the convention can't catch — recurring forgotten bullets, fixed-on-merge surprises, sessions that genuinely need to touch the same paths — that's the trigger to revisit; until then, keep the surface tiny.

## Cross-capacity dependency

`.claude/tools/probe.sh` (spec 011 runtime-introspect) reads `started-at` as the "session boundary" signal to detect stale snapshots. Post-017 it does NOT read a specific subdir — instead it scans `.claude/.session-state/*/started-at` and takes the maximum mtime as the conservative boundary. Single-session use: identical behavior to pre-017. Parallel sessions: `stale=true` may trigger earlier in the older session (a conservative false positive — agent re-runs the verifier, safe direction).
