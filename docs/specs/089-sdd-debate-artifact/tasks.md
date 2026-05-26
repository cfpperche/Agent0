# 089 — sdd-debate-artifact — tasks

_Generated from `plan.md` on 2026-05-25. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create `.claude/skills/sdd/templates/debate.md.tmpl` with canonical structure: header (slug, date, broker, stop criteria), 3 round placeholders, `## Synthesis`, `## Applied changes`
- [x] 2. Update `.claude/skills/sdd/SKILL.md` frontmatter: add `debate` to `description` (subcommand list) and `argument-hint`
- [x] 3. Update `.claude/skills/sdd/SKILL.md` body: add `## Subcommand: debate — 🔓 Medium freedom: scaffold + orchestrate broker loop` section between `tasks` and `list`; include parsing rule, refusal cases, scaffold step, broker instruction, round-handling protocol, convergence + 3-round-cap stop criteria
- [x] 4. Update `.claude/skills/sdd/SKILL.md` § Unknown subcommand usage hint to include `debate`
- [x] 5. Update `.claude/skills/sdd/SKILL.md` § Eval Scenarios with Eval 4: debate happy path
- [x] 6. Update `.claude/rules/spec-driven.md`: rename § The four artifacts → § The artifacts; add `debate.md` paragraph; add optional step 1.5 to § Workflow
- [x] 7. Dogfood: run `/sdd debate` against this very spec (089) — verify `debate.md` scaffolds, Round 1 pre-populates from `spec.md` key claims, broker instruction is clear

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] `ls .claude/skills/sdd/templates/debate.md.tmpl` returns the file (Scenario: scaffold debate.md — static fact)
- [x] `grep -E 'debate' .claude/skills/sdd/SKILL.md | head -5` shows the subcommand in frontmatter `description` and in body H2 (acceptance criterion: SKILL.md updated)
- [x] `grep -E 'The artifacts' .claude/rules/spec-driven.md` matches (acceptance criterion: rule renamed)
- [x] `grep -c 'debate.md' .claude/rules/spec-driven.md` ≥ 2 (acceptance criterion: rule mentions debate.md in artifacts list and workflow step)
- [x] Dogfood invocation produces `docs/specs/089-sdd-debate-artifact/debate.md` with Round 1 populated, `{{` placeholders all substituted, and broker instruction emitted to user (covers Scenarios: scaffold + prompt human broker)
- [x] Re-invoking `/sdd debate` on the same spec refuses with "debate already in flight" (Scenario: refuse mid-debate re-invocation)
- [x] After dogfood verification, tick all acceptance boxes in `spec.md` and flip `**Status:**` to `shipped`

## Notes

- The dogfood step (task 7) is the same self-test pattern as 087-skill-rubric and 086-memory-cap-query-decay — confirms the capacity works against itself before declaring shipped.
- No new env var, no new hook, no new dependency. The "implementation" is markdown + one new template file.
- After ship, add a reminder for the rule-of-three demand test: if ≥3 debates produce real spec edits over the next ~60 days, scope a follow-up spec for broker-script (direct API) promotion. Until then, broker-human is the answer.
