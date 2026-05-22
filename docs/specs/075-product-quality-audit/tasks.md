# 075 — product-quality-audit — tasks

_Generated from `plan.md` on 2026-05-22. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Move 1 — retire the size ceiling

- [ ] 1. Rewrite `.claude/rules/artifact-budgets.md` — remove the `max × 1.2` / `max × 1.8` overshoot cascade; rewrite the rule around the single uniform catastrophe byte cap (≈200 KB, finalize the exact value here); drop the "scope proxy" framing. Decide and document the fate of the `# OVERRIDE: budget-exempt:` grammar (retire, or keep for the catastrophe cap).
- [ ] 2. Sweep all 15 `.claude/skills/product/templates/pipeline/*/schema.md` — remove or raise `max_size` in the Layer 1 JSON block + the `## Target` table; **keep every `min_size` floor untouched.** List the 15 files touched in `notes.md`.
- [ ] 3. In `references/delegation-briefs.md` — strip the per-step "Overshoot cascade per artifact-budgets.md" boilerplate from all 15 step briefs + the § Mood-screen-writer brief; replace with the one-line catastrophe-cap note.
- [ ] 4. Update `references/pipeline-coverage.md` — rewrite the "Overshoot cascade" section as the catastrophe cap + a pointer to the new quality-judge step.

### Move 2 — add the quality judge

- [ ] 5. Decide + document the verdict JSON shape (per-criterion `pass`/`concern`/`fail` + scope assessment) and the `.state.json` `quality_verdicts` field. Resolve the **v5-additive vs v6-bump** question (per `plan.md` § Risks) and record the decision in `notes.md`.
- [ ] 6. Audit `references/quality-checklist.md`; reposition it as the judge's rubric contract — restructure if needed so per-step criteria are cleanly assemble-able into a rubric (the `plan.md` unknown).
- [ ] 7. Write `references/quality-judge.md` — rubric assembly per step (from `schema.md` + `quality-checklist.md` + the right-sizing criterion), the verdict shape from task 5, and the `advisory` / `gate-flag` routing rule tied to the `state-machine.md` failure taxonomy.
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
