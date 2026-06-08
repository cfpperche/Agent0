# 172 - settings-hook-removal-sync - tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add failing harness-sync fixtures for Agent0-owned hook removal and pre-baseline no-prune behavior.
- [x] 2. Add settings hook identity extraction and baseline read/write support.
- [x] 3. Update `merge_settings_json` to prune only removed Agent0-owned hook identities.
- [x] 4. Update harness-sync documentation.
- [x] 5. Refresh `.agent0/HANDOFF.md`.

## Verification

- [x] Focused baseline test: `bash .agent0/tests/harness-sync/29-baseline-recorded-on-apply.sh`.
- [x] New test: `bash .agent0/tests/harness-sync/44-settings-removes-agent0-hook.sh`.
- [x] New test: `bash .agent0/tests/harness-sync/45-settings-no-baseline-no-prune.sh`.
- [x] New test: `bash .agent0/tests/harness-sync/46-settings-missing-source-preserves-baseline.sh`.
- [x] Regression: `bash .agent0/tests/harness-sync/run-all.sh`.
- [x] Regression: `bash .agent0/tests/context-injection/run-all.sh`.
- [x] Regression: `bash .agent0/tests/context-retrieval/run-all.sh`.
- [x] Static check: `git diff --check`.
- [x] Syntax check: `bash -n .agent0/tools/sync-harness.sh .agent0/tests/harness-sync/44-settings-removes-agent0-hook.sh .agent0/tests/harness-sync/45-settings-no-baseline-no-prune.sh .agent0/tests/harness-sync/46-settings-missing-source-preserves-baseline.sh`.

## Notes

- Claude review was requested through `claude-exec`; concrete risks incorporated: idempotency must compare `settings_hooks`, missing/unparseable settings must fail open, identity should be structured rather than separator-concatenated, and local-only/skipped settings must preserve previous ownership metadata.
