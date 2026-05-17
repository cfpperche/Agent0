# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

Working tree has 3 uncommitted edits under `packages/mcp-product-pipeline/src/templates/11-roadmap/` — **NOT this session's work**, owned by a sibling session that already committed `15d200d feat(026): Phase B task 20 — step 11 roadmap port` and may still be mid-calibration on the same task. Leave alone.

**This session's main deliverable: Claude Code Core Cheatsheet** at `site/src/pages/cheatsheet/claude-core.astro`. 7 commits shipped end-to-end (`6b8e5f3` → `db9ace7`). Single printable A3 poster page with 4 parts:

- **PART I — CLI** (8 cards) — every `claude --help` flag/subcommand
- **PART II — Platform** (16 cards) — settings · hooks · CLAUDE.md · MCP · skills · agents · rules · tools · auth · cost · output · plugin · commands · env vars · workflow patterns
- **PART III — Lifecycle** — SVG sequence diagram (6 lanes, 12 per-turn hook events, scroll-animated)
- **PART IV — Atlas** (10 cards / 14 SVG diagrams) — decision compasses · file system map · hook taxonomy radial · MCP ecosystem · auth chain · tool tree · cost matrix · hook fire heatmap · composition graph · session states · compaction flow

Interactive: fuzzy search (`/` to focus), mythology mode (17 capacities as tarot epithets), animated lifecycle on scroll, PDF poster export via `window.print()`. Vanilla JS + CSS + inline SVG only — no framework.

Live at <https://cfpperche.github.io/Agent0/cheatsheet/claude-core/> once GitHub Pages workflow finishes.

## Next steps

1. **Spec 026 Phase B — remaining tasks 21-22** (sibling owns task 20 calibration). Step 12 legal closes Specification gate; step 13 prototype-v3 is NEW visual step. Same port→judge→calibrate loop. Coordinate with sibling on task 20 before starting.
2. **Memorialize port→judge→calibrate as 8th phase** of `.claude/memory/anthill-port-workflow.md` — deferred from prior session, still pending.
3. **REMINDERS unchanged** — fair OD re-match, OD `--bump/--apply` upstream test, spec 029 adoption check (due 2026-05-30).

## Carryover (orthogonal lanes, not active)

- **Cheatsheet content drift watch** — when Claude Code ships a new version, bump `CC_VERSION` constant at top of `claude-core.astro` and re-audit. Page stamps version in banner.
- **Architecture HTML rendering** (step-9 open Q1) — vendor Cocoon-AI renderer into `packages/mcp-product-pipeline/scripts/`. Not blocking spec 026 acceptance.
- **Step-10 nits** surfaced by judge — cash-vs-GAAP reconciliation paragraph + headcount-plan callout. Sub-paragraph additions, pick up if revisiting spec 026.
- **Pyshrnk CLAUDE.md reconciliation** — long-standing parking lot.

## Decisions & gotchas

- **SVG `<text>` with HTML `<code>` children breaks layout.** Browser renders the `<code>` as inline HTML, escaping the SVG flow and squashing positioned elements. Use `<tspan fill="...">` for monospace coloring inside SVG text. Caught + fixed in `db9ace7`.
- **Cheatsheet content + chrome are decoupled.** CC version bumps need only an edit to the `CC_VERSION` constant at the top of the .astro file plus content tweaks; no schema, no JS rebuild dance.
- **Atlas section is dense (~5 MB page) but A3-printable.** The "↓ A3 poster" toolbar button triggers `window.print()` against the existing print stylesheet — works cleanly across all 4 parts including the animated lifecycle SVG (force-final-state under @media print).
