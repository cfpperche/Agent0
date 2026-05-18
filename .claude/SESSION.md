# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 045 (`prototype-skill-pipeline-realign`) — SHIPPED (all 7 batches).** Goal `ratifico 100% sua posicao, planejar e executar a spec045 com suas decisoes` drove this session. Batch 7 acceptance gate executed via targeted Step 07 sitemap-IA dispatch against Pass E PRD seed (NOT full 15-step end-to-end which is ~11hr — that's a follow-on); load-bearing mechanical fix PASSED: spec-045 v3 sitemap shows 15 routes vs Pass E's 5 (5 auth net-new, 3 admin net-new beyond just /settings/policy, 2 error net-new). A/B documented at `docs/specs/045-*/artifacts/redogfood-comparison.md`. Spec status flipped `in-progress → shipped`.

Spec 045 ports spec 032's 17 industry-alignment decisions to the `/prototype` skill independently of MCP shipping (scout pattern — small ship validates design before MCP commits ~6 weeks). Skill bumped v0.1 → v0.2.0. New shape: 15 linear steps × 4 phases (`discovery → specification → identity → visual-contract`); gates at [4, 12, 14]; sitemap-IA promoted to Step 07 with schema-enforced `required_categories` (load-bearing fix for Pass E silent under-cover bug); legal shift-left Step 09 DPIA-triggered by Step 08 data-flow.json; PRD reshape to Lenny 1-pager hybrid at Step 05; OST Step 06; GTM-launch Step 12; cost↔roadmap swap (our addition not in 032); collapse 3→2 prototype passes (deleted v2 Step 7 tombstoned; renamed Step 13 → Step 15 screen-atlas absorbing brand+tokens responsibility).

**Validator green:** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` exit 0; description 1024 chars ✓; 15 dirs in `templates/pipeline/` ✓; state.json declares `version: 3` ✓; SKILL.md has `metadata.skill-version: "0.2.0"` ✓.

## WIP (uncommitted)

5 references + SKILL.md rewritten + 4 templates extended + 9 dirs renamed via `git mv` + 1 dir deleted + 3 new dirs (06-ost / 07-sitemap-ia / 12-gtm-launch) + 4 spec/artifact files added (spec.md + plan.md + tasks.md + 68 KB tombstone at `docs/specs/045-*/artifacts/deleted-step-7-prototype-v2.md`). Sed-cleanup of `prototype-v2/v3` token references in 04-ux-testing + 14-design-system. Pre-existing dirty (NOT touched): `.claude/skills/brainstorm/templates/render.html.tmpl` (sibling-session WIP).

## Next steps

1. **Commit the spec 045 work.** Suggested: `feat(045): /prototype v3 — industry-aligned 15-step pipeline (ports spec 032 decisions; sitemap-IA schema enforcement; legal shift-left; PRD-1pager Lenny hybrid; collapsed 3→2 prototype passes; Batch 7 targeted acceptance gate PASS)`. Skip brainstorm template (sibling-session WIP).
2. **Full 15-step end-to-end run (follow-on, not blocker).** Targeted Batch 7 gate exercised the load-bearing sitemap-IA fix; full pipeline run with Steward brief would establish upper-bound wall-time + token cost for the realigned shape, and exercise the orchestrator's parent-side schema-enforcement + re-dispatch flow. Recommended within 30 days. Add to REMINDERS as low-urgency.
3. **Carryover lanes (orthogonal):** spec 029 adoption check due 2026-05-30; spec 026 Phase C/D pending; REMINDERS new spec-045-adjacent items.

## Decisions & gotchas

- **Scout-pattern (Q6 ratified):** spec 045 ships BEFORE spec 032 (skill = smaller test bed; bugs found here inform 032 implementation). Skill bundled-template provenance now says "derived from spec 032 decisions, NOT re-copied from packages/mcp-product-pipeline".
- **Cost↔roadmap swap is OUR addition** (spec 032 kept cost@10 before roadmap@11; spec 045 swaps). If redogfood validates value, feed back to 032 as new Decision 18.
- **State.json v3 is breaking (no auto-migration).** Orchestrator refuses silent upgrade — older state files require clear + restart.
- **21 files still reference `prototype-v2/v3` as historical migration context** (e.g. "deleted Step 7 (prototype-v2)" in SKILL.md). LEGITIMATE — document the migration. Deeper sweep of template body cross-refs deferred — Batch 7 is the real test.
- **Tombstone path:** `docs/specs/045-prototype-skill-pipeline-realign/artifacts/deleted-step-7-prototype-v2.md` (68 KB; verbatim deleted prompt.md + schema.md + references/; rollback path documented inline).

## Carryover (orthogonal)

- Spec 029 adoption check due 2026-05-30.
- Spec 026 Phase C/D pending.
- Spec 032 children 037-044 (MCP-side realign — separate calendar).
- Sibling session: brainstorm `render.html.tmpl` edits.
- `.claude/REMINDERS.md` items per startup readout.
