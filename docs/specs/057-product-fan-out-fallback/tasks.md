# 057 — Tasks

1. [ ] Resolve open question #1 (degrade threshold) — recommend N=2 consecutive loop-budget exhaustions in same wave.
2. [ ] Resolve open question #2 (degraded brief shape) — recommend same brief verbatim; sub-agent vs parent is orchestration concern only.
3. [ ] Resolve open question #3 (pre-emptive biome sweep) — recommend always-between-waves, not conditional.
4. [ ] Edit `SKILL.md § Phase 4 Step 15b`: add "Between-wave biome sweep" sub-section with literal command.
5. [ ] Edit `SKILL.md § Phase 4 Step 15b`: add "Fan-out fallback strategy" sub-section with degrade trigger + parent-write fallback path.
6. [ ] Edit `delegation-briefs.md § Per-stack screen-writer`: note brief is execution-strategy-agnostic.
7. [ ] Edit `templates/report.md.tmpl`: add `## Build health § Fan-out degradations` placeholder + population rule.
8. [ ] Edit `quality-checklist.md § Step 15`: degradations are expected; gate criterion is "REPORT surfaces them".
9. [ ] Verify with a dry-run that intentionally provokes loop-budget exhaustion (e.g. corrupt one screen-writer's input) — confirm degradation triggers and REPORT surfaces it.
10. [ ] Commit: `feat(057): /product fan-out fallback — between-wave biome + degrade-to-parent-write`.
