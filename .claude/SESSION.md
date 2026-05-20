# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-20 — spec 068 IMPLEMENTED, tested, verified on branch `068-harness-sync-baseline-reconciliation`. Uncommitted.**

Spec 068 (`harness-sync-baseline-reconciliation`) is done — all 10 impl tasks + 6 verification checks complete. `sync-harness.sh` now does 3-way reconciliation on the plain-file path (fork vs recorded baseline vs Agent0-current): *stale* files auto-update without `--force`, genuinely *customized* files still refuse, upstream-*removed* files are deleted when the fork copy is clean. Baseline lives at `<fork>/.claude/harness-sync-baseline.json` (git-tracked in the fork, per-file sha manifest). Bug 1 (stale-vs-customized) and Gap E (orphan deletion) both fixed.

`spec.md` Status → `shipped`; `tasks.md`/`spec.md` boxes checked; `notes.md` filled (1 deviation: conditional `write_baseline`).

## WIP (uncommitted)

All on branch `068-harness-sync-baseline-reconciliation`, not yet committed:
- `.claude/tools/sync-harness.sh` — baseline globals + trap; `load_baseline`/`baseline_sha_for`/`record_manifest`/`reconcile_deletions`/`prune_empty_parents`/`write_baseline`; 3-way `process_file`; manifest-recording `walk_copy_check`; 2 new counters; `main` wiring.
- `.claude/tests/harness-sync/24..31-*.sh` — 8 new regression tests; `run-all.sh` loop extended to `01..31`.
- `.claude/rules/harness-sync.md`, `CLAUDE.md` § Harness sync — baseline mechanism documented.
- `docs/specs/068-*/{spec,tasks,notes}.md` — closed out.

## Recent commits (anchors)

- `ae8524c` — spec 068 scaffold (this branch, off `3ea53d5`).
- `origin/main` at `3ea53d5`.

## Next steps

1. **Commit spec 068** — review `git diff`, commit on this branch (no auto-commit done — project posture). Suggested: `feat(068): harness-sync 3-way baseline reconciliation — stale-vs-customized + orphan deletion`.
2. **Deferred `/product` dogfood** — spec 068 was its prerequisite, now unblocked. Scratch path `/tmp/mei-saas-066-dogfood`, `--stack=next`, original mei-saas idea string. NOT in-repo — mei-saas fork has uncommitted `app/` work.
3. Spec 064 cron natural fire — Mon 2026-05-25 09:00 UTC.

## Decisions & gotchas

- **mei-saas catch-up sync now has a clean path** — verified empirically: a baseline seeded from mei-saas's real `/product` bytes relabels its drifted tree as 15 stale / 0 customized / 27 orphan-removed (was: all `customized`, would-refuse). One-time bootstrap is `--apply --force --force-except='<real customizations>'`, then 3-way from there.
- **`write_baseline` is conditional** — skips the write when the files-map is byte-identical to the existing baseline, so a no-op re-apply leaves `harness-sync-baseline.json` untouched (idempotency). Deviation from `plan.md`'s "write on every --apply"; see `notes.md`.
- Stray untracked files at repo root (`bo-*.png`, `gta6-thread.png`) — not ours, leave them.

## Carryover (orthogonal — not touched this session)

- Spec 046 dogfood gate due 2026-07-01; spec 029 adoption check due 2026-05-30.
- `.claude/REMINDERS.md` items per startup readout.
