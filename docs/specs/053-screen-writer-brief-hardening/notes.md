# 053 — In-flight notes

## Design decisions

### 2026-05-19 — parent — OQ-1 resolution: `primary_metric` as explicit string-label

**Decided:** add `primary_metric: <label>` as optional string field on routes. Sub-agent decides the value source from route data model + components.

**Alternatives considered + rejected:**

- **Implicit derivation** (orchestrator regex-scans route name/components for `R$`, `%`, count-tokens) — fragile: "Itens críticos" doesn't match a currency pattern but IS the route's load-bearing value at `/estoque`. Heuristic would under-fire on labels, over-fire on incidental numbers.
- **Rich structured field** (`primary_metric: { label, source, format }`) — explicit but inflates sitemap.yaml. Postponed to v2 if downstream sub-agents prove ambiguous on the simple label.

**Why string-label v1:** founder-author legibility + zero ambiguity at the brief boundary. Sub-agent's job is to render the labeled metric prominently; finding the value source is part of its existing data-model judgment.

### 2026-05-19 — parent — OQ-2 resolution: `deferred_states` allowed

**Decided:** mirror `deferred_categories` pattern at the route level. `deferred_states: [{name, reason}]` on a route entry lets the sub-agent skip a declared state's render branch when the data model has no degenerate case.

**Why:** auto-augmentation for primary routes (forces `default+loading+empty+error`) is correct as a default but generates "empty-state-for-its-own-sake" copy when the founder always has data (e.g. `/faturamento` with ≥1 invoice in v1). Deferral with reason preserves the discipline (visible tradeoff in REPORT) while letting the sub-agent skip the wasted render.

### 2026-05-19 — parent — OQ-3 resolution: Biome checklist inline, no extract

**Decided:** the Biome anti-pattern checklist lives in `delegation-briefs.md § Per-stack screen-writer` body, NOT in a separate `.claude/rules/biome-anti-patterns.md`.

**Why:** Biome anti-patterns are React/Next-specific. The per-stack screen-writer brief is already React/Next scoped (line "Next.js stack" header). Extracting to `.claude/rules/` would propagate React-specific guidance to non-JS forks via sync-harness (per `feedback_agent0_changes_ship_via_rules_not_memory.md`). "Extract if reused" deferred — not actually reused elsewhere in current scope.

**Revisited recommendation:** original `tasks.md` said "inline-then-extract-if-reused". On critique, the "then-extract" was procrastination disguised as forethought — no reuse was identified, the extract was hypothetical. Decision is permanently inline unless a fork explicitly wants Biome rules in `.claude/rules/`.

## Deviations

### 2026-05-19 — parent — quality-checklist.md staleness left alone

The per-step gate criteria table in `quality-checklist.md § 1` still references the v2 13-step pipeline (rows 01-13, atlas at "13"). v0.3.0 is 15 steps with atlas at 15a + per-route writers at 15b.

Spec 053 ships its additions as a new `§ 8. Step 15 screen-writer additions` section without rewriting the stale table. A staleness note was added to point at the gap.

**Why:** migrating the full table to v0.3.0 step numbering is bigger than spec 053's scope and would touch every row's wording. Deferred to spec 058+ when the next dogfood reveals which v0.3.0 step gates actually need rework.

## Tradeoffs

- **Brief inflation.** Added ~500 tokens of CONSTRAINTS to per-stack screen-writer brief. Risk: over-prescription degrades sub-agent agency. Mitigation: each new CONSTRAINT is *mechanical* (do/don't list, not judgment call), so brief growth funds machine-checkable wins, not micromanagement.
- **DONE_WHEN bloat.** The new DONE_WHEN line is long (≈8 conditions). Trade is readability vs single-source. Kept on one line to mirror the existing pattern; if it crosses a comfort threshold later, can split into a bulleted DONE_WHEN block.

## Open questions

None remaining at ship — original OQ-1/2/3 resolved above.

Forward-looking (for next dogfood):

- **Does `primary_metric` v1 string-label cause sub-agent ambiguity?** Watch for "which number is that" failures in next dogfood; if ≥2 such cases, promote to v2 rich structure.
- **Does the Biome checklist catch all common anti-patterns?** Current list is 5 items (key-i, semantic roles, dangerouslySetInnerHTML, button type, img alt). Next dogfood may surface a 6th; extend inline.
- **Should the staleness note point at a specific replacement spec?** Currently says "058+ candidate". If a fresh dogfood surfaces the full quality-checklist rework as a real priority, scaffold 058.
