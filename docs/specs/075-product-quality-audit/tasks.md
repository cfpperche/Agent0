# 075 — product-quality-audit — tasks

_Generated from `plan.md` on 2026-05-22. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Move 1 — retire the size ceiling

- [x] 1. Rewrite `.claude/rules/artifact-budgets.md` — cascade removed; rewritten around the uniform 200 KB catastrophe cap; "scope proxy" framing dropped; `# OVERRIDE: budget-exempt:` kept, now scoped to the cap. Also updated `CLAUDE.md` § (the cascade summary there would otherwise be stale — see `notes.md`).
- [x] 2. Schema sweep — **only 6 of 15 schemas carried `max_size`** (02/03/08/09/10/15); the `## Target` sections became `## Size floor` (anti-stub framing), `max_size` removed from tables + Layer 1 JSON; every `min_size` floor intact. `grep` confirms zero residual `max_size`. See `notes.md`.
- [x] 3. In `references/delegation-briefs.md` — **full ceiling scrub** (extended from the literal task per the 2026-05-22 scope decision; see `notes.md` § Deviations): (a) stripped the "Overshoot cascade" boilerplate from all 17 brief blocks (15 standard + Step 09 `effective_max` + Step 14 per-file `file_max`) → one-line uniform-200-KB catastrophe-cap note; (b) retargeted the 6 stale `schema.md § Target` pointers (Steps 02/03/08/09/10/15a) → `§ Size floor`; (c) replaced the ~10 inline "X-Y KB hard ceiling" lines → `≥ N KB` anti-stub floors; (d) rewrote every `DONE_WHEN` size clause from a range → floor-only check. `grep` confirms zero residual `Overshoot cascade` / `× 1.2` / `× 1.8` / `§ Target` / `hard ceiling` / `Size budget` / `size within` / `N-N KB`. Two `size targets` cross-pointers into `pipeline-coverage.md` (brief CONTEXT line + cross-ref line) deferred to task 4, which owns that file.
- [x] 4. Updated `references/pipeline-coverage.md` — the "Overshoot cascade" section → two paragraphs (the uniform 200 KB catastrophe cap + "right-sizing is judged, not measured" pointing at `references/quality-judge.md`); section retitled `Per-step output + size floors`; the per-step table's `Size target` column → `Size floor (anti-stub)` with `≥ N KB` floors; the 6 `§ Target` source cells retargeted → `§ Size floor`; the legend + the two `Lightening op` ceiling mentions (Steps 01, 05) scrubbed. `grep` confirms no `size budget` / `size target` / `§ Target` / `budget-exempt` residue (the lone `1.2`/`1.8`/`overshoot` hit is the deliberate retirement-explanation prose). The two `delegation-briefs.md` pointers into the renamed section were updated to match.

### Move 2 — add the quality judge

- [x] 5. Decide + document the verdict JSON shape (per-criterion `pass`/`concern`/`fail` + scope assessment) and the `.state.json` `quality_verdicts` field. Resolve the **v5-additive vs v6-bump** question (per `plan.md` § Risks) and record the decision in `notes.md`. — **Done:** verdict shape + `quality_verdicts` map decided; **v5-additive, no v6 bump**. See `notes.md` § Design decisions.
- [x] 6. Audit `references/quality-checklist.md`; reposition it as the judge's rubric contract — restructure if needed so per-step criteria are cleanly assemble-able into a rubric (the `plan.md` unknown). — **Done:** full restructure (the `plan.md` Risk #54 outcome). Each step's mashed prose cell split into named `id`-bearing criteria; retired size ranges + the stale `§ Target` pointer scrubbed; judge-graded semantic criteria separated from deterministic orchestrator gates; header reframed to "judge's rubric contract". 3 cross-ref one-liners (pipeline-coverage/state-machine/delegation-briefs) updated to match.
- [x] 7. Write `references/quality-judge.md` — rubric assembly per step (from `schema.md` + `quality-checklist.md` + the right-sizing criterion), the verdict shape from task 5, and the `advisory` / `gate-flag` routing rule tied to the `state-machine.md` failure taxonomy. — **Done:** created. Covers what/when/judge-units/rubric-assembly/right-sizing criterion text/verdict/routing/never-does/cost. Routing is the global rule (`concern`=advisory, `fail`=gate-flag), with the phase→gate table + the judge-`fail`≠BLOCKED distinction.
- [ ] 8. Add the § quality-judge brief to `references/delegation-briefs.md` — 5-field handoff; `model: opus`; pointwise chain-of-thought; the right-sizing criterion carrying the explicit **anti-verbosity** instruction (do not reward length).
- [ ] 9. Wire `SKILL.md` — after each step: run the `wc -c` anti-stub pre-filter (skip the judge on a stub), dispatch the judge sub-agent, record the verdict; route a `fail` → pre-populate the next phase gate's `iterate` recommendation, or in gate-less Phase 4 → terminal handoff flag.
- [ ] 10. Update `references/state-machine.md` — add the judge to the phase progression; add the `quality_verdicts` field to the `.state.json` shape (per task 5); document the verdict→gate routing.
- [ ] 11. Add a `## Quality concerns` section to `templates/report.md.tmpl` (spec 073's `build-report.ts` renders it automatically).

## Verification

_Maps to `spec.md` § Acceptance criteria._

- [ ] 12. `grep` all 15 `schema.md` — confirm no stale `max_size` scope-ceiling remains and every `min_size` floor is intact; confirm `artifact-budgets.md` no longer contains the `1.2`/`1.8` cascade. (criteria: cascade removed, `max_size` removed/raised, floors retained)
- [ ] 13. Confirm the static facts by inspection: the § quality-judge brief exists and dispatches a separate `opus` sub-agent; the rubric is sourced from `schema.md` + `quality-checklist.md` (no new rubric authored); the right-sizing criterion carries the anti-verbosity instruction; the judge has no autonomous hard-BLOCK path. (criteria: brief exists, rubric source, anti-length, never-hard-BLOCK, opus)
- [ ] 14. Dogfood-validate against a real `/product` run (or a representative slice): judge dispatched per step; a correctly-scoped large artifact passes right-sizing (no false positive — the core regression the spec exists to kill); a genuinely bloated section is flagged by dimension; a `fail` pre-populates a phase gate's `iterate` and, in Phase 4, the handoff; the anti-stub pre-filter short-circuits a stub; the catastrophe cap circuit-breaks a runaway. Confirm no new trim-loop/runaway pattern emerged from removing the cascade. (criteria: all 6 behavioral scenarios)

## Notes

_Populated during execution — see `notes.md` for in-flight design decisions. Record here: the 15 schema files swept (task 2), the v5/v6 decision (task 5), and any `quality-checklist.md` restructuring (task 6)._

- **task 2** — only 6 of 15 schemas carried `max_size` (02/03/08/09/10/15); all swept. See `notes.md` § Deviations.
- **task 5 (2026-05-22)** — verdict JSON shape + `.state.json` `quality_verdicts` map decided. **v5-additive, NO v6 bump** — the resume gate is strict refuse-all-non-5 with no field migration, and an additive ignore-if-absent field carries no mis-orchestration risk (the practiced bump-rule, per the v4→v5 precedent). Task 10 will reword `state-machine.md` line 48's bump-rule. Full reasoning in `notes.md` § Design decisions.
- **task 6 (2026-05-22)** — `quality-checklist.md` got a **full restructure** (plan.md Risk #54 — "real restructuring, not just repositioning"): mashed per-step prose cells → named `id`-bearing criteria; retired size ranges scrubbed (Move-1 residue this file still carried); judge-graded semantic criteria split from deterministic orchestrator gates. The criterion `id`s become `verdict.criteria[].id`. No new criteria authored — existing clauses split + named only (spec.md "no new rubric").
