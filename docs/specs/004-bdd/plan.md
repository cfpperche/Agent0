# 004 — bdd — plan

_Drafted from `spec.md` on 2026-05-10. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two surgical changes plus a smoke verification — no code, no hooks, no tooling.

1. **Rewrite the acceptance section of `.claude/skills/sdd/templates/spec.md.tmpl`** to use the canonical scenario shape (nested sub-bullets), with a brief inline note that plain checkbox bullets remain valid for static-fact criteria. The rest of the template (Intent / Non-goals / Open questions / Context) is unchanged.

2. **Extend `.claude/rules/spec-driven.md`** with a new `## Acceptance scenarios` h2 section that documents: (a) the canonical Given/When/Then nested shape; (b) the inline-prose alternative for short scenarios; (c) when to use a plain checkbox bullet instead (static-fact criteria — file exists, bit set, JSON parses); (d) the mixed-shape allowance (scenarios + plain bullets in the same spec). Also fix the existing one-line description on line 31 from "acceptance criteria as a checklist" to mention scenarios.

3. **Smoke check** by running `/sdd new <throwaway>` and confirming the new template renders with scenario placeholders, then deleting the throwaway. This is the empirical proof that scenario 1 of the spec ("SDD scaffolds with scenario-shaped acceptance template") holds.

The pattern intentionally mirrors how 003-reminders shipped: a writing-discipline change touching the smallest surface that can carry the discipline forward. No `PreToolUse` is added because there is no behavior to gate — the discipline is *what* gets written into spec.md, not *whether* it gets written.

## Files to touch

**Modify:**
- `.claude/skills/sdd/templates/spec.md.tmpl` — replace the `## Acceptance criteria` body. Old shape (3 generic placeholder bullets) → new shape (one scenario placeholder in nested form + one plain checkbox placeholder + a one-line inline comment explaining when each is appropriate). Total delta: ~10 lines.
- `.claude/rules/spec-driven.md` — append a new `## Acceptance scenarios` section (~30-40 lines) before the existing `## Relationship to other rules` section. Tweak the one-line "acceptance criteria as a checklist" mention on line 31 to read "acceptance criteria as scenarios or a checklist".

**Create:** none.

**Delete:** none.

## Template change — concrete shape

Note on notation in this section: the actual `.tmpl` file will use double-curly placeholders that `/sdd new` substitutes (matching the existing template convention — the metadata placeholders for NNN, SLUG, DATE, plus content slots like `intent`, `criterion 1`, etc., all delimited by the same double-curly syntax used across the other `.tmpl` files in this repo). Below, the example blocks use angle-bracket notation purely so this plan document does not itself contain unfilled-template-placeholder substrings that would confuse downstream `/sdd` parsing.

The current `## Acceptance criteria` block in `spec.md.tmpl`:

```markdown
## Acceptance criteria

_A checklist of observable outcomes. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan._

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>
```

becomes:

```markdown
## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan. See `.claude/rules/spec-driven.md` § Acceptance scenarios for shape guidance._

- [ ] **Scenario: <scenario 1 title>**
  - **Given** <precondition>
  - **When** <action>
  - **Then** <observable outcome>

- [ ] **Scenario: <scenario 2 title>**
  - **Given** <precondition>
  - **When** <action>
  - **Then** <observable outcome>

- [ ] <plain criterion — for static facts that don't fit scenario shape>
```

Three placeholder slots: two scenario shells + one plain bullet. Signals to the spec author that both shapes are first-class.

## Rule change — section to add

Insert before the `## Relationship to other rules` section in `.claude/rules/spec-driven.md`:

```markdown
## Acceptance scenarios

The acceptance section of `spec.md` should describe **observable behavior** in Given/When/Then scenarios. A scenario is a contract a verifier (human or sub-agent) can mirror directly into `tasks.md`'s verification steps.

### Canonical shape — nested sub-bullets

- [ ] **Scenario: <short title>**
  - **Given** <precondition: state that must hold>
  - **When** <action that triggers the behavior>
  - **Then** <observable outcome: what becomes true / visible>

### Compact shape — inline prose

For short scenarios that fit on one line:

- [ ] **Scenario: <title>** — **Given** <precondition>; **When** <action>; **Then** <outcome>

Use the nested shape by default; switch to inline only when the scenario is genuinely one-line.

### Plain bullets — for static-fact criteria

Not every criterion is a behavior. Existence checks, executable bits, JSON parses, file paths — these are static facts. Use a plain checkbox bullet:

- [ ] `<concrete static fact, e.g. .claude/hooks/foo.sh exists and is executable>`

Mixing scenario bullets with plain bullets in the same `## Acceptance criteria` is expected and correct. Do not force a static fact into Given/When/Then; do not write a behavior as a flat bullet.

### Why this shape

- A scenario is **executable in prose**: a sub-agent dispatched (via the 002-delegation gate) with a 5-field brief whose DELIVERABLE references "scenario N from `docs/specs/NNN-<slug>/spec.md`" can construct the verification without follow-up clarification.
- The Given/When/Then split prevents the common failure mode where an acceptance bullet describes *what* without *when* — the verifier then has to infer the precondition and trigger from plan.md or conversation.
- Tasks.md verification steps map 1:1 from scenarios: each scenario becomes one task that asserts the Then under the Given/When.

### What this does NOT introduce

This is a writing discipline. There is no Cucumber, no Gherkin parser, no test-runner integration, no hook that validates `spec.md` shape. Scenarios are prose; their value is clarity for the next reader (often a sub-agent), not machine consumption. Specs 001-003 keep their flat-checklist shape — `git log` is the audit trail, not a rewrite.
```

The "Why this shape" paragraph cross-references 002-delegation; that's the load-bearing reason for the discipline (sub-agent briefs become tighter when acceptance is scenario-shaped).

## Alternatives considered

### Adopt Cucumber / a Gherkin parser

Rejected. Spec explicitly forbids: "no Cucumber, no Gherkin parser, no test-runner integration." Reason: Agent0 is a base template with no language stack; pulling in a Ruby/JS dep just for spec-shape parsing would be premature and lock the template to a particular ecosystem. The prose shape is forward-compatible — if a real project later adopts Cucumber, scenarios are already in a near-migrate-ready form.

### Standalone `/bdd` skill alongside `/sdd`

Rejected. Spec explicitly: "BDD is a *shape* of `/sdd`'s output, not a parallel workflow." A separate skill would fragment the surface — users would have to remember which one to invoke for which kind of work. The `/sdd` workflow is the only entry point for non-trivial work; BDD evolves what `/sdd` produces.

### Retroactively rewrite specs 001-003 to scenario shape

Rejected. Spec explicitly: "no retroactive rewrite of specs 001-003." Reason: their flat checklists are the historical record of the design at the time. Rewriting would erase the evolution and create confusion about what was actually written when each capacity shipped. New specs from 004 onward adopt scenarios; old ones stay as-is.

### Add a `Background` shared-Given section

Considered (open question 2 in spec). Rejected for this iteration. Cucumber's Background is useful when scenarios share a precondition; in our specs so far, repetition has not been a real pain point. Revisit only if multiple specs feel painfully redundant. Adding the section now would commit a shape change without evidence it earns its keep.

### Split `.claude/rules/bdd.md` from `spec-driven.md`

Considered (open question 3 in spec). Rejected. Two related disciplines in two files invites readers to miss the connection. Folding `## Acceptance scenarios` into `spec-driven.md` keeps the workflow + shape rules co-located. If BDD ever generalizes beyond `/sdd` (e.g., test-naming conventions), spinning it out becomes warranted; until then, one file.

### Hook that validates `spec.md` shape (e.g., PostToolUse(Edit) on `docs/specs/**/spec.md`)

Rejected. Spec explicitly: "No new hook." A hook that policed scenario shape would either reject valid plain bullets (false positive) or be lenient enough to be useless. The discipline lives in the rule + template; enforcement is conventional. The next time a sub-agent reads `spec.md`, it sees the shape and continues it.

## Risks and unknowns

- **Verbosity for trivial specs.** A 5-bullet checklist might become a 20-line scenario block. Mitigation: the template offers plain bullets for static facts, and the rule actively encourages using them — scenarios are for behavior, not every line. If a spec ends up all-scenarios for trivial items, the spec author is misusing the shape; the rule should be clear enough to prevent this. Revisit if early specs feel bloated.
- **Inline-vs-nested drift.** With both shapes accepted, different authors will pick differently and specs may look inconsistent. Accepted: consistency within a spec matters more than across specs, and the rule says "default nested, inline for short". A future style-lint could enforce one shape, but that's premature.
- **The 5-field delegation brief assumption.** Scenario 5 of the spec assumes a sub-agent dispatched with `DELIVERABLE: verify scenario N from spec X` can do its job from the scenario alone. Plausible but not yet observed in production — verification task will exercise this concretely with a real (small) dispatch.
- **No hook means no enforcement, which means drift.** Over time, spec authors might forget the scenario shape and revert to flat checklists. Mitigation: the template defaults to the new shape, so scaffolded specs start scenario-shaped. The rule documents the discipline. Conventional enforcement is sufficient for a small project; reconsider only if drift is observed across many specs.
- **Acceptance criterion 5 (sub-agent verifies scenario directly) is hard to falsify cheaply.** Will exercise it with a tiny live dispatch in the verification phase, but a "scenario was clear enough" signal is qualitative.

## Research / citations

- `docs/specs/004-bdd/spec.md` — primary source for intent and the open-question defaults.
- `.claude/rules/spec-driven.md` — current rule being extended; the existing structure (h2 sections, terse imperative tone) is the style guide for the new section.
- `.claude/skills/sdd/templates/spec.md.tmpl` — current template being modified.
- `docs/specs/002-delegation/` — drives the load-bearing reason scenarios matter (5-field briefs become tighter when acceptance is scenario-shaped). The `## Acceptance criteria` of 002-delegation is referenced as the comparison "before" shape.
- BDD background (informational reference, no tooling adoption): Dan North, *Introducing BDD* (2006); the Cucumber project's Given/When/Then conventions. Cited here so future readers understand the shape's lineage; this spec does not adopt the tooling.
- `.claude/rules/research-before-proposing.md` — the open-question phase consulted no external sources beyond the BDD references above; the design is small enough that conventions and prior internal patterns (specs 001-003) carry the weight.
