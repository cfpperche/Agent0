# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-22 (cont.) — spec 075 Move 1 complete.** Active spec is `docs/specs/075-product-quality-audit/` — replacing the `/product` size-budget *instrument* with a rubric quality judge.

- **075 Move 1 — retire the size ceiling — DONE (tasks 1-4).** Tasks 1-2 committed earlier (`22aae4b`). **Tasks 3-4 done this session, UNCOMMITTED.**
  - task 3 — `references/delegation-briefs.md` full ceiling scrub (~37 edits): 17 brief blocks' "Overshoot cascade" boilerplate → one-line 200 KB catastrophe-cap note; 6 stale `schema.md § Target` pointers → `§ Size floor`; ~10 inline "X-Y KB hard ceiling" → `≥ N KB` anti-stub floors; every `DONE_WHEN` size range → floor-only check.
  - task 4 — `references/pipeline-coverage.md`: "Overshoot cascade" section → catastrophe-cap + "right-sizing is judged" paragraphs; per-step table `Size target` column → `Size floor (anti-stub)`; section retitled; legend + 2 "Lightening op" ceiling mentions scrubbed.
  - task 3 was **extended** from the literal scope (cascade-strip only) to a full scrub per the user's 2026-05-22 decision — see `075/notes.md § Deviations`.
- **073 product-report-html — shipped (`06c2c2a`).** Done, no follow-up.
- **076 product-dogfood-fixes — scaffolded (`e8ff256`).** spec.md filled; plan/tasks NOT drafted; 1 open question (#8) blocks `/sdd plan`.

## WIP — resume point for 075

**Move 1 complete. Next = Move 2 (tasks 5-11) — add the quality judge.** Work `docs/specs/075-product-quality-audit/tasks.md` from task 5.

- **task 5** — decide + document the verdict JSON shape (per-criterion `pass`/`concern`/`fail` + scope assessment) + the `.state.json` `quality_verdicts` field. **Resolve v5-additive vs v6-bump** (`plan.md` § Risks) — needs reading `references/state-machine.md` to see how strict the resume version-gate is; record the call in `notes.md`.
- tasks 6-11 — reposition `quality-checklist.md` as the judge rubric contract; write `references/quality-judge.md`; add the § quality-judge brief to `delegation-briefs.md` (`model: opus`, pointwise CoT, anti-verbosity); wire `SKILL.md` (per-step `wc -c` pre-filter + judge dispatch + verdict routing); update `state-machine.md`; add `## Quality concerns` to `templates/report.md.tmpl`.
- Verification 12-14 — incl. a dogfood run.

## Next steps

1. **Commit Move 1** (tasks 3-4 uncommitted) — natural unit, `feat(075)`-shaped.
2. **Continue 075 Move 2** from task 5. Design is locked in `075/spec.md` — implement, don't re-litigate.
3. **076** — needs the founder to resolve the #8 open question (`076/spec.md` § Open questions) before `/sdd plan`.
4. Dated reminders: spec 029 05-30 · spec 035 06-07 · spec 046 07-01 · spec 060 07-19.

## Decisions & gotchas

- **075 design is locked (`075/spec.md`):** Design A — single `opus` judge, pointwise CoT; rubric = `schema.md` + `quality-checklist.md` + a scope-aware right-sizing criterion; **no autonomous hard-BLOCK** (`fail` pre-populates the phase gate's `iterate`, or in gate-less Phase 4 the handoff); catastrophe cap = uniform 200 KB.
- **The producer briefs deliberately do NOT mention the judge** — avoids writing-to-the-judge bias; the judge evaluates after the fact.
- **Bash cwd drifts** after Skill invocations — `cd /home/goat/Agent0` defensively, or use absolute paths.
- **`secrets-scan` hook blocks compound `git add && git commit`** — run them as separate Bash calls.
- **`governance-gate` blocks `rm -rf`** (combined `-r`+`-f`) — use `mktemp -d` for fixtures, `rm -r` without `-f`.

## Carryover (orthogonal — not touched this session)

- `.claude/REMINDERS.md` items per startup readout.
- `docs/specs/074-subagent-personas/` — untracked, another session's draft spec; not ours, leave it.
- Parked: SOUL.md per sub-agent (delegation brief); `/product` full-stack expansion (caminhos A/B/C).
