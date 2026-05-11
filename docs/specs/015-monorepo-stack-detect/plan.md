# 015 — monorepo-stack-detect — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Refactor the existing `mcp-recipes-hint.sh` detection logic into a small helper function that takes a path argument and emits signal labels. Call it once for `$CLAUDE_PROJECT_DIR` (preserving existing behaviour) and then loop over workspace-dir globs (`apps/*/`, `packages/*/`, `services/*/`, `workspaces/*/`, plus `$CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` if set) calling it on each match. Aggregate signal labels (with workspace-prefixed paths) and the recipe set across all invocations; emit one combined hint block as today.

Spec 014's open question 4 anticipated this: the refactor lets 014's new detection branches (OpenTelemetry, Grafana) be workspace-walked for free. If 015 lands BEFORE 014, the OTel/Grafana additions in 014 inherit the walk; if 014 lands first, 015's refactor brings them into the walk. Either order works as long as the function abstraction is preserved.

Build order: refactor existing branches into a `detect_at <path>` function (no behaviour change — regression guard via existing spec 012 suite) → add workspace-walk loop calling the function → add env-var override → RED tests for workspace scenarios → run both suites → live-verify against a fixture mimicking a real monorepo.

## Files to touch

**Create:**

- `.claude/tests/monorepo-stack-detect/run-all.sh` — driver.
- `.claude/tests/monorepo-stack-detect/01-next-in-apps-web.sh` — RED: fixture with `apps/web/next.config.js` → hint suggests `next-devtools-mcp` + `playwright-mcp` with signal label `apps/web/next.config.js`.
- `.claude/tests/monorepo-stack-detect/02-db-in-apps-api.sh` — RED: fixture with `apps/api/schema.prisma` → hint suggests `dbhub` with signal `apps/api/schema.prisma`.
- `.claude/tests/monorepo-stack-detect/03-combined-dedupe.sh` — RED: fixture with multiple workspaces and overlapping signals → hint dedupes recipe names but lists all signals.
- `.claude/tests/monorepo-stack-detect/04-default-layouts.sh` — RED: cycle through all 4 default workspace dirs (`apps`, `packages`, `services`, `workspaces`), each with `next.config.js` in one of its children → each fires.
- `.claude/tests/monorepo-stack-detect/05-custom-workspace-dirs.sh` — RED: `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS="modules subprojects"` + `modules/web/next.config.js` → detector picks it up; default `apps/*/` doesn't fire (the env var replaces, not merges).
- `.claude/tests/monorepo-stack-detect/06-root-still-works.sh` — RED: root `next.config.js` (no workspaces) → hint fires unchanged (regression guard for spec 012).
- `.claude/tests/monorepo-stack-detect/07-depth-cap.sh` — RED: `apps/web/nested/deep/next.config.js` → hint does NOT fire (depth-2+ ignored).
- `.claude/tests/monorepo-stack-detect/08-opt-out.sh` — RED: monorepo with strong signals + `CLAUDE_SKIP_MCP_RECIPES=1` → silent (regression guard for spec 012's escape hatch).
- `.claude/tests/monorepo-stack-detect/09-empty-env-disables-walk.sh` — RED: `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""` (empty) + monorepo with workspace signals → walk skipped, only root detection runs.

**Modify:**

- `.claude/hooks/mcp-recipes-hint.sh` — refactor existing per-signal blocks into a `detect_at` shell function taking `<path>` as arg; loop the function over root + workspace-walk dirs; aggregate the union of recipes; emit one combined hint block. Default workspace set: `apps packages services workspaces`. Override via `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` (space-separated; replaces default; empty string disables walk).
- `.claude/rules/mcp-recipes.md` — § Stack-detector signal table gains a "Walk scope" subsection naming the default workspace dirs + the env-var override. Existing rows describe what each signal detects (file/dep); they apply at every walked path. Add a new gotcha for the depth cap.

**Delete:** none.

## Alternatives considered

### Walk arbitrary depth

Rejected. Stat-call cost grows with tree depth; on a 1000-file project the walk could become noticeable. The depth-1 + env-var-for-custom-paths combo handles 95%+ of real monorepos. Forks with unusual structures use the env var to point directly at workspace roots.

### Parse workspace config files (`pnpm-workspace.yaml`, `package.json` workspaces field)

Rejected. Adds dependency on YAML parsing (jq doesn't natively do YAML); shells out to additional tools; ties hook to specific tooling conventions. The shallow-glob + env-var-override approach is simpler and equally effective in practice.

### Hardcode the walk to only `apps/*/`

Rejected. Even within pnpm/Yarn workspaces, conventions vary — Nx uses `apps/` + `libs/`, Turborepo uses `apps/` + `packages/`, some teams use `services/`. The default-set covers the dominant conventions; the env var handles exotic ones.

### Make workspace walk OPT-IN via separate env var

Rejected. The whole point of this spec is closing a documented blind spot. Opt-in walks would leave the default behaviour unchanged and the blind spot intact. Forks that find the walk noisy can opt OUT via `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""` (empty set).

### Always emit per-workspace blocks separately (one hint block per workspace)

Rejected. SessionStart context budget is precious — multiple blocks bloat. The combined-hint with signal-list-prefixed-by-workspace already preserves enough information for the agent to know where signals came from.

## Risks and unknowns

- **`CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""` empty-set semantics.** Setting to empty string SHOULD opt out of all walks (root-only detection, equivalent to spec 012's pre-015 behaviour). Test 09 covers this explicitly.
- **Refactor regression risk.** Pulling existing branches into a function that takes `<path>` is mechanical, but easy to introduce off-by-one bugs (e.g. forgetting to reset state between calls). Mitigation: the existing spec 012 test suite is the regression net — run it after every refactor commit.
- **Spec 014 coordination.** If 014 lands first, its OTel/Grafana branches must be made path-parameterisable when 015's refactor lands. Mitigation: spec 014's tasks already note the open question; 015 takes responsibility for the refactor regardless of order.
- **Signal-label readability.** Prefixed paths (`apps/web/next.config.js`) are longer than bare ones (`next.config.js`); SessionStart context block grows. Bounded by the 4-workspace default + few signals per workspace; not unbounded.
- **Permission errors on workspace dirs.** A monorepo with read-restricted dirs (rare but possible — `apps/internal/.../` chmod 000) would surface stat errors. Mitigation: silence-fail on each detect_at call (exit 0 if stat fails); same fail-open posture as every other hook.
- **`grafana/` collision.** Spec 014 may add a `grafana/` dir signal. If a monorepo has `apps/grafana/` (a Grafana dashboards subproject) AND `apps/web/`, the workspace-walk would fire grafana-mcp on `apps/grafana/`. Acceptable: that's likely correct.

## Research / citations

- Spec 012 (`docs/specs/012-mcp-recipes/`) — capacity being extended.
- Spec 014 (`docs/specs/014-mcp-recipes-extras/`) — sibling; coordinate on refactor approach.
- Monorepo conventions (informational): pnpm workspaces, Yarn workspaces, npm workspaces, Turborepo, Nx, Bazel. The default-set covers 90%+ of JS/TS monorepos by convention; non-JS monorepos (Python with `src/` layouts) typically don't use these names.
