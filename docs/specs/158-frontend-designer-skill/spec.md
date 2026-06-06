# 158 — frontend-designer-skill

_Created 2026-06-05._

**Status:** in-progress
**UI impact:** none

<!-- This spec ships a skill; the skill itself produces UI in consumer projects, but the skill artifacts (SKILL.md/scripts/templates) are not themselves a UI surface, so this spec is `none`. The skill's *dogfood* demos each carry their own UI-impact declaration. -->

## Intent

Agent0 has two adjacent UI capacities with a gap between them. `/product` is docs-first planning — it produces a design-system doc and a design-time visual contract (mood/atlas/fixture-spec) but **explicitly does not generate a runnable app**. The **spec-155 visual-contract acceptance gate** proves a *built* UI works by driving it (`agent-browser.sh verify-contract` → `report.json`). Nothing in between actually **crafts or refines the real frontend with taste**.

`frontend-designer` fills that implementation-craft gap. It is a build-time "artist" skill: given a product/domain context, an optional existing design system, a target platform, and **mandatory reference research**, it produces or refines runnable frontend UI and proves it with evidence. It never reopens `/product`'s planning, invents no new acceptance gate (it reuses spec 155), and ships zero frozen stack opinions (it detects and adapts). Design comes from a context-engineered loop — research → direction → implement → drive-and-see → critique → refine — not from a persona prompt.

This spec graduates the decision-grade `/meeting` synthesis at `.agent0/meetings/frontend-designer-skill-design-2026-06-06T01-30-48Z/meeting.md` (Claude + Codex, blind-opening + pressure-test, ledger 5 claims all path-anchored, 0 assertion-only).

## Acceptance criteria

- [ ] **Scenario: Skill scaffolds and validates as a compliant Agent0 skill**
  - **Given** the skill is implemented under `.agent0/skills/frontend-designer/` with the standard `.claude/skills/frontend-designer` + `.agents/skills/frontend-designer` symlinks
  - **When** `bash .claude/skills/skill/scripts/*validate*` (`/skill validate frontend-designer`) runs
  - **Then** the SKILL.md passes the agentskills.io frontmatter spec with a declared `agent0-portability-tier: agentskills-portable`

- [ ] **Scenario: Three modes with explicit per-mode contracts**
  - **Given** the SKILL.md
  - **When** a reader looks for the operating modes
  - **Then** `create`, `refine`, and `explore` are each documented with required inputs, produced outputs/artifacts, and per-mode acceptance criteria; `create`/`refine` emit runnable code, `explore` emits design artifacts only (no code)

- [ ] **Scenario: Stack ladder is project-derived, never a frozen default**
  - **Given** a target project
  - **When** the skill must pick a framework/platform
  - **Then** it resolves in order: existing project stack+design-system → `/product` system-design stack → explicit user hint → **research canonical options and record an open decision / ask** before writing code; it NEVER consumes a bundled skeleton or hardcoded default

- [ ] **Scenario: Reference research is mandatory and artifacted**
  - **Given** any `create`/`refine`/`explore` pass
  - **When** the skill establishes a design direction
  - **Then** it writes a git-tracked `reference-research.md` (each entry: source URL/path · domain relevance · pattern borrowed · pattern rejected · implementation consequence) and a `design-direction.md` (domain-grounded tokens + chosen references + rationale), one compact pair per surface, in the active SDD spec dir if SDD-driven else `docs/design/<surface>/`

- [ ] **Scenario: Existing design system is reused, not reinvented**
  - **Given** a project with a detectable design system (Tailwind config / token files / shadcn|Radix / `/product` design-system doc / open-design vendor)
  - **When** the skill designs
  - **Then** it reads and reuses those tokens/components; it only *proposes* new tokens when none exist (and records the proposal in `design-direction.md`)

- [ ] **Scenario: Browser-renderable output is proven via the spec-155 gate**
  - **Given** a `create`/`refine` pass on a browser-renderable surface
  - **When** the skill declares done
  - **Then** it emits a `UI impact: render|interaction|flow` declaration and a green `agent-browser.sh verify-contract` `report.json`; **`agent-browser` unavailable is a BLOCKER, never a pass**

- [ ] **Scenario: Native-only surfaces are labeled honestly**
  - **Given** a non-browser-renderable surface (native mobile/desktop with no Expo-web/Storybook/web-preview harness)
  - **When** the skill declares done
  - **Then** it uses a project-provided browser-renderable harness if one exists; otherwise it ships code + native build/test evidence **explicitly labeled** as "not visual-contract proof", and it adds no new native visual tooling (rule-of-three demand test)

- [ ] **Scenario: The refine/craft loop has explicit stop criteria and a bound**
  - **Given** the iterative research→implement→drive→critique→refine loop
  - **When** the skill iterates
  - **Then** the SKILL.md declares explicit "good-enough" stop criteria and a max-iteration bound; the loop stops on either

- [ ] **Scenario: Dependency footprint is minimal and free**
  - **Given** the skill's declared dependencies
  - **When** audited
  - **Then** hard deps are only shell + `rg` + `jq` + the project's package manager + `agent-browser.sh`; everything else is detect-don't-impose; every dependency is free and runs both locally and remotely

- [ ] **Scenario: Dogfood proves capability across three edges**
  - **Given** the implemented skill
  - **When** it is dogfooded into 3 demo projects in `/tmp`
  - **Then** (a) greenfield + real design-system web demo produces a green `verify-contract` report whose output visibly reuses the fixture's tokens/components; (b) refine-existing demo shows before/after evidence, a bounded diff, preserved behavior, and a critique loop stopping on explicit criteria; (c) a no-design-system demo on a non-web platform proves token-proposal + native-honesty (render evidence via Expo-web/Storybook/web-preview if achievable, else honestly labeled)

## Non-goals

- Re-implementing `/product`'s planning pipeline (concept brief, PRD, OST, roadmap, etc.) or its design-system *generation* — the skill consumes those, it does not regenerate them.
- Generating a whole product/app (backend, auth, data layer). Scope is UI surfaces: screens, components, flows.
- Inventing a new acceptance gate or a "design quality score" — done-proof reuses spec 155.
- Shipping stack templates / frozen defaults / starter skeletons of any kind.
- New native (iOS/Android/desktop) visual-verification tooling — deferred behind the rule-of-three demand test.
- A persistent "design dashboard" or global reference cache (harness-drift).
- Paid services as a hard dependency (`/image` fal mood-boards stay an optional, opt-in upgrade).

## Open questions

- [x] New skill vs `/product` mode? → **New skill** (meeting D1).
- [x] Runnable code or designs only? → **Runnable for create/refine; explore is design-only** (meeting D2).
- [x] Stack stance? → **Project-derived ladder, never frozen** (meeting D3).
- [x] Reference-research mechanism? → **web + agent-browser + rg, artifacted** (meeting D4).
- [x] Done-proof? → **reuse spec 155; unavailable = blocker** (meeting D6).
- [x] Where do design docs live? → **git-tracked, SDD spec dir or `docs/design/<surface>/`** (meeting delta).
- [ ] Does `explore` mode survive its first real use, or collapse into create's research phase? Resolve after dogfood — keep narrow for v1.

## Context / references

- `.agent0/meetings/frontend-designer-skill-design-2026-06-06T01-30-48Z/meeting.md` — the decision-grade synthesis this spec graduates.
- `.agent0/context/rules/visual-contract.md` (spec 155) — the done-proof gate this reuses.
- `.agent0/context/rules/browser-primitive.md` (spec 152/153) — `agent-browser.sh`, the reference-capture + drive primitive.
- `.claude/skills/product/SKILL.md` — boundary: planning vs craft.
- `.claude/skills/skill/` — skill scaffolding + portability tiers + validator.
- `.agent0/context/rules/runtime-capabilities.md` + project memory `feedback_no_shipped_stack_opinions` — the no-frozen-defaults constraint.
