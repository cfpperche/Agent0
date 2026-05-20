# 066 — product-ui-quality

_Created 2026-05-20._

**Status:** shipped

## Intent

The `/product` skill's visual-contract phase (Step 15) generates a 36-route Next.js prototype via a parallel screen-writer fan-out — and that fan-out is where output quality collapses. The 2026-05-19/20 **mei-saas dogfood** (a full `/product` run for "Simplis"), plus a follow-up report from the mei-saas agent, exposed nine flaws; eight live inside the screen-writer fan-out (F8 is a stale-template issue), while the atlas and the 14 planning artifacts came out clean. Rather than fix a structurally-broken step — making a blind parallel fan-out produce responsive, consistent, visually-verified UI is a hard problem the original `/product` design lost — this spec **restructures** `/product`: the visual-contract phase ends at `screen-atlas.md` plus a small brand-applied hi-fi killer-flow mood (static HTML, the proven Step 02 mechanism), and `/product` then **mandatorily hands off to SDD** — it scaffolds an umbrella spec plus the foundation child spec, with the remaining children listed in the umbrella's matrix. The 36-route screen-writer fan-out is **deleted**. The actual app build moves to the SDD workflow, which is built for deliberate, harness-disciplined, visually-fed implementation. `/product` keeps its genuine strength — design synthesis → a visual contract — and stops doing the thing it does badly. This serves every founder who runs `/product`; the mei-saas prototype is the first re-validation target.

## Acceptance criteria

- [x] **Scenario: `/product` ends at the visual contract, not a built app**
  - **Given** a `/product --stack=next` run
  - **When** the pipeline reaches its end
  - **Then** it has produced `docs/screen-atlas.md` + a hi-fi killer-flow mood (3-5 static HTML screens) + the Step 02 lo-fi mood, and has **not** produced an `app/**/page.tsx` screen set or run any screen-writer fan-out

- [x] **Scenario: mandatory SDD handoff scaffolds the umbrella**
  - **Given** `/product` has completed the visual-contract phase
  - **When** the run finishes
  - **Then** it has scaffolded a filled umbrella spec under `docs/specs/` (`**Type:** umbrella`, with a child-spec matrix sliced by roadmap phase) plus the foundation child spec (child #1, ready to start); children #2..N are listed in the umbrella matrix, not pre-scaffolded

- [x] **Scenario: the hi-fi mood is the rendered half of the contract**
  - **Given** the visual-contract phase
  - **When** the atlas step runs
  - **Then** it produces 3-5 brand+tokens-applied killer-flow screens as self-contained, mobile-first static HTML — a `<style>` block with `@media` breakpoints, never `style=` attributes for layout — giving the SDD children a rendered visual target, not only prose

- [x] **Scenario: `components.md` becomes a real input spec**
  - **Given** the umbrella has been scaffolded
  - **When** the component-library child spec (child #2) is created
  - **Then** its `spec.md` derives from Step 14's `components.md` + `tokens.css` — the design-system spec is the upstream contract, no longer a decorative doc

- [x] **Scenario: shared fixtures are one coherent source**
  - **Given** `/product` holds the persona (concept brief) and the entity model (system design)
  - **When** the visual-contract phase produces its artifacts
  - **Then** it emits a fixture/seed spec (one persona, one coherent entity set, internally consistent dates) that the foundation child implements as a shared `lib/mock-data.ts` — every screen imports it, none invents its own

- [x] The Next.js screen-writer brief and the screen-writer fan-out are removed from `references/delegation-briefs.md` and `SKILL.md` Phase 4.
- [x] The scaffolded umbrella spec encodes a standing styling constraint every child inherits: Tailwind utility classes (the declared stack), no inline `style={{}}` for layout/positioning — closing F1/F2 at the build layer.
- [x] Phase 0 seeds `<out>/.mcp.json` with the Playwright MCP block — visual verification is available to every SDD-child session, and best-effort within the `/product` run itself.
- [x] If the Playwright MCP is loaded, the hi-fi mood screens are screenshotted at mobile + desktop widths and checked for horizontal overflow, with results in `REPORT.md`; if not, an advisory records the skip (best-effort — never blocks).
- [x] `SKILL.md` Phase 5 handoff prints the path to the scaffolded umbrella spec — not a `pnpm dev` instruction.
- [x] `templates/pipeline/15-screen-atlas/` is rewritten for the atlas-only role (no screen-writer references, no per-route `.html` output, current 15-step numbering) — closing F8.
- [x] Step 14's design-system brief emits the Tailwind v4 `@theme` token block (so the downstream component-library child gets real utilities).
- [x] `references/quality-checklist.md` Step 15 criteria are updated for the atlas-only deliverable (atlas completeness + hi-fi mood, not a 36-route fan-out).
- [x] A `/product` smoke run on a small idea reproduces none of F1-F9 — verified against the re-mapping in `## Context`.

## Non-goals

- **The SDD-driven app build itself.** `/product` scaffolds the umbrella + child #1; building the app is the founder working the child specs. Out of scope.
- **The validator-cascade harness flaw (F7's root cause).** Deleting the fan-out makes the cascade moot *for `/product`*, but the underlying harness flaw — `post-edit-validate.sh` typechecking project-wide on every parallel sub-agent edit — is real for any fan-out and is fixed separately in **spec 067** (`parallel-edit-validation`).
- **Steps 01-14 rework.** The restructure touches only the pipeline tail (Step 15 → Phase 5). Steps 01-14 are unchanged except the Step 14 `@theme` addition.
- **Expo / React Native.** The same restructure applies symmetrically; verification is Next.js-only this spec.
- **Visual design taste** (color, type, brand feel) — owned by steps 13/14.
- **Hand-fixing the shipped mei-saas prototype** — a downstream re-run, the founder's call.

## Open questions

- [x] **SDD scaffolding mechanism** — RESOLVED in `plan.md` (Approach §3 + Alternatives): `/product` writes the umbrella + child #1 spec files directly (sdd templates as base), NOT via a `/sdd new` skill-to-skill call — because `/product` must fill them from pipeline artifacts.
- [x] **Child #1 boundary** — RESOLVED in `plan.md` (OQ resolutions): child #1 owns skeleton + tooling + route-group dirs + thin `layout.tsx` shells; shared chrome *components* belong to child #2 (component library), which wires them into the shells.
- [x] **Hi-fi mood selection** — RESOLVED in `plan.md`: the hi-fi mood covers the same killer-flow screens Step 02's lo-fi mood selected (visual lineage preserved).

## Context / references

Flaw matrix from the mei-saas dogfood and the mei-saas agent's follow-up report (2026-05-20), and how the restructure resolves each:

| ID | Flaw | Resolution under the restructure |
|----|------|----------------------------------|
| F1 | Mobile-first absent (`delegation-briefs.md:442-511`) | Screen-writers deleted. Mobile-first required of the hi-fi mood (`<style>`+`@media`) and of every SDD child via the umbrella's standing constraint. |
| F2 | Inline `style={{}}` sanctioned (`delegation-briefs.md:468`) | Dissolves — the screen-writer brief is removed. Tailwind-only mandate carried by the umbrella's standing constraint. |
| F3 | No visual-rendering gate (`quality-checklist.md`) | Fan-out + build-verify deleted. Phase 0 seeds `.mcp.json`; the hi-fi mood gets a best-effort Playwright check; per-route visual verification moves into the SDD children. |
| F4 | Shared chrome unvalidated (`delegation-briefs.md:473`) | The atlas no longer writes `app/` layouts. Chrome becomes shared components built by the component-library / foundation child. |
| F5 | No shared component layer (`delegation-briefs.md:467`) | **Fixed.** `components.md` becomes the input spec for the dedicated component-library child (child #2). |
| F6 | Inline-style bloat / budget overshoot | Dissolves with the fan-out. |
| F7 | Validator-cascade under fan-out (spec 057) | Moot for `/product` (no fan-out). Root harness flaw fixed in spec 067. |
| F8 | Step 15 template desynced (`templates/pipeline/15-screen-atlas/`) | Template rewritten for the atlas-only role. |
| F9 | No shared fixtures — incoherent mock data across screens (mei-saas agent report) | `/product` emits a fixture/seed spec; the foundation child implements `lib/mock-data.ts`; every screen imports it. Same upstream-spec pattern as F5. |

Net: F2, F6 resolved by removal; F7 moot for `/product` (harness fix → spec 067); F1, F3, F4 converted into SDD-child concerns the harness already disciplines; F5 and F9 fixed by upstream-spec relationships; F8 a template rewrite. F1/F2/F3 and the new F9 were independently re-confirmed by the mei-saas agent's follow-up report — external validation of the diagnosis.

- mei-saas dogfood — `/product` "Simplis" run, 2026-05-19/20, `github.com/cfpperche/mei-saas` (commits `3f40e4c`, `cc1ff59`); CC session transcript `43610f10` under `~/.claude/projects/-home-goat-mei-saas/`. Follow-up report from the mei-saas agent: 2026-05-20.
- `.claude/skills/product/SKILL.md` — the skill being restructured (v0.3.0, spec 048).
- `.claude/skills/sdd/` — the handoff target; `.claude/rules/spec-driven.md` § umbrella spec type; `docs/specs/060-harness-gaps-2026/` — the canonical umbrella-spec example.
- `docs/specs/067-parallel-edit-validation/` — the harness-side fix for F7's root cause (split out of this spec).
- `docs/specs/048-product-skill-foundation/`, `docs/specs/045-prototype-skill-pipeline-realign/` — pipeline lineage.
- `docs/specs/057-*` (validator-cascade workaround), `docs/specs/056-pipeline-size-reconciliation`, `docs/specs/065-artifact-budget-discipline`.
- Decision lineage: this restructure extends the "`/product` is a design partner, not a generator" principle (`.claude/REMINDERS.md` — full-stack-expansion item, "Caminho B rejected") one layer up: `/product` is not a screen generator either.
