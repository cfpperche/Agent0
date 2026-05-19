# 057 — Tasks

1. [x] Resolve open question #1 — **DECIDED: N=1 same-wave** (NOT N=2 consecutive). First failure in a wave triggers degrade; orchestrator cancels in-flight siblings + switches remaining routes to parent-write. Empirical: dogfood-2 Wave 1 had 5/5 sub-agents hit loop budget — N=1 would have saved 4 sub-agents of wasted work because sub-agents in the same wave share lint state via repo-wide `biome check`.
2. [x] Resolve open question #2 — **DECIDED: same brief verbatim**. Sub-agent vs parent is orchestration choice; the brief contract is execution-strategy-agnostic. Per-stack screen-writer brief gains explicit note documenting this.
3. [x] Resolve open question #3 — **DECIDED: always-between-waves**. Cost ~25ms per pass; benefit is each wave starts from a clean lint state, breaking the validator-cascade. NOT conditional.
4. [x] Edit `SKILL.md § Phase 4 Step 15` (Step 15b sub-section) — added "Between-wave biome sweep" mandatory line + "Degrade-to-parent-write trigger" with N=1 same-wave + "Parent-write fallback shape" + "Logging" steps under "Fan-out execution (spec 057 — wave + cascade discipline)" block.
5. [x] (combined with 4 — same SKILL.md block covers both biome sweep + degrade fallback).
6. [x] Edit `delegation-briefs.md § Per-stack screen-writer`: added paragraph noting brief is execution-strategy-agnostic (same brief works for sub-agent dispatch OR parent-write fallback).
7. [x] Edit `templates/report.md.tmpl`: added `### Fan-out degradations (spec 057)` sub-section under `## Build health` with placeholder table + designed-as-expected framing.
8. [x] Edit `quality-checklist.md`: added new `## 8a. Step 15b fan-out fallback (NEW in spec 057; orchestration discipline)` section before existing 8b (formerly 8). Codifies between-wave biome sweep + N=1 degrade trigger + REPORT visibility as gate criteria.
9. [ ] Verify with a dry-run that intentionally provokes loop-budget exhaustion (e.g. corrupt one screen-writer's input) — confirm degradation triggers and REPORT surfaces it. **Deferred to next /product invocation**; spec 057 ships orchestration-doc-only.
10. [ ] Commit: `feat(057): /product fan-out fallback — between-wave biome + degrade-to-parent-write at N=1`.
