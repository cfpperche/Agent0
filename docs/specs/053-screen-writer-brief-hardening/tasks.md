# 053 — Tasks

1. [x] Resolve open question #1 — **DECIDED: explicit string-label** (`primary_metric: "<label>"`), sub-agent decides value source from route data model. v2 may richen to `{label, source, format}` if downstream ambiguity surfaces. See `notes.md`.
2. [x] Resolve open question #2 — **DECIDED: `deferred_states` allowed** with `{name, reason}` shape mirroring `deferred_categories`. Auto-augmentation on primary routes can only be dropped via this. See `notes.md`.
3. [x] Resolve open question #3 — **DECIDED: inline only, no extract.** Biome checklist is React/Next-specific and doesn't belong in a generic `.claude/rules/` rule. See `notes.md`.
4. [x] Edit `sitemap-schema.md`: add optional `primary_metric: string` + `deferred_states` to route field set.
5. [x] Edit `templates/pipeline/07-sitemap-ia/prompt.md`: instruct sub-agent to set `primary_metric` for routes with load-bearing operational values + YAML example shows `deferred_states` usage.
6. [x] Edit `delegation-briefs.md § Per-stack screen-writer CONSTRAINTS`: add 4 new clauses (metadata, states implementation evidence, Biome anti-patterns, primary metric); update DONE_WHEN.
7. [x] Edit `quality-checklist.md`: add `§ 8. Step 15 screen-writer additions` with 4 gate criteria + staleness note on v2 table.
8. [ ] Verify with a dry-run dogfood (single route, e.g. `/estoque` from a fresh sitemap declaring `states: [empty]` + `primary_metric: "Itens críticos"`) — sub-agent produces empty-render + MetricTile. **Deferred to next /product invocation**; spec 053 ships brief-only.
9. [ ] Commit: `feat(053): screen-writer brief — metadata + states + Biome checklist + primary metric`.
