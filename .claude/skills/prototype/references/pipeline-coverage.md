# Pipeline coverage — 13 steps × 4 phases at "standard" tier

How `/prototype` v2 (spec 036) maps the 13-step `mcp-product-pipeline` canonical templates onto the 4 agile phases. **Single tier — "standard".** Lightening per step is fixed by this doc; no `--fast`/`--deep` flag soup.

For the heavy canonical pipeline at full rigor, invoke `mcp__product-pipeline__*` tools directly (out of scope for `/prototype` v2).

## Phase ↔ step map

| Phase | Pipeline steps | Gate at end? | Bulk wall-clock target |
|---|---|---|---|
| **Phase 1 — Discovery** | 01-ideation · 02-prototype-v1 · 03-spec · 04-ux-testing | ✓ AskUserQuestion | 8-12 min |
| **Phase 2 — Identity** | 05-brand · 06-design-system · 07-prototype-v2 | ✓ AskUserQuestion | 10-15 min |
| **Phase 3 — Specification** | 08-prd · 09-system-design · 10-cost-estimate · 11-roadmap · 12-legal | ✓ AskUserQuestion | 10-15 min |
| **Phase 4 — Synthesis** | 13-prototype-v3 | (no gate; closes with `/sdd new`) | 5-8 min |

**Total target: 30-45 min** end-to-end for a clean run. Add ~5 min per gate iteration if user picks `iterate`.

## Per-step output + size targets (standard tier)

Sizes are TARGET MINIMUMS — sub-agents should hit them; falling materially below triggers a `BLOCKED` mark in `.state.json` and a `tdd-advisory: <step> output undersized` warning in REPORT.md.

| # | Step | Sub-agent model | Output file(s) | Size target (standard) | Canonical (heavy) for ref |
|---|---|---|---|---|---|
| 01 | Ideation | **opus** | `concept-brief.md` | 4-10 KB | 12-25 KB |
| 02 | Prototype v1 | sonnet × N | `direction-a.html` (1 only at standard, not 3) + `screens/<NN>-<name>.html` × 3-5 (killer flow) + `REPORT.md` | direction ≥ 6 KB, screens ≥ 4 KB each | direction ≥ 10 KB, 3 directions + 3-15 screens |
| 03 | Spec | sonnet | `functional-spec.md` + `architecture.md` (single combined optional) | 8-12 KB combined | spec ≥ 15 KB + arch ≥ 4 KB separate |
| 04 | UX Testing | sonnet | `validation-report.md` | 5-8 KB | ≥ 8 KB |
| 05 | Brand | sonnet | `brand-book.md` | 4-8 KB (2-3 section snapshot) | 6-12 KB (7 required sections) |
| 06 | Design System | sonnet | `tokens.css` + `components.md` + `design-system.md` | tokens ≥ 1.5 KB, components ≥ 3 KB, ds ≥ 8 KB | ds ≥ 12 KB |
| 07 | Prototype v2 | sonnet × N (cap=5) | `direction-final.html` + `screens/<NN>-<name>.html` × same-N-as-step-02 + `REPORT.md` | direction ≥ 8 KB, screens ≥ 4 KB | direction ≥ 10 KB |
| 08 | PRD | sonnet | `prd.md` (with US-NN stable IDs + P0/P1/P2) | 6-10 KB | ≥ 8 KB |
| 09 | System Design | sonnet | `system-design.md` + `architecture.json` + `security.md` | sd ≥ 12 KB, sec ≥ 3 KB | sd ≥ 20 KB bridge-floor, ≥ 28 KB canonical |
| 10 | Cost Estimate | sonnet | `cost-estimate.md` (single-scenario, no bear/base/bull) | 5-8 KB | 7-18 KB |
| 11 | Roadmap | sonnet | `roadmap.md` (3-phase MVP/Growth/Polish sketch) | 5-8 KB | 6-12 KB |
| 12 | Legal | sonnet | `legal-posture.md` (checklist + posture; no full regulation matrices) | 4-7 KB | 6-15 KB depending on regulated class |
| 13 | Prototype v3 | sonnet × N (cap=5) | `screen-atlas.md` + `screens/<NN>-<name>.html` × full-PRD-coverage + `REPORT.md` | atlas ≥ 8 KB, screens ≥ 6 KB each, count = max(killer-flow + 1 edge-state, 4) | atlas ≥ 10 KB, screens ≥ 8 KB, count product-class-calibrated |

## Lightening op applied per step (single-tier "standard" decisions)

These are the standard-tier lightening choices — fixed, not flagged. Source: Explore-agent synthesis 2026-05-18.

1. **01 Ideation:** 5-8 web searches (vs 15-25 canonical); ~10KB brief target (vs 12-25KB); skip the `critique mode` (4-7 challenger concepts) unless user explicitly iterates the gate.
2. **02 Prototype v1:** ONE direction only (vs 3 mood boards + compare picker); 3-5 killer-flow screens (vs 3-15 depending on product class). No Layer-3 inner checkpoint — direction-pick collapses into the phase gate.
3. **03 Spec:** Combined `functional-spec.md` + `architecture.md` flatten to one doc (or separate, sub-agent picks based on size). Skip the standalone `architecture.html`/`.json` viz unless user passes `--with-arch-diagram` (out of scope for v1).
4. **04 UX Testing:** Heuristic-only (Nielsen 10 + WCAG 2.1 AA top issues). Projected-mode default (audits the spec, not rendered HTML — saves a render-and-measure pass). Validation mode declaration still required (downstream gating).
5. **05 Brand:** 2-3 section snapshot (voice samples + visual direction posture + "we are/we are not" pair) vs canonical 7 required sections. Sub-agent interviews via inline prompt block — no separate founder-interview turn.
6. **06 Design System:** Catalog-path PREFERRED (pick 1-2 vendors from `od-catalog-index.json` and inherit their tokens) vs custom-derive. Custom path falls back only if catalog produces zero matches for the brand mood.
7. **07 Prototype v2:** Same screen count + same filenames as step 02 (inheritance discipline). Skip per-screen 4-dim critique pre-emit; trust step-04 audit routing for fixes.
8. **08 PRD:** Stable US-NN IDs + P0/P1/P2 tiering + acceptance criteria per story + ONE primary success metric. Skip the in-PRD competitive analysis (concept brief already covers).
9. **09 System Design:** Bridge-floor (6 sections: stack, integrations, data model, decisions locked, security, observability). Skip trade-off triggers + alternatives-considered + non-functional budgets (defer to engineering phase).
10. **10 Cost Estimate:** Single-scenario burn rate (build weeks × hourly rate + run-cost line items table). Skip bear/base/bull + sensitivity + unit economics (defer to post-launch when real data exists).
11. **11 Roadmap:** 3-phase sketch (MVP / Growth / Polish) without detailed milestone definitions or per-phase deliverables table. Phase titles still user-flow-shaped (not label-shaped).
12. **12 Legal:** Brief checklist (what regulations apply, what sub-processors exist, IP assignment posture). Skip full GDPR article-grid + per-flow controller/processor analysis (counsel-review work, not v1 posture work).
13. **13 Prototype v3:** Killer-flow screens + 1 combined edge-state screen + legal-mandatory surfaces (consent dialog if applicable). Skip supporting surfaces (settings detail pages, admin panels) — `/sdd new` will handle in engineering phase. PRD coverage matrix still required; deferred US-NNs marked with reason.

## Bundled-template provenance + drift discipline

All 13 step prompts + schemas + references live at `.claude/skills/prototype/templates/pipeline/<step>/`, copied verbatim from `packages/mcp-product-pipeline/src/templates/<step>/` at spec 036 ship date (2026-05-18).

**Drift sync:** `.claude/REMINDERS.md` carries a quarterly item to diff bundled vs canonical and resync if changed. Due 2026-08-18, then every 90 days.

**Why bundle (not symlink or runtime-read):** the v2 skill is standalone — must work in a fork that lacks `packages/mcp-product-pipeline/` (forks consume capacities; they don't necessarily extend the harness with the heavy pipeline). Bundle is the price of portability.

## Three-prototype-pass rationale (verbatim from canonical pipeline)

Steps 02 / 07 / 13 are three prototype passes serving different phase-closing questions. v2 preserves this (does not collapse to one pass) because each pass answers a unique question:

- **Step 02 (Pass 1):** Which visual direction resonates? Pre-brand, pre-design-system. Killer flow only.
- **Step 07 (Pass 2):** Does brand + tokens hold together? Post-Identity. Same screens as Pass 1, brand-tuned + audit-fixed.
- **Step 13 (Pass 3):** Is the COMPLETE product surface cohesive and PRD-covered? Post-Specification. Full coverage matrix.

Collapsing into one pass would either under-specify (skip brand iteration → render falls flat) OR over-engineer early (render full PRD surface before scope locks → wasted work on cut features).

## Cross-references

- `state-machine.md` — phase/step progression, `.state.json` shape, resume support
- `delegation-briefs.md` — 14 sub-agent briefs (13 step + 1 per-stack screen-writer)
- `od-catalog-index.json` — Step 06 catalog path vendor index (72 vendors at 2026-05-18 snapshot)
- `quality-checklist.md` — per-step gate criteria + per-screen 4-dim rubric
- `docs/specs/036-prototype-skill-refactor/` — spec/plan/tasks driving this refactor
