# 075 — product-quality-audit — plan

_Drafted from `spec.md` on 2026-05-22. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two moves: **retire the ceiling instrument**, then **add the judge layer**. They are separable and the retirement is the lower-risk half, so do it first.

**Move 1 — retire the size ceiling (subtractive, deterministic).** Strip the `max × 1.2 / max × 1.8` overshoot cascade from `artifact-budgets.md` and rewrite the rule around a single uniform catastrophe byte cap (≈200 KB). Remove or raise the `max_size` ceilings in all 15 step `schema.md` files — **keep every `min_size` anti-stub floor untouched**. Strip the per-brief "Overshoot cascade per artifact-budgets.md" boilerplate from the 15 briefs + the mood-screen-writer brief, replacing it with the one-line catastrophe-cap note. This move alone removes the false-positive instrument the mei-saas dogfood exposed.

**Move 2 — add the quality judge (additive).** A new `delegation-briefs.md` § quality-judge brief: a pointwise, chain-of-thought (G-Eval style) evaluation dispatched as a separate `opus` sub-agent after each step. Its rubric is *assembled* from the step's existing `schema.md` (required sections + `contains`-anchors) + `quality-checklist.md` criteria + one explicit **right-sizing criterion** carrying the anti-verbosity instruction. It returns a structured verdict — per-criterion `pass`/`concern`/`fail` + a one-line scope assessment. `SKILL.md` dispatches the judge per step, runs the cheap `wc -c` anti-stub pre-filter first (skip the judge call on a stub), records the verdict to `.state.json`, and routes a `fail`: pre-populate the next phase gate's `iterate` recommendation, or — in gate-less Phase 4 — surface it in the terminal handoff + `REPORT.md` § Quality concerns. The judge never autonomously hard-BLOCKs; structural hard-BLOCK stays the `schema.md` Layer 1 job.

Order: Move 1 → Move 2 brief + verdict shape → `SKILL.md` wiring → `state-machine.md` / `pipeline-coverage.md` / `quality-checklist.md` / `report.md.tmpl` updates → verification.

## Files to touch

**Create:**
- `.claude/skills/product/references/quality-judge.md` — the judge's operational reference: how the rubric is assembled per step, the verdict JSON shape, the `advisory` / `gate-flag` routing rule tied to the `state-machine.md` failure taxonomy.

**Modify:**
- `.claude/rules/artifact-budgets.md` — remove the two-threshold overshoot cascade; rewrite around the uniform catastrophe cap; drop the "scope proxy" framing. (`# OVERRIDE: budget-exempt:` grammar can stay or retire — decide in tasks.)
- `.claude/skills/product/references/delegation-briefs.md` — add the § quality-judge brief; strip the per-step overshoot-cascade boilerplate from all 15 step briefs + the mood-screen-writer brief; fix the unrelated-but-adjacent Step 08 line if convenient (else leave for the sibling spec).
- `.claude/skills/product/templates/pipeline/*/schema.md` — 15 files: remove/raise `max_size` in the Layer 1 block + the `## Target` table; keep `min_size`. Mechanical but broad.
- `.claude/skills/product/SKILL.md` — per-step judge dispatch + `wc -c` pre-filter + verdict processing; gate `iterate`-recommendation pre-population; Phase 4 handoff flag.
- `.claude/skills/product/references/state-machine.md` — judge in the phase progression; add `quality_verdicts` to the `.state.json` shape (version question — see Risks); the verdict→gate routing.
- `.claude/skills/product/references/pipeline-coverage.md` — the "Overshoot cascade" section → judge + catastrophe cap.
- `.claude/skills/product/references/quality-checklist.md` — reposition from orchestrator self-check doc to the judge's rubric contract.
- `.claude/skills/product/templates/report.md.tmpl` — add a `## Quality concerns` section (consumed by spec 073's `build-report.ts` automatically — it renders whatever sections REPORT.md carries).

**Delete:** none — `artifact-budgets.md` is rewritten, not deleted (it still documents the catastrophe cap).

## Alternatives considered

### Recalibrate the KB numbers instead of replacing the instrument (the finding-#1 path)

Rejected. This was the original triage's "balde B" fix — find better lo-fi/hi-fi budget numbers. The mei-saas dogfood proved the *instrument* is the problem, not the numbers: a fixed constant is scope-blind by construction, so any recalibration is correct for one scope and wrong for the next. Recalibrating polishes a broken instrument.

### Keep size as a hard gate, add the judge as pure advisory on top

Rejected. Leaves the false-positive ceiling firing (10/10 in dogfood) and a toothless judge — fixes neither #1/#2/#6 nor #10. The point is to *replace* the instrument, not stack a second one beside it.

### Design B (per-criterion PRE) or Design C (diverse-model panel) for v1

Rejected for v1 (see `spec.md` § Non-goals). Both are escalation paths: B if a halo effect is observed, C if single-judge verdicts prove unreliable in dogfood. Building either now is speculative machinery ahead of evidence (rule-of-three).

## Risks and unknowns

- **The judge is an LLM — non-deterministic, v1 calibration unproven.** Mitigation: the human-at-gate backstop (no autonomous hard-BLOCK) + a dedicated dogfood validation pass before the spec closes.
- **`.state.json` shape change** — adding `quality_verdicts` is a shape change; `state-machine.md`'s own rule bumps the version on shape changes (v6?). Decide v5-additive (back-compatible, readers ignore unknown field) vs v6 (consistent with the doc's history, but touches the resume version-gate). Resolve in tasks.
- **The 15-schema sweep is broad** — mechanical but error-prone; a missed file leaves a stale ceiling. Verification must grep all 15.
- **Cost** — ~15 extra `opus` judge calls per run. Marginal against a 35-55 min run, but real; `sonnet` judge is the documented knob if it bites.
- **Verbosity bias may leak** despite the anti-length rubric wording — dogfood must check the judge isn't simply rewarding longer artifacts.
- **Removing the cascade removes the trim-loop guard.** The claim "no ceiling → no trim-loop incentive" is a hypothesis; dogfood must confirm no new runaway pattern emerges (the catastrophe cap is the backstop).
- **`quality-checklist.md` may need real restructuring**, not just repositioning, to be cleanly assemble-able into a per-step rubric — unknown until the file is audited.

## Research / citations

- LLM-as-judge state of the art (2026): [Best Practices](https://futureagi.com/blog/llm-as-judge-best-practices-2026) · [bias prevalence — frontier models fail 50%+ untreated](https://www.adaline.ai/blog/llm-as-a-judge-reliability-bias) · [Replacing Judges with Juries (panel)](https://arxiv.org/pdf/2404.18796) · [LLM Jury-on-Demand](https://arxiv.org/abs/2512.01786) · [G-Eval — CoT rubric scoring](https://deepeval.com/docs/metrics-llm-evals). Key takeaways applied: pointwise grading sidesteps position bias; verbosity bias is mitigated by a length-aware rubric criterion; generation and evaluation models must be separate.
- `.claude/skills/product/templates/pipeline/02-prototype/schema.md` + `11-cost-estimate/schema.md` — read 2026-05-22; the `min_size`/`max_size` Layer 1 shape this plan edits.
- `.claude/skills/product/references/{delegation-briefs,state-machine,pipeline-coverage}.md` — read 2026-05-22 for the 10-finding triage; the orchestration surfaces this plan touches.
- mei-saas dogfood `.state.json` `partial_results` (2026-05-21) — the empirical evidence base (10/10 overshoots, every `oversize_reason` = miscalibration).
- Conversation 2026-05-22 — the budget-instrument discussion, Design A/B/C, the 4 resolved open questions.
