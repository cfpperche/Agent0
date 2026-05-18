# Plan — 045-prototype-skill-pipeline-realign

## Approach

Single-spec monolithic ship (per Q1 ratification). All work happens in ~7 file-touch batches that map 1:1 to the new pipeline shape's structural concerns. Within each batch, parent does mechanical edits (since per-edit validator cost is repo-wide and burned Phase 3 of Pass E — see spec 036 REPORT.md finding #1); sub-agents are reserved for **content writing inside new template `prompt.md`/`schema.md` files**, NOT structural reshape of existing references. Batch order is dependency-driven: structural reshape (SKILL.md / state-machine / pipeline-coverage / delegation-briefs) before template work, template work before validate, validate before redogfood.

## Files to touch (definitive — drives tasks.md)

### Batch 1 — Structural reshape (SKILL + references)

- `M .claude/skills/prototype/SKILL.md` — Phase ordering rewrite (4 substantive phases: discovery → specification → identity → visual-contract; gates [4, 12, 14]); add `metadata.skill-version: 0.2.0` frontmatter; references to step counts/numbers updated throughout
- `M .claude/skills/prototype/references/state-machine.md` — `.state.json` v3 shape (phase enum, step 1-15); legacy v2 detection on resume; new gates_passed enum
- `M .claude/skills/prototype/references/pipeline-coverage.md` — new 15-step table in new order; output paths updated; per-step lightening choices for new steps (OST / sitemap-IA / GTM)
- `M .claude/skills/prototype/references/delegation-briefs.md` — full rewrite of 15 step briefs in new order + retain per-stack screen-writer brief; cost↔roadmap CONTEXT swap; legal brief moved to position 9 with DPIA-trigger language

### Batch 2 — Sitemap schema enforcement (single most important mechanical fix)

- `M .claude/skills/prototype/references/sitemap-schema.md` — declare `required_categories: [marketing, auth, primary, admin, error]` as schema binding; per-route field set; explicit `deferred-out-of-v1` escape clause for categories with zero routes; document the parent-side validation that BLOCKS Step 07 if uncovered category found without deferral

### Batch 3 — Template deletions + renames

- `D .claude/skills/prototype/templates/pipeline/07-prototype-v2/` — DELETED (tombstone preserved)
- `+ docs/specs/045-prototype-skill-pipeline-realign/artifacts/deleted-step-7-prototype-v2.md` — tombstone (verbatim copy of deleted prompt.md + schema.md + references/, with deletion-rationale header)
- `mv .claude/skills/prototype/templates/pipeline/13-prototype-v3/` → `.claude/skills/prototype/templates/pipeline/15-screen-atlas/` — slug rename; internal `prompt.md` body absorbs brand+tokens-applied responsibility from deleted Step 7

### Batch 4 — New step templates (OST, sitemap-IA, GTM)

- `+ .claude/skills/prototype/templates/pipeline/06-ost/prompt.md + schema.md` — Opportunity Solution Tree (Teresa Torres-aligned; sibling artifact to PRD)
- `+ .claude/skills/prototype/templates/pipeline/07-sitemap-ia/prompt.md + schema.md` — IA + full screen inventory; schema binds to sitemap-schema.md's `required_categories`
- `+ .claude/skills/prototype/templates/pipeline/12-gtm-launch/prompt.md + schema.md` — positioning / launch plan / pricing strategy (Stage-Gate stage 6 lightweight)

### Batch 5 — Existing template reshape

- `M .claude/skills/prototype/templates/pipeline/01-ideation/prompt.md` — extend with H2 "Market sizing" (TAM/SAM/SOM brief, lightweight) per Decision 6
- `M .claude/skills/prototype/templates/pipeline/03-spec/prompt.md` — extend with H2 "Problem-validation interviews" (3-5 summaries seeding OST) per Decision 6
- `M .claude/skills/prototype/templates/pipeline/05-prd/prompt.md` — full reshape to Lenny 1-pager hybrid per Decision 1 + 15
- `M .claude/skills/prototype/templates/pipeline/08-system-design/prompt.md` — extend with H2 "RACI" + "Risk register" per Decision 10; also DPIA-trigger output (data-flow inventory consumed by Step 9 legal)
- `M .claude/skills/prototype/templates/pipeline/05-prd/schema.md` — schema update for Lenny hybrid section requirements

### Batch 6 — Validate skill compliance

- Run `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` — must exit 0
- Run `node_modules/.bin/biome check .claude/skills/prototype/ 2>/dev/null || true` — only if biome available; not blocking
- Visual sanity: `tree .claude/skills/prototype/templates/pipeline/` shows 15 dirs (no 07-prototype-v2, presence of 06-ost / 07-sitemap-ia / 12-gtm-launch / 15-screen-atlas)

### Batch 7 — Steward redogfood (acceptance gate E)

- Run `/prototype "Claude Code governance dashboard" --stack=next --out=/tmp/dogfood-v3` in fresh session (cold-cache wall-time signal + isolation from this session's context)
- Compare against `/tmp/dogfood-v2/` (Pass E baseline): specifically the sitemap.yaml route inventory + screen-atlas coverage matrix
- Acceptance: NEW screens auth/admin/error categories emerge (Pass E silent gaps now covered explicitly)
- Document outcome in `docs/specs/045-prototype-skill-pipeline-realign/artifacts/redogfood-comparison.md`

## Alternatives considered + rejected

- **Parent + 6 children (mirror spec 032's shape).** Rejected per Q1: skill is ~50 files vs MCP's hundreds; 6 children would all touch SKILL.md + delegation-briefs.md → merge conflicts between siblings; spec 036 shipped as single-spec without children and worked fine; total scope (~3 weeks) doesn't justify decomposition overhead.
- **Wait for spec 032 to ship + re-sync via REMINDERS.** Rejected per Q6: skill stays on old shape for 5-6 weeks (no users complaining yet, but no benefit to delay); scout-pattern (ship 045 first → de-risk 032) loses its value if 032 ships first; 045 is decoupled from 032's calendar by design (skill is standalone, no MCP runtime dep per spec 036).
- **Defer cost↔roadmap swap.** Rejected per Q3: free win (~30 min of edits); already adjacent to other Specification-phase reorderings; if not now, becomes niggling open question forever.
- **Bundle post-launch-review skill alongside.** Rejected per Q4: needs persistence (MCP `POST_LAUNCH_ACTIONS` array per spec 032 Decision 11), can't ship standalone; separate spec when MCP backend lands.
- **Fresh redogfood case (ERP salões).** Rejected per Q7: Steward gives perfect A/B comparator (Pass E artifacts intact); the specific bug (sitemap silent undercoverage) is exactly what Steward demonstrated; fresh case would test MORE concerns but dilutes the targeted validation. Fresh case waits for full-stack expansion spec.

## Risks + mitigations

1. **Batch 1's SKILL.md rewrite is the highest-blast-radius edit.** SKILL.md is the orchestration body; a malformed section breaks every subsequent `/prototype` invocation. **Mitigation:** edit in surgical sections (parse old Phase 1, write new Phase 1, validate intermediary state via grep before moving to Phase 2); run `bash .claude/skills/skill/scripts/validate.sh` after every Batch 1 file to catch breakage early.

2. **delegation-briefs.md is the largest file (~370 lines). Rewriting 15 briefs in new order risks copy-paste errors (wrong CONTEXT references, swapped DELIVERABLE paths).** **Mitigation:** use a single Write that completely replaces the file from scratch (not incremental Edits) — fewer chances for partial-state failures; reference the new STEPS table in pipeline-coverage.md as the source of truth for ordering.

3. **Template renames (Batch 3) confuse git diff history.** Slug rename `prototype-v3` → `screen-atlas` and step number 13 → 15 means the file appears as delete+create instead of rename. **Mitigation:** use `git mv` for the directory rename so git history tracks it as rename (not delete+add); preserve the deleted-step-7 content as tombstone file in `docs/specs/045-*/artifacts/`.

4. **State.json v3 schema break for in-flight prototypes.** If a fork has a paused `/prototype` run at v2 schema, post-045 invocations with `--from-step=NN` will abort. **Mitigation:** acceptance criterion C scenario explicitly tests this; abort message gives clear actionable: "state v2 found — pre-spec-045 run; clear --out dir or run fresh".

5. **Sitemap schema enforcement blocking Step 07 may surprise founders mid-run.** If founder declares an "internal-only ERP" with no marketing/auth, schema would block. **Mitigation:** the `deferred-out-of-v1` escape clause per category is explicit + must include `reason`; founder can always opt out per category, just must do so consciously (which is the point — silent gaps were the bug).

6. **Steward redogfood (Batch 7) requires a fresh CC session for cold-cache + isolation.** Cannot complete in this session's turn. **Mitigation:** Batches 1-6 complete in this session; Batch 7 queued as first SESSION.md WIP for next session; `/goal` hook expectation: substantive progress means Batches 1-6 ship + Batch 7 is set up to launch immediately next time.

## Estimated effort

- Batch 1 — Structural reshape: ~45-60 min (4 files, heavy editing)
- Batch 2 — Sitemap schema: ~10 min (1 file, additive)
- Batch 3 — Deletions + renames: ~15 min (rm + git mv + write tombstone)
- Batch 4 — New step templates: ~30 min (3 new dirs, prompt.md + schema.md each)
- Batch 5 — Existing template reshape: ~30 min (5 files, surgical edits)
- Batch 6 — Validate: ~5 min (1 command + visual sanity)
- Batch 7 — Steward redogfood: ~2-3 hours wall-time (separate session)

**Total this session (Batches 1-6):** ~2.5-3 hours wall-time, ~150-200 tool calls.

## Acceptance gate

Static facts (acceptance § A, C, D) verified by grep + skill-validate immediately after Batch 6. Scenario-shape acceptance (§ B, E) verified by Batch 7's Steward redogfood (next session). Spec status flips `in-progress → shipped` when E.scenario "silent-undercover bug fixed via sitemap-IA" passes — that's the load-bearing acceptance gate. Until then, spec stays `in-progress` even if Batches 1-6 complete cleanly.
