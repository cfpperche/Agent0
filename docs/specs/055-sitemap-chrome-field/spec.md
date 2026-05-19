# 055 — sitemap `chrome` field orthogonal to `category`

**Status:** draft

## Problem

`sitemap-schema.md` enforces 5 required_categories `[marketing, auth, primary, admin, error]` to guarantee PRD coverage (no silently-undercovered surface). The `category` field is also implicitly used by per-stack screen-writers to decide the route-group path:

- `category: primary` or `admin` → `app/(app)/<path>` (shared chrome)
- `category: marketing` → `app/(marketing)/<path>` (marketing chrome)
- `category: auth` → flat `app/<path>` (chromeless)

This conflates two orthogonal concerns:

- **(a) PRD coverage semantic** — which surface satisfies which US (required by schema enforcement).
- **(b) Runtime chrome inheritance** — which `layout.tsx` the page sits under at runtime.

Dogfood-2 evidence: `/[clinicSlug]/agendar` + `/[clinicSlug]/portal` are functionally tutor-public chromeless surfaces (clinic-branded white-label). The sitemap sub-agent filed them as `category: primary` to satisfy the schema (no silent undercoverage), but the per-stack screen-writer correctly placed them under `app/(booking)/` after the parent overrode the chrome decision — sub-agent screen-writers couldn't have made that call from `category` alone.

## Acceptance criteria

- [ ] **Scenario: sitemap declares `chrome` orthogonal to `category`**
  - **Given** a tutor-public route serving the same `category: primary` for PRD coverage
  - **When** Step 07 sub-agent emits sitemap.yaml
  - **Then** the route entry has both `category: primary` AND `chrome: booking`
- [ ] **Scenario: per-stack screen-writer reads `chrome` for routing decision**
  - **Given** a route with `chrome: booking`
  - **When** the per-stack screen-writer dispatches
  - **Then** `page.tsx` is placed at `app/(booking)<path>/page.tsx`, NOT `app/(app)<path>/page.tsx`
- [ ] **Scenario: atlas writes a route-group layout per `chrome` value**
  - **Given** sitemap routes spread across `chrome ∈ {app, marketing, booking}`
  - **When** atlas writer dispatches
  - **Then** `app/(app)/layout.tsx`, `app/(marketing)/layout.tsx`, and `app/(booking)/layout.tsx` are each written (if ≥1 route in that chrome)

## Non-goals

- Reworking category semantics (5 required_categories stays).
- Adding chrome categories beyond `{app, marketing, booking, auth, chromeless}` — that enum is closed for v1.
- Multi-chrome routes (a single route inheriting two layouts — rejected, Next.js doesn't compose nested route groups that way).

## Open questions

1. Backward compatibility: existing dogfoods without `chrome:` — orchestrator default-infers from category mapping, or hard-requires migration?
2. Should `chrome` be required field on every route, or default-inferred from category?
3. Auth category: `chrome: auth` (own group layout with consistent auth shell) or `chrome: chromeless` (flat)?
