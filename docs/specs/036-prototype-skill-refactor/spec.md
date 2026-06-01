# 036 — prototype-skill-refactor

_Created 2026-05-18._

**Status:** superseded — see Closure

## Closure (2026-05-31)

Closed without completion. Every premise of this refactor dissolved as the product
lifecycle settled after 2026-05-18:

- **`/prototype` no longer exists** — it evolved into `/product`: `034` (v1) → `036`
  (partial: Pass C/D template fixes, commit `27654e9`) → `045` (`/prototype` v3, 15-step,
  industry-aligned) → `048` (rename `/prototype` → `/product`, production-shaped layout).
- **`packages/mcp-product-pipeline/` was discontinued** (commit `8cf6c5a` — "/product skill
  is canonical delivery"). This spec's core mechanism — copying 13 templates verbatim from
  that package into a skill bundle — has no source anymore.
- The "agile frontend to the 13-step pipeline" niche is occupied by `/product` (spec 048,
  shipped): planning artifacts + visual contract, handing off to `/sdd` for the build.

The legitimate remaining kernel — generating a runnable full-stack app, not just planning
artifacts — is **not** a `/prototype` revival. It is tracked as **Caminho C** of reminder
`r-2026-05-19` (a separate future `/promote`-style skill, ~spec 064+ when prioritized);
Caminho B (extending `/product` into a monorepo generator) was rejected as a
single-responsibility violation.

## Intent

`/prototype` v1 (spec 034) was scoped as the agile **alternative** to the 13-step `mcp-product-pipeline` — but in practice it covers only ~25-30% of the pipeline output, skipping 8 of 13 steps entirely (spec, UX testing, system-design, cost, roadmap, legal, prototype-v3) and partially covering 4 (ideation, brand, design-system, PRD). The 2026-05-17 live dogfood (`/tmp/prototype-claude-code-governance-dashboard/`) made the gap visible: 23 generated files, 10 KLoC of TSX, zero real planning artifacts, and a critical render bug (tokens.css never imported because of a false-positive grep heuristic in Phase 4) that made the entire design system a no-op. The user-facing verdict was "skill rejeitada".

This spec refactors `/prototype` into the agile **frontend** to the same 13-step pipeline: same artifacts, same gates, but in fluid/parallel/light mode. Single depth tier (no `--fast`/`--deep` flag soup), standalone (no MCP-server runtime dependency — 13 templates copied verbatim into the skill bundle), single user invocation drives all 13 steps end-to-end with 3 condensed phase gates instead of the heavy pipeline's 3 user-checkpoints. Spec 034 is superseded by this spec.

## Acceptance criteria

- [ ] **Scenario: end-to-end 13-step coverage**
  - **Given** the refactored skill is installed at `.claude/skills/prototype/`
  - **When** a user runs `/prototype "<idea>" --stack=<next|expo> --out=<path>`
  - **Then** the output directory contains all 13 pipeline-equivalent artifacts: concept-brief.md, direction-*.html, screens/ (v1 + v2 + v3), functional-spec.md, validation-report.md, brand-book.md, tokens.css, components.md, design-system.md, prd.md, system-design.md, architecture.json, security.md, cost-estimate.md, roadmap.md, legal-posture.md, screen-atlas.md, REPORT.md

- [ ] **Scenario: standalone — no MCP dependency**
  - **Given** the fork has `packages/mcp-product-pipeline/` removed or missing
  - **When** a user runs `/prototype "<idea>" --stack=next --out=/tmp/foo`
  - **Then** the run completes successfully without any `mcp__product-pipeline__*` tool calls and without referencing paths under `packages/mcp-product-pipeline/`

- [ ] **Scenario: output dir is configurable (`--out` flag)**
  - **Given** spec 034 hardcoded `/tmp/prototype-<slug>/`
  - **When** a user passes `--out=/home/user/myproject`
  - **Then** all artifacts land at `/home/user/myproject/` (the dir is created if absent; existing non-empty dir prompts idempotency confirm matching Phase 0 behaviour)

- [ ] **Scenario: tokens.css import is verified, not grep-guessed**
  - **Given** spec 034's Phase 4 step 1 used `grep -q 'tokens.css' app/globals.css` which matched comment text and silently skipped the actual import (root cause of 2026-05-17 dogfood failure)
  - **When** the v2 skill enters its stitch phase
  - **Then** the bundled `globals.css` template ships with `@import "../tokens.css";` as line 1 already present, AND the stitch phase verifies the line exists via `grep -qE '^@import.*tokens\.css' app/globals.css` (strict regex, not loose substring), AND the dev server's compiled CSS chunk contains at least one `--color-*` token from `tokens.css` (smoke test)

- [ ] **Scenario: 4 phase gates, single user-confirm each**
  - **Given** the heavy MCP pipeline has 3 Layer-3 user checkpoints (after Discovery / Identity / Specification phases)
  - **When** the v2 skill runs end-to-end
  - **Then** the user is asked to confirm exactly 3 times (Phase 1 gate after steps 1-4 → "Discovery complete?"; Phase 2 gate after steps 5-7 → "Identity coherent?"; Phase 3 gate after steps 8-12 → "Specification locked?"); Phase 4 (step 13 atlas) closes without a gate; aborting at any gate persists `.state.json` for resume

- [ ] **Scenario: resumable mid-pipeline via `--from-step=NN`**
  - **Given** a previous invocation aborted at any step
  - **When** the user re-runs `/prototype "<idea>" --from-step=07 --out=<same-path>`
  - **Then** the skill reads `.state.json` from the output dir, validates the slug/idea match, and resumes from step 7 without re-running steps 1-6 (idempotency replaces v1's overwrite-prompt-then-restart pattern)

- [ ] **Scenario: 5 dogfood-surfaced template bugs are fixed in the bundled skeleton**
  - **Given** the 2026-05-17 dogfood surfaced 5 template/skill bugs (pnpm-workspace.yaml placeholder strings; package.json missing `test` script; SKILL.md Phase 2 parallel-dispatch wording vague; validator scope is repo-wide; tokens.css import grep heuristic false-positive)
  - **When** the v2 skill is dispatched
  - **Then** all 5 bugs are absent from the bundled templates + SKILL.md: pnpm-workspace.yaml has `true`/`false` literal values (not placeholders); package.json includes `"test": "echo 'no tests yet' && exit 0"`; SKILL.md Phase 2 includes a literal worked example of "5 Agent tool calls in one message"; validator scope hint documents the repo-wide gotcha; globals.css ships with the `@import "../tokens.css"` line + strict-regex re-verification

- [ ] **Scenario: spec 033 compliance (skill validate exit 0)**
  - **Given** the refactored SKILL.md at `.claude/skills/prototype/SKILL.md`
  - **When** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` is run
  - **Then** it exits 0 (no rule violations from the spec 033 toolkit)

- [ ] **Scenario: live dogfood passes the render-not-raw test**
  - **Given** the v2 skill is shipped
  - **When** the user runs `/prototype "Claude Code governance dashboard" --stack=next --out=/tmp/dogfood-v2` (same brief as v1's failed dogfood)
  - **Then** `pnpm dev` boots, `curl http://localhost:3000/` returns HTML where the linked CSS chunk contains `--color-background:` and other token definitions (not just Tailwind reset), AND a visual inspection (user-reported) shows the dark theme + cyan primary + monospace typography defined in tokens.css are actually applied (not raw browser-default styling)

- [ ] 13 step templates exist at `.claude/skills/prototype/templates/pipeline/01-ideation/` … `13-prototype-v3/` — copied verbatim from `packages/mcp-product-pipeline/src/templates/` at scaffold time
- [ ] Skill body documents the quarterly REMINDERS check for template drift between the bundled copies and the canonical `packages/mcp-product-pipeline/src/templates/`
- [ ] Spec 034's `**Status:**` line is updated to `superseded by 036-prototype-skill-refactor`
- [ ] Concurrency cap retained at 5 for screen-writer fan-outs (Phase 2 prototype-v1 + Phase 2 prototype-v2 + Phase 4 prototype-v3); proven non-OOM on 17-route dogfood

## Non-goals

- **Not promoting `/prototype` v2 to MCP server status.** The v2 skill is a CC-native orchestration layer; the MCP pipeline remains the heavy canonical implementation. Users wanting full pipeline rigor invoke `mcp__product-pipeline__*` tools directly.
- **Not changing the underlying pipeline's 13-step design.** The pipeline itself (templates, schemas, gates, three-pass rationale) stays as-is at `packages/mcp-product-pipeline/`. This refactor only changes how `/prototype` covers it.
- **Not introducing depth tiers (`--fast`/`--standard`/`--deep`).** Decided 2026-05-17: single well-calibrated tier ("standard"). Users wanting more rigor invoke MCP pipeline directly; users wanting less are out of scope.
- **Not auto-pushing artifacts to GitHub.** `gh repo create` / push remains a manual user step after the skill completes (matches the 2026-05-17 conversation outcome — user wanted to inspect first).
- **Not replacing `/sdd` as the engineering handoff.** Phase 4's final message is still `/sdd new <slug>`; that's the gate from prototype to engineering.
- **Not fixing supply-chain-hook substring-greediness** (the "pnpm install" echo-text false-positive surfaced in 2026-05-17 dogfood). Out of scope; tracked separately for spec 008 follow-up.

## Open questions

_All 5 resolved 2026-05-18 in conversation; decisions inline for traceability + inherited by `plan.md`._

- [x] **Q1 — Phase 1 sub-agent models.** Step 1 = `opus` (concept brief = multi-source comparative synthesis with web research); Steps 2/3/4 = `sonnet` (mechanical with dense brief). Declared in `delegation-briefs.md` per-step `model` field; tunable via dogfood.
- [x] **Q2 — Template drift sync.** Quarterly REMINDERS.md item: "Diff `.claude/skills/prototype/templates/pipeline/` vs `packages/mcp-product-pipeline/src/templates/`; sync if changed." Matches pattern of other quarterly snapshot REMINDERS (spec 033 agentskills.io re-snap, spec 034 stack-defaults re-research). No script.
- [x] **Q3 — Phase gate UX.** `AskUserQuestion` structured at each of 3 gates (Phase 1, 2, 3) with options `continue` / `iterate` / `abort`. Friction is the feature: audit trail + unambiguous user intent.
- [x] **Q4 — Sub-agent BLOCKED handling.** Degrade gracefully + log to `.state.json` + REPORT.md, continue to next step. Abort ONLY when Step 1 (concept brief — upstream of everything) or Step 13 (final atlas) fail. Mid-pipeline failures (e.g., Step 12 legal) annotate gap without losing other steps.
- [x] **Q5 — `--out=<path>` collision.** Phase 0 prompts `<dir> exists and is non-empty. Overwrite? (y/N)`. On `y`: `rm -r <dir>` then scaffold. On `n`/no-answer: abort. Matches v1 Phase 0 pattern; no `--force` flag.

## Context / references

- `docs/specs/034-prototype-skill/` — the spec being superseded; v1 design memory + dogfood findings
- `packages/mcp-product-pipeline/` — the 13-step canonical pipeline this skill is the agile frontend to
- `packages/mcp-product-pipeline/src/templates/01-ideation/` … `13-prototype-v3/` — source-of-truth templates to copy
- `docs/specs/025-mcp-product-pipeline/` — original spec for the heavy pipeline MCP
- `docs/specs/026-pipeline-prd/` — pipeline PRD / phase 2 dogfood (where the spec 034 lightening opportunities were first surfaced)
- `docs/specs/033-skill-compliance-toolkit/` — `/skill validate` spec, the compliance gate this skill MUST pass
- `.claude/rules/spec-driven.md` — SDD discipline for this kind of refactor
- `.claude/rules/delegation.md` — 5-field handoff for all Agent dispatches across 13 steps
- `.claude/rules/research-before-proposing.md` — guides Phase 1 Step 1 web research depth
- 2026-05-17 dogfood evidence: `/tmp/prototype-claude-code-governance-dashboard/REPORT.md` (5 findings list + Fidelity scorecard)
- 2026-05-17 conversation: "skill rejeitada" user feedback that triggered this spec
