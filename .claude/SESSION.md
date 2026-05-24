# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 — closed.** Spec 083 (memory-events-journal, MS-2 of umbrella 080) shipped end-to-end in one session: scaffold → spec → plan → tasks → implementation → mechanical verifications → commit. Single commit `f7fc1fa` (22 files, 813 insertions). Tree clean. Local `main` is **2 commits ahead of origin** (`d0f215e` prior-session handoff + `f7fc1fa` this session) — push pending user decision.

Umbrella 080 progress: MS-3, MS-6 ✓ (spec 081). MS-1 ✓ (spec 082). MS-2 ✓ (this spec). Remaining: MS-4 (084 — independent), MS-5+MS-7 (085 — depends on 082+083, now unblocked).

## WIP — resume point

**No active WIP.**

**Boot-time consequences:**

1. `.claude/hooks/memory-events-journal.sh` registers at next session start. Any `Edit`/`Write`/`MultiEdit` of `.claude/memory/*.md` (except `MEMORY.md`) will append one JSONL line to `.claude/.memory-events.jsonl` AND auto-regenerate `MEMORY.md` via `memory-project.sh`. Fail-open (always exit 0).
2. `.claude/hooks/memory-index-gate.sh` registers at next session start. Any agent attempt to `Edit`/`Write`/`MultiEdit` `.claude/memory/MEMORY.md` directly is BLOCKED (exit 2) unless the tool input carries `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` (or HTML-comment form). Override-bypassed edits recorded as `manual-edit` events.
3. First boot-time edit of any entry will trigger the "journal empty; run backfill" advisory once — run `bash .claude/tools/memory-backfill.sh` early in the next session to seed 13 `add` events with git-introduction timestamps (one-shot, idempotent).

## Next steps

1. **Push** — `git push origin main` to publish 083 (2 commits ahead). After push, optionally `bash .claude/tools/memory-backfill.sh` in a fresh session to seed the journal.
2. **Spec 084 (MS-4 reminders refactor)** — independent of 082/083, smaller scope. `.claude/reminders.yaml` refactor + `check_command` + snooze. Manual migration of existing bullets, no migration tooling. Good shorter-session candidate.
3. **Spec 085 (MS-5 + MS-7 cap+query+decay)** — now fully unblocked (082 ✓ + 083 ✓). Cap MEMORY.md index-line at 250 chars + `memory-query.sh` + decay engine (advisory default, transparent overridable formula).
4. **Dated reminders due:** 029 (05-30) · 035 (06-07) · 046 (07-01) · 060 (07-19).

## Decisions & gotchas

- **083 overrode umbrella 080 OQ-5.** Journal is gitignored per-machine, not a single git-tracked backfill commit. Rationale: append-only JSONL in a shared repo produces merge conflicts on every concurrent commit; entry files themselves are git-tracked and carry durable history. OQ-5 marked `RESOLVED 2026-05-24 by 083` in umbrella spec.
- **Side cleanup: 9 entries' `name:` field migrated kebab → Title Case** (e.g. `anthill-archived` → `Anthill archived`) so projected MEMORY.md doesn't visually regress vs the hand-curated index. Per 082 schema, `name:` IS the canonical display label — alignment was overdue.
- **Within-session settings.json activation is gated** — adding a new hook mid-session does NOT make it fire on subsequent edits this session. Live-hook scenarios (V1/V3/V4/V5 in 083 spec) are unverified mid-session; will validate naturally on first entry edit next session. Same gotcha 082 hit.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
