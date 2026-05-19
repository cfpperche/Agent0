# 056 — pipeline size reconciliation

**Status:** draft

## Problem

Across 4 dogfoods of the `/product` skill (specs 045, 048, the current Vetro run), the same pattern recurs: sub-agents flag a conflict between the brief's hard ceiling in `delegation-briefs.md` and the template's `min_size` floor in `templates/<step>/schema.md`. Sub-agents ship oversized + log the conflict; orchestrator accepts and moves on. Steps affected (Vetro dogfood):

- 02 direction-a.html — 23.8 KB vs brief ceiling 12 KB (~2x over)
- 03 functional-spec — 22 KB vs ceiling 12 KB (~1.8x over)
- 08 system-design — 33.6 KB vs ceiling 18 KB
- 09 legal-posture — 19.3 KB vs ceiling 7 KB
- 10 roadmap — 15 KB vs ceiling 8 KB
- 15a screen-atlas — 20 KB vs ceiling 15 KB

Either the briefs are wrong (too tight for the schema requirements) or the schemas are bloated (mandate too much for the brief's intent). Without one canonical truth, sub-agents waste cycles auto-resolving + the REPORT logs noise that doesn't lead to action.

## Acceptance criteria

- [ ] **Scenario: single canonical size source per step**
  - **Given** Step N has both a `schema.md` and a brief in `delegation-briefs.md`
  - **When** a maintainer reads the size budget
  - **Then** exactly ONE artifact (`schema.target = { min_size, max_size }`) declares the budget, and the brief references it textually (`<= schema.target.max_size KB`)
- [ ] **Scenario: schema target is calibrated against actual output**
  - **Given** standard-tier output of step N across ≥ 2 dogfoods
  - **When** the outputs are measured
  - **Then** ≥ 80% land within `[schema.target.min_size, schema.target.max_size]`
- [ ] **Scenario: oversize is handled explicitly, not silently**
  - **Given** a sub-agent's output exceeds `max_size` by ≥ 20%
  - **When** the sub-agent declares done
  - **Then** the deliverable is partial-result with a `oversize_reason` field (not silent ship-oversized)

## Non-goals

- Forcing identical sizing rules across all 15 steps — each step has its own appropriate range.
- Schema-level enforcement at the validator (current pattern is sub-agent self-check; validator-cascade in spec 057 has separate scope).
- Adding more dimensions to the size budget (e.g. token count vs byte count — bytes is fine for v1).

## Open questions

1. Which artifact is authoritative — `schema.md` or `delegation-briefs.md`? Recommend schema (each step has one schema; briefs reference).
2. Hard ceiling (abort on overshoot) or soft ceiling (warn)? Currently soft via partial-result; consider hard for steps that downstream consumers depend on (e.g. Step 05 PRD — 4-7 KB tight is by design).
3. Should we run a backfill calibration pass across dogfoods 034/045/048/Vetro before adjusting numbers, or just edit schemas from current intuition?
