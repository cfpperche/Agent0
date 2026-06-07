# 167 - scope-admission-governance - plan

_Drafted from `spec.md` on 2026-06-07. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship a rule-only scope-admission discipline. The rule should be precise enough that future specs can use it as a checklist, but light enough that it does not create a new tracking system.

The implementation touches three documentation surfaces: the new rule, the parent governance doctrine, and the SDD rule. The parent doctrine points to the detailed scope-admission rule; SDD tells agents to consult it before writing specs that expand Agent0 capacities.

## Files to touch

**Create:**
- `.agent0/context/rules/scope-admission-governance.md` - first-class scope-admission rule.
- `docs/specs/167-scope-admission-governance/spec.md` - intent and acceptance criteria.
- `docs/specs/167-scope-admission-governance/plan.md` - implementation plan.
- `docs/specs/167-scope-admission-governance/tasks.md` - execution checklist.
- `docs/specs/167-scope-admission-governance/notes.md` - in-flight design memory.

**Modify:**
- `.agent0/context/rules/agent0-governance-doctrine.md` - link the new detailed rule and mark the follow-up as active/shipped.
- `.agent0/context/rules/spec-driven.md` - route Agent0 capacity specs through scope admission.
- `.agent0/HANDOFF.md` - refresh current state and next actions.

**Delete:**
- None.

## Alternatives considered

### Add a validator for admission sections

Rejected because there is not enough evidence that agents will skip the rule often enough to justify enforcement. V1 should make the discipline visible and then observe usage.

### Add a structured registry of capacity proposals

Rejected because reminders, routines, spec open questions, and notes already cover deferred intent. A registry would create maintenance overhead before the shape of repeated demand is known.

### Force every SDD spec template to include scope admission

Rejected because many specs are bug fixes, docs, refactors, or consumer-specific work. Scope admission applies to Agent0 capacity expansion, not every spec.

## Risks and unknowns

- If the rule is too broad, agents may treat it as ritual and rubber-stamp every proposal.
- If the rule is too strict, urgent safety fixes may wait for artificial repetition.
- The admission brief could drift into a second spec template; keep it as a compact checklist until repeated use proves a template change is worth it.
- Future hard gates need extra care because false-positive blocking in consumer projects is more expensive than advisory noise.

## Research / citations

- `docs/specs/166-agent0-governance-doctrine/spec.md`
- `.agent0/context/rules/agent0-governance-doctrine.md`
- `.agent0/context/rules/visual-contract.md`
- `.agent0/context/rules/routines.md`
- `.agent0/context/rules/artifact-budgets.md`
- `.agent0/context/rules/spec-driven.md`
