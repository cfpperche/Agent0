# 169 - post-launch-maintenance-loop - notes

_Created 2026-06-08._

In-flight design memory for this spec. Append decisions, deviations, tradeoffs, and open questions surfaced while building.

## Design decisions

### 2026-06-08 - parent - v1 capped to rule and templates

Claude's read-only critique agreed with the instrument-only direction but objected that the original draft left the v1 surface too open. Accepted: because evidence is founder-directive plus one external pattern, not rule-of-three or dogfood failure, v1 is capped to a context rule plus copyable templates. A portable skill, hook, daemon, webhook receiver, scheduler, or validator stays out of scope until dogfood proves the passive surface is insufficient.

### 2026-06-08 - parent - template path and freshness posture

Templates live under `.agent0/context/templates/post-launch-maintenance-loop/` because `.agent0/context/**` already propagates through `sync-harness.sh`; no new top-level template sync root is needed. Vendor docs are isolated to the Sentry -> Linear -> Codex example. No reminder/routine is added in v1 because there is not yet drift evidence.

## Deviations

_None yet._

## Tradeoffs

### 2026-06-08 - parent - passive surface over automation

The shipped surface is intentionally passive. It gives consumers a high-friction manual/dry-run starting point, which is less ergonomic than a webhook or skill but keeps Agent0 out of production operations and avoids pretending one provider stack is the architecture.

## Open questions

Resolved in `spec.md`; no deferred acceptance criteria.
