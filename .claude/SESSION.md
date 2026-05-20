# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-20 — spec 068 scaffolded on branch `068-harness-sync-baseline-reconciliation`. Implementation NOT started.**

Spec 068 (`harness-sync-baseline-reconciliation`) — fixes the `sync-harness` **stale-vs-customized** gap (Bug 1) and the **can't-delete-orphans** gap (Gap E), both surfaced while prepping the mei-saas `/product` dogfood. Adds a recorded sync baseline (`.claude/harness-sync-baseline.json` — git-tracked, per-file sha manifest + `agent0_commit`) → 3-way reconciliation (`fork` vs `baseline` vs `agent0-current`) in the plain-file path. `spec.md` / `plan.md` / `tasks.md` filled; `notes.md` empty. Q1-Q4 resolved in `plan.md`.

## WIP (uncommitted)

- None — spec 068 scaffold committed on the branch with this handoff.

## Recent commits (anchors)

- This session committed the spec 068 scaffold on branch `068-harness-sync-baseline-reconciliation` (branched off `3ea53d5`).
- `origin/main` is at `3ea53d5` — earlier this session pushed `d87e04a` (067) + `3ea53d5` (`/product` hygiene).

## Next steps

1. **Implement spec 068** — work `docs/specs/068-harness-sync-baseline-reconciliation/tasks.md` top-to-bottom on this branch. 10 impl tasks; task 1 = recon (`.claude/tests/harness-sync/` pattern + `sync-harness.sh` line ranges).
2. After 068 ships: the deferred `/product` dogfood.
3. Spec 064 cron natural fire — Mon 2026-05-25 09:00 UTC.

## Decisions & gotchas

- **`/product` dogfood is DEFERRED behind spec 068** — founder chose to fix Agent0 first. When it resumes: scratch path `/tmp/mei-saas-066-dogfood`, run from an Agent0 session, `--stack=next`, original mei-saas idea string. **NOT in-repo** — the mei-saas fork has uncommitted `app/` work (`app/_components/`, `app/icon.svg` are untracked) that must not be destroyed.
- **mei-saas fork is on the OLD `/product` skill** (v0.3.0, spec 048). `sync-harness` cannot update it cleanly today — that *is* Bug 1, which spec 068 fixes.
- **Spec 068 Q2** — baseline is a per-file sha manifest, deliberately diverging from copier/cruft's git-ref model (Agent0's harness is verbatim-copied, no template variables). Flagged to the founder as the main judgment call; approved.

## Carryover (orthogonal — not touched this session)

- Spec 046 dogfood gate due 2026-07-01; spec 029 adoption check due 2026-05-30.
- `.claude/REMINDERS.md` items per startup readout.
- `gta6-thread.png` — stray untracked file at repo root, not ours.
