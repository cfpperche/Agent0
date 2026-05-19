# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**5 specs de refinamento do `/product` v0.3.0 — ALL SHIPPED.** Cada uma commitada como `feat(NNN): ...` separado, scaffolds preservados em commit anterior `docs(053-057): scaffold ...`.

- **053** screen-writer brief hardening — metadata + states evidence + Biome anti-pattern checklist + `primary_metric` field
- **054** brand-book Glossary + Language — Phase 0.5 language resolution + `## Glossary` table mandatory; consumed by Step 15 only
- **055** sitemap `chrome` field orthogonal to `category` — drives route-group placement; default-inference back-compat fallback
- **056** pipeline size reconciliation — schema.md canonical for 6 priority steps; 9 legacy steps deferred to phase 2
- **057** fan-out fallback — between-wave biome sweep + degrade-to-parent-write at N=1 same-wave (revised from N=2)

**OQ resolutions: critique-driven across all 5 specs.** 5 of the 15 original recommendations were revised after the user pushed back on rubber-stamping. See per-spec `notes.md` for the design memory. Memory entry `feedback_no_rubber_stamping_own_prior_text.md` saved.

## WIP (uncommitted)

- `M .claude/SESSION.md` — this file (about to commit)
- `M .claude/skills/brainstorm/templates/render.html.tmpl` — pre-existing dirty, NOT this session

## Next steps

1. **Verification dogfood** of all 5 specs at next `/product` invocation. Each tasks.md task 8 (or equivalent) is deferred to a real run — confirms the new schemas/briefs/orchestration actually work end-to-end.
2. **Untouched Vetro audit findings** (qualitative gaps not addressable by mechanical brief changes): #2 time-cursor agenda over text, #4/#5/#9 UX semantic (growth-loop, animal photo, booking hierarchy), #10 console errors. Ex-post Playwright audit only — no spec yet.
3. **Spec 056 phase 2** when next 2-3 dogfoods accumulate evidence on the 9 legacy steps (01/04/05/06/07/11/12/13/14).

## Decisions & gotchas

- **Critique discipline saved.** When user asks to "resume" / "attack" work I drafted earlier, I default to rubber-stamping my prior recommendations. New memory entry `[[feedback-no-rubber-stamping-own-prior-text]]` codifies the discipline: critique prior recs, surface where reasoning was thin, present real tradeoffs.
- **Spec 053 `primary_metric` v1 = string-label, not rich struct.** v2 deferred until downstream sub-agents prove ambiguous.
- **Spec 054 Phase 0.5 NEW.** Adds an `AskUserQuestion` between Init and Phase 1 for `target_language` resolution. `{{target_language}}` substituted into 6 user-facing briefs. Phase 4.5 simplified to read state.
- **Spec 055 default-inference back-compat ONLY.** New sitemaps SHOULD emit `chrome` explicitly; default-inference cannot decide booking-vs-app correctly without help.
- **Spec 056 conditional model for Step 09 legal.** Base 5-10 KB + DPIA +5/+12 + AI +2/+5 + Regulated +2/+8. Other 5 steps use simple ranges.
- **Spec 057 N=1, not N=2.** Sub-agents in same wave share lint state via repo-wide biome — first fail strongly predicts siblings will too. N=2 wastes throughput.
- **`max_size` added to JSON `required_files` blocks** is documentation-only at standalone-skill level (MCP package validator ignores unknown keys).

## Carryover (orthogonal)

- Spec 046 dogfood window — promotion gate 2026-07-01.
- Spec 029 adoption check due 2026-05-30.
- Spec 026 Phase C/D pending.
- Acme Yard substrate work — `/sdd new substrate` at `/home/goat/acmeyard`.
- `.claude/REMINDERS.md` items per startup readout.
