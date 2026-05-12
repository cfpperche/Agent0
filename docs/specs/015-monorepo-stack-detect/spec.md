# 015 — monorepo-stack-detect

_Created 2026-05-11. Status: draft._

## Intent

Extend spec 012's stack-detector hook to walk one level deep into common monorepo workspace layouts (`apps/*/`, `packages/*/`, `services/*/`, `workspaces/*/`) so a fork with `apps/web/next.config.js` + `apps/api/schema.prisma` at `CLAUDE_PROJECT_DIR` root surfaces the right recipe hints, instead of silently passing the monorepo blind spot documented in spec 012's gotchas. Same SessionStart hint shape, same hook, same opt-out env var; the diff is the scope of the scan. Adds one new env var (`CLAUDE_MCP_RECIPES_WORKSPACE_DIRS="<space-separated dir names>"`) for forks whose monorepo uses a non-standard layout.

## Acceptance criteria

- [ ] **Scenario: Next.js detected one level deep in `apps/*/`**
  - **Given** the fork has `apps/web/next.config.js` and `apps/api/package.json` (with non-Next deps) at `CLAUDE_PROJECT_DIR/apps/`
  - **When** a session starts at the monorepo root
  - **Then** the hint suggests `next-devtools-mcp` + `playwright-mcp` and the signal label reads `apps/web/next.config.js`

- [ ] **Scenario: DB detected one level deep**
  - **Given** the fork has `apps/api/schema.prisma`
  - **When** a session starts
  - **Then** the hint suggests `dbhub` with signal label `apps/api/schema.prisma`

- [ ] **Scenario: combined signals from multiple workspaces dedupe correctly**
  - **Given** the fork has `apps/web/next.config.js` + `apps/api/schema.prisma`
  - **When** a session starts
  - **Then** the hint lists `next-devtools-mcp`, `playwright-mcp`, `dbhub` each exactly once (set-like union)

- [ ] **Scenario: standard layouts auto-recognised**
  - **Given** workspaces under any of `apps/`, `packages/`, `services/`, `workspaces/` (the v1 default set)
  - **When** a session starts
  - **Then** detection covers all of them; signals from any workspace contribute to the suggestion set

- [ ] **Scenario: custom workspace layout via env var**
  - **Given** `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS="modules subprojects"` is set, and the fork has `modules/web/next.config.js`
  - **When** a session starts
  - **Then** the env-var-listed dirs replace (not merge with) the default set, and detection covers `modules/*/`

- [ ] **Scenario: root signals still detected (regression)**
  - **Given** the fork has `next.config.js` at root (the original spec 012 case)
  - **When** a session starts
  - **Then** the hint fires unchanged — workspace-walk does NOT supersede or duplicate root detection

- [ ] **Scenario: depth cap honored**
  - **Given** a deeply nested project with `apps/web/nested/deep/next.config.js`
  - **When** a session starts
  - **Then** the hint does NOT fire on the depth-2+ file (walk is strictly depth-1 per workspace pattern)

- [ ] **Scenario: opt-out still works**
  - **Given** `CLAUDE_SKIP_MCP_RECIPES=1`
  - **When** a session starts in a monorepo with strong signals
  - **Then** the hint is NOT emitted

- [ ] **Scenario: empty env-var disables walk entirely**
  - **Given** `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""` (set but empty)
  - **When** a session starts in a monorepo with `apps/web/next.config.js`
  - **Then** the workspace walk is skipped entirely; only root-level detection runs (equivalent to spec 012's pre-015 behaviour)

- [ ] `.claude/hooks/mcp-recipes-hint.sh` gains a workspace-walk pass that runs after root detection
- [ ] `.claude/rules/mcp-recipes.md` § Stack-detector signal table documents the workspace-walk default set and the `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` override
- [ ] Spec 012's test suite still 6/6 PASS (regression-free)
- [ ] New test suite under `.claude/tests/monorepo-stack-detect/` covers all 9 scenarios

## Non-goals

- **Walking deeper than one level.** Depth-2+ is a slippery slope toward arbitrary tree walks; expensive and rarely the right call. Forks with deeper nesting use `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` to point directly at workspace roots.
- **Per-workspace `.mcp.json` files.** MCP convention is per-project; some monorepos may want per-workspace MCPs but that's a tool-author problem (Claude Code's MCP loading is per-`CLAUDE_PROJECT_DIR`), not a recipe-recommendation problem.
- **Auto-fixing the user's monorepo structure.** No moving / symlinking files on the user's behalf.
- **Parsing workspace configuration files** (e.g. `pnpm-workspace.yaml`, `package.json` `workspaces` field). The workspace-name globbing approach is shallow on purpose; forks with exotic structures use the env var.
- **Signal-label format change.** The header line stays `Stack signals detected: <comma-separated>`; just may include workspace-prefixed paths now.

## Open questions

_Resolved 2026-05-12 before implementation:_

- [x] **Default workspace dir set** — `apps packages services workspaces`. `crates` omitted in v1; revisit when/if cargo monorepo signal surfaces alongside JS/Python sub-projects.
- [x] **Multiple matches in same workspace** — keep separate (`apps/web/next.config.js, apps/web/schema.prisma`). Greppable, no special parsing.
- [x] **Performance ceiling** — defer instrumentation. ~100 syscalls per SessionStart is trivial on local SSD; add timing only if CI/network-FS signal surfaces.
- [x] **Interaction with spec 014 (extras)** — refactor first into `detect_at <path>` function; both root and walk call it. Spec 014's future branches inherit the abstraction regardless of land order.

## Context / references

- Spec 012 (`docs/specs/012-mcp-recipes/`) — capacity being extended. The monorepo blind spot is documented in its § Gotchas; this spec closes it.
- Spec 014 (`docs/specs/014-mcp-recipes-extras/`) — sibling extension; coordinate via the `detect_at <path>` refactor (open question 4).
- `.claude/rules/mcp-recipes.md` — capacity rule doc; extends the stack-detector signal table.
- `.claude/hooks/mcp-recipes-hint.sh` — hook to extend.
- Real-world monorepo conventions: pnpm workspaces (`apps/`, `packages/`), Turborepo (`apps/`, `packages/`), Nx (`apps/`, `libs/`), Yarn workspaces (variable). The v1 default set covers the dominant conventions; the env var handles the rest.
