# 032 — pipeline-industry-alignment — plan

_Drafted from `spec.md` on 2026-05-17. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

This spec is **the parent** — it locks the new pipeline shape (17 decisions in `spec.md` § Acceptance criteria § A) and decomposes implementation into **8 child specs** that ship incrementally, each independently reviewable. The parent itself ships **zero code**; its only deliverable is `spec.md` + `research-report.md` + this plan + the child-spec dispatch list. Code lands in children.

The decomposition strategy: **037 = foundational structural refactor** (STEPS array, gates, repeatable-step infra) blocks everything; **038-043 = per-step template work** (PRD-1pager+OST, sitemap, legal-shift-left, GTM, Discovery+system-design extensions, post-launch-review) which can mostly parallelize after 037 lands; **044 = end-to-end redogfood Octant validation** which depends on all and is the spec-032 acceptance gate. Phase B's port→dogfood→judge→calibrate loop (`.claude/memory/anthill-port-workflow.md`) applies inside each template-work child spec — every new/reshaped template gets a dogfood pass before merge.

## Files to touch

This parent spec creates spec files and a research artifact, nothing else. All `packages/mcp-product-pipeline/` source changes happen in child specs.

**Create (this parent spec):**
- `docs/specs/032-pipeline-industry-alignment/spec.md` — already created (Decisions 1-17 locked)
- `docs/specs/032-pipeline-industry-alignment/plan.md` — this file
- `docs/specs/032-pipeline-industry-alignment/tasks.md` — phase-by-phase dispatch + verification (already drafted, updated post-Q1-Q7)
- `docs/specs/032-pipeline-industry-alignment/research-report.md` — already created (48 sources)
- `docs/specs/032-pipeline-industry-alignment/MIGRATION-NOTES.md` — to be created in child spec 037 per Decision 16 (documents shape changes for any future fork re-cherry-pick)

**Create (each child spec — handled separately):**
- `docs/specs/037-pipeline-structural-refactor/` — foundation
- `docs/specs/038-prd-1pager-ost/` — PRD reshape
- `docs/specs/039-sitemap-ia-step/` — root-cause fix for atlas under-cover
- `docs/specs/040-legal-shift-left/` — re-template existing legal at new position
- `docs/specs/041-gtm-launch-step/` — new step template
- `docs/specs/042-discovery-systemdesign-extensions/` — bullet expansions (market + problem-validation + RACI/risk + NSM)
- `docs/specs/043-post-launch-review-step/` — repeatable step template
- `docs/specs/044-redogfood-octant-validation/` — end-to-end acceptance

**No direct modification to `packages/mcp-product-pipeline/` in this parent spec.**

### Child-spec dispatch table (post Q1-Q7 resolution)

| NNN | Slug | Implements decisions | Effort | Depends on | Ship-order |
|---|---|---|---|---|---|
| 037 | pipeline-structural-refactor | 2 (infra) · 3 · 4 (slot) · 5 (slot) · 7 (slot) · 8 (delete step 7) · 11 (sibling array + MCP tools) · 12 (OST slot) · 14 (rename → screen-atlas) · 16 (version bump 0.1.0→0.2.0 + MIGRATION-NOTES) | **L+** (grew from Q1+Q4+Q6+Q12 additions) | — | 1 (blocking) |
| 038 | prd-1pager-ost | 1 · 9 (NSM slot) · 12 (OST template) · 15 (Lenny hybrid bones) | L | 037 | 2 |
| 039 | sitemap-ia-step | 5 (content) · 13 (YAML schema w/ required_categories) | M | 037 · 038 | 3 (parallel w/ 040-043) |
| 040 | legal-shift-left | 4 (re-template at new slot, DPIA-trigger logic) | M | 037 · 042 (needs system-design data-flow) | 3 (parallel — but content-orders after 042) |
| 041 | gtm-launch-step | 7 (content) | M | 037 | 3 (parallel) |
| 042 | discovery-systemdesign-extensions | 6 (extend steps 1+3) · 10 (extend system-design) | S-M | 037 | 3 (parallel) |
| 043 | post-launch-review-step | 11 (template that consumes the sibling tools shipped in 037) | M | 037 · 038 | 3 (parallel) |
| 044 | redogfood-octant-validation | 17 (verbatim + gap-audit + fresh dir end-to-end) | M+ (scope grew per Q7 c) | 037-043 all shipped | 4 (last) |

Estimated calendar duration: 037 ~1.5 weeks (grew), 038 ~1 week, parallelizable 039-043 ~2 weeks, 044 ~1 week. Total ~5.5 weeks calendar (~6.5 weeks worst-case with calibration loops).

**Effort changes from initial plan:**
- 037 went L → L+ because Q1 (sibling-not-step) introduces `POST_LAUNCH_ACTIONS` array + new MCP tool surface (`product_post_launch_review_start/get/submit`); Q4 adds slug rename `prototype-v3` → `screen-atlas`; Q6 adds version bump + MIGRATION-NOTES.md.
- 044 went M → M+ because Q7 (c) expanded from "validate atlas" to "walk full pipeline 1→15 + sibling, gap-audit per step, comparator vs 026 where applicable".

## Alternatives considered

### One mega-spec ("032-mega" — everything in one ship unit)
Rejected because: (a) review surface is unmanageable (~30+ template files + pipeline.ts + state.ts + tools.ts + tests + dogfood evidence in a single PR); (b) blocks any partial shipping — a calibration miss on the sitemap step would block the legal-shift-left change which is GDPR-compliance load-bearing; (c) the parent-spec + child-specs pattern is exactly what the SDD escalation note in `.claude/rules/spec-driven.md` § *Escalation path* describes; (d) `.claude/memory/feedback_anthill_port_smart_not_rigid.md` prescribes "calibration over rigidity" — calibration needs separable per-step cycles, mega-spec collapses them.

### No parent spec — just write child specs as they come up
Rejected because: (a) loses coherence of vision — a new contributor opening any one child spec couldn't reconstruct why the pipeline reshape exists; (b) the 48-source research and the 10 locked decisions need a single home, not 8 fragmented home-references; (c) the decomposition itself is a design decision that needs review (parent spec is the artifact where "should we have an OST step or embed?" can be argued; child specs assume the answer); (d) Open questions Q1-Q7 in spec.md are cross-cutting — they need to resolve at parent level, not be re-litigated 8 times.

### Fork `packages/mcp-product-pipeline/` into a v2 package, keep v1 frozen for backward compatibility
Rejected because: (a) we have one consumer right now (this repo, eventually downstream forks via sync-harness) — premature optimization; (b) the harness-sync spec 016 doesn't propagate packages anyway; (c) two parallel packages = doubled maintenance forever, calibration drift between them inevitable; (d) Open Q6 (backward-compat with forks) can be handled by a single `pipelineVersion` field in `.mcp.json` if needed, not by package fork.

### DAG / parallel-track pipeline (Brand+PRD parallel, dual-track agile)
Already rejected in `spec.md` § Non-goals (third bullet). Reproducing reasoning here for plan-completeness: linear sequence with `GATE_AFTER` is preserved because (a) DAG support is a multi-month refactor of state.ts + tools.ts + product_advance semantics; (b) the dual-track value (Torres) can be approximated by making OST a living artifact (Camp C decision 1) and adding the post-launch-review loop (decision 2) without restructuring sequencer; (c) DAG support is a separate spec if/when justified by usage data, not a prerequisite for this alignment work.

## Risks and unknowns

### Risks

- **Decision 8 reversibility (collapse prototype-v2 → delete step 7).** This is the most-painful-to-rollback decision. If, after 044 redogfood validation, the founder finds that hi-fi prototype WITHOUT a mid-fi stop is too steep a jump from lo-fi (step 2), reintroducing step 7 means: re-writing its template, re-calibrating brand+tokens-applied flow, and updating prototype-v3 to depend on prototype-v2 again. Phase B work on step 7 (commit `15d200d`) is discarded by decision 8 — that's sunk cost. **Mitigation:** child spec 037 must produce a deletion-with-tombstone (preserve the old step 7 template body in `docs/specs/037-*/artifacts/deleted-step-7-prototype-v2.md`) so rollback is "restore from tombstone" not "rewrite from scratch".

- **Atlas calibration carry-over.** Phase B calibrated step 13 (atlas) against current PRD format (16 user-stories). Camp C reshapes PRD to 1-pager — the atlas's "for each US-NN render a screen" logic now consumes a different artifact (1-pager + OST + sitemap). The dogfood-calibrated literal-anchor counts (4-dim score, ≥10 KB atlas size, ≥8 KB per-screen) may need re-calibration. **Mitigation:** child spec 039 (sitemap) and child spec 038 (PRD) both include "re-run atlas dogfood against reshape" as their own acceptance criterion.

- **Phase B calibrations partially discarded.** Templates 5 (brand), 6 (design-system), 7 (prototype-v2 — deleted), 11 (roadmap), 12 (legal), 13 (atlas) were all calibrated in Phase B. Decisions 4 + 8 directly discard step 7 + relocate step 12. Other Phase B work (step 11 roadmap, step 13 atlas) survives untouched as long as their *inputs* survive — which they mostly do. **Mitigation:** parent plan tracks per-template "preserved / re-calibrated / discarded" in a table to be filled in tasks.md.

- **Calendar timeline (~5 weeks) may overlap with founder priorities.** This is a multi-week effort; if a downstream project (consultancy engagement, dogfood) urgently needs the current 13-step pipeline, blocking work on 032 while reshape is incomplete may surface mid-flight. **Mitigation:** decision 5 (sitemap step) is the highest-value isolated child spec — if calendar pressure hits, ship 037 + 038 + 039 + 044 (a 3-spec slice) as v1, defer 040-043 to v2.

- **GDPR shift-left mis-calibration.** Decision 4 moves legal earlier, but moving without the DPIA-trigger logic (data-flow inventory from system-design) means legal lands without the upstream signal it needs. **Mitigation:** child spec 040 (legal shift-left) MUST sequence after system-design's data-flow output, not just position earlier in the linear order. The dependency is content (legal references system-design's data-flow inventory), not just slot.

- **POST_LAUNCH_ACTIONS sibling infrastructure** (Decision 11). New top-level concept in `pipeline.ts` + new MCP tool surface (`product_post_launch_review_start/get/submit`). This is the first non-linear capability in the MCP — risk of inconsistent state semantics with linear `product_advance`. **Mitigation:** child spec 037 includes type-level test enforcing "sibling actions cannot fire `product_done` or affect `state.currentStep`"; the two concepts share `state.ts` storage but not `state.ts` advance logic.

- **Slug rename `prototype-v3` → `screen-atlas`** (Decision 14). Git diff renames are fragile across the porter→judge→calibrate Phase B history; commits that referenced `13-prototype-v3` by path will retroactively be unreachable by path. **Mitigation:** child spec 037 preserves the old path in `docs/specs/037-*/artifacts/path-rename-table.md` mapping old `<NN>-prototype-v3` → new `<NN>-screen-atlas` for any historical reference.

### Unknowns

- **OST artifact format.** Embedded in PRD-1pager step? Own step? Own template inside step? Open Q2 in spec.md. Resolves in child spec 038.
- **Sitemap step output format.** Markdown route list? Tree? YAML the atlas consumes? Open Q3 in spec.md. Resolves in child spec 039.
- **Numbering for post-launch-review step.** `14`, `14R`, drop-the-number? Open Q1. Resolves in child spec 037 + 043.
- **Backward-compatibility window.** Hard cutover vs deprecation? Open Q6. Resolves in child spec 037.
- **Redogfood brief — verbatim vs revised.** Open Q7. Resolves in child spec 044.

## Research / citations

- **`docs/specs/032-pipeline-industry-alignment/research-report.md`** — 48-source web research captured 2026-05-17. Full list. Key sources informing this plan's decomposition:
  - [SVPG — Flavors of Prototypes](https://www.svpg.com/flavors-of-prototypes/) — basis for decision 8 (2-stage prototyping)
  - [Lenny Rachitsky — PRDs / 1-Pagers](https://www.lennysnewsletter.com/p/prds-1-pagers-examples) — basis for PRD-1pager shape in child spec 038
  - [Product Talk — OST](https://www.producttalk.org/opportunity-solution-trees/) — basis for OST sibling artifact (Torres)
  - [GDPR Art 25](https://gdpr-info.eu/art-25-gdpr/) + [EDPB Guidelines 4/2019](https://www.edpb.europa.eu/sites/default/files/files/file1/edpb_guidelines_201904_dataprotection_by_design_and_by_default_v2.0_en.pdf) — basis for decision 4 (legal shift-left)
  - [Eleken — Sitemap UX](https://www.eleken.co/blog-posts/sitemap-ux) + [Raw.Studio — Hidden UX moments](https://raw.studio/blog/empty-states-error-states-onboarding-the-hidden-ux-moments-users-notice/) — basis for decision 5 (sitemap step)
  - [Stage-Gate International](https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/) — basis for post-launch-review step (stage 6)
  - [Asana — GTM 9-step](https://asana.com/resources/go-to-market-gtm-strategy) — basis for decision 7 (GTM step)
- **Predecessor specs:**
  - `docs/specs/025-mcp-product-pipeline/` — original 12-step shape
  - `docs/specs/026-mcp-pipeline-deep-port/` — Phase B template calibrations (preserved where possible, discarded for step 7)
- **Memory references:**
  - `.claude/memory/anthill-port-workflow.md` — port→dogfood→judge→calibrate loop applies in each template-work child spec
  - `.claude/memory/feedback_anthill_port_smart_not_rigid.md` — calibration over rigidity; basis for decision 6 (resist over-stepify)
  - `.claude/memory/feedback_mcp_package_self_contained.md` — all template changes live inside `packages/mcp-product-pipeline/`, not Agent0 `.claude/`
  - `.claude/memory/feedback_agent0_changes_ship_via_rules_not_memory.md` — child specs that emit new rules ship them into `.claude/rules/` so forks inherit
- **SDD escalation reference:**
  - `.claude/rules/spec-driven.md` § *Escalation path* — endorses parent-spec + child-specs pattern for multi-week work
