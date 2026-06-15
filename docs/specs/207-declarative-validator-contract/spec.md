# 207 — declarative-validator-contract

_Created 2026-06-15._

**Status:** shipped
**Closure:** 2026-06-15 — implemented declarative `.agent0/validator.json` precedence in `.agent0/validators/run.sh`; validation PASS: validator-contract, validator-js-test-script, typecheck-advisory, lint-validator; `bash -n .agent0/validators/run.sh`; `bash .agent0/validators/run.sh` ok:true/no-stack-detected; doctor 25 ok.
**UI impact:** none

## Intent

Agent0's validator should express the harness quality direction without pretending it knows every consumer project's stack. The current stack-detection fallback still builds commands such as `pnpm test` or `pnpm exec biome check` from repository markers, which creates false failures in monorepos and pushes stack policy into the reusable harness. Add a repo-local declarative contract so a consumer can say exactly how it validates test, typecheck, lint, build, and UI acceptance; when that contract exists, the validator becomes a command orchestrator instead of a stack detector.

## Acceptance criteria

- [x] **Scenario: declarative commands take precedence**
  - **Given** a project with `.agent0/validator.json` declaring validation commands
  - **When** `.agent0/validators/run.sh` runs
  - **Then** it executes the declared commands in harness-defined order and does not run stack-detected fallback commands

- [x] **Scenario: monorepo command ownership**
  - **Given** a pnpm monorepo whose root lacks `scripts.test` but `.agent0/validator.json` declares package-scoped commands
  - **When** the validator runs
  - **Then** the JSON command contains the package-scoped commands and no implicit `pnpm test`

- [x] **Scenario: invalid or empty contract fails with clear signal**
  - **Given** `.agent0/validator.json` exists but has no runnable commands or contains non-string command values
  - **When** the validator runs
  - **Then** it emits a clear `validator-config-advisory:`/error signal and returns `ok:false` for malformed declarations rather than falling back to guessed stack commands

- [x] **Scenario: legacy fallback remains compatible**
  - **Given** a project without `.agent0/validator.json`
  - **When** the validator runs
  - **Then** existing stack fallback behavior continues, including the just-added pnpm missing-root-test advisory

- [x] `.agent0/context/rules/typecheck-advisory.md` or a validator rule document explains that the recommended path is declaring project-local validator commands, while stack detection is compatibility fallback.

## Non-goals

- Replacing every stack fallback branch in this change.
- Adding a full JSON Schema validator or a new dependency.
- Proving that declared commands provide sufficient coverage; the consumer project owns the content of its commands.
- Auto-discovering package-level monorepo commands.

## Open questions

- [x] Should missing command categories in `.agent0/validator.json` be blocking? No for v1. Declared commands are the executable contract; missing categories are documentation/discipline unless a future spec adds a `required` array.

## Context / references

- User feedback: the harness should provide direction and require project-owned validation declaration, not ship stack-specific validation assumptions as the primary contract.
- `.agent0/validators/run.sh`
- `.agent0/context/rules/typecheck-advisory.md`
