# 126 — site-refactor

_Created 2026-05-30._

**Status:** in-progress

## Resolved decisions (debate 126 gate — 2026-05-30)

The load-bearing gate from `debate.md` is resolved. Acceptance below is written to this **single resolved branch**, not conditionally:

- **Site identity:** OSS-project landing for the Agent0 open-source project.
- **Primary audience:** developers evaluating / forking Agent0.
- **Lead capture:** none in v1.
- **Claim stance:** capability/expertise framing only — cite repo specs/dogfood/hooks; **no business-result metrics**.

## Intent

Complete, **in-place** refactor of the Agent0 marketing site (`site/` — Astro 5 + Tailwind 4; three content locales `/en/`,`/pt/`,`/es/` + a root redirect to `/en/`) across four axes: content/positioning, visual/brand, architecture/code, perf/SEO/a11y. **The cross-model debate reversed the original premise.** The refactor was opened on the assumption that the site was mis-positioned (mechanism-led instead of outcome-led); resolving the identity gate established that this surface is the **open-source project landing for developers**, so "The harness for AI coding agents" is an honest product category, not a defect. The thesis is therefore a *developer-facing* improvement of the existing OSS landing: sharpen the governance/discipline value story, **kill the stale capacity inventory** (the hardcoded "Eighteen capacities" and any out-of-date counts) in favor of the current, multi-runtime-accurate truth, modernize the visual system into something coherent and reusable, and tighten architecture/perf/SEO/a11y — with no stack migration and no lead capture. Content/positioning is the **phase gate**; visual and architecture work is subordinate to the approved copy architecture; perf/SEO/a11y is a non-regression guardrail throughout.

## Acceptance criteria

_Observable outcomes, written to the resolved OSS-landing-for-developers branch. The model-visible / build contract must not regress._

- [ ] **Scenario: Root canonicalizes to a locale correctly**
  - **Given** a visitor hits the site root (`/Agent0/`)
  - **When** the page loads
  - **Then** it redirects/canonicalizes to a locale entry (`/en/`) without rendering a broken or blank intermediate

- [ ] **Scenario: Each locale hero states developer value accurately**
  - **Given** any locale page (`/en/`, `/pt/`, `/es/`)
  - **When** a developer reads the hero
  - **Then** it clearly states what Agent0 does *for them* (the governance/discipline value of the harness), with no stale or unverifiable claim — "harness" framing is allowed and expected

- [ ] **Scenario: The capacity / MCP inventory is current**
  - **Given** the refactored page
  - **When** the capacity/MCP sections render
  - **Then** the counts and contents match the repo's real, multi-runtime-accurate state — the dead "Eighteen capacities" magic number is gone

- [ ] **Scenario: Claim classes are enforced**
  - **Given** all shipped copy
  - **When** reviewed
  - **Then** capability claims cite a real basis (repo specs / dogfood / hooks / tests) and **no business-result metric claim** (delivery time, incident rate, revenue) ships — unsubstantiated copy is cut on contract

- [ ] **Scenario: All locales refactored in lockstep**
  - **Given** the three content surfaces (`/en/`, `/pt/`, `/es/`) + root redirect
  - **When** the new copy/structure ships
  - **Then** every locale carries it with no untranslated fallback across the three `strings.ts` entries; no locale-specific regression

- [ ] **Scenario: Build + stack preserved**
  - **Given** the in-place constraint
  - **When** `bun run build` runs in `site/`
  - **Then** it succeeds on the existing Astro 5 + Tailwind 4 toolchain with no stack swap

- [ ] **Scenario: Non-functional quality does not regress against a named baseline**
  - **Given** a pre-refactor baseline artifact captured before work starts (recorded in `notes.md` or a small audit file: exact URLs `/en/`,`/pt/`,`/es/`, tool/command, viewport, pass/fail thresholds)
  - **When** the refactor ships
  - **Then** performance, SEO meta/OG (including resolving the current missing `og:image`, with `twitter:card` already `summary_large_image`), and a11y (contrast, semantics) are equal-or-better against that baseline

- [ ] **Scenario: Phase boundary is observed**
  - **Given** the four-axis scope in one phased spec
  - **When** work proceeds
  - **Then** content/positioning (copy architecture for the dev audience) is approved before visual/code refactor starts; perf/SEO/a11y is checked as a guardrail throughout

- [ ] Visual redesign is expressed as a coherent, reusable design system (tokens/components), not ad-hoc per-section styling; IA/component restructure **is in scope** for this "complete" refactor
- [ ] `dist/` is gitignored local-verification output (not a tracked deliverable); the deploy target is GitHub Pages (`cfpperche.github.io/Agent0/`)

## Non-goals

- **No stack migration.** Stays Astro 5 + Tailwind 4 + the current i18n approach (in-place evolution, not a rebuild; no-shipped-stack-opinions discipline).
- **No change to the Agent0 product/repo itself** — only `site/` is in scope.
- **No new CMS, blog, or content backend** — static Astro stays static.
- **No dropping or reducing locales** — i18n breadth preserved.
- **No lead capture / contact funnel in v1** — no form, email CTA, or calendar link.
- **No pivot to consultancy / outcomes positioning** — explicitly killed by the resolved identity decision; this is the OSS project's developer landing.
- **Keep the existing dev-oriented CTAs** (GitHub + quickstart) as the primary action; the refactor sharpens them, it does not replace them with a sales funnel.

## Open questions

- [ ] **Visual/brand source of truth** — align the visual redesign to an existing brand artifact (`/product` brand step / `/image` brand assets), or run a dedicated visual discovery? Owner: resolve at `/sdd plan` time. (Non-blocking for plan start; the content/positioning phase gate precedes visual work.)

## Context / references

- `docs/specs/024-public-landing/` — the originating spec; shipped this explicitly as a public OSS landing for Claude Code at `cfpperche.github.io/Agent0/` (the historical contract that grounded the identity resolution).
- `docs/specs/126-site-refactor/debate.md` — the Claude×Codex debate that reversed the premise and resolved the gate; Synthesis = `converged`.
- `site/` — Astro 5 + Tailwind 4; three content locales (`en`/`pt`/`es`) via `src/i18n/locales.ts`, `src/pages/index.astro` redirects root to `/en/`; components: `Hero`, `CapacityGrid`, `McpGrid`, `WhyBuilt`, `QuickStart`, `HowToExtend`, `Faq`, `Header`, `Footer`, `LanguageSwitcher`, `CodeBlock`.
- `site/src/i18n/strings.ts` — current copy (the mechanism-led headlines + the "Eighteen capacities" stale inventory).
- Memory: `feedback_no_shipped_stack_opinions` (in-place, no migration), `feedback_bio_framing` (expertises/capabilities framing — the resolved claim stance), `feedback_speculative_observability` (rule-of-three / no-speculative-claim — gates capability claims), `feedback_consultancy_positioning` (the directive whose scope the debate clarified does NOT apply to this OSS-landing surface).
