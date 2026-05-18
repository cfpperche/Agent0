# Tasks — 045-prototype-skill-pipeline-realign

Working checklist. Each task = one logical edit unit. Check off as completed.

## Batch 1 — Structural reshape

- [ ] **1.1** Add `metadata.skill-version: 0.2.0` to `.claude/skills/prototype/SKILL.md` frontmatter
- [ ] **1.2** Rewrite SKILL.md § Phase 1 — Discovery (steps 01-04 unchanged content; restate gate at step 4 = `gate_discovery`)
- [ ] **1.3** Rewrite SKILL.md § Phase 2 — was Identity, now **Specification** (steps 05-12: prd-1pager → ost → sitemap-ia → system-design → legal → roadmap → cost-estimate → gtm-launch; gate at step 12 = `gate_specification`)
- [ ] **1.4** Rewrite SKILL.md § Phase 3 — was Specification, now **Identity** (steps 13-14: brand → design-system; gate at step 14 = `gate_identity`)
- [ ] **1.5** Rewrite SKILL.md § Phase 4 — Synthesis → renamed **Visual contract** (step 15: screen-atlas; no gate; closes with /sdd new handoff)
- [ ] **1.6** Update SKILL.md § Phase 0 — references to step ordering + handoff message paths use new step numbers
- [ ] **1.7** Update SKILL.md "Worked example" parallel-dispatch shape — use Phase 2 (specification) Steps 06+07 OR 09+10 quad (true parallel, no FS race), drop the false-positive 02+03+04 example
- [ ] **1.8** Rewrite `references/state-machine.md` § `.state.json` shape — bump to `version: 3`; `phase` enum `discovery | specification | identity | visual-contract`; `step` int 1-15
- [ ] **1.9** Update state-machine.md § Phase progression diagram — 4 substantive phases + gates [4, 12, 14]
- [ ] **1.10** Add state-machine.md § Resume from v2 state — if `version != 3`, abort with actionable error
- [ ] **1.11** Rewrite `references/pipeline-coverage.md` § Phase ↔ step map — 4 phases, gates [4, 12, 14]
- [ ] **1.12** Rewrite pipeline-coverage.md § Per-step output + size targets — 15 rows new order, including new OST / sitemap-ia / gtm-launch / screen-atlas (renamed) rows; cost↔roadmap swap reflected
- [ ] **1.13** Update pipeline-coverage.md § Lightening op per step — add bullets for OST / sitemap-ia / gtm-launch (new); remove bullet for prototype-v2 (deleted); update prototype-v3 → screen-atlas bullet
- [ ] **1.14** Update pipeline-coverage.md § Bundled-template provenance — explicit note: "spec 045 ships own template derivations, NOT re-copied from packages/mcp-product-pipeline (which is mid-realign via spec 032)"
- [ ] **1.15** Update pipeline-coverage.md § Three-prototype-pass rationale → renamed § Two-prototype-pass rationale; rewrite reasoning (lo-fi Step 02 + hi-fi Step 15 absorbs both v2 + v3 work)
- [ ] **1.16** Full rewrite of `references/delegation-briefs.md` — 15 step briefs in new order + per-stack screen-writer brief (unchanged shape); CONTEXT references use new step numbers + paths; legal brief moved to Step 09 with DPIA-trigger language consuming system-design's data-flow inventory
- [ ] **1.17** Add new screen-writer brief variant for `gate_specification` (Step 12 — gtm-launch is doc-only, no dispatch fan-out)

## Batch 2 — Sitemap schema enforcement

- [ ] **2.1** Rewrite `references/sitemap-schema.md` — declare `required_categories: [marketing, auth, primary, admin, error]` as schema binding; per-route field set (path / category / states / covers_us / components); explicit `deferred-out-of-v1` escape clause shape with `reason` field
- [ ] **2.2** Add sitemap-schema.md § Parent-side validation — pseudocode for orchestrator's post-Step-07 check: enumerate sitemap routes, group by category, BLOCK Step 07 if any required_category has 0 routes AND no top-level `deferred_categories: [{name, reason}]` declaration

## Batch 3 — Template deletions + renames

- [ ] **3.1** Create tombstone: `docs/specs/045-prototype-skill-pipeline-realign/artifacts/deleted-step-7-prototype-v2.md` — verbatim copy of `.claude/skills/prototype/templates/pipeline/07-prototype-v2/prompt.md` + `schema.md` + `references/*.md` with deletion-rationale header (cites Decision 8 + 14)
- [ ] **3.2** Delete `.claude/skills/prototype/templates/pipeline/07-prototype-v2/` recursively
- [ ] **3.3** `git mv .claude/skills/prototype/templates/pipeline/13-prototype-v3/ .claude/skills/prototype/templates/pipeline/15-screen-atlas/`
- [ ] **3.4** Update `.claude/skills/prototype/templates/pipeline/15-screen-atlas/prompt.md` body — absorb brand+tokens-applied responsibility from deleted Step 7 (was distributed across both); slug name `prototype-v3` → `screen-atlas` updated wherever inline

## Batch 4 — New step templates

- [ ] **4.1** Create `.claude/skills/prototype/templates/pipeline/06-ost/prompt.md` — Opportunity Solution Tree (Teresa Torres Continuous Discovery Habits methodology; lightweight at standard tier: 1 desired outcome root → 3-5 opportunities → 2-3 solutions per opportunity)
- [ ] **4.2** Create `.claude/skills/prototype/templates/pipeline/06-ost/schema.md` — required sections + size target
- [ ] **4.3** Create `.claude/skills/prototype/templates/pipeline/07-sitemap-ia/prompt.md` — IA decomposition + full screen inventory; schema-bound to sitemap-schema.md; required_categories enforcement
- [ ] **4.4** Create `.claude/skills/prototype/templates/pipeline/07-sitemap-ia/schema.md` — YAML output shape + validation rules
- [ ] **4.5** Create `.claude/skills/prototype/templates/pipeline/12-gtm-launch/prompt.md` — positioning canvas (April Dunford-aligned lightweight) + launch plan 4-week sketch + pricing strategy (free/standard/pro tier shape if relevant)
- [ ] **4.6** Create `.claude/skills/prototype/templates/pipeline/12-gtm-launch/schema.md` — required sections + size target

## Batch 5 — Existing template reshape

- [ ] **5.1** Extend `templates/pipeline/01-ideation/prompt.md` — add § Market Sizing (TAM/SAM/SOM, lightweight, NOT primary research — desk research with 1-2 cited sources per number)
- [ ] **5.2** Extend `templates/pipeline/03-spec/prompt.md` — add § Problem-Validation Interviews (3-5 summaries; can be synthetic if standard-tier; seeds OST opportunities)
- [ ] **5.3** Full rewrite `templates/pipeline/05-prd/prompt.md` — Lenny 1-pager hybrid: H2 sections in exact order: Problem · Why now · Success metrics (with NSM slot) · Solution sketch · User stories (US-NN stable IDs) · Anti-goals · Release scope · Upstream/downstream refs
- [ ] **5.4** Update `templates/pipeline/05-prd/schema.md` — Lenny hybrid section requirements; 4-7 KB target (tighter than pre-spec — 1-pager discipline)
- [ ] **5.5** Extend `templates/pipeline/08-system-design/prompt.md` (number after renumbering: still 08 in new order) — add § RACI Matrix + § Risk Register; § Data Flow Inventory (consumed downstream by Step 09 legal for DPIA trigger)
- [ ] **5.6** Renumber other templates if path conflicts surface (audit only — no expected conflicts since 03/04/08/10/11 are kept positionally; 06/07/12/15 are new dirs; 05 keeps shape; 13 deleted, 13 renamed→15)

## Batch 6 — Validate

- [ ] **6.1** Run `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` → must exit 0
- [ ] **6.2** Visual sanity `ls .claude/skills/prototype/templates/pipeline/` shows 15 dirs (NOT 13): 01-ideation, 02-prototype, 03-spec, 04-ux-testing, 05-prd, 06-ost, 07-sitemap-ia, 08-system-design, 09-legal, 10-roadmap, 11-cost-estimate, 12-gtm-launch, 13-brand, 14-design-system, 15-screen-atlas
- [ ] **6.3** Grep audit: `grep -rn "prototype-v2\|prototype-v3\|13-prototype" .claude/skills/prototype/` returns ONLY tombstone references (or zero)
- [ ] **6.4** Grep audit: `grep -rn "version.*2\|phase.*identity.*specification" .claude/skills/prototype/references/state-machine.md` returns the new v3 shape only

## Batch 7 — Steward redogfood (NEXT SESSION)

- [ ] **7.1** Fresh CC session — invoke `/prototype "Claude Code governance dashboard" --stack=next --out=/tmp/dogfood-v3`
- [ ] **7.2** Walk all 15 steps + 3 gates end-to-end (founder choice = continue on each)
- [ ] **7.3** Compare `/tmp/dogfood-v3/docs/07-sitemap-ia.yaml` vs `/tmp/dogfood-v2/docs/02-sitemap.yaml`: new should cover ≥3 auth routes + ≥2 admin routes beyond policy + ≥2 error routes
- [ ] **7.4** Compare `/tmp/dogfood-v3/docs/15-screen-atlas.md` vs `/tmp/dogfood-v2/docs/13-screen-atlas.md`: new PRD coverage matrix shows 0 silent gaps in required_categories
- [ ] **7.5** Verify `/tmp/dogfood-v3/` follows iter-2 layout (all artifacts under docs/, root clean)
- [ ] **7.6** Verify build: `tsc --noEmit` exit 0 + `biome check .` exit 0
- [ ] **7.7** Write `docs/specs/045-prototype-skill-pipeline-realign/artifacts/redogfood-comparison.md` — A/B table + acceptance verdict
- [ ] **7.8** Flip spec 045 status `in-progress → shipped`
- [ ] **7.9** Bump `metadata.skill-version: 0.2.0 → 0.2.1` if any post-redogfood patches needed; else keep 0.2.0
- [ ] **7.10** Commit + close `/goal`
