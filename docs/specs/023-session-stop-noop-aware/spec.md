# 023 — session-stop-noop-aware

_Created 2026-05-12._

**Status:** shipped

## Intent

The Stop hook (`.claude/hooks/session-stop.sh`) today blocks at session end when the repo has uncommitted changes AND `SESSION.md` was not modified during the session (mtime newer than `started-at`). The single signal `git status --porcelain` returns non-empty conflates three distinct cases that have different correct responses:

1. **Real WIP this session created** — handoff update is legitimate; block is correct.
2. **Pre-existing carryover from prior sessions** — already documented in SESSION.md; no new information; block is noise.
3. **Pure no-op sessions** (greeting, status check, read-only Q&A) — nothing happened; block forces meaningless SESSION.md edit.

Observed live on 2026-05-12: session opened with `voltei` (one-word greeting), agent responded with status summary, zero edits. The hook blocked because `.gitignore` (carryover from earlier session, documented) and `docs/specs/010-audit-forensics/` (paused parallel WIP, documented) showed in porcelain. The block forced a SESSION.md edit whose only content was "no work done this session" — pollution.

The fix discriminates case (2)/(3) from case (1) by snapshotting `git status --porcelain` at SessionStart and comparing at Stop: if the porcelain is byte-identical to the start-of-session snapshot, **nothing changed during this session** → exit 0 silently. Otherwise, today's logic continues. Zero behavior change for the cases the hook exists to catch; eliminates the false-positive on no-op or read-only sessions.

## Acceptance criteria

- [ ] **Scenario: no-op session with pre-existing carryover**
  - **Given** the repo has uncommitted changes when the session starts (e.g. `.gitignore` modified, untracked spec dir)
  - **When** the session performs no edits, no `git add`, no `git restore` — pure Q&A / status / read-only Bash
  - **Then** the Stop hook does NOT block (exit 0); SESSION.md is not forcibly edited

- [ ] **Scenario: session edits a file without updating SESSION.md**
  - **Given** the session begins with any porcelain state (clean or carryover)
  - **When** the agent edits a tracked or untracked file (porcelain changes)
  - **Then** the Stop hook blocks once with the existing reminder reason (behavior preserved)

- [ ] **Scenario: session edits then reverts via `git restore`**
  - **Given** the session begins with porcelain state P
  - **When** the agent modifies a file then runs `git restore` (or equivalent) returning to state P
  - **Then** the Stop hook does NOT block (porcelain identical to start snapshot)

- [ ] **Scenario: session adds new untracked file**
  - **Given** the session begins with porcelain state P
  - **When** a new untracked file appears (test fixture, screenshot, log)
  - **Then** the Stop hook blocks (porcelain changed; new artifact warrants handoff decision)

- [ ] **Scenario: session commits everything mid-session**
  - **Given** the session begins with porcelain state P containing uncommitted work
  - **When** the agent commits the work; porcelain returns to P (or shrinks)
  - **Then** the Stop hook's behavior matches today's: if SESSION.md was updated this session OR porcelain is unchanged from start snapshot, no block; else block

- [ ] **Scenario: SessionStart cannot write the snapshot**
  - **Given** the SessionStart hook runs but `git` or write to state dir fails
  - **When** the Stop hook runs at session end
  - **Then** the Stop hook falls back to today's logic (mtime-based check); failure mode is conservative (block in ambiguity)

- [ ] `.claude/.session-state/<session_id>/start-porcelain.txt` is written by SessionStart on every fresh session (best-effort; failure silent)
- [ ] `.claude/.session-state/` remains gitignored (spec 017 invariant preserved); the new snapshot file inherits the ignore
- [ ] `.claude/rules/session-handoff.md` § State files documents the new snapshot and the carryover-discrimination semantic
- [ ] Snapshot survives `/compact` and `/resume` (same `session_id`, same state dir) — agent re-enters the session with handoff continuity intact

## Non-goals

- Tool-call introspection — no transcript parsing to detect "did Edit/Write fire". The porcelain delta is a strictly stronger signal because it includes Bash side effects (e.g. `git add`, file creation via shell redirect) that a tool-call scan would miss.
- SESSION.md content parsing — no "carryover-acknowledged" marker convention. The hook stays content-blind.
- Per-file granularity — Stop does not name which files changed. The porcelain delta is a binary signal (changed / not changed); detail is the dev's job via `git status` / `git diff`.
- Auditing avoided false-positives. The hook stays sub-1ms, no JSONL writes.
- Retrofitting old sessions. A session started before the snapshot landed has no `start-porcelain.txt`; falls back to today's logic. Acceptable one-time degradation per session.
- Cross-session porcelain inheritance. Each session_id gets its own snapshot. A new session sees the porcelain at its OWN start, not the previous session's start.

## Open questions

_All resolved 2026-05-12 (defaults accepted)._

- [x] **Q1: Snapshot empty when git unavailable.** Resolved: write no file. Explicit absence triggers fallback to today's logic; an empty-snapshot match would silently disable the hook when git breaks. SessionStart guards the write with `git rev-parse --git-dir` and `|| true` on the redirect — both conditions must succeed for the file to land.

- [x] **Q2: Cleanup window for snapshot vs `started-at`.** Resolved: rides inside spec 017's per-session state dir; the 7-day `rm -rf` sweep removes the snapshot atomically with the rest of the subdir. No new cleanup logic.

- [x] **Q3: Test coverage shape.** Resolved: add `.claude/tests/session-handoff/` with 5 scenario scripts + `run-all.sh` orchestrator. Mirrors `.claude/tests/session-state-isolation/` shape.

- [x] **Q4: Behavior when `CLAUDE_SKIP_SESSION_HOOKS=1`.** Resolved: documentation-only — the env var already short-circuits both hooks; no snapshot is written; next session without the env var sees no snapshot → fallback path. Rule doc § State files mentions the interaction.

## Context / references

- `.claude/hooks/session-stop.sh` — the blocking hook being amended.
- `.claude/hooks/session-start.sh` — the snapshot writer to be amended.
- `.claude/rules/session-handoff.md` — doc to amend with the new semantic.
- `docs/specs/017-session-state-isolation/` — established the per-`session_id` state dir layout 023 builds on.
- Live observation 2026-05-12 — conversation that surfaced the false-positive (the user's session that triggered this spec).
