# 045 — prototype-skill-pipeline-realign

_Created 2026-05-18._

**Status:** shipped

## Intent

Apply spec 032's 17 industry-alignment decisions to the `/prototype` skill's bundled pipeline (templates + briefs + SKILL.md orchestration), independently of `packages/mcp-product-pipeline/`'s shipping schedule. Skill ships **before** spec 032 ships, acting as a scout: smaller test bed (~50 files vs MCP's hundreds), faster turnaround (~3 weeks vs ~5-6), feeds findings back into spec 032's implementation. Skill `/prototype` is standalone (bundled templates, no MCP runtime dep per spec 036), so this refactor does not couple to spec 032's calendar. The quarterly REMINDERS diff item (due 2026-08-18) still fires when spec 032 lands to verify both stacks end up on the same shape.

The 2026-05-18 Pass E dogfood (this session) demonstrated the gap concretely: Steward's `/audit/overrides`-and-friends shipped without `auth` (login/signup/password-reset/invite-accept), without `admin` beyond `/settings/policy` (no billing/team-management/org-settings), and without `error` beyond `/not-found` (no /500). Root cause per spec 032 § Decision 5 + 13: PRD enumerates user-stories (P0/P1/P2 priorities) but no step enumerates **full screen inventory** — atlas sub-covers silently. This spec ports the mechanical fix (sitemap-IA as own step with YAML schema-enforced `required_categories`) plus the other 16 decisions to the skill.

Spec 036 (current `/prototype` v2) stays `shipped`; this spec produces v3. Skill version bumps from `0.1.0` (implicit, Pass E shape) to `0.2.0` (this spec) via new `metadata.skill-version` frontmatter field. Hard cutover — no deprecation phase, no flag-gated old shape.

## Acceptance criteria

### A. Structural reshape (per spec 032 decisions)

- [x] **Static fact:** `docs/specs/045-prototype-skill-pipeline-realign/{spec,plan,tasks}.md` exist
- [ ] **Static fact:** `.claude/skills/prototype/SKILL.md` frontmatter declares `metadata.skill-version: 0.2.0`
- [ ] **Static fact:** `.claude/skills/prototype/SKILL.md` orchestrates 4 substantive phases (`discovery → specification → identity → visual-contract`) with gates after steps 4 / 12 / 14
- [ ] **Static fact:** `.claude/skills/prototype/references/delegation-briefs.md` contains 15 step-specific briefs + 1 per-stack screen-writer brief (was: 13 + 1)
- [ ] **Static fact:** `.claude/skills/prototype/references/pipeline-coverage.md` STEPS table lists 15 linear steps in the new order (ideation → prototype → spec → ux-testing → prd-1pager → ost → sitemap-ia → system-design → legal → roadmap → cost-estimate → gtm-launch → brand → design-system → screen-atlas)
- [ ] **Static fact:** `.claude/skills/prototype/templates/pipeline/07-prototype-v2/` is DELETED
- [ ] **Static fact:** `docs/specs/045-prototype-skill-pipeline-realign/artifacts/deleted-step-7-prototype-v2.md` preserves the deleted content as tombstone
- [ ] **Static fact:** `.claude/skills/prototype/templates/pipeline/13-prototype-v3/` is RENAMED to `.claude/skills/prototype/templates/pipeline/15-screen-atlas/`
- [ ] **Static fact:** New step dirs exist: `.claude/skills/prototype/templates/pipeline/06-ost/`, `.claude/skills/prototype/templates/pipeline/07-sitemap-ia/`, `.claude/skills/prototype/templates/pipeline/12-gtm-launch/` (each with `prompt.md` + `schema.md`)
- [ ] **Static fact:** `.claude/skills/prototype/templates/pipeline/05-prd/prompt.md` body shape is Lenny 1-pager hybrid (Problem · Why now · Success metrics with NSM slot · Solution sketch · User stories · Anti-goals + 3 our-specific sections: Release scope · NSM-as-dedicated-slot · Upstream/downstream refs)
- [ ] **Static fact:** `.claude/skills/prototype/references/sitemap-schema.md` enforces `required_categories: [marketing, auth, primary, admin, error]` and a per-route field set documented as schema-binding

### B. Pipeline ordering scenarios

- [ ] **Scenario: legal-shift-left applied**
  - **Given** the realigned skill is installed
  - **When** the user runs `/prototype` and reaches Specification phase
  - **Then** Step 09 (legal) dispatches BEFORE Step 11 (cost-estimate), so legal posture informs sub-processor framework + cost includes legal review budget
- [ ] **Scenario: roadmap before cost**
  - **Given** Specification phase is in progress
  - **When** Step 10 (roadmap) and Step 11 (cost-estimate) dispatch
  - **Then** roadmap fires FIRST so cost calculates per-phase using roadmap's phase boundaries, not inventing implicit ones (residual gap from my analysis; not in spec 032)
- [ ] **Scenario: sitemap-IA enforces categories**
  - **Given** Step 07 (sitemap-ia) dispatches
  - **When** the sub-agent emits sitemap.yaml
  - **Then** the YAML contains routes covering ALL 5 `required_categories: [marketing, auth, primary, admin, error]` OR explicitly marks a category as `deferred-out-of-v1` with reason; if any required category has zero routes + zero deferral, the step is BLOCKED
- [ ] **Scenario: PRD-first reordering**
  - **Given** Specification phase begins
  - **When** Step 05 (prd-1pager) dispatches
  - **Then** Step 05 fires BEFORE Step 13 (brand) — current spec 036 shape inverts this (brand@5, PRD@8)
- [ ] **Scenario: GTM-launch gates Specification**
  - **Given** Step 12 (gtm-launch) completes
  - **Then** Specification-phase gate fires (continue/iterate/abort), gating transition into Identity phase
- [ ] **Scenario: collapsed 3→2 prototype passes**
  - **Given** the realigned skill runs end-to-end
  - **When** all 15 steps complete
  - **Then** only TWO prototype rounds exist (Step 02 lo-fi discovery + Step 15 hi-fi screen-atlas absorbing brand+tokens); no `direction-final.html` artifact (was Step 07 in spec 036) appears at output

### C. State machine v3

- [ ] **Static fact:** `.claude/skills/prototype/references/state-machine.md` declares `.state.json` `version: 3` shape including `phase` enum of `discovery | specification | identity | visual-contract`, `step` int 1-15
- [ ] **Scenario: post-refactor resume preserves state**
  - **Given** a v3 state.json exists at `<out>/docs/.state.json` from a partial run
  - **When** user invokes `/prototype ... --from-step=NN`
  - **Then** orchestrator validates v3 shape; if v2 shape found (legacy from spec 036), abort with `state v2 found — pre-spec-045 run; clear --out dir or run fresh /prototype`

### D. Skill compliance preserved

- [ ] **Static fact:** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` exits 0 after refactor
- [ ] **Static fact:** All path references in SKILL.md + references/*.md + templates/pipeline/<step>/prompt.md use absolute `{{out}}/docs/NN-<slug>.<ext>` form (per spec 036 finding #7 + iter-2 fix)

### E. Steward redogfood (acceptance gate)

- [ ] **Scenario: silent-undercover bug fixed via sitemap-IA**
  - **Given** Pass E's Steward `/tmp/dogfood-v2/` output exists as comparator
  - **When** user re-runs `/prototype "Claude Code governance dashboard" --stack=next --out=/tmp/dogfood-v3` with the new shape
  - **Then** the NEW screen-atlas (`/tmp/dogfood-v3/docs/15-screen-atlas.md`) contains routes covering `auth` category (≥3 of login/signup/password-reset/invite-accept), `admin` category (≥2 beyond just policy: at minimum billing + team-management), `error` category (≥2: /not-found + /500 OR equivalent), AND PRD coverage matrix is complete with NO silent gaps in `required_categories`
- [ ] **Static fact:** `/tmp/dogfood-v3/docs/REPORT.md` build-health section shows tsc exit 0 + biome exit 0
- [ ] **Static fact:** `/tmp/dogfood-v3/` follows the iter-2 layout discipline (all artifacts under `docs/`, root has only Next.js skeleton + build config)

## Non-goals

- Post-launch-review skill: out of scope (per Q4 — Decision 11 in spec 032 needs MCP backend for persistence; cannot ship as standalone skill until MCP's `POST_LAUNCH_ACTIONS` array lands).
- MCP `packages/mcp-product-pipeline/` re-shape: scope of spec 032 + its children (037-044). This spec does NOT touch the MCP package.
- Full-stack monorepo skill expansion: out of scope (separate spec, captured in REMINDERS — "Discutir expansão full-stack do /prototype").
- Re-snapshotting `packages/mcp-product-pipeline/src/templates/`: skill is standalone post-spec-036; we re-derive templates from spec 032's decisions, NOT re-copy from the MCP (which hasn't shipped 032 yet). Quarterly REMINDERS diff item (due 2026-08-18) fires the eventual reconciliation when spec 032 lands.

## Open questions

None — 7 design questions from 2026-05-18 conversation all resolved with founder ratification:
- Q1: single spec (not parent+children)
- Q2: numbering 045
- Q3: include cost↔roadmap swap
- Q4: post-launch out of scope
- Q5: add `metadata.skill-version: 0.2.0`
- Q6: ship now (scout pattern before spec 032)
- Q7: Steward redogfood case

## Dependencies + cross-references

- **Spec 032 (parent of 037-044, in-progress)** — source of the 17 design decisions ported here. This spec inherits 032's intellectual ammunition without coupling to its calendar.
- **Spec 036 (shipped 2026-05-18)** — the `/prototype` v2 baseline being refactored. v2 stays in git history; v3 (this spec) supersedes after acceptance gates pass.
- **Spec 033 (shipped)** — skill compliance toolkit; `bash scripts/validate.sh` is the acceptance gate D.
- **Spec 026** — `mcp-pipeline-deep-port` parent of spec 032; provides historical context for why the MCP pipeline shape is what it is.
- **REMINDERS** item due 2026-08-18 (`Diff .claude/skills/prototype/templates/pipeline/ vs packages/mcp-product-pipeline/src/templates/`) — fires when spec 032 lands to verify post-045 skill and post-032 MCP converge.

## Lineage

- Industry decision basis: spec 032 § Acceptance criteria § A (17 decisions, 48-source research at `docs/specs/032-pipeline-industry-alignment/research-report.md`).
- Skill-specific scout-pattern: this spec's contribution beyond spec 032 — validates the design at smaller scale before MCP commits ~6 weeks to full implementation.
- Cost↔roadmap swap: residual gap surfaced in 2026-05-18 conversation; not in spec 032 (kept as "unchanged" in 032's STEPS table). This spec proposes the swap and validates it via Steward redogfood; if value confirmed, feed back to spec 032 as new Decision 18.
- **2026-05-18 follow-up:** skill renamed `/prototype` → `/product` per spec 048 (v0.3.0); output layout refactored to drop NN- prefix and emit semantic-named artifacts. The 15-step pipeline shape from this spec is preserved intact; only the surface (name + paths) changes. MCP-side work (032 children 037-044) no longer planned — MCP discontinuation announced 2026-05-18; skill becomes canonical foundation tool for Agent0.
