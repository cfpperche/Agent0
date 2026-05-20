# Quality checklist — `/product` v0.4.0

Per-step gate criteria the skill checks before marking a step `completed` in `.state.json`. Failure → mark BLOCKED with reason; degrade per `delegation-briefs.md § Failure handling`. Each item maps to a `REPORT.md` section (see § REPORT.md section mapping at the end).

**Spec 066 reshaped Phase 4-5.** The v2/v3 per-route screen-writer fan-out is deleted — there is no `app/**/page.tsx` set to score, no `pnpm install` / build verification, no `tsc` / `biome` ship gate, no fan-out degradation tracking. Steps 1-14 are unchanged; Step 15 is the visual contract (§ 2); Phase 5 is the SDD handoff (§ 3).

## 1. Per-step gate criteria (steps 01-14)

Sizes are referenced from each step's `templates/pipeline/<NN-step>/schema.md § Target`; this table is a derived view.

| # | Step | Gate criteria (skill checks before marking complete) |
|---|---|---|
| 01 | Ideation | `docs/concept-brief.md` 4-10 KB; 9 H2 sections incl `§ Market Sizing`; ≥ 5 `[N]` citations |
| 02 | Prototype v1 (lo-fi) | `docs/direction-a.html` within schema range + `docs/screens/*.html` × 3-5 (killer-flow lo-fi mood); direction-a.html has `:root` + `--background` + `--foreground` + `--primary` + `Most Popular` + `<svg`; cites ≥ 1 OD vendor |
| 03 | Spec | `docs/functional-spec.md` 12-30 KB; `**Given**` / `**When**` / `**Then**` present; ≥ 3 Gherkin scenarios; `§ Problem-Validation Interviews` |
| 04 | UX Testing | `docs/validation-report.md` 5-8 KB; `Nielsen` + `WCAG`; `validation_mode:` line; YAML `findings[]` ≥ 3, each with `severity` + `fix_skill_hint` |
| 05 | PRD | `docs/prd/v1.md` 4-7 KB; literal `\| US-NN \|` table row; 9 H2 (6 Lenny bones + 3 our-specific); ONE NSM in its dedicated slot; P0/P1/P2 tiers visible |
| 06 | OST | `docs/ost.md` 3-6 KB; 1 outcome → 3-5 opportunities → 2-3 solutions per; every solution carries a status |
| 07 | Sitemap-IA | `docs/sitemap.yaml` 2-5 KB valid YAML; `required_categories` enforced (each has ≥ 1 route OR is in `deferred_categories` with reason) — orchestrator BLOCKS + re-dispatches otherwise |
| 08 | System Design | `docs/system-design.md` 15-42 KB + 8 H2 (incl RACI + Risk Register); `docs/security.md` 3-10 KB; `docs/data-flow.json` valid JSON, `flows[]` ≥ 3 |
| 09 | Legal posture | `docs/legal-posture.md` within schema-computed conditional range; escape clause line 1-5; `§ DPIA` present iff data-flow has sensitive categories; sub-processor count matches system-design |
| 10 | Roadmap | `docs/roadmap.md` 6-18 KB; 3 phase headers, user-flow-shaped; 1-3 milestones per phase; `§ Open Decisions` |
| 11 | Cost Estimate | `docs/cost-estimate.md` 5-8 KB; Assumptions / Build Cost / Run Cost / Legal & Audit Budget / Recommendations headers; build cost rows reference roadmap phases |
| 12 | GTM-launch | `docs/gtm-launch.md` 4-7 KB; Positioning Canvas (5 lines) + Launch Plan (4 week milestones) + Pricing Strategy |
| 13 | Brand | `docs/brand-book.md` 4-8 KB; `**Version:**` + `**Date:**` + `## Language` + `## Glossary` (both sub-sections) + `**We are**`/`**We are not**` + 3+ voice samples + Product Name decision |
| 14 | Design System | `docs/design-system/tokens.css` ≥ 1.5 KB with a **Tailwind v4 `@theme` block** + light-mode `@media` override; `components.md` ≥ 3 KB; `README.md` ≥ 8 KB with `Audit Response` + OD vendor citation |

## 2. Visual contract (Step 15 — three sub-steps)

Step 15 is three parallel sub-agents. Each has its own gate:

### 15a — Screen atlas

- `docs/screen-atlas.md` exists, 10-28 KB (per `15-screen-atlas/schema.md § Target`).
- All 8 required H2 headers present: Overview / Screens Index / Sitemap Coverage Cross-Check / PRD Coverage Matrix / Design Fidelity / States Coverage Matrix / User Flow Walkthrough / Open Decisions.
- **Screens Index** table has one row per `docs/sitemap.yaml` route — full inventory, no silent drop.
- **PRD Coverage Matrix** lists every `US-NN` from `docs/prd/v1.md` (covered → route(s), or deferred → reason). Silent omission is a gate failure.
- **Sitemap Coverage Cross-Check** confirms every `required_categories` member is represented.
- `§ User Flow Walkthrough` carries the literal `Closed-beta partner` named-human acceptance clause.
- **NO `app/` / `.tsx` / `.html` file was written** — the atlas is a markdown contract, not an implementation. A stray `app/` tree is a gate failure (the writer overstepped its brief).

### 15b — Hi-fi killer-flow mood

- 3-5 files at `docs/screens/hifi/<NN>-<name>.html`, each within the hi-fi budget (8-18 KB).
- Each is self-contained HTML: one `<style>` block + a `:root` token block (values copied from `docs/design-system/tokens.css`).
- **Mobile-first:** the `<style>` block carries ≥ 1 `@media (min-width: …)` breakpoint and the base CSS targets 375 px. NO `style=` layout attributes (the lone exception: a single dynamic value like a progress-bar width).
- Copy is on-brand (matches `brand-book.md` voice, respects `## Glossary § We don't say`) and fixture-grounded (data from `docs/fixture-spec.md`, no lorem ipsum).

### 15c — Fixture spec

- `docs/fixture-spec.md` exists, 2-6 KB.
- `## Persona` + `## Entities` + `## Cross-Screen Consistency Notes` present.
- One persona only; every `system-design.md § Data Model` entity has an example-records table.
- Dates form a plausible timeline; foreign keys resolve; cross-screen totals agree (internal consistency is the whole point).

## 3. SDD handoff (Phase 5)

- `<out>/docs/specs/001-<slug>/` exists with `spec.md` filled — `**Type:** umbrella`, a `## Child-spec matrix` table, a `## Standing constraints` section.
- `<out>/docs/specs/002-foundation/` exists with `spec.md` filled (skeleton + tooling + route-group dirs + thin `layout.tsx` shells).
- The umbrella's child-spec matrix slices children #3..N by `docs/roadmap.md` phases (or falls back to a single `app-build` child when the roadmap lacks phase structure).
- The Phase 5 handoff message printed to chat names the umbrella spec path — NOT a `pnpm dev` instruction.

See `references/sdd-handoff.md` for the full Phase 5 contract.

## 4. Sitemap completeness (Step 07 → atlas)

- All 5 `required_categories` present (marketing / auth / primary / admin / error) → ✓, otherwise a gap-audit entry per missing category.
- Per-route fields complete per `sitemap-schema.md` Rules 4-6.
- The atlas § Screens Index reflects the full sitemap inventory at standard tier.

## 5. Skill-self compliance (gate; non-skippable)

`bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 — the spec 033 gate. NOT optional. The skill prints the result in the Phase 5 handoff.

## 6. Best-effort visual check (Step 15b)

If the Playwright MCP is loaded this session: each `docs/screens/hifi/*.html` is screenshotted at 375 px + 1280 px and probed for horizontal overflow (`scrollWidth > clientWidth`). Results land in REPORT.md § Visual check. If the MCP is not loaded, a `visual-gate-skipped` advisory is recorded. **Best-effort — never blocks the run.**

## REPORT.md section mapping

| Checklist | REPORT.md section |
|---|---|
| 1 — Per-step gate criteria (01-14) | `## Pipeline coverage` (per-step status: pass / blocked + reason) |
| 2 — Visual contract (15a/15b/15c) | `## Visual contract` (atlas + hi-fi mood + fixture-spec status) |
| 3 — SDD handoff | `## SDD handoff` (umbrella + foundation child paths) |
| 4 — Sitemap completeness | `## Coverage scorecard` (atlas Screens Index vs sitemap; per-category counts) |
| 6 — Best-effort visual check | `## Visual check` (per-screen 375/1280 px overflow result, or skip advisory) |
