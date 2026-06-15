# 207 — declarative-validator-contract — plan

_Drafted from `spec.md` on 2026-06-15. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add an early `.agent0/validator.json` branch after global advisories and before stack detection. If the file exists, parse `.commands` with `jq`, validate that every present command value is a non-empty string, compose a shell pipeline in fixed order (`test`, `typecheck`, `lint`, `build`, `ui`), and execute that pipeline through the existing JSON capture path. This keeps the validator JSON contract unchanged while moving stack ownership to the consumer project.

Keep the existing stack detector intact as a compatibility fallback when no declarative file exists. That avoids a breaking migration across existing consumers while making the preferred contract explicit in the rule docs and tests.

## Files to touch

**Create:**
- `.agent0/tests/validator-contract/` — fixtures for declarative validator behavior.
- `docs/specs/207-declarative-validator-contract/` — spec record.

**Modify:**
- `.agent0/validators/run.sh` — add `.agent0/validator.json` precedence, validation, and command composition.
- `.agent0/context/rules/typecheck-advisory.md` — document the declarative validator path and fallback status.
- `.agent0/tools/sync-harness.sh` if needed — ensure `.agent0/validator.json` itself remains consumer-owned and is not shipped as a managed file.

**Delete:**
- None.

## Alternatives considered

### Remove stack detection immediately

Rejected because existing consumers rely on fallback validation when they have not yet declared `.agent0/validator.json`. A hard removal would convert this architectural cleanup into a migration fire drill.

### Add package-manager-specific monorepo discovery

Rejected because it repeats the same category error: the harness would keep guessing project-specific commands. Monorepo test targets are product/project decisions and belong in a repo-local declaration.

## Risks and unknowns

- Shell command strings are consumer-owned and intentionally executed. This is no worse than the current inferred shell pipeline, but docs should make the trust boundary explicit.
- A project can declare weak no-op commands. The validator checks shape, not semantic coverage; that matches existing manifest-as-intent behavior.
- Missing categories may be too quiet for some teams. V1 keeps them non-blocking; a later `required` field can add stricter policy without changing the basic contract.

## Research / citations

- `.agent0/validators/run.sh` current command composition and JSON capture flow.
- `.agent0/context/rules/typecheck-advisory.md` existing manifest-as-intent behavior.
