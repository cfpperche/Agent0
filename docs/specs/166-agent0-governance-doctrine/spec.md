# 166 - agent0-governance-doctrine

_Created 2026-06-07._

**Status:** shipped

**UI impact:** none

## Intent

Codify the strategic governance doctrine discussed in the 2026-06-07 Agent0 future brainstorm: Agent0 should continue as a stack-neutral template/governance harness for software projects, not become a product surface by default. The doctrine gives future Agent0 expansion work a clear boundary: use a layered governance model, separate security from quality, treat software evolution as continuous, and require explicit scope-admission discipline before adding new first-party capacities.

## Acceptance criteria

- [x] **Scenario: future expansion has a boundary rule**
  - **Given** a future Agent0 change proposes a new first-party capacity, category, or governance mechanism
  - **When** the agent reads the Agent0 governance doctrine rule
  - **Then** the rule states that Agent0 remains a stack-neutral template/governance harness and defines how to decide whether the change is owned, instrumented, or ignored by Agent0

- [x] **Scenario: taxonomy is layered, not flat**
  - **Given** a maintainer is classifying governance expansion work
  - **When** they use the doctrine rule
  - **Then** it distinguishes the continuous-evolution spine, quality/security domains, context/replication substrate, multi-runtime transversal constraint, and scope-admission meta-governance

- [x] **Scenario: security is first-class**
  - **Given** a governance proposal touches secrets, vulnerable dependencies, permissions, sensitive data, exposed surfaces, or adversarial risk
  - **When** the doctrine is applied
  - **Then** security is treated as a first-class lane with different failure economics from quality, not as a sub-bucket of quality

- [x] **Scenario: product drift is blocked at doctrine level**
  - **Given** a proposal would make Agent0 own consumer release, operation, deployment, runtime observability, or a product dashboard
  - **When** the doctrine is applied
  - **Then** the proposal is framed as out of scope unless future evidence satisfies the scope-admission discipline

- [x] `docs/specs/166-agent0-governance-doctrine/{spec,plan,tasks,notes}.md` exists with no template placeholders.
- [x] `.agent0/context/rules/agent0-governance-doctrine.md` exists and is referenced by both root entrypoints' Agent0 managed block.
- [x] The change adds no new hook, tool, validator, runtime, product surface, or consumer sync apply.

## Non-goals

- Build a product, daemon, dashboard, SaaS surface, release runner, deployment primitive, or operational control plane.
- Add or harden gates, validators, hooks, tools, or sync behavior in this spec.
- Define detailed implementation specs for `scope-admission-governance`, `gate-algebra`, `security-governance-lane`, or `continuous-evolution-spine`; those remain candidate follow-ups.
- Propagate the new doctrine to consumer projects during this spec; sync is an explicit operator action.

## Open questions

- [ ] Should the future `scope-admission-governance` follow-up stay rule-only, or should it eventually gain a lightweight checker after enough repeated demand?
- [ ] Should the future `gate-algebra` follow-up unify vocabulary only, or also refactor existing gates around a shared data model?

## Context / references

- `.agent0/.brainstorm-state/futuro-do-agent0-2026-06-07T22-27-26Z.html` - rendered brainstorm artifact.
- `.agent0/.brainstorm-state/futuro-do-agent0-2026-06-07T22-27-26Z.json` - source brainstorm state.
- `.agent0/.runtime-state/claude-exec/20260607T223905Z-agent0-future-taxonomy/last-message.md` - Claude second-opinion critique.
- `.agent0/context/rules/spec-driven.md` - spec artifact and status conventions.
- `.agent0/context/rules/runtime-capabilities.md` - precedent for honest runtime capability mapping.
- `.agent0/context/rules/harness-sync.md` - Agent0/consumer boundary and shipped-surface vocabulary.
- `.agent0/context/rules/secrets-scan.md` and `.agent0/context/rules/vuln-audit.md` - existing evidence that security uses distinct controls from quality.
