# 049 — tasks

Execute top-to-bottom. Each task maps to one bash invocation or one Edit.

## Phase A — moves (git mv preserves history)

- [x] A1. `git mv packages/mcp-product-pipeline/design-systems .claude/skills/product/design-systems`
- [x] A2. `git mv packages/mcp-product-pipeline/vendor/open-design .claude/skills/product/vendor/open-design`
- [x] A3. `git mv packages/mcp-product-pipeline/scripts/sync-open-design.ts .claude/skills/product/scripts/sync-open-design.ts`
- [x] A4. `git mv packages/mcp-product-pipeline/schemas/od-vendor-manifest.schema.json .claude/skills/product/schemas/od-vendor-manifest.schema.json` (mkdir target parent first)
- [x] A5. `git mv packages/mcp-product-pipeline/tests/sync-open-design.test.ts .claude/skills/product/scripts/sync-open-design.test.ts`
- [x] A6. `git mv packages/mcp-product-pipeline/runtime/od-sync .claude/skills/product/runtime/od-sync` (mkdir target parent first)

## Phase B — sync engine adaptation

- [x] B1. Edit `.claude/skills/product/scripts/sync-open-design.test.ts`: `"../scripts/sync-open-design.js"` → `"./sync-open-design.js"`
- [x] B2. Optional cosmetic: rename `PKG_ROOT` → `SKILL_ROOT` in `.claude/skills/product/scripts/sync-open-design.ts` (functional behavior unchanged)

## Phase C — path rewrites

- [x] C1. Bulk rewrite `.claude/skills/product/references/od-catalog-index.json`: `packages/mcp-product-pipeline/` → `.claude/skills/product/` (sed -i; covers `source` field + 72 `vendor_path` entries)
- [x] C2. Edit `.claude/skills/product/SKILL.md` § Notes OD entry: replace "if the package is present; falls back to mood-only inheritance if absent" with the new self-contained semantic
- [x] C3. Bulk rewrite `.claude/skills/product/templates/pipeline/02-prototype/` files: `packages/mcp-product-pipeline/` → `.claude/skills/product/` (5 files: prompt.md, schema.md, references/pipeline.md, references/od-bridge.md, references/design-fidelity-checklist.md)
- [x] C4. Verify with `grep -rn 'packages/mcp-product-pipeline/design-systems\|packages/mcp-product-pipeline/vendor/open-design' .claude/skills/product/` — expect zero matches

## Phase D — verification

- [x] D1. `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` — exit 0 (gate D)
- [x] D2. `bun .claude/skills/product/scripts/sync-open-design.ts --verify` — exit 0 (checksums intact; git mv preserves content byte-for-byte)
- [x] D3. `bun .claude/skills/product/scripts/sync-open-design.ts --check` — sync engine reads MANIFEST from new location, fetches upstream HEAD, writes daily report to `.claude/skills/product/runtime/od-sync/2026-05-18.md`. Drift report against upstream is informational, not a failure.

## Phase E — memory + REMINDERS

- [x] E1. Edit `.claude/memory/od-vendor-port-plan.md`: add RESOLVED stamp at top with `→ docs/specs/049-od-vendor-port-to-skill/` pointer; keep original content as historical record
- [x] E2. Dismiss obsolete REMINDER about quarterly diff between `.claude/skills/product/templates/pipeline/` and `packages/mcp-product-pipeline/src/templates/` (with MCP discontinuation + this port, the skill IS the canonical source)

## Phase F — commit

- [x] F1. `git status` + `git diff --stat` — confirm spec scaffold + 6 moves + rewrites + memory updates only (no stray edits)
- [x] F2. `git add` the relevant paths (not `git add -A`; per CLAUDE.md staging discipline)
- [x] F3. Commit with HEREDOC body: `feat(049): port OD vendor from MCP package to /product skill — 73 design-systems + sync engine + manifest moved; skill now self-contained`
- [x] F4. `git status` — confirm clean
- [x] F5. Flip spec 049 `Status:` to `shipped`; mark all checkboxes in this tasks.md.
