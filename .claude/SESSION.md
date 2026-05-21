# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-21 (cont.) — 070 follow-up #1 done: memory-ref de-leak. `main` clean + in sync; follow-up edits uncommitted.**

- **070 follow-up #1 — memory-ref de-leak (done, direct, no spec).** Stripped 9 `.claude/memory/<file>.md` path-pointer citations (`feedback_speculative_observability.md`, `cc-platform-hooks.md`) from 6 rule files: `spec-driven`, `runtime-introspect`, `rule-load-debug`, `routines`, `user-prompt-framing`, `artifact-budgets`. Pointer dropped, operational concept kept — per spec 070's resolved OQ1.
- **Scope correction vs. handoff estimate:** the prior handoff said "11 pointers / 8 files". Actual: 9 genuine leaks / 6 files. The 2 remaining `.claude/memory/MEMORY.md` mentions (CLAUDE.md § Memory, `memory-placement.md`) are the index-file-*name* convention — kept, same carve-out as the literal `NNN` in `docs/specs/NNN-<slug>/`. Consequential staleness fix rode along: dropped `memory-placement.md`'s "discovery via cross-references from specific rule docs" clause.
- Earlier this session: specs 068–072 shipped + pushed; mei-saas fork synced (`98a899f`).

## WIP (uncommitted)

- 7 fork-bound files edited (6 rule de-leaks + `memory-placement.md` staleness fix) + `.claude/memory/propagation-hygiene.md` § Not-yet-cleaned updated. Not committed — awaiting review.

## Next steps

1. **Commit the 070 follow-up #1 de-leak** (8 files; suggested: `chore(070): follow-up #1 — strip .claude/memory/ path-pointer leaks from 6 rules`).
2. **`/product` dogfood of mei-saas** — queued; runs in a mei-saas-rooted session (kickoff prompt prepared 2026-05-21). Live-validates spec 069's Phase 0 overwrite (`clear-target.sh` must preserve `.git/` + harness). mei-saas baseline is clean + pushed; checkpoint `a2c8ec2` is the safety net.
3. Dated reminders (not yet due): spec 029 adoption 2026-05-30 · spec 035 missed-clarification count 2026-06-07 · spec 046 gate 2026-07-01 · spec 060 §A/§B review 2026-07-19.

## Decisions & gotchas

- **Memory basenames-as-examples — newly-surfaced residual leak, deferred.** `routines.md` + `memory-placement.md` use bare memory-file basenames (`cc-platform-hooks.md`, `agent0-purpose.md`, …) as illustrative examples. Distinct softer class from the path-pointer citations; cleaning = editorial rewrite. Recorded in `propagation-hygiene.md` § Not-yet-cleaned.
- **070 follow-up #2 (spec citations in hook/tool code comments) is deliberately OUT of scope** — code comments are not instruction-context, low harm; 070 deferred them on purpose.

## Carryover (orthogonal — not touched this session)

- `.claude/REMINDERS.md` items per startup readout.
- Discussion items parked: SOUL.md per sub-agent (delegation brief); `/product` full-stack expansion (caminhos A/B/C).
