# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 (4th) — Bertolini dogfood-loop study + deferred-reference memory.** Studied the X thread (<https://x.com/brunobertolini/status/2058617644769493017>), the linked gist (paste-and-go autonomous-loop wizard), and Cherny's auto-mode/multi-clauding parent tweet via Playwright. Decision after `/sdd refine` discussion of 4 scope options: **D — not adopt, save as `reference` memory**. 1 commit: `9314e12` — `.claude/memory/bertolini-dogfood-loop.md` captures pattern + explicit revisit trigger.

## WIP — resume point

**No active WIP from this session.** Working tree carries an orthogonal in-progress capacity from the maintainer — see Carryover.

## Next steps

1. **Dated reminders**: 029 (05-30, 6 days) · 035 (06-07) · 046 (07-01) · 060 (07-19).
2. **Watch for cascade-classification pattern recurrence** — second/third independent sighting promotes the meta-shape (ordered buckets + named match + conservative default) from [[bertolini-dogfood-loop]] to a paragraph in `.claude/rules/delegation.md` § Advisories. Don't build a wizard; do edit the rule.

## Decisions & gotchas

- **Rule-of-three discipline held against an interesting single sample.** Bertolini's pattern is genuinely novel (we have no cascade classification anywhere) but the demand test is one sighting. Deferred via [[skill-eval-pattern]] precedent. The memory entry names exactly what to promote when 2+ more sightings land — pre-cooked decision so future-me doesn't re-derive.
- **The novel piece is the cascade, not the taxonomy.** Bertolini's 4 buckets (`backend_fix` / `tracking_fix` / `ui_issue` / `needs_product`) are SaaS-with-analytics-bound and won't generalize. What's portable is the meta-shape: ordered buckets + named match criteria + ultimate-default-to-conservative when uncertain.
- **Agent0 isn't a dogfood target for the loop itself.** It's a meta-harness without browser-exploration scenarios; the wizard's premise ("test your consumer SaaS app") doesn't map. Forks that ARE product apps already inherit `/routine` + post-edit-validator and can roll their own — no need for an Agent0-side wizard.

## Carryover (orthogonal — not touched this session)

- **Propagation-advisory capacity in progress** (maintainer WIP) — 4 files staged across this session: `.claude/hooks/propagation-advise.sh` (new), `.claude/rules/propagation-advisory.md` (new), `.claude/settings.json` (hook registration), `CLAUDE.md` (capacity index entry). Single logical unit — commit together when ready.
- `docs/specs/074-subagent-personas/` — untracked draft (carried from earlier handoff).
