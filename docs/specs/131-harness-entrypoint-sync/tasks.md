# 131 — harness-entrypoint-sync — tasks

_Generated from `plan.md` on 2026-05-31. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Generalize `.agent0/tools/lib/managed-block.sh`: add optional marker-name arg (default `AGENT0`) to `detect_marker_state` and `_extract_region`; verify existing callers (sync-harness, check-instruction-drift) are byte-unaffected.
- [x] 2. Add `PROJECT_SOURCE_REL` (`.agent0/project-core.md`) and `PROJECT_MARKER` (`AGENT0:PROJECT`) constants to `sync-harness.sh`.
- [x] 3. Implement `_mirror_project_region(rel, rendered, rendered_sha)` in `sync-harness.sh`: detect-state → create/up-to-date/stale/customized/force per the consumer-source-mirror rule; record `<rel>#PROJECT` synthetic key into the manifest; honor `--check` / `--dry-run`; reuse existing counters (UP_TO_DATE / STALE_UPDATED / OVERWRITTEN / CUSTOMIZED_REFUSED / DRIFT).
- [x] 4. Implement `sync_project_core()` (no-op when source absent) calling `_mirror_project_region` for `CLAUDE.md` and `AGENTS.md`; wire into main between `merge_gitignore` and `write_baseline`.
- [x] 5. Confirm `.agent0/project-core.md` is NOT in any `COPY_CHECK_*` array (must stay consumer-owned / outside manifest).
- [x] 6. Document in `.agent0/context/rules/harness-sync.md`: new § "Project core (consumer-source mirror)" + Gap-A note (guarded by `check-instruction-drift.sh`).
- [x] 7. (Optional) Extend `check-instruction-drift.sh`: when `.agent0/project-core.md` exists, assert both entrypoints' `PROJECT` regions equal the source.
- [x] 8. Reword `spec.md` § Acceptance: "single-sourced index" → "kept byte-identical, enforced by `check-instruction-drift.sh`"; note physical single-sourcing is a non-goal.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] Sentinel test (spec AC1): fixture consumer with one sentinel sentence only in `.agent0/project-core.md` → after `--apply`, the sentence appears in BOTH `CLAUDE.md` and `AGENTS.md` PROJECT regions.
- [x] Consumer-edit refused (spec AC3): hand-edit a rendered PROJECT region → `--apply` (no `--force`) refuses, leaves it untouched, never writes the source; `--force` re-renders.
- [x] Stale auto-update (spec AC4): change the source, leave the region → `--apply` re-renders without `--force`.
- [x] Codex-override-wins (spec AC5): documented in the rule; assert the mirror does not touch `AGENTS.override.md` / nested AGENTS.md (no manifest entry).
- [x] Manifest exclusion (spec static fact): `.agent0/project-core.md` absent from `COPY_CHECK_*`; sync never writes it.
- [x] Synthetic keys (spec static fact): after `--apply`, `harness-sync-baseline.json` carries `CLAUDE.md#PROJECT` + `AGENTS.md#PROJECT`.
- [x] Index untouched: changing only the PROJECT region leaves the `AGENT0:BEGIN…END` block byte-identical.
- [x] Regression: full `.agent0/tests/harness-sync/run-all.sh` (or equivalent) stays green; `bash -n` clean.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Gap A was already CI-guarded (`check-instruction-drift.sh`) — discovered during planning; scoped out of the build.
- The feature is opt-in: no `.agent0/project-core.md` → `sync_project_core` is a no-op, so existing consumers are unaffected until they adopt it.
