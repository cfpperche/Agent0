---
mode: synthesis
delegable: true
delegation_hint: "draft the design system — tokens (color, typography, spacing, radius, motion), core components, patterns — applying the brand book to a working scale"
---

# Step 6 — Design System

**Goal:** translate the brand book (step 5) into a concrete design system — tokens, primitives, components, patterns. Output is the reference any designer/developer uses to render screens consistently. Pure synthesis.

**Mode:** `synthesis`. Fully delegable. Sub-agent reads `docs/product/05-brand/` + `docs/product/02-prototype/` (for screen inventory) and drafts the design system without user input.

**Output file (suggested):** `design-system.md` in `docs/product/06-design-system/`. For richer systems, a `tokens/` subfolder with `color.md`, `typography.md`, etc.

---

## How to conduct this step

1. **Read brand + prototype.** Brand for the feel (color story, voice, visual direction); prototype for the inventory (which UI primitives actually appear).

2. **Tokens first.** Define the atomic layer before composing:
   - **Color:** name palette + semantic mapping (primary / secondary / accent / surface / text / border / success / warning / danger / info). 6-12 hex values total in v1; resist palette inflation.
   - **Typography:** font family choices (with fallback stack), 4-6 size steps with line-height + weight per step, semantic mapping (h1/h2/h3/body/caption/etc).
   - **Spacing:** 4-or-8-base scale (4 / 8 / 12 / 16 / 24 / 32 / 48 / 64). Name them numerically (`space-4`, `space-8`) OR semantically (`tight` / `default` / `loose`); pick one convention.
   - **Radius:** 2-4 values (none, sm, md, full).
   - **Motion (if applicable):** 2-3 durations (`instant 150ms`, `quick 250ms`, `expressive 400ms`), 1-2 easing curves.

3. **Components — the v1 inventory.** From the prototype screens, derive which components must exist. Typical minimal set: Button (variants: primary, secondary, ghost, danger), Input (text, textarea, select, checkbox, radio), Card, Modal/Sheet, Toast, NavBar, Avatar, EmptyState. Per component: states (default, hover, active, disabled, error), spacing, typography use, anatomy.

4. **Patterns — composed structures.** Patterns are how components combine: form layout, list-with-empty-state, error-handling pattern, loading skeleton pattern, confirmation flow. Name 4-6 patterns that the prototype repeatedly needs.

5. **Accessibility floor.** Color contrast (target WCAG AA 4.5:1 for text), focus states visible by default, keyboard navigation contracts.

6. **Submit + advance.** Synthesis-mode, no gate. After submit, advance moves to step 7 (prototype-v2 — re-render the prototype with brand+design-system applied).

---

## Voice & rigor

- Resist tokens-by-the-yard. A v1 design system with 30 colors and 12 type scales is over-engineered. 8 colors and 5 type scales force the designer to make hard choices early, which is what good systems do.
- Tokens have semantic names, not visual names. `color-primary` survives a rebrand; `color-blue-500` doesn't. Both can co-exist (raw + semantic) but semantic is the consuming surface.
- Components describe ANATOMY + STATES, not implementation. "Button has [icon-slot]? [label] [icon-slot]?" beats "Button uses React.forwardRef and accepts className prop".
- If the brand voice was sardonic / playful / etc, that should appear IN the design system — error messages with a hint of voice, empty states that aren't generic "No items found". The design system enforces the brand.

## What this step does NOT do

- Implementation. This is a spec for designers + developers, not React components.
- Per-screen designs. Step 7 (prototype-v2) re-renders screens using these tokens/components.
- Marketing site design. Step 17 (GTM, future MCP) handles marketing assets.
