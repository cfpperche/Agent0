# sitemap.yaml schema

The `sitemap.yaml` file produced by Phase 2 Subagent A drives Phase 3's per-route dispatches and Phase 4's coverage scorecard. This file defines its schema and the validation rules the skill enforces after Subagent A returns.

## Top-level shape

```yaml
slug: <kebab-case product slug, matches /tmp/prototype-<slug>/>
platform: web | mobile
stack: next | expo
required_categories:
  - marketing
  - auth
  - primary
  - admin
  - error
routes:
  - path: /
    category: marketing
    states: [default]
    covers_us: ["landing impression", "primary CTA click"]
    components: [Hero, FeatureGrid, FooterCTA]
  - path: /login
    category: auth
    states: [default, loading, error]
    covers_us: ["email entry", "submit + auth error path"]
    components: [LoginForm, OAuthButtons]
  # ...
```

## Required fields per route

| Field | Type | Required | Constraint |
|---|---|---|---|
| `path` | string | yes | starts with `/`; matches stack's path convention (Next.js: `/foo/bar`; Expo: `/foo/bar` since expo-router uses path syntax) |
| `category` | string | yes | must be one of `marketing | auth | primary | admin | error` |
| `states` | list of strings | yes | at least 1; primary screens MUST include `default`, `loading`, `empty`, `error` (per quality-checklist.md states-coverage matrix) |
| `covers_us` | list of strings | yes | at least 1; each entry is a user-story-fragment in 3-8 words |
| `components` | list of strings | yes | at least 1; component names in PascalCase; subagent-screen-writer treats these as targets to materialize |

## Required categories enforcement

`required_categories: [marketing, auth, primary, admin, error]` — the skill validates that at least one route per category is present in `routes`. Missing categories trigger:
- **Gap audit entry in REPORT.md** — names the missing category + names what the skill auto-compensated (e.g., "auth missing from sitemap — agent added /login, /signup, /reset")
- **Phase 4 stamp** — REPORT.md gap-audit section lists each compensation by mechanism vs founder-explicit

## Validation rules (post-Subagent-A return)

The skill runs these checks before dispatching Phase 3:

1. **Schema parses** — valid YAML, top-level keys match shape
2. **slug matches** — `slug` field equals the slug passed to `/prototype`
3. **5 categories present** — every entry in `required_categories` appears as at least one route's `category`
4. **Per-route fields complete** — every route has all 5 required fields with valid types
5. **Path uniqueness** — no duplicate `path` values
6. **Component name validity** — `components` entries match `^[A-Z][A-Za-z0-9]*$`
7. **Minimum screen count by product class** — Micro: ≥6 routes; Mobile/Dev Tool/SMB SaaS: ≥12 routes; Venture: ≥20 routes (calibration from spec 026 task 22 implicit)

If validation fails, the skill prompts the user with the specific failures and offers two options: (a) re-run Subagent A with augmented brief addressing the gaps, (b) edit `sitemap.yaml` manually and re-validate.

## Why this schema (and not just freeform)

The 5-category requirement forces the agent to think about ALL surfaces (not just the "happy path screens" a founder mentions). Real apps have marketing pages, auth flows, primary feature surfaces, admin/settings, AND error states; omitting any of these is the most common prototype gap surfaced by spec 032 research (Eleken / Slickplan / Raw.Studio all enforce this in their sitemap deliverables). The `states` field per route is the second-most-common gap — building only the happy path produces prototypes that crumble on first edge case.
