# 207 — declarative-validator-contract — tasks

_Generated from `plan.md` on 2026-06-15. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add `.agent0/validator.json` parsing and command composition to `.agent0/validators/run.sh`.
- [x] 2. Add validator-contract fixtures for precedence, pnpm monorepo package commands, malformed config, and legacy fallback.
- [x] 3. Document the declarative contract and fallback posture.
- [x] 4. Run focused validation suites and update this spec closure evidence.

## Verification

- [x] Declarative commands take precedence over stack detection.
- [x] Pnpm monorepo package-scoped commands run without implicit `pnpm test`.
- [x] Malformed/empty `.agent0/validator.json` fails clearly instead of falling back.
- [x] Existing pnpm fallback tests still pass when no declarative file exists.

## Notes

- 2026-06-15 — focused validation passed:
  - `bash -n .agent0/validators/run.sh`
  - `bash .agent0/tests/validator-contract/run-all.sh`
  - `bash .agent0/tests/validator-js-test-script/run-all.sh`
  - `bash .agent0/tests/typecheck-advisory/run-all.sh`
  - `bash .agent0/tests/lint-validator/run-all.sh`
