# 176 - project-core-template-review - tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add template acknowledgement marker to Agent0 source and example.
- [x] 2. Add template-review advisory predicate to startup/status, doctor, and sync.
- [x] 3. Update docs/rules to explain the marker and silence path.
- [x] 4. Add fixture tests for pending review, quiet reviewed state, and bootstrap precedence.
- [x] 5. Refresh handoff.

## Verification

- [x] `bash .agent0/tests/project-core-template-review/run-all.sh` passes.
- [x] `bash .agent0/tests/bootstrap-advisory/run-all.sh` passes.
- [x] `bash .agent0/tests/harness-sync/47-project-core-example.sh` passes.
- [x] `bash .agent0/tests/harness-sync/run-all.sh` passes.
- [x] `bash .agent0/tests/instruction-drift/run-all.sh` passes.
- [x] `bash .agent0/tools/check-instruction-drift.sh` passes.
- [x] `git diff --check` passes.

## Notes

- Syncing `cognixse` after this should copy `.agent0/project-core.md.example`, preserve its existing `.agent0/project-core.md`, and emit template-review advisory until the CognixSE source acknowledges the current marker.
