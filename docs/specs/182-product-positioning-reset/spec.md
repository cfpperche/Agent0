# 182 — product-positioning-reset

_Created 2026-06-09._

**Status:** shipped
<!-- Bare enum only: draft | in-progress | shipped | shipped-partial | superseded | abandoned | deferred. Do NOT append dates/commits/test-counts/rationale here — that goes on the optional **Closure:** line below. -->

**Closure:** 2026-06-09 — README/LICENSE/site/proof reset implemented; site maintenance default reopened; `bun run build` in `site/` passed; `agent-browser.sh verify-contract` passed against local preview; `git diff --check` passed for spec 182 files; residual: license holder can be revised from `cfpperche` later if requested.

**UI impact:** render

## Intent

Agent0's public surface should explain the actual product thesis: Agent0 is not another coding agent, SaaS control plane, or application framework. It is a portable governance and evidence harness for existing coding-agent runtimes, currently Claude Code and Codex, focused on disciplined work loops: intent before code, bounded delegation, validation evidence, session continuity, and syncable harness state. This reset removes the stale capacity-count narrative, adds a real license, and records a concise proof/limits document without trying to measure adoption across local consumer projects yet.

## Acceptance criteria

- [x] **Scenario: README states the product thesis**
  - **Given** a reader opens `README.md`
  - **When** they read the opening sections
  - **Then** they can tell Agent0 is a portable governance/evidence harness for existing coding agents, not a coding agent or app runtime itself

- [x] **Scenario: Landing page matches the thesis**
  - **Given** a reader opens the English, Portuguese, or Spanish landing page
  - **When** they read the hero and explanatory sections
  - **Then** the copy centers portability, evidence, continuity, and disciplined commits instead of raw capacity count or AI-agent hype

- [x] **Scenario: Product proof is honest about evidence level**
  - **Given** a reader opens the proof document
  - **When** they inspect the current evidence claims
  - **Then** it distinguishes local dogfood and multi-runtime repo evidence from external adoption or commercial traction

- [x] `LICENSE` exists at the repo root and README no longer says no license is shipped.
- [x] The stale "Eight capacities" framing is removed from README.
- [x] This spec does not add a consumer adoption, local consumer inventory, or dogfood-health measurement task.
- [x] The public site renders the repositioned landing by default while retaining an explicit maintenance override.

## Non-goals

- Measuring adoption across local consumer projects.
- Creating a dashboard, daemon, SaaS surface, telemetry system, or product analytics loop.
- Removing existing capacities or changing harness behavior.
- Repositioning Agent0 as a standalone coding agent, IDE, hosted service, or application framework.
- Rewriting every detailed docs page in this pass; the reset targets first-contact surfaces and a concise proof artifact.

## Open questions

- None.

## Context / references

- `README.md` — current first-contact repo surface.
- `site/src/i18n/strings.ts` — landing page copy in en/pt/es.
- `site/src/config.ts` — maintenance-mode default for the public site.
- `.agent0/context/rules/agent0-governance-doctrine.md` — Agent0 remains a stack-neutral template/governance harness, not a product app by default.
- `.agent0/context/rules/runtime-capabilities.md` — source of truth for current Claude/Codex capability positioning.
- Prior Claude/Codex product critique captured at `.agent0/.runtime-state/claude-exec/20260609T144545Z-agent0-product-defense/last-message.md`.
