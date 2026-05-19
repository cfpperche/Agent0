# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 060 umbrella + top-3 follow-ups scaffolded** (2026-05-19) — ready for commit:

- `docs/specs/060-harness-gaps-2026/` — **umbrella** (new `Type:` convention) aggregating 2026 competitive-audit findings: §A 8 standard-missing · §B 9 emerging · §C 8 descartado
- `docs/specs/061-subagent-stop-hook/` — #1 (§A3 · alta · S) — closes delegation audit row via `SubagentStop`
- `docs/specs/062-goal-skill/` — #2 (§A1 · alta · M) — `/goal` skill, contract-not-promise at user→main
- `docs/specs/063-worktree-isolated-subagents/` — #3 (§A2 · alta · M) — 6th optional handoff field `ISOLATION: worktree`

All in `draft`. `.claude/rules/spec-driven.md` § The four artifacts extended to document `**Type:**` (omitted default; `umbrella` for aggregators; expansion gated by rule-of-three). Two REMINDERS appended (mid-cycle §A/§B review 2026-07-19; Q3 audit 2026-08-19).

## WIP (uncommitted)

- `M .claude/{REMINDERS,SESSION}.md` · `M .claude/rules/spec-driven.md`
- `?? docs/specs/{060,061,062,063}-*/` (16 new files)
- Carryover from prior session (orthogonal — not this session's work): `M docs/specs/059-product-phase0-harness-aware/tasks.md`, `?? v*-*.png` screenshots

## Next steps

1. **Commit** in 3 fatias (umbrella+rule · 3 follow-ups · reminders) OR single `feat:` — user preference pending
2. **Attack 061 first** (top ROI). Pre-flight per `061/tasks.md` task 1 = capture real `SubagentStop` payload schema empirically before locking the parser
3. After 061 ships: re-priorize §A/§B rows, scaffold next batch per umbrella `tasks.md` task 6
4. mei-saas `/product` invocation still pending (founder action, prior-session carryover)

## Decisions & gotchas

- **Term `umbrella`** picked over `epic` / `tracking` — descriptive without Jira baggage; spec 060 is canonical example
- **`**Type:**` is bold inline line**, not YAML — preserves 59-spec convention; avoids parser/migration cost
- **062 /goal: rule-only v1**. Same constraint as `user-prompt-framing.md` — actor (main agent) can't externally enforce on itself. Hook deferred to v2 on rule-of-three drift only. Native `/goal` exists in CC v2.1.139+ — skill is portable/customizable across versions; task 1 checks namespace collision, renames to `/contract` if needed
- **063 worktree: rule-only v1** by same constraint — gate parses brief but can't mutate the `Agent` tool call pre-dispatch. Operational hook for validator scoping = `git rev-parse --show-toplevel` before validator runner (safe regardless of isolation)
- **Audit research delegated** to general-purpose agent (opus) 2026-05-19; URLs frozen in `060/plan.md` § Research
- **Delegation gate blocked first dispatch** of this session (research agent missing 5-field handoff) — capacity working as intended; frame validated empirically

## Carryover (orthogonal — not touched this session)

- mei-saas `/product` Phase 0 ready (founder owns next step; full context in `git log` 2026-05-19 commits 5f33e3e + 1d11e07 + .claude/memory)
- Spec 046 dogfood gate due 2026-07-01
- Spec 029 adoption check due 2026-05-30
- Spec 026 Phase C/D pending
- Acme Yard substrate work at `/home/goat/acmeyard`
- `.claude/REMINDERS.md` items per startup readout
