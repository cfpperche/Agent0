# 057 — `/product` fan-out fallback

**Status:** shipped

## Problem

Dogfood-2 Wave 1 of Step 15b (`/tmp/dogfood-vet`, 5 parallel screen-writers) all hit `CLAUDE_DELEGATION_LOOP_BUDGET` exhaustion. Root cause: the post-edit validator runs `biome check` **repo-wide**, not per-edited-file. Each parallel sub-agent inherits in-flight lint errors from sibling sub-agents and cannot reach `ok=true`. The parent had to pivot to parent-write for the remaining 19 of 24 routes (parent edits are exempt from the validator).

Net effect: the fan-out value proposition collapsed — instead of 5 routes/wave at 5 waves = 25 routes in parallel, the run produced 5 routes in fan-out + 19 routes parent-write. The recovery worked but the failure mode is silent: REPORT.md mentioned the issue, but the orchestrator didn't surface it as a degradation event.

SKILL.md § Notes mentions the validator-cascade and prescribes "parent-side biome check --write between PHASES". This dogfood proved that mitigation isn't enough — the cascade fires inside a single phase, between waves of the same fan-out step.

## Acceptance criteria

- [ ] **Scenario: parent-side biome runs between waves of Step 15b**
  - **Given** Step 15b dispatches N waves of up to 5 sub-agents each (sitemap has > 5 routes)
  - **When** wave K returns (all sub-agents in the wave done OR failed)
  - **Then** orchestrator runs `node_modules/.bin/biome check --write .` before dispatching wave K+1
- [ ] **Scenario: degrade-to-parent-write on cascade detection**
  - **Given** ≥ 2 sub-agents in the same wave hit `CLAUDE_DELEGATION_LOOP_BUDGET` exhaustion
  - **When** the wave completes
  - **Then** the orchestrator switches the remaining routes in subsequent waves to parent-write with the same brief, logging `degraded_to_parent: true` per route in REPORT
- [ ] **Scenario: REPORT surfaces degradation explicitly**
  - **Given** any route was degraded to parent-write during the run
  - **When** REPORT.md is authored at Phase 5
  - **Then** a `## Build health § Fan-out degradations` section lists each degraded route, the reason, and the wave it occurred in

## Non-goals

- Fixing the validator-cascade at the harness level — `.claude/hooks/post-edit-validate.sh` changes are bigger and live in a separate spec.
- Reducing fan-out cap below 5 — `cap=5` is proven non-OOM on a 17-route dogfood.
- Auto-retrying degraded routes in a future wave (one-shot is enough for v1).

## Open questions

1. Threshold for "degrade": 2 consecutive failures? 50% of wave? First failure in the run?
2. When degraded, should parent-write use the same brief verbatim, or a simplified version (since parent has more context than sub-agent)?
3. Should orchestrator pre-emptively biome-write between waves even on success, or only when validator stderr reports dirty siblings?
