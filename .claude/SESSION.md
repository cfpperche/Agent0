# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-22 — mei-saas `/product` dogfood → 3 specs.** The dogfood produced a 10-finding triage; this session shipped one spec, scaffolded two, and began implementing one.

- **073 product-report-html — shipped, committed (`06c2c2a`).** `/product` now generates `docs/REPORT.html` (navigable rendered reading surface). Done — no follow-up.
- **075 product-quality-audit — IN PROGRESS.** Replaces the `/product` size-budget *instrument* with a rubric quality judge. The dogfood proved the per-step KB ceiling is a scope-blind constant (10/10 overshoots, 0 true positives). spec/plan/tasks drafted + 4 OQs resolved (`a124424`); **Move 1 partial committed (`22aae4b`)** — tasks 1-2 of 14.
- **076 product-dogfood-fixes — scaffolded, committed (`e8ff256`).** The 6 non-budget dogfood findings (#2-sections, #3, #4, #5, #9 + harness #8). spec.md filled; plan/tasks NOT drafted; has 1 open question.

## WIP — resume point for 075

**Active build = 075. Work `docs/specs/075-product-quality-audit/tasks.md` top-to-bottom from task 3.** Done: 1-2 (cascade retired from `artifact-budgets.md` + `CLAUDE.md`; `max_size` swept from the 6 schemas that carried it — 02/03/08/09/10/15). Remaining:

- **task 3** — strip the "Overshoot cascade per artifact-budgets.md" boilerplate from the ~16 brief blocks in `references/delegation-briefs.md` (15 step briefs + § Mood-screen-writer) → one-line catastrophe-cap note.
- **task 4** — `references/pipeline-coverage.md` — the "Overshoot cascade" section + the per-step size-target table → catastrophe cap + judge pointer.
- **Move 2 (tasks 5-11)** — the rubric judge: verdict shape + the v5/v6 `.state.json` decision (task 5), reposition `quality-checklist.md`, write `references/quality-judge.md`, the judge brief, `SKILL.md` wiring, `state-machine.md`, `## Quality concerns` in `report.md.tmpl`.
- **Verification 12-14** — incl. a dogfood run.

## Next steps

1. **Continue 075** from task 3 (above). The design is locked in `075/spec.md` — implement it, don't re-litigate.
2. **076** — needs the founder to resolve the #8 open question (`076/spec.md` § Open questions) before `/sdd plan`.
3. Dated reminders: spec 029 05-30 · spec 035 06-07 · spec 046 07-01 · spec 060 07-19.

## Decisions & gotchas

- **075 design is locked (`075/spec.md`):** Design A — single `opus` judge, pointwise CoT; rubric = `schema.md` + `quality-checklist.md` + a scope-aware right-sizing criterion; **no autonomous hard-BLOCK** (gate-flag teeth — `fail` pre-populates the phase gate's `iterate`, or in gate-less Phase 4 the handoff); catastrophe cap = uniform 200 KB.
- **The "15-schema sweep" was 6** — only 02/03/08/09/10/15 carried `max_size`. See `075/notes.md`.
- **Bash cwd drifts** after Skill invocations (lands in skill dirs) — `cd /home/goat/Agent0` defensively, or use absolute paths.
- **`secrets-scan` hook blocks compound `git add && git commit`** — run them as separate Bash calls.
- **`governance-gate` blocks `rm -rf`** (combined `-r`+`-f`) — use `mktemp -d` for fixtures, `rm -r` without `-f`.

## Carryover (orthogonal — not touched this session)

- `.claude/REMINDERS.md` items per startup readout.
- `docs/specs/074-subagent-personas/` — untracked, another session's draft spec; not ours, leave it.
- Parked discussion: SOUL.md per sub-agent (delegation brief); `/product` full-stack expansion (caminhos A/B/C).
