---
name: runtime-capabilities-maintenance
description: Maintainer discipline for the runtime-capabilities matrix — Update rule + drift enforcement + skill-portability relationship.
metadata:
  type: project
  created_at: '2026-05-27T00:00:00Z'
  last_accessed: '2026-05-27'
  confirmed_count: 0
---
# Runtime capabilities maintenance

Maintainer-binding companion to `.agent0/context/rules/runtime-capabilities.md`. The companion rule carries the status vocabulary + the capability matrix consumers consult; this memory carries the discipline the upstream maintainer applies when changing runtime support for a capability or when wiring the drift check.

## Update rule

Every future spec that changes runtime support for a capability must update `.agent0/context/rules/runtime-capabilities.md` in the same change. New capability rows may be added without expanding the drift check's minimum-required-labels set; that set grows only when a follow-up spec explicitly promotes a row to the minimum.

## Drift enforcement

`.agent0/tools/check-instruction-drift.sh` protects the anchor-level contract without parsing per-cell values:

- The registry file exists.
- `CLAUDE.md` and `AGENTS.md` managed blocks point to this file.
- The legacy `## Codex Capability Tiers` table is absent from `AGENTS.md`.
- The six status vocabulary terms appear in this file.
- Minimum-set capability labels appear as table rows without duplicates.

Extra rows are permitted. Duplicate minimum-set rows are drift.

## Skill portability relationship

`.claude/skills/skill/references/portability-tiers.md` is a separate axis: it describes skill-body portability (`cc-native`, `agentskills-portable`, `runtime-agnostic`). The runtime-capabilities registry describes runtime support for Agent0 capabilities. Skill rows may cite skill portability tiers as evidence, but the registry does not replace per-skill frontmatter or the portability-tier policy.

## Cross-references

- `.agent0/context/rules/runtime-capabilities.md` — consumer-facing companion (status vocabulary + matrix + future-runtimes placeholders)
- `.agent0/tools/check-instruction-drift.sh` — the drift enforcement implementation
- `docs/specs/093-runtime-capability-registry/spec.md` § *Scenario: users can inspect one canonical capability matrix* — the source of truth for the minimum-set list embedded in the drift checker
- `.claude/skills/skill/references/portability-tiers.md` — the separate skill-portability axis
