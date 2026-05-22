# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-21 (cont.) — specs 061 + 063 shipped; spec 060 umbrella re-evaluated.**

- 070 follow-up #1 (`18fe9f7`), spec 061 subagent-stop-hook (`7fbacbb`), spec 063 worktree-isolation (`b29a6bd`) — all committed + pushed.
- **Spec 060 (harness-gaps umbrella)** — bookkeeping fixed (061/063 marked shipped in the matrix + context) and task 6 re-evaluation done: **A6 + A8 → closed**, **B8 → deferred**, A4/A5/A7 → kept pending (07-19 review batch), **B4 → recommended next spec**. Umbrella stays `draft` (A4/A5/A7 still unresolved). No bulk-scaffold — the matrix stays the single source of truth.

## WIP (uncommitted)

- Spec 060 re-eval: `docs/specs/060-*/{spec,tasks,notes}.md` + SESSION.md. Docs only. Not committed.

## Next steps

1. **Commit the spec 060 re-evaluation.**
2. **Decide B4 (SOUL.md / persona per sub-agent)** — the recommended next spec. Scaffold via `/sdd new` now, or hold for the 2026-07-19 §A/§B review batch.
3. **`/product` dogfood of mei-saas** — in progress in a parallel session. After it: live-validate spec 069 Phase 0 overwrite.
4. Dated reminders: spec 029 05-30 · spec 035 06-07 · spec 046 07-01 · spec 060 07-19.

## Decisions & gotchas

- **Don't bulk-scaffold umbrella follow-ups.** 060's gap matrix is the single source of truth for "what's pending"; empty draft specs rot. Scaffold a follow-up spec only when it becomes the actively-worked next unit.
- **Stale `in-progress` specs are a recurring pattern.** 061 + 063 both shipped their capacity but stayed `in-progress` because checkboxes weren't flipped when the code landed. (035 is `in-progress` *by design* — dogfood window.) Flip spec status + tasks boxes in the same commit as the code.
- **Memory basenames-as-examples — residual leak, deferred.** `routines.md` + `memory-placement.md` use bare memory-file basenames as examples. Recorded in `propagation-hygiene.md` § Not-yet-cleaned.

## Carryover (orthogonal — not touched this session)

- `.claude/REMINDERS.md` items per startup readout.
- Discussion items parked: SOUL.md per sub-agent (delegation brief); `/product` full-stack expansion (caminhos A/B/C).
