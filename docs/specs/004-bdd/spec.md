# 004 — bdd

_Created 2026-05-10._

**Status:** shipped

## Intent

Evolve the `/sdd` workflow so every spec's acceptance section captures **observable behavior** in Given/When/Then scenarios instead of a flat checklist of outcomes. The shape is BDD-inspired prose (no Cucumber, no parser, no test-runner integration) — a writing discipline that makes each acceptance criterion *executable in prose*: a sub-agent reading the spec can map directly from "what state must hold" + "what action triggers" + "what becomes observable" to a verification step in `tasks.md`.

This addresses three friction points observed across specs 001-003:

1. **Acceptance bullets that say *what* without *when***. Items like "validator missing → fails open" are correct but compressed; the *given/when* context lives in plan.md or the conversation, forcing a reader to cross-reference. Scenarios pull that context inline.
2. **Verification tasks invent their own framing.** When `tasks.md` is generated, the verification steps for each acceptance bullet are inferred ad hoc — sometimes by Claude, sometimes by the user. A scenario shape gives the verifier a stable contract to mirror (Given is the setup, When is the trigger, Then is the assertion).
3. **Sub-agents dispatched against acceptance criteria need to invent the precondition/action split themselves.** With the delegation gate (002) now requiring 5-field handoffs, a brief that includes a scenario in CONTEXT/DELIVERABLE collapses into "verify scenario N from spec X" — much tighter than restating the whole intent.

This is a writing-and-tooling change to the `/sdd` template + a clarifying rule update. No new hooks, no validator changes. The discipline only applies when SDD itself applies.

## Acceptance criteria

Acceptance for this spec is itself written in scenario form to dogfood the change. Each scenario must be demonstrable against the implemented template + rule.

- [ ] **Scenario: SDD scaffolds with scenario-shaped acceptance template**
  - **Given** a fresh repo with the updated `.claude/skills/sdd/templates/spec.md.tmpl`
  - **When** the user runs `/sdd new <slug>`
  - **Then** the generated `spec.md` contains a `## Acceptance criteria` section whose body is a scenario block (Given/When/Then), not a flat checkbox checklist

- [ ] **Scenario: Existing specs are not retroactively rewritten**
  - **Given** specs 001-003 already on `main` with flat acceptance checklists
  - **When** the BDD change is applied
  - **Then** their `spec.md` files remain unchanged (historical record); only newly-scaffolded specs adopt the scenario shape

- [ ] **Scenario: A criterion that does not fit scenario shape can be a plain bullet**
  - **Given** a spec where some acceptance items are about static facts (file exists, executable bit set, JSON parses) rather than behavior
  - **When** the spec author writes those items
  - **Then** the template explicitly permits mixing — scenarios for behavioral criteria, plain checkbox bullets for static-fact criteria — and the rule documents when each is appropriate

- [ ] **Scenario: SDD skip rule continues to govern when scenarios are required**
  - **Given** a change that the SDD rule classifies as "skip" (typo, rename, one-file fix)
  - **When** the user makes that change without invoking `/sdd new`
  - **Then** no scenarios are required — BDD applies only inside SDD's scope, never as a separate gate

- [ ] **Scenario: A delegated sub-agent can verify a scenario directly from `spec.md`**
  - **Given** a spec with a Given/When/Then scenario and a sub-agent dispatched (via the 002-delegation gate) with a 5-field brief whose DELIVERABLE references "scenario N from `docs/specs/NNN-<slug>/spec.md`"
  - **When** the sub-agent reads the spec
  - **Then** the scenario provides enough context (precondition, trigger, observable outcome) for the sub-agent to construct the verification without further clarification — no follow-up "what does done look like?" round-trip

## Non-goals

- **No Cucumber, Gherkin parser, or step-definition framework.** The shape is prose-readable Given/When/Then, not a tool stack. If a project later adopts Cucumber-style tooling, scenarios will already be in a compatible-enough shape to migrate without rewriting.
- **No test-runner enforcement.** TDD-style "fail first, then implement" is the scope of a separate spec (planned 005-tdd) reinforced by the existing `post-edit-validate.sh` validator. BDD here is a *spec-writing* discipline; whether tests exist for each scenario is not gated by this spec.
- **No retroactive rewrite of specs 001-003.** Their flat checklists stay as the historical record. The `git log` of acceptance-section changes is more honest than a rewrite.
- **No new hook.** The discipline lives in the template + rule; enforcement is conventional (the `/sdd` skill writes the new template, agents read the rule). No `PreToolUse` checks the format of `spec.md`.
- **No standalone `/bdd` skill.** BDD is a *shape* of `/sdd`'s output, not a parallel workflow. Adding a separate skill would fragment the surface.
- **No requirement that every criterion be a scenario.** Plain checkbox bullets remain valid for static-fact criteria (existence checks, bit flags). The template offers both shapes; the rule explains when each fits.

## Open questions

All three resolved 2026-05-10 by user approval of the suggested defaults:

- [x] **Bullet structure inside a scenario.** Default (a): nested sub-bullets — `- [ ] **Scenario: title**` followed by indented `- **Given** …`, `- **When** …`, `- **Then** …`. The rule documents this as the canonical shape and accepts the inline-prose alternative (b) for short scenarios that fit on a single line.
- [x] **`Background` shared-Given section.** Not supported in this iteration. Repetition across scenarios is acceptable; revisit only if multiple real specs feel painfully redundant after a few months of use.
- [x] **`.claude/rules/spec-driven.md` extension vs new `.claude/rules/bdd.md`.** Extend the existing rule with a `## Acceptance scenarios` h2 section. Keeps the spec-driven discipline in one file; avoids surface fragmentation.

## Context / references

- `.claude/rules/spec-driven.md` — the rule this spec evolves; new scenario shape becomes part of the workflow.
- `.claude/skills/sdd/templates/spec.md.tmpl` — the template this spec rewrites.
- `docs/specs/001-governance-gate/spec.md`, `docs/specs/002-delegation/spec.md`, `docs/specs/003-reminders/spec.md` — examples of the current flat-checklist shape; not modified, but useful comparison for the rule's "before/after" guidance.
- `docs/specs/002-delegation/` — drives criterion 5 (delegated sub-agent reads scenario as a brief input). The 5-field discipline established in 002 is what makes scenario-shaped acceptance valuable for delegation.
- Planned `docs/specs/005-tdd/` (not yet scaffolded) — companion spec that would address test-first enforcement via the validator. Out of scope for 004.
- BDD background reading (cite during plan phase if helpful): the original Dan North "Introducing BDD" essay; the Cucumber Given/When/Then conventions. Reference only — no tooling adoption implied.
