# 060 — harness-gaps-2026 — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Scaffold `docs/specs/061-subagent-stop-hook/{spec,plan,tasks,notes}.md` — top pick #1
- [x] 2. Scaffold `docs/specs/062-goal-skill/{spec,plan,tasks,notes}.md` — top pick #2
- [x] 3. Scaffold `docs/specs/063-worktree-isolated-subagents/{spec,plan,tasks,notes}.md` — top pick #3
- [x] 4. Edit `.claude/rules/spec-driven.md` § The four artifacts to document `**Type:** umbrella` convention (one paragraph; values: omitted default, `umbrella` = aggregator)
- [x] 5. Add reminder to `.claude/REMINDERS.md`: "review §A/§B medium-priority rows in spec 060 after first child ships" (due 2026-07-19)
- [ ] 6. After 061 ships, re-evaluate §A4-A8 + §B1/B4/B7/B8 priorities — scaffold the next batch of follow-up specs based on updated signal
- [x] 7. Schedule next competitive harness audit (2026-08-19) via `/remind` skill

## Verification

- [ ] Every row in §A of `spec.md` has either a `→ NNN` link OR an inline `closed: <reason>` marker
- [ ] Every row in §B has either `→ NNN`, `closed: <reason>`, or `deferred: <re-evaluate condition>`
- [ ] `.claude/rules/spec-driven.md` mentions the `**Type:**` field with values listed
- [ ] Specs 061/062/063 exist with `**Status:** draft` and valid spec.md/plan.md/tasks.md/notes.md

## Notes

The umbrella will likely sit in `draft` for weeks while child specs ship. That is expected — `shipped` requires all §A+§B rows resolved, which is multi-month work. The umbrella `shipped` state is bookkeeping, not a deliverable.
