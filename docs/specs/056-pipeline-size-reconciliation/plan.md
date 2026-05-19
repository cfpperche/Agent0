# 056 — Plan

## Approach

Promote `schema.md` to the authoritative size source. Each `templates/pipeline/<step>/schema.md` gets a `target: { min_size, max_size }` field with reconciled values. `delegation-briefs.md` stops hardcoding sizes and references the schema target. `pipeline-coverage.md § Per-step size targets` becomes a derived view, not a redundant declaration.

Phased rollout — prioritize the 6 steps with empirically-confirmed drift (02, 03, 08, 09, 10, 15a); leave the others until next dogfood surfaces drift for them.

## Files to touch

- `.claude/skills/product/templates/pipeline/02-prototype/schema.md` — confirm `min_size`/`max_size` reconcile with brief (currently brief says 6-12 KB ceiling, output lands 24 KB; schema floor is 10 KB — investigate which is wrong).
- `.claude/skills/product/templates/pipeline/03-spec/schema.md` — same for functional-spec.
- `.claude/skills/product/templates/pipeline/08-system-design/schema.md` — same; system-design is bridge-floor by design, target may need raising.
- `.claude/skills/product/templates/pipeline/09-legal/schema.md` — same; legal is mandated-content-heavy when DPIA fires (calibrate separately for conditional sections).
- `.claude/skills/product/templates/pipeline/10-roadmap/schema.md` — same.
- `.claude/skills/product/templates/pipeline/15-screen-atlas/schema.md` — same.
- `.claude/skills/product/references/delegation-briefs.md` — for the 6 steps above, replace hardcoded sizes with `<= schema.target.max_size KB`.
- `.claude/skills/product/references/pipeline-coverage.md § Per-step size targets` — single-source the size table from schema; cite schema target paths.

## Alternatives considered

- **Eliminate sizing constraints entirely.** Rejected — sub-agents balloon without a budget, and oversized artifacts hurt downstream consumers (the next sub-agent reads more tokens).
- **Move sizing to brief only.** Rejected — schemas need to be self-contained for portability per spec 033 (agentskills.io alignment).
- **Adaptive sizing (sub-agent picks based on perceived complexity).** Rejected — sub-agents are bad at self-estimating; range floor/ceiling is the budget signal.

## Risks

- **Backfill cost.** 6 schema.md files × calibration analysis. Mitigation: phased; do 2 steps per pass, validate next dogfood, iterate.
- **Calibration choice may be wrong.** Different products produce different sizes legitimately. Mitigation: ranges (min..max) not single targets; allow 20% overshoot as soft-ceiling before partial-result trigger.
- **Conditional-content steps (Step 09 legal — DPIA fires sometimes)** need conditional sizing: base + DPIA + AI-Specific + Regulated Aspects. Could be modeled as `target: { base, +DPIA, +AI, +Regulated }` summed by orchestrator.
