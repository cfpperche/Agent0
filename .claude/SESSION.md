# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-22 (cont.) — 076 OQ#8 resolved, plan.md still empty.** Founder picked the (b)+(c) synthesis: a `# SKILL-DIRECTED: <slug>` marker (mirroring `# OVERRIDE:` grammar, ≥10 chars) that the skill adds to each brief and `delegation-gate.sh` reads to suppress *only* the `escalation` advisory — `model-discipline` keeps firing on undeclared models, ad-hoc parent dispatches without the marker still get `escalation` (true-positive preserved). Audit row gains `skill_directed: "<slug>" | null`. Decision recorded with rejection reasoning in `076/notes.md`; acceptance criterion #8 in `076/spec.md` rewritten as a Given/When/Then scenario; OQ#8 marked resolved inline.

Uncommitted: `076/spec.md` + `076/notes.md` + this SESSION.md.

## WIP — resume point

**076 is unblocked for `/sdd plan`.** No code touched yet — only spec.md + notes.md edits. Next action is `/sdd plan` to draft the implementation approach across the 6 findings (5 `/product` skill bugs + 1 harness-core marker mechanism).

## Next steps

1. Commit the OQ#8 resolution (spec.md + notes.md) as a single `docs(076)` row before planning, so plan.md lands on top of a resolved spec.
2. Run `/sdd plan` for 076. The marker mechanism (#8) is the only cross-cutting change — it touches `delegation-gate.sh`, the audit-row builder, `.claude/rules/delegation.md` § Advisories, and adds 1 line per Step 02-15 brief in `delegation-briefs.md`. The other 5 findings are local to `/product` skill files.
3. **075 task 14** — `/product` dogfood scenarios 3-6 still pending (carryover, pairs with "069 live validation" reminder).
4. Dated reminders coming due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.

## Decisions & gotchas

- **`secrets-scan` hook blocks compound `git add && git commit`** — run them as two separate Bash calls; `git commit -F-` heredoc works fine.
- **`governance-gate` blocks `rm -rf`** — use `rm -r` without `-f`.
- **OQ#8 (c)-puro is a foot-gun.** Inverting the gate on `MODEL_SPECIFIED=true` alone silences the legitimate ad-hoc case (parent picked sonnet for multi-signal task). The marker is the discriminator that preserves the true-positive — don't let plan.md regress to (c)-puro.

## Carryover (orthogonal — not touched this session)

- **075 task 14** — `/product` dogfood scenarios 3-6 pending.
- `docs/specs/074-subagent-personas/` — untracked draft (persona/role-prompting killed on research grounds; leave it for the originating session).
- `.claude/REMINDERS.md` items per startup readout.
