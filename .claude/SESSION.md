# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-25 — spec 087 (skill-rubric) shipped in 3 commits.**

Three commits on `main`:

- `01fbcd7` — scaffold. `.claude/skills/skill/references/skill-rubric.md` (canonical doc) + `scripts/check-rubric.sh` (~110 LOC, body-shape advisor; sibling to validate.sh for frontmatter). `/skill audit` wired to invoke both per target, surfacing rubric findings as a non-blocking footer block. Own SKILL.md gained annotations + `## Eval Scenarios`. Cross-ref added to `.claude/rules/spec-driven.md` § *Acceptance scenarios* ("skill-level sibling").
- `ac10d3b` — annotate `/sdd` (5 subcommand headers) + `/product` (8 phase headers). Eval scenarios per skill (3 each). Calibration: gates + judge + scaffolds = 🔒 Low; content steps = 🔓 Medium.
- `5307230` — override markers on `/remind`, `/routine`, `/brainstorm` (T5 smoke surfaced they have 5-8 qualifying step headers, contrary to spec NG-4's sub-threshold assumption; SKILL-RUBRIC-EXEMPT preserves no-scope-creep posture). Plus the full `docs/specs/087-skill-rubric-freedom-evals/` (spec/plan/tasks/notes) shipped with `Status: shipped`.

All 8 verifications (V1-V8) pass: 7/7 skills silent under `check-rubric.sh`; cross-ref present; synthetic gap-injection tests fire the expected advisories.

## WIP — resume point

**No active WIP.**

## Next steps

None queued. Two non-blocking follow-ups documented in `docs/specs/087-skill-rubric-freedom-evals/notes.md`:

1. Rule-of-three trigger for spec 088 — if `/skill audit` surfaces `/remind`/`/routine`/`/brainstorm` rubric advisories ≥3 distinct sessions over the next month, file spec 088 to annotate them instead of exempting.
2. `/product` description over agentskills.io rule4 cap (1086 chars vs 1024) — pre-existing at HEAD before this session, out of scope for 087; addressable via `/skill port product` when prioritized.

## Decisions & gotchas

- **Plan deviation captured upfront** — spec said "extend `validate.sh`"; plan re-hosted in `audit` because `validate.sh` `exec skills-ref`s into canonical and is upstream-spec-scoped. `check-rubric.sh` is the body-shape sibling, repo-local by design.
- **Threshold heuristic empirically validated.** Counting `^##` headers minus frame sections (`Notes`/`Gotchas`/`Cross-references`/`Reference Files`/`Eval Scenarios`/`Argument parsing`/`Unknown*`/`Worked example*`) cleanly separates `/image` (sub-threshold) from the 6 above-threshold skills. No clean numeric threshold cleaves the 3 named targets from the 3 misclassified — override-marker is the right escape.
- **Eval scenarios body shape is loose by design.** Validator checks only `## Eval Scenarios` header + ≥2 `### Eval ` sub-headers; Input/Expected/Failure-indicators is convention in the reference doc, not regex-enforced. Same posture as `## Acceptance criteria` in spec.md.
