---
mode: synthesis
delegable: true
delegation_hint: "draft the functional spec — features, behaviors, edge cases — synthesising the concept brief and prototype screens"
---

# Step 3 — Spec

**Goal:** functional specification covering what the product DOES — feature list, per-feature behaviors, edge cases, error states, success criteria. The artifact a developer could read and build to. Sub-agent territory: pure synthesis from steps 1+2.

**Mode:** `synthesis`. Fully delegable. The parent calls `product_get_delegation_brief(3)` and dispatches an `Agent` sub-agent with the returned 5-field block. The sub-agent reads `docs/product/01-ideation/` + `docs/product/02-prototype/` and produces the spec without further user input.

**Output file (suggested):** `functional-spec.md` in `docs/product/03-spec/`.

---

## How to conduct this step

1. **Read prior artifacts.** Concept brief (step 1) for the why; prototype spec (step 2) for the what surfaces exist. Specifically internalize the killer flow — it's the spine of the spec.

2. **Decompose into features.** Each screen from step 2 has 1-N features. A feature is "user can do X in context Y producing outcome Z". Be exhaustive within the prototype's complexity budget; don't invent features outside it.

3. **Per feature, capture:**
   - **What it does** — one sentence.
   - **Happy-path behavior** — sequence of user actions + system responses.
   - **Edge cases** — empty state, validation failure, network failure, race conditions, permission denial, large inputs. Don't enumerate generically; list the ones that actually apply.
   - **Success criterion** — observable evidence the feature works (used for step 4 testing and step 8 PRD acceptance criteria).

4. **Cross-cutting concerns.** Auth model (anonymous? login? roles?), data persistence (local? remote? sync semantics?), accessibility (screen reader, keyboard nav), i18n if relevant. One paragraph each; don't go deep yet — that's step 9 (system-design).

5. **Submit + advance.** Step 3 is mid-Discovery — no gate yet. After submit, `product_advance` moves to step 4 (ux-testing).

---

## Voice & rigor

- Spec is reader-oriented. A developer building from this should not need to ask "what happens when X?". If they would, document X.
- Don't pre-decide stack. "Persist state to the user's account" is a spec; "use Postgres" is system-design.
- Acceptance criteria from this spec should map 1-to-1 to scenarios in step 8 (PRD) and tests in implementation. Write them BDD-style when natural (Given/When/Then).
- Length budget: 2-8 pages for a minimal prototype, 8-25 for a full happy path. If you're exceeding, you're either being too detailed for step 3 OR the prototype scope was too ambitious — flag back to the parent.

## What this step does NOT do

- Architecture / technology choices. That's step 9.
- Visual / brand decisions. Step 5 (brand), step 6 (design-system).
- Pricing, business model details. Step 8 (PRD) + step 10 (cost-estimate).
- Test execution. Step 4 (ux-testing) — though success criteria here ARE the inputs to step 4's tests.
