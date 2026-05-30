# 118 — move-validators-tests-to-agent0 — tasks

_Generated from `plan.md` on 2026-05-29. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation — relocate

- [x] 1. `git mv .claude/validators .agent0/validators` and `git mv .claude/tests .agent0/tests`; confirm both `.claude/` dirs are gone (no tracked files left).

## Implementation — repoint references

- [x] 2. Global scoped sed: in every tracked file EXCEPT `docs/specs/` and `.git/` (filter anchored `(^|/)docs/specs/`), replace `.claude/tests` → `.agent0/tests` and `.claude/validators` → `.agent0/validators`.
- [x] 3. Hand-verify delicate spot 1 — `sync-harness.sh`: `COPY_CHECK_RECURSIVE` has `.agent0/tests`, `COPY_CHECK_GLOBS` has `.agent0/validators|*.sh`, `COPY_CHECK_EXCLUDE` has `.agent0/tests/propagation-advisory/*`.
- [x] 4. Hand-verify delicate spot 2 — `lint-validator.md` + `typecheck-advisory.md` `paths:` frontmatter both point at `.agent0/validators/run.sh`.
- [x] 5. Hand-verify delicate spot 3 — `propagation-advise.sh` shipped-surface set: `.agent0/validators/*`, `.agent0/tests/*` shipped; `.agent0/tests/propagation-advisory/*` excluded.
- [x] 6. Hand-verify delicate spot 4 — `delegation-verify.sh` default validator resolves to `$PROJECT_DIR/.agent0/validators/run.sh`.

## Verification

- [x] 7. `ls .agent0/validators/run.sh .agent0/tests/` → present; `ls .claude/validators .claude/tests` → gone. [spec: Scenario 1]
- [x] 8. `git log --follow .agent0/validators/run.sh` shows pre-move history. [spec: Scenario 2]
- [x] 9. Full suite green: loop every `.agent0/tests/*/run-all.sh`. [spec: Scenario 4] (note pre-existing typecheck-advisory/08 failure if it recurs — not a regression)
- [x] 10. Repo-wide grep outside `docs/specs/` for `.claude/tests`|`.claude/validators` → empty; confirm `.claude/rules`|`.claude/hooks`|`.claude/skills` paths intact AND `docs/specs/` frozen (clean vs HEAD). [spec: final criteria + Scenarios 3, 5, 6]
- [x] 11. `spec.md` Status → `shipped`; outcome recorded; `notes.md` finalized.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
