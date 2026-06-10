---
name: memory-placement-maintenance
description: Maintainer audit narratives and split-vs-move-full disposition criteria that established the three-bucket memory model.
metadata:
  type: project
  created_at: '2026-06-10T00:00:00-03:00'
---
# Memory placement maintenance

Extracted from `.agent0/context/rules/memory-placement.md` — maintainer-binding design context that established the three-bucket model. The rule itself carries the operative routing rubric; this entry carries the archaeology and disposition criteria for future borderline audits.

## Why three buckets, not two

The previous version of the rule had only two buckets: project-shared (rules) and per-user (preferences). That model conflates two distinct kinds of project-shared knowledge: behavioral mandates that should ride with capacities into consumer projects, and factual reference that's project-internal design context. Three empirical triggers established the current shape:

1. **CC-32-hooks discovery.** Claude Code has 32 hook events (not the ~9 commonly cited). That knowledge is project-shared (other Agent0 contributors benefit), NOT a behavioral mandate (it's reference data), and SHOULD NOT ship to consumer projects (consumer projects consume capacities, they don't extend the harness). No existing bucket fit.
2. **The 2026-05-27 maintainer-rules-to-memory audit (spec 096).** Three rules (`hook-chain-latency.md`, `compaction-continuity.md`, `rule-load-debug.md`) documented capacity internals that only the upstream maintainer ever acts on — budgets to defend when adding a new hook, the PreCompact/SessionStart mechanism to preserve when editing the snapshot pair, opt-in observability for diagnosing path-scoped loads. They were drifting into consumer-project context noise. Moving them to memory removed that drift AND surfaced the criterion the routing tree names explicitly. **This is the canonical case for the `move-full` disposition** — entire rule routes to memory because zero consumer-binding content exists.
3. **The 2026-05-27 borderline-rules-disposition audit (spec 097).** Three rules (`runtime-capabilities.md`, `propagation-advisory.md`, `runtime-introspect.md`) mixed consumer-binding sections (status vocabulary the agent consults, override grammar the agent invokes, probe output shape the agent pattern-matches, env-var contracts the agent honours) with maintainer-binding sections (update rule + drift-check anchors, regex pattern table + shipped-surface set + audit-log policy, env-var extension contract + per-detector inference heuristics + dogfood archaeology). **This is the canonical case for the `split` disposition** — the rule retains its consumer-facing slice at `.agent0/context/rules/<slug>.md`, and a maintenance companion carries the maintainer-binding content. The cross-link is one `## Maintenance` section in the rule pointing at the memory companion. Precedent file pair: the runtime-capabilities rule and its maintenance companion. (`propagation-advisory` was originally the split precedent, but its rule slice documented a maintainer-only, sync-excluded mechanism and later moved fully to memory under the audience test — consumer-facing content is the admission criterion for a rule file.)

## Split-vs-move-full criterion for future borderline audits

When a rule mixes consumer-binding sections (override grammar, env vars, behavior the agent invokes) with maintainer-binding sections (extension contracts, internal mechanism, drift tooling), the right disposition is **split** into a thin consumer-facing rule + a `<slug>-maintenance.md` memory companion. Move-full only when ZERO consumer-binding content exists. Keep-as-is only when a re-audit shows the maintainer-binding sections are themselves consumer-relevant (rare — the canonical sign is that the consumer-side agent actively loads the section to inform its own behavior, not the maintainer extending the capacity).

The `.agent0/memory/` bucket covers all three trigger classes — pure-reference (CC-32-hooks), full-rule reclassification (spec 096), and split companions (spec 097).
