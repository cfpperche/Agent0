# Step 7 — Design fidelity checklist (Layer 2 scoring rubric)

Per-screen scoring against step 6's design system + step 5's brand. Five dimensions, each 1-5; any dim < 3/5 requires a fix pass before emit. Mirrors step 2's 5-dim rubric but tuned for re-render rather than mood-board emit.

Run this checklist on **every screen** AND on `direction-final.html`. Two fix passes is normal. Document the final scores in `REPORT.md § Design Fidelity Scores`.

---

## Per-screen structural checklist (pre-scoring)

Every screen + `direction-final.html` must pass every item below before the 5-dim scoring runs:

- [ ] Self-contained (no `<link>` to external stylesheets, no remote fonts, no CDN scripts) — opens cleanly via `file://`
- [ ] `:root` block inlines step 6's `tokens.css` content (or aliases per `token-mapping.md` § Path B)
- [ ] Every CSS color / font / spacing / radius / shadow value reads from `var(--token)` — zero raw `#hex` / `rgb()` / arbitrary `rem` literals (except hairline `1px` borders and `0` resets)
- [ ] Skip-to-content link is the first focusable element (carries through from step 2's a11y discipline)
- [ ] `:focus-visible` outline declared (passes step 4's F-01 family of findings)
- [ ] Every `<input>` / `<textarea>` / `<select>` has a matching `<label for>` pointing at a real form element ID (passes step 4's F-13 family)
- [ ] Semantic HTML used (`<nav>`, `<main>`, `<section>`, `<article>`, `<figure>`, `<button>` — not `<div role="button">`)
- [ ] Color contrast on every text-on-background pair ≥ 4.5:1 body / 3:1 large + UI (WCAG AA — step 6's `## Accessibility Floor` is the authoritative source)
- [ ] All applied audit findings carry a `<!-- fix(F-NN): ... -->` HTML comment at the locus
- [ ] No external dependencies, no console errors on load

A screen that fails the structural checklist gets fixed and re-checked BEFORE the 5-dim scoring runs. Scoring a structurally-broken screen pollutes the rubric.

---

## 5-dim scoring — per screen

Score 1-5 on each. Any dim < 3 requires a fix pass.

### 1. Token fidelity (1-5)

- **5** — every CSS value reads from a `var(--token)` defined in step 6's `tokens.css`; no aliases needed (rename path) OR aliases are explicit and consistent (alias path per `token-mapping.md` § Path B); no inline literals
- **4** — one or two utility classes use literal values (e.g. `border: 1px solid var(--color-border-1);` has the `1px` literal — acceptable hairline pattern); otherwise clean
- **3** — three or more inline literals across the screen; tokens consumed correctly but coverage incomplete
- **2** — major raw-value blocks (a card's colors all `#hex`, a section's spacing in arbitrary `px`); tokens declared but not consumed
- **1** — tokens.css imported but unused; the screen uses its own value layer

Below 3: rewrite the offending block to consume `var(--*)`, then re-score.

### 2. Brand voice in copy (1-5)

- **5** — every user-facing string (headings, buttons, empty states, error messages, microcopy, tooltips) reads in step 5's brand voice; a reader could identify the brand from copy alone
- **4** — 1-2 strings read slightly generic but don't drift OFF-brand (e.g. "Save changes" is fine but "Click here to save" wouldn't be); body copy is on-brand
- **3** — most copy is on-brand, but one section (often error messages or empty states — the easy-to-forget surfaces) reads generic
- **2** — multiple OFF-brand strings; the screen looks like the system but reads like generic SaaS
- **1** — placeholder text ("Lorem ipsum", "[error message]", "Button label"); voice forgotten entirely

Below 3: re-read step 5's `brand-book.md § Voice samples`, rewrite the offending strings, re-score.

### 3. Component fidelity (1-5)

- **5** — every component used on the screen matches step 6's `components.md` § Anatomy (slots, variants, states); states the screen needs (loading / empty / error / disabled / success) are present and styled per the system
- **4** — one component has a minor anatomy drift (e.g. icon slot ordered after label instead of before — visual variation, not structural break); states mostly covered
- **3** — one or two missing states (e.g. button-loading skipped because the screen is "static"); components match anatomy
- **2** — multiple components drift from `components.md` (e.g. screen invents a button variant not in the system); states broadly absent
- **1** — components on the screen don't match the system at all; ad-hoc designs

Below 3: bring the deviating component back to `components.md` shape; if the screen genuinely needs a new variant, surface in REPORT.md § Token Gaps and propose for step 6 next iteration.

### 4. Audit-fix coverage (1-5)

- **5** — every step-4 finding routed to this screen (per `prompt.md § 3`) is materially applied; each fix carries the `<!-- fix(F-NN): ... -->` annotation; each fix passes its own acceptance (e.g. `:focus-visible` rule actually present AND visible against the canvas at 1440px)
- **4** — all findings applied; one annotation comment was accidentally stripped; otherwise clean
- **3** — most findings applied; one minor finding (severity ≤ 2) was skipped with a documented reason in REPORT.md § Audit Response
- **2** — one severity ≥ 3 finding was skipped without documentation; OR a fix was applied but doesn't pass its acceptance (the `:focus-visible` rule was added but with `outline: none` somewhere overriding it)
- **1** — multiple findings routed to this screen are absent in the render; audit ignored

Below 3: apply the missing fixes, annotate, re-verify acceptance, re-score. Audit findings are acceptance criteria, not suggestions — see `prompt.md § Voice & rigor`.

When the screen has NO findings routed to it (step 4 frontmatter exists but no `fix_skill_hint: "prototype-v2"` finding mentions this screen), Audit-fix scores **N/A** — record as `—` in the table and skip the dimension's gate check. A screen with no routed findings still must clear the other 4 dims at ≥ 3.

### 5. Brief specificity (1-5)

- **5** — every word / number / label sourced from step 1 brief / step 3 functional-spec OR is a deliberate Part-2 invented placeholder consistent with step 2's identifier table (e.g. "@em.alex" persona handle locked in step 2's Part 2 — step 7 uses the same handle, doesn't re-invent)
- **4** — mostly brief-sourced; one or two strings drifted to plausible-invented but consistent with brief domain
- **3** — competent but generic in one section (e.g. landing page hero is brief-grounded but feature bullets read generic)
- **2** — pervasive generic copy; brief context lost
- **1** — filler / lorem ipsum / invented metrics that contradict step 1 or step 3 numbers

Below 3: re-read step 1's `04-concept-brief.md` and step 3's `functional-spec.md`, rewrite the offending strings with brief-sourced phrases (NOT lower the bar), re-score.

---

## Aggregate gate

| Screen | Token | Voice | Component | Audit-fix | Specificity | Min |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| direction-final.html | 5 | 4 | 5 | — | 4 | 4 |
| screens/01-landing.html | 4 | 5 | 5 | — | 5 | 4 |
| screens/05-triage-view.html | 5 | 4 | 4 | 5 | 4 | 4 |
| ... | | | | | | |

The Min column is the gate indicator (✓ if ≥ 3). Audit-fix shows `—` when no findings routed to that screen.

**Gate pass:** every screen's Min ≥ 3. Any Min < 3 blocks emit — fix that screen and re-score.

**Two fix passes is normal.** A first pass that emits every dim ≥ 3 is suspicious — pressure-test by spot-checking one screen's `var(--*)` usage against `tokens.css`, one string against brand-book voice samples, one component against `components.md`. If the spot-check holds, the scores are honest.

---

## When `direction-final.html` scores differently from screens

`direction-final.html` is the design-system showcase, not a product surface. Two implications for scoring:

- **Brand voice (dim 2)** scores against step 5's voice samples — the showcase still reads in brand voice, the section-titles ("Half the price. All the speed.") are real product taglines from step 5, not generic system labels
- **Audit-fix coverage (dim 4)** is always **`—`** for `direction-final.html` — the file isn't a product screen; the audit didn't reference it. The dim's gate check is skipped for this file.
- **Brief specificity (dim 5)** scores against step 1 brief identifiers but tolerates more "system-level demonstration" copy — the showcase exists to demo the system, not to render a specific user flow

Document the dim-4 N/A explicitly in REPORT.md § Design Fidelity Scores; otherwise readers wonder if the audit was skipped.

---

## Anti-slop quick-check (re-verify before emit)

Step 2's anti-AI-slop P0 gate carries forward to step 7. Quick reference — every box must be ✓:

- [ ] No aggressive purple / violet gradient backgrounds (unless brand-book explicitly calls for one)
- [ ] No generic emoji feature icons as decoration (✨ 🚀 🎯)
- [ ] No rounded card + left coloured border accent as default layout (unless brand-book calls for it)
- [ ] No hand-drawn SVG humans / faces
- [ ] Inter / Roboto / Arial used as body text only — never as display face (unless brand-book picked it for display)
- [ ] No invented metrics that contradict step 1 brief or step 3 spec
- [ ] No filler copy — zero lorem ipsum / "Feature One" / vague benefit bullets
- [ ] No motivational copy unless brand-book voice is explicitly motivational (PT-BR: "campeão", "você consegue"; EN: "you got this", "crush your goals")

A screen that trips an anti-slop rule blocks emit even if all 5 dims score ≥ 3. Fix the slop, re-score, then continue.
