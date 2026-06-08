# 168 - agent0-roadmap-html

_Created 2026-06-08._

**Status:** shipped

**UI impact:** render

## Intent

Create a standalone HTML page in Agent0 that presents the Agent0 governance roadmap in a visual, roadmap.sh-inspired format: the categories discussed in specs 166 and 167, what exists today, and what remains deferred or missing. The page should be inspectable by opening the HTML directly, without introducing a new frontend stack.

## Acceptance criteria

- [x] **Scenario: roadmap page renders**
  - **Given** a browser opens `docs/agent0-roadmap.html`
  - **When** the page loads
  - **Then** it shows the Agent0 roadmap heading, category filters, status legend, and a connected roadmap map

- [x] **Scenario: current and missing work are visible**
  - **Given** a maintainer reviews the page
  - **When** they inspect any governance category
  - **Then** the page distinguishes current shipped capabilities from deferred/missing follow-ups

- [x] **Scenario: no new stack is introduced**
  - **Given** the repo has no resolved root frontend stack
  - **When** this spec is delivered
  - **Then** the page is a standalone HTML/CSS/JS file and does not add npm/bun/package dependencies

- [x] `docs/specs/168-agent0-roadmap-html/reference-research.md` and `design-direction.md` exist.
- [x] `docs/specs/168-agent0-roadmap-html/fixture-spec.json` exists for render-tier browser verification.
- [x] The page passes render-tier visual-contract verification with `agent-browser`.

## Non-goals

- Clone roadmap.sh exactly, copy roadmap.sh branding/assets, or use its source code.
- Add this page to the Astro site navigation or rebuild `site/dist/`.
- Create a live dashboard, generated roadmap pipeline, or product surface.
- Commit runtime screenshots or browser evidence.

## Open questions

- [ ] Should this page later become generated from specs/rules instead of manually curated?
- [ ] Should the existing Astro site expose this page after the content stabilizes?

## Context / references

- `docs/specs/166-agent0-governance-doctrine/`
- `docs/specs/167-scope-admission-governance/`
- `.agent0/context/rules/agent0-governance-doctrine.md`
- `.agent0/context/rules/scope-admission-governance.md`
- `.agent0/HANDOFF.md`
- `https://roadmap.sh/`
- `https://roadmap.sh/roadmaps/?g=Web+Development`
