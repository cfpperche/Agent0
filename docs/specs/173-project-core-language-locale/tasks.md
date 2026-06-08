# 173 - project-core-language-locale - tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add Agent0's `.agent0/project-core.md` and mirror its exact content into `CLAUDE.md` and `AGENTS.md`.
- [x] 2. Add `.agent0/project-core.md.example` and include only the example file in the sync manifest.
- [x] 3. Update `language.md`, `harness-sync.md`, and `runtime-capabilities.md` to document authority order and the example/source split.
- [x] 4. Add a harness-sync regression test for example shipping without real source creation/overwrite.
- [x] 5. Refresh `.agent0/HANDOFF.md` with spec 173 state and the no-consumer-sync boundary.

## Verification

- [x] `bash .agent0/tools/check-instruction-drift.sh --skip-sync-check` passes.
- [x] `bash .agent0/tools/check-instruction-drift.sh` passes.
- [x] `bash .agent0/tests/instruction-drift/run-all.sh` passes.
- [x] `bash .agent0/tests/harness-sync/37-project-core-mirror.sh` passes.
- [x] `bash .agent0/tests/harness-sync/47-project-core-example.sh` passes.
- [x] `bash .agent0/tests/harness-sync/run-all.sh` passes.
- [x] `git status --short --branch` confirms no consumer repo was touched from this worktree.

## Notes

- Do not run `sync-harness.sh` against `/home/goat/mei-saas`, `/home/goat/acmeyard`, `/home/goat/cognixse`, or any other consumer as part of this spec.
