# 176 - project-core-template-review - notes

_Created 2026-06-08._

_In-flight design memory for this spec - decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention._

## Design decisions

### 2026-06-08 - parent - Template change requires explicit source acknowledgement

Configured consumers should receive updated `.agent0/project-core.md.example` files, but Agent0 must not edit real `.agent0/project-core.md` automatically. A marker in the source makes the review state visible and cleanable without comparing source content to a template it should naturally differ from.

## Deviations

## Tradeoffs

## Open questions
