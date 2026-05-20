# 068 — harness-sync-baseline-reconciliation — tasks

_Generated from `plan.md` on 2026-05-20. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Recon.** Read `.claude/tests/harness-sync/*.sh` for the test-harness pattern (setup/teardown, fixture forks, assertions) and the highest existing test number. Re-confirm the exact line ranges of `process_file()`, `walk_copy_check()`, `merge_settings_json()` (atomic-write pattern), and the counter declarations in `.claude/tools/sync-harness.sh`. — _Done. Pattern: self-contained `mktemp -d` fixture, `trap` cleanup, `echo "PASS: …"`. Highest test = 23; new tests 24-31. `run-all.sh` has a hardcoded `01..23` loop (extended). `process_file()` ~196-252, `walk_copy_check()` ~254-278, counters ~162-167._
- [x] 2. **Baseline read.** Add `load_baseline()` — if `<fork>/.claude/harness-sync-baseline.json` exists, one `jq` call dumps its `.files` map to a sorted `path\tsha` temp file. Add `baseline_sha_for <relpath>` — Bash-3.2-safe lookup against that temp file (no `declare -A`; `awk` exact-match — see `notes.md`). Returns empty string when absent. Malformed baseline fails open.
- [x] 3. **Agent0 manifest set.** `walk_copy_check()` records every visited Agent0 managed-file relpath + sha into `MANIFEST_RAW`, sorted/uniq'd into `MANIFEST_TSV` — the "current manifest set" consumed by the deletion pass and the baseline write.
- [x] 4. **3-way `process_file()`.** Hash-mismatch branch rewritten with the `plan.md` decision table: `baseline == fork` → **stale**, copy + report `~ stale -> updated`; `baseline != fork` (present) → **customized**, refuse; `baseline` absent → **customized (no baseline)**, refuse; `--force` overrides both customized cases. `STALE_UPDATED` counter added.
- [x] 5. **Deletion pass.** `reconcile_deletions()` runs after `walk_copy_check`: baseline paths not in the current manifest with `fork_sha == baseline_sha` → remove + `prune_empty_parents()` bottom-up; `fork_sha != baseline_sha` → `!! customized (upstream-removed)`, refuse; fork lacks it → no-op. `REMOVED` counter added. Honors `--check`/`--dry-run`/`--force`.
- [x] 6. **Baseline write.** `write_baseline()` — on `--apply` (not `--dry-run`), after all passes: builds `{agent0_commit, synced_at, tool_version, files}` from the manifest set, atomic `mktemp` + `mv`. Skips the write when the files-map is byte-identical to the existing baseline (idempotency — see `notes.md` § Deviations).
- [x] 7. **Counters / summary / exit.** `STALE_UPDATED` + `REMOVED` wired into the summary line. `--check`: stale/removed set `DRIFT=1`. `--apply`: exit 1 only on `customized-refused` — stale/removed are successful actions.
- [x] 8. **`.gitignore` guard.** Confirmed: no pattern in Agent0's `.gitignore` catches `.claude/harness-sync-baseline.json` — the non-dotted basename dodges every `.claude/.*` glob. No `!`-negation needed; `.gitignore` unchanged.
- [x] 9. **Regression tests.** Tests `24`-`31` added under `.claude/tests/harness-sync/`, one per `spec.md` scenario — stale-auto-update, customized-still-refused, removed-orphan, customized-upstream-removed, `--check` labelling, baseline-recorded-on-apply, idempotent-apply, bootstrap-no-baseline. `run-all.sh` loop extended to `01..31`. All 31 pass.
- [x] 10. **Docs.** `.claude/rules/harness-sync.md` updated — § Customization detection rewritten to the 3-way table, new § Sync baseline, § Audit (baseline IS the record), § Manifest scope (deletion propagation), § Gotchas (4 new). `CLAUDE.md` § Harness sync names the baseline mechanism + file path + spec 068.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] Run the full `.claude/tests/harness-sync/` suite — all 31 tests pass (23 existing + 8 new). Covers stale auto-update, customized refused, removed-orphan, customized-upstream-removed, baseline recorded, idempotency, `--check` labelling.
- [x] On a fixture fork with no baseline file, `sync-harness --apply` does not error (exit 1 = refusal, not exit 2), refuses differing files as `(no baseline)`, copies missing files, and writes `harness-sync-baseline.json` — test `31-baseline-bootstrap-no-baseline.sh`.
- [x] Existing `settings.json` / `CLAUDE.md` / `.gitignore` merge tests (05, 06, 13-23) still pass unchanged — the structured-merge paths were not touched.
- [x] Empirical: read-only `sync-harness --check` against the real mei-saas fork runs cleanly on 545 files (510 up-to-date, drifted `/product` flagged `customized (no baseline)` — bootstrap path). With a baseline seeded from a scratch copy of mei-saas's real `/product` bytes, the drifted tree relabels as **15 stale, 0 customized, 27 orphan-removed** — the live case from the session investigation, fixed.
- [x] Two consecutive `--apply` runs on a synced fork: the second mutates zero files and leaves `harness-sync-baseline.json` byte-identical — test `30-baseline-idempotent-apply.sh`.
- [x] `.claude/rules/harness-sync.md` and `CLAUDE.md` § Harness sync reflect the baseline mechanism; the only remaining "2-state" mentions are deliberate (explaining the *old* model and the malformed-baseline fallback); no "Audit: None" wording remains.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- In-flight design decisions, the one deviation from `plan.md` (conditional `write_baseline`), and one tradeoff are recorded in `notes.md`.
- All 10 implementation tasks + 6 verification checks complete. Work is on branch `068-harness-sync-baseline-reconciliation`, uncommitted — the developer reviews `git diff` and commits (no auto-commit, per project posture).
- Tool change is contained: `sync-harness.sh` gained baseline globals + a trap, `load_baseline`/`baseline_sha_for`/`record_manifest`/`reconcile_deletions`/`prune_empty_parents`/`write_baseline`, a rewritten `process_file` hash-mismatch branch, a manifest-recording `walk_copy_check`, 2 new counters, and 3 new lines in `main`. The structured-merge functions (`merge_settings_json`, `merge_claude_md*`, `merge_gitignore`) were not touched.
- Next: the deferred `/product` dogfood (SESSION.md) — spec 068 was its prerequisite. A real mei-saas catch-up sync now has a clean path: one-time `--apply --force --force-except='<real customizations>'` seeds the baseline, then 3-way from there.
