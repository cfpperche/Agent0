---
name: Agent0 core thesis
description: Agent0 intentionally avoids becoming an agent/skill catalog; durable value is prompt engineering, context engineering, and governance.
metadata:
  type: project
  created_at: '2026-05-26'
  last_accessed: '2026-05-26'
  confirmed_count: 1
---
# Agent0 core thesis

Decision confirmed by the user on 2026-05-26: Agent0 should not compete by accumulating many agents and skills. That layer ages quickly as frontier models improve; specialized personas and compensating prompts that were useful for one model generation often become stale or counterproductive in the next.

Agent0's durable value is:

- **Prompt engineering**: concise, high-signal prompts and reusable prompt contracts for planning, review, audit, debate, and implementation framing.
- **Context engineering**: specs, notes, handoff, memory, capability registry, runtime entrypoints, and loading discipline that give any capable coding agent the right context at the right time.
- **Governance**: hooks, gates, drift checks, sync discipline, validation, secrets controls, and release criteria that keep agent work auditable and bounded.

How to apply:

- Treat new first-party agents/skills as exceptions, not growth strategy.
- Add a skill only when it encodes a stable protocol or durable workflow, not a temporary workaround for current model weakness.
- Prefer improving prompts, context shape, evidence flow, and guardrails before adding a persona or specialist agent.
- Keep multi-runtime work focused on transparent capability mapping and governance parity, not mirroring every Claude-specific agent/skill surface into Codex.

Strategic contrast: systems like MetaSwarm, Maestro, SuperClaude, and large plugin marketplaces compete by breadth of agents/skills. Agent0 should stay narrower: a provider-neutral harness for disciplined software work, where the model can improve without forcing the framework to carry obsolete orchestration scaffolding.
