# 156 — sync-exclude-od-regenerated-state — tasks

_Generated from `plan.md` on 2026-06-05. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Seed array + matcher.** In `.agent0/tools/sync-harness.sh`, add `COPY_CHECK_SEED=( … )` (the 3 OD relpaths) beside `COPY_CHECK_EXCLUDE`, with a comment: ship-once-never-reconcile, and why NOT `EXCLUDE` (cold-start read of `od-catalog-index.json`). Add `is_seed()` mirroring `matches_exclude()`.
- [x] 2. **`process_seed()`.** Add the function: respects `_skip_tracked_local_only`; if dst absent → copy (check: `+ would seed` + `DRIFT=1`; apply: `+ seeded`; dry-run variant) incrementing `SEEDED`; if dst present → `= seed <rel> (consumer-owned, not reconciled)`, no compare/flag/overwrite, incrementing `SEED_KEPT`. Add the two counters near the other counters.
- [x] 3. **Wire into the walk.** In `walk_copy_check`, before `record_manifest` in the recursive loop (and defensively the glob + literal loops), add `if is_seed "$relfile"; then process_seed "$relfile"; continue; fi`. Seeds therefore never reach `record_manifest`.
- [x] 4. **Deletion-pass skip.** In `reconcile_deletions`, add `is_seed "$rel" && continue` early in the per-baseline-row loop so a lingering baseline entry for a seed is neither deleted nor refused during the one-apply transition.
- [x] 5. **Summary line.** Surface `SEEDED` / `SEED_KEPT` in the `synced:` summary line (e.g. `N seeded, N seed-kept`).
- [x] 6. **Rule doc.** Add a `## Seed files (ship-once, never-reconcile)` section to `.agent0/context/rules/harness-sync.md` (near § Manifest scope): the three OD paths, the semantics, baseline behavior (not recorded ⇒ self-heal), and why it differs from `COPY_CHECK_EXCLUDE` (spec 156).
- [x] 7. **Tests.** Add `.agent0/tests/harness-sync/NN-seed-od-state.sh` (glob-discovered) — see Verification for the assertions. Mirror the existing test harness in that suite.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] V1 (Scenario: consumer that ran /product syncs clean) — a consumer with a present, drifted seed (sha != baseline != agent0) is reported `= seed …`, NOT `!! customized`; `--check` exit reflects no drift from it.
- [x] V2 (Scenario: /product still works in a fresh consumer) — a cold consumer (seed absent) receives the seed via `--apply` (`+ seeded`), so `od-catalog-index.json` exists for runtime read.
- [x] V3 (Scenario: already-drifted consumer self-heals) — given a baseline that still lists a seed path, `--apply` writes a new baseline WITHOUT it, does NOT delete/refuse the consumer's copy (no `!! customized (upstream-removed)`), and the consumer's bytes are unchanged.
- [x] V4 (static facts) — `--force` does NOT overwrite a present seed; the three exact OD relpaths are the seeds; mechanism mirrors the spec-144 matcher shape, not its full-exclude.
- [x] V5 (no regression) — full `.agent0/tests/harness-sync/` suite green; `bash -n` clean; the live `cognixse --check` now shows the three OD files as `= seed …` (or absent from drift), not `!! customized`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
