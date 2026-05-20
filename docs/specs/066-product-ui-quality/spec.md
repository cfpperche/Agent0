# 066 — product-ui-quality

_Created 2026-05-20._

**Status:** draft

## Intent

The `/product` skill generates a complete v1 product foundation including a working Next.js/Expo prototype, but its visual-contract phase (Step 15) produces UI below 2026 baseline quality. The 2026-05-19/20 **mei-saas dogfood** — a full `/product` run for "Simplis", 36 routes, pushed to `github.com/cfpperche/mei-saas` — exposed eight concrete flaws. The headline one: the pipeline never instructs any sub-agent to produce **mobile-first / responsive** layouts, and the screen-writer brief actively sanctions React inline `style={{}}` objects, which physically cannot express media queries. Compounding it: there is no visual-rendering gate anywhere (the entire quality bar is `tsc` + `biome` + HTTP-200, so glaring chrome bugs — a wordmark rendered twice — ship undetected); the shared route-group chrome is produced by one unvalidated dispatch; no step builds a shared component layer, so 36 screens re-implement primitives inline (30-54 KB files); and the Step 15 template is desynced from the live 15-step pipeline. This spec fixes the **skill** so a fresh run produces responsive, consistent, visually-verified screens. It serves every founder who runs `/product`; the mei-saas prototype is the first re-validation target.

## Acceptance criteria

- [ ] **Scenario: generated web screens are mobile-first responsive**
  - **Given** a `/product --stack=next` run has completed
  - **When** a representative screen renders at a 375 px viewport
  - **Then** content reflows to a single column with no horizontal scroll and no clipped or overlapping elements, and the same screen at 1280 px shows the intended desktop layout

- [ ] **Scenario: the pipeline gates on rendered pixels, not only static checks**
  - **Given** Step 15 / Phase 4 of a `/product` run
  - **When** the build-verification stage runs
  - **Then** each representative route is rendered headlessly at ≥2 viewports (mobile + desktop) via Playwright, screenshots are captured, and a visual-check result is recorded in `docs/REPORT.md`

- [ ] **Scenario: shared chrome is validated before screens inherit it**
  - **Given** the atlas has written the route-group layout(s) (`app/(<chrome>)/layout.tsx`)
  - **When** the orchestrator processes the atlas output
  - **Then** the chrome is checked for composition defects (brand wordmark rendered more than once, unfilled placeholder text/comments, empty declared regions) and any defect is flagged before the screen-writer fan-out

- [ ] **Scenario: screens reuse a shared component layer**
  - **Given** the design-system step produced `components.md`
  - **When** the screen-writers run
  - **Then** the components named in `components.md` exist as shared modules under `app/_components/` and screens import them instead of re-implementing primitives inline

- [ ] The Next.js screen-writer brief in `references/delegation-briefs.md` mandates responsive layout via breakpoint-aware utility classes and forbids inline `style={{}}` for layout/positioning; both CONSTRAINTS and DONE_WHEN reflect this.

- [ ] `references/quality-checklist.md` includes a responsive/visual gate criterion (it is currently 100 % static checks — `tsc`, `biome`, grep, file-existence).

- [ ] `templates/pipeline/15-screen-atlas/` (`prompt.md` + `references/`) is resynced with the live 15-step pipeline — no surviving references to pre-spec-045 numbering (`step 8 PRD`, `step 5 brand-book`, `step 6 design-system`, `prototype-v3`) or `.html` screen output.

- [ ] A fresh `/product` smoke run (or a re-run of the mei-saas prototype) reproduces none of the eight dogfood flaws (F1-F8 in `## Context`).

## Non-goals

- Hand-fixing the already-shipped mei-saas prototype — that is a downstream re-run that verifies this spec, not part of it. This spec fixes the *skill*.
- Redesigning the parallel screen-writer fan-out / validator-cascade (F7) — that is spec 057's domain; referenced here, not reworked (a small mitigation may ride along — see Open questions).
- Expo / React Native mobile-first parity — the dogfood was Next.js; Expo is a fast-follow unless the change is trivially symmetric.
- Visual *design taste* (color, type pairing, brand feel) — owned by the design-system steps (13/14). This spec is about responsive correctness, cross-screen consistency, and visual verification — not aesthetic judgement.

## Open questions

- [x] **v1 scope** — RESOLVED 2026-05-20 (user): F1-F6 + F8 in scope; F7 referenced-only (spec 057's domain).
- [x] **Visual-gate severity** — RESOLVED 2026-05-20 (user): advisory for v1 — records the visual-check result in `REPORT.md`, does not fail the run; matches the `tsc`/`biome` smoke-test posture.
- [x] **Component-layer mechanism** — RESOLVED in `plan.md` (Approach §2): a new component-builder dispatch between the atlas (15a) and the screen-writer fan-out (15b).
- [x] **Styling mechanism** — RESOLVED in `plan.md` (Approach §1+§4): Tailwind v4 exclusively; Step 14 emits an `@theme` token block; inline `style={{}}` narrowed to runtime-dynamic values only.
- [x] **Chrome-validation placement** — RESOLVED in `plan.md` (Approach §3): a parent-side orchestrator grep check after the atlas returns, with the Playwright visual gate as backstop.

## Context / references

The eight-flaw matrix, diagnosed this session against the mei-saas dogfood:

| ID | Flaw | Primary evidence |
|----|------|------------------|
| F1 | Mobile-first absent from the pipeline | `references/delegation-briefs.md:442-511` (screen-writer brief — zero responsive constraints); `references/quality-checklist.md` (no visual gate) |
| F2 | Brief sanctions inline `style={{}}` (cannot express `@media`) | `references/delegation-briefs.md:468` ("`var()` inline OR Tailwind") |
| F3 | No visual-rendering gate — quality bar is 100 % static | `references/quality-checklist.md`; `SKILL.md` Phase 4 smoke-test (HTTP-200 only) |
| F4 | Shared chrome written by one unvalidated dispatch | `references/delegation-briefs.md:473`; mei-saas `app/(app)/layout.tsx` (wordmark rendered 2×) |
| F5 | No shared component layer — primitives re-implemented per screen | `references/delegation-briefs.md:467` ("extract … if needed" — optional) |
| F6 | Inline-style bloat → systematic budget overshoot | mei-saas screen files 30-54 KB vs 8-18 KB target (`pipeline-coverage.md`) |
| F7 | Validator-cascade degrades quality under fan-out | spec 057; mei-saas transcript Waves 3-5 |
| F8 | Step 15 template desynced from live pipeline | `templates/pipeline/15-screen-atlas/prompt.md` (pre-spec-045 numbering) |

- mei-saas dogfood — `/product` "Simplis" run, 2026-05-19/20, `github.com/cfpperche/mei-saas` (commits `3f40e4c`, `cc1ff59`); CC session transcript `43610f10` under `~/.claude/projects/-home-goat-mei-saas/`.
- `.claude/skills/product/SKILL.md` — the skill being fixed (v0.3.0, spec 048).
- `docs/specs/048-product-skill-foundation/`, `docs/specs/045-prototype-skill-pipeline-realign/` — pipeline lineage.
- `docs/specs/057-*` (validator-cascade), `docs/specs/056-pipeline-size-reconciliation` (budget calibration), `docs/specs/065-artifact-budget-discipline`.
- `.claude/rules/artifact-budgets.md`.
