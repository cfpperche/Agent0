# 023 — session-stop-noop-aware — plan

_Drafted from `spec.md` on 2026-05-12. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two small additive edits to the existing per-`session_id` state directory established by spec 017:

1. **SessionStart writes the snapshot.** After `touch "$STATE_DIR/started-at"` in `.claude/hooks/session-start.sh`, append a single `git status --porcelain` capture to `$STATE_DIR/start-porcelain.txt`. Best-effort: if `git` is absent or the directory write fails, do nothing — Stop hook falls back to today's logic. No new error paths.

2. **Stop compares before blocking.** In `.claude/hooks/session-stop.sh`, after the existing "no porcelain → exit 0" early-out but before the SESSION.md mtime check, add a porcelain comparison: if `$STATE_DIR/start-porcelain.txt` exists AND `cmp -s` against the current `git status --porcelain` output returns 0 (identical), exit 0 silently. Otherwise, fall through to existing logic. The `cmp -s` is a byte-exact comparison — porcelain output is deterministically sorted by git, so identical → no work happened.

The snapshot rides inside the existing per-session state dir; spec 017's 7-day cleanup sweep removes it automatically with the rest of the dir. No new state, no new env vars, no new gitignore entries (spec 017's existing `.claude/.session-state/` ignore covers the new file).

## Files to touch

**Modify:**
- `.claude/hooks/session-start.sh` — after `touch "$STATE_DIR/started-at"`, write porcelain snapshot. Guard with `git rev-parse --git-dir` presence check; silence stderr; never propagate failure (`|| true`).
- `.claude/hooks/session-stop.sh` — between the existing porcelain non-empty check (line 49) and the SESSION.md mtime check (line 54), insert: if `$STATE_DIR/start-porcelain.txt` exists and `cmp -s` matches current porcelain, exit 0.
- `.claude/rules/session-handoff.md` § *State files* — document the new snapshot file, the carryover-discrimination semantic, and the fallback behavior when snapshot is missing.

**Create:**
- `.claude/tests/session-handoff/01-noop-with-carryover.sh` — scenario 1 from spec.
- `.claude/tests/session-handoff/02-edits-without-session-update.sh` — scenario 2.
- `.claude/tests/session-handoff/03-edit-then-revert.sh` — scenario 3.
- `.claude/tests/session-handoff/04-new-untracked-file.sh` — scenario 4.
- `.claude/tests/session-handoff/05-snapshot-missing-fallback.sh` — scenario 6 (graceful degradation).

**Delete:** none.

## Alternatives considered

### mtime sweep — `find` for any file modified after `started-at`

Walk the repo tree (excluding `.claude/.session-state/`, `.git/`, `node_modules/`, etc.) for files with mtime newer than `started-at`. If none, exit 0; else block.

Rejected: misses `git add` of a pre-existing untracked file (mtime unchanged, but porcelain changed — legitimate handoff trigger). Misses `git restore` of an edited file (mtime is bumped by `restore`, the file content went back, the dev's work is gone — porcelain returns to start state; mtime check would still trigger block). The directory walk is also slower and noisier (must exclude paths) than porcelain comparison. Porcelain is git's canonical "what state am I in" signal — use it.

### Track git HEAD SHA at SessionStart

Save `git rev-parse HEAD` at start, compare at Stop. If SHA changed AND porcelain is empty, the session committed work — handoff trigger is the new SHA, not porcelain. If SHA unchanged AND porcelain unchanged, no-op.

Rejected as a *replacement* for porcelain (HEAD comparison can't detect uncommitted/untracked work changes). Could augment in a v2 if the "session committed everything" case needs special UX, but in v1 the porcelain-identical check already handles "committed back to start state" cleanly (porcelain returns to whatever was uncommitted carryover at start; SHA different but porcelain identical → exit 0; correct, because the commit means SESSION.md update is the dev's voluntary choice, not a hook enforcement).

### Tool-call introspection via `transcript_path`

Parse the assistant transcript at Stop hook fire and scan for `tool_use` blocks of type `Edit`/`Write`/`MultiEdit`/`Bash`. If none with side-effect potential fired, exit 0.

Rejected: brittle (transcript shape can drift across Claude Code releases — already observed in spec 011 dogfood and spec 020), expensive (JSONL parse on every Stop), and weaker signal than porcelain (the agent can run side-effect Bash that doesn't change porcelain, e.g. `npm test`). Porcelain is the source-of-truth state signal; the transcript is a noisy approximation.

### SESSION.md content marker — "carryover-acknowledged"

Parse SESSION.md for a `<!-- carryover-acknowledged: <files> -->` marker. If present and matches current carryover, skip the block.

Rejected: requires user discipline to maintain the marker (forget once, false-positive returns), couples Stop hook to SESSION.md schema (currently free-form prose), and doesn't help pure no-op sessions where SESSION.md is irrelevant.

## Risks and unknowns

- **Porcelain output determinism.** `git status --porcelain` (v1 format) sorts entries by path; output is byte-identical for identical state. Verified via `man git-status`. v2 format (`--porcelain=v2`) is also stable. The hook uses default `--porcelain` (v1) for minimal payload. If git changes default output one day (unlikely — v1 is stable contract), the comparison degrades to false-negative (Stop blocks more often) — acceptable failure mode.
- **Race between snapshot write and first user input.** SessionStart runs synchronously and completes before the agent's first turn; by the time any tool fires, the snapshot is on disk. No race.
- **`/compact` and `/resume`.** Both fire `SessionStart` with the same `session_id` (per `.claude/rules/session-handoff.md` § Parallel sessions). The existing logic touches `started-at` and removes `nagged` on every SessionStart; the new logic OVERWRITES the snapshot. This is correct: post-compact, the porcelain at compact-resume-time IS the new baseline; pre-compact work should already be either committed or noted in SESSION.md by then. Document this explicitly in the rule update.
- **Permission to write the state dir.** Spec 017 ensures `mkdir -p "$STATE_DIR"` runs in SessionStart. If it succeeds (typical case), the snapshot write succeeds too. Edge case: read-only filesystem — both `touch` and snapshot write fail; entire session-state machinery is degraded. Acceptable — environment is broken regardless.
- **First-session-after-upgrade.** A user pulls the spec 023 change mid-session; the snapshot was never written this session because the old SessionStart ran. Stop falls back to today's logic. One transitional false-positive per session, then stable. Documented.
- **Concurrent parallel sessions.** Each session_id has its own state dir and snapshot. Snapshots do not collide. Spec 017 invariant.
- **`unknown` session_id collision.** When session_id is malformed or missing, both hooks fall to literal `unknown` subdir (spec 017). Two concurrent sessions both falling to `unknown` would share a snapshot — Session B's SessionStart overwrites Session A's snapshot. At Session A's Stop, the snapshot is wrong (reflects B's start state). Edge case is identical to today's `nagged`-marker collision under `unknown` — accepted in spec 017. Not a regression.

## Research / citations

- `man git-status` — confirms `--porcelain` output is stable and sorted.
- `.claude/hooks/session-stop.sh` lines 38-56 — existing decision tree the spec amends.
- `.claude/hooks/session-start.sh` lines 37-40 — insertion point for the snapshot write.
- `docs/specs/017-session-state-isolation/spec.md` — established the per-`session_id` state dir.
- `.claude/rules/session-handoff.md` § State files — current documentation of the state file layout.
- Live observation 2026-05-12 — session that triggered this spec (this conversation).
