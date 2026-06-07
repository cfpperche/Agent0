# 167 - scope-admission-governance - tasks

_Generated from `plan.md` on 2026-06-07. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create the spec 167 artifact set with filled `spec.md`, `plan.md`, `tasks.md`, and `notes.md`.
- [x] 2. Add `.agent0/context/rules/scope-admission-governance.md`.
- [x] 3. Link scope admission from `.agent0/context/rules/agent0-governance-doctrine.md`.
- [x] 4. Add SDD guidance for Agent0 capacity-expansion specs.
- [x] 5. Refresh `.agent0/HANDOFF.md`.

## Verification

- [x] Verify spec 167 files contain no template placeholders.
- [x] Verify the new rule is reachable from the governance doctrine and SDD rule.
- [x] Verify no hooks, validators, tools, scripts, or sync applies were added.
- [x] Run docs-focused checks: `git diff --check`, placeholder scan, and relevant static reads.
- [x] Review `git status --short`.

## Notes

- This spec is intentionally rule-only. Do not promote scope admission to a checker until repeated friction proves it is needed.
