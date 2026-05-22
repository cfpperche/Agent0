# 060 — harness-gaps-2026 — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Scaffold `docs/specs/061-subagent-stop-hook/{spec,plan,tasks,notes}.md` — top pick #1
- [x] 2. Scaffold `docs/specs/062-goal-skill/{spec,plan,tasks,notes}.md` — top pick #2
- [x] 3. Scaffold `docs/specs/063-worktree-isolated-subagents/{spec,plan,tasks,notes}.md` — top pick #3
- [x] 4. Edit `.claude/rules/spec-driven.md` § The four artifacts to document `**Type:** umbrella` convention (one paragraph; values: omitted default, `umbrella` = aggregator)
- [x] 5. Add reminder to `.claude/REMINDERS.md`: "review §A/§B medium-priority rows in spec 060 after first child ships" (due 2026-07-19)
- [x] 6. **Re-evaluate §A4-A8 + §B4/B8 priorities** — DONE 2026-05-21 (061 + 063 shipped). Matrix Outcome column updated: A6 + A8 **closed**, B8 **deferred** (reasons inline), A4/A5/A7 kept pending for the 2026-07-19 review batch, B4 marked **recommended next spec**. The "scaffold the next batch" clause is deliberately NOT done as a bulk-scaffold — per `notes.md` § Tradeoffs (2026-05-19), empty draft specs rot and the matrix is the single source of truth; a spec is scaffolded only when it becomes the active next unit. Full re-evaluation in `notes.md` § Design decisions (2026-05-21). (§B1/B7 from the original task-6 list were already resolved — folded into 061/062 — so the live scope was A4-A8 + B4 + B8.)
- [x] 7. Schedule next competitive harness audit (2026-08-19) via `/remind` skill

## Verification

- [ ] Every row in §A of `spec.md` has either a `→ NNN` link OR an inline `closed: <reason>` marker
- [ ] Every row in §B has either `→ NNN`, `closed: <reason>`, or `deferred: <re-evaluate condition>`
- [x] `.claude/rules/spec-driven.md` mentions the `**Type:**` field with values listed
- [x] Specs 061/062/063 exist with valid spec.md/plan.md/tasks.md/notes.md (scaffolded at draft; 061 + 063 since shipped, 062 superseded)

## Notes

The umbrella will likely sit in `draft` for weeks while child specs ship. That is expected — `shipped` requires all §A+§B rows resolved, which is multi-month work. The umbrella `shipped` state is bookkeeping, not a deliverable.
