# 056 — Tasks

1. [ ] Resolve open question #1 (authoritative artifact) — recommend `schema.md`.
2. [ ] Resolve open question #2 (hard vs soft ceiling) — recommend soft with 20% overshoot trigger for partial-result.
3. [ ] Resolve open question #3 (backfill calibration) — recommend yes for 6 priority steps; measure across dogfoods 045 + 048 + Vetro.
4. [ ] Run calibration: measure standard-tier output of steps 02 / 03 / 08 / 09 / 10 / 15a across 3 dogfoods; compute median + range.
5. [ ] Decide reconciled values per step (bump schema, tighten brief, or split conditional sections for Step 09).
6. [ ] Edit `templates/pipeline/02-prototype/schema.md`: set `target: { min_size, max_size }`.
7. [ ] Edit `templates/pipeline/03-spec/schema.md`: same.
8. [ ] Edit `templates/pipeline/08-system-design/schema.md`: same; consider sub-targets per H2 section if RACI + risk-register inflate.
9. [ ] Edit `templates/pipeline/09-legal/schema.md`: model conditional content (`base + DPIA + AI-Specific + Regulated Aspects`).
10. [ ] Edit `templates/pipeline/10-roadmap/schema.md`: same.
11. [ ] Edit `templates/pipeline/15-screen-atlas/schema.md`: same.
12. [ ] Edit `delegation-briefs.md`: replace hardcoded sizes for the 6 steps with `<= schema.target.max_size KB` references.
13. [ ] Edit `pipeline-coverage.md § Per-step size targets`: single-source from schema; remove duplicate declarations.
14. [ ] Run a verification dogfood (single fresh idea) and confirm ≥ 80% of outputs land in `[min_size, max_size]` for the 6 reconciled steps.
15. [ ] Commit: `feat(056): pipeline size reconciliation — schema is canonical, briefs reference`.
