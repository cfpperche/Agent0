---
mode: interactive
delegable: partial
delegation_hint: "render Turn 2 hi-fi screens from a locked direction + concept brief (sub-agent gets direction tokens + brief via context; cannot conduct user discovery interview)"
---

# Step 2 — Prototype (HTML mood boards + hi-fi screens)

**Goal:** produce 3 genuinely distinct HTML mood boards proposing visual directions, plus a REPORT.md self-critique, plus 8 hi-fi screens of whichever direction the user picks. The output materializes the central thesis of this pipeline — HTML you can open in a browser is the artifact, NOT a markdown spec describing one.

**Mode:** `interactive`. Two turns separated by a user checkpoint:
- **Turn 1** (discovery → 3 directions → REPORT) — agent runs discovery, generates 3 mood boards as standalone HTML files (each with palette swatches, type sample, hero sample, dashboard sample, mood blurb), writes `compare.html` side-by-side + `REPORT.md` with 5-dim critique and anti-AI-slop audit
- **Turn 2** (8 hi-fi screens of picked direction) — gated by a Layer 3 checkpoint where the user picks one direction. Agent then renders 8 product screens at high fidelity using picked direction's tokens

Sub-agent delegation is `partial`: Turn 2 (screen rendering from a locked direction + brief) can be delegated; Turn 1 cannot — it requires the user channel for discovery and direction pick.

**Output files** (all under `docs/product/02-prototype/`):
- `direction-a.html`, `direction-b.html`, `direction-c.html` — 3 mood boards, ≥ 8 KB each
- `compare.html` — side-by-side comparison surface, ≥ 2 KB
- `REPORT.md` — primary artifact submitted to `product_step_submit`, ≥ 6 KB
- `screens/<NN-name>.html` × 8 — Turn 2 hi-fi screens, ≥ 4 KB each

---

## How to conduct this step

### 1. Read the prior concept brief + extract identifiers

Call `product_step_get(1)` and read `04-concept-brief.md`. Extract: product name + tagline + audience + JTBD + identity (scale / model / AI-nativity), key competitors, and any brief-stated brand preferences (PT-BR? dark-first? brutalist? specific accent color? Pix-first?). The brief is the authoritative source — directions reference IT, not invented context.

**Pin a TWO-PART identifier extraction in chat BEFORE writing any HTML.** This is the discipline that separates brief-grounded mockups from plausible-but-substituted ones. **CRITICAL:** real concept briefs rarely contain every concrete identifier a mood board needs (e.g., persona handles, issue ID prefixes, specific sprint numbers are usually abstract in the brief). Treating an invented placeholder as "brief-sourced" is the failure mode this section prevents.

**Part 1 — Brief-sourced identifiers (verbatim with source quote)**

Enumerate ONLY values that appear literally in the brief. Each row needs a source quote so a reader can verify.

| Identifier type | Source quote (exact text from brief) | Verbatim value |
|---|---|---|
| Product name | "<exact quote>" (Identity block) | `<value>` |
| Pricing tier values | "<exact quote>" (Monetization Sketch table) | `<value>` (e.g., "$0 / $4 / $7") |
| North-star metric name + value | "<exact quote>" (Business Model § Key Metrics) | `<value>` |
| Currency format | "<exact quote>" (Identity for PT-BR products) | `<value>` |
| Persona TYPE labels | "<exact quote>" (Target Persona table) | `<value>` (e.g., "Senior IC", "Engineering Manager" — abstract types) |
| Performance claims | "<exact quote>" (Hook or Mechanics) | `<value>` (e.g., "100 ms load", "20 issues") |
| Any named system / loop / mechanic | "<exact quote>" (Mechanics Breakdown) | `<value>` |

If a row has no source quote, it does NOT belong in Part 1. Move it to Part 2.

**Part 2 — Plausible-invented placeholders (clearly marked as invented)**

Enumerate placeholders the brief did NOT provide concretely but the mood board needs (issue ID prefixes, persona slugs/handles, specific sprint numbers, dashboard row content). Mark each one as invented and lock it for consistency across all 3 directions.

| Identifier type | Why brief didn't provide | Locked invented value | Note |
|---|---|---|---|
| Issue ID prefix | Brief describes abstractly, no concrete prefix | `<value>` (e.g., "SWF-" — chosen) | Consistent across all 3 directions |
| Persona slug / handle | Brief gives persona TYPES, not slugs | `<value>` (e.g., "@senior.ic") | Mark as placeholder in REPORT |
| Specific sprint number | Brief gives "sprint" abstractly | `<value>` (e.g., "Sprint 19") | Plausible placeholder |
| Specific cycle time | Brief might give range or absent | `<value>` (e.g., "3.2d") | Mark as plausible |
| Dashboard issue titles | Always invented | `<value>` × 5-7 | Realistic to brief domain |

After pinning BOTH parts, treat them as the **complete name list for the HTML phase**. Every dashboard row / metric / hero / pricing tile uses Part 1 values for verifiable brief grounding AND Part 2 values for consistency across directions. The REPORT.md § "Brief Compliance Check" must distinguish which is which — "Pricing $0/$4/$7 (verbatim from brief)" vs "Issue IDs SWF-247/248 (invented placeholder, plausible to brief domain)".

Conflating the two — claiming an invented "@mara.ic" persona handle was "brief-sourced" — weakens Specificity at D7 AND misleads the next reader. Score honesty starts here.

### 2. Discovery (5-7 questions in chat, prose)

The brief usually answered most of these. Only ask what's genuinely missing. One question at a time, accept short answers, prose not forms.

1. **Output surface.** Multi-screen app prototype, marketing landing, or both?
2. **Primary surface.** Desktop / mobile / both?
3. **Visual tone.** Pick 2-3 adjectives: editorial / minimal / warm / technical / brutalist / playful / corporate / fintech-clean.
4. **Brand context.** Existing brand spec? Reference site to match? Or "pick a direction for me"?
5. **Density.** Information-dense (Datadog, Linear) or spacious (Notion, Stripe)?
6. **Language.** Single language or i18n needed? (PT-BR products: confirm Pix + LGPD presence.)
7. **Constraints.** Hard "no" on a pattern? Target competitor to differentiate from? Must-have palette anchor?

**Skip discovery entirely if the brief explicitly enumerates 3 directions** (e.g., "propose 3 directions: dark-technical, warm-soft, brutalist"). Treat the brief as pre-answered.

### 3. Pick 3 direction families (genuinely distinct)

**OD vendor pre-flight — do this first.** Read `references/od-bridge.md`, then call `product_design_systems_index`. It returns the 72-system catalogue (`{name, mood, palette_summary}` each) plus a `vendor_paths` map of absolute roots. For each direction, shortlist 1-4 vendored design systems, call `product_design_system_path("<system>")` for each, and `Read` the returned `DESIGN.md` — that vendored, pinned file is the compositional source (palette roles, typography rules, component stylings, layout principles) for the direction, replacing training-data guesswork. Also read `<vendor_paths.prompts>/directions.extracted.md` for the 5 canonical schools' full specs. If `product_design_systems_index` returns `code: "od-vendor-missing"` (broken install) or `code: "od-disabled"` (OD grounding deliberately switched off via `PRODUCT_PIPELINE_OD=off`), surface the error and fall back to `references/pipeline.md` § "Manual escape — OD vendor unavailable".

The 5 schools (editorial-monocle / modern-minimal / warm-soft / tech-utility / brutalist-experimental) are starting families — each direction maps to one, or a justified blend.

**Hard rule:** the 3 directions must come from genuinely different angles — different palette family, different typographic personality, different layout posture. NOT three takes on the same green. If two directions land in the same school, drop one and pick a contrasting school.

Per direction, pin in chat BEFORE writing HTML:
- **Codename** (e.g., "Operador Silencioso", "Calma Estratégica") — visual DNA reference, not marketing label
- **Palette** — 6 tokens (background / foreground / primary / accent / border / muted) with exact `hsl()` / `oklch()` values, taken from the consulted `DESIGN.md` files (verbatim, not improvised)
- **Type** — heading font family + body font family + signature weight
- **Layout posture** — density level + container max-width + signature shape (e.g., "hairline borders, near-zero radius, dark canvas")
- **Mood blurb** — one sentence in product voice (PT-BR if Brazilian) — why this direction
- **Citation chain** — 1-4 vendored design systems composed, each cited in REPORT.md by name **and** `DESIGN.md` path (`design-systems/<system>/DESIGN.md`). Name-drop without the path is not a citation

### 4. Build the 3 mood-board HTMLs

Read `references/visual-constraints.md` + `references/a11y-checklist.md` + `references/anti-patterns.md` BEFORE writing. When the OD vendor is available, seed each file from `<vendor_paths.skills>/web-prototype/assets/template.html` (pre-baked token system + class inventory) rather than the bare scaffold — see `references/od-bridge.md` § *Build phase*. Each `direction-{a,b,c}.html` is a **MOOD BOARD** — a sequence of labeled DEMONSTRATION sections each showing one UI surface (hero / dashboard / pricing / etc.) rendered in the direction's tokens. Read as a cohesive document with landing-page narrative flow (eyebrow + title + lead + body rhythm), but the framing is "here's how X looks in this design system" — NOT "marketing landing page that happens to use these tokens".

**Critical distinction:** sections are SAMPLES of UI surfaces, not the surfaces themselves in production framing. A "hero sample" section presents the hero design pattern; it is NOT the product's marketing landing-page hero with codename badge above it. A "dashboard sample" section presents the dashboard design pattern; it is NOT the user's actual triage view.

**Section rhythm (mandatory for every content section)** — use a 4-layer pattern that gives the direction a landing-page narrative flow:

```html
<section class="section" aria-labelledby="section-<n>-title">
  <p class="section-eyebrow">SHORT LABEL CAPS</p>                   <!-- 1. eyebrow: small uppercase tracking label -->
  <h2 class="section-title" id="section-<n>-title">                  <!-- 2. title: headline that makes the point -->
    Headline that makes the point about this surface.
  </h2>
  <p class="section-lead">                                            <!-- 3. lead: one-sentence intro framing the content -->
    One sentence that frames what the reader is about to see and why it matters for this direction.
  </p>
  <div class="section-body">                                          <!-- 4. body: the actual surface (kanban, pricing tiles, etc.) -->
    <!-- pricing tile grid / kanban / metric cards / etc. -->
  </div>
</section>
```

This is the **discipline that separates landing-page cohesion from loose sections**. Headings alone are not enough; the eyebrow + title + lead trio gives every section narrative entry. Anthill's reference output uses this rhythm consistently across every content section — adopt it. The header (#1) and palette strip (#2) sections may use a lighter variant (no lead) but content sections #3-#6 must carry all 4 layers.

Eyebrow content — use these EXACT labels (or close variants that explicitly name the section type — NOT the section content):

| Section | Required eyebrow content | Examples that DON'T pass |
|---|---|---|
| Type sample | `TYPOGRAPHY` or `TYPE SAMPLE` | `THE LETTERFORM` (content, not section type) |
| Hero sample | `HERO SAMPLE` or `HERO` or `THE HOOK` | `hero-pill` badge with codename — replaces eyebrow, fails the section-rhythm check |
| Dashboard sample | `DASHBOARD SAMPLE` or `DASHBOARD` or `TRIAGE VIEW` | `KEYBOARD-FIRST` (that's a feature theme, not section type) |
| Charts & sparklines | `CHARTS & SPARKLINES` or `DATA VIZ` or `CHARTS` | `CYCLE TIME` (that's the chart subject, not section type) |
| Pricing tile grid | `PRICING` or `PRICING TILES` | `PLANS & TIERS` is fine; `HALF THE PRICE` is the h2 title, not eyebrow |
| Personality footer | `DESIGN SYSTEM LINEAGE` or `INFLUENCES` or `DS LINEAGE` | `BUILT ON` (too vague) |

The eyebrow labels the **section type**; the h2 below it makes the point. Conflating the two — putting a codename badge or a content-theme phrase where the eyebrow should be — is the failure mode that produces "marketing landing page" feel instead of "mood board demonstration".

Title examples (one sentence, makes the point, NOT just the section name):
- Pricing → "Half the price. All the speed." (NOT "Pricing tiers")
- Dashboard → "Sprint health, instant triage." (NOT "Dashboard sample")
- Hero → "Five keystrokes to triage your sprint." (NOT "Hero sample")
- DS lineage → "Built on hairline restraint." (NOT "Design system lineage")

Required sections per file (all 8 mandatory, in this order, visible at 1440px + 375px without horizontal overflow). Sections #3-#8 ALL use the 4-layer rhythm with the eyebrow content from the table above:

1. **Header / topnav** — product name + section anchors (palette / type / hero / dashboard / charts / pricing / lineage). Lighter rhythm (no lead). This is the page chrome, not a content section. Anchors verify that all 8 sections exist and are scrollable from the topnav.
2. **Palette strip** — 6 swatches with name + value. Eyebrow `PALETTE` + h2 title + 6 swatches; lead optional.
3. **Type sample** — eyebrow `TYPOGRAPHY` + h2 + lead + body showing H1 / H2 / body / mono / caption at signature weights.
4. **Hero sample** — eyebrow `HERO SAMPLE` (or `HERO` / `THE HOOK`) + h2 + lead + body. Body contains the demonstration: title + subtitle + CTA + visual mockup (terminal demo, command palette UI, kanban preview — pick one anchored to the brief's hook). The eyebrow is REQUIRED; a `hero-pill` codename badge above the h1 is NOT a substitute. The hero sample is a DEMONSTRATION of how the hero pattern looks in this direction's tokens — it is NOT the product's actual marketing landing-page hero.
5. **Dashboard sample** — eyebrow `DASHBOARD SAMPLE` (or `DASHBOARD` / `TRIAGE VIEW`) + h2 + lead + body. Body contains the demonstration: a realistic product surface (kanban / metric cards / data table / triage view) rendered in this direction's tokens. Use REAL data — Part 1 (brief-verbatim) for verifiable numbers, Part 2 (locked invented placeholders) for content like issue titles and persona handles. Never lorem ipsum. The dashboard sample is a DEMONSTRATION of how the dashboard pattern looks in this direction — it is NOT the user's actual triage workspace.
6. **Charts & sparklines sample** — eyebrow `CHARTS & SPARKLINES` (or `DATA VIZ` / `CHARTS`) + h2 + lead + body. Body contains AT LEAST TWO data-viz instances:
   - **One brief-grounded chart (mandatory)** — render the brief's named north-star or hero metric as a primary chart (line, bar, or area). For SwiftBoard the brief names cycle-time / triage velocity / sprint health — pick whichever maps to a real chart treatment (line chart of cycle-time over 30 days is the canonical pick). Render inline SVG using direction's tokens; no external libs. Include axes, axis labels with `font-variant-numeric: tabular-nums`, and 7-30 data points.
   - **One flexible second chart (mandatory but type-flex)** — your pick: 2-3 inline sparklines next to metrics, a small bar chart, a donut, a heatmap row, an area chart. Whichever exercises a DIFFERENT data-viz pattern than the primary chart so the direction's full data-viz token vocabulary is visible.
   - Use direction tokens for chart strokes/fills/axes (`var(--primary)` for primary line, `var(--accent)` for highlights, `var(--border)` for axes, `var(--muted)` for axis labels)
   - Tabular numerics on all axis labels and inline values (`font-variant-numeric: tabular-nums`)
   - The chart `<figure>` carries a `<figcaption>` prose summary per a11y rule #4
7. **Pricing tile grid** — eyebrow `PRICING` + h2 + lead + body. Body contains 3 tier cards using the brief's pricing values verbatim (Part 1 of the extraction table). The Pro tier carries a "Most Popular" emphasis (badge, border highlight, or scale). Each tile lists 3-5 feature bullets and a CTA. Dedicated UI surface block, NOT inline hero copy. Free-tier-only products surface a "Free forever" tile + roadmap-tier preview tiles. Token-economy products use pacote tiers (`Otimizar CV · 3🪙`, `Pacote · 8🪙`, `Pacote · 20🪙`).
8. **Personality footer / Design System Lineage** — eyebrow `DESIGN SYSTEM LINEAGE` (or `INFLUENCES`) + h2 + lead + body. Body contains the DS citation chain (1-3 named systems with concrete reference details — "Linear's hairline borders + cv01/ss03 OpenType + tight letter-spacing", NOT just "modern minimal") + one paragraph on what kind of product this direction signals.

For the **Linear-anchored direction specifically** (when the brief positions the product against Linear or the modern-minimal school is one of the 3 picks): activate Linear's actual OpenType features in `:root` with `font-feature-settings: "cv01", "ss03";` on the body — this is the Linear-insider tell that elevates authorial voice on D3. Other directions may pick their own school-specific feature settings (IBM Plex Mono → `"kern", "liga"`; Iowan/Charter serif → `"smcp"` for any small-caps run).

Visual fidelity hard rules (`references/pipeline.md` § "Build phase rules" for the full list):
- `:root` declares all 6 palette tokens; use `var(--token)` throughout
- Colors in `hsl()` / `oklch()` syntax — no bare hex literals
- Maximum 3 heading levels per file
- No fixed widths on containers — `max-width` + percentage/auto
- Touch targets ≥ 44×44 px on mobile
- Skip-to-content link as first focusable element
- `:focus-visible` outline on all interactive elements
- Every `<input>` / `<select>` has a matching `<label for>`
- No external dependencies (CDN scripts, web fonts beyond a system-stack fallback)

### 5. Build compare.html

Two-zone shape — **at-a-glance triage hero above the fold + deeper comparison below**. This is the founder's "pick 1 of 3 in 30 seconds" surface; the at-a-glance hero is the load-bearing zone.

**Zone 1 — At-a-glance triage hero** (visible at 1440×900 without scroll):

3-column side-by-side grid. Each column = one direction. Per column:
- Codename + one-sentence tagline at the top
- Palette strip (6 swatches inline, name + value compact)
- One product-surface tile (the same kind across columns for visual A/B/C parity — pick triage row OR metric tile, not different ones per column)
- 2 metric tiles (codename + value + caption — uses the identifier table's north-star metric and one supporting number)

The 3-column zone is what the founder sees first. It must FIT one viewport at 1440×900. No iframe selectors here. No "click to switch direction" affordances. All 3 directions visible simultaneously.

**Zone 2 — Deeper comparison** (below the fold):

- **Property comparison table:** rows for School / Canvas / Display font / Body font / Accent / DS composite / Mood — columns are A/B/C
- **Anti-AI-slop P0 audit table** — full 8-rule × 3-direction grid (NOT a one-line summary). Each row is one P0 rule; each cell carries `✓ PASS` plus a SPECIFIC evidence note in parentheses where evidence varies by direction. Example cell content:
  - `✓ PASS (Inter as body; no display use)` (rule: "Inter/Roboto/Arial as body only")
  - `✓ PASS (23 issues, 3.2d cycle, $4/seat — all from brief)` (rule: "No invented metrics")
  - `✓ PASS` (when evidence is uniformly the absence of the anti-pattern across all 3, e.g., "No purple gradient")
  This audit table is the AUDIT discipline made visible to the founder; a single-line summary is not enough — the per-cell evidence proves the discipline ran. Conditional rules (PT-BR Pix/LGPD, token economy) appear only when applicable; otherwise omit the rows.
- "Open each direction at full fidelity" anchor links (NOT iframes — iframes force one-at-a-time viewing which defeats the at-a-glance purpose)
- Optional: per-direction full-page preview tiles or screenshot thumbs

Size target: ~300-500 LOC total. Don't crowd Zone 1 — leave breathing room so the founder's eye lands on palette + product tile first.

### 6. Self-critique (5-dim + anti-slop, pre-emit)

Read `references/checklist.md`. For EACH direction:

**5-dimension critique** (score 1-5; any dimension < 3/5 requires a fix pass before emit):
1. **Philosophy** — visual posture matches what was asked
2. **Hierarchy** — one obvious focal point per surface
3. **Execution** — typography / spacing / alignment correct, not approximate; tokens used consistently
4. **Specificity** — every word, number, label sourced from the brief; zero filler
5. **Restraint** — one accent used at most twice per screen; one decisive flourish

**Anti-AI-slop P0** (`references/anti-patterns.md` for full list):
- No purple/violet gradient backgrounds · no generic emoji feature icons · no left-coloured-border rounded cards as default · no hand-drawn SVG humans · Inter/Roboto/Arial as body only · no invented metrics · no filler copy · no motivational copy

Two fix passes is normal. Do NOT emit with a failing dimension.

### 7. Write REPORT.md

Read `references/examples.md` § "REPORT walkthrough" for the canonical shape. Required sections (see `schema.md` for the floor):

- `## Run Summary` — discovery answers summarized; output paths
- `## Design Systems Consulted` — table: System / Reference / Used in Direction (cite ≥ 3 named systems across the 3 directions)
- `## 3 Direction Summaries` — per direction: codename, file, visual DNA, citation, mood, brief-compliance highlights, anti-slop checks
- `## 5-Dim Critique Pre-Emit Scores` — table with all 5 dims × A/B/C + minimum
- `## Anti-AI-Slop Audit` — table of all P0 rules × A/B/C
- `## Brief Compliance Check` — table: Brief requirement / Addressed
- `## Turn 2 Plan` — list 8 screens that would render for the picked direction; map to brief's mechanics-breakdown

### 8. Surface for user pick (Layer 3 checkpoint)

After REPORT.md drafts, do NOT call `product_step_submit` yet. Surface to user:

```
✅ Turn 1 complete — 3 directions emitted

  file:///<absolute-path>/direction-a.html  — <codename A>
  file:///<absolute-path>/direction-b.html  — <codename B>
  file:///<absolute-path>/direction-c.html  — <codename C>
  file:///<absolute-path>/compare.html      — side-by-side

  REPORT summary: all 3 cleared 5-dim ≥ 3/5; anti-slop clean.

  Pick a direction (a / b / c) to proceed to Turn 2 (8 hi-fi screens).
  Or refine — which direction needs which adjustment before we proceed?
```

Wait for user. Do NOT advance.

### 9. Turn 2 — 8 hi-fi screens of picked direction

Once user picks (e.g., "C"), generate 8 product screens in `screens/01-<name>.html` through `screens/08-<name>.html`. Each screen ≥ 4 KB, uses the picked direction's palette + type tokens verbatim (copy `:root` from the direction file). Each screen exercises a real product surface from the brief's mechanics + user-flow sections.

Default 8-screen set (adapt to brief's mechanics-breakdown when possible):
1. `01-landing.html` — full marketing landing (hero, value sections, pricing, FAQ)
2. `02-onboarding.html` — first-run wizard (3-5 steps)
3. `03-dashboard.html` — primary in-product workspace
4. `04-<mechanic>.html` — main core-value mechanic (product-specific)
5. `05-<mechanic>.html` — secondary mechanic or detail view
6. `06-<mechanic>.html` — workflow / multi-step interaction surface
7. `07-settings.html` — account / preferences / billing
8. `08-empty-error.html` — empty + error + loading states combined

Confirm the 8-screen list with the user BEFORE writing if the brief is ambiguous about which mechanics deserve dedicated screens.

Append `## Turn 2 — 8 Screens Hi-Fi` section to REPORT.md with: per-screen one-line summary, 5-dim scores per screen, anti-slop re-run, deviations from brief.

### 10. Submit

Call `product_step_submit` with:
- `step: 2`
- `filename: "REPORT.md"`
- `content: <full report including Turn 2 section>`
- `extra_files`: array of `{ path, content }` for `direction-a/b/c.html` + `compare.html` + 8 screens (`screens/01-...html` through `screens/08-...html`)

Schema enforces presence + min_size + contains for all listed files; missing/undersized produces `code: "schema-incomplete"` with the failure list.

### 11. Advance

Call `product_advance` to move to step 3 (spec). Step 2 carries a Layer 3 checkpoint internally (user direction pick between Turn 1 and Turn 2); both turns are conducted in one logical step from the pipeline's perspective. The pipeline's gate (`GATE_AFTER: [4,7,12]`) does NOT fire after step 2 — step 7 (prototype-v2) is the first gate where the user formally signs off on the visual lane.

---

## Voice & rigor

- The HTML is the artifact. Treat each direction file like a real production deliverable — every word, every number, every value is from the brief or self-citable. No filler.
- Citation chain is mandatory. Every direction names which design systems it composes from. "Inspired by Linear's hairline borders + Wise's amber accent" is a real citation. "Modern minimal" alone is not.
- Honest 5-dim scoring. If a direction is genuinely 3/5 on Execution because the serif fallback on Windows is acceptable-but-not-identical, score it 3 and note the mitigation. Score inflation breaks the discipline.
- The 3 directions must be 3 distinct families. If two directions read as variations of the same idea, the user got 2 directions, not 3.
- PT-BR products get PT-BR copy throughout. Pix-first if fintech/payment-adjacent. LGPD footer link mandatory. Token-economy cost badges where applicable.

## What this step does NOT do

- Pixel-perfect production code. The HTML is mood-board / hi-fi mockup — interactivity is CSS-only unless an interaction is core to the direction's expression
- Framework code (.tsx / .vue / .svelte). Step 13 (prototype-v3) synthesizes the picked direction into stack-native code when the spec demands it
- Brand voice deep-dive. Step 5 (brand) covers voice, copy patterns, illustration style
- Design tokens for code consumption. Step 6 (design-system) emits the `tokens.css` consumed by step 7 + step 13
- User testing of the mockups. Step 4 (ux-testing) validates via intuition-mode or tested-mode

## What this step replaces

Anthill's `anthill-prototype` skill (402 LOC SKILL.md + 10 references = 2311 LOC total) in `html-mockup` mode. The `stack-native` half (full-product / mobile-native / shadcn-bootstrap = 1382 LOC across 3 references) is OUT OF SCOPE per spec 026 — those reappear when step 13 (prototype-v3) gets the framework-synthesis port.

The OD vendor bundle (anthill's `.anthill/vendor/open-design/` + `.anthill/design-systems/`) is **ported and ships inside this package** (spec 027): 72 vendored `DESIGN.md` design systems + 33 skill bundles + the 5-school direction library, pinned and checksum-verified. The agent grounds each direction in a vendored `DESIGN.md` via `product_design_systems_index` + `product_design_system_path` — see `references/od-bridge.md` for the pre-flight read sequence. DESIGN.md citation by name + path is mandatory (`schema.md` enforces it). The pre-OD inline 5-school description is retained in `references/pipeline.md` § "Manual escape — OD vendor unavailable" as a documented fallback for broken installs.
