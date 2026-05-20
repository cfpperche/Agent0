# 068 — harness-sync-baseline-reconciliation — tasks

_Generated from `plan.md` on 2026-05-20. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. **Recon.** Read `.claude/tests/harness-sync/*.sh` for the test-harness pattern (setup/teardown, fixture forks, assertions) and the highest existing test number. Re-confirm the exact line ranges of `process_file()`, `walk_copy_check()`, `merge_settings_json()` (atomic-write pattern), and the counter declarations in `.claude/tools/sync-harness.sh`.
- [ ] 2. **Baseline read.** Add `load_baseline()` — if `<fork>/.claude/harness-sync-baseline.json` exists, one `jq` call dumps its `.files` map to a sorted `path\tsha` temp file. Add `baseline_sha_for <relpath>` — Bash-3.2-safe lookup against that temp file (no `declare -A`; `grep`/`look`). Returns empty string when absent.
- [ ] 3. **Agent0 manifest set.** Modify `walk_copy_check()` to accumulate every Agent0 managed-file relpath it visits into a sorted temp file — the "current manifest set" consumed by the deletion pass and the baseline write.
- [ ] 4. **3-way `process_file()`.** Rewrite the hash-mismatch branch with the decision table from `plan.md`: `baseline == fork` → **stale**, copy + report `~ stale` / `updated` (no `--force` needed); `baseline != fork` (present) → **customized**, refuse (today's behavior, `--force` overrides); `baseline` absent → **customized (no baseline)**, refuse, `--force` overrides. Add the `STALE_UPDATED` counter.
- [ ] 5. **Deletion pass.** Add `reconcile_deletions()` (runs after `walk_copy_check`): for each path in the baseline file-set NOT in the Agent0 current manifest set — `fork_sha == baseline_sha` → remove from fork + `rmdir` now-empty parent dirs bottom-up; `fork_sha != baseline_sha` → keep, refuse, advise manual resolution (`!! customized (upstream-removed)`); fork no longer has it → no-op. Add the `REMOVED` counter. Honors `--check`/`--dry-run` (detect, no writes) and `--force` (overwrite the customized-upstream-removed refusal into a delete).
- [ ] 6. **Baseline write.** Add `write_baseline()` — on `--apply` without `--dry-run`, after all passes: build `{ "agent0_commit": <git rev-parse HEAD of $AGENT0_ROOT, or null>, "synced_at": <iso>, "tool_version": <n>, "files": { <relpath>: <agent0_sha>, … } }` from the current manifest set, write atomically (`mktemp` + `mv`, mirroring `merge_settings_json`).
- [ ] 7. **Counters / summary / exit.** Wire `STALE_UPDATED` and `REMOVED` into the summary line. `--check`: `stale` and `removed` set `DRIFT=1` (exit 1). `--apply`: exit code stays 1 *only* on `customized-refused` — stale auto-updates and removals are successful actions, not refusals.
- [ ] 8. **`.gitignore` guard.** Confirm no pattern in Agent0's `.gitignore` (and the additive-merge entry set) catches `.claude/harness-sync-baseline.json`; the non-dotted name should already dodge `.claude/.*` globs. Add an explicit `!`-negation only if a broad pattern is found.
- [ ] 9. **Regression tests.** Add tests under `.claude/tests/harness-sync/` (numbered after the current highest), one per `spec.md` scenario — stale-auto-update, customized-still-refused, removed, customized-upstream-removed, bootstrap-no-baseline, baseline-recorded-on-apply, idempotency, `--check` labelling. Written red-first per `.claude/rules/tdd.md`; each test name mirrors its scenario title.
- [ ] 10. **Docs.** Update `.claude/rules/harness-sync.md` — § Customization detection (2-state → 3-way table), new § Sync baseline (file shape, location, git-tracked, bootstrap), § Audit (no longer "None"), § Manifest scope (deletion propagation), § Gotchas (Bash-3.2 lookup, one-time first-sync reconciliation). Update `CLAUDE.md` § Harness sync to name the baseline mechanism + file path.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [ ] Run the full `.claude/tests/harness-sync/` suite — every test passes, existing and new (covers scenarios: stale auto-update, customized refused, removed, customized-upstream-removed, baseline recorded, idempotency, `--check` labelling).
- [ ] On a fixture fork with no baseline file, `sync-harness --apply` does not error, refuses differing files, and writes `harness-sync-baseline.json` — confirms the bootstrap static criterion.
- [ ] Existing `settings.json` / `CLAUDE.md` / `.gitignore` merge tests still pass unchanged — confirms the structured-merge paths were not touched.
- [ ] Empirical: `sync-harness --check` against the mei-saas fork (after a one-time baseline seed) labels its stale `/product` skill tree as `stale`, not `customized` — the live case from the session investigation.
- [ ] Two consecutive `--apply` runs on a synced fork: the second mutates zero files and leaves `harness-sync-baseline.json` byte-identical — idempotency scenario.
- [ ] `.claude/rules/harness-sync.md` and `CLAUDE.md` § Harness sync reflect the baseline mechanism; no stale "2-state" / "Audit: None" wording remains.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
