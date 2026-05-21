# 072 — sync-harness-self-overwrite — tasks

_Generated from `plan.md` on 2026-05-21. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Write `.claude/tests/harness-sync/33-self-overwrite-single-run.sh` — stage a fixture fork whose `.claude/tools/sync-harness.sh` is a length-altered copy of Agent0's current `sync-harness.sh`, with a `harness-sync-baseline.json` entry recording that altered copy's sha (so it classifies `stale`). Run `--apply` once against the fork's own copy. Assert: exit 0, stderr has no `unbound variable` / syntax-error line, and the fork's `sync-harness.sh` ends byte-identical to Agent0's.
- [x] 2. Run test 33 against the current (pre-fix) `sync-harness.sh` — confirm it **fails** (the self-overwrite crash reproduces). This proves the test catches the bug; do not proceed until red is observed.
- [x] 3. Implement the fix in `.claude/tools/sync-harness.sh`: (a) capture `ORIGINAL_ARGS=("$@")` as the first executable line, before the parse loop; (b) after the sanity block, if `AGENT0_SYNC_REBOOTSTRAP_TMP` is set, register `trap 'rm -f "$AGENT0_SYNC_REBOOTSTRAP_TMP"' EXIT`; (c) add `_self_rebootstrap()` — write-verdict for the single relpath `.claude/tools/sync-harness.sh` via `sha_of` + `load_baseline`; on a write-verdict with `AGENT0_SYNC_REBOOTSTRAPPED` unset and apply-non-dry-run mode, `mktemp` + `cp` Agent0's copy + `export` the two env vars + `exec bash "$tmp" "${ORIGINAL_ARGS[@]}"`; (d) call `_self_rebootstrap` as the first line of the orchestration tail, immediately before `load_baseline`.
- [x] 4. Add `33` to the explicit scenario-number list in `.claude/tests/harness-sync/run-all.sh`.
- [x] 5. Update `.claude/rules/harness-sync.md` — add a `## Self-rebootstrap` subsection describing the pre-flight, and a `## Gotchas` entry for the one-time transitional crash a pre-072 fork still hits on the upgrade that installs the fix ("re-run `--apply`, it is clean").

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] Run test 33 against the fixed `sync-harness.sh` — passes: single-run `--apply`, exit 0, no crash, fork copy updated (spec scenario "a self the run will overwrite does not crash the run").
- [x] Confirm an up-to-date fork `--apply` triggers no rebootstrap — `sync-harness.sh` reports `= up to date`, behavior unchanged; the existing `30-baseline-idempotent-apply.sh` still passes (spec scenario "an up-to-date self adds no overhead").
- [x] Confirm a fork with a customized `sync-harness.sh` run `--apply` without `--force` is refused with no crash and no rebootstrap (spec scenario "a customized-and-refused self is not rebootstrapped").
- [x] Run the full `.claude/tests/harness-sync/run-all.sh` — all 33 scenarios pass (spec criterion: test suite gains coverage, `run-all.sh` includes it and passes).
- [x] `.claude/rules/harness-sync.md` documents the self-rebootstrap behavior and the transitional crash (spec criterion).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
