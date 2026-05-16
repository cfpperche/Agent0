---
mode: synthesis
delegable: partial
delegation_hint: "re-render the picked direction from step 2 with brand (step 5) + design-system tokens (step 6) applied, inline-fixing step 4's fix_skill_hint:prototype-v2 findings; the screen list + N are inherited from step 2 Turn 2 (do NOT re-pick); per-screen render is delegable, REPORT cross-cutting + audit-response routing + Layer 3 checkpoint stay with parent"
---

# Step 7 — Prototype v2 (brand + tokens applied; audit fixes inlined)

**Goal:** the LAST step of the Identity phase. Re-render the screens picked in step 2 Turn 2 using the brand voice (step 5) and the design system (step 6), AND pre-fix every step-4 audit finding tagged `fix_skill_hint: "prototype-v2"` inline during the re-render. The output is a coherent, brand-clean, audit-cleared visual that closes Identity. **Identity-phase gate fires after this step** (`GATE_AFTER: [4, 7, 12]`).

**Mode:** `synthesis` with `delegable: partial`. The path decisions (which screen file maps to which step-2 source, which audit finding lands on which screen) stay with the parent because they need cross-screen view. The per-screen render itself is delegable — and SHOULD be delegated in parallel when N ≥ 6 (mirrors step 2 Turn 2's fan-out pattern).

**Output bundle** (atomic via `extra_files` — all files written together or none):

| File | Role | Floor |
|---|---|---|
| `direction-final.html` | the design-system-applied showcase — proves the brand+tokens hold together cohesively across surfaces; NOT just one of the screens | ≥ 10 KB |
| `screens/<NN>-<name>.html` × N | the picked direction's screens re-rendered with brand+tokens; N inherited from step 2 Turn 2 | ≥ 4 KB each |
| `REPORT.md` | run summary + per-screen design-fidelity scores + audit-response + brand-voice check + deviations | ≥ 6 KB |

`direction-final.html` is the **token-coverage check** — the at-a-glance surface a founder opens to verify "the design system holds together as a system". It is NOT just the step-2 direction file re-rendered; it composes the full token vocabulary (palette / type / spacing / radius / shadow / components) across the same section rhythm step 2 used, but now with the final brand-tuned values. Without it, the user has no single-surface way to gut-check the system before committing the screens.

---

## How to conduct this step

Read `references/token-mapping.md` (how step 6 tokens.css lands in HTML — class vs inline, semantic vs primitive routing) and `references/design-fidelity-checklist.md` (the Layer 2 scoring rubric vs step 6) before drafting. The audit-response pattern mirrors step 6's exactly — read `06-design-system/references/audit-response.md` for the canonical consumer shape; the differences for step 7 are captured in `references/audit-response.md`.

### 1. Read the inputs

- **Step 2 picked direction + Turn-2 screens** — `docs/product/02-prototype/`. The user picked one of `direction-a/b/c.html` between Turn 1 and Turn 2; the Turn-2 set lives in `screens/`. Identify the picked direction from step 2's REPORT.md § Turn 2 Plan + § Turn 2 — Hi-Fi Screens (it names which direction was rendered). Treat the picked direction file as the visual lineage and the `screens/` set as the source HTML to re-render.
- **Step 5 brand-book** — `docs/product/05-brand/brand-book.md`. Voice samples (ON-brand and OFF-brand pairs), motion principles, imagery posture, anti-patterns. The brand is what step 7 lays on top of the system.
- **Step 6 design-system bundle** — `docs/product/06-design-system/`. `tokens.css` is the canonical value layer (the file step 7 imports into every screen's `:root` verbatim), `components.md` is the anatomy + states spec, `design-system.md` is the narrative + `## Catalog Lineage` (catalog / custom / mixed path declaration — inherit it, do not second-guess).
- **Step 4 validation report + frontmatter** — `docs/product/04-ux-testing/validation-report.md`. **Parse the YAML frontmatter if present.** Filter `findings[]` by `fix_skill_hint: "prototype-v2"` — those are the findings step 7 must apply inline during re-render (typically `:focus-visible` restore, semantic HTML pass — real `<input>`/`<textarea>` with `<label for>`, bulk-action confirmation, missing skip-link). Each applied fix is documented in REPORT.md `## Audit Response` with the originating finding ID and which screen(s) materialized the fix.
- **Step 1 concept brief + Step 3 functional-spec** — for cross-referencing copy and user-flow shape when re-rendering. The brand-book provides voice; the brief + spec provide the strings (real product name, real persona handles, real mechanic vocabulary).

If any of step 2's picked direction screens, step 5 brand-book, or step 6 design-system bundle is missing, stop and report to the parent — don't fabricate the missing input. Step 4 frontmatter absence is acceptable (projected-mode audit); handle per § 3 below.

### 2. Inherit screen count + filenames from step 2 Turn 2

Step 7 does NOT re-pick N or rename screens. It re-renders the EXACT screens step 2 Turn 2 emitted. Read `docs/product/02-prototype/screens/` to enumerate the actual filenames (e.g. `01-landing.html`, `02-onboarding-import.html`, ..., `NN-empty-error.html`) and mirror them in `docs/product/07-prototype-v2/screens/` one-to-one.

Why inheritance, not re-pick:
- Step 2 already calibrated N to product class (§ 9 calibration table — 3-15 range; SMB SaaS lands 6-10, micro-product 3-5, marketplace 10-15). Re-picking would risk N-drift between Identity-phase artifacts.
- The user signed off on the screen list at step 2's Layer 3 checkpoint. Changing the list mid-Identity erodes that signoff.
- The audit (step 4) referenced specific screen filenames (`05-triage-view.html`, `07-command-palette.html` — see step 4 findings F-01 / F-02 / F-12 / F-13 location fields). Renaming screens breaks the audit-fix traceability.

**Schema enforces only the floor (`min_count: 3`)** — the inheritance discipline lives in this prompt. If step 2 Turn 2 had N=8 screens, step 7 emits 8 screens with the same names. If step 2 had N=4, step 7 emits 4. Deviations (e.g., merging two screens, splitting one) must be flagged in REPORT.md § Deviations from brand-or-system with a one-line rationale.

### 3. Route the audit findings

Read `references/audit-response.md` for the full procedure. Quick orientation:

**Frontmatter present + at least one `fix_skill_hint: "prototype-v2"` finding** (the typical case):

a. Filter the findings array. Typical patterns:
   - `:focus-visible` rule missing on a screen → inline CSS fix during re-render of that screen
   - `<span>` masquerading as `<input>` → replace with real `<input>` / `<textarea>` carrying programmatic `<label for>` (semantic HTML pass)
   - Missing skip-link as first focusable → add `<a class="skip-link" href="#main">Skip to content</a>` as the first focusable element of every screen
   - Bulk-action without confirmation pattern → wire a confirm-modal OR an undo-toast (decide once, apply consistently)
   - Loading / empty / error states absent → render them (mirror step 6 § Patterns)

b. Map each finding to the screen(s) named in its `location` field. The mapping is the parent's job — do it BEFORE dispatching per-screen sub-agents so each sub-agent receives only the findings it must materialize.

c. Apply the fix inline in the screen's HTML during render. Annotate each applied fix with an HTML comment at the locus: `<!-- fix(F-01): added :focus-visible rule per step 4 audit (location: screens/05-triage-view.html) -->`. The comment is the in-source audit trail; the REPORT documents the cascade.

**Frontmatter present but NO `fix_skill_hint: "prototype-v2"` findings** — emit the explicit empty-state line in `## Audit Response`: *"Step 4 emitted structured findings, none routed to prototype-v2. All findings actioned at step 6 (design-system) or deferred. No inline render fixes applied this step."* Plus the `### Findings reviewed (not actioned)` list with one bullet per non-applied finding + routing destination — mirrors step 6 § 6.

**Frontmatter ABSENT but the markdown body's `## Priority Recommendations` section names prototype-v2 fixes** (prose-routed audit — the audit had measurable findings but the auditor didn't emit structured frontmatter; common when the audit was hand-written or pre-dates step-4's frontmatter port). Parse the prose routing table — typically a "Step-7 critical" or "Acceptance criteria on prototype-v2" row naming finding IDs explicitly. Treat the named findings as if `fix_skill_hint: "prototype-v2"` had been set; apply each fix per § 3 + § 5, annotate with `<!-- fix(F-NN): ... -->`, document in `## Audit Response` per `references/audit-response.md` § "Prose-routed audit" template. Do NOT claim projected mode — that would misrepresent a measurable audit.

**No frontmatter AND no prose routing (truly projected mode)** — emit *"No prototype-v2-routed findings from step 4 audit (audit ran in projected mode — markdown spec input, no measurable findings to hand off). Render fidelity decisions made from first principles against step 6's `## Accessibility Floor`."*

The audit-response section is mandatory regardless — the regression mode is silently skipping it and giving the next reader no proof that step 7 consumed the audit.

### 4. Render `direction-final.html` — the token-coverage showcase

Before the screens, render the design-system holding-together check. This is the at-a-glance surface a founder opens to verify "the brand + tokens compose into a coherent system" before drilling into individual screens.

**Shape** — mirrors step 2's direction file section rhythm (header / palette strip / type sample / hero / dashboard / charts / pricing / DS lineage) but rendered with the **final** brand-tuned values from step 6's `tokens.css` (NOT the step-2 direction's original tokens). The 8-section rhythm proves token coverage across the full vocabulary. Anchor the same canonical strings step 2 enforces (`<!DOCTYPE html`, `<style`, `:root`, `--background` / `--foreground` / `--primary` — or whatever semantic equivalents step 6's `tokens.css` uses, e.g. `--color-canvas` / `--color-foreground` / `--color-accent`; the schema accepts the cross-naming via the contains-substrings list).

**Critical:** import `tokens.css` verbatim into `:root` (copy-paste the content of `docs/product/06-design-system/tokens.css` between the `<style>` tags' `:root { ... }`). This is the contract — step 7 consumes step 6's canonical values, it does not invent or re-derive. If a token referenced by a screen is absent from step 6's `tokens.css`, that's a gap to flag back to step 6 (REPORT.md § Token Gaps), not silently invent.

**Open with a brand-tagline line** in the HTML's `<header>`, sourced from step 5's brand-book voice samples. The surface should READ in brand voice, not just LOOK like the design system. This is the brand×design-system intersection check.

Canonical placement — the tagline sits in the topnav as a `<p class="brand-tagline">` element directly under the product mark, NOT inside an `<h1>` (the showcase's h1 is "Design system applied" or similar system-naming), NOT inline with body copy. The brand-mark + tagline pair is the same shape step 2's direction files used in their header section:

```html
<header class="topnav">
  <div class="brand">
    <span class="brand-mark">PRODUCT_NAME</span>
    <p class="brand-tagline">Voice sample echoing brand-book § Voice.</p>
  </div>
  <nav class="section-anchors"><!-- ... --></nav>
</header>
```

### 5. Render the screens — per-screen render (delegable for N ≥ 6)

Each screen in `docs/product/07-prototype-v2/screens/<NN>-<name>.html` re-renders the corresponding step-2 screen with brand + tokens + inline audit fixes. Two delegation patterns, by N:

**Sequential (N < 6)** — single agent (parent or sub-agent) walks the screens in order. Lower coordination cost; suitable for micro-products / CLI tools.

**Parallel sub-agents (N ≥ 6)** — parent dispatches one sub-agent per screen (or batches of 2-3) in the same response. Each brief locks ONE screen filename, the audit findings routed to that screen, and the path to step 6's tokens.css. This is the same fan-out pattern as step 2 Turn 2 — see `02-prototype/prompt.md` § 3.5 for the brief shape. Use `model: opus` for each sub-agent; sonnet times out on heavy step-7 templates (the screens carry both render + audit-fix application + voice-tuned copy in one pass).

**Per-screen render rhythm** — the discipline that separates a v2 re-render from a v1 retrace:

1. **Copy the step-2 source screen verbatim** as the starting point.
2. **Replace `:root` block** with step 6's `tokens.css` content. Do NOT rename tokens — if step 2 used `--background` and step 6 uses `--color-canvas`, the cleanest fix is to update the HTML's CSS selectors to use `var(--color-canvas)`; alternatively, alias the semantic names in `:root` (`--background: var(--color-canvas);`) for backwards compatibility. Document the choice once in REPORT.md, apply consistently. **At first per-screen render**, leave a one-line HTML comment at the top of that screen's `<head>` recording the choice (e.g. `<!-- token-path: B (alias) — step-2 primitives aliased to step-6 semantic names in :root; CSS selectors unchanged -->`); this is the scratch-buffer that prevents drift across N screens AND prevents inconsistency between what was actually shipped and what REPORT.md § Design System Applied claims at write-time.
3. **Apply the routed audit fixes** for this screen (per § 3). Annotate inline with `<!-- fix(F-NN): ... -->` HTML comments.
4. **Voice-tune the copy** — re-read step 5's `brand-book.md` § Voice samples and brand-check every user-facing string on this screen. Replace any string that reads OFF-brand. Concrete: "Try again." vs "Well, that didn't work. Want to try again?" depending on the brand voice's posture. Sardonic brand → sardonic empty states; warm brand → warm error messages. **If step 5's brand-book § Product Name designated a final name different from step 2's placeholder** (e.g. step 2 said "Linear-Clone" as a placeholder and step 5 picked "Octant"), that rename IS part of the brand-voice pass — apply consistently across all screens AND `direction-final.html`. Identifiers from external systems that were imported at step 2 (workspace IDs, issue ID prefixes the brief specified) may be preserved if historically meaningful for the persona; document any preserved identifier in REPORT.md § Run Summary so the rename audit is explicit. Silently shipping the placeholder name is the failure mode this clause prevents.
5. **State coverage** — for each component on the screen, verify its states (loading / empty / error / disabled / success) render per step 6's `components.md`. If a state was skipped in step 2 because the screen didn't exercise it, decide whether step 7 should add it (typical when the audit flagged a missing state) or carry the gap forward.
6. **No flow changes** — if the brand/design-system reveal a flow problem (e.g., the modal pattern no longer fits the brand posture), DO NOT redesign the flow in step 7. Flag the issue in REPORT.md § Deviations and continue with the original flow. Flow is step 2's contract; step 7 refines surface, not structure.

### 6. Self-critique — per-screen design-fidelity score + audit-fix coverage

For each screen + `direction-final.html`, score 1-5 across:

1. **Token fidelity** — every color / type / spacing value reads from a `var(--token)`; no raw literals; the `:root` block matches step 6's `tokens.css` exactly (or with documented aliases per § 5.2).
2. **Brand voice in copy** — every user-facing string reads in brand voice per step 5's samples; no generic SaaS filler ("Get started today", "Welcome aboard"); no off-brand drift (warm brand with cold strings = fail).
3. **Component fidelity** — components compose per step 6's `components.md` (anatomy + states + variants); no invented components; states the screen needs are present.
4. **Audit-fix coverage** — every step-4 finding routed to this screen is materially applied; the inline `<!-- fix(F-NN) -->` comment exists; the fix passes its acceptance (e.g., `:focus-visible` rule actually present and visible at 1440px against the canvas).
5. **Brief specificity** — every word / number / label sourced from the brief or self-citable; no filler; no invented metrics that drift from step 1/3 numbers.

Any dimension < 3/5 requires a fix pass before emit. Two fix passes is normal. Document the pre-emit scores in REPORT.md § Design Fidelity Scores. If a screen scores 5/5 across the board on the first pass, that is *also* worth noting — uniform 5s either reflect a fast convergence (good) or a bias-toward-passing (suspicious; pressure-test one screen by spot-checking the inline tokens vs the brand voice rules).

### 7. Write `REPORT.md`

Required level-2 sections (see `schema.md` for the floor):

- `## Run Summary` — picked direction (from step 2), brand-book path, design-system path, audit findings count + routing summary, output paths surfaced as `file://` URLs
- `## Design System Applied` — confirm catalog / custom / mixed path inherited from step 6 § Catalog Lineage; list the tokens.css token categories actually exercised in `direction-final.html` + the screens (color / type / spacing / radius / shadow / components); flag any token defined in step 6 that no screen consumes (over-engineered design system signal — surface it back to step 6 next iteration)
- `## Screen-by-Screen` — table or per-screen block: filename → step-2 source → audit findings applied (with IDs) → voice changes made (one-line examples) → component additions/state-coverage updates
- `## Audit Response` — per finding applied: ID, screen(s), before-state, after-state, fix annotation (the `<!-- fix(F-NN) -->` comment text); plus the `### Findings reviewed (not actioned at prototype-v2 layer)` list with routing destinations for findings landed elsewhere; empty-state line when no frontmatter (per § 3)
- `## Design Fidelity Scores` — table: Screen | Token | Voice | Component | Audit-fix | Specificity | Min. The Min column is the gate indicator (✓ if ≥ 3 across all five dims)
- `## Brand Voice Check` — sample 3-5 user-facing strings per screen, paired with the brand-book voice sample they echo. The discipline that prevents "looks like the design system, sounds like generic SaaS"
- `## Deviations from Brand or System` — every place step 7 deviated from step 5 or step 6 with a one-line rationale (e.g., "Step 6 specified `--space-1: 0.25rem` for compact density; screen 04-backlog uses 0.125rem on the bulk-action bar gap to fit 5 actions in the 1440px width — flag back to step 6 for a `--space-half` token next iteration"). Empty when no deviations — say so explicitly.
- `## Token Gaps` *(optional)* — design-system gaps surfaced while applying tokens (forwarded back to step 6 for next iteration). Common signals: a screen needs a shadow level step 6 didn't define, a missing semantic color, an undeclared component state.

### 8. Surface for user confirmation (Layer 3 checkpoint)

After REPORT.md drafts, do NOT call `product_step_submit` yet. Surface to user:

```
✅ Step 7 complete — prototype-v2 rendered with brand + tokens + audit fixes inline

  file:///<absolute-path>/direction-final.html  — design-system showcase
  file:///<absolute-path>/screens/01-<name>.html  — <one-line summary>
  file:///<absolute-path>/screens/NN-<name>.html  — <one-line summary>

  REPORT summary:
    · all N screens cleared design-fidelity ≥ 3/5 across 5 dimensions
    · M audit findings applied inline (F-01, F-02, F-12, F-13 — or per project)
    · K findings routed elsewhere (documented in § Audit Response)
    · D deviations from brand or system (documented in § Deviations)

  Open the URLs and confirm Identity is ready to close. Reply "looks good" to gate-pass, or name a specific screen that needs another pass.
```

Wait for user. The Identity gate fires here — do NOT call `product_gate_pass` or `product_advance` until the user confirms.

### 9. Submit

Call `product_step_submit` with:
- `step: 7`
- `filename: "REPORT.md"`
- `content: <full report>`
- `extra_files`: `[{path: "direction-final.html", content: ...}, {path: "screens/01-<name>.html", content: ...}, ..., {path: "screens/NN-<name>.html", content: ...}]`

Schema enforces presence + min_size + contains for all listed files; missing/undersized produces `code: "schema-incomplete"` with the failure list. All files persist atomically — nothing is written unless every file passes Layer 1.

### 10. Advance (gate-required: identity)

Call `product_advance`. Because `GATE_AFTER` includes 7, advance returns `code: "gate-required", phase: "identity"`. Parent confirms with user (the file:// URLs from § 8 are the gate-pass artifact), then calls `product_gate_pass("identity")`, then `product_advance` to enter Specification (step 8 PRD). The gate-pass is the user's explicit "Identity is done" signoff — it is not implicit in `product_step_submit`.

---

## Voice & rigor

- **v2 is a REFINEMENT, not a redesign.** Same flow, same screens, same N — surface treatment refines, brand voice tightens, audit findings clear. If you find yourself rewriting screens wholesale, back-flag to step 2/5/6 rather than fix in step 7.
- **Inline fixes carry their finding ID.** The `<!-- fix(F-NN): ... -->` HTML comment is the in-source audit trail. A reader of the HTML diff between step 2 and step 7 should see WHY each change happened, mapped to a finding ID or a brand-voice rule.
- **Token references map to step 6 names.** Every `var(--token)` in step 7 resolves against step 6's `tokens.css`. A token reference that doesn't resolve is a gap — flag back to step 6 via REPORT.md § Token Gaps, do not invent the missing token in this step.
- **Brand voice IS the copy.** Concrete strings, not placeholders. "Try again." or "Well, that didn't work. Want to try again?" — pick the one that matches step 5's voice. Never `[error message]`, never lorem ipsum.
- **Audit findings are acceptance criteria, not suggestions.** A `fix_skill_hint: "prototype-v2"` finding that step 7 emits without addressing is a discipline failure — surface it in `## Audit Response` § Findings reviewed (not actioned) with an explicit reason if intentionally deferred.

## What this step does NOT do

- **Pixel-perfect production code.** The HTML is hi-fi mockup — interactivity remains CSS-only unless an interaction is core to the brand expression.
- **Framework code (React / Vue / Svelte).** Step 13 (prototype-v3, NEW) synthesizes the picked direction into stack-native code when the spec demands it.
- **Brand voice deep-dive.** Step 5 owns voice; step 7 *applies* it.
- **Design tokens.** Step 6 owns tokens; step 7 *consumes* them.
- **Flow redesign.** Step 2 owns flow; step 7 keeps it. Deviations get flagged, not silently changed.
- **User testing of the mockups.** Step 4 ran the audit; step 7 closes its prototype-v2-routed findings. Re-validation is for post-launch (step 14+, future).

## What this step replaces

Step 7 is `anthill-prototype` re-invoked — anthill bundled the v1 mood-board pass AND the v2 brand+system-applied pass into a single 402-LOC SKILL.md. The MCP port splits them: step 2 is the v1 pass (mood boards + Turn-2 hi-fi screens, independent of brand/system), step 7 is the v2 pass (the same screens, now refined). The decomposition makes Identity-phase cycles observable — step 2 outputs go through the audit (step 4), the audit drives step 5/6/7 in a measurable cascade.

The **inline audit-fix consumption is new** (relative to anthill). Anthill's prototype skill didn't programmatically consume audit findings — any fixes downstream were the designer's manual responsibility. The MCP port closes the loop: step 4 emits YAML frontmatter (its port-improvement, see `04-ux-testing/schema.md`), step 6 reads it for design-system-routed fixes, step 7 reads it for prototype-v2-routed fixes, each documents the cascade in `## Audit Response`. This is the audit-as-delegation-manifest pattern made symmetric across the Identity phase's two artifact-producing steps (6 and 7).

The OD vendor (anthill's `.anthill/vendor/open-design/` + `.anthill/design-systems/`) is **already vendored in this package** (spec 027) — step 7 inherits the picked direction's catalog citations from step 2 (and step 6, when catalog-path), it does NOT re-shop the catalogue. Re-shopping mid-Identity would risk losing the user's signoff from step 2's Layer 3 checkpoint.
