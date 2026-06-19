# 210 — validator-multistack-advisory — tasks

_Generated from `plan.md` on 2026-06-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Verify:** `bash docs/specs/210-validator-multistack-advisory/verify.sh`

## Implementation

- [x] 1. Add `detect_all_stacks()` to `.agent0/validators/run.sh`: `git ls-files` over manifest globs mirroring the fallback chain EXACTLY (`package.json`+js lockfiles→js, `pyproject.toml`/`requirements.txt`→python, `go.mod`→go, `Cargo.toml`→rust, `composer.json`→php; vendored trees pruned) → distinct stack set. Not-a-git-repo / `git` absent → degrade to root-marker detection, never error. [codex fold: NOT setup.py/setup.cfg/requirements-variants]
- [x] 2. Build `multi-stack_advisory_msg`, gated on: `stack != declared` AND `CLAUDE_VALIDATOR_SKIP_MULTISTACK != 1` AND distinct-stack-count > 1. Message names the audited (first-match) stack + the unaudited stack(s) + points at `.agent0/validator.json`.
- [x] 3. Emit `multi-stack_advisory_msg` in the existing advisory stderr block (alongside lint/typecheck/test advisories). Confirm JSON `ok`/`exit` untouched.
- [x] 4. Write `verify.sh` with fixtures: (a) polyglot+subtree (root JS + `services/api/composer.json`) → advisory fires, names both sides, `ok`/`exit` unchanged; (b) `validator.json` present → no advisory; (c) single-stack → no advisory; (d) git-absent → graceful (no error); (e) `CLAUDE_VALIDATOR_SKIP_MULTISTACK=1` → no advisory.
- [x] 5. `bash -n` + run `verify.sh` green.
- [x] 6. Run the existing validator test suites (`.agent0/tests/lint-validator/`, `.agent0/tests/*validator*`) to confirm NO regression.

## Codex review gate

- [x] 7. Send the `run.sh` diff to codex for read-only review (high effort); fold findings; report verdict. **(Pause before docs.)**

## Docs

- [x] 8. Rewrite `lint-validator.md` § Single-stack v1, `typecheck-advisory.md` § No multi-stack typecheck, `php-laravel-support.md` § monorepo gotchas — fallback is compatibility-only; monorepos declare `validator.json`; fallback emits `multi-stack-advisory:`. Stop promising a walk.
- [x] 9. Document `multi-stack-advisory:` + `CLAUDE_VALIDATOR_SKIP_MULTISTACK` in `typecheck-advisory.md` (canonical validator-contract rule).

## Verification

- [x] 10. `verify.sh` green across all 5 scenarios; existing validator suites green; `bash .agent0/tools/doctor.sh` clean.
- [x] 11. Codex reviews the full final diff; fold; report verdict. Fill `**Closure:**`, check all spec/tasks boxes, record spec-verify pass. **(Pause for maintainer OK before commit.)**

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
