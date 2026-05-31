# 130 — harness-baseline-relocate — tasks

_Generated from `plan.md` on 2026-05-31. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. `sync-harness.sh`: repoint `BASELINE_FILE` to `.agent0/harness-sync-baseline.json`; add `LEGACY_BASELINE_FILE` for `.claude/...`; update header comment (~134).
- [x] 2. `load_baseline`: read `$BASELINE_FILE`, fall back to `$LEGACY_BASELINE_FILE` when the new path is absent.
- [x] 3. Add `_remove_legacy_baseline` helper: on apply (not check/dry-run), `rm -f` the legacy file when present and log `- baseline migrated (removed legacy .claude/harness-sync-baseline.json)`.
- [x] 4. `write_baseline`: write to `$BASELINE_FILE`; call `_remove_legacy_baseline` after a successful `mv` AND on the idempotent early-return; update the three log strings to `.agent0/...`.
- [x] 5. `bash -n` clean.

## Verification

- [x] 6. Repoint every `.agent0/tests/harness-sync/` assertion hardcoding `.claude/harness-sync-baseline.json` to `.agent0/...` (grep the whole tree).
- [x] 7. New test `NN-baseline-legacy-migration.sh`: legacy-only consumer → `--apply` reads it (no `!! customized` storm), writes `.agent0/` baseline, removes legacy; `--check` mutates nothing.
- [x] 8. Run `.agent0/tests/harness-sync/run-all.sh` — all pass (maps to all behavior scenarios).
- [x] 9. Verify `.agent0/harness-sync-baseline.json` is NOT gitignored (Agent0 + a consumer `.gitignore`); baseline still absent from `COPY_CHECK_*`.
- [x] 10. Update `.agent0/context/rules/harness-sync.md` (§ Sync baseline, § Audit, § Path relocations, gotchas) and `.agent0/memory/harness-home.md` (disposition matrix) to the new path.

## Goal tail (resync + cleanup)

- [ ] 11. Resync mei-saas: `sync-harness.sh --apply` → observe `.agent0/harness-sync-baseline.json` created + legacy `.claude/` removed; re-check exit 0.
- [ ] 12. Sweep mei-saas `.claude/` for any post-migration residue; confirm only legitimate files remain.
- [ ] 13. Commit Agent0 spec 130 + commit mei-saas baseline migration (separate repos, separate commits).

## Notes

- The legacy file is git-tracked in the consumer, so its removal appears as a deletion in the consumer's `git diff` — that diff IS the migration audit record.
