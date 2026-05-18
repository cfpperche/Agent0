# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 036 (`prototype-skill-refactor`) — IMPLEMENTATION COMPLETE, AWAITING DOGFOOD.** Spec drafted + Passes A/B/C/D all shipped this session. Only Pass E (live dogfood replay) remains as acceptance gate before spec 036 flips `draft → shipped` and spec 034 flips `shipped → superseded`. All bundled templates fixed + skill body rewritten + ops/docs hygiene applied. Pushed to origin/main (`5989492` for spec + Pass A/B; pending commit for Pass C/D).

Triggered by 2026-05-17 dogfood "skill rejeitada" user feedback. `/prototype` v1 was scoped as agile *alternative* to 13-step mcp-product-pipeline but covered only ~25-30% (8 steps missing entirely). v2 reframes as agile *frontend* covering all 13 steps at single "standard" depth tier, standalone (templates bundled, no MCP runtime dep), `--out=<path>` flag (drop /tmp hardcode), `--from-step=NN` resume support, 3 `AskUserQuestion` gates between phases. Pass C bundled `pnpm-workspace.yaml` with literal `true` values (pre-empts pnpm v11 placeholder generation), added `"test"` script to both next + expo `package.json`, and prepended `@import "../tokens.css";` to `next/app/globals.css` so the v2 stitch step doesn't depend solely on the strict-regex re-verification.

This session's v1 dogfood at `/tmp/prototype-claude-code-governance-dashboard/` (17 routes, 10 KLoC TSX, dev server runs) remains there as the acceptance baseline for Pass E (replay with same brief on v2 + verify design system actually renders).

## WIP (in flight)

**Pass E of spec 036 — live dogfood replay.** Single remaining task before status flip. Replay command: `/prototype "Claude Code governance dashboard" --stack=next --out=/tmp/dogfood-v2` in a fresh session. Verify (a) all 13 step artifacts produced; (b) design system renders (NOT raw HTML — token import path proven end-to-end); (c) typecheck + lint exit 0; (d) PRD coverage matrix complete. Then flip spec 036 → `shipped` + spec 034 → `superseded by 036-prototype-skill-refactor` + close REMINDERS "Full 23-route /prototype dogfood" item.

## Next steps

1. **Pass E** (live dogfood replay — fresh session recommended for cold-cache wall-time signal). Total estimate ~30-45 min real run.
2. **Spec 036 status flip** to `shipped` after Pass E passes acceptance.
3. **Spec 034 status flip** to `superseded by 036-prototype-skill-refactor` (deferred from Pass D task 21 per spec 036 Notes guidance — never supersede before v2 validates).
4. **Close REMINDERS "Full 23-route /prototype dogfood" item** (Pass E satisfies it).
5. **Carryover lanes (orthogonal):** spec 029 adoption check (due 2026-05-30), spec 026 Phase C/D, agent0-atlas + Hermes post REMINDERS due-dates.

## Decisions & gotchas

- **5 spec 036 open questions resolved 2026-05-18:** Step 1=opus + Steps 2-13=sonnet; quarterly REMINDERS drift sync (no script); `AskUserQuestion` structured at 3 gates; degrade gracefully + log on mid-pipeline BLOCKED, abort only on Step 01 or Step 13 fail; Phase 0 overwrite prompt (no `--force` flag).
- **Validator scope is repo-wide gotcha** (Pass B SKILL.md Notes documents). One bad Biome format error in any file blocks ALL subsequent sub-agents in the same dispatch batch until cleaned. Run `biome check --write .` between batches as parent-side mitigation.
- **OD catalog index bundled at 21.6 KB** (72 vendors with category + mood + palette_primary + vendor_path). Full per-vendor DESIGN.md NOT bundled (size budget) — Step 06 reads them from `packages/mcp-product-pipeline/design-systems/<vendor>/DESIGN.md` if present, falls back to mood-only otherwise.
- **Bundled pipeline templates 1.3 MB total** (13 step dirs × 60-160 KB each). Skill dir grew from ~250 KB → 1.5 MB. Acceptable (no per-skill size cap; SKILL.md body is 163 lines / ~2400 tokens — well under 5000 cap).
- **Sub-agent parallel-dispatch discipline rediscovered.** Spec 034 dogfood revealed serial-1 dispatching even when skill body said parallel. v2 SKILL.md now has an explicit literal "5 Agent tool calls in one message" worked example.

## Carryover (orthogonal lanes, not active)

- **Pre-existing dirty (NOT touched this session):** `.claude/REMINDERS.md` (sibling-session edits from prior), `.claude/skills/brainstorm/templates/render.html.tmpl` (older session WIP). NOT included in this session's commit.
- **Sibling sessions:** hermes-core 8th surface decision (Cookbook/Recipes was top recommendation; user thinking). `cfpperche/claude-core` and `cfpperche/hermes-core` repos at separate paths.
- **Dogfood artifacts at /tmp/:** `/tmp/prototype-claude-code-governance-dashboard/` (17-route Next.js v1 dogfood, contains design-system-fix patch — wipe-able; v2 replay will create new dir).
- **Spec 029** adoption check due 2026-05-30.
- **Spec 026 Phase C/D** still pending (orthogonal track).
