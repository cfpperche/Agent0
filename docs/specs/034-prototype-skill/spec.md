# 034 — prototype-skill

_Created 2026-05-17._

**Status:** shipped  _(2026-05-17. Two-stack typecheck + lint gates verified empirically: Next.js prototype `/tmp/prototype-linear-clone/` and Expo prototype `/tmp/prototype-habit-tracker/` both pass typecheck exit 0 AND lint exit 0 after a single `biome format --write` + 4 surgical type/key fixes. 2 scenarios remain documented-partial — see tasks.md § Notes.)_

## Intent

Ship a `/prototype` Agent0 slash-command skill that takes a founder's one-line product idea (`/prototype "linear-clone for SMB SaaS"`) and produces a **working, monorepo-scaffolded, stack-native hi-fi prototype** at `/tmp/prototype-<slug>/` — real code that compiles and runs in the chosen stack (Next.js, Expo, etc.), not HTML mockups. This is the **agile counterpart** to the 15-step `mcp-product-pipeline` (paused as spec 032): same quality bar on the artifacts that matter (sitemap completeness, design fidelity, brand voice, states coverage) but agile execution — parallelized subagents, ≤5 discovery questions, founder skips what doesn't apply, no per-step linear walk. Driving fact: critical analysis 2026-05-17 surfaced that the 15-step pipeline, while defensible for consultancy + curriculum + multi-stakeholder products, is overengineered for solo founder + AI workflows; Cagan's "hi-fi prototype is the only spec" position (research-report.md § 2) hasn't been honestly tested. This skill tests it. Built as the second consumer of the `/skill` toolkit (spec 033) — scaffolded via `/skill new prototype --tier cc-native`, frontmatter-validated as a ship gate.

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan. See `.claude/rules/spec-driven.md` § Acceptance scenarios for shape guidance._

- [x] **Scenario: skill is spec-033-compliant on ship**
  - **Given** the `prototype` skill scaffold has been built per this spec's tasks
  - **When** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` runs
  - **Then** exit 0 with no stderr; AND the next session-start `available-skills` system reminder surfaces `prototype` with the intended description

- [ ] **Scenario: end-to-end SMB-SaaS dogfood produces runnable Next.js monorepo**
  - **Given** a fresh session
  - **When** the user runs `/prototype "linear-clone for SMB SaaS engineering managers"`
  - **Then** a runnable Next.js monorepo lands at `/tmp/prototype-linear-clone/` with ≥ 12 screens covering all 5 required_categories (marketing + auth + primary + admin + error), tokens applied, voice on-brand, within ≤ 30 minutes wall-clock; AND `cd /tmp/prototype-linear-clone && pnpm dev` starts the dev server cleanly with every route rendering without crash

- [x] **Scenario: REPORT.md provides design-fidelity scorecard**
  - **Given** the prototype build completed
  - **When** the founder opens `REPORT.md` at the monorepo root
  - **Then** the file includes (a) sitemap coverage scorecard (X/Y routes wired), (b) 4-dim fidelity score per screen (Token / Voice / Component / Brief-fit, drop Specificity per spec 026 task 22 calibration), each ≥ 3/5 on primary screens, (c) gap-audit naming which required_categories were compensated by mechanism (e.g. "auth required by schema — added login/signup/reset without founder explicit mention")

- [x] **Scenario: skill works for 2+ stacks without duplicating logic in SKILL.md**
  - **Given** the skill is invoked twice — once for a web product, once for a mobile product
  - **When** both runs complete
  - **Then** the two prototypes use different stacks (e.g. Next.js + Expo) chosen via Phase 1 discovery (or `--stack=` override); AND the per-stack scaffolding logic lives entirely in `templates/monorepo-skeleton/<stack>/` and `references/stack-defaults.md` — the SKILL.md body has no stack-specific branching beyond template selection

- [x] **Scenario: founder flag-overrides collapse discovery phase**
  - **Given** the user runs `/prototype "<idea>" --stack=next --skip-prd --skip-brand`
  - **When** Phase 1 discovery runs
  - **Then** the stack question is skipped silently (already known), the PRD-1pager subagent (Phase 2 Subagent D) is not dispatched (skip-prd), and the brand+tokens subagent uses Open Design default tokens (skip-brand); discovery asks at most 2 questions (persona + backend/auth that aren't obvious from the idea)

- [x] **Scenario: parallel subagent dispatches honor delegation discipline**
  - **Given** the skill enters Phase 2 (4 parallel dispatches: sitemap, brand+tokens, monorepo, PRD) and Phase 3 (1 dispatch per route, cap 5 concurrent)
  - **When** each `Agent` tool call fires
  - **Then** every dispatch passes the 5-field handoff per `.claude/rules/delegation.md` (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN), so the delegation-gate hook never returns exit 2; Phase 3 caps at 5 concurrent subagents to prevent OOM with rest queued

- [ ] **Scenario: idempotent re-run wipes prior prototype output safely**
  - **Given** `/tmp/prototype-<slug>/` already exists from a prior invocation
  - **When** the user re-runs `/prototype "<same idea>"` with the same slug
  - **Then** the skill prompts for confirmation; on yes, removes the prior directory using `rm -r` (not `rm -rf` — governance-gate blocks combined `-r` + `-f`); on no, aborts cleanly

- [x] `.claude/skills/prototype/SKILL.md` exists with all spec-033-required frontmatter fields (`name: prototype`, `description ≤1024`, `compatibility:` cc-native canonical text, `metadata.agent0-portability-tier: cc-native`, `argument-hint:` at top-level per Phase C decision)
- [x] `.claude/skills/prototype/references/` contains at least: `stack-defaults.md` (research-cached with date stamp), `sitemap-schema.md`, `quality-checklist.md`, `delegation-briefs.md` (5-field templates for each subagent type)
- [x] `.claude/skills/prototype/templates/` contains at least: `monorepo-skeleton/next/`, `monorepo-skeleton/expo/`, `prd-1pager.md.tmpl`, `report.md.tmpl`
- [x] Skill body ≤ 500 lines (`rule7-body-warn` clean); body ≤ 5000 estimated tokens (`rule8-body-token-warn` clean) — actual: 130 lines / ~2889 tokens
- [x] Two-stack dogfood verified — Next.js (linear-clone) AND Expo (habit-tracker) — both pass typecheck + lint via the generated monorepo's scripts. **Empirical evidence:** Next.js `tsc --noEmit` exit 0, `biome check .` exit 0 after auto-format + 4 surgical fixes (3 useButtonType + 1 noArrayIndexKey on dashboard screen-writer output) propagated to the bundled template. Expo `tsc --noEmit` exit 0, `biome check .` exit 0 after `biome check --fix --unsafe` of bundled babel.config.js (arrow-function migration) + biome.json added to template.
- [x] Compliance gate is non-skippable: tasks.md includes a final acceptance task that runs `/skill validate prototype` and requires exit 0 before declaring done

## Non-goals

_What this change explicitly does NOT do. Future scope or adjacent problems that look similar but aren't in this spec._

- **No re-implementation of the 15-step MCP linearly.** The skill is the agile counterpart, not a thin wrapper. No per-step ceremony, no cross-step schema audit, no Open Design grounding pass beyond reusing patterns from `packages/mcp-product-pipeline/src/templates/06-design-system/references/`.
- **No cost-estimate, roadmap, GTM, legal-DPIA, system-design, ux-testing report.** Out of scope — founder produces these via other tools (or the 15-step MCP) if needed.
- **No prototype-v2 mid-fidelity stage.** Collapsed per spec 032 Decisions 8 + 14.
- **No HTML-only mockups.** Output must be real code in the chosen stack that compiles and runs.
- **No invocation of `mcp__product-pipeline__*` tools from within the skill.** The whole point is bypassing that ceremony.
- **No skill body that hard-codes stack-specific paths.** Stack knowledge lives in `templates/monorepo-skeleton/<stack>/` + `references/stack-defaults.md`; the SKILL.md selects the template based on discovery answer.
- **No commit / push from within the skill.** All output is at `/tmp/prototype-<slug>/` (gitignored); engineering handoff is via `/sdd new <slug>` separately.
- **No support for >2 stacks in v1.** Ship next + expo. SvelteKit / Electron / CLI templates are deferred to follow-up specs if real demand surfaces.

## Open questions

_Unknowns to resolve before `plan.md` can be locked. Each should have an owner (who decides) or a path to resolution. Empty if there are none._

- [ ] **Subagent concurrency cap of 5 — empirically validated?** The prompt asserts 5 simultaneous Agent dispatches to prevent OOM. Real-world test: dispatch 5 sonnet-tier sub-agents writing screen files in parallel against the 1M-context Opus parent; observe context pressure + tool-use timeout behavior. **Owner**: dogfood task during impl. Reduce to 3 if OOM observed.
- [ ] **Default brand-and-tokens source when `--skip-brand` is set.** Two options: (a) bundle a generic baseline tokens.css in the skill at `templates/default-tokens.css`; (b) ask the brand+tokens subagent to produce neutral defaults (no founder discovery). **Owner**: implementation choice during plan — leaning (a) for predictability + speed.
- [ ] **Stack template content vs reference.** Should `templates/monorepo-skeleton/next/` contain ALL the boilerplate (package.json, tsconfig, app router shell, biome.json) as concrete files, OR should it contain a SCRIPT (`scaffold.sh`) that generates them via `npx create-next-app` + post-processing? **Owner**: implementation — leaning concrete files (predictable, no network dep at scaffold time, but harder to keep current).
- [ ] **Screen-writer subagent budget per route.** Cap time / tokens / retries per Phase-3 dispatch to prevent one screen blocking the whole build. **Owner**: implementation; surface in `delegation-briefs.md` as a CONSTRAINTS field default.
- [ ] **REPORT.md authoring — skill direct vs final dispatch?** The prompt says "skill (NOT subagents) does" the stitch + verify. But report generation involves reading all screen files + scoring against fidelity rubric; that's substantial. Decide: inline in skill, or one final synthesis dispatch with the full screen-files context. **Owner**: implementation; leaning inline (skill is the single coordinator and owns the cross-cutting view).

## Context / references

_Links to related specs, prior art, issues, docs, conversations._

- **Spec 033 toolkit (mandatory dependency):** `.claude/skills/skill/` — scaffolder, validator, porter, references
- **Spec 032 (paused parent context):** `docs/specs/032-pipeline-industry-alignment/spec.md`, `docs/specs/032-pipeline-industry-alignment/research-report.md`
- **Spec 026 (calibration source for 4-dim fidelity):** `docs/specs/026-mcp-product-pipeline-bench/` (drops Specificity from the original 5-dim rubric per task 22 calibration)
- **MCP knowledge to selectively borrow (NOT invoke):**
  - `packages/mcp-product-pipeline/src/templates/06-design-system/` — tokens.css patterns
  - `packages/mcp-product-pipeline/src/templates/06-design-system/references/` — Open Design grounding catalog
  - `packages/mcp-product-pipeline/src/templates/13-prototype-v3/references/` — states-coverage matrix, screen-atlas-format, prd-coverage-rubric, tokens-application-checklist
- **Sibling skill patterns to steal structure from:**
  - `.claude/skills/brainstorm/SKILL.md` — phased interactive flow + state file
  - `.claude/skills/sdd/SKILL.md` — slash-command parsing + subcommand dispatch
  - `.claude/skills/skill/SKILL.md` — meta-skill orchestrator shape
- **Rules (binding):**
  - `.claude/rules/delegation.md` — 5-field handoff (delegation-gate hook will reject otherwise)
  - `.claude/rules/research-before-proposing.md` — stack defaults must be researched
  - `.claude/rules/spec-driven.md` — this spec follows the SDD shape; downstream engineering hand-off uses `/sdd new`
- **Project memory:**
  - `.claude/memory/MEMORY.md` (index)
  - `feedback_anthill_port_smart_not_rigid.md` — design discipline driver
  - `feedback_mcp_package_self_contained.md` — confirms placement under `.claude/skills/`, NOT under `packages/mcp-product-pipeline/`
  - `feedback_agent0_changes_ship_via_rules_not_memory.md` — skill ships to forks via sync-harness, so behavior in templates/references, not in project-local memory
- **Industry research (spec 032 research-report.md):**
  - Sitemap drives full screen inventory — Eleken, Slickplan, Raw.Studio
  - Lenny's 1-pager PRD shape — lennysnewsletter.com/p/prds-1-pagers-examples
- **Source prompt:** conversation 2026-05-17 (adapted from user-supplied "Task — build the `prototype` skill" prompt; adaptations: spec-033-compliance gates, Phase C decisions on `agent0-` namespace + `argument-hint` top-level, governance-gate `rm -r` discipline)
