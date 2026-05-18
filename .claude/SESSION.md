# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 048 (`product-skill-foundation`) — SHIPPED in this session.** Two coupled changes: (1) skill rename `/prototype` → `/product` (semantic reframe: foundation generator + design partner for product lifecycle, NOT throwaway prototype); (2) layout refactor — drop `NN-` prefix, emit semantic-named artifacts under `<out>/docs/` (PRD release-scoped at `prd/v1.md` subfolder from day 1; design system grouped at `design-system/`). Skill v0.2.0 → v0.3.0. State.json v3 → v4 (breaking). Dogfood: `/tmp/dogfood-erp/` (ERP para salões de beleza) cold-cache full 15-step PASS — 24 routes generated, tsc + biome clean. Bundled skeleton `globals.css` token import path updated 3rd time (`docs/06-tokens.css` → `docs/14-tokens.css` → `docs/design-system/tokens.css`). MCP discontinuation cascade explicitly OUT OF SCOPE (handled in MCP session).

**Spec 047 (`php-laravel-support`) — SHIPPED + pushed (sibling session).** Made Agent0 PHP/Laravel-aware end-to-end across 7 capacities. 24 tests passing. Acme Yard project bootstrapped at `/home/goat/acmeyard` with Laravel 13.8 + Agent0 harness synced; public repo live at https://github.com/cfpperche/acmeyard. Domain `acmeyard.com` purchase in flight.

## WIP (uncommitted)

Spec 048 work needs commit:
- `R/RM` block: `.claude/skills/prototype/**` → `.claude/skills/product/**` (~50+ renames)
- `M .claude/skills/product/SKILL.md` (name + description + version 0.3.0)
- `M .claude/skills/product/references/{state-machine,delegation-briefs,pipeline-coverage,quality-checklist,stack-defaults}.md`
- `M .claude/skills/product/templates/**/prompt.md` (output paths semantic + token path)
- `M .claude/skills/product/templates/monorepo-skeleton/next/app/{globals.css,layout.tsx}`
- `M CLAUDE.md` (`## Prototype skill` → `## Product skill`)
- `M docs/specs/045-prototype-skill-pipeline-realign/spec.md` (§ Lineage note)
- `?? docs/specs/048-product-skill-foundation/{spec,plan,tasks}.md`

Pre-existing dirty (NOT mine, leave alone): `.claude/skills/brainstorm/templates/render.html.tmpl`.

## Next steps

1. **Commit spec 048 work.** Suggested: `feat(048): /product skill foundation — rename + production-shaped layout`. Skip brainstorm template.
2. **Spec 049 candidate — `product-skill-vN-mode`** — post-launch evolution primitives (`/product --mode=evolve --existing=<docs>` + `/product promote`). Picks up the gap MCP was supposed to fill. High founder value.
3. **Spec 050 candidate — schema-ceiling reconciliation.** Persistent finding across spec 045 + 048 dogfoods: Steps 03/04/08/10/11/14 schemas mandate sizes that conflict with brief ceilings. Pick one canonical truth.
4. **Spec 051 candidate — validator-cascade structural fix.** Per-file scope OR ship pre-spec biome.json defaults so sub-agents don't burn loop-budget on sibling lint errors.

## Decisions & gotchas

- **`/product` name ratified** via `/goal confirmo tudo, pode implementar e validar o plano`. Rejected `/blueprint`, `/foundry`, `/launchpad`, keep-`/prototype`-with-reframe.
- **Slug numbering bumped 046 → 048.** Sibling sessions claimed 046 (sdd-in-flight-notes) + 047 (php-laravel-support) during this work. Renamed cleanly.
- **MCP discontinuation announced — Agent0's foundation tool becomes `/product` going forward.** Spec 032 children 037-044 (MCP-side) are no longer planned. Reconciliation of spec 032 with this reality is user's MCP-session concern.
- **PRD release-scoped via `prd/v1.md`** from day 1 — forces founder to think "this PRD is v1, there will be v2" instead of "this is THE PRD". OST/roadmap/cost stay flat (`docs/ost.md`) — founder promotes to subfolder when accumulation justifies.

## Carryover (orthogonal)

- Spec 045 full end-to-end cold-cache run — DONE this session at /tmp/dogfood-v3/ (already shipped).
- Spec 046 dogfood window — promotion gate 2026-07-01.
- Spec 029 adoption check due 2026-05-30.
- Spec 026 Phase C/D pending.
- Acme Yard substrate work — `/sdd new substrate` in `/home/goat/acmeyard` (mês 0 of Acme Yard).
- `.claude/REMINDERS.md` items per startup readout.
