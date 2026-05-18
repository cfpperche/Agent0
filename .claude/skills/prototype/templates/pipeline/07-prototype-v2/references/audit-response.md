# Step 7 — Consuming Step-4 Audit Frontmatter (prototype-v2 layer)

The consumer-side spec for step 7's audit-response cycle. Mirrors `06-design-system/references/audit-response.md` (step 6's consumer pattern) with the differences that matter for step 7 — namely, fixes land as **HTML annotations in re-rendered screens**, not token edits in `tokens.css`.

Read step 6's audit-response.md first for the contract shape and the routing taxonomy. This page adds:
- Which finding patterns are prototype-v2 territory (vs design-system or deferred)
- How to inline a fix in HTML with an audit-trace comment
- How to distribute findings across screens when one finding references multiple screens
- The empty-state + projected-mode cases for step 7's perspective

## What's prototype-v2 territory (the routing filter)

Findings tagged `fix_skill_hint: "prototype-v2"` typically fall into these patterns:

| Pattern | WCAG / Heuristic | Inline fix shape |
|---|---|---|
| Missing `:focus-visible` rule | A11y 2.4.7 (Focus visible) | Add `:focus-visible { outline: 2px solid var(--color-accent); outline-offset: 2px; }` to screen's `<style>` |
| `<span>` masquerading as `<input>` | A11y 4.1.2 / 1.3.1 | Replace `<span class="typed">` with `<input type="text" role="combobox" aria-controls="..." aria-expanded="true">` |
| Missing programmatic label | A11y 1.3.1 / 3.3.2 | Add `<label for="field-id">Label text</label>` paired with real `<input id="field-id">` |
| Missing skip-link | A11y 2.4.1 (Bypass blocks) | Add `<a class="skip-link" href="#main">Skip to content</a>` as first focusable element |
| Bulk-destructive without confirmation | Heuristic 5 (Error prevention) | Wire confirm-modal pattern OR undo-toast pattern (decide once, apply consistently across screens) |
| Missing aria-live region | A11y 4.1.3 (Status messages) | Add `<div aria-live="polite" id="status">` to surface state changes |
| Missing semantic landmarks | A11y 1.3.1 (Info & relationships) | Replace `<div class="nav">` with `<nav>`, `<div class="content">` with `<main>`, etc. |
| Missing alt-text on informative images | A11y 1.1.1 (Non-text content) | Add `alt="..."` (or `alt=""` + `role="presentation"` for decorative) |
| Missing or empty loading/error/empty-state | Pattern coverage (step 6) | Render the missing state per step 6's `## Patterns` and `components.md` |

What's NOT prototype-v2 territory (leave for step 6 or deferred):

- **Contrast fails** — those are token tunes; step 6 owns them
- **Color-on-color hierarchy** — token tunes; step 6
- **Border / divider invisibility** — token tune OR documented "borders are decorative" policy; step 6
- **WCAG 2.2 readiness** — outside v1 scope, defer
- **Cosmetic polish (severity ≤ 1)** — defer to backlog

## How to inline a fix with an audit-trace annotation

The annotation is the in-source audit trail. A reader of the HTML diff between step 2 and step 7 should see WHY each change happened, mapped to a finding ID.

### Shape

```html
<!-- fix(F-01): added :focus-visible rule per step 4 audit (location: screens/05-triage-view.html, severity 4) -->
<style>
  /* ... existing styles ... */
  :focus-visible {
    outline: 2px solid var(--color-accent);
    outline-offset: 2px;
  }
</style>
```

The comment lives directly adjacent to the changed code. Three required fields:
- **Finding ID** — `F-01`, `F-12`, etc., from step 4's frontmatter
- **One-line description** — what the fix does, paraphrased
- **Location reference** — the file path + severity from the original finding's `location` and `severity` fields

When a fix cascades across multiple screens (e.g. `:focus-visible` rule applied identically to screens 05 and 07), each screen carries its own annotation — don't centralize. The audit trail must be locally visible in every affected file.

When a fix is structural (replacing `<span>` with `<input>`), annotate at the locus of the structural change:

```html
<!-- fix(F-12): replaced span-as-input with real <input role="combobox"> per step 4 audit (location: screens/07-command-palette.html, severity 3) -->
<input
  type="text"
  role="combobox"
  aria-controls="result-list"
  aria-expanded="true"
  aria-activedescendant="r1"
  aria-label="Search commands and issues"
  class="palette-typed"
/>
```

## Distributing findings across screens

A finding's `location` field often names multiple screens (`screens/02, 03, 06, 07, 08` — see step 4's F-13 example). Parent's job is to translate that list into per-screen sub-agent briefs.

Translation procedure:

1. **Parse the `location` field** — split by comma; resolve each entry to a screen filename in this step's `screens/` dir.
2. **Compose per-screen finding lists** — each sub-agent brief carries only the findings touching its screen. Sub-agent for `screens/02-onboarding.html` receives F-13 only if F-13's location includes screens/02.
3. **Apply the same fix shape consistently** — if F-13 routes the "real `<input>` everywhere" pattern, every affected screen gets the same shape (real `<input>` + matching `<label for>`), not screen-specific variations.
4. **Document the cascade in `## Audit Response`** — F-13 lands as one block in the section with the full screen list under the "Screens" header, not five separate sub-blocks per screen. The HTML annotations carry the per-screen trace.

### Location-with-no-failing-element edge case

A finding's `location` field may include a screen that has no failing element to fix — F-13 ("form fields not real inputs") might list `screens/02-onboarding-import.html` because the auditor scanned every screen's markup, but screen 02 is a read-only importer with no editable fields. There's nothing to convert.

In that case, the per-screen brief still references the finding (so the screen's REPORT row proves the cycle reviewed it), but the brief explicitly says "F-NN routed informationally to this screen — no failing element to fix; record as `— (informational)` in the Audit-fix scoring column". The screen still gets the audit-cycle visibility; it just doesn't carry an inline `<!-- fix(F-NN) -->` annotation because there's nothing to annotate.

Skipping the finding silently — leaving the screen with no acknowledgment that F-13 was considered — is the regression mode this guidance prevents. A reader of the screen's REPORT row should be able to tell "F-13 was reviewed for this screen and there was nothing to apply" vs "F-13 was forgotten for this screen".

## Documenting in `## Audit Response`

Per applied finding, one block (mirrors step 6's shape with shaped-for-render differences):

```markdown
### F-01 — Keyboard focus visible on triage view + command palette

**Heuristic:** A11y 2.4.7 (Focus visible)
**Severity:** 4 (critical)
**Screens:** screens/05-triage-view.html, screens/07-command-palette.html
**Before:** No `:focus-visible` rule in either screen's `<style>`; browser default focus ring is barely visible against the near-black canvas (`oklch(0.10 0.005 240)`)
**After:** Added `:focus-visible { outline: 2px solid var(--color-accent); outline-offset: 2px; }` to both screens' `<style>` blocks; verified outline visible at 1440px against the canvas (high-contrast against the cyan accent)
**Annotation:** `<!-- fix(F-01): added :focus-visible rule per step 4 audit (location: screens/05-triage-view.html, severity 4) -->` placed before each screen's `<style>` block
**Acceptance check:** opened each screen in a browser, tabbed through focusable elements, confirmed cyan outline visible on focus
```

Multi-screen cascades document the full screen list in the **Screens** header; the annotation text shows the canonical comment shape.

When a fix doesn't pass its acceptance on the first apply (e.g. the `:focus-visible` rule was added but a later `outline: none` declaration overrode it), the block carries an additional **Iterations** sub-line: `Iterations: 2 — first apply overridden by .btn { outline: none }; removed the global override, ran second apply, acceptance confirmed.`

## After per-finding blocks: routing trace

Two trailing sections close `## Audit Response`:

```markdown
### Batches resolved this step

- `keyboard-focus-restore` (F-01) — RESOLVED via `:focus-visible` rule on screens 05 + 07. Total effort: 5 minutes (matches step 4's `complexity_estimate`).
- `semantic-html-pass` (F-12, F-13) — RESOLVED via real `<input>` + `<label for>` on screens 02, 03, 06, 07, 08. Total effort: ~1 day.
- `bulk-action-confirmation` (F-02) — RESOLVED via undo-toast pattern on screen 04 (chose toast over confirm-modal because the persona is keyboard-first and a modal interrupts the flow). Total effort: ~half-day.

### Findings reviewed (not actioned at prototype-v2 layer)

- F-07 (tertiary text contrast) → routed to step 6 (token tune, design-system territory) — RESOLVED at step 6
- F-09 (tertiary text on alt surface) → routed to step 6 — RESOLVED at step 6 via same token edit
- F-10 (hairline borders below 3:1 UI floor) → routed to step 6 (documented as policy, no token change)
- F-15 (`prefers-reduced-motion` wrap) → deferred to backlog (cosmetic, AAA-only)
```

One bullet per non-applied finding in the second section. Each bullet names the finding ID + one-line summary + the routing destination + a one-line "why-not-here" justification. This is the audit trail that proves the prototype-v2 cycle DID consume the audit, even when most findings landed elsewhere.

## Empty case (no prototype-v2-routed findings)

When step 4 frontmatter exists but no findings have `fix_skill_hint: "prototype-v2"`:

```markdown
## Audit Response

*Step 4 emitted structured findings, none routed to prototype-v2. All findings actioned at step 6 (design-system) or deferred. No inline render fixes applied this step.*

### Findings reviewed (not actioned)

- F-07 (tertiary contrast) → step 6 (token tune) — RESOLVED at step 6
- F-09 (contrast on alt surface) → step 6 — RESOLVED at step 6
- F-10 (border discipline) → step 6 (policy added)
- F-15 (reduced-motion wrap) → deferred (cosmetic)
```

The reviewed-not-actioned list documents that the prototype-v2 cycle DID read the frontmatter, even though nothing landed at the render layer.

## Prose-routed audit case (frontmatter absent, but markdown § Priority Recommendations names prototype-v2 fixes)

When step 4 had measurable findings but the auditor didn't emit YAML frontmatter — common when the audit was hand-written or pre-dates step 4's frontmatter port — the routing typically lives in `## Priority Recommendations` as a markdown table. Look for rows naming finding IDs explicitly under a "Step-7 critical" or "Acceptance criteria on prototype-v2" label. Treat those finding IDs as if `fix_skill_hint: "prototype-v2"` had been set; apply per § "How to inline a fix" above; document in `## Audit Response` with the prose-routing source acknowledged:

```markdown
## Audit Response

*Step 4 audit ran without YAML frontmatter (hand-written / pre-port format), but `## Priority Recommendations` § Step-7 critical row routed F-02, F-03, F-12, F-13 to prototype-v2 explicitly. Treating prose-routed findings as if `fix_skill_hint: "prototype-v2"` had been set; per-finding blocks below.*

### F-02 — Bulk-action confirmation pattern
... (per-finding block per § "Documenting in `## Audit Response`" above)
```

Do NOT default to the projected-mode empty-state line in this case — that would misrepresent a measurable audit and silently drop the routed fixes. The prose-routed branch is named explicitly because skipping it is a real regression mode (the dogfood that surfaced this gap had a fully-prose-routed audit that an unguarded agent would have classified as projected-mode and ignored).

## No-frontmatter case (step 4 ran in projected mode — no prose routing either)

```markdown
## Audit Response

*No prototype-v2-routed findings from step 4 audit (audit ran in projected mode — markdown spec input, no measurable findings to hand off; `## Priority Recommendations` did not name prototype-v2 fixes). Render fidelity decisions made from first principles against step 6's `## Accessibility Floor` (focus indicator, semantic HTML, skip-link, label discipline).*
```

The explicit empty-state line is the contract. Skipping the section silently is the regression mode.

## Why this contract matters

Without the structured handoff + the HTML annotation discipline, the audit→render-fix loop is invisible. A finding like F-01 ("`:focus-visible` missing on triage") gets cleared, the screen looks correct, but a reader of the diff has no way to know that the fix was driven by an audit — it looks like a generic CSS addition. The annotation makes the lineage local; the `## Audit Response` table makes the cascade global. Together they make the prototype-v2 cycle's audit consumption traceable and auditable, closing the same loop step 6 closes at the token layer.

The pattern is symmetric: step 6 owns token edits, step 7 owns render edits, both consume the same frontmatter contract from step 4, both document via `## Audit Response`. Identity-phase observability is the goal — a reader of the four Identity artifacts (step 4 audit + step 5 brand + step 6 system + step 7 render) should be able to trace any audit finding from its origin to its resolution without re-reading the markdown bodies.
