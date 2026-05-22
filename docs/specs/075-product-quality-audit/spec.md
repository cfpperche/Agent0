# 075 — product-quality-audit

_Created 2026-05-22._

**Status:** draft

## Intent

`/product` currently gates artifact scope with a **size budget** — a per-step KB ceiling, the `max × 1.2 → partial-result` / `max × 1.8 → hard-abort` overshoot cascade (`.claude/rules/artifact-budgets.md`), and `max_size` ceilings in each step's `schema.md`. The mei-saas dogfood (two runs, 2026-05-19 + 2026-05-21) proved this instrument is broken: **every artifact with a meaningful ceiling overshot it** (10/10 mood screens; functional-spec, roadmap, cost-estimate, sitemap, fixture-spec, brand-book), and every sub-agent `oversize_reason` diagnosed "the budget is miscalibrated for this scope", not "I bloated". The cascade fired ~15 times with zero true positives. Root cause: a KB ceiling is a **scope-blind fixed constant** — it cannot adapt to a run's declared scope (the mei-saas run requested full Fases 1-8 against budgets calibrated for an MVP).

This spec replaces the **ceiling instrument** with a rubric-based quality judge: after each pipeline step, an independent-context sub-agent evaluates the step's artifact(s) against the step's **already-existing rubric** (`schema.md` required-sections + `contains`-anchors + `quality-checklist.md` per-step criteria) plus an explicit **scope-aware right-sizing criterion**. The judge replaces "is this artifact ≤ N KB?" with "is this artifact scoped correctly, complete, and coherent for its declared job?" — the question the KB number was a poor proxy for. This is **Design A** from the 2026-05-22 discussion: a single judge per step, chain-of-thought, structured verdict, with opt-in per-criterion teeth (a `fail` on a load-bearing criterion routes the step to BLOCKED/iterate — giving the visual check the teeth dogfood finding #10 asked for).

Scope-floor checks are unchanged: the cheap `wc -c` **anti-stub floor** stays (a 2 KB concept-brief genuinely is a stub — judgment there is overkill), and the overshoot cascade is reduced to a **generous catastrophe-only byte cap** (a dumb circuit-breaker against true token runaway, no longer a scope budget).

## Acceptance criteria

- [ ] **Scenario: quality judge runs after a step**
  - **Given** a pipeline step's sub-agent has returned its artifact(s)
  - **When** the orchestrator dispatches the quality-judge sub-agent (independent context, 5-field brief)
  - **Then** a structured verdict is recorded — per-criterion `pass` / `concern` / `fail` against the step's rubric, plus a one-line scope assessment — and surfaced in `REPORT.md` / `.state.json`

- [ ] **Scenario: a correctly-scoped large artifact is NOT flagged**
  - **Given** an artifact that is larger than the retired KB ceiling but correctly scoped for the run's declared product scope
  - **When** the judge evaluates it
  - **Then** the right-sizing criterion returns `pass` — no false positive, because the criterion is scope-aware, not byte-count-based

- [ ] **Scenario: a genuinely bloated artifact is flagged by dimension**
  - **Given** an artifact with a section that covers detail its job does not require (genuine bloat)
  - **When** the judge evaluates it
  - **Then** the right-sizing criterion returns `concern`/`fail` naming the bloated section and dimension (the actionable signal `oversize_reason` aimed at)

- [ ] **Scenario: a judge `fail` reaches a phase gate (teeth — finding #10)**
  - **Given** a judge verdict with `fail` on a step inside a phase that has a downstream `AskUserQuestion` gate
  - **When** the orchestrator reaches that gate
  - **Then** the gate's recommended option is pre-populated as `iterate`, citing the failed criterion — the human decides; the judge never autonomously BLOCKs

- [ ] **Scenario: a judge `fail` in gate-less Phase 4**
  - **Given** a judge verdict with `fail` on a Phase 4 artifact (15a / 15b / 15c — no downstream gate)
  - **When** the run reaches the terminal handoff
  - **Then** the `fail` is surfaced in the handoff message and a `REPORT.md` § Quality concerns section — not buried as a one-line note

- [ ] **Scenario: anti-stub pre-filter short-circuits the judge**
  - **Given** an artifact below the step's `wc -c` anti-stub floor
  - **When** the orchestrator checks it
  - **Then** it is flagged a stub and re-dispatched without spending a judge call

- [ ] **Scenario: catastrophe cap still circuit-breaks runaway**
  - **Given** a sub-agent producing an artifact past the generous catastrophe byte cap (≫ the step's expected size)
  - **When** the cap is hit
  - **Then** the sub-agent stops and emits a partial-result — a dumb token-runaway circuit-breaker, with no trim-loop and no scope-budget semantics

- [ ] The size-budget overshoot cascade (`max × 1.2` / `max × 1.8`) is removed from `.claude/rules/artifact-budgets.md`, or rewritten as the catastrophe-only cap; the rule no longer frames a KB number as a scope proxy
- [ ] Each step's `schema.md` `max_size` ceiling is removed or raised to the catastrophe threshold; the `min_size` anti-stub floors are retained
- [ ] A quality-judge 5-field brief exists in `references/delegation-briefs.md`; the judge is dispatched as a separate sub-agent (generation and evaluation models are separate, per LLM-as-judge best practice)
- [ ] The judge rubric is sourced from each step's `schema.md` + `quality-checklist.md` — no new rubric is authored; `quality-checklist.md` becomes the judge's contract rather than an orchestrator self-check doc
- [ ] The right-sizing rubric criterion explicitly instructs the judge **not to reward length** (verbosity-bias mitigation — the bias that would otherwise push artifacts larger)
- [ ] `SKILL.md` dispatches the judge at each step and processes the verdict; `pipeline-coverage.md` and `state-machine.md` are updated to reflect the judge step and the retired ceiling
- [ ] The quality judge never autonomously hard-BLOCKs or aborts a run — deterministic structural BLOCK/abort stays the `schema.md` Layer 1 job; the judge's strongest action is the gate `iterate` recommendation (or, in gate-less Phase 4, the handoff flag)
- [ ] The judge sub-agent runs on `opus` (stronger reasoner for evaluation + within-family asymmetry vs the `sonnet` step producers); a `sonnet` judge is the documented cost knob
- [ ] The catastrophe byte cap is a single uniform absolute value (≈200 KB), not a per-step multiplier — a per-step number would re-rot exactly the way the retired ceiling did

## Non-goals

- **Not a panel/jury (Design C).** v1 is a single judge per step. A diverse-model panel for gate-critical artifacts is the documented escalation if v1 verdicts prove noisy in dogfood — deferred per rule-of-three.
- **Not per-criterion PRE calls (Design B).** v1 evaluates the whole rubric in one judge call per step. Splitting into one call per criterion (halo-effect mitigation) is deferred until a halo effect is observed.
- **Not a cross-family / non-Claude judge.** v1 accepts mild self-preference bias (Claude judging Claude) — pointwise single-artifact evaluation makes it bland. An external non-Claude judge API would break the skill's standalone Claude-native posture; deferred.
- **Does not author new rubrics.** Autorubric-style rubric generation is out of scope — the per-step `schema.md` + `quality-checklist.md` rubrics already exist and are reused.
- **Does not remove the anti-stub floor.** The cheap `wc -c` floor stays; only the *ceiling* instrument is replaced.
- **Does not address the orthogonal `/product` dogfood fixes** — findings #3 (mood-screen nav rule), #4 (Playwright `file://`), #5 (false parallelism), #8 (model advisory), #9 (Step 08 typo) are a separate spec. This spec absorbs only the budget-instrument findings (#1, #2-partial, #6, #7, #10-teeth).

## Open questions

_All four resolved 2026-05-22 (conversation). Recorded here as the decision trail; the resolutions are reflected in § Acceptance criteria above._

- **Teeth granularity** → **RESOLVED:** two levels — `advisory` and `gate-flag`. The judge never autonomously hard-BLOCKs; deterministic structural BLOCK/abort stays the `schema.md` Layer 1 job. A `fail` pre-populates the next phase gate's `iterate` recommendation (human decides); in gate-less Phase 4 it surfaces in the handoff message + `REPORT.md` § Quality concerns. Marking is a global rule tied to the `state-machine.md` failure taxonomy — not per-step checkboxes.
- **Panel for gate-critical artifacts** → **RESOLVED:** deferred. Single judge in v1 — the human at the phase gate is v1's reliability backstop (a panel matters when the verdict is consumed autonomously; here it is consumed by a human). Panel is the escalation if dogfood shows single-judge verdicts unreliable.
- **Cross-family judge** → **RESOLVED:** deferred. v1 accepts mild self-preference bias — pointwise rubric grading (no rival-family artifact to prefer) makes it bland. The judge runs on `opus` for within-family asymmetry vs the `sonnet` producers. An external non-Claude judge is the escalation if the opus judge proves systematically lenient on Claude output.
- **Catastrophe-cap multiplier** → **RESOLVED:** a single uniform absolute cap (≈200 KB), not a per-step multiplier — a per-step number would re-rot the way the ceiling did. Exact value finalized in `plan.md`.

## Context / references

- `.claude/rules/artifact-budgets.md` — the size-budget rule this spec retires/rewrites
- `.claude/skills/product/templates/pipeline/*/schema.md` — per-step `min_size` floors (kept) + `max_size` ceilings (removed/raised); the required-sections + `contains`-anchors that become the judge rubric
- `.claude/skills/product/references/quality-checklist.md` — per-step gate criteria; becomes the judge's contract
- `.claude/skills/product/references/delegation-briefs.md` — gains the quality-judge brief
- `.claude/skills/product/references/{pipeline-coverage,state-machine}.md` — updated for the judge step + retired ceiling
- mei-saas dogfood `.state.json` `partial_results` (2026-05-21) — the empirical evidence: 10/10 overshoots, every `oversize_reason` = miscalibration
- Dogfood findings #1 / #2 / #6 / #7 / #10 — the budget-instrument subset of the 10-finding triage (2026-05-22)
- Sibling spec — the orthogonal dogfood fixes (#3 / #4 / #5 / #8 / #9), to be scaffolded separately
- LLM-as-judge research (2026): [Best Practices](https://futureagi.com/blog/llm-as-judge-best-practices-2026) · [bias prevalence](https://www.adaline.ai/blog/llm-as-a-judge-reliability-bias) · [Replacing Judges with Juries](https://arxiv.org/pdf/2404.18796) · [LLM Jury-on-Demand](https://arxiv.org/abs/2512.01786) · [G-Eval](https://deepeval.com/docs/metrics-llm-evals)
- Conversation 2026-05-22 — the budget-instrument discussion + Design A/B/C
