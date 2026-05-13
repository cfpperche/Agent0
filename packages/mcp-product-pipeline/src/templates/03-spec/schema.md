# Step 3 — Schema (required sections)

## Required sections

- features
- cross-cutting-concerns
- success-criteria
- edge-cases
- non-goals

## Recommended additional sections

- data-model — informal shape of entities the product manages
- auth-and-permissions — who can do what, if non-trivial
- integration-points — external systems touched, named

## Section content guidance

- **features** — list with per-feature happy-path behavior. Cover every feature in the prototype scope.
- **cross-cutting-concerns** — auth, data persistence, a11y, i18n. One paragraph each; not every section needs depth.
- **success-criteria** — observable conditions per feature ("user sees X after Y"). Used downstream for step 4 testing + step 8 PRD acceptance.
- **edge-cases** — failure / empty / boundary scenarios that actually apply to this product. Not generic.
- **non-goals** — features deliberately out of v1. Each entry has a reason.
