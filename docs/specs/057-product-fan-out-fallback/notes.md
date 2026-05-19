# 057 — In-flight notes

## Design decisions

### 2026-05-19 — parent — OQ-1 resolution: N=1 same-wave (critique-revised from N=2)

**Decided:** the first loop-budget exhaustion in a wave triggers degrade-to-parent-write. Orchestrator cancels any in-flight siblings + switches all remaining routes (this wave + subsequent waves) to parent-write.

**Why N=1 (not the original N=2 recommendation):** dogfood-2 evidence is unambiguous — Wave 1 had **5/5 sub-agents** hit `CLAUDE_DELEGATION_LOOP_BUDGET` exhaustion. Sub-agents in the same wave share lint state via repo-wide `biome check`; when one fails, the others read the same dirty state and almost certainly fail too. N=2 would have wasted ~4 sub-agents of work (3-5 minutes per sub-agent + token budget) before degrading. N=1 catches it on first signal.

**Critique of original recommendation:** the tasks.md scaffold said "recommend N=2 consecutive — give cascade one chance to resolve". On critique: the cascade does NOT resolve on its own — each new wave inherits the prior wave's lint dirt, so the cascade entrenches rather than resolves. Waiting for N=2 is throughput-burning theater. N=1 is aggressive but correct given the cascade's mechanism.

### 2026-05-19 — parent — OQ-2 resolution: same brief verbatim

**Decided:** parent-write fallback uses the same per-stack screen-writer brief verbatim. Sub-agent vs parent is an orchestration concern only; the brief contract (CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN) does not change.

**Why:** simplifies the orchestration code path (parent reads brief + calls `Write`; no special-case "parent simplification" logic). Also means brief edits propagate to both execution strategies uniformly — no risk of the parent-write path drifting from the sub-agent path.

### 2026-05-19 — parent — OQ-3 resolution: always-between-waves biome sweep

**Decided:** between-wave biome sweep runs MANDATORILY before every wave K+1 dispatch, even on clean waves. NOT conditional on validator stderr or wave outcome.

**Why:** ~25ms cost per pass × N waves is negligible (~150ms total for a 30-route dogfood). Conditional logic ("sweep only when prior wave dirty") adds parsing surface + race-condition risk between wave-completion detection and sweep execution. Unconditional is simpler + faster to reason about.

### 2026-05-19 — parent — Brief execution-strategy decoupling

Adding the "brief is execution-strategy-agnostic" note to delegation-briefs.md is non-trivial design memory. It cements the invariant: future brief edits MUST work for both sub-agent dispatch + parent-write. Without this note, a future contributor might add a CONSTRAINT like "ask the user before <foo>" that breaks parent-write (parent IS the user-facing context — can't sub-prompt itself).

## Deviations

### 2026-05-19 — parent — quality-checklist.md numbering renumbered

The previous section `## 8. Step 15 screen-writer additions` (added by spec 053) is renumbered to `## 8b`. Spec 057 inserts `## 8a. Step 15b fan-out fallback` BEFORE it because the orchestration discipline conceptually precedes the per-route additions.

This is a backward-incompatible rename inside a single file's numbering. No external references (other rule docs, scripts) cite `§ 8` of quality-checklist.md, so the rename is safe locally. If something starts citing the section number, switch to slugs.

### 2026-05-19 — parent — REPORT.md template stale-numbering left alone

`templates/report.md.tmpl` is the v2 13-step template (per `## Pipeline coverage` table rows 01-13). The Fan-out degradations sub-section is added under existing `## Build health` without touching the stale pipeline-coverage rows. Migrating the template to v0.3.0 15-step layout is a separate concern (spec 058+ candidate).

## Tradeoffs

- **N=1 cancels in-flight siblings — wasted work on cancellation.** Even if siblings WOULD have succeeded (rare given shared lint state), cancelling them at N=1 burns the work they'd done. Trade: in dogfood-2, none of the 5 siblings would have succeeded (5/5 hit budget), so cancellation lost nothing. If a future dogfood shows siblings legitimately recovering after N=1 fail (rare), revisit.
- **Between-wave biome sweep mutates the working tree.** Parent-side `biome check --write .` modifies files outside the current wave's sub-agent edit set. Trade: parent edits are exempt from the validator, so the writes don't trigger validation; founder sees the changes in git diff if they're reviewing the diff. Net is hygiene > risk.
- **Always-on sweep adds ~150ms total per /product run.** Trade: 150ms is 0.4% of the 35-55 min total /product run; not measurable in practice.
- **Parent-write hides sub-agent quality drift.** The whole point of fan-out is sub-agents do work in parallel. Parent-write recovers the route but masks whether sub-agent could have succeeded with cleaner state. Mitigation: REPORT prominently logs degradation per route — repeated degradations are visible signal that brief or validator needs structural attention.

## Open questions

None remaining at ship — OQ-1/2/3 resolved.

Forward-looking:

- **Is N=1 too aggressive in practice?** Watch the next 2-3 dogfoods. If a dogfood shows wave with first-fail then 4-of-4 siblings succeed cleanly, N=1 over-degrades and the right threshold is higher. Hypothesis: this won't happen, because the validator-cascade mechanism is structural.
- **Should orchestrator track per-route attempt counts in `.state.json`?** Currently the degradation log is in-memory + written to REPORT at Phase 5. If a run aborts mid-fan-out, the log is lost. Adding persistence to `.state.json` would survive aborts. Defer until aborted-mid-fan-out becomes a real problem.
- **Threshold escalation on repeated degradations?** Currently degradation is per-route; subsequent waves still attempt sub-agents (just on parent-write path). Could we escalate: after Y degradations in a row, suppress sub-agent dispatch entirely for the rest of the step? Probably not needed — once degraded, the orchestrator is on parent-write path already; doesn't re-attempt sub-agents until next /product run.
- **Should brief gain a "fallback mode" hint?** Currently the brief is identical for sub-agent + parent. A parent-write run COULD benefit from "you have more context — use it" hints. Trade: cluttering the brief with execution-strategy-conditional logic violates the OQ-2 resolution. Defer.
