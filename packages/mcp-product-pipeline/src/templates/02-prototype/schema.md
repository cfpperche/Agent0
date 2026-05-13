# Step 2 — Schema (required sections)

`product_step_submit` rejects with `code: "schema-incomplete"` if any required section is absent. Section slugs are lowercased dash-joined H2 titles.

## Required sections

- entry-surface
- killer-flow
- screens
- user-flow
- complexity-budget

## Recommended additional sections

- secondary-flows — second/third user journeys named with one line each
- data-model-sketch — the shape of data each screen reads/writes (informal)
- open-questions — design decisions deferred to later steps

## Section content guidance

- **entry-surface** — one sentence: web / mobile / extension / CLI / widget / multi-surface. If multi-surface, name the primary one and rationale.
- **killer-flow** — the single user journey that has to work in v1. Name the user, the trigger, the steps, the success state. Concrete: "A returning user opens the dashboard → sees today's tasks → marks one done → gets immediate confirmation" beats "Users complete their tasks".
- **screens** — list/table of screens. Per screen: name, primary affordance, key data shown, transitions in/out. 3-12 screens depending on complexity-budget.
- **user-flow** — text diagram of how screens connect. Arrow form or numbered steps both fine. Mark conditional branches.
- **complexity-budget** — "minimal prototype" or "full happy path" plus one sentence justifying the choice given the concept's risk profile.
