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

**Pin a brief-identifier extraction table in chat BEFORE writing any HTML.** This is the discipline that separates brief-grounded mockups from plausible-but-substituted ones. The table enumerates the identifiers that MUST appear verbatim in dashboard / hero / metric content; the agent then refuses to substitute close-but-different variants in the HTML phase.

Required rows (omit a row when the brief is silent on it):

| Identifier type | Source quote (brief section) | Verbatim value to use |
|---|---|---|
| Product name | Identity block | `<value>` |
| Issue/record ID prefix | Mechanics or User Flow | `<value>` (e.g., "SWF-" not "SB-") |
| Persona slug(s) / handle(s) | Target Persona table | `<value>` (e.g., "@mara.ic" not "Maya Chen") |
| Sprint / cycle / period label | Mechanics or User Flow | `<value>` (e.g., "Sprint 19") |
| North-star metric name + value | Business Model § Key Metrics | `<value>` (e.g., "87% issues touched") |
| Pricing tier values | Monetization Sketch table | `<value>` (e.g., "$0 / $4 / $7" with tier labels) |
| Currency format | Identity (PT-BR products) | `<value>` (e.g., "R$ 19,90" not "$19.90") |
| Any other named system / loop / mechanic | Mechanics Breakdown | `<value>` |

After pinning, treat the table as a non-negotiable name list — every dashboard row / metric / hero / pricing tile MUST use these values exactly. "Plausible engineering names" or "close-enough variants" weaken brief traceability and trip Specificity in the 5-dim critique.

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

Read `references/pipeline.md` § "5 canonical schools" before proceeding. The 5 schools (editorial-monocle / modern-minimal / warm-soft / tech-utility / brutalist-experimental) are starting families — directions can blend or deviate when the brief justifies it.

**Hard rule:** the 3 directions must come from genuinely different angles — different palette family, different typographic personality, different layout posture. NOT three takes on the same green. If two directions land in the same school, drop one and pick a contrasting school.

Per direction, pin in chat BEFORE writing HTML:
- **Codename** (e.g., "Operador Silencioso", "Calma Estratégica") — visual DNA reference, not marketing label
- **Palette** — 6 tokens (background / foreground / primary / accent / border / muted) with exact `hsl()` / `oklch()` values
- **Type** — heading font family + body font family + signature weight
- **Layout posture** — density level + container max-width + signature shape (e.g., "hairline borders, near-zero radius, dark canvas")
- **Mood blurb** — one sentence in product voice (PT-BR if Brazilian) — why this direction
- **Citation chain** — 1-3 named design systems composed (Linear, Notion, Stripe, Wise, etc.). Cited by name in REPORT.md

### 4. Build the 3 mood-board HTMLs

Read `references/visual-constraints.md` + `references/a11y-checklist.md` + `references/anti-patterns.md` BEFORE writing. Each `direction-{a,b,c}.html` is a self-contained file (no external deps) with embedded CSS. Required sections per file (all 7 mandatory, visible at 1440px + 375px without horizontal overflow):

1. **Header** — codename + tagline + one-sentence personality blurb
2. **Palette strip** — 6 swatches with name + value
3. **Type sample** — H1 / H2 / body / mono / caption at signature weights
4. **Hero sample** — title + subtitle + CTA matching the product's actual JTBD
5. **Dashboard sample** — at least one realistic product surface (kanban / metric cards / data table / form). Use REAL data from the brief (verbatim from the identifier table pinned in § 1) — never lorem ipsum
6. **Pricing tile grid** — 3 tier cards ($0 free / paid Pro / higher tier) using the brief's pricing values verbatim. The Pro tier carries a "Most Popular" emphasis (badge, border highlight, or scale). Each tile lists 3-5 feature bullets and a CTA. This is a dedicated UI surface block, NOT inline hero copy. Even free-tier-only products surface a "Free forever" tile + roadmap-tier preview tiles. Token-economy products use pacote tiers instead (`Otimizar CV · 3🪙`, `Pacote · 8🪙`, `Pacote · 20🪙`).
7. **Personality footer / Design System Lineage** — DS citation chain (1-3 named systems with concrete reference details — not just "modern minimal") + one paragraph on what kind of product this direction signals

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

- Property comparison table: rows for School / Canvas / Display font / Body font / Accent / DS composite / Mood — columns are A/B/C
- Anti-slop summary (one-line per direction confirming P0 pass)
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

The OD vendor bundle (`.anthill/vendor/open-design/` + `.anthill/design-systems/`) that anthill references at every direction-picking step is **not yet ported** — see `.claude/memory/od-vendor-port-plan.md`. While OD is unported, this step relies on the agent's training-data knowledge of named design systems (Linear, Notion, Stripe, Wise, etc.) rather than vendored DESIGN.md files. When OD ports, `references/pipeline.md` will shrink dramatically and DESIGN.md citation becomes mandatory.
