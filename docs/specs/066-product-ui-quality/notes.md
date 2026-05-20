# 066 — product-ui-quality — notes

_Created 2026-05-20._

_In-flight design memory for this spec — decisions, deviations, tradeoffs surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Entry shape: `### YYYY-MM-DD — <author> — <one-line title>`._

## Design decisions

### 2026-05-20 — parent — Mood-screen-writer is ONE brief, two modes (not two briefs)

`plan.md` said "delete the screen-writer briefs" + "adapt a hi-fi-mood brief from the Step 02 mood brief". Ambiguity surfaced at implementation: Step 02's lo-fi mood screens were *also* produced by the per-stack screen-writer brief being deleted — so deleting it orphaned Step 02 (b). Decision: replace `§ Per-stack screen-writer` with a single `§ Mood-screen-writer` brief parameterized by `{{mood_tier}}` (`lo-fi` for Step 02, `hi-fi` for Step 15b). One brief serves both passes — avoids two near-duplicate briefs and gives Step 02 (b) a valid target. The mobile-first `@media` mandate (closes F1) lives in this one brief and so applies to both passes.

### 2026-05-20 — parent — hi-fi mood lands at `docs/screens/hifi/`

Neither spec nor plan named the hi-fi mood output path. Decision: `docs/screens/hifi/<NN>-<name>.html` — groups the hi-fi mood under `docs/screens/` alongside Step 02's lo-fi mood (`docs/screens/<NN>-<name>.html`) without a path collision, and keeps Phase 0's `mkdir` simple.

### 2026-05-20 — parent — Step 15a/15b/15c dispatched in parallel (one message)

`plan.md` listed Phase 4 as atlas → hi-fi mood → fixture-spec, reading as sequential. Decision: dispatch all three in ONE message (parallel `Agent` calls). All three read only Phase 1-3 artifacts (already on disk) and write to distinct paths — no FS race. The atlas forward-references the hi-fi mood screens by path; that is fine because the atlas is a contract document, not a consumer of their bytes. Documented in SKILL.md § Worked example.

### 2026-05-20 — parent — pruned the entire `15-screen-atlas/references/` dir

Task 14 said "prune obsolete screen-writer-specific reference files" — only `tokens-application-checklist.md` is unambiguously screen-writer-specific. Decision: delete all four (`tokens-application-checklist`, `screen-atlas-format`, `states-coverage`, `prd-coverage-rubric`) and make the rewritten `prompt.md` fully self-contained. All four were laced with step-7/step-13/MCP cruft; leaving three stale reference files is exactly the F8 template-desync this spec exists to kill. The new `prompt.md` absorbs the still-valid section-shape conventions inline.

### 2026-05-20 — parent — task 17 verified by synthetic smoke trace

A full live `/product` run is a 15-step, multi-hour, many-thousand-token dogfood. The restructure is a skill-body change (markdown only) — fully validated by tracing the rewritten body against the acceptance scenarios. Decision: verify task 17 / the 5 scenarios via synthetic trace, per the spec-059 precedent (`git log`: "spec 059 closed via synthetic smoke test" — the same skill). `spec.md` itself already names the live mei-saas re-run as "the first re-validation target" (downstream, the founder's call). Trace recorded in `tasks.md § Notes`.

## Deviations

### 2026-05-20 — parent — `sitemap-schema.md` edited though not in plan's "Files to touch"

`plan.md § Files to touch` did not list `references/sitemap-schema.md`. Implementation found it carried three dangling references to the deleted per-stack screen-writer (`primary_metric` rendering, `chrome` path-resolution, the intro line). Task 3's instruction — "grep the rest of the doc for dangling references and fix each" — covers it; fixed for consistency (an unfixed F8-style desync otherwise). Plan was not pre-updated because the find was mechanical, not a strategy change.

## Tradeoffs

_None weighed mid-flight beyond the design decisions above._

## Open questions

_None outstanding. The live `/product` dogfood (mei-saas re-run) is downstream, named in `spec.md` Intent + Non-goals — not a blocker for this spec's closure._
