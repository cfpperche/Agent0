# 004 — bdd — tasks

_Generated from `plan.md` on 2026-05-10. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Rewrite `## Acceptance criteria` block in `.claude/skills/sdd/templates/spec.md.tmpl`** — done; template now scaffolds nested Given/When/Then scenarios + plain bullet for static facts. Intro line references `.claude/rules/spec-driven.md § Acceptance scenarios`.
- [x] 2. **Tweak the one-line acceptance description in `.claude/rules/spec-driven.md`** — done; line 31 now reads "acceptance criteria as scenarios or a checklist (see § *Acceptance scenarios* below)".
- [x] 3. **Append `## Acceptance scenarios` section to `.claude/rules/spec-driven.md`** — done; inserted before `## Relationship to other rules`. Section covers canonical nested shape, compact inline shape, plain-bullets-for-static-facts, "Why this shape" (cross-references 002-delegation), and "What this does NOT introduce" disclaimer.

## Verification

Each verification maps to a numbered scenario in `spec.md § Acceptance criteria`.

- [x] 4. **Verify scenario 1 (SDD scaffolds with scenario-shaped template)** — ran `/sdd new bdd-smoke-throwaway`, the rendered `docs/specs/005-bdd-smoke-throwaway/spec.md` `## Acceptance criteria` section was the exact new shape (nested Given/When/Then + plain bullet placeholders). Throwaway dir removed with `# OVERRIDE: ...` marker (governance gate confirmed working).
- [x] 5. **Verify scenario 2 (existing specs not retroactively rewritten)** — `git status --short docs/specs/001-governance-gate/ docs/specs/002-delegation/ docs/specs/003-reminders/` returned empty (zero modifications to those dirs). Only the template, rule, and 004-bdd files appear in the working diff.
- [x] 6. **Verify scenario 3 (mixed shape allowed)** — confirmed by inspection: lines 64-70 of `.claude/rules/spec-driven.md` explicitly permit plain checkbox bullets for static-fact criteria AND state that mixing scenarios with plain bullets is "expected and correct".
- [x] 7. **Verify scenario 4 (SDD skip rule still governs)** — confirmed by inspection: `## When to skip` (line 15) is intact and untouched; the new `## Acceptance scenarios` (line 45) is purely additive about *shape* and does not introduce a "you must scenario-ize all changes" gate. Scenarios apply iff SDD applies.
- [x] 8. **Verify scenario 5 (delegated sub-agent verifies a scenario from spec.md)** — load-bearing live test. Dispatched a sub-agent (agent_id `a7b747b14046ad143`) with a 5-field brief whose DELIVERABLE referenced "scenario 3 from `docs/specs/004-bdd/spec.md`". The sub-agent replied `PASS`, line range 64-70, with one-sentence reasoning that matched the independent inspection above — **with zero follow-up clarification, in 2 tool calls** (Read both files, then reply). Audit log gained an entry with `formatted=true, override=null, advisory_emitted=false`. The load-bearing claim of the spec is empirically validated.
- [x] 9. **Cleanup** — nothing to clean. Throwaway dir was removed in task 4. No state files were created (the cenário 5 sub-agent only Read; no Edit/Write triggered post-edit-validate). Audit log retains the cenário 5 entry as a real record (not test data).

## Notes

The verification batch was significantly cheaper than 002-delegation's: only one live Agent dispatch (task 8, the load-bearing scenario 5 test) plus a `/sdd new` smoke and four inspection checks. This is because BDD adds no runtime behavior — its impact is on the *next* spec author (human or agent), not on the harness.

Two minor wording fixes worth noting for future readers:

- The original `tasks.md` task 8 wording referenced "scenario 6 from `docs/specs/004-bdd/tasks.md`", but scenario 6 there is a verification task, not a Given/When/Then scenario. The actual dispatch (correctly) referenced scenario 3 from `spec.md`. The task description was checked-off as "intent satisfied" rather than rewritten — `git log` of this file shows the evolution.
- The sub-agent's reply was 3 lines, no commentary, no follow-up. This is the strongest possible signal that the scenario shape was self-sufficient — a failure mode would have been "could you clarify what 'satisfies the scenario' means?", which did not happen.

The discipline now compounds: the *next* spec scaffolded with `/sdd new` will start in scenario shape, and any future sub-agent dispatched against its acceptance criteria will get a tighter brief by default.
