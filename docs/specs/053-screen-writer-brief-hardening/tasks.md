# 053 — Tasks

1. [ ] Resolve open question #1 (primary_metric: explicit field vs implicit derivation) — recommend explicit.
2. [ ] Resolve open question #2 (deferred_states allowed?) — recommend yes, mirrors deferred_categories pattern.
3. [ ] Resolve open question #3 (Biome checklist inline vs referenced rule) — recommend inline-then-extract-if-reused.
4. [ ] Edit `sitemap-schema.md`: add optional `primary_metric: string` to route field set.
5. [ ] Edit `templates/pipeline/07-sitemap-ia/prompt.md`: instruct sub-agent to set `primary_metric` for routes with load-bearing operational values.
6. [ ] Edit `delegation-briefs.md § Per-stack screen-writer CONSTRAINTS`: add 4 new clauses (metadata, states, Biome anti-patterns, primary metric).
7. [ ] Edit `quality-checklist.md § Step 15`: add 4 gate criteria mirroring the constraints.
8. [ ] Verify with a dry-run dogfood (single route, e.g. `/estoque` from a fresh sitemap declaring `states: [empty]` + `primary_metric: "Itens críticos"`) — sub-agent produces empty-render + MetricTile.
9. [ ] Commit: `feat(053): screen-writer brief — metadata + states + Biome checklist + primary metric`.
