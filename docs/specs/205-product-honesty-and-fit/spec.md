# 205 — product-honesty-and-fit

_Created 2026-06-12._

**Status:** shipped-partial

**Closure:** 2026-06-12 — shipped in working tree (commit pending maintainer approval); proof: skill validator exit 0, staleness-check tests 11/11, product-overwrite suite 5/5, full harness battery 44/44; residual: the Change-2 judge-mix measurement run (requires a real `/product` dogfood; mix ships provisional per `quality-judge.md § Measurement protocol`; reminder filed).

**UI impact:** none

## Intent

Six approved improvements to the `/product` skill (v0.5.0), arising from a methodology review against product/SE literature (Cagan 4-risks, Torres continuous discovery, lean validation, LLM-as-judge economics) plus the 2026-05-23 empirical baseline. The common thread is **epistemic honesty and fit**: artifacts must stop presenting fabricated evidence as proof and projections as fact; the judge must earn its ~50% token share; the gates must put the few decisions that matter in front of the human; and the pipeline must stop assuming every product is a screen-based web app. None of the changes blocks the pipeline — the user can always proceed; the documents just confess what they are. All six were discussed and individually approved by the maintainer on 2026-06-12.

## Acceptance criteria

### Change 1 — Assumption register replaces synthetic evidence

- [x] **Scenario: Step 03 stops fabricating interviews**
  - **Given** a fresh `/product` run at standard tier
  - **When** Step 03 (functional spec) completes
  - **Then** the artifact contains an assumption register — bets classified by risk type (value / usability / viability / feasibility), each with a confidence level and rationale — and contains NO summaries written as if real user interviews occurred
- [x] **Scenario: riskiest assumption gets a test recipe, not enforcement**
  - **Given** the assumption register exists
  - **When** the artifact is read
  - **Then** it names the single riskiest assumption, proposes the cheapest real-world test for it, and states an abandon-signal (e.g. "fewer than 3 of 10 recognize the problem → rethink") — all as written advice; the orchestrator never checks or enforces any of it
- [x] **Scenario: market sizing presents as hypothesis**
  - **Given** Step 01 (concept brief) completes
  - **When** the § Market Sizing section is read
  - **Then** TAM/SAM/SOM figures are framed as desk-research estimates with cited sources and explicit uncertainty, not as established facts
- [x] The pipeline flow is unchanged: same steps, same gates, nothing new blocks

### Change 2 — Judge economics (both points approved; measure-first)

- [ ] **Scenario: model mix measured before adoption**
  - **Given** the current all-opus judge baseline (17 judges ≈ 1.6M of 3.1M tokens, 2026-05-23 run)
  - **When** a comparison run uses sonnet judges for light steps (01-07) and opus for heavy steps (08-15)
  - **Then** the run records whether the cheap judges still catch real semantic inconsistencies (the fixture-spec "streak 17 vs 8" class); the mix is adopted only if detection holds, reverted or re-split otherwise
- [x] **Scenario: per-phase batched judging**
  - **Given** a phase whose producers have all returned
  - **When** the quality judge is dispatched
  - **Then** one judge call covers the phase's artifact set together (instead of one call per step), and the rubric explicitly asks for cross-document contradictions within the phase
- [x] The verdict→gate routing contract (`references/quality-judge.md`) still works after batching — fail verdicts still pre-fill `iterate` at the phase gate

### Change 3 — Gate leverage (both corrections approved)

- [x] **Scenario: kill-gate after Step 01**
  - **Given** Step 01 returns the concept brief
  - **When** the orchestrator proceeds
  - **Then** an `AskUserQuestion` asks "Did the brief capture your idea?" with continue / adjust / abort BEFORE Step 02 dispatches — the cheapest redirect point
- [x] **Scenario: gates present a distilled review agenda**
  - **Given** any phase gate fires
  - **When** the `AskUserQuestion` is shown
  - **Then** it surfaces the 3-5 decisions actually worth the human's attention (key choices the documents made + judge concerns), assembled from already-generated material; the REPORT.html link remains for deep review
- [x] No gate blocks anything new — `continue` without reading remains possible

### Change 4 — Projection labels on roadmap / cost / GTM (approved as proposed)

- [x] **Scenario: projection disclaimer**
  - **Given** Steps 10, 11, 12 complete
  - **When** `roadmap.md`, `cost-estimate.md`, `gtm-launch.md` are read
  - **Then** each opens with a fixed disclaimer block: pre-validation projection, phase-1-only confidence, re-derive after the brief's assumptions are tested
- [x] **Scenario: ranges instead of point values**
  - **Given** the cost estimate is generated
  - **When** monetary/effort figures appear
  - **Then** they are ranges ("R$ 35-60k"), not single values ("R$ 47k")
- [x] Steps 10-12 still always run, same position in the flow, no new prompts

### Change 5 — Product-shape awareness (FULL level — minimal-only rejected by maintainer)

- [x] **Scenario: Step 01 classifies the product form**
  - **Given** any idea string
  - **When** Step 01 completes
  - **Then** the concept brief declares a product form (screen-based app / headless service / CLI / bot / embedded-in-platform) that downstream steps read as binding
- [x] **Scenario: completeness gate adapts to form**
  - **Given** a non-screen product form is declared
  - **When** Step 07 (sitemap-IA) runs
  - **Then** the required-categories check enforces a form-appropriate baseline (e.g. commands + docs surface for a CLI; endpoints for a headless service) instead of `[marketing, auth, primary, admin, error]` — the anti-silent-undercoverage lesson (Pass E) is preserved against the correct ruler
- [x] **Scenario: visual contract has a per-form variant**
  - **Given** a non-screen product form
  - **When** Phase 4 runs
  - **Then** the contract artifacts are the form's interface contract (command/message/endpoint atlas + fixtures) rather than screen atlas + hi-fi HTML screens
- [x] **Scenario: screen-based products are unaffected**
  - **Given** a web/mobile app idea
  - **When** the full pipeline runs
  - **Then** behavior is identical to v0.5.0 (same categories, same screen-based visual contract)

### Change 6 — Staleness checker (ship together with the others)

- [x] **Scenario: upstream edit flags downstream staleness**
  - **Given** a completed run where the user hand-edits `docs/prd/v1.md` changing US-03
  - **When** the staleness checker runs
  - **Then** it reports which downstream artifacts were generated before the edit, which of those reference US-03, and the `--from-step=NN` command to refresh them
- [x] The checker is advisory only: it never regenerates artifacts, never blocks, never mutates state

## Non-goals

- Blocking the pipeline on real-user validation — all six changes preserve "user can always proceed"
- Removing or reordering any of the 15 steps; no new flags
- Auto-regenerating stale artifacts (Change 6 reports; the human re-runs)
- Tier/depth flags (`--fast`/`--deep`) — single standard tier stays
- Presenting investor-ready (disclaimer-free) variants of the projection documents

## Open questions

- [x] Change 2: per-phase batching preserves per-step granularity — the batched judge writes one verdict FILE per judge-unit (same paths as v0.5.0); the in-message array is only a trace (resolved at plan; `quality-judge.md`)
- [x] Change 2: boundary resolved per phase-BATCH, not step-range (01-07/08-15 would split mid-batch): Phases 1/3 sonnet, Phases 2/4 opus; final adoption still pending the measurement run (resolved at plan; `quality-judge.md § Cost & model mix`)
- [x] Change 3: yes — state bumps v5→v6 (`gates_passed` gains `concept` ordered first, `iterations` gains `concept`, new `product_form` field); resume refuses v5 per the established precedent (resolved at plan; `state-machine.md`)
- [x] Change 5: taxonomy = `screen-app | headless-service | cli | bot | embedded`; declaration lives in BOTH the concept brief `§ Product Form` (human, binding) and `.state.json.product_form` (machine, mirrored after Step 01) (resolved at plan; `product-forms.md`)
- [x] Change 5: variant surface = exactly four (Step 02 mood, Step 07 categories, Step 14 scope, Phase 4 contract), all declarative in `product-forms.md`; Step 02 stays static HTML for every form so craft-floor/judge plumbing is untouched (resolved at plan)
- [x] Change 6: standalone `scripts/staleness-check.ts`, on-demand only (mentioned in the Phase 5 handoff message); not folded into `build-report.ts` — the report builder is mid-pipeline presentation plumbing, the checker is a post-run diagnostic (resolved at plan)

## Context / references

- `.claude/skills/product/SKILL.md` (v0.5.0) — current pipeline
- `.claude/skills/product/references/{pipeline-coverage,quality-judge,quality-checklist,sitemap-schema,state-machine,sdd-handoff}.md`
- `.agent0/memory/product-pipeline-empirical-baseline.md` — 2026-05-23 dogfood: 3.1M tokens, 17 opus judges ≈ 50% of spend, 9 concerns / 0 fails / 0 iterations, all gates passed first-try
- Maintainer discussion 2026-06-12 — six changes reviewed one-by-one, all approved; Change 5 explicitly at full level (minimal-only rejected); Change 6 explicitly "together with the others" (not deferred)
- Literature anchors: Cagan 4-risks (value/usability/viability/feasibility), Teresa Torres continuous discovery (real-touchpoint principle), lean riskiest-assumption testing, LLM-as-judge cost/quality tradeoffs
