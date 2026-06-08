# 174 - bootstrap-advisories - tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add project-core pending-bootstrap predicate to `sync-harness.sh`.
- [x] 2. Add shared startup/status bootstrap block.
- [x] 3. Add doctor project-core advisory check.
- [x] 4. Document the advisory and the required silence after `.agent0/project-core.md` exists.
- [x] 5. Add fixture tests for pending, configured, and no-example states.
- [x] 6. Refresh `.agent0/HANDOFF.md`.

## Verification

- [x] `bash .agent0/tests/bootstrap-advisory/run-all.sh` passes.
- [x] `bash .agent0/tests/agent0-status/test.sh` passes.
- [x] `bash .agent0/tests/harness-sync/47-project-core-example.sh` passes.
- [x] `bash .agent0/tests/harness-sync/run-all.sh` passes.
- [x] `bash .agent0/tools/check-instruction-drift.sh` passes.
- [x] `git diff --check` passes.

## Notes

- `mei-saas` was synced without configuring `.agent0/project-core.md`; `sync-harness --check`, `doctor.sh`, `status.sh`, and `startup-brief.sh` now show the pending bootstrap advisory while `.agent0/project-core.md.example` is present and the real source is absent.
