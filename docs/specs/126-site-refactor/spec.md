# 126 — site-refactor

_Created 2026-05-30._

**Status:** draft

## Intent

Complete, **in-place** refactor of the Agent0 marketing site (`site/` — Astro 5 + Tailwind 4 + 4-locale i18n) across four axes — content/positioning, visual/brand, architecture/code, and perf/SEO/a11y — with **positioning realignment as the load-bearing driver**. The current site leads with the *mechanism*: `meta.title` and `hero.title` are literally "The harness for AI coding agents", the tagline opens "Agent0 is a base repository that ships the discipline — hooks, rules, spec-driven workflow", the opening section is "Eighteen capacities, all opt-in", and the entire IA (`CapacityGrid`, `McpGrid`, `HowToExtend`, `QuickStart`, `WhyBuilt`) is harness-onboarding-centric. This contradicts the standing consultancy-positioning directive — *lead with business outcomes and solution delivery, not methodology; Agent0 is one capability, never the headline*. The refactor keeps the stack (Astro + Tailwind + i18n; no migration) and evolves the current codebase rather than rebuilding from scratch. It serves whoever the site's primary visitor turns out to be — and pinning that audience is itself an open question this spec must resolve before `plan.md` locks.

## Acceptance criteria

_Observable outcomes. Positioning criteria are the spec's spine; the other three axes must not regress and should measurably improve._

- [ ] **Scenario: Above-the-fold leads with an outcome, not the mechanism**
  - **Given** a first-time visitor lands on the site root
  - **When** they read the hero (headline + tagline + primary CTA) without scrolling
  - **Then** the headline names a business outcome / value delivered, and the words "harness", "capacities", and a bare "Agent0 is a base repository…" do NOT carry the primary headline

- [ ] **Scenario: Mechanism is demoted to supporting evidence**
  - **Given** the refactored page
  - **When** a reader scrolls past the hero
  - **Then** harness mechanics (capacities, MCPs, hooks, spec-driven workflow) appear as proof/credibility below the fold — present and honest, but subordinate to the outcome narrative

- [ ] **Scenario: All locales refactored in lockstep**
  - **Given** the 4 i18n surfaces (default + en/es/pt)
  - **When** the new copy + structure ship
  - **Then** every locale carries the new positioning with no untranslated fallback and no locale-specific regression

- [ ] **Scenario: Build + stack preserved**
  - **Given** the in-place constraint
  - **When** `bun run build` runs in `site/`
  - **Then** it succeeds on the existing Astro 5 + Tailwind 4 toolchain with no stack swap, and `dist/` is rebuilt

- [ ] **Scenario: Non-functional quality does not regress**
  - **Given** the pre-refactor Lighthouse / meta-OG / a11y baseline (captured before work starts)
  - **When** the refactor ships
  - **Then** performance, SEO meta/OG, and accessibility (contrast, semantics) are equal-or-better against that baseline

- [ ] Visual redesign is expressed as a coherent, reusable design system (tokens/components), not ad-hoc per-section styling
- [ ] No business-outcome claim ships without a substantiating basis (real case/metric/capability) — aspirational/unverifiable claims are cut, per the rule-of-three / no-speculative-claim discipline

## Non-goals

- **No stack migration.** Stays Astro 5 + Tailwind 4 + the current i18n approach; this is an in-place evolution, not a rebuild (per the no-shipped-stack-opinions discipline — the stack choice is not relitigated here).
- **No change to the Agent0 product/repo itself** — only `site/` (the marketing surface) is in scope.
- **No new CMS, blog, or content backend** — static Astro stays static.
- **No dropping or reducing locales** — i18n breadth is preserved, not trimmed.
- **Not standing up a separate second site** (e.g. a distinct consultancy domain) — unless the identity open question explicitly resolves that way, this refactors the existing single surface.

## Open questions

- [ ] **Site identity — OSS-project landing vs consultancy outcomes-site vs hybrid?** This is load-bearing: if `site/` is the *Agent0 open-source project* page, then "the harness for AI coding agents" is arguably an honest, correct subject and the positioning critique partly dissolves. If it's a *consultancy* surface, mechanism-led copy is the defect the directive names. The refactor's whole shape depends on which. Owner: user.
- [ ] **Primary audience** — potential consulting clients (want outcomes) or developers evaluating Agent0 OSS (want mechanism)? The two demand near-opposite headlines; a hybrid risks serving neither. Owner: user.
- [ ] **Outcome-claim substantiation** — leading with business outcomes needs proof (cases, metrics, named results). Do those exist yet, or would outcome-led copy be aspirational? If unsubstantiated, what's the honest interim framing (expertises/capabilities cultivated, per the bio-framing directive) rather than fabricated results? Owner: user + evidence audit.
- [ ] **Scope sequencing** — all four axes in one big-bang refactor, or content/positioning first (the driver) then visual → perf as follow-ons? Big-bang risks a stalled half-migration; phased risks an awkward intermediate. Owner: debate + user.
- [ ] **Visual/brand source of truth** — align to an existing brand artifact (e.g. `/product` brand step / `/image` brand assets), or does the visual axis need its own design discovery before plan? Owner: user.

## Context / references

- `docs/specs/024-public-landing/` — the originating spec that built the current site.
- `site/` — Astro 5 + Tailwind 4, 4 locales; components: `Hero`, `CapacityGrid`, `McpGrid`, `WhyBuilt`, `QuickStart`, `HowToExtend`, `Faq`, `Header`, `Footer`, `LanguageSwitcher`, `CodeBlock`.
- `site/src/i18n/strings.ts` — current copy (the mechanism-led headlines quoted in § Intent).
- Memory: `feedback_consultancy_positioning` (outcomes over harness — the driver), `feedback_no_shipped_stack_opinions` (why in-place, no migration), `feedback_bio_framing` (expertises over feature-inventory — candidate honest framing if outcomes are unsubstantiated), `feedback_speculative_observability` (rule-of-three / no-speculative-claim — gates outcome claims).
- Reminder `r-2026-05-30` family: `site/dist/` was already pending a rebuild (122/123/124 changed source strings) — this refactor subsumes it.
