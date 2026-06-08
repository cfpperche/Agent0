# 174 - bootstrap-advisories - notes

_Created 2026-06-08._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention._

## Design decisions

### 2026-06-08 — parent — Silence after bootstrap is part of acceptance

The advisory is useful only while it is true. Once `.agent0/project-core.md` exists, startup/status/sync/doctor must stop warning about project-core bootstrap to avoid stale context and false-positive training.

### 2026-06-08 — codex — mei-saas sync kept configuration pending

`/home/goat/mei-saas` was synced with the advisory mechanism but without creating `.agent0/project-core.md`, per user instruction. The consumer now intentionally shows pending bootstrap alerts until its project-specific language/core guidance is configured.

## Deviations

## Tradeoffs

## Open questions
