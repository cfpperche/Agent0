# 166 - agent0-governance-doctrine - plan

_Drafted from `spec.md` on 2026-06-07. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship this as a documentation-first doctrine spec. The concrete artifact is a new context rule that future agents can consult before expanding Agent0 capacities. Root entrypoints get a short managed-block pointer so the doctrine is visible early, while the detailed rule carries the actual decision model.

Keep v1 deliberately non-mechanical: no hooks, validators, scripts, sync applies, or hard gates. The output should constrain future specs, not implement any of the candidate follow-up mechanisms yet.

## Files to touch

**Create:**
- `.agent0/context/rules/agent0-governance-doctrine.md` - canonical governance doctrine rule.
- `docs/specs/166-agent0-governance-doctrine/spec.md` - intent and acceptance criteria.
- `docs/specs/166-agent0-governance-doctrine/plan.md` - implementation plan.
- `docs/specs/166-agent0-governance-doctrine/tasks.md` - execution checklist.
- `docs/specs/166-agent0-governance-doctrine/notes.md` - in-flight design memory.

**Modify:**
- `CLAUDE.md` - add managed-block pointer to the doctrine.
- `AGENTS.md` - mirror the same managed-block pointer for Codex.
- `.agent0/HANDOFF.md` - refresh session state after the doctrine lands.
- `.agent0/.brainstorm-state/futuro-do-agent0-2026-06-07T22-27-26Z.json` - finalize the brainstorm state.

**Delete:**
- None.

## Alternatives considered

### Build a product-facing Agent0 surface now

Rejected because the user explicitly does not yet see the product. Starting with a product surface would outrun the observed pain and conflict with Agent0's current base-template purpose.

### Add a scope-admission gate immediately

Rejected because the current discussion produced doctrine, not enough repeated operational evidence for a new hard gate. The rule-of-three discipline should be documented before it becomes enforcement.

### Keep the six governance categories as a flat list

Rejected because the Claude critique surfaced a real modeling issue: continuous evolution is a temporal spine, multi-runtime is a transversal constraint, and context/replication are substrate rather than peer domains.

## Risks and unknowns

- The doctrine could become vague slogan text if it does not include concrete expansion questions and boundaries.
- Over-indexing on doctrine could slow legitimate future specs if it reads like a veto instead of a classification tool.
- Root entrypoint edits require managed-block parity checks so Claude and Codex do not drift.
- The future gate-algebra and scope-admission topics may deserve separate specs, but should not leak into this implementation.

## Research / citations

- `.agent0/.brainstorm-state/futuro-do-agent0-2026-06-07T22-27-26Z.json`
- `.agent0/.runtime-state/claude-exec/20260607T223905Z-agent0-future-taxonomy/last-message.md`
- `.agent0/context/rules/spec-driven.md`
- `.agent0/context/rules/runtime-capabilities.md`
- `.agent0/context/rules/harness-sync.md`
- `.agent0/context/rules/secrets-scan.md`
- `.agent0/context/rules/vuln-audit.md`
