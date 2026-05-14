# Step 2 — Schema (prototype HTML mood boards + REPORT + hi-fi screens)

The submitted `REPORT.md` MUST contain the level-2 markdown headings below + meet the Layer 1 size/content floor in the JSON fenced block. All listed files must be persisted via the `extra_files` parameter on `product_step_submit`. Both checks fire on submit; missing sections OR Layer 1 failures produce `code: "schema-incomplete"` with the failure list.

## Required sections (REPORT.md markdown headings)

Section names slugify by lowercasing + dashing — `## 3 Direction Summaries` → `3-direction-summaries`. Cosmetic variants are accepted (trailing punctuation, "Pre-Emit" suffix, etc.); slugifier strips them.

- `run-summary`
- `design-systems-consulted`
- `3-direction-summaries`
- `5-dim-critique` (full title may read `5-Dim Critique Pre-Emit Scores`; slugifier accepts the prefix match)
- `anti-ai-slop-audit` (accepts `anti-slop-audit`)
- `brief-compliance` (accepts `brief-compliance-check`)
- `turn-2-plan` (required after Turn 1 emit)
- `turn-2-8-screens-hi-fi` (REQUIRED on final submit — added after user picks direction and Turn 2 completes)

The Identity block (codename, palette tokens, type stack, citation chain per direction) lives inside `3-direction-summaries` — it is enforced via the `contains` substrings in the Layer 1 fenced block below, not as separate headings.

## Layer 1 — file-level floor

```required_files
{
  "required_files": [
    {
      "path": "direction-a.html",
      "min_size": 10240,
      "contains": ["<!DOCTYPE html", "<style", ":root", "--background", "--foreground", "--primary", "Most Popular", "<svg"]
    },
    {
      "path": "direction-b.html",
      "min_size": 10240,
      "contains": ["<!DOCTYPE html", "<style", ":root", "--background", "--foreground", "--primary", "Most Popular", "<svg"]
    },
    {
      "path": "direction-c.html",
      "min_size": 10240,
      "contains": ["<!DOCTYPE html", "<style", ":root", "--background", "--foreground", "--primary", "Most Popular", "<svg"]
    },
    {
      "path": "compare.html",
      "min_size": 4096,
      "contains": ["<!DOCTYPE html", "direction-a", "direction-b", "direction-c", "Palette", "School", "Anti-AI-slop", "PASS"]
    },
    {
      "path": "REPORT.md",
      "min_size": 6144,
      "contains": [
        "## Run Summary",
        "## Design Systems Consulted",
        "## 3 Direction Summaries",
        "## 5-Dim Critique",
        "## Anti-AI-Slop Audit",
        "## Brief Compliance",
        "Philosophy",
        "Hierarchy",
        "Execution",
        "Specificity",
        "Restraint"
      ]
    }
  ],
  "required_glob": [
    {
      "pattern": "screens/[0-9][0-9]-*.html",
      "min_count": 8,
      "per_match_min_size": 4096,
      "per_match_contains": ["<!DOCTYPE html", "<style", ":root"]
    }
  ]
}
```

### Notes on the floors

- **`direction-{a,b,c}.html` min_size 10240** (10 KB) — bumped from 8 KB after adding the charts & sparklines section in refinement v4. Pivota's anthill reference landed at 17-20 KB; benchmark runs land at 33-47 KB. A 10 KB floor catches stubs while allowing terse variants
- Each direction file's `contains` enforces:
  - The `:root` token system + 3 canonical token names (`--background` / `--foreground` / `--primary`) — agents that forget the token system trip Layer 1 immediately
  - The substring `Most Popular` — proxy for the required **pricing tile grid** surface (see prompt.md § 4 section #7). The "Most Popular" badge convention is universal across SaaS pricing surfaces; if a product's tier structure uses a different highlight word (e.g., "Recommended", "Featured", or "Free Forever" for a free-only product), the agent should include the literal substring `Most Popular` in a comment (`<!-- Most Popular tier: rendered as "Recommended" because <reason> -->`) or as the emphasis label, to pass the check
  - The substring `<svg` — proxy for the required **charts & sparklines sample** surface (see prompt.md § 4 section #6). Inline SVG is the canonical way to render charts in self-contained HTML; agents that skip the charts section trip Layer 1 immediately. CSS-only chart treatments (e.g., a `<div>` height-grid bar chart) that don't use `<svg` should include the substring `<svg` in a comment (`<!-- chart rendered as CSS grid; no SVG used -->`) to pass
- **`compare.html` min_size 4096** + substrings `direction-a` / `direction-b` / `direction-c` + `Palette` + `School` — bumped from 2 KB after step 2 benchmark showed both producers landing at 25-32 KB on a real compare surface. Substrings now enforce both the at-a-glance hero (palette swatches present) and the deeper comparison table (school property row)
- **`REPORT.md` min_size 6144** (6 KB) — covers Turn 1 sections at honest depth. Turn 2 section grows the file further on resubmit; pivota's REPORT landed at ~16 KB after Turn 2; step 2 bench showed producers landing 21-27 KB on Turn 1 alone
- **`screens/[0-9][0-9]-*.html` glob** — exactly the `01-`, `02-`, ..., `08-` shape. `min_count: 8` is a hard floor (per spec 026 plan); `per_match_min_size: 4096` filters stubs. Each screen MUST carry `:root` declaration (verbatim copy of picked direction's tokens) — `per_match_contains` enforces

## Section content guidance (depth, not just presence)

The schema enforces presence and floors; *depth* is the agent's responsibility. Quality cues per section:

- **Run Summary** — discovery answers (or "brief pre-answered direction count"); mode (`html-mockup` always at this step); output paths surfaced as `file://` URLs
- **Design Systems Consulted** — table: System / DS reference / Used in Direction. Cite ≥ 3 distinct named systems across the 3 directions. If a direction blends 2 systems (e.g., Notion × Stripe), list both rows. This is the citation chain that grounds direction picks in real product references rather than invented vibes
- **3 Direction Summaries** — per direction, in this order: codename, file path, visual DNA (palette + type + layout posture), DS composite, direction-library match (one of the 5 schools or "custom — justified by [reason]"), personality blurb, key brief-compliance highlights, key anti-slop checks passed
- **5-Dim Critique** — table: Direction | Philosophy | Hierarchy | Execution | Specificity | Restraint | Min. The `Min` column carries the gate-pass indicator (✓ if ≥ 3). Any score < 3 should have been fixed in a pre-emit pass — if it lands in the final report, the agent has a discipline failure to explain in the next "Critique notes" subsection
- **Anti-AI-Slop Audit** — table of all P0 rules × A/B/C with ✓ or specific note. PT-BR / Pix / LGPD rows only when product is Brazilian
- **Brief Compliance** — table: Brief requirement / Addressed (which direction). Source requirements from the concept brief's identity block + mechanics-breakdown + risks. If a brief requirement is unaddressed across all 3 directions, call it out — do NOT silently skip
- **Turn 2 Plan** — bullet list of 8 screens that would render for whichever direction the user picks. Map to brief's mechanics-breakdown when possible; default set is `landing / onboarding / dashboard / <mechanic> / <mechanic> / <workflow> / settings / empty-error`
- **Turn 2 — 8 Screens Hi-Fi** (final submit only) — per-screen one-line summary + 5-dim scores per screen + anti-slop re-audit + any deviations from brief noted

## Citations and named systems

When citing a named design system, the citation should be specific enough that a reader holding the brief and the cited system's homepage can verify the visual claim. "Composed from Linear" is acceptable; "Composed from Linear's hairline borders + tight letter-spacing + near-black canvas with cobalt accent" is better and reads as a real reference rather than a name-drop. The 5-dim Specificity score is partially derived from how concrete these citations are.
