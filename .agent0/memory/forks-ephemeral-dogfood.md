---
name: Forks are ephemeral dogfood
description: Capacity docs' "forks" framing is forward-looking; current reality is
  all forks are spun-up-then-archived dogfood projects. Hard-cutover is the default
  back-compat posture.
metadata:
  type: project
  created_at: '2026-05-17T22:14:43-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---
# Forks are ephemeral dogfood projects

When Agent0 capacity docs (CLAUDE.md, `.claude/rules/*.md`, sync-harness, MCP READMEs) reference "forks", the term is **forward-looking framing**, not a description of an active ecosystem.

**Reality (founder-confirmed 2026-05-17):** all projects cited as "forks" of Agent0 are **ephemeral, used solely for dogfooding the project itself**. No production consumer base, no third-party adopters, no long-lived downstream copies. Forks are spun up to validate new capabilities, archived once their purpose is served, and the harness-sync tool (spec 016) is mostly a forward-pointing capability rather than a tool with active users.

## Implications for design decisions

- **Backward-compatibility:** Hard cutover is the default posture for breaking changes. Deprecation phases and `pipelineVersion`-style runtime version switches are over-engineering until evidence shows otherwise. Documented in spec 032 § Q6 reasoning (chose hard cutover for the pipeline reshape).
- **Migration friction:** Acceptable. A future fork (if one materializes) reads migration notes + re-cherry-picks. Cost is theoretical.
- **Pre-1.0 versioning:** Stay 0.x until a real adopter ships in production. `0.1.0 → 0.2.0` semantics is "still calibrating", not "stable release".
- **Capacity propagation paths:** Different from fork-count reality. `.claude/rules/` and `.claude/hooks/` DO ship to any hypothetical fork via sync-harness — they need to be correct + portable even if no fork exists yet. The propagation channel is real even when the consumer base is empty.

## What this is NOT

- NOT a license to ignore the sync-harness manifest. The capacity docs ride the harness; they must remain correct even with zero forks.
- NOT a license to drop versioning entirely. Version bumps + migration notes are cheap to maintain even at zero adopters; they're the affordance the system needs when the first real fork lands.
- NOT a permanent fact. If a third party ever forks Agent0 in earnest (a partner adopts the MCP for production planning, a sibling project depends on `.claude/rules/`), this fact flips — and back-compat posture should flip with it.

## Recurring signal

The user has flagged this 3+ times in different decision contexts (sync-harness back-compat, MCP version bump in 032). When future specs propose deprecation infrastructure or compat shims "for forks", check this memory first — the cost is real, the benefit is hypothetical.

See also: [[feedback_agent0_changes_ship_via_rules_not_memory]] (user-memory) — the inverse rule, about what DOES ship: `.claude/rules/` propagates, `.agent0/memory/` stays project-local.
