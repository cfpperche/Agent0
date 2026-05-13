---
mode: synthesis
delegable: true
delegation_hint: "draft prototype-v2 re-rendering step 2's screen spec with brand voice + design-system tokens/components applied"
---

# Step 7 — Prototype v2

**Goal:** the LAST step of Identity phase. Re-render the step 2 prototype spec using the brand voice (step 5) and the design system (step 6). What changes between v1 and v2 is the surface treatment — same flow, same screens, now with applied identity.

**Mode:** `synthesis`. Fully delegable. Reads steps 2, 5, 6; produces a refined screen spec where each screen now references specific components, tokens, and voice samples.

**Output file (suggested):** `prototype-v2-spec.md` in `docs/product/07-prototype-v2/`. For richer specs, a `screens/` subfolder with one file per screen.

---

## How to conduct this step

1. **Read all three prior artifacts.** Step 2 (the prototype spec — screens, flow), step 5 (brand book — voice samples, anti-patterns), step 6 (design system — tokens, components, patterns).

2. **Per screen, refine the v1 spec with:**
   - **Components used.** Replace prose ("an input field") with explicit component references ("`Input` component, variant: text, label position: top").
   - **Token references.** Replace prose ("dark background") with semantic tokens ("`color-surface-inverse` background, `color-text-inverse` foreground").
   - **Voice in copy.** Every user-facing string the screen contains should match the brand voice samples from step 5. Surface this directly — don't write "[appropriate error message here]"; write the actual error message.
   - **State coverage.** For each component on the screen, name how its states (loading, empty, error, disabled, success) appear.

3. **Update the user flow if needed.** Brand and design-system rarely change the FLOW (steps), but may change the SHAPE (modal vs full-screen, single-step vs multi-step). If you change flow, note the change with reasoning.

4. **Patterns audit.** Walk through the screen list checking that the design system's patterns (step 6) are actually being applied. If a pattern is unused, either drop it from the system or surface that gap.

5. **Submit.** Step 7 closes Identity phase — the gate fires on `product_advance`. After submit, advance returns `code: "gate-required", phase: "identity"`. Parent confirms with user, calls `product_gate_pass("identity")`, then `product_advance` to enter Specification (step 8 PRD).

---

## Voice & rigor

- v2 is a REFINEMENT, not a redesign. If you find yourself rewriting screens wholesale, something's wrong upstream — back-flag to step 5/6 rather than fix in step 7.
- Concrete voice in copy. "Try again." beats "[error message]". If the brand voice is sardonic, the actual error string should drip with it — "Well, that didn't work. Want to try again?"
- Token references should map to step 6 names. If a screen references a token name not defined in the design system, add it to step 6 first (and update the artifact), or pick an existing token that works.
- v2 is the artifact a designer can render to high-fidelity from. After this, mockups can be drawn.

## What this step does NOT do

- High-fidelity visual design / mockups. Those are downstream of this spec.
- Component implementation (React / Vue / Swift). Implementation is post-pipeline.
- Marketing site design. Step 17 (GTM, future MCP).
