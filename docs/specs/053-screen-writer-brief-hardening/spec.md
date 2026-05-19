# 053 — screen-writer brief hardening

**Status:** shipped

## Problem

Dogfood-2 (`/tmp/dogfood-vet`, Vetro ERP) surfaced 5+ findings traceable to gaps in `.claude/skills/product/references/delegation-briefs.md § Per-stack screen-writer CONSTRAINTS`. Sub-agents do literally what the brief asks; they do not do what no one asked.

Recurring gaps observed:

- **Per-route `metadata` absent** — only 2/24 routes exported `export const metadata: Metadata`; 22 inherited the root title, hurting SEO and browser-tab orientation.
- **States declared in `sitemap.routes[].states[]` not implemented** — e.g. `/estoque` declared `[default, loading, empty, error]` but sub-agent emitted only `default` + `loading`; no empty-render branch.
- **Biome anti-patterns recurring** — `key={i}`, `<div role="status">`/`<div role="article">`, `dangerouslySetInnerHTML` forced fork-local biome.json relax to unblock the build.
- **"Primary metric" prominence missed** — operational metrics like "Caixa atual R$ 1.450,00" rendered as small top-right badges instead of MetricTile/hero.

Root cause: the brief leaves these decisions to the sub-agent's judgment. They are mechanical — `do X / don't do Y` — and belong in CONSTRAINTS.

## Acceptance criteria

- [ ] **Scenario: per-route metadata is exported**
  - **Given** a sitemap entry with `path`, `category`, `display_name` (or derivable from path)
  - **When** the per-stack screen-writer is dispatched
  - **Then** the resulting `page.tsx` exports `export const metadata: Metadata = { title, description }` where `title` matches the route's display name and `description` matches its purpose
- [ ] **Scenario: every declared state has implementation evidence**
  - **Given** `sitemap.routes[].states: [default, loading, empty]`
  - **When** the screen-writer is dispatched for that route
  - **Then** `loading.tsx` sibling exists AND a page-internal render branch handles `length === 0` (or `<EmptyState>` is referenced)
- [ ] **Scenario: Biome anti-pattern checklist is enforced at brief time**
  - **Given** a screen-writer producing a skeleton `loading.tsx`
  - **When** biome check runs after the edit
  - **Then** no `key={i}` from `.map((_, i) =>)` appears AND no `<div role="status|article|region">` (use `<output>/<article>/<section>`) AND no `dangerouslySetInnerHTML`
- [ ] **Scenario: primary metric surfaces as MetricTile, not badge**
  - **Given** a sitemap entry with `primary_metric: "Caixa atual"` (new field, optional)
  - **When** the screen-writer is dispatched
  - **Then** the metric renders as a MetricTile or hero-level element, NOT a small badge in a corner

## Non-goals

- Adding sitemap fields beyond `primary_metric` (chrome is spec 055; voice glossary is spec 054)
- Post-write QA agent to validate brief adherence (rejected this session — see `.claude/SESSION.md`)
- Hard-fail validator on Biome anti-patterns (would worsen validator-cascade — see spec 057)

## Open questions

1. Is `primary_metric` an optional sitemap field, or implicit (orchestrator scans for value-token shapes like `R$`/`%`)?
2. If sitemap declares `states: [empty]` but the data model has no degenerate case, should the brief allow the sub-agent to flip the state to `deferred_states: [{name: empty, reason}]`?
3. Should the Biome anti-pattern checklist be inline in the brief body verbatim, or extracted to a referenced rule (`.claude/rules/biome-anti-patterns.md`)?
