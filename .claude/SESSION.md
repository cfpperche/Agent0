# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 046 (`sdd-in-flight-notes`) — SHIPPED.** Goal `implementar e validar spec046` drove this session. Adds a **fourth optional artifact** `notes.md` to the SDD scaffold, ported from Travis Fischer's "implementation-notes" pattern ([thread](https://unrollnow.com/status/2056415973125796184)) — captures the in-flight design memory gap between pre-flight `spec.md`/`plan.md` and post-flight commit/PR. `/sdd` skill bumped v0.1 → v0.2. Rule-only v1 (no hook, no validator integration) mirroring spec 035's dogfood-first shape; promotion gate at 2026-07-01 via REMINDERS.

Spec 045 from prior session is already committed (d8817b8); spec 046 lands as a separate `feat(046)` commit.

## WIP (uncommitted)

Spec 046 scope:
- `M .claude/REMINDERS.md` (one new bullet)
- `M .claude/rules/delegation.md` (one paragraph after § *The 5-field handoff* canonical template)
- `M .claude/rules/spec-driven.md` (rename "three" → "four artifacts" + bullet)
- `M .claude/skills/sdd/SKILL.md` (cp line, version 0.1→0.2, description, Step 5 wording)
- `M CLAUDE.md` (one literal-string swap)
- `?? .claude/skills/sdd/templates/notes.md.tmpl` (new template)
- `?? docs/specs/046-sdd-in-flight-notes/` (spec dir with 4 files, including its own meta-dogfood notes.md)

Pre-existing dirty (NOT touched): `.claude/skills/brainstorm/templates/render.html.tmpl`, `.claude/skills/prototype/templates/monorepo-skeleton/next/app/globals.css` — both sibling-session WIP.

## Next steps

1. **Dogfood window opens for spec 046.** Next 3-5 specs scaffolded after 046 should naturally exercise the notes.md flow. REMINDERS gate at 2026-07-01 decides promote-to-mandatory vs revert.
2. **Push spec 045 + 046 when convenient.** Branch is ≥2 commits ahead of `origin/main`.

## Decisions & gotchas

- **Meta-dogfood caught a real bug.** The "Mechanical lint pass" verification task in spec 046's `tasks.md` was too coarse (grepped for `{{NNN}}` anywhere — matched legitimate prose describing the placeholder syntax). Logged as a Deviation in `docs/specs/046-*/notes.md` in real time; substituted a structural lint (H1 / subtitle / status lines only). Exactly the failure mode the notes.md artifact exists to capture — first entry validates the design.
- **v1 is intentionally rule-only.** No `delegation-gate.sh` advisory yet. Per `.claude/memory/feedback_speculative_observability.md`'s rule-of-three demand test, observability/enforcement waits for ≥3 missed-notes-during-spec-work sessions. Provisional answers and v2 landing spot are documented inline in `docs/specs/046-*/notes.md` § Open questions.
- **Numbers 037-044 still reserved.** Per prior session note: MCP-side realign (children of spec 032, separate calendar). Spec 046 uses 046, not 037.
- **Skill validator stays green** after the SKILL.md version bump (`bash .claude/skills/skill/scripts/validate.sh .claude/skills/sdd` exit 0).

## Carryover (orthogonal)

- Spec 045 full 15-step end-to-end run (follow-on, not blocker, within 30 days).
- Spec 029 adoption check due 2026-05-30.
- Spec 026 Phase C/D pending.
- Spec 032 children 037-044 (MCP-side realign — separate calendar).
- Sibling sessions: brainstorm `render.html.tmpl`, prototype `globals.css` — not mine to commit.
- `.claude/REMINDERS.md` items per startup readout.
