# 032 — pipeline-industry-alignment — tasks

_Generated from `plan.md` on 2026-05-17. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

_This is a **parent spec** — its tasks are mostly to scaffold + dispatch + monitor child specs, not to write code. Code lands in child specs 037-044. The parent ships when all 8 children ship AND the redogfood validation (scenario C in spec.md) passes._

## Implementation

### Phase 0 — Parent spec preflight

- [x] 1. **Lock the 17 shape decisions** in `spec.md` § Acceptance criteria § A (10 initial + 7 from Q1-Q7 resolution).
- [x] 2. **Capture the 48-source research** in `research-report.md` (already done).
- [x] 3. **Draft `plan.md` with child-spec dispatch table + alternatives + risks** (already done).
- [x] 4. **Resolve all 7 open questions before dispatching child specs.** Done 2026-05-17 in item-by-item discussion. Decisions 11-17 in spec.md § Acceptance criteria § A. Resolutions:
  - [x] Q1 → Decision 11 (c) sibling-not-step
  - [x] Q2 → Decision 12 (b) OST own linear step
  - [x] Q3 → Decision 13 (c) structured YAML w/ schema
  - [x] Q4 → Decision 14 (a) step 7 dies + slug rename → `screen-atlas`
  - [x] Q5 → Decision 15 (c) hybrid Lenny bones + 3 sections
  - [x] Q6 → Decision 16 (a) hard cutover, version 0.1.0 → 0.2.0
  - [x] Q7 → Decision 17 (c) verbatim + gap-audit + fresh dogfood
- [x] 5. **Flip spec 032 Status `draft → in-progress`** — done 2026-05-17.

### Phase 1 — Dispatch child specs (sequential by dependency)

- [ ] 6. **Dispatch child spec 037 — pipeline-structural-refactor.** Use `/sdd new pipeline-structural-refactor`; fill its spec.md from the dispatch row in this plan + Q1 + Q6 resolutions; this is the foundation, blocking everything else.
- [ ] 7. **Wait for 037 to ship** (status `shipped`) before dispatching 038. Verify: `pipeline.ts` STEPS array matches the new shape, `bun test` 120+ pass, validator clean.
- [ ] 8. **Dispatch child spec 038 — prd-1pager-ost.** Implements Camp C; resolves spec.md Q2 (OST embedded vs own step) and Q5 (Lenny adapt vs net-new) inside the child.
- [ ] 9. **Wait for 038 to ship** before dispatching 039 (sitemap depends on PRD/OST output format).

### Phase 2 — Dispatch remaining template children (parallelizable)

- [ ] 10. **Dispatch in parallel: 039 (sitemap), 040 (legal), 041 (GTM), 042 (extensions), 043 (post-launch-review).**
  - 039 resolves spec.md Q3 (sitemap output format) in its plan.md
  - 043 inherits Q1 (numbering) decision from this parent
  - Each child runs its own port→dogfood→judge→calibrate loop per `.claude/memory/anthill-port-workflow.md`
- [ ] 11. **Track child-spec status weekly.** Use `/sdd list --in-flight` to see active child specs. Mark blockers in this tasks.md § Notes.
- [ ] 12. **Resolve calibration carryover per template (Phase B preservation).** For each Phase B-calibrated template that survives reshape (steps 5 brand, 6 design-system, 11 roadmap, 13 atlas), verify the child spec touching it preserves the calibrated literal-anchors. Step 7 (prototype-v2) tombstone goes into `docs/specs/037-*/artifacts/`.

### Phase 3 — End-to-end redogfood (child spec 044)

- [ ] 13. **All of 037-043 must be shipped** (Status `shipped`) before 044 starts.
- [ ] 14. **Dispatch child spec 044 — redogfood-octant-validation.** Per spec.md Q7 decision: walk the new pipeline 1→end on Octant brief (verbatim or revised per Q7) in `/tmp/bench/032-redogfood-octant/`.
- [ ] 15. **Capture redogfood evidence**: full output tree under `docs/specs/044-*/dogfood/` with the new screen atlas demonstrating auth set + error/empty/404 + team-management + issue-creation + billing surfaces.

## Verification

_Each maps to spec.md § Acceptance criteria._

- [ ] **A.1-A.17 (the 17 shape decisions)** — verified by inspection of child-spec implementations:
  - A.1 Camp C (PRD hybrid) → 038 ships PRD-1pager + OST
  - A.2 Option 3 (post-launch loop) → 037 + 043 ship sibling infra + template
  - A.3 PRD-first → 037 ships reordered STEPS array
  - A.4 Legal shift-left → 040 ships repositioned legal template (depends on 042 system-design data-flow)
  - A.5 Sitemap step own → 039 ships
  - A.6 Discovery folds (market + interviews) → 042 ships extensions to step 1 + step 3
  - A.7 GTM step → 041 ships
  - A.8 Prototype collapse → 037 ships step-7 deletion + tombstone
  - A.9 NSM in PRD → 038 ships NSM bullet in PRD-1pager template
  - A.10 RACI in system-design → 042 ships extensions to step 8 (was 9)
  - A.11 sibling-not-step → 037 ships POST_LAUNCH_ACTIONS array + MCP tools
  - A.12 OST own linear step → 037 ships STEPS array slot + 038 ships template
  - A.13 sitemap YAML schema → 039 ships YAML schema + required_categories
  - A.14 prototype-v2 collapse mechanics + rename → 037 ships delete + rename `prototype-v3` → `screen-atlas`
  - A.15 PRD hybrid Lenny + 3 our sections → 038 ships template
  - A.16 hard cutover, 0.1.0→0.2.0 + MIGRATION-NOTES → 037 ships version bump + MIGRATION-NOTES.md
  - A.17 verbatim brief + gap-audit + fresh dogfood → 044 ships
- [ ] **B (decomposition)** — verified by this plan.md + tasks.md existing with the 8-child dispatch table.
- [ ] **C.1 (redogfood resolves atlas under-cover)** — verified by 044 child spec output: the atlas inventory includes auth/error/admin/CRUD-creation/billing surfaces; sitemap-coverage metric ≥95%.
- [ ] **C.2 (post-launch-review re-runnable + updates OST)** — verified by 043 child spec acceptance test: run step N=2 times in a row on a fixture, confirm versioned `review-NN.md` artifacts and OST diff persists.
- [ ] **Static fact** — `docs/specs/032-pipeline-industry-alignment/research-report.md` exists with 48 sources (already done).
- [ ] **Final step** — flip spec 032 Status from `in-progress` to `shipped` once all 8 children are shipped and C.1 + C.2 pass.

## Notes

_Capture cross-cutting decisions resolved during execution here._

### Q1-Q7 resolution audit trail (2026-05-17 item-by-item discussion)

| Q | Original framing | Founder decision | Folded into |
|---|---|---|---|
| Q1 | post-launch step numbering — (a) step 14 linear / (b) 14R suffix / (c) sibling-not-step / (d) step 14 + repeatable mode | **(c) sibling-not-step** | Decision 11 |
| Q2 | OST placement — (a) embedded in PRD / (b) own linear step / (c) sibling-not-step | **(b) own linear step** | Decision 12 |
| Q3 | sitemap output format — (a) markdown / (b) tree visual / (c) structured YAML / (d) hybrid md+yaml | **(c) structured YAML w/ schema-enforced required_categories** | Decision 13 |
| Q4 | prototype-v2 collapse mechanics — (a) step 7 dies + step 13 absorbs / (b) step 13 dies + step 7 absorbs / (c) both die + new merged | **(a) step 7 dies + rename slug → screen-atlas** | Decision 14 |
| Q5 | PRD-1pager template — (a) Lenny verbatim / (b) net-new / (c) hybrid | **(c) hybrid Lenny bones + 3 our sections** | Decision 15 |
| Q6 | back-compat with forks — (a) hard cutover / (b) deprecation phase / (c) pipelineVersion field | **(a) hard cutover, 0.1.0 → 0.2.0 + MIGRATION-NOTES.md** | Decision 16 |
| Q7 | redogfood brief — (a) verbatim / (b) revised / (c) verbatim + gap-audit + fresh dogfood end-to-end | **(c) + dogfood completo do zero, 026 atlas como comparator-where-applicable** | Decision 17 |

Item-by-item context: each Q had its own prós × contras table (4-5 cols typical), diagnostic with founder feedback memory references (`feedback_anthill_port_smart_not_rigid`, `feedback_mcp_package_self_contained`, `feedback_agent0_changes_ship_via_rules_not_memory`), and explicit tradeoff statement. Founder responses were concise picks ("C", "B", "A com rename pra screen-atlas"). Q6 also surfaced the factual context "todos projetos citados como forks sao efemeros e usados para dogfood do projeto" — preserved separately in `.claude/memory/forks-ephemeral-dogfood.md`.

### Child-spec status tracker (updated weekly)

| NNN | Slug | Status | Notes |
|---|---|---|---|
| 037 | pipeline-structural-refactor | not started | foundation |
| 038 | prd-1pager-ost | not started | depends on 037 |
| 039 | sitemap-ia-step | not started | depends on 037 + 038 |
| 040 | legal-shift-left | not started | depends on 037 |
| 041 | gtm-launch-step | not started | depends on 037 |
| 042 | discovery-systemdesign-extensions | not started | depends on 037 |
| 043 | post-launch-review-step | not started | depends on 037 |
| 044 | redogfood-octant-validation | not started | depends on 037-043 |

### Carry-over from this conversation

- Decisions 1-3 locked via item-by-item discussion 2026-05-17 (Camp C / Option 3 / Option 2). Decisions 4-10 proposed by Claude with research citations; founder said "luz verde" to proceed. If founder pushes back on any of 4-10 during plan/tasks review, update spec.md § Acceptance criteria § A and re-cascade to plan.md dispatch table.
