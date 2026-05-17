# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Claude Code learning site shipped.** Three big surfaces landed this session, all under `/site/src/pages/`:

1. **Cheatsheet de-Agent0-ification + anatomy upgrade** — `cheatsheet/claude-core.astro`. Purged 7 contamination points (RULES card removed, `[sdd, remind]` → `[simplify, debug]`, SKILL·AGENT·RULE → SKILL·AGENT·HOOK diagram, etc.). FILE SYSTEM MAP card upgraded to thematic `.claude/` anatomy (CONTEXT / CONFIG / CAPABILITIES / LIFECYCLE / RUNTIME STATE) with managed-policy + precedence chains. Added anchor IDs on Atlas cards so other pages can deep-link.
2. **Master Class** — `masterclass/claude-code.astro` (EN) + `masterclass/pt/claude-code.astro` + `masterclass/es/claude-code.astro`. 12 modules each, TL;DR-first per Akshay pedagogical pattern, mini-diagrams + recipes + "Deep dive →" to Atlas. Language switcher (EN/PT/ES) + PDF print button with A4 reading-flow @media print.
3. **Hook Cookbook** — `cookbook/hooks.astro`. 10 production-ready recipes covering all 7 hook event families. Filter-by-family chips, PDF print, deep-links to Atlas + Master Class.

Wiring: `components/Header.astro` got `Master Class ↗` + `Cookbook ↗` links; `i18n/strings.ts` got `nav.masterclass` + `nav.cookbook` in en/pt/es. Build clean (`bun run build` → 8 pages, 1.04s).

Working tree: 8 files staged-ready (5 modified, 3 new dirs). Two unrelated files left untouched: pre-existing `.claude/skills/brainstorm/templates/render.html.tmpl` mod and `banner-4-atos.png` — both from prior sessions.

## Next steps

1. **Commit cheatsheet cleanup + masterclass + cookbook in one consolidated push.** Pending user OK.
2. **Distribution before more building** — Akshay-style announcement thread on X. The site has zero distribution; building a third page has lower marginal ROI than promoting the existing two. (Suggested by analysis at end of "more ideas?" prompt; user can redirect.)
3. **Spec 026 Phase C** (tasks 23-25). Still pending. Pick dogfood slug; update `packages/mcp-product-pipeline/README.md` (13-step diagram); update `.mcp.json.example` header.
4. **Spec 026 Phase D** (tasks 26-31). End-to-end dogfood. Still pending.
5. **Memorialize port→judge→calibrate as 8th phase of `.claude/memory/anthill-port-workflow.md`** — still pending 3+ sessions.
6. **REMINDERS unchanged** — fair OD re-match, OD `--bump/--apply` upstream test, spec 029 adoption check (2026-05-30).

## Decisions & gotchas

- **i18n routing dev/prod mismatch.** `astro.config.mjs` has `redirectToDefaultLocale: true` + `prefixDefaultLocale: true`. Dev server returns 404 (with full HTML body) for non-locale-prefixed URLs (`/cheatsheet/claude-core/`, `/cookbook/hooks/`, `/masterclass/claude-code/`). PT/ES work because they match locale list. **Static build is fine** — `dist/<path>/index.html` is generated and GitHub Pages serves as 200. Resolution deferred: either move EN under `/masterclass/en/` to match PT/ES, or set `redirectToDefaultLocale: false`. Not blocking deploy.
- **Page chrome stays Agent0-branded; page content is Claude-Code-only.** Settled in the de-Agent0 pass. Watch: any new card/annotation naming an Agent0 skill/rule/script/dir is contamination.
- **CSS duplicated across 3 Master Class variants + Cookbook.** Future refactor: extract poster theme tokens + module CSS to a shared `styles/poster.css`. Today's duplication is intentional shipping cost.

## Carryover (orthogonal lanes, not active)

- Spec 026 Phase B follow-ons (multi-`any_of_contains_*` schema; 4-dim model upstream; step-10 nits; step-13 open Qs; architecture HTML rendering; Pyshrnk CLAUDE.md reconciliation).
- Bench artifacts (~10+ MB wipe-able): `/tmp/bench/026-dogfood-step{11,12,13}/`.
