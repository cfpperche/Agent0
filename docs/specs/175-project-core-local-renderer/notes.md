# 175 - project-core-local-renderer - notes

_Created 2026-06-08._

_In-flight design memory for this spec - decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention._

## Design decisions

### 2026-06-08 - parent - Derived mirrors should self-heal locally

The consumer-owned `.agent0/project-core.md` is the only source of truth. `CLAUDE.md` and `AGENTS.md` regions are derived output, so refreshing them should not require an upstream Agent0 source path. Direct edits to derived regions should be overwritten by the local renderer.

## Deviations

## Tradeoffs

## Open questions
