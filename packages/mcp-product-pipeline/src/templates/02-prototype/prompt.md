---
mode: draft-after-input
delegable: partial
delegation_hint: "draft the prototype direction-spec — screen list, user flow, key interactions — from the concept brief; user already confirmed direction"
---

# Step 2 — Prototype

**Goal:** translate the concept brief (step 1 output) into a screen-level prototype spec: which screens exist, how the user moves between them, what each screen's primary affordance is. Output is a *spec for prototyping*, not pixels yet.

**Mode:** `draft-after-input`. Parent collects 2-3 directional choices from the user (entry surface, killer flow, complexity budget), then the parent OR a sub-agent drafts the screen-level spec. Drafting can be delegated via `product_get_delegation_brief(2)` after direction is locked.

**Output file (suggested):** `prototype-spec.md` in `docs/product/02-prototype/`. Optional: a `screens/` subfolder for one-screen-per-file breakdowns when the spec has 8+ screens.

---

## How to conduct this step

1. **Read the concept brief** at `docs/product/01-ideation/<your-file>.md`. Internalize the hook, target audience, and differentiation before drafting screens.

2. **Direction interview (parent only, 3 quick choices):**

   - "Entry surface: web app, mobile app, browser extension, CLI, embedded widget, or something else?"
   - "Killer flow — the *one* user journey that has to work flawlessly in v1. Pick one." (Don't accept "everything"; force the cut.)
   - "Complexity budget: 'minimal prototype' (3-5 screens, fake data is fine) or 'full happy path' (8-12 screens, real-ish backend behavior)?"

3. **Synthesise — drafting can delegate.** Once direction is locked, the documentation work is pure synthesis. Either the parent drafts inline OR calls `product_get_delegation_brief(2)` and dispatches an `Agent` sub-agent. The sub-agent has the same MCP tool surface — it reads the concept brief from `docs/product/01-ideation/`, drafts the spec, and submits via `product_step_submit`.

4. **Screen list — table form is fine, prose is fine.** Per screen, capture: route/name, primary affordance (the one thing the user does here), data shown, transitions in/out. Don't draw boxes-and-arrows yet — the spec exists so a designer can.

5. **User flow — text diagram preferred over ASCII art.** Sequential arrow form like `landing → signup → onboarding-step-1 → onboarding-step-2 → dashboard` is enough. Branches matter; mark conditional paths.

6. **Submit + advance.** Section validation runs on submit. Once written, call `product_advance` to move to step 3 (spec).

---

## Voice & rigor

- Screens are routes/views, not features. "Settings" is a screen; "user can change theme" is an affordance within it.
- The killer flow gets the most depth; secondary flows get one line each. Don't equally distribute attention — the prototype proves the bet, not the menu.
- Estimate screen count up front. If you're producing 20+ screens, the prototype is too big for step 2 — push complexity into step 7 (prototype-v2 after brand/design-system).
- For mobile or chat-style UX, "screens" may be states or message turns. Adapt the framing; don't force web metaphors.

## What this step does NOT do

- Pixel design. That's step 6 (design-system) producing tokens/components and step 7 (prototype-v2) re-rendering with brand applied.
- Functional spec. Edge cases, validation rules, business logic detail belong in step 3 (spec).
- User testing report. Step 4 (ux-testing) is where validation happens.
