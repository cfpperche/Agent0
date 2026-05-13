# Pipeline — html-mockup direction generation

The operational playbook for step 2's Turn 1: discovery → 3 direction families → build → 5-dim critique → emit. Replaces anthill's `.anthill/vendor/open-design/` (OD) bundle inline. When the OD vendor ports to this repo (see `.claude/memory/od-vendor-port-plan.md`), this file shrinks dramatically and gains explicit DESIGN.md-citation grounding.

## 5 canonical schools (starting families)

These are the 5 visual schools from OD's `directions.extracted.md`. Each direction the agent emits should map to ONE of these, OR explicitly justify a blend (e.g., "Notion × Stripe — warm-soft × tech-utility hybrid for fintech-clean aesthetic").

| id | Label | Mood | Palette family | Type | Named references | School-specific tells |
|----|-------|------|----------------|------|------------------|----------------------|
| `editorial-monocle` | Editorial — Monocle / FT magazine | Print-magazine feel, content-led, calm | Off-white + ink + warm rust | Serif display + system body | Monocle, FT, NYT Cooking, The New Yorker | `font-feature-settings: "smcp"` for small-caps eyebrows; rule-line dividers (`border-top: 1px solid`); pull-quote with rust `border-left` |
| `modern-minimal` | Modern minimal — Linear / Vercel | Dark or near-white, restrained, tech-product | Near-black or near-white + cobalt accent | System sans throughout | Linear, Vercel, Raycast, Arc browser | **Linear OpenType:** `font-feature-settings: "cv01", "ss03"` on body (activates Linear's actual variant alternates — insider tell); hairline borders 1px no shadow; tight letter-spacing `-0.03 to -0.04em`; weight-300 display |
| `warm-soft` | Warm soft — Stripe pre-2020 / Headspace | Approachable, fintech-friendly, human | Cream bg + terracotta or moss-green accent | Serif display + system body | Stripe (pre-2020), Headspace, Notion (pre-AI), Calm | Soft shadow stack (multi-layer low-opacity); generous radius (`8-16px`); warm neutral grays (not pure gray) |
| `tech-utility` | Tech / utility — Datadog / GitHub | Data-dense, ops-focused, functional | Dark or light + grid + monospace accents | Mono headings + system body | Datadog, GitHub, Grafana, Sentry | Monospace display: `font-feature-settings: "kern", "liga"` on JetBrains/IBM Plex Mono; square corners `3px max radius`; grid-paper background pattern allowed |
| `brutalist-experimental` | Brutalist / experimental — Are.na / Yale | Loud type, visible grid, statement | Hot-red / electric-yellow + black + white | Display sans (large), tight letter-spacing | Are.na, Yale School of Art, MSCHF, KFC Studios | Display sans at 6-9rem; visible 12-column grid overlay; one decisive flourish (rotated heading, oversized punctuation, baseline shift) |

**Picking 3 distinct directions:**

- The 3 directions MUST come from different palette families. Two "modern-minimal" picks with different greens are NOT distinct — pick one and replace the other with a contrasting school
- A direction can blend 2 schools (e.g., `tech-utility` × `warm-soft`) when the brief justifies it. Cite both in REPORT.md ("custom — Notion × Stripe blend, justified by brief's explicit Notion-meets-Stripe example")
- Match a brief-stated preference verbatim. Brief says "brutalist with hot red"? → `brutalist-experimental` is one of the 3, not optional
- Brief silent on tone → pick 3 contrasting schools that cover different product personalities (e.g., `modern-minimal` + `warm-soft` + `tech-utility` is a safe diverse triple)

## Discovery — what to elicit before picking directions

The brief from step 1 already carries audience + JTBD + scale + AI-nativity. Discovery fills the 3 gaps the brief usually doesn't cover at this depth:

1. **Visual tone preference** — 2-3 adjectives. If brief is silent, ask. Adjectives point at schools above
2. **Brand context** — existing brand spec? Reference site to match? Or "pick for me"? A named reference (e.g., "match Linear's vibe") becomes a direction anchor — one of the 3 must be Linear-anchored
3. **Hard constraints** — explicit "no" patterns ("no dark mode default", "no serif", "must be PT-BR + Pix-first"). These disqualify schools that would violate them

Skip discovery entirely if the brief enumerates 3 specific directions. Treat the brief as pre-answered.

## Build phase — per-direction HTML scaffold

Each `direction-{a,b,c}.html` is a self-contained file (no external deps). Canonical structure:

```html
<!DOCTYPE html>
<html lang="<lang>">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Direction <ID> — <Codename></title>
  <style>
    :root {
      --background: <hsl or oklch>;
      --foreground: <hsl or oklch>;
      --primary:    <hsl or oklch>;
      --accent:     <hsl or oklch>;
      --border:     <hsl or oklch>;
      --muted:      <hsl or oklch>;
      --radius:     <value>;
      --font-display: <stack>;
      --font-body:    <stack>;
      --font-mono:    <stack>;
    }
    /* all styles inline — no external CSS */
  </style>
</head>
<body>
  <a href="#main" class="sr-only-focusable">Skip to content</a>
  <main id="main">
    <!-- 1. Header with codename + tagline -->
    <!-- 2. Palette strip — 6 swatches -->
    <!-- 3. Type sample — H1/H2/body/mono/caption -->
    <!-- 4. Hero sample — title + subtitle + CTA -->
    <!-- 5. Dashboard sample — kanban / metric cards / table -->
    <!-- 6. Personality footer — DS citation + signal paragraph -->
  </main>
</body>
</html>
```

### Build phase rules (hard — any failure = fix pass before emit)

1. All 6 palette tokens declared in `:root` (`--background` / `--foreground` / `--primary` / `--accent` / `--border` / `--muted`)
2. All colors in `hsl()` or `oklch()` syntax — no bare hex literals, no `rgb()`. `hsl()` is the safe default for browser compat; `oklch()` is preferred when the palette is being tuned for perceptual uniformity (warm-soft, editorial directions especially benefit)
3. **All 7 required surfaces present** per prompt.md § 4: header, palette strip, type sample, hero sample, dashboard sample, **pricing tile grid (3 tiers, "Most Popular" emphasis on Pro)**, personality footer / DS lineage. Pricing-as-product-UI is what gives the founder a second product surface beyond the dashboard — omitting it weakens product mental model at D4
4. **School-specific OpenType applied** per the table above — the Linear-anchored direction MUST carry `font-feature-settings: "cv01", "ss03"` on body; other schools apply their school tells when applicable
5. Maximum 3 heading levels per file (page title / section title / card title)
6. No fixed widths on containers — use `max-width` + percentage/auto + flex/grid for layout
7. Skip-to-content link as first focusable element (a11y floor)
8. `:focus-visible` outline on all interactive elements
9. Tabular numerics on prices / counts / dates: `font-variant-numeric: tabular-nums`
10. No external resources (no `<link rel="stylesheet">`, no remote `<script src>`, no Google Fonts unless the system fallback works alone)
11. Renders without horizontal overflow at 375px AND 1440px viewports
12. Dashboard / metric / pricing / table content uses REAL data from the brief-identifier extraction table pinned in prompt.md § 1 — product name, issue ID prefix, persona slugs, sprint label, metric values, pricing tiers — all verbatim. Substituting plausible variants ("Maya Chen" when the brief says "@mara.ic") weakens Specificity at D7

## Anti-AI-slop hard rules (P0 gate — block emit)

Read `references/anti-patterns.md` for the full rationale per rule. Quick reference:

- No aggressive purple/violet gradient backgrounds (`linear-gradient(..., purple, violet)`)
- No generic emoji feature icons (`✨ 🚀 🎯` — inline SVG or single-glyph functional only)
- No "rounded card with left coloured border accent" as default layout pattern
- No hand-drawn SVG humans / faces / scenery
- Inter / Roboto / Arial are body fonts only — never display
- No invented metrics ("10× faster", "99.9% uptime") without a source from the brief
- No filler copy — zero "Feature One / Two", lorem ipsum, vague benefit bullets
- No motivational copy for user states ("Vamos lá, campeão!" / "Você consegue!")
- **PT-BR products:** Pix QR Code prominent if fintech/payment-adjacent; LGPD footer link mandatory; PT-BR copy throughout (currency `R$ 19,90` not `$19.90`)
- **Token-economy products:** cost badge on action buttons (`Otimizar CV · 3🪙`); saldo visible in header; double-confirm for ≥ 5 tokens

## 5-dim critique (pre-emit gate)

Score each direction 1-5 on each dimension. Any dimension < 3/5 requires a fix pass. Read `references/checklist.md` for the full rubric.

| Dim | What it measures | Typical -1 cause |
|-----|------------------|------------------|
| **Philosophy** | Visual posture matches what was asked | Drifted to a generic default mid-build |
| **Hierarchy** | One obvious focal point per surface | Two equal-weight CTAs competing |
| **Execution** | Typography / spacing / alignment correct, not approximate | Inconsistent token use; non-tabular numerics |
| **Specificity** | Every word / number / label is from the brief | Generic copy slipped in; invented persona names |
| **Restraint** | One accent used at most twice per screen; one decisive flourish | Three competing flourishes or gradients |

Two fix passes is normal. Do NOT emit with a failing dimension.

## When the OD vendor lands

This document is the interim. When the OD vendor ports (`.claude/memory/od-vendor-port-plan.md`):

1. Replace the 5-school table with `read .vendor/open-design/prompts/directions.ts` (canonical schools live there)
2. Replace the build-phase HTML scaffold with `copy .vendor/open-design/skills/web-prototype/assets/template.html` as seed (token system + class inventory pre-baked)
3. Add a mandatory "Design Systems Consulted" entry that grounds each direction in a vendored `.vendor/design-systems/<system>/DESIGN.md` file path (not just a name-drop). REPORT.md gains a Citation Chain section enforced via schema
4. Frames (`.vendor/open-design/frames/{iphone-15-pro,macbook,browser-chrome}.html`) become optional device-chrome wrappers for screen mocks in Turn 2

Until then, the agent grounds directions in training-data knowledge of named design systems. Quality target: anthill's pivota-level citation chain in REPORT.md, even without vendored DS files.
