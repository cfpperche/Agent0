# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-23 — spec 079 shipped + mei-saas synced.** Goal `/goal entregar spec 079 implementada e validada` satisfied for static acceptance + propagation. Agent0 commits `f920201..4b3b474` on `main` (7 commits, one per Block A-F + closure); spec.md Status flipped to `shipped`; all 9 acceptance criteria + 4 OQs ticked; 1 deviation logged at `docs/specs/079-product-stack-aware-handoff/notes.md` (historical `app-skeleton` mention retained in SKILL.md v0.5.0 changelog paragraph — past-behavior reference, not live consumer). mei-saas fork synced: commit `dbcb6d1` on `origin/main` (29 files: 4 stale-updated + 25 removed + baseline.json recorded; 0 customized-refused). Local WIP in mei-saas (`SESSION.md` + `docs/specs/002-foundation/{plan,tasks}.md`) preserved untouched per founder's prior session.

## WIP — resume point

**Pending live validation:** re-run `/product` end-to-end against `/home/goat/mei-saas` to confirm Phase 5 emits infra children per `docs/system-design.md` D-03 + `roadmap.md` Fase 1, and that foundation child #1 references system-design.md (not the deleted templates). Deferred to next session by user decision. Phase 0's `clear-target.sh` will overwrite mei-saas's prior `/product` output; founder accepted that in the directive.

## Next steps

1. Re-run `/product` in mei-saas — `cd /home/goat/mei-saas && /product "<idea text>" --out=. --stack=next` (or `--stack=` omitted to test the `(none declared)` fallback at Step 08). Validate the umbrella's child-spec matrix carries `003-monorepo-backbone, 004-schema-rls, 005-auth-foundation, 006-brasilapi-integration` (or equivalent extracted slugs) before per-phase visual children at #7+.
2. **076** — 33 tasks, still ready to implement; orthogonal to 079 (no file overlap per 079 plan § Risks). Pick this up if no other priority surfaces.
3. **Carryover:** 075 task 14 (`/product` dogfood scenarios 3-6).
4. Dated reminders coming due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.
5. Untracked drafts at session start (not touched this session — leave for originating sessions): `docs/specs/080-memory-system-scale-ready/`, `docs/specs/081-compact-history-runtime-readme/`.

## Decisions & gotchas

- **`secrets-scan` blocks `cd <path> && git commit`** — use `git -C /home/goat/mei-saas commit -F-` to commit in another repo without compounding. `git -C` is the idiomatic shape.
- **mei-saas `monorepo-skeleton/` template dir is fork-local** — not synced from Agent0, stays in mei-saas. Don't be alarmed if a future grep there hits it.
- **079 principle saved as feedback memory `no-shipped-stack-opinions`** — Agent0 ships mechanisms, not frozen stack opinions. Reject any future spec proposing a template/snapshot/defaults file; pipeline output + human at contract-time decide.
- **OQ defaults all adopted in 079** — no granularity cap, infra block-precedes visual, keep `--stack` name, emit migration advisory. Documented as resolutions in `docs/specs/079-.../spec.md § Open questions`.

## Carryover (orthogonal — not touched this session)

- **075 task 14** — `/product` dogfood scenarios 3-6 pending.
- `docs/specs/074-subagent-personas/` — untracked draft (persona/role-prompting killed on research grounds; leave it for the originating session).
- `.claude/REMINDERS.md` items per startup readout.
