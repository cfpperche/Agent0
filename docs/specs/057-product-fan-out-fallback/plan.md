# 057 — Plan

## Approach

Add two mechanisms to SKILL.md § Phase 4 Step 15b without touching the harness:

1. **Between-wave biome sweep** — the orchestrator runs `node_modules/.bin/biome check --write .` (parent-side, exempt) between each wave of the fan-out. Cost is small (~25ms per pass observed in dogfood-2); benefit is each wave starts from a clean lint state, breaking the cascade.

2. **Degrade-to-parent-write fallback** — after a configurable threshold of loop-budget exhaustions in a wave (recommend 2 consecutive), the orchestrator stops dispatching remaining routes in the fan-out as sub-agents and writes them itself using the same brief. Parent edits are exempt from the post-edit validator; the cascade can't trip. Each degraded route is logged with reason.

Both mechanisms are orchestrator-side only — no changes to sub-agent briefs, no new hooks, no validator changes.

## Files to touch

- `.claude/skills/product/SKILL.md` § Phase 4 Step 15b — add new sub-sections:
  - **Between-wave biome sweep** (mandatory)
  - **Fan-out fallback strategy** (triggered by N=2 loop-budget exhaustions)
- `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer — add a note that the same brief is valid for parent-write (sub-agent vs parent is an execution-strategy choice, not a brief change).
- `.claude/skills/product/references/quality-checklist.md` § Step 15 — add "fan-out degradations are expected, REPORT must surface them".
- `.claude/skills/product/templates/report.md.tmpl` — add `## Build health § Fan-out degradations` placeholder section, populated when ≥1 route degraded.

## Alternatives considered

- **Switch validator to per-edited-file scope.** Right answer architecturally but big spec — touches `.claude/hooks/post-edit-validate.sh` and the validator semantic. Deferred. This spec ships the mitigation that works *today*.
- **Disable validator during Step 15b entirely.** Rejected — too permissive; legitimate errors get missed.
- **Serialize Step 15b (no fan-out).** Rejected — defeats the cap=5 throughput value when the cascade doesn't fire.
- **Reduce cap=5 to cap=2.** Rejected — cap=2 isn't immune to cascade, just slows it.

## Risks

- **Parent-write hides sub-agent quality drift.** The whole point of dispatching to sub-agents is that they do the work. Parent-write recovers the route but masks whether the sub-agent could have succeeded with a clean lint state. Mitigation: REPORT logs degradation prominently — repeated degradations are a signal the brief or validator needs structural attention.
- **Between-wave biome sweep adds latency.** ~25ms × N waves is negligible (~150ms for a 30-route dogfood). Acceptable.
- **Threshold tuning may be wrong.** N=2 is intuitive but unvalidated; could be N=1 (early degrade) or N=3 (give the cascade a chance to resolve). Empirical via next dogfood.
