# 049 — plan

## Approach

Mechanical file relocation + path rewriting. No design creativity required — the layout target is already validated by anthill's pattern + spec 027's sibling-split. Execute parent-side (no sub-agent dispatches needed; the work is repetitive string substitution + git mv).

## Files to touch

### Moves (`git mv` — preserve history)

| From | To |
|---|---|
| `packages/mcp-product-pipeline/design-systems/` | `.claude/skills/product/design-systems/` |
| `packages/mcp-product-pipeline/vendor/open-design/` | `.claude/skills/product/vendor/open-design/` |
| `packages/mcp-product-pipeline/scripts/sync-open-design.ts` | `.claude/skills/product/scripts/sync-open-design.ts` |
| `packages/mcp-product-pipeline/schemas/od-vendor-manifest.schema.json` | `.claude/skills/product/schemas/od-vendor-manifest.schema.json` |
| `packages/mcp-product-pipeline/tests/sync-open-design.test.ts` | `.claude/skills/product/scripts/sync-open-design.test.ts` |
| `packages/mcp-product-pipeline/runtime/od-sync/` | `.claude/skills/product/runtime/od-sync/` |

### Rewrites inside the skill

| File | Change |
|---|---|
| `.claude/skills/product/references/od-catalog-index.json` | `source` field + 72 `vendor_path` entries: `packages/mcp-product-pipeline/` → `.claude/skills/product/` |
| `.claude/skills/product/SKILL.md` (line ~164) | OD vendor note: drop "if the package is present" / "falls back to mood-only" — vendor now ships with skill |
| `.claude/skills/product/templates/pipeline/02-prototype/prompt.md` | Path references in body text |
| `.claude/skills/product/templates/pipeline/02-prototype/schema.md` | Path references in citation guidance |
| `.claude/skills/product/templates/pipeline/02-prototype/references/pipeline.md` | OD path references |
| `.claude/skills/product/templates/pipeline/02-prototype/references/od-bridge.md` | OD path references |
| `.claude/skills/product/templates/pipeline/02-prototype/references/design-fidelity-checklist.md` | OD path reference + drop stale "we don't ship that library yet" note |
| `.claude/skills/product/scripts/sync-open-design.ts` | Optional cosmetic: `PKG_ROOT` → `SKILL_ROOT` (functional path resolution unchanged because both names mean "one dir up from `scripts/`") |

### Schema $ref check (no change expected)

`.claude/skills/product/vendor/open-design/MANIFEST.json` `$schema` field reads `../../schemas/od-vendor-manifest.schema.json`. From the new location (`.claude/skills/product/vendor/open-design/MANIFEST.json`), `../../` walks to `.claude/skills/product/` → `schemas/od-vendor-manifest.schema.json` ✓. Verify but don't expect to edit.

### Updates outside the skill

| File | Change |
|---|---|
| `.claude/memory/od-vendor-port-plan.md` | Mark RESOLVED at top with pointer to spec 049; preserve original content as historical record |
| `.claude/REMINDERS.md` | Dismiss the quarterly-diff reminder against `packages/mcp-product-pipeline/src/templates/` (no longer canonical); the `--check`-against-upstream reminder stays valid (just untested) |

## Alternatives considered

1. **Drawer at `.claude/vendor/open-design/` + `.claude/design-systems/`** (Option B from conversation) — repo-level mirror of anthill layout. Rejected: forces sync-harness manifest extension for a feature that only `/product` uses; loses self-contained semantic.
2. **Separate workspace package `packages/open-design-vendor/`** (Option D from conversation) — could be published independently as `@agent0/open-design-vendor`. Rejected: workspace overhead; forks need `pnpm install` to materialize; cross-fork distribution gets weirder.
3. **Leave OD in MCP, refactor skill to "no OD vendor" mode** — drop OD entirely, revert step-02 prompts to inline 5-school description. Rejected: regresses prototype-step quality (the citation chain is anthill's proven wedge); the "vendor data" doesn't conflict with skill self-containment, only "MCP runtime" does.
4. **Git submodule from `nexu-io/open-design` directly** — bypass the sync engine. Rejected for the same reasons anthill + spec 027 rejected it: submodule friction; loss of pinning + audit trail + per-path checksum.
5. **Keep sync engine in MCP, vendor data in skill** — split sync engine from vendor data. Rejected: sync engine writes to the same vendored tree it ships from; splitting creates a circular dependency where the maintainer-only tool depends on a package being sunsetted.

## Risks

1. **Test file relative imports break.** `tests/sync-open-design.test.ts` imports from `"../scripts/sync-open-design.js"`. After moving both into `.claude/skills/product/scripts/`, that path becomes `"./sync-open-design.js"`. One-line fix as part of acceptance A.
2. **`MANIFEST.json $schema` ref breaks.** The `../../schemas/od-vendor-manifest.schema.json` path needs to remain valid after the move. Validated by tracing: from `.claude/skills/product/vendor/open-design/MANIFEST.json`, `../../` = `.claude/skills/product/`; then `schemas/od-vendor-manifest.schema.json` = `.claude/skills/product/schemas/od-vendor-manifest.schema.json` ✓ (matches new schema location).
3. **Sync script `PKG_ROOT` semantic drift.** The constant says `PKG_ROOT` but the new context is a skill, not a package. Behavior is correct (path resolves to skill root via `new URL('..', import.meta.url)`), but the name lies. Cosmetic rename `PKG_ROOT` → `SKILL_ROOT` recommended for code clarity.
4. **MCP source code breakage after the move.** `packages/mcp-product-pipeline/src/od.ts` + `src/tools.ts` + `tests/od.test.ts` + `src/templates/02-prototype/` reference paths that disappear. **Out of scope per Non-goals** — user MCP session handles. This spec's plan acknowledges the breakage explicitly so the user's next MCP-side session has clear scope.
5. **`prepublishOnly` MCP script will fail** — `bun scripts/sync-open-design.ts --verify` resolves to nothing after the move. Out of scope (MCP not being published anymore); flagged for user awareness.
6. **Bun runtime requirement for sync engine** — `.claude/skills/product/scripts/sync-open-design.ts` requires `bun` at the maintainer's machine. Already required (MCP package used bun); no new dependency. Documented in spec 049 § Dependencies via the test reference.

## Execution order

1. **Scaffold spec 049** (this file + spec.md + tasks.md) — done by the time this plan is read.
2. **Run 6 `git mv` operations** in sequence. Order doesn't matter (no cross-file dependencies during the moves themselves).
3. **One-line edit to `tests/sync-open-design.test.ts`** — `"../scripts/sync-open-design.js"` → `"./sync-open-design.js"`.
4. **Optional cosmetic edit to `scripts/sync-open-design.ts`** — `PKG_ROOT` → `SKILL_ROOT` for honesty.
5. **Bulk-rewrite `od-catalog-index.json`** — one `sed -i 's|packages/mcp-product-pipeline/|.claude/skills/product/|g'` covers source field + all 72 vendor_path entries.
6. **Targeted rewrites** to SKILL.md note + 5 step-02 template files. Each is a small Edit (or sed for the bulk substring case).
7. **`bash .claude/skills/skill/scripts/validate.sh .claude/skills/product`** — confirm gate D from spec 048 still passes.
8. **`bun .claude/skills/product/scripts/sync-open-design.ts --verify`** — confirm checksums match (they should — git mv preserves content).
9. **`bun .claude/skills/product/scripts/sync-open-design.ts --check`** — fetch upstream HEAD, write daily report, confirm engine works from new location. May report drift (`d25a7aaf` was pinned 2026-04-30, upstream likely advanced); drift report ≠ failure.
10. **Update `.claude/memory/od-vendor-port-plan.md`** — RESOLVED stamp + spec 049 pointer at top.
11. **Update `.claude/REMINDERS.md`** — dismiss obsolete diff reminder; the `--check` one stays.
12. **Commit** — `feat(049): port OD vendor from MCP package to /product skill` with HEREDOC body listing the moves + rewrites + sync verification result.

## Notes

- Per CLAUDE.md governance gate, `rm -rf` is blocked (combined flags) but not needed here — `git mv` is non-destructive.
- Per `.claude/rules/delegation.md`, no sub-agent dispatches happen during this spec (parent-side mechanical work; sub-agent would just add audit-log noise).
- Per `.claude/rules/secrets-scan.md` + supply-chain hooks, no install commands needed — bun is already at the user's machine.
- Per `.claude/rules/tdd.md`, the sync engine has existing tests (`sync-open-design.test.ts`) which port with it; no new test files required (mechanical move + rewrites don't introduce new behavior to test).
