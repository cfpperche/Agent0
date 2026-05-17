# 034 — prototype-skill — plan

_Drafted from `spec.md` on 2026-05-17. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build the `/prototype` skill at `.claude/skills/prototype/` as the second consumer of the spec 033 toolkit — scaffolded via `/skill new prototype --tier cc-native`, validated via `/skill validate prototype` as a non-skippable ship gate. Structure mirrors `/sdd` (multi-phase orchestrator with subcommand-style dispatch internally) but content domain is hi-fi prototype generation. The SKILL.md body is the coordinator; it dispatches 4 parallel sub-agents in Phase 2 (sitemap, brand+tokens, monorepo, PRD) and N parallel sub-agents in Phase 3 (one per route, cap 5 concurrent) with 5-field handoffs that satisfy the delegation gate; it owns the cross-cutting REPORT.md authoring in Phase 4 (no final synthesis dispatch — skill already has all artifacts in memory).

Build order — **knowledge artifacts first, then stack templates, resolve plan-time open questions, then SKILL.md body, then dogfood, then verify**. Two-stack dogfood (Next.js linear-clone + Expo founder-choice) is the only empirical way to verify the "stack-specific knowledge stays in templates/" acceptance criterion; ship gate requires both stacks pass typecheck + lint via the generated monorepo's scripts plus `/skill validate prototype` exit 0.

Phase 1 open questions (5 from spec.md) resolved during plan execution before SKILL.md body is written, with decisions captured in the appropriate references/ file. Stack templates ship as **concrete bundled files**, not scaffold scripts — predictable, offline-capable, reviewable in git; staleness managed by a date-stamped `references/stack-defaults.md` and a quarterly re-research reminder.

## Files to touch

**Create — knowledge artifacts:**
- `.claude/skills/prototype/references/stack-defaults.md` — date-stamped research cache: recommended stack per platform class (web → Next.js 15 + React + Tailwind + shadcn/ui; mobile → Expo SDK + React Native + NativeWind), with dep versions + idiomatic patterns + freshness check protocol
- `.claude/skills/prototype/references/sitemap-schema.md` — YAML schema spec for sitemap.yaml; required_categories list; per-route fields (path/category/states/covers_us/components); validation rules
- `.claude/skills/prototype/references/quality-checklist.md` — the spec.md quality bar materialized: 4-dim fidelity scoring rubric, states coverage matrix, sitemap completeness check, monorepo-runs check
- `.claude/skills/prototype/references/delegation-briefs.md` — 5-field brief templates for each subagent type (Phase 2: sitemap / brand+tokens / monorepo / PRD; Phase 3: screen-writer per stack)

**Create — stack templates:**
- `.claude/skills/prototype/templates/monorepo-skeleton/next/` — full Next.js 15 skeleton: package.json, tsconfig, next.config, biome.json, app/layout.tsx, app/page.tsx (placeholder), tailwind config, postcss config
- `.claude/skills/prototype/templates/monorepo-skeleton/expo/` — full Expo SDK skeleton: package.json, tsconfig, app.json, App.tsx, navigation shell, NativeWind config
- `.claude/skills/prototype/templates/prd-1pager.md.tmpl` — Lenny hybrid shape (Problem · Why now · Release scope · NSM · Top 3-5 user-stories · Anti-goals · Upstream/downstream refs), strict 1-page discipline (≤ 3 bullets per section)
- `.claude/skills/prototype/templates/report.md.tmpl` — REPORT.md structure with sections for sitemap coverage scorecard, per-screen 4-dim fidelity, gap-audit, dev-server health check
- `.claude/skills/prototype/templates/default-tokens.css` — neutral baseline tokens.css for `--skip-brand` invocations (semantic CSS custom properties, no brand-specific values)

**Create — orchestrator:**
- `.claude/skills/prototype/SKILL.md` — meta-skill body; spec-033-compliant frontmatter (name/description/license/compatibility cc-native/metadata.agent0-portability-tier/argument-hint top-level); Phase 0 (parse + idempotency check) → Phase 1 (discovery, ≤5 questions, flag-overrides collapse) → Phase 2 (4 parallel dispatches) → Phase 3 (per-route dispatches, cap 5) → Phase 4 (stitch + verify + REPORT.md inline) → Phase 5 (handoff message)

**Modify:**
- (None expected at plan time.) `CLAUDE.md` capacity section addition is OPTIONAL — `/prototype` is discoverable via the harness SKILL.md surface like any other skill; no capacity section needed unless skill grows operational primitives that other skills depend on. Defer decision to impl.

**Delete:** none.

**Possibly create — defer to impl:**
- `.claude/skills/prototype/scripts/scaffold-monorepo.sh` — helper invoked by Phase 2 Subagent C if template-copy + sed substitution proves insufficient (e.g., needs `pnpm install` to bake lockfile). Optional; only build if SKILL.md body proves bash-inline approach awkward.
- A REMINDERS.md item for quarterly re-research of `stack-defaults.md` content (same cadence pattern as the agentskills.io spec snapshot in spec 033).

## Alternatives considered

### Build directly via `mkdir` + manual `SKILL.md` (bypass spec 033 toolkit)

Rejected. Spec 033 shipped 2026-05-17 specifically to enforce this exact discipline; bypassing it on the next skill would be inconsistent with the cultural commitment and would skip the non-negotiable `/skill validate prototype` gate. The `/skill new prototype --tier cc-native` path produces a compliant scaffold in seconds — no friction to honor.

### Stack scaffolding via `npx create-next-app` + post-processing (scripts, not bundled files)

Rejected. Three reasons. **Predictability**: bundled concrete files mean every prototype starts from byte-identical state — easier to debug regressions. **Offline-capable**: no network dependency at scaffold time means the skill works in restricted environments + air-gapped dogfood runs. **Reviewable**: git diff on `templates/monorepo-skeleton/next/` is auditable; a script's output is not. The trade is staleness — `create-next-app` always emits current-default conventions, while our bundled skeleton ages. Mitigation: `references/stack-defaults.md` has a `Retrieved: <date>` header and a quarterly re-research reminder (same cadence pattern as spec 033's agentskills.io snapshot — proven discipline).

### Single subagent per prototype run (sequential build)

Rejected. The whole point of this skill is the agile counterpart parallelizing across the full screen inventory; sequential execution would replicate the 15-step MCP's worst operational property (waiting on each step) without its quality discipline (cross-step schema audits). Cap of 5 concurrent in Phase 3 is the design — empirical OOM check during dogfood will tune downward if needed.

### REPORT.md authored via a final synthesis subagent

Rejected for v1. The skill is the single coordinator and already has all Phase 2/3 artifacts available (sitemap.yaml, tokens.css, brand-voice.md, screen files from each route's subagent return). A synthesis subagent would need ALL screen files re-loaded into its context, wasting tokens. Inline authoring by the skill keeps the cross-cutting view in one place. Revisit if inline authoring proves too slow or context-heavy in dogfood.

### Auto-cleanup of `/tmp/prototype-<slug>/` on idempotent re-run without confirmation

Rejected. Per Agent0's general "no surprises" posture (delegation-gate, secrets-scan, governance-gate all confirm destructive ops), prompting for confirmation is the right default. `rm -r` (not `-rf`) is the correct tool — governance-gate blocks the combined `-r` + `-f` flag combo per spec 001.

### Ship without dogfood, gate on validator only

Rejected. Spec 033 validator catches frontmatter compliance, not behavioral correctness. Two-stack dogfood (Next.js + Expo) is the only empirical verification of the "stack-specific knowledge lives in templates/" acceptance criterion. Shipping without it means we discover the abstraction broke on the third use, in someone else's session.

### Three-stack initial release (next + expo + sveltekit)

Rejected for v1. Each stack template requires research, scaffolding, dogfood, and ongoing maintenance. Two stacks is the minimum to prove the abstraction; adding a third triples the surface area without doubling the value. SvelteKit / Electron / CLI templates are deferred to follow-up specs if real demand surfaces (per spec.md non-goal).

## Risks and unknowns

- **Risk — 5-subagent concurrency causes OOM or context pressure on parent Opus.** Mitigation: dogfood with realistic 12-screen sitemap as the first test; if OOM observed, drop cap to 3 and update `delegation-briefs.md` + SKILL.md body. The cap is a CONSTRAINTS field in Phase 3 dispatch templates, so the tuning point is well-located.
- **Risk — Next.js / Expo conventions evolve between today's snapshot and use.** Real example: Next.js 15 → 16 could change app router structure. Mitigation: `references/stack-defaults.md` carries `Retrieved: 2026-05-17` header; quarterly re-research reminder (REMINDERS.md item, same shape as spec 033's `due: 2026-08-17`).
- **Risk — screen-writer subagent budget overflow on complex screens.** Mitigation: per-route CONSTRAINTS in delegation brief — "≤ 3 components per screen", "no inline state machines", token-budget hint. If a screen still blocks after retry, mark it `BLOCKED` in REPORT.md and continue with rest of the build (don't fail the whole prototype on one bad screen).
- **Risk — dev server doesn't start due to dep-install failure.** Mitigation: Phase 2 Subagent C (monorepo scaffolder) explicitly runs `pnpm install` (or bun-equivalent) as part of its dispatch; verifies exit 0; returns a `dep-install-status` field in its handoff payload that the skill checks before Phase 4.
- **Risk — SKILL.md body bloat above 500 lines (rule7 soft warn) or 5000 tokens (rule8 soft warn).** Mitigation: move detailed sub-phase logic into `references/` files using the "Read X before doing Y" pattern that the agentskills.io best-practices doc endorses. The 4 reference files already split a lot out; body should fit in budget.
- **Unknown — Playwright MCP availability in production sessions.** Phase 4 uses it for per-route screenshots. If absent, skip the screenshot step gracefully (mark REPORT.md "screenshots N/A — Playwright MCP unavailable"); don't fail the build.
- **Unknown — does the CC harness re-load SKILL.md mid-session if we edit it during dogfood?** Spec 033 verified next-session pickup but not mid-session reload. Decide at impl: probably safest to start a fresh session between SKILL.md edit and dogfood run to avoid stale instance.
- **Unknown — Phase 3 dispatches inside an already-Skill-tool-invoked context.** The `Skill` tool that invokes `/prototype` runs in the parent agent; Agent dispatches from inside that context may have different concurrency semantics than a top-level dispatch. Test empirically.

## Research / citations

- **Mandatory dependency** — spec 033 toolkit (`.claude/skills/skill/`): scaffolder, validator, porter, references-snapshot, frontmatter rules
- **agentskills.io frozen rules** — `.claude/skills/skill/references/spec-snapshot.md` (binding for the validator gate)
- **Frontmatter best practices** — `.claude/skills/skill/references/description-best-practices.md` (drove the description shape decision)
- **Portability tier policy** — `.claude/skills/skill/references/portability-tiers.md` (cc-native is the only tier this skill can be — heavy `.claude/` reference + Agent tool + Playwright MCP dependencies)
- **Phase C decisions inherited (spec 033)** — `agent0-portability-tier` namespace + `argument-hint:` stays top-level
- **Source design prompt** — conversation 2026-05-17 (user-supplied task brief, adapted with spec 033 compliance gates + Phase C decisions + governance-gate `rm -r` discipline)
- **15-step MCP context (paused parent)** — `docs/specs/032-pipeline-industry-alignment/spec.md` + `research-report.md` (industry findings: sitemap drives full inventory, Lenny 1-pager, required_categories)
- **Fidelity scoring calibration** — `docs/specs/026-mcp-product-pipeline-bench/` (drops Specificity from 5-dim → 4-dim Token/Voice/Component/Brief-fit)
- **MCP knowledge to selectively borrow (NOT invoke)** — `packages/mcp-product-pipeline/src/templates/{06-design-system,13-prototype-v3}/`
- **Structural references (steal shape)** — `.claude/skills/{brainstorm,sdd,skill}/SKILL.md`
- **Rules (binding)** — `.claude/rules/{delegation,research-before-proposing,spec-driven}.md`
- **Project memory** — `feedback_anthill_port_smart_not_rigid.md`, `feedback_mcp_package_self_contained.md`, `feedback_agent0_changes_ship_via_rules_not_memory.md`
- **Stack research (will be done in Phase A task 2)** — Next.js 15 docs (https://nextjs.org/docs), Expo SDK docs (https://docs.expo.dev/), shadcn/ui (https://ui.shadcn.com/), NativeWind (https://www.nativewind.dev/) — all WebFetch'd during `stack-defaults.md` authoring with retrieval date logged
