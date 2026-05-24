# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 — closed.** Spec 082 (memory-frontmatter-schema, MS-1 of umbrella 080) shipped end-to-end in one session: scaffold → spec → plan → tasks → implementation → verification → commit. Single commit `19218f9` (13 files, 686 insertions). Pushed to `origin/main` along with 2 pending commits from prior session (`05a5ec8` session-start dual-emit, `3aca65c` handoff). Tree clean, in sync with origin.

## WIP — resume point

**No active WIP.**

**Boot-time consequence:** the new `.claude/hooks/memory-frontmatter-validate.sh` registers at next session start. From that point on, any `Edit`/`Write` to `.claude/memory/*.md` (except `MEMORY.md`) triggers a `memory-frontmatter-advisory:` stderr line if the entry violates the 6-field schema. Non-blocking. All 13 current entries already conform — zero standing advisories expected.

## Next steps

1. **Spec 083 (MS-2 event-sourcing)** — unblocked by 082 ship. `/sdd new memory-events-journal` (slug tentative). Scope: event-sourced memory always-on + raw-edit gate on `MEMORY.md` + projection helper. 083 decides `entry_id` strategy — see 082 spec § Non-goals.
2. **Spec 084 (MS-4 reminders refactor)** — independent of 082/083, smaller scope. `.claude/reminders.yaml` refactor + `check_command` + snooze. Manual migration of existing bullets, no migration tooling. Good shorter-session candidate.
3. **Spec 085 (MS-5 + MS-7 cap+query+decay)** — blocked on 082 ✓ + 083. Do not start until 083 ships.
4. **Dated reminders due:** 029 (05-30) · 035 (06-07) · 046 (07-01) · 060 (07-19).

## Decisions & gotchas

- **082 OQ-5 collapsed during refinement** — schema lives as `## Frontmatter schema` section in `.claude/rules/memory-placement.md`, NOT a new dotfile under `.claude/memory/`. Cleaner: zero manifest changes. HTML comment `<!-- DO NOT RENAME — referenced verbatim by .claude/hooks/memory-frontmatter-validate.sh -->` anchors the validator's citation; renaming silently breaks the pointer.
- **Within-session settings.json activation is gated** — adding a new hook mid-session does NOT make it fire on subsequent edits this session. Already in `.claude/rules/compaction-continuity.md` § Gotchas; surfaced again empirically during 082's e2e. Re-noting because the failure mode is silent (no error, hook just doesn't fire).

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
