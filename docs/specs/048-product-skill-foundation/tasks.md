# 048 — product-skill-foundation — tasks

_Generated from `plan.md` 2026-05-18. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Batch A — Scaffold spec 048

- [x] 1. Resolve numbering conflict (046 + 047 taken by sibling sessions → use 048).
- [x] 2. Create `docs/specs/048-product-skill-foundation/` directory.
- [x] 3. Write `spec.md` with 5 acceptance criteria sections (A rename / B layout / C state-machine / D compliance / E dogfood) + non-goals + 4 ratified open questions + dependencies + lineage.
- [x] 4. Write `plan.md` with files-to-touch matrix + 5 alternatives considered + 6 risks + 5-batch execution table.
- [x] 5. Write `tasks.md` (this file).
- [x] 6. Status `in-progress` declared in spec.md (executing, not just planning).

## Batch B — Rename `/prototype` → `/product`

- [ ] 7. `git mv .claude/skills/prototype .claude/skills/product` (single git operation).
- [ ] 8. Edit `.claude/skills/product/SKILL.md` frontmatter:
  - `name: prototype` → `name: product`
  - `description: ...` reframe (foundation generator + design partner for product lifecycle, NOT agile frontend / throwaway prototype); keep ≤1024 chars per spec 033
  - `metadata.skill-version: 0.2.0` → `metadata.skill-version: 0.3.0`
- [ ] 9. Find/replace literal `/prototype` → `/product` in all `.claude/skills/product/` files (SKILL.md, references/*.md, templates/pipeline/*/prompt.md, templates/pipeline/*/references/*.md, templates/pipeline/*/schema.md) — DISTINGUISH between slash-command refs (`/prototype` skill invocation — rename) vs semantic refs ("lo-fi prototype" as design artifact — keep).
- [ ] 10. Edit `CLAUDE.md` — `## Prototype skill` heading → `## Product skill`; reframe paragraph (foundation generator + design partner; lifecycle-aware; spec 048 reference instead of 036+045).
- [ ] 11. Edit `docs/specs/045-prototype-skill-pipeline-realign/spec.md` § Lineage — append note "skill renamed to /product per spec 048 (2026-05-18)".
- [ ] 12. Run sanity grep: `grep -rn '/prototype' .claude/skills/product/ CLAUDE.md` — confirm zero remaining slash-command refs (semantic "prototype" matches are OK).

## Batch C — Layout refactor (drop NN- prefix, semantic paths, state.json v4)

- [ ] 13. Edit `.claude/skills/product/SKILL.md`:
  - Phase 0 mkdir: `<out>/docs/02-screens` → `<out>/docs/screens`
  - Phase 0 state.json: `version: 3` → `version: 4`
  - Phase 1 dispatch references — update DELIVERABLE paths per spec.md § B mapping
  - Phase 2 dispatch references — same
  - Phase 3 dispatch references — same (Step 13 → `docs/brand-book.md`; Step 14 → `docs/design-system/{tokens.css, components.md, README.md}`)
  - Phase 4 dispatch references — Step 15 atlas → `docs/screen-atlas.md`; per-route screen writers unchanged (still `app/<route>/page.tsx`)
  - Phase 4 stitch regex: `grep -qE '^@import.*docs/.*tokens\.css'` → `grep -qE '^@import.*docs/design-system/tokens\.css'`
  - Phase 4 stitch sed fallback: `sed -i '1i @import "../docs/14-tokens.css";'` → `sed -i '1i @import "../docs/design-system/tokens.css";'`
  - Phase 5 handoff message — update artifact paths shown to founder
- [ ] 14. Edit `.claude/skills/product/references/delegation-briefs.md` — 16 briefs (15 step + 1 per-stack screen-writer):
  - Step 01 — DELIVERABLE: `docs/concept-brief.md` + DONE_WHEN path check
  - Step 02 — DELIVERABLE: `docs/direction-a.html` + `docs/screens/` + DONE_WHEN
  - Step 03 — DELIVERABLE: `docs/functional-spec.md`; CONTEXT: read `concept-brief.md` + `direction-a.html` + `screens/`
  - Step 04 — DELIVERABLE: `docs/validation-report.md`; CONTEXT: read `direction-a.html` + `screens/`
  - Step 05 — DELIVERABLE: `docs/prd/v1.md` (subfolder!); CONTEXT: `concept-brief.md` + `functional-spec.md` + `validation-report.md` + `direction-a.html` + `screens/`
  - Step 06 — DELIVERABLE: `docs/ost.md`; CONTEXT: `prd/v1.md` + `functional-spec.md` + `concept-brief.md`
  - Step 07 — DELIVERABLE: `docs/sitemap.yaml`; CONTEXT: `prd/v1.md` + `functional-spec.md` + `concept-brief.md`
  - Step 08 — DELIVERABLE: `docs/system-design.md` + `docs/security.md` + `docs/data-flow.json`; CONTEXT: `prd/v1.md` + `sitemap.yaml` + `functional-spec.md` + `concept-brief.md`
  - Step 09 — DELIVERABLE: `docs/legal-posture.md`; CONTEXT: `prd/v1.md` + `system-design.md` + `data-flow.json` + `concept-brief.md`
  - Step 10 — DELIVERABLE: `docs/roadmap.md`; CONTEXT: `prd/v1.md` + `system-design.md` + `concept-brief.md` + `validation-report.md`
  - Step 11 — DELIVERABLE: `docs/cost-estimate.md`; CONTEXT: `roadmap.md` + `system-design.md` + `legal-posture.md` + `prd/v1.md`
  - Step 12 — DELIVERABLE: `docs/gtm-launch.md`; CONTEXT: `prd/v1.md` + `concept-brief.md` + `roadmap.md` + `legal-posture.md`
  - Step 13 — DELIVERABLE: `docs/brand-book.md`; CONTEXT: `prd/v1.md` + `gtm-launch.md` + `concept-brief.md` + `direction-a.html`
  - Step 14 — DELIVERABLE: 3 files at `docs/design-system/` (`tokens.css` + `components.md` + `README.md`); CONTEXT: `brand-book.md` + `sitemap.yaml` + `concept-brief.md` + `validation-report.md`
  - Step 15 — DELIVERABLE: `docs/screen-atlas.md`; CONTEXT: enumerate all 16 prior artifact paths under `docs/` (new names)
  - Per-stack screen-writer — sitemap entry source: `docs/sitemap.yaml`; tokens (Step 15): `docs/design-system/tokens.css`; voice (Step 15): `docs/brand-book.md`; components reference (Step 15): `docs/design-system/components.md`; Step 02 lo-fi screen target: `docs/screens/<name>.html`
- [ ] 15. Edit `.claude/skills/product/references/pipeline-coverage.md` — STEPS table paths column updated to new names.
- [ ] 16. Edit `.claude/skills/product/references/state-machine.md`:
  - `.state.json` v4 shape declared
  - Migration discipline: v3→v4 is BREAKING (no auto-migration); orchestrator aborts with `state v3 found — pre-spec-048 run; clear --out dir or run fresh /product`
- [ ] 17. Edit `.claude/skills/product/references/sitemap-schema.md` — own path reference to `docs/sitemap.yaml`.
- [ ] 18. Edit `.claude/skills/product/templates/pipeline/01-ideation/prompt.md` — output path `docs/01-concept-brief.md` → `docs/concept-brief.md`.
- [ ] 19. Edit `.claude/skills/product/templates/pipeline/02-prototype/prompt.md` — output paths updated.
- [ ] 20. Edit `.claude/skills/product/templates/pipeline/03-spec/prompt.md` — output path updated; any CONTEXT path refs.
- [ ] 21. Edit `.claude/skills/product/templates/pipeline/04-ux-testing/prompt.md` — output path updated.
- [ ] 22. Edit `.claude/skills/product/templates/pipeline/05-prd/prompt.md` — output path `docs/05-prd.md` → `docs/prd/v1.md`.
- [ ] 23. Edit `.claude/skills/product/templates/pipeline/06-ost/prompt.md` — output path updated.
- [ ] 24. Edit `.claude/skills/product/templates/pipeline/07-sitemap-ia/prompt.md` — output path updated.
- [ ] 25. Edit `.claude/skills/product/templates/pipeline/08-system-design/prompt.md` — 3 output paths updated.
- [ ] 26. Edit `.claude/skills/product/templates/pipeline/09-legal/prompt.md` — output path + CONTEXT to `data-flow.json` updated.
- [ ] 27. Edit `.claude/skills/product/templates/pipeline/10-roadmap/prompt.md` — output path updated.
- [ ] 28. Edit `.claude/skills/product/templates/pipeline/11-cost-estimate/prompt.md` — output path + CONTEXT to `roadmap.md` updated.
- [ ] 29. Edit `.claude/skills/product/templates/pipeline/12-gtm-launch/prompt.md` — output path updated.
- [ ] 30. Edit `.claude/skills/product/templates/pipeline/13-brand/prompt.md` — output path updated.
- [ ] 31. Edit `.claude/skills/product/templates/pipeline/14-design-system/prompt.md` — 3 output paths into `design-system/` subfolder; `14-design-system.md` becomes `design-system/README.md`.
- [ ] 32. Edit `.claude/skills/product/templates/pipeline/15-screen-atlas/prompt.md` — output path + CONTEXT enumeration of all 17 input artifact paths + Sitemap Coverage Cross-Check path computation.
- [ ] 33. Edit `.claude/skills/product/templates/monorepo-skeleton/next/app/globals.css` — `@import "../docs/14-tokens.css"` → `@import "../docs/design-system/tokens.css"` (THIRD update; verify via grep after).
- [ ] 34. Edit `.claude/skills/product/templates/report.md.tmpl` if it exists — update artifact path placeholders.
- [ ] 35. Grep sanity check: `grep -rn 'docs/0[0-9]-' .claude/skills/product/` returns zero results (all NN- prefixes removed); `grep -rn 'docs/1[0-5]-' .claude/skills/product/` returns zero results.

## Batch D — Dogfood "ERP para salões de beleza"

- [ ] 36. Preflight: verify `/tmp/dogfood-erp` does not exist (clean cold-cache slot).
- [ ] 37. Phase 0: mkdir + state.json v4 init for `/tmp/dogfood-erp/`.
- [ ] 38. Phase 1 Discovery — Step 01 (opus, BLOCKING); Step 02 (sonnet); Steps 03+04 parallel (sonnet). Gate 1 auto-continue.
- [ ] 39. Phase 2 Specification — Step 05 (BLOCKING); Steps 06+07 parallel; Step 07 sitemap schema check; Steps 08-09-10 sequential; Steps 11+12 parallel. Gate 2 auto-continue.
- [ ] 40. Phase 3 Identity — Step 13 → Step 14. Gate 3 auto-continue. Parent-side biome cleanup before Phase 4.
- [ ] 41. Phase 4 Visual contract — copy Next.js skeleton; Step 15a atlas writer; Step 15b per-route screen writers (cap=5, ~4 batches per sitemap size).
- [ ] 42. Stitch step: verify globals.css imports `docs/design-system/tokens.css` correctly.
- [ ] 43. Build verification: `cd /tmp/dogfood-erp && node_modules/.bin/tsc --noEmit` exit 0 + `node_modules/.bin/biome check .` exit 0.
- [ ] 44. Write `/tmp/dogfood-erp/docs/REPORT.md` with: pipeline coverage / sitemap coverage / build health / A/B vs `/tmp/dogfood-v3` (Audity NN-flat) / findings / open decisions.
- [ ] 45. Verify layout discipline: zero files with `NN-` prefix at `/tmp/dogfood-erp/docs/`; `prd/v1.md` + `design-system/` subfolders present.

## Batch E — Validator + ship

- [ ] 46. Run `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` — exit 0 required.
- [ ] 47. Verify SKILL.md description ≤1024 chars (spec 033 compliance).
- [ ] 48. Update SESSION.md to reflect spec 048 SHIPPED + spec 049 candidate queued.
- [ ] 49. Update `.claude/REMINDERS.md` — dismiss obsolete prototype-template-diff item if appropriate; add `spec-049 — product-skill-vN-mode` candidate item (post-launch evolution primitives gap).
- [ ] 50. Flip spec 048 status: `in-progress → shipped` in spec.md.
- [ ] 51. Commit all spec 048 work. Suggested message:
  ```
  feat(048): /product skill foundation — rename + production-shaped layout

  - rename /prototype → /product (semantic reframe: foundation generator + design partner for product lifecycle, not throwaway prototype). Skill v0.2.0 → v0.3.0.
  - layout refactor: drop NN- prefix, emit semantic-named artifacts. PRD release-scoped via prd/v1.md subfolder from day 1. Design system grouped in design-system/. Other artifacts flat top-level.
  - state.json version 4 (breaking; refuses silent v3 upgrade).
  - skeleton globals.css token path: docs/design-system/tokens.css (3rd update — caught + fixed each time).
  - dogfood: /tmp/dogfood-erp/ (ERP para salões de beleza) cold-cache full 15-step, tsc+biome PASS, new layout validated end-to-end.

  MCP discontinuation cascade is out of scope (handled in MCP-session). spec 049 (product-skill-vN-mode, post-launch evolution primitives) queued as logical next step.
  ```

## Notes

- **Goal directive:** `/goal confirmo tudo, pode implementar e validar o plano` 2026-05-18 — Stop hook active; cannot end session until spec 048 shipped + dogfood passed + commit made.
- **Slug renumbering rationale (task 1):** plan proposed 046; on dir creation discovered 046-sdd-in-flight-notes + 047-php-laravel-support already exist from sibling sessions. Bumped to 048 to avoid conflict. Spec.md § Open questions Q1 records the renumber.
- **Sub-agent oversize discipline carries over from spec 045 findings:** Phase 1 (Steps 03/04) + Phase 3 (Step 14 ×3) blew ceilings 2-4x in spec 045 dogfood due to schema/ceiling mismatch. For this dogfood, accept the same overshoots as long as the LAYOUT (paths + subfolders) is correct — this spec is about layout + naming, not ceiling recalibration. Spec 050 candidate: ceiling vs schema reconciliation.
