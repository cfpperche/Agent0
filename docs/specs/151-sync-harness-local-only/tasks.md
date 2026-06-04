# 151 — sync-harness-local-only — tasks

_Generated from `plan.md` on 2026-06-04. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. **(TDD red)** Write `.agent0/tests/harness-sync/42-local-only.sh`: build a tmp consumer whose `.gitignore` ignores `.agent0/`; run `--apply`; assert (a) a gitignored harness file was written, (b) `git status --porcelain` shows ZERO tracked changes (no `.gitignore`/`CLAUDE.md`/`AGENTS.md`/`.gitleaks.toml`/`.claude/settings.json`), (c) output contains a `local-only` notice. Also assert a NON-ignoring consumer still gets tracked files (mode off). Confirm it FAILS against current code.
- [ ] 2. Add `_is_local_only` (git `check-ignore` on representative `.agent0/` paths; not-a-git-repo → false) and set the `LOCAL_ONLY` global once the consumer root is resolved; init `SKIPPED_TRACKED=0`.
- [ ] 3. Add `_consumer_tracks <relpath>` predicate (true when the path is NOT consumer-ignored).
- [ ] 4. Gate the four write sites under `LOCAL_ONLY=1`: COPY_CHECK per-file copy, `merge_settings_json`, `merge_claude_md`, `.gitignore` merge — skip + `SKIPPED_TRACKED++` when `_consumer_tracks`. Leave gitignored writes (the `.agent0/` tree + baseline) untouched.
- [ ] 5. Reporting: print the one-line local-only notice on detection; append `, N tracked-skipped (local-only)` to the final summary.
- [ ] 6. Document local-only mode in `.agent0/context/rules/harness-sync.md` (trigger, behavior, motivating case; link `.agent0/memory/tmux-sentinel-sync-no-commit.md`).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [ ] 7. **(TDD green)** `bash .agent0/tests/harness-sync/42-local-only.sh` passes.
- [ ] 8. Full suite no regression: `bash .agent0/tests/harness-sync/run-all.sh` all green (incl. 42).
- [ ] 9. `bash -n .agent0/tools/sync-harness.sh` clean + shellcheck via the suite's shellcheck scenario.
- [ ] 10. `grep -q 'local-only' .agent0/context/rules/harness-sync.md` (doc present).

## Notes

_Populated during the /squad run._
