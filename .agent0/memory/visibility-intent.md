---
name: Visibility capacity intent
description: User's stated goal for the next visibility/introspection capacity in
  Agent0 — agent self-debugging, not human dashboards
metadata:
  type: project
  created_at: '2026-05-11T19:33:20-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---
User's articulated intent (2026-05-11): the next "visibility" wedge in Agent0 should let the **agent itself** see/debug what it's implementing at runtime, so it does NOT depend on human ratification and does NOT rely solely on static-code reading.

**Why:** human-in-the-loop ratification is the current bottleneck; trusting static code alone misses runtime state (real DB schema vs. migration intent, last-error after an edit, dev-server log after a save, DOM after a frontend change). The zydrex `laravel-boost` MCP was the trigger reference — framework-specific runtime introspection.

**How to apply:** scope future visibility specs around evidence the *agent* consumes mid-task (introspection MCPs the agent queries, hook-injected runtime hints, transcript self-query), NOT around OTel/Grafana dashboards a human reviews after the fact. The observability-for-humans angle is acknowledged as valuable but explicitly de-prioritised for this wedge. The capacity must be generic enough to ship in Agent0 base template (works on any fork's stack), not Laravel-specific.

Resolved: spec 011 (runtime-introspect) realized this intent for the local test/build probe wedge (later removed in spec 116 — the SubagentStop validator + inline Bash output subsumed it); spec 012 (mcp-recipes) for adoption of external MCPs (Playwright, DBHub, etc.). Future visibility capacities (transcript self-query, DB introspection in pyshrnk, dev-server log forwarding) continue under this framing.
