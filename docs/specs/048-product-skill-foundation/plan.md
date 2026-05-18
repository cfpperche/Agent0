# 048 — product-skill-foundation — plan

_Drafted from `spec.md` 2026-05-18. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two coupled changes (rename + layout refactor) shipped as one atomic spec. Both touch overlapping files (SKILL.md, references/*.md, all 15 templates/pipeline/<step>/prompt.md, monorepo-skeleton globals.css), and shipping them separately would force two rounds of dogfood validation. Bundling is the lower-cost path.

**Execution shape:** 5 batches, sequenced. Batches B+C touch the same file surfaces (rename then layout-refactor the same SKILL.md / delegation-briefs.md / templates), so doing them in one continuous pass is cheaper than splitting. Batch D (dogfood) validates end-to-end. Batch E (validator + commit) closes.

**Idempotency:** the rename `git mv .claude/skills/prototype .claude/skills/product` is a single git operation. Find/replace `/prototype` → `/product` is mechanical sed. The layout refactor is also mechanical — every brief's CONTEXT/DELIVERABLE paths replace 1:1 per the mapping table in spec.md § B. Worth scripting? Probably not — sed for the rename is enough; layout paths need per-context awareness because some refs go to `docs/prd/v1.md` (subfolder) and others go to `docs/sitemap.yaml` (flat), so a single mass sed would corrupt.

## Files to touch

**Skill directory (renamed via git mv):**

- `.claude/skills/product/` (was `.claude/skills/prototype/`)

**Inside the renamed skill — content edits:**

- `SKILL.md` — frontmatter (name + description + version 0.3.0); Phase 0 mkdir paths; Phase 1-5 dispatch references (each step's deliverable path); Phase 5 handoff message paths; stitch regex (`docs/design-system/tokens.css`); Notes section (validator-scope + dispatch-order + sub-agent oversize warnings — keep wording but update path examples)
- `references/delegation-briefs.md` — all 15 step briefs (CONTEXT reads + DELIVERABLE writes) + per-stack screen-writer brief (Step 02 lo-fi mood screen path; Step 15 hi-fi page.tsx path is `app/<route>/page.tsx` — unchanged)
- `references/pipeline-coverage.md` — paths table reflects new layout
- `references/state-machine.md` — declares `version: 4` + migration discipline (refuse silent v3 upgrade); `phase` enum + `step` 1-15 unchanged
- `references/sitemap-schema.md` — own path citation updates to `docs/sitemap.yaml` (it was already pseudo-correct in v3 since the file was at `docs/07-sitemap.yaml` — only drops `07-` prefix)
- `templates/pipeline/01-ideation/prompt.md` — `Write to {{out}}/docs/01-concept-brief.md` → `Write to {{out}}/docs/concept-brief.md`
- `templates/pipeline/02-prototype/prompt.md` — same pattern for `02-direction-a.html` + `02-screens/` → `direction-a.html` + `screens/`
- `templates/pipeline/03-spec/prompt.md` — `03-functional-spec.md` → `functional-spec.md`
- `templates/pipeline/04-ux-testing/prompt.md` — `04-validation-report.md` → `validation-report.md`
- `templates/pipeline/05-prd/prompt.md` — **`05-prd.md` → `prd/v1.md`** (subfolder creation)
- `templates/pipeline/06-ost/prompt.md` — `06-ost.md` → `ost.md`
- `templates/pipeline/07-sitemap-ia/prompt.md` — `07-sitemap.yaml` → `sitemap.yaml`
- `templates/pipeline/08-system-design/prompt.md` — `08-system-design.md` + `08-security.md` + `08-data-flow.json` → `system-design.md` + `security.md` + `data-flow.json`
- `templates/pipeline/09-legal/prompt.md` — `09-legal-posture.md` → `legal-posture.md`; CONTEXT references to `08-data-flow.json` → `data-flow.json`
- `templates/pipeline/10-roadmap/prompt.md` — `10-roadmap.md` → `roadmap.md`
- `templates/pipeline/11-cost-estimate/prompt.md` — `11-cost-estimate.md` → `cost-estimate.md`; CONTEXT refs to `10-roadmap.md` → `roadmap.md`
- `templates/pipeline/12-gtm-launch/prompt.md` — `12-gtm-launch.md` → `gtm-launch.md`
- `templates/pipeline/13-brand/prompt.md` — `13-brand-book.md` → `brand-book.md`
- `templates/pipeline/14-design-system/prompt.md` — **`14-tokens.css` + `14-components.md` + `14-design-system.md` → `design-system/tokens.css` + `design-system/components.md` + `design-system/README.md`** (subfolder + README rename)
- `templates/pipeline/15-screen-atlas/prompt.md` — `15-screen-atlas.md` → `screen-atlas.md`; CONTEXT reads list updated to new paths; Sitemap Coverage Cross-Check path computation updated
- `templates/monorepo-skeleton/next/app/globals.css` — `@import "../docs/14-tokens.css"` → `@import "../docs/design-system/tokens.css"` (third update)

**Outside the skill:**

- `CLAUDE.md` — `## Prototype skill` section → `## Product skill`; description reframe
- `docs/specs/045-prototype-skill-pipeline-realign/spec.md` § Lineage — add note "skill renamed to /product via spec 048"
- `.claude/SESSION.md` — Batch E update reflecting spec 048 SHIPPED
- `.claude/REMINDERS.md` — dismiss stale prototype-template-diff reminder (if appropriate; user may keep for MCP-session reconciliation); optionally add spec-049 candidate item

**NOT touched:**

- `packages/mcp-product-pipeline/` — MCP responsibility (user's MCP session)
- `docs/specs/032-pipeline-industry-alignment/` — same
- `docs/specs/037-044*` — never created, not our problem
- `.claude/skills/skill/` — meta-toolkit unchanged

## Alternatives considered

### A. Split into two specs (048-rename + 049-layout)

- **Why considered:** keeps each spec scope tight; bisectable git history if regression surfaces.
- **Rejected because:** double dogfood overhead (each spec needs its own end-to-end validation), and the file surfaces overlap so heavily that conflict resolution between the two specs would be painful.

### B. Keep `NN-` prefix, just rename the skill

- **Why considered:** minimal-change path; least disruptive to existing forks.
- **Rejected because:** the layout issue is the same magnitude as the naming issue — both stem from the "this is throwaway pipeline output" framing that no longer holds. Fixing one without the other leaves half the dissonance.

### C. Hybrid emit — `--mode=draft` (NN-flat) vs `--mode=initialize` (production layout)

- **Why considered:** lets founder choose per use case; backwards-compatible with v3 output.
- **Rejected because:** doubles the surface to maintain; spec 045 dogfood already showed the cost of testing variations; no real scenario where a founder wants throwaway output now that MCP isn't the alternative.

### D. Keep `/prototype` name, just reframe semantically in SKILL.md description

- **Why considered:** zero edits to file paths; zero risk to existing references.
- **Rejected because:** the user explicitly named `/product` as the choice. Reframing-without-renaming pays interest forever — every new person seeing `prototype` defaults to the throwaway connotation regardless of what the description says.

### E. PRD as flat `docs/prd.md` until v2 exists

- **Why considered:** simpler first-run layout; defer subfolder until needed.
- **Rejected because:** the subfolder gesture at first run is the *signal* that this artifact is release-versioned by nature. Deferring it loses the teaching moment; founders default to "this PRD is THE PRD" and then resist creating v2 later.

## Risks + unknowns

1. **Sync-harness fork migration friction.** Forks with `.claude/skills/prototype/` checked in won't auto-migrate; their next `sync-harness.sh` will leave the old dir orphaned + add the new one. Acceptable (manual cleanup), but worth documenting in spec.md § Non-goals + REMINDERS.
2. **State.json v4 breaking abort.** Any in-flight runs from pre-048 won't auto-upgrade; founder must clear `--out` and restart. Same pattern as spec 045's v2→v3 abort. Acceptable per same precedent.
3. **Hidden hard-coded references** to old paths or skill name in places we don't notice (e.g. a forgotten audit log path, a hook reading `prototype-state.json`). Mitigation: Batch E validator + manual grep across the full repo.
4. **The skeleton's `globals.css` is being updated for the third time** — every spec that changes the tokens.css path forgets this file. Spec 045 commit message claimed it was updated but it wasn't (caught by today's dogfood). This time: explicit Batch C task includes the grep verification.
5. **Dogfood time budget.** Full 15-step run took ~2.5h in spec 045; same scale expected here. If we hit it, ~6-7h total estimate holds. If we hit ~4h on dogfood alone, that's still within session budget.
6. **REPORT.md template** in `.claude/skills/product/templates/report.md.tmpl` — needs verification its path placeholders update too (or it's a static template that the SKILL.md substitutes into).

## Execution batches (sequenced, with rough sizing)

| # | Batch | Effort | Depends on | Outcome |
|---|---|---|---|---|
| A | Scaffold spec 048 (this file + spec.md + tasks.md) | 30 min | — | docs/specs/048-product-skill-foundation/ populated |
| B | Rename `/prototype` → `/product` (git mv + find/replace) | 45-60 min | A | .claude/skills/product/ exists; all references updated |
| C | Layout refactor (drop NN-, semantic paths, version 4) | 90-120 min | B | All deliverable paths + globals.css + state.json migrated |
| D | Dogfood "ERP para salões de beleza" cold-cache end-to-end | 150-180 min | C | /tmp/dogfood-erp/ exists with new layout; tsc + biome PASS; REPORT.md compares vs /tmp/dogfood-v3 |
| E | Validator + commit + spec flip + SESSION.md | 30 min | D | spec 048 status `shipped`; clean commit; SESSION.md updated |

**Total: ~6-7 hours**. Realistic for one focused session given /goal directive.

## Acceptance gate

Per spec.md § E — the dogfood `/tmp/dogfood-erp/` is the proof. If it lands with the new layout intact and tsc + biome green, spec 048 ships. If layout regressions surface (e.g. some sub-agent writes to `docs/05-prd.md` because its brief still has the old path), batch C needs revision before E proceeds.
