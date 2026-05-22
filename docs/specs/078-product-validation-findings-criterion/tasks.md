# 078 — product-validation-findings-criterion — tasks

_Generated from `plan.md` on 2026-05-22. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Flip `docs/specs/078-product-validation-findings-criterion/spec.md` `**Status:** draft` → `in-progress`.
- [x] 2. Reword the `findings` criterion in `.claude/skills/product/references/quality-checklist.md § 04 — Validation` per `plan.md § Approach`: grade the unconditional markdown `## Findings` table (≥ 3 substantive severity-rated findings) as the core; scope the YAML `findings[]` frontmatter expectation to measurable-mode audits; state that a projected-mode audit legitimately omits the frontmatter. Keep the stable `id: findings`.
- [x] 3. Decide + record (in `notes.md`) whether the optional cross-reference line in `04-validation/prompt.md` step 7 / `schema.md` is worth adding — default per plan: skip it, to avoid leaking judge-awareness into the producer-facing template (spec-075 principle).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 4. **Dogfood setup** — ephemeral `/tmp/078-dogfood/docs/` with `.state.json` + two `validation-report.md` fixtures: (a) **projected-mode** — no YAML frontmatter, `## Accessibility Review` rows all projected `warn`s, a `## Findings` table with ≥ 3 substantive severity-rated findings; (b) **measurable-mode** — `## Accessibility Review` with real measured ratios, still NO YAML frontmatter, same solid `## Findings` table.
- [x] 5. **Scenario 1** — dispatch the `04-validation` quality judge against fixture (a); the reworded rubric must yield `findings: pass` (`spec.md` scenario 1).
- [x] 6. **Scenario 2** — dispatch the `04-validation` quality judge against fixture (b); the rubric must yield `findings: concern`/`fail` — a measurable-mode report still owes the frontmatter (`spec.md` scenario 2).
- [x] 7. **Scenario 3 + criterion consistency** — confirm by reading the reworded criterion that the "≥ 3 substantive" floor is explicit (scenario 3 — a thin findings set still fails, either mode), and that the criterion no longer contradicts `04-validation/prompt.md` step 7 + `schema.md § Optional YAML frontmatter` (`spec.md` acceptance criterion 4). Tear down `/tmp/078-dogfood`.
- [x] 8. **Close** — tick the passing `spec.md § Acceptance criteria` boxes; flip `spec.md` `**Status:** in-progress` → `shipped`; record the implementation decisions in `notes.md`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
