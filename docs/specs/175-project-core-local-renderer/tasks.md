# 175 - project-core-local-renderer - tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add local `project-core-sync.sh` renderer.
- [x] 2. Register post-edit hooks for Claude and Codex.
- [x] 3. Make `sync-harness.sh` delegate project-core rendering to the local renderer.
- [x] 4. Update doctor/status/bootstrap/drift messaging.
- [x] 5. Update rules and runtime capability docs.
- [x] 6. Update and add tests.
- [x] 7. Refresh handoff.

## Verification

- [x] `bash .agent0/tests/project-core-sync/run-all.sh` passes.
- [x] `bash .agent0/tests/bootstrap-advisory/run-all.sh` passes.
- [x] `bash .agent0/tests/harness-sync/37-project-core-mirror.sh` passes.
- [x] `bash .agent0/tests/harness-sync/47-project-core-example.sh` passes.
- [x] `bash .agent0/tests/harness-sync/run-all.sh` passes.
- [x] `bash .agent0/tests/instruction-drift/run-all.sh` passes.
- [x] `bash .agent0/tools/check-instruction-drift.sh` passes.
- [x] `git diff --check` passes.

## Notes

- `mei-saas` must be resynced after this Agent0 change so it receives `project-core-sync.sh` and the post-edit hooks.
