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
      "contains": ["<!DOCTYPE html", "<style", ":root", "--color", "var(--", "<svg"]
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
  - The `:root` token system + the `--color` family name (token-naming inherited from step 6 — semantic prefix `--color-*`; step 2's primitive `--background`/`--foreground` are accepted as aliases per `prompt.md` § 5.2)
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
