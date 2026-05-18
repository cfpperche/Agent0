# 048 — product-skill-foundation

_Created 2026-05-18._

**Status:** shipped

## Intent

Two changes, one spec: (1) rename `/prototype` → `/product`, because the semantic of "prototype = throwaway exploration before commit" is wrong now that MCP is being discontinued and the skill becomes the canonical foundation generator + design partner across the full product lifecycle (v1 → vN); (2) refactor the skill's output layout to drop `NN-` prefix and emit production-shaped artifacts directly, because the prefix was designed when artifacts were thought-of-as-pipeline-output (temporal ordering matters for first-read) but is dead weight once those artifacts become the project's forever home (semantic naming wins; temporal narrative survives via REPORT.md + .state.json).

The triggering insight (2026-05-18 conversation): for a real project like an ERP for beauty salons, the skill emits 15 artifacts that need to live with the product through MVP → v1 → vN. The current `NN-` prefix + flat output forces a manual reorg post-launch (move concept-brief to _archive/, rename 05-prd.md to prd/v1.md, group design system files, etc.). The skill should emit the production layout directly — semantic naming, release-scoped PRD via `prd/v1.md` subfolder from day 1, grouped design system, and the temporal order legible via `REPORT.md` for first-read review.

Spec 045 (`/prototype` v3, shipped 2026-05-18) introduced the 15-step industry-aligned pipeline + sitemap-IA schema enforcement + DPIA shift-left + cost↔roadmap swap + collapsed 3→2 prototype passes. This spec inherits all of that intact — same pipeline shape, same gates, same orchestration. **Only the skill name and the output layout change.** Skill version bumps `0.2.0 → 0.3.0` (breaking — state.json v3 → v4).

The MCP discontinuation cascade is OUT OF SCOPE here (user handles in MCP session). This spec is purely skill-side.

## Acceptance criteria

### A. Rename `/prototype` → `/product`

- [ ] **Static fact:** `.claude/skills/product/` directory exists (renamed from `.claude/skills/prototype/`)
- [ ] **Static fact:** `.claude/skills/prototype/` directory does NOT exist
- [ ] **Static fact:** `.claude/skills/product/SKILL.md` frontmatter declares `name: product`, `metadata.skill-version: 0.3.0`
- [ ] **Static fact:** `.claude/skills/product/SKILL.md` description reframes the skill as "foundation generator + design partner for product lifecycle (v1 → vN)" — NOT "agile frontend / throwaway prototype"
- [ ] **Static fact:** `CLAUDE.md` has `## Product skill` capacity section (renamed from `## Prototype skill`) with updated description
- [ ] **Static fact:** No file under `.claude/skills/product/` contains the literal substring `/prototype` referring to the skill itself (mentions of "prototype" in semantic sense — "lo-fi prototype" as design artifact — are allowed; the slash-command + skill name is the rename target)
- [ ] **Static fact:** `docs/specs/045-prototype-skill-pipeline-realign/spec.md` § Lineage gains a note "skill subsequently renamed to /product per spec 048"

### B. Layout refactor — production-shaped paths

- [ ] **Static fact:** `.claude/skills/product/references/state-machine.md` declares `version: 4` (breaking; orchestrator refuses silent v3 → v4 upgrade)
- [ ] **Static fact:** Output emitted to `<out>/docs/` follows the new paths per the mapping below (none of `NN-` prefixed):
  | Artifact | New path |
  |---|---|
  | Concept brief | `docs/concept-brief.md` |
  | Lo-fi direction | `docs/direction-a.html` |
  | Killer-flow mood screens | `docs/screens/<name>.html` |
  | Functional spec | `docs/functional-spec.md` |
  | UX validation report | `docs/validation-report.md` |
  | PRD 1-pager | `docs/prd/v1.md` (release-scoped subfolder from day 1) |
  | OST | `docs/ost.md` |
  | Sitemap-IA | `docs/sitemap.yaml` |
  | System design | `docs/system-design.md` |
  | Security | `docs/security.md` |
  | Data flow | `docs/data-flow.json` |
  | Legal posture | `docs/legal-posture.md` |
  | Roadmap | `docs/roadmap.md` |
  | Cost estimate | `docs/cost-estimate.md` |
  | GTM-launch | `docs/gtm-launch.md` |
  | Brand book | `docs/brand-book.md` |
  | Design tokens | `docs/design-system/tokens.css` |
  | Component anatomy | `docs/design-system/components.md` |
  | Design system overview | `docs/design-system/README.md` |
  | Screen atlas | `docs/screen-atlas.md` |
  | Run report | `docs/REPORT.md` |
  | State machine | `docs/.state.json` |
- [ ] **Static fact:** `.claude/skills/product/templates/monorepo-skeleton/next/app/globals.css` imports tokens via `@import "../docs/design-system/tokens.css"` (3rd update — was `06-tokens.css` in spec 036, `14-tokens.css` in spec 045 hotfix)
- [ ] **Static fact:** Stitch step in `SKILL.md` Phase 4 uses regex `grep -qE '^@import.*docs/design-system/tokens\.css' <out>/app/globals.css` (path-strict; not loose-substring)
- [ ] **Static fact:** `delegation-briefs.md` 15 step briefs + per-stack screen-writer all reference the new paths (CONTEXT reads + DELIVERABLE writes)
- [ ] **Static fact:** Step 15 Sitemap Coverage Cross-Check (in `templates/pipeline/15-screen-atlas/prompt.md`) reads sitemap from `docs/sitemap.yaml` and atlas writes to `docs/screen-atlas.md`

### C. State machine breaking-upgrade discipline

- [ ] **Scenario: v3 state file refused**
  - **Given** an existing `<out>/docs/.state.json` declaring `version: 3` from a pre-048 run
  - **When** the user invokes `/product ... --from-step=NN`
  - **Then** orchestrator aborts with `state v3 found — pre-spec-048 run; clear --out dir or run fresh /product` (mirrors spec 045 v2→v3 abort pattern)

### D. Skill compliance preserved

- [ ] **Static fact:** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 after refactor
- [ ] **Static fact:** SKILL.md description ≤1024 chars (spec 033 limit)

### E. Dogfood — "ERP para salões de beleza"

- [ ] **Scenario: cold-cache end-to-end with new layout**
  - **Given** a fresh CC session with the renamed + refactored skill installed
  - **When** the user runs `/product "ERP para salões de beleza" --stack=next --out=/tmp/dogfood-erp`
  - **Then** all 15 pipeline steps complete; 17 artifacts land at the spec-B paths (no `NN-` prefix anywhere in `docs/`); `prd/v1.md` subfolder + `design-system/` subfolder both exist; `tsc --noEmit` + `biome check .` both exit 0; `REPORT.md` exists at `docs/REPORT.md` with A/B comparison against `/tmp/dogfood-v3` (Audity NN-flat output)
- [ ] **Static fact:** `/tmp/dogfood-erp/docs/REPORT.md` build-health section shows tsc exit 0 + biome exit 0
- [ ] **Static fact:** `/tmp/dogfood-erp/` follows the new layout discipline (root has only Next.js skeleton + build config; everything skill-produced under `docs/`)

## Non-goals

- **MCP changes** — out of scope; user handles in MCP-dedicated session per `2026-05-18 conversation`. This spec does NOT touch `packages/mcp-product-pipeline/`, spec 032, or the children 037-044 that spec 032 planned.
- **Post-launch evolution primitives** (`--mode=evolve --existing=<docs>`, `/product promote`, PRD diff, sitemap diff, OST update against deployed product) — out of scope; deferred to **spec 049 — product-skill-vN-mode** when prioritized. The cleanup of MCP-mode rationale ("post-launch needs MCP backend") is a side-effect of MCP discontinuation, not this spec's concern.
- **Sync-harness manifest path migration for existing forks** — if any fork has `.claude/skills/prototype/` checked in, harness sync becomes manual (delete old + accept new). Cross-fork migration tooling is out of scope.
- **Real archive layout (`_archive/v0-foundation/`)** — first run emits everything top-level; founder decides when to promote artifacts to `_archive/` post-launch (manual or via future `/product promote`). Skill does NOT pre-archive.

## Open questions

None — all 4 decisions ratified via `/goal confirmo tudo, pode implementar e validar o plano` 2026-05-18:

- Q1 → slug `048-product-skill-foundation` (was 046 in original plan; renumbered to 048 due to sibling-session 046+047 conflicts)
- Q2 → PRD release-scoped subfolder `docs/prd/v1.md` from day 1 (force versioning discipline at first run)
- Q3 → OST + roadmap + cost-estimate flat by default (`docs/ost.md`, `docs/roadmap.md`, `docs/cost-estimate.md`); founder promotes to subfolder when accumulation justifies
- Q4 → dogfood case "ERP para salões de beleza" (real motivating case; exercises B2B vertical SaaS — different domain from Audity's B2B governance, surfaces hidden assumptions)

## Dependencies + cross-references

- **Spec 045 (shipped 2026-05-18)** — the v3 industry-aligned pipeline this spec inherits intact. Only name + layout change. Spec 045 stays shipped; gains a § Lineage note about the rename.
- **Spec 036 (shipped 2026-05-18)** — v2 baseline that 045 superseded. Stays shipped; tombstone semantics preserved.
- **Spec 033 (shipped)** — skill compliance toolkit; `bash scripts/validate.sh` is acceptance gate D.
- **Spec 032 (in-progress, parallel session)** — MCP-side industry alignment. Cross-references in 032's `## Scout addendum` (when user updates it) should reflect this spec's rename: scout was `/prototype v3` (spec 045); it's now `/product v0.3.0` (spec 048).
- **Spec 049 (future) — product-skill-vN-mode** — picks up the post-launch evolution primitives gap that MCP was supposed to handle; depends on this spec.
- **REMINDERS quarterly diff item (due 2026-08-18)** — was about diff'ing `.claude/skills/prototype/templates/` vs `packages/mcp-product-pipeline/src/templates/`; with MCP discontinuation, this reminder becomes obsolete (user dismisses in MCP session); the renamed `.claude/skills/product/templates/` is the only source of truth post-048.

## Lineage

- Skill rename + layout refactor proposed 2026-05-18 in conversation. MCP discontinuation announcement was the trigger — once the MCP isn't the canonical product-pipeline, the `/prototype` name's "throwaway" semantic is wrong and the `NN-` prefix's "pipeline-output-temporary" semantic is wrong.
- Naming decision (`/product`): user ratified during 2026-05-18 conversation; alternatives evaluated were `/blueprint`, `/foundry`, `/launchpad`, keep-`/prototype`-with-reframe — `/product` won on directness + consistency with `/sdd`, `/skill`, `/remind` (short noun-of-the-domain convention).
- Layout discipline: deduced from "how do artifacts evolve as the product evolves" question; production-shape-from-day-1 chosen over current-NN-flat-with-manual-reorg pattern (Option B from 2026-05-18 conversation).
