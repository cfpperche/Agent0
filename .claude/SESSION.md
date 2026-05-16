# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

This session refactored the public landing page (`site/`) to match repo reality + opened a new **MCPs by Agent0** catalog section. Site refactor still uncommitted. Parallel SDD lane shipped specs 028 (`/sdd refine`, `60e8a03`) + 029 (`/sdd list --in-flight` + `**Status:**` field, `e1df0a7`) — **now 10 commits ahead of origin** (push pending) + site refactor on top.

Uncommitted in `site/` (4 M + 2 ??): `Header.astro` (+#mcps nav), `i18n/capacities.ts` (+typecheck-advisory + rule-load-debug → 18), `i18n/strings.ts` (count copy + new `mcps` block en/pt/es), `layouts/Landing.astro` (+`<McpGrid>` between Capacities and Why), `components/McpGrid.astro` NEW (2-col cards, status badge, placeholder slot), `i18n/mcps.ts` NEW (`MCPS[]` seeded with product-pipeline live/8 tools/spec 025-027).

Build clean (`bun run build`, 4 pages, 599ms). Playwright verified 3 locales render, 18 capacity cards, 0 console errors, mobile 390px OK.

Untracked at repo root NOT from this session: 7 `step7-*.png` from prior spec-026 dogfood (wipe-able).

## Next steps

1. **Decide commit shape for site refactor** — single commit "feat(site): MCPs section + 18-capacity catalog sync" vs split (site copy fix / MCPs section). The MCPs section is the load-bearing addition.
2. **Push 11 commits when ready** — current 10 + site refactor. No force-push concerns.
3. **Spec 026 Phase B — remaining tasks 17-22**: step 8 PRD (next, opens Specification phase), 9 system-design, 10 cost, 11 roadmap, 12 legal, 13 prototype-v3 NEW.
4. **Fair OD re-match + future OD `--bump`/`--apply`** — both still pending in `.claude/REMINDERS.md`, deferred-style not urgent.
5. **Adoption check for spec 029** — 14d revert window per Open Q1, tracked in REMINDERS.md (due 2026-05-30).

## Decisions & gotchas

- **MCPs section placement: after Capacities, before Why** (confirmed via AskUserQuestion). Native capacities → derived products → motivation.
- **"MCP recipes" capacity ≠ "MCPs by Agent0" section.** Recipes = adoption of third-party MCPs (Playwright/DBHub). Section = MCPs we author in-repo (currently product-pipeline). The closing distinction paragraph guards against future conflation.
- **Capacity count drift was real**: `rule-load-debug` + `typecheck-advisory` were in CLAUDE.md and `.claude/rules/` but missing from site. A future "harness vs site count" check could `/loop`-verify.
- **Adding future MCPs = `MCPS[].push(...)` in `src/i18n/mcps.ts`.** Grid has dashed placeholder card already.
- **No `.claude/`, hooks, or rules touched this session.** Memory `feedback_mcp_package_self_contained` + `feedback_agent0_changes_ship_via_rules_not_memory` both honored.

## Carryover (orthogonal lanes, not active)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending (13 modified + 2 untracked there).
- Praxis-prototype lane (consultancy-site, separate repo): deployed at https://cfpperche.github.io/praxis-prototype/. Possible `section-line-grid` opacity bump 0.045 → 0.07.
- Bench artifacts (wipe-able): `/tmp/bench/026-dogfood-step{2..7}/` (~1 MB combined) + `/tmp/bench/026-comparison-anthill/` (~140 KB).
