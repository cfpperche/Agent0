# 127 — site-content-refactor

_Created 2026-05-30._

**Status:** in-progress

## Resolved decisions (debate 127 gate — 2026-05-30)

Resolved by the Claude×Codex debate (`Resolution: converged`) + user gate. Acceptance below is written to this single resolved branch:

- **Page granularity:** grouped-by-theme explanatory pages (≈5–6: safety gates / spec workflow / validators / runtime & session / skills & tooling) + a "how the harness works" overview. NOT per-capacity (~23 pages was doc-bloat that duplicates the rules and re-stales).
- **i18n scope:** **en-first** for the new explanatory routes; `pt`/`es` are a **tracked, blocking follow-up**, documented as an **explicit, named exception to spec 126's no-locale-reduction contract** — routes are never silently absent/stubbed/fallback. The existing landing stays full 3-locale.
- **Link hierarchy:** card → on-site explanatory page → "source on GitHub". The source link prefers current `.agent0/context/rules/*` or `.agent0/skills/*`; early `docs/specs/00*` may appear **only** as a labeled "history" link, never the primary current target.
- **Derive vs curate (anti-restaling boundary):** *derive* from the repo at build time — identifiers, counts, source links, runtime status, source paths; *hand-author* — explanatory prose and examples. No machine-rendered mirror of the rules.
- **Currency mechanism:** a typed content manifest + a build-time check that fails verification on staleness (conditions pinned in acceptance; schema in `plan.md`).

## Intent

Spec 126 fixed the site's surface currency — capacity counts (now derived), multi-runtime copy, og:image, redirect — but the **content still misrepresents the harness's current state at a deeper level**, and the site has no explanatory surface of its own. Two concrete failures: (1) capacity cards carry `spec NNN` badges and links pointing at **early specs (001, 002, 003, …) that have since been refactored/superseded** across dozens of later specs — clicking a card lands the visitor on stale original intent, not current behavior; (2) the only "learn more" path is raw GitHub markdown (rules/specs) — there is no on-site page explaining a capacity or how the harness actually works. This spec refactors **all page content to reflect the harness's current, multi-runtime reality** and adds **on-site explanatory pages** (grouped-by-theme + a "how the harness works" overview), so the site is self-explanatory and truthful rather than a link-farm into superseded specs. It is an **IA expansion** beyond 126's single-page in-place scope (new routes), still in-place on Astro 5 + Tailwind 4 + i18n (no stack migration), still the OSS-project-landing-for-developers identity resolved in spec 126.

## Acceptance criteria

_Observable outcomes. The 126 contract (build, stack, harness-honest positioning) must not regress; the locale contract is amended by the documented en-first exception above._

- [ ] **Scenario: No card links to a superseded/early spec as if it were current**
  - **Given** the capacity inventory on the page
  - **When** a visitor follows a card's "learn more" affordance
  - **Then** it lands on current canonical truth via the resolved hierarchy (on-site page → current rule/skill → optional "history" spec link); no `docs/specs/00*` is the *primary* target, and misleading `spec NNN` badges are removed or re-pointed

- [ ] **Scenario: Grouped explanatory pages + overview exist**
  - **Given** a visitor wanting to understand the harness without reading raw repo markdown
  - **When** they navigate from a capacity or the nav
  - **Then** ≈5–6 grouped-by-theme pages describe the capacities (what each does, current multi-runtime behavior, how to use it) AND a "how the harness works" overview explains how hooks ↔ rules ↔ skills ↔ runtimes fit as a system

- [ ] **Scenario: Every content surface is audited against current state**
  - **Given** the surfaces in `strings.ts` (hero, whyBuilt, quickStart, howToExtend, faq, mcps, nav, footer, meta), `capacities.ts`, and `mcps.ts`
  - **When** reviewed against the live repo (`CLAUDE.md`, `.agent0/context/rules/`, `runtime-capabilities.md`)
  - **Then** no copy references a refactored-away behavior, superseded path, or stale spec number — including the known defects `howToExtend` "Register new hooks in .claude/settings.json" (Codex uses `.codex/hooks.json`) and `whyBuilt` "the agent cannot drift out of" (enforceability overclaim)

- [ ] **Scenario: Per-capacity runtime status is accurate, not globally "multi-runtime"**
  - **Given** any explanatory page/group
  - **When** it describes a capacity
  - **Then** it states the current Claude/Codex status sourced from `runtime-capabilities.md`, distinguishing enforcement / advisory / read-only / convention / planned, and "works-now (human-brokered/native)" vs "automation-planned" (e.g. cross-model debate works human-brokered today; the automated runner is 091)

- [ ] **Scenario: Anti-restaling currency check fails the build on drift**
  - **Given** the typed content manifest
  - **When** the build/verification runs
  - **Then** it FAILS if a `sourcePath` 404s locally, a card targets `docs/specs/00*` as primary, a capacity lacks an explanatory route, or a resolved-locale page is missing — staleness is caught mechanically, not by manual vigilance

- [ ] **Scenario: New routes carry full route/nav/meta wiring**
  - **Given** each new public route
  - **When** the site builds
  - **Then** it exists for the resolved locale set, has a working language-switch equivalent, is linked from the landing flow (not orphaned), preserves the root redirect, and carries its own title/description/OG — no route strands the user on raw GitHub markdown as the first explanatory surface

- [ ] **Scenario: Build + stack preserved**
  - **Given** the in-place constraint
  - **When** `bun run build` runs in `site/`
  - **Then** it succeeds on Astro 5 + Tailwind 4 with no stack swap

- [ ] Content derived/curated per the resolved boundary (derive ids/counts/links/runtime-status/paths; hand-author prose) — not a machine-rendered mirror of the rules
- [ ] No business-result-metric claims (126 claim-stance carries over: capability/expertise framing only)

## Non-goals

- **No stack migration** — in-place on Astro 5 + Tailwind 4 + current i18n.
- **No re-opening the site identity** — stays the OSS-project landing for developers (spec 126 resolved gate); no consultancy/outcomes pivot.
- **No lead capture / sales funnel** (carries over from 126).
- **No full visual redesign** — 126's visual system + design tokens stay; new pages reuse them. (Bolder visual direction remains 126's OQ5.)
- **No auto-generated API-style docs dump** — explanatory prose is hand-authored for a developer reader; only the structured bits (ids/counts/links/status/paths) are derived (see § Resolved decisions).
- **No per-capacity pages** — grouped-by-theme is the resolved IA.
- **pt/es parity for the new routes is NOT in v1** — explicit, tracked exception to 126; it is a blocking follow-up, not abandoned.

## Open questions

_All resolved into § Resolved decisions or acceptance by the debate. None blocking `/sdd plan`._

## Context / references

- `docs/specs/126-site-refactor/` — predecessor; fixed surface currency + positioning, explicitly an in-place single-page pass. This spec extends it to deep content truth + IA expansion. The 126 link/badge staleness is the motivating defect; the en-first locale exception is a documented amendment to 126.
- `docs/specs/127-site-content-refactor/debate.md` — the Claude×Codex debate; `Resolution: converged`, 8 critique points accepted.
- `site/` — Astro 5 + Tailwind 4; routes today are only the redirect + `/en/`,`/pt/`,`/es/` landings (no sub-pages); `src/i18n/{strings,capacities,mcps}.ts` hold the content; `src/components/*` the sections.
- `CLAUDE.md`, `.agent0/context/rules/*`, `.agent0/context/rules/runtime-capabilities.md` — the current source of truth the content + manifest must reconcile against.
- Memory: `feedback_consultancy_positioning` (§ Scope note: this is the OSS landing, not consultancy), `feedback_no_shipped_stack_opinions`, `feedback_speculative_observability` (rule-of-three / no-speculative-claim), `feedback_bio_framing` (capability/expertise framing).
