# 049 — OD vendor port from MCP to `/product` skill

_Created 2026-05-18._

**Status:** shipped

## Intent

Move the Open Design (OD) vendor bundle — 73 named `DESIGN.md` design systems + 33 skill bundles + 5-school prompt sources + frames + sync engine + JSON schema + checksum manifest — **out** of `packages/mcp-product-pipeline/` and **into** `.claude/skills/product/`. After this spec, the `/product` skill is fully self-contained: no path-string reaches into `packages/mcp-product-pipeline/`, and the MCP discontinuation can complete in the user's MCP-dedicated session without leaving the skill in a half-broken state.

The triggering insight: spec 048 rebranded `/prototype` → `/product` as the standalone foundation generator, but the OD coupling was preserved as an "if the MCP package is present, read from it; else fall back to mood-only" — a soft dependency that contradicts the self-contained semantic. With MCP being discontinued, the soft dependency becomes a broken dependency. Porting OD inside the skill closes that loop and inherits anthill's proven sibling-split layout (`vendor/` for Apache-attributed upstream, `design-systems/` for the consumed `DESIGN.md` tree) — scoped to the skill rather than the repo.

Anthill (the original source of the OD pattern, ADR `.anthill/memory/architecture/adr-vendor-open-design.md`) keeps `.anthill/vendor/open-design/` next to `.anthill/design-systems/`. Anthill's distribution is symlink-at-inject-time (template injection model). Our distribution becomes "the skill ships the vendor" — sync-harness already covers `.claude/skills/`, so forks inherit OD automatically with zero manifest extension.

Spec 027 (`od-vendor-port`) originally landed OD inside the MCP package. This spec re-homes those same assets to the skill, keeping the sibling-split design intact but scoping it under `.claude/skills/product/`. Spec 027 stays shipped (its design rationale + sync-engine code still hold); only the destination changes.

## Acceptance criteria

### A. Vendor relocation (file moves)

- [ ] **Static fact:** `.claude/skills/product/design-systems/` exists and contains 73 vendor subdirs (airbnb / airtable / apple / linear-app / notion / stripe / wise / …) each with a `DESIGN.md`
- [ ] **Static fact:** `.claude/skills/product/vendor/open-design/` exists and contains `MANIFEST.json`, `LICENSE`, `NOTICE`, `skills/` (33 bundles), `prompts/{system,discovery,directions}.ts`, `frames/`, `templates/`
- [ ] **Static fact:** `.claude/skills/product/scripts/sync-open-design.ts` exists (moved from `packages/mcp-product-pipeline/scripts/sync-open-design.ts`)
- [ ] **Static fact:** `.claude/skills/product/scripts/sync-open-design.test.ts` exists (moved from `packages/mcp-product-pipeline/tests/sync-open-design.test.ts`); relative import `../scripts/sync-open-design.js` → `./sync-open-design.js`
- [ ] **Static fact:** `.claude/skills/product/schemas/od-vendor-manifest.schema.json` exists (moved from `packages/mcp-product-pipeline/schemas/`)
- [ ] **Static fact:** `.claude/skills/product/runtime/od-sync/` exists (moved from `packages/mcp-product-pipeline/runtime/od-sync/`) with prior daily reports preserved; `.gitkeep` added if empty
- [ ] **Static fact:** `packages/mcp-product-pipeline/design-systems/` does NOT exist after the move
- [ ] **Static fact:** `packages/mcp-product-pipeline/vendor/open-design/` does NOT exist after the move
- [ ] **Static fact:** `packages/mcp-product-pipeline/scripts/sync-open-design.ts` does NOT exist after the move
- [ ] **Static fact:** `git log --follow` on each moved file shows continuous history from MCP-located ancestor through new skill-located descendant (git mv preserves rename)

### B. Path rewrites inside the skill

- [ ] **Static fact:** `.claude/skills/product/references/od-catalog-index.json` `source` field reads `.claude/skills/product/design-systems/` (was `packages/mcp-product-pipeline/design-systems/`)
- [ ] **Static fact:** Every `vendor_path` in the 72-entry `vendors[]` array starts with `.claude/skills/product/design-systems/` (was `packages/mcp-product-pipeline/design-systems/`)
- [ ] **Static fact:** `.claude/skills/product/SKILL.md` § Notes OD entry no longer says "if the package is present; falls back to mood-only inheritance if absent" — the vendor is now always present (it ships with the skill)
- [ ] **Static fact:** `.claude/skills/product/templates/pipeline/02-prototype/prompt.md` references resolve to `.claude/skills/product/design-systems/<v>/DESIGN.md` (or repo-relative equivalent), NOT to `packages/mcp-product-pipeline/...`
- [ ] **Static fact:** `.claude/skills/product/templates/pipeline/02-prototype/references/{pipeline.md,od-bridge.md,design-fidelity-checklist.md}` no longer reference `packages/mcp-product-pipeline/` for OD paths
- [ ] **Static fact:** `grep -rn 'packages/mcp-product-pipeline/design-systems\|packages/mcp-product-pipeline/vendor/open-design' .claude/skills/product/` returns zero matches after rewrites

### C. Sync engine still functional from skill root

- [ ] **Static fact:** `.claude/skills/product/scripts/sync-open-design.ts` `PKG_ROOT` constant (or its skill-renamed equivalent) resolves via `import.meta.url` to `.claude/skills/product/` — verified by tracing `new URL('..', import.meta.url)` from the new script location
- [ ] **Static fact:** `.claude/skills/product/vendor/open-design/MANIFEST.json` `$schema` field resolves to `.claude/skills/product/schemas/od-vendor-manifest.schema.json` from its location (`../../schemas/od-vendor-manifest.schema.json` still correct)
- [ ] **Scenario: --check works from skill location**
  - **Given** the migrated sync engine at `.claude/skills/product/scripts/sync-open-design.ts`
  - **When** a maintainer runs `bun .claude/skills/product/scripts/sync-open-design.ts --check`
  - **Then** the script (a) fetches upstream HEAD SHA via `git ls-remote` (b) reads the manifest at the new path (c) writes a daily report to `.claude/skills/product/runtime/od-sync/YYYY-MM-DD.md` (d) updates `last_check_sha`/`last_check_at` in MANIFEST.json (e) exits 0 (or non-zero with explicit drift report if upstream HEAD ≠ pinned SHA)
- [ ] **Scenario: --verify confirms checksum integrity**
  - **Given** the relocated vendored tree with original per-path sha256 checksums in MANIFEST.json
  - **When** the maintainer runs `bun .claude/skills/product/scripts/sync-open-design.ts --verify`
  - **Then** every per-path checksum matches the actual file/tree content (because git mv preserves content byte-for-byte) and the script exits 0

### D. Spec 048 self-contained semantic preserved

- [ ] **Static fact:** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 (no regression vs spec 048's gate D)
- [ ] **Static fact:** `.claude/skills/product/SKILL.md` description still ≤1024 chars (spec 033 limit; unchanged by this spec)
- [ ] **Static fact:** Spec 048's portability tier `cc-native` is preserved (vendor is data, not behavior; the skill stays cc-native — verified by `.claude/skills/product/SKILL.md` frontmatter `metadata.agent0-portability-tier: cc-native`)

## Non-goals

- **MCP source-code cleanup** — out of scope. `packages/mcp-product-pipeline/src/od.ts`, `packages/mcp-product-pipeline/src/tools.ts` (OD-related MCP tools `product_design_systems_index` + `product_design_system_path`), and `packages/mcp-product-pipeline/tests/od.test.ts` will break after this move because they reference paths that no longer exist under the package. **User handles MCP-side cleanup in MCP-dedicated session** per the 2026-05-18 constraint. This spec deliberately leaves the MCP source code as-is to avoid scope-creep into the user's separate cleanup.
- **MCP package.json `files` / `scripts` reconciliation** — `package.json` will still list `vendor/`, `design-systems/`, `schemas/`, `scripts/` in its `files` array after this move (some now empty/missing); `sync` + `prepublishOnly` scripts will reference a non-existent path. **MCP session deals.**
- **MCP `src/templates/02-prototype/` rewriting** — MCP's own template files (parallel to the skill's templates) reference OD paths; they break too. **MCP session deals.** The skill's templates ARE in scope (this spec rewrites them).
- **Re-running sync against upstream** — the moved files are byte-identical to the pre-move state; the existing `pinned_sha d25a7aaf` + per-path checksums in MANIFEST.json remain accurate. No `--apply` run needed. A `--check` run is in scope to confirm the engine still works from its new location.
- **Renaming the skill `scripts/` dir** — the skill already has `scripts/` (created by spec 048 for any future skill-local maintenance scripts); the sync engine joins that dir naturally.
- **Publishing OD as a standalone npm/agentskills package** — vendor stays internal to the skill for now. Future spec can extract if cross-skill consumption emerges.

## Open questions

None — design ratified inline 2026-05-18 with `Aqui (Recommended)` answer (skill executes the migration including the git mv operations).

## Dependencies + cross-references

- **Spec 027 (shipped)** — original OD vendor port into MCP. Stays shipped (its design rationale + sync engine code carry forward). This spec re-homes the assets; spec 027's architectural choices (sibling-split, SHA pinning, prepublishOnly, fail-loud-not-degrade) all preserved.
- **Spec 048 (shipped 2026-05-18)** — `/product` skill foundation. This spec is the natural follow-up: closes the soft-dependency loop spec 048 left behind.
- **`.claude/memory/od-vendor-port-plan.md`** — historical project memory; updated post-port to reflect "OD vendor lives in skill" reality.
- **REMINDER (due 2026-08-18)** — quarterly diff between `.claude/skills/product/templates/pipeline/` and `packages/mcp-product-pipeline/src/templates/`. After this spec + MCP discontinuation, the skill IS the canonical source of truth for templates; the reminder becomes obsolete (user dismisses in MCP session) — replaced with a leaner reminder about `--check` quarterly cadence against upstream `nexu-io/open-design`.
- **REMINDER (untested `--check`/`--apply` against upstream)** — perfect time to validate the engine end-to-end at the new location; `--check` smoke test is in this spec's acceptance criteria.
- **`packages/mcp-product-pipeline/`** — MCP package becomes partially broken pending the user's MCP-side cleanup. Documented as Non-goal; not this spec's concern.

## Lineage

- **Anthill ADR `.anthill/memory/architecture/adr-vendor-open-design.md`** — original OD vendor architecture (sibling split, SHA pin, prepublishOnly, fail-loud). Spec 027 ported it to MCP; this spec re-homes it to the skill.
- **2026-05-18 conversation** — user asked how to remove the skill's MCP dependency on OD vendor; analysis surfaced 3 viable homes (skill-internal / `.claude/` drawer / separate package). Skill-internal won on: (1) closes spec 048's self-contained loop, (2) zero sync-harness extension needed, (3) preserves anthill's proven sibling-split semantic.
