# 205 — product-honesty-and-fit — plan

_Drafted from `spec.md` on 2026-06-12. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Six approved changes land as one coordinated edit to the `/product` skill, bumping it to **v0.6.0** and the state file to **v6**. The changes are mostly prose/template surgery (SKILL.md orchestration text, reference contracts, per-step prompt/schema templates) plus one new bun script. Order of work follows dependency, not change number: first the state-machine v6 contract (everything else references it), then the new `references/product-forms.md` (Step 07/02/14/15 surfaces read it), then the per-step template edits (Changes 1 + 4), then the judge contract (Change 2), then the SKILL.md orchestration edits that tie it together (Changes 3 + 5 wiring + version bumps), then the staleness script (Change 6), and finally validation.

Resolved open questions (from `spec.md`):

1. **Batched judge granularity** — one judge call per phase, but the judge emits **one verdict object per judge-unit** (a JSON array, one element per unit, same shape as today). The orchestrator merges each element into `quality_verdicts` under its own key. The verdict→gate routing contract is untouched; re-judge on `iterate` overwrites per-key as before. The batched judge's brief gains a cross-document instruction: contradictions between the phase's artifacts are reported as a `cross-consistency` criterion on the offending unit's verdict.
2. **Model mix** — per phase-batch (not per step-range, which would split mid-batch): Phase 1 → sonnet, Phase 2 → opus, Phase 3 → sonnet, Phase 4 → opus. Heavy artifacts (08-12, 15a-c) stay opus-judged; light ones go sonnet. Verdicts already record `model`, which is the measurement surface; `quality-judge.md` gains a § Measurement protocol naming the detection-quality bar (the "streak 17 vs 8" class must still be caught) and the revert path. Adoption is provisional until the next dogfood run records detection holding.
3. **State v6** — adding `gate_concept` (after Step 01) is a behavioral break under the documented bump rule (a v5 resume would mis-orchestrate gate order/iterations), so: `version: 6`, `gates_passed` valid values gain `concept` (ordered first), `iterations` gains `concept: 0`, new field `product_form` (set after Step 01; `null` at init). Resume validation refuses v5 with the same message pattern as v4/v3/v2.
4. **Form-factor taxonomy + home** — enum `screen-app | headless-service | cli | bot | embedded`. Declared in the concept brief (`§ Product form`, human-readable + binding) AND mirrored to `.state.json.product_form` (machine-readable). All per-form behavior lives declaratively in the new `references/product-forms.md`: per form → Step 07 required-categories set, Step 02 mood variant, Step 14 design-system scope, Phase 4 contract artifacts. `screen-app` is the default and reproduces v0.5.0 behavior byte-for-byte in intent.
5. **Variant surface reach** — exactly the four surfaces above (02, 07, 14, 15). Step 02 for non-screen forms still produces static HTML mood (a terminal-session / conversation / API-walkthrough mockup is still HTML) so the craft-floor and judge plumbing stay unchanged.
6. **Staleness checker** — standalone `scripts/staleness-check.ts` (bun, mirrors `build-report.ts` conventions, with a `.test.ts`). On-demand; mentioned in the Phase 5 terminal handoff message. Compares artifact mtimes against `.state.json` ordering + greps US-NN references; prints stale set + the `--from-step=NN` refresh command. Never mutates anything.

## Files to touch

**Create:**
- `.claude/skills/product/references/product-forms.md` — per-form contract: category sets, mood variants, design-system scope, Phase 4 contract artifacts (Change 5)
- `.claude/skills/product/scripts/staleness-check.ts` — advisory staleness reporter (Change 6)
- `.claude/skills/product/scripts/staleness-check.test.ts` — tests: stale detection, US-NN reference matching, no-mutation guarantee

**Modify:**
- `.claude/skills/product/SKILL.md` — v0.6.0: frontmatter description; Phase 0 init (state v6 shape, refuse v5); Phase 1 gains `gate_concept` after Step 01 + product-form capture; § Quality judge rewritten for per-phase batch + model mix; gate sections gain the distilled review-agenda shape (Change 3b); Phase 4 form-variant dispatch; Phase 5 handoff message mentions staleness checker
- `.claude/skills/product/references/state-machine.md` — v6 shape, version history entry, `gate_concept` in progression + Gate UX, `product_form` field, resume refuses v5
- `.claude/skills/product/references/quality-judge.md` — per-phase batch dispatch, per-unit verdict array, `cross-consistency` criterion, model-mix table, § Measurement protocol + revert path
- `.claude/skills/product/references/quality-checklist.md` — assumption-register criteria for Step 03; market-sizing-as-hypothesis criterion for Step 01; projection-disclaimer criteria for Steps 10-12
- `.claude/skills/product/references/pipeline-coverage.md` — step table rows for 01/03/10/11/12 updated; form-awareness notes on 02/07/14/15
- `.claude/skills/product/references/sitemap-schema.md` — `required_categories` becomes form-conditional (set selected per `product_forms.md`); enforcement mechanics unchanged
- `.claude/skills/product/references/delegation-briefs.md` — briefs for Steps 01 (product form + market-sizing framing), 03 (assumption register), 10/11/12 (disclaimer + ranges), 02/07/14/15 ({{product_form}} substitution), quality-judge brief (batch + mix)
- `.claude/skills/product/templates/pipeline/01-ideation/{prompt,schema}.md` — § Product form (new, required) + § Market Sizing reframed as hypothesis with uncertainty (Change 1)
- `.claude/skills/product/templates/pipeline/03-spec/{prompt,schema}.md` — § Problem-Validation Interviews replaced by § Assumption Register (4-risk classification, confidence, riskiest-assumption test recipe, abandon-signal) (Change 1)
- `.claude/skills/product/templates/pipeline/10-roadmap/{prompt,schema}.md` — projection disclaimer block (Change 4)
- `.claude/skills/product/templates/pipeline/11-cost-estimate/{prompt,schema}.md` — projection disclaimer + ranges-not-point-values (Change 4)
- `.claude/skills/product/templates/pipeline/12-gtm-launch/{prompt,schema}.md` — projection disclaimer (Change 4)
- `.claude/skills/product/templates/pipeline/07-sitemap-ia/schema.md` — category set resolved from product form (Change 5)

**Delete:** none.

## Alternatives considered

### Per-step judge calls with a cheaper model everywhere (instead of per-phase batching + mix)

Rejected: keeps 17 dispatch overheads and loses the cross-document consistency check that batching buys for free; an all-sonnet judge panel risks losing exactly the semantic-inconsistency detection that justified the judge (the one validated catch in the baseline run).

### Keeping state v5 (treat the new gate as additive)

Rejected: the documented bump rule says behavioral phase/step breaks bump. A v5 file resumed under the new orchestrator has no `iterations.concept` and a `gates_passed` ordering that can never include `concept`; the conservative refuse-and-restart posture is the established precedent (v4→v5).

### Minimal-only product-shape change (document the screen-app limitation, defer the full variant)

Rejected by the maintainer explicitly (2026-06-12 discussion): go straight to the full level — Step 01 classifies the form, downstream surfaces adapt.

### Folding the staleness checker into `build-report.ts`

Rejected: the report builder is best-effort presentation plumbing that runs mid-pipeline; staleness checking is a post-run, on-demand diagnostic. Coupling them makes the report builder slower and gives the checker a misleading auto-run surface. Standalone script, mentioned in the terminal handoff.

## Risks and unknowns

- **Batched judge output discipline** — one call returning N verdict objects raises the malformed-JSON risk vs today's one-object-per-call. Mitigation: the brief mandates a JSON array written to one verdict file per unit (the judge writes N files, same paths as today), so the merge path stays identical; the array is only the in-message summary.
- **Sonnet judges may be complacent** — the measurement protocol exists precisely for this; the revert is a one-line model-table change. Until a dogfood run confirms detection, `quality-judge.md` marks the mix as provisional.
- **Form-variant templates are necessarily thinner than the screen-app path** — the non-screen Step 07 category sets and Phase 4 contract shapes are first-cut (no dogfood yet). The schema enforcement mechanics are form-neutral, so a weak first-cut category set degrades to a weaker completeness check, not a broken pipeline.
- **delegation-briefs.md is 65 KB** — targeted edits risk breaking brief structure consumed verbatim by dispatches. Mitigation: edit only the named sections; run the skill validator after.
- **The measurement-run acceptance criterion (Change 2) cannot be fully ticked in this repo session** — it requires a real ~3M-token `/product` dogfood run. Deliverable here is the mechanism + protocol + recording surface; the run itself is residual work recorded at close.

## Research / citations

- `.agent0/memory/product-pipeline-empirical-baseline.md` — 2026-05-23 dogfood (cost split, verdict distribution, the fixture-spec semantic catch)
- `references/{state-machine,quality-judge,pipeline-coverage,sitemap-schema}.md` — current contracts read in full before this plan
- Maintainer discussion 2026-06-12 — the six approvals and their constraints (no blocking, full level on Change 5, ship Change 6 together)
- LLM-as-judge practice (G-Eval-style pointwise grading, verbosity-bias mitigation) — already embedded in `quality-judge.md`; this plan preserves those properties under batching
