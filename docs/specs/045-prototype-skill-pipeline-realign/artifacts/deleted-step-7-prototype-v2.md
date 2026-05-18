# Tombstone — deleted step 7 (prototype-v2) — preserved per spec 045 Decision 8 + 14

_Source: spec 045 (`docs/specs/045-prototype-skill-pipeline-realign/`); deletion ratified by founder 2026-05-18._

## Why deleted

Per spec 032 Decision 8 (ported by spec 045): the 3-prototype-pass shape (lo-fi → brand-tuned → atlas) was over-engineered. Cagan SVPG "Flavors of Prototypes" treats lo-fi + hi-fi as the natural pair; the mid-fi brand-tuned step is redundant work that delays the atlas without adding decision value.

Per spec 032 Decision 14: step 15 (renamed `screen-atlas`, was `prototype-v3` at slot 13) absorbs the brand+tokens-applied responsibility. There is now ONE hi-fi pass (Step 15) that consumes Step 14 design-system tokens AND fixes Step 04 audit findings AND produces full sitemap coverage.

## Rollback path

If acceptance gate E in spec 045 (Steward redogfood) reveals that hi-fi WITHOUT a mid-fi stop is too steep a jump from lo-fi (Step 02), reintroducing this step means: copy the prompt.md + schema.md + references/ below back into `.claude/skills/prototype/templates/pipeline/07-prototype-v2/`; renumber the post-7 slots back to v2 shape; update SKILL.md + delegation-briefs.md + pipeline-coverage.md + state-machine.md to acknowledge Step 7 again.

## Verbatim preserved content

<details>
<summary>Click to expand the deleted prompt.md + schema.md + references/ — restored byte-for-byte from spec 036 ship snapshot (2026-05-18 04:00 UTC)</summary>

### Original 07-prototype-v2/prompt.md

```markdown
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
```

### Original 07-prototype-v2/schema.md

```markdown
# Step 7 — Schema (prototype-v2: direction-final + screens + REPORT)

The submitted `REPORT.md` MUST contain the level-2 markdown headings below + meet the Layer 1 size/content floor in the JSON fenced block. All listed files must be persisted via the `extra_files` parameter on `product_step_submit`. Both checks fire on submit; missing sections OR Layer 1 failures produce `code: "schema-incomplete"` with the failure list.

## Required sections (REPORT.md markdown headings)

Section names slugify by lowercasing + dashing — `## Audit Response` → `audit-response`. Cosmetic variants (trailing punctuation, parenthetical suffixes) are accepted; slugifier strips them.

- `run-summary`
- `design-system-applied`
- `screen-by-screen`
- `audit-response`
- `design-fidelity-scores`
- `brand-voice-check`
- `deviations-from-brand-or-system` (accepts `deviations`)

## Optional sections (not enforced, but produced when applicable)

- `token-gaps` — design-system gaps surfaced while applying tokens (forwarded back to step 6 for next iteration)

## Layer 1 — file-level floor

```required_files
{
  "required_files": [
    {
      "path": "direction-final.html",
      "min_size": 10240,
      "contains": ["<!DOCTYPE html", "<style", ":root", "--color-", "var(--", "<svg"]
    },
    {
      "path": "REPORT.md",
      "min_size": 6144,
      "contains": [
        "## Run Summary",
        "## Design System Applied",
        "## Screen-by-Screen",
        "## Audit Response",
        "## Design Fidelity Scores",
        "## Brand Voice Check",
        "| Token | Voice | Component | Audit-fix | Specificity |"
      ],
      "any_of_contains": [
        "### F-",
        "*No prototype-v2-routed findings",
        "*Step 4 emitted structured findings, none routed to prototype-v2",
        "*Step 4 audit ran without YAML frontmatter",
        "<!-- fix(F-"
      ]
    }
  ],
  "required_glob": [
    {
      "pattern": "screens/[0-9][0-9]-*.html",
      "min_count": 3,
      "per_match_min_size": 4096,
      "per_match_contains": ["<!DOCTYPE html", "<style", ":root", "var(--"]
    }
  ]
}
```

### Notes on the floors

- **`direction-final.html` min_size 10240** (10 KB) — same floor as step 2's direction files. `direction-final.html` is the **token-coverage showcase** (see `prompt.md` § 4), not a re-rendered screen — it must exercise the full token vocabulary at section-rhythm depth, which lands well past 10 KB on a real port. Pivota's anthill v2 reference landed around 18-25 KB.
- `direction-final.html`'s `contains` enforces:
  - The `:root` token system + the `--color-` family prefix (token-naming inherited from step 6 — semantic namespace `--color-*`; step 2's primitive `--background`/`--foreground` are accepted as aliases per `prompt.md` § 5.2). **Note the trailing dash:** `--color-` (not `--color`) means a file declaring a single `--color: red` variable does NOT pass — the check requires a namespaced semantic token like `--color-canvas` / `--color-foreground` / `--color-accent`. Dogfood v2 (2026-05-16) surfaced this gap; v1 used `--color` (no dash) which was permissive.
  - The substring `var(--` — proxy for "tokens are actually consumed", not just declared in `:root`. A direction-final that declares all tokens but uses raw `#hex` literals everywhere trips this check
  - The substring `<svg` — proxy for the required charts/data-viz section (inherits step 2's data-viz discipline; the design-system showcase must exercise inline SVG token coverage just like step 2 does)
- **`screens/[0-9][0-9]-*.html` glob** — the `01-`, `02-`, ..., `NN-` shape inherited verbatim from step 2 Turn 2 (see `prompt.md` § 2 — inheritance discipline). `min_count: 3` is the **universal sanity floor** matching step 2; the actual N is inherited from step 2 (no re-pick).
- **`per_match_min_size: 4096`** matches step 2 — a screen below 4 KB is a stub. Step 7 screens often grow vs. step 2 (audit fixes + brand voice + token aliases all add bytes), so 4 KB stays the floor.
- **`per_match_contains`** enforces `:root` (step 6 tokens must be inlined per screen, not imported via `<link>` — keeps screens self-contained for `file://` opening) AND `var(--` (the tokens are consumed, not just declared). A screen that imports step 6's `tokens.css` content verbatim into `:root { ... }` AND uses `var(--*)` in its CSS rules passes both substrings.
- **`REPORT.md` min_size 6144** (6 KB) — covers the 7 required sections at honest depth. The 5-dim Design Fidelity Scores table alone runs ~30 lines on N=8 screens; § Audit Response carries before/after per applied finding; § Brand Voice Check needs 3-5 string examples per screen. Real ports land 12-18 KB.
- The `contains` substring list on REPORT.md is six anchor headings + the literal table-header row `| Token | Voice | Component | Audit-fix | Specificity |` from `## Design Fidelity Scores`. A REPORT that has the headings but omits the scores table (or names different dimension columns) trips Layer 1 because the structural row fragment is missing. **Why the literal pipe-delimited row, not loose substrings:** earlier iterations enforced standalone substrings (`"Token"`, `"Voice"`, ...), which a malformed report can satisfy from prose discussion alone (dogfood 2026-05-15 surfaced this — the substrings appear in prose throughout REPORT.md, so the check was silently fakeable). The full pipe-delimited fragment only appears as a markdown table header, restoring the structural floor the check is supposed to enforce.

## Section content guidance (depth, not just presence)

The schema enforces presence and floors; *depth* is the agent's responsibility per `prompt.md` § 7.

- **Run Summary** — picked direction name (from step 2's REPORT.md § Turn 2 Plan), brand-book path, design-system bundle paths (tokens.css + components.md + design-system.md), audit findings count + routing summary (e.g., "16 findings: 4 routed to prototype-v2 (F-01, F-02, F-12, F-13), 4 routed to design-system (F-06, F-07, F-09, F-10), 8 deferred"), output paths as `file://` URLs
- **Design System Applied** — confirm the catalog/custom/mixed path inherited from step 6 § Catalog Lineage; per-category checklist (color / type / spacing / radius / shadow / components) showing which tokens were exercised + which were defined-but-unused (over-engineered signal — flag back to step 6 next iteration). When a screen needed a token step 6 didn't define, note the gap inline AND in § Token Gaps if present
- **Screen-by-Screen** — table or per-screen block with five columns: `Filename | Step-2 source | Audit findings applied (IDs) | Voice changes (one-line examples) | Component/state additions`. The "voice changes" column is the brand×copy intersection check — one example per screen forces the discipline. Empty cells are valid (a screen with no audit findings routed to it shows `—` in that column)
- **Audit Response** — mirrors `06-design-system/references/audit-response.md` shape. Per-finding block: ID, screen(s), heuristic + severity, before-state (the markup pattern that failed), after-state (the markup pattern that now passes), HTML annotation (the literal `<!-- fix(F-NN): ... -->` comment placed in the screen). After per-finding blocks: `### Findings reviewed (not actioned at prototype-v2 layer)` list with one bullet per non-applied finding + routing destination. Empty-state line when no frontmatter (per `prompt.md` § 3)
- **Design Fidelity Scores** — table: `Screen | Token | Voice | Component | Audit-fix | Specificity | Min`. The Min column carries the gate indicator (✓ if ≥ 3 across all five dims). Any score < 3 should have been fixed in a pre-emit pass; if it lands in the final report, note the discipline failure in the row's notes column or in a follow-up paragraph
- **Brand Voice Check** — 3-5 user-facing strings per screen, each paired with the brand-book voice sample it echoes. The discipline that prevents "design-system applied, brand voice forgotten". Sample shape: `screens/05-triage.html: "Empty — go grab one." (echoes brand-book § Voice samples: "Direct, no hand-holding, slight smirk")`. When a brand-book voice sample doesn't fit any string on a screen, that's not a defect — list 3 strings instead of 5; the floor is 3
- **Deviations from Brand or System** — every place step 7 deviated from step 5's brand-book or step 6's design-system, one-line rationale per deviation. Empty when no deviations — say so explicitly (`*No deviations from brand or system in this step's render.*`); silently skipping the section is the regression mode
- **Token Gaps** *(optional)* — design-system gaps surfaced while applying tokens. List shape: `<gap>: <which screen surfaced it>: <recommended addition for step 6 next iteration>`. E.g., `--shadow-modal: screens/07-command-palette needed a hard-edge dialog shadow; step 6's --shadow-md is too soft (the cool-brutalist direction is hairline-only). Recommend step 6 add --shadow-modal or document the dialog-without-shadow choice.`

## Citations and named systems

Step 7 inherits step 2's design-system citations (in `direction-final.html`'s `<!-- lineage: ... -->` HTML comment header and `## Design System Applied` § Catalog Lineage in REPORT.md). It does NOT re-shop the OD catalogue — the user's Layer 3 checkpoint at step 2 locked the direction; re-shopping mid-Identity erodes that signoff.

When step 6 ran on a **custom path** (no catalog citation), step 7's `## Design System Applied` notes the custom-path inheritance and skips the catalog-citation block. When step 6 ran on **mixed path** (catalog anchor + deviations), step 7 inherits the same composition.

The Layer 1 `contains` check on `direction-final.html` does NOT enforce `design-systems/` substring (that's a step-2 concern). Step 7's discipline is brand+tokens applied to the inherited direction, not catalog re-citation.

## Atomic write semantics

`product_step_submit` validates ALL files in the bundle (primary `REPORT.md` + `extra_files`) before writing any. On any failure (missing section, undersized file, missing substring, glob count below floor) the response is `{ code: "schema-incomplete", failures: [...] }` and NOTHING is written. On success, all files persist atomically via mktemp+rename — the bundle is consistent or absent, never partial.
```

### Original 07-prototype-v2/references/

#### audit-response.md

```markdown
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
```

#### design-fidelity-checklist.md

```markdown
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
```

#### token-mapping.md

```markdown
# Step 7 — Token mapping (how step 6 tokens.css lands in HTML)

The contract for step 7's render: every color / type / spacing / radius / shadow value in `direction-final.html` and `screens/*.html` resolves to a `var(--token)` defined in `docs/product/06-design-system/tokens.css`. This page documents the mechanics of the substitution — how step 2's primitive tokens become step 6's semantic ones, how to handle naming mismatches, and where the canonical aliases live.

## The substitution contract

Step 2 declared its `:root` per direction (e.g. `--background`, `--foreground`, `--primary`, `--accent`, `--border`, `--muted` — six tokens, primitive names anchored to the direction's mood). Step 6 emits a richer, **semantic** token set (e.g. `--color-canvas`, `--color-foreground`, `--color-foreground-secondary`, `--color-foreground-tertiary`, `--color-accent`, `--color-border-1`, `--color-border-2`, plus `--font-*`, `--space-*`, `--radius-*`, optionally `--shadow-*`).

Step 7's job is to **carry the screens forward to the semantic vocabulary** without rewriting their structure. Two paths:

### Path A — Direct rename (recommended)

Find every `var(--background)` in the screen's CSS, replace with `var(--color-canvas)`. Same for the other 5 primitives. Apply consistently across all N screens AND `direction-final.html`. This is the cleanest landing — the HTML reads in step 6's vocabulary and a reader can grep for `--color-canvas` across the workspace and find the semantic intent.

When to pick this path: step 6's token names are recognisably semantic versions of step 2's primitives. Mechanical rename, no ambiguity.

### Path B — Alias in `:root`

Keep the screen's `var(--background)` references unchanged. In each screen's `:root` block, alias the primitives to the semantics:

```css
:root {
  /* step 6's canonical semantic tokens */
  --color-canvas: oklch(0.10 0.005 240);
  --color-foreground: oklch(0.96 0.005 240);
  --color-foreground-secondary: oklch(0.72 0.010 240);
  --color-foreground-tertiary: oklch(0.55 0.010 240);
  --color-accent: oklch(0.78 0.18 200);
  --color-border-1: oklch(0.20 0.010 240);
  --color-border-2: oklch(0.30 0.012 240);
  /* … */

  /* step 2 aliases — preserved so the screens' CSS doesn't have to be rewritten */
  --background: var(--color-canvas);
  --foreground: var(--color-foreground);
  --primary: var(--color-accent);
  --accent: var(--color-accent);
  --border: var(--color-border-1);
  --muted: var(--color-foreground-tertiary);
}
```

When to pick this path: step 2's HTML is dense and rewriting CSS selectors carries regression risk; or step 6's semantic names don't map 1:1 to step 2's primitives (e.g. step 2 had one `--border`, step 6 distinguishes `--color-border-1` / `--color-border-2`). The alias block makes the mapping explicit and locally visible.

**Pick the path once, apply consistently.** Mixing Path A on some screens and Path B on others creates an audit nightmare. Document the choice in `REPORT.md § Design System Applied`.

## What "canonical token names" mean per category

Step 6's `tokens.css` is the source of truth. Step 7's screens consume from there. Common categories + typical canonical names:

| Category | Typical semantic names | Notes |
|---|---|---|
| Color — canvas | `--color-canvas`, `--color-surface`, `--color-surface-2` | Background scale; brand-tuned by step 5 |
| Color — foreground | `--color-foreground`, `--color-foreground-secondary`, `--color-foreground-tertiary` | Text colors; tertiary is the body-meta level |
| Color — accent | `--color-accent`, `--color-accent-2` (optional) | Primary brand accent; max 1-2 |
| Color — semantic | `--color-success`, `--color-warning`, `--color-danger`, `--color-info` | State communication; brand-tuned hue family |
| Color — border | `--color-border-1`, `--color-border-2` | Border scale; primary load-bearing + secondary subtle |
| Type — family | `--font-display`, `--font-body`, `--font-mono` | Each is a font-stack with fallbacks |
| Type — scale | `--text-xs`, `--text-sm`, `--text-base`, `--text-lg`, `--text-xl`, `--text-2xl`, `--text-3xl`, `--text-4xl` | Paired with line-height + weight |
| Spacing | `--space-1` through `--space-8` (or `--space-tight-*` / `--space-spacious-*` when split) | Derived from density base |
| Radius | `--radius-none`, `--radius-sm`, `--radius-md`, optionally `--radius-full` | Brutalist directions often `--radius-none` only |
| Shadow | `--shadow-sm`, `--shadow-md`, `--shadow-lg` | Optional — direction may explicitly omit |

If step 6's `tokens.css` uses different names (e.g. `--background-primary` instead of `--color-canvas`), inherit step 6's names verbatim — DO NOT rename step 6's tokens to match this table. The table is illustrative; step 6's file is canonical.

## When a screen needs a token step 6 didn't define

This is the **token gap** signal. The screen wants a `--shadow-modal` (hard-edge dialog shadow); step 6's `tokens.css` defines `--shadow-sm` / `--shadow-md` / `--shadow-lg`, all of which feel too soft for the cool-brutalist direction's hairline aesthetic.

**Do not invent the token inline.** Two valid responses:

1. **Use the closest existing token + flag the gap in REPORT.md § Token Gaps** with a one-line recommendation for step 6 next iteration (`Recommend step 6 add --shadow-modal for hard-edge dialog elevation, or document that the direction is hairline-only and dialogs use 2px border-1 instead.`).
2. **Skip the shadow entirely and replace with a `--color-border-1` 2px outline** — i.e., make the design choice that aligns with the direction's posture (hairline brutalism doesn't have shadows). Document the choice in `## Deviations from Brand or System`.

Inventing `--shadow-modal: 0 0 0 2px black;` inline in a screen is the failure mode — the token escapes step 6's canonical definition and lives only in one screen; the next iteration of step 6 won't see it, and the screen drifts out of the system.

## When step 5's brand-book pulls a token in a direction step 2 didn't anticipate

The brand-book might call for a warmer canvas than step 2's direction chose (step 2 picked a Cool Brutalist with `oklch(0.10 0.005 240)`; step 5's brand voice reads "warm humanist" and step 6 ended up at `oklch(0.12 0.008 60)` — slightly warmer hue, same lightness). Step 7 inherits step 6's value verbatim — the screens get the warmer canvas, even though step 2's direction file still has the original cool value.

This is expected. The user's Layer 3 signoff at step 2 was on the *direction* (mood, hierarchy, system composition), not on the exact hex values. Step 5/6 refine those values; step 7 lands them. Document the shift in REPORT.md § Run Summary so the user sees the cascade explicitly.

## Self-contained file discipline

Every screen + `direction-final.html` MUST be self-contained — opening it directly via `file://` shows the full design without network access. This means:

- **No `<link rel="stylesheet" href="tokens.css">`** — inline the `:root` block verbatim in the screen's `<style>` tag.
- **No `@import url(...)` of remote fonts** — system-stack fallbacks only (`font-family: 'IBM Plex Mono', ui-monospace, 'SF Mono', Menlo, monospace;`). The brand-book may name a specific font; the screen's `--font-body` token can reference it, but the actual loading is a system-stack assumption.
- **No external CSS frameworks** (Tailwind, Bootstrap, etc.) — step 7's HTML is hi-fi mockup, not production code. Step 13 (prototype-v3, NEW) handles stack-native rendering when the spec demands it.

The schema's Layer 1 `per_match_contains: [":root", "var(--"]` enforces inline + token-consuming patterns. A screen that imports tokens via `<link>` and uses `var(--*)` in CSS rules WOULD pass the substring check (the substrings appear in the linked file when inlined), but a reviewer opening `file://` would see the screen unstyled — discipline failure surfaced at review, not at submit.

## Cross-step traceability

A reader of `screens/05-triage-view.html` should be able to trace any visual choice through:

1. The `:root` block → step 6's `tokens.css` (the value layer)
2. A `<!-- fix(F-NN): ... -->` HTML comment → step 4's findings frontmatter (the audit-driven changes)
3. A user-facing string → step 5's brand-book voice samples (the brand layer)
4. The component structure (e.g., `<article class="issue-card">`) → step 6's `components.md` § Anatomy (the system layer)
5. The screen filename → step 2's Turn-2 emit (the structural origin)

Five-step traceability is the audit trail step 7 produces. When any link in the chain breaks (a `var(--unknown-token)`, a string with no brand-book echo, a component shape that doesn't match `components.md`), that's a defect to surface in REPORT.md § Deviations or § Token Gaps.
```

</details>
