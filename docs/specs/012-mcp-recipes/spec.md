# 012 — mcp-recipes

_Created 2026-05-11._

**Status:** shipped

## Intent

Document and surface a curated, per-project, stack-aware set of opt-in MCP server recipes so forks adopt mature external introspection capabilities (browser, DB, framework) without inventing their own configurations. Spec 011 covered the agent-self-debug wedge with hooks; this spec covers the **adopt** side of the build-vs-adopt split — the recipes name the four mature external MCPs (Playwright MCP, Chrome DevTools MCP, DBHub, Next.js DevTools MCP), each as a copy-paste-ready `.mcp.json` block with capabilities, install-command, and when-to-enable notes. A `SessionStart` companion hook detects the fork's stack and emits a one-block hint naming the applicable recipes — the fork still chooses, no automatic installs. Each fork's `.mcp.json` is its own (per MCP convention); Agent0 ships only the example + the stack-aware nudge.

## Acceptance criteria

- [ ] **Scenario: recipe documented for each of the 4 v1 MCPs**
  - **Given** the spec ships
  - **When** a developer reads `.claude/rules/mcp-recipes.md`
  - **Then** they find one section per MCP (Playwright, Chrome DevTools, DBHub, Next.js DevTools) covering: official source URL, what runtime introspection it provides, the verbatim `.mcp.json` block to paste, the per-fork install command (`npx -y` / `bunx` shape), and explicit when-to-enable signals (E2E work / Postgres-backed app / Next.js project / etc.)

- [ ] **Scenario: `.mcp.json.example` ships at repo root**
  - **Given** a fork of Agent0 is freshly cloned
  - **When** the developer runs `ls`
  - **Then** they find `.mcp.json.example` at the repo root with commented blocks for all four MCPs and a header comment explaining the copy-and-uncomment workflow

- [ ] **Scenario: Next.js project detection suggests next-devtools + playwright**
  - **Given** the fork's repo contains `next.config.{js,ts,mjs}` OR `package.json` listing `next` in dependencies
  - **When** a Claude Code session starts in that fork
  - **Then** the SessionStart hint block includes a recipe-suggestion line naming next-devtools-mcp and playwright-mcp (browser observation is naturally paired with framework introspection for E2E)

- [ ] **Scenario: non-Next browser-stack detection suggests playwright + chrome-devtools**
  - **Given** the fork has `package.json` with `react` / `vue` / `svelte` / `vite` / `astro` dependencies BUT no `next` signal
  - **When** a session starts
  - **Then** the hint suggests playwright-mcp and chrome-devtools-mcp (Stagehand-style observation, no framework-specific helpers)

- [ ] **Scenario: DB-shaped project detection suggests DBHub**
  - **Given** the fork contains any of: `schema.prisma`, `drizzle.config.*`, `alembic.ini`, `database/migrations/`, `db/migrate/`, OR a `DATABASE_URL` line in `.env.example`
  - **When** a session starts
  - **Then** the hint suggests DBHub with a one-line "set `DATABASE_URL` and re-source" follow-up

- [ ] **Scenario: no stack signals → silent**
  - **Given** the fork is the Agent0 base (no Next/React/Vue/DB markers, just markdown + hooks)
  - **When** a session starts
  - **Then** the hint block is NOT emitted (no false suggestions; silence is the right default for a generic template)

- [ ] **Scenario: hint co-exists with spec 011's probe hint**
  - **Given** spec 011 is also installed (probe.sh exists)
  - **When** a session starts in a stack-detected fork
  - **Then** the SessionStart context contains BOTH the runtime-introspect probe hint AND the mcp-recipes recipe-suggestion hint — order does not matter, both blocks are visible

- [ ] **Scenario: opt-out**
  - **Given** `CLAUDE_SKIP_MCP_RECIPES=1` is set
  - **When** a session starts
  - **Then** the recipe hint is NOT emitted regardless of stack signals (parallel escape hatch to `CLAUDE_SKIP_RUNTIME_INTROSPECT`)

- [ ] `.claude/rules/mcp-recipes.md` exists and covers the 4 MCPs end-to-end
- [ ] `.mcp.json.example` exists at repo root with all 4 blocks commented, header comment explaining workflow
- [ ] `.claude/hooks/mcp-recipes-hint.sh` exists, is executable, and is registered on `SessionStart` in `.claude/settings.json`
- [ ] Stack detector function uses a small fixed list of file/dependency signals (no globs walking node_modules, no parsing every JSON)
- [ ] `CLAUDE.md` gets a new § Mcp recipes block (one paragraph + link to the rule doc)
- [ ] No new hooks fire outside `SessionStart` — this capacity is pure recommendation, never blocks or audits

## Non-goals

- **Auto-install of MCP servers.** Recipes are documented and suggested; the developer runs `npx`/`bunx`/clones manually. No `npm i`-on-behalf shenanigans.
- **Custom MCP authoring.** Agent0 does NOT build new MCPs in this spec. The four are external, mature, and curated. Future MCPs land in follow-up specs.
- **Lifecycle management.** No process supervision, no restart-on-crash, no port management. Each MCP defines its own stdio/http lifecycle; Claude Code handles invocation.
- **Cross-project shared MCPs.** Each fork's `.mcp.json` is its own (this matches MCP's per-project convention). No global registry, no shared cache.
- **MCPs outside the 4 in scope for v1.** OpenTelemetry MCP, Grafana MCP, Filesystem, Git, Memory, etc. are real candidates but are deferred. v1 is browser × 2 + DB × 1 + framework × 1 = the highest-leverage starter set.
- **Detection beyond shallow file-existence/dependency-name checks.** No package-lock parsing, no node_modules walking, no transitive-dep introspection. Telltale signals are: top-level files, `package.json.dependencies` keys.
- **Security configuration helpers.** Recipes link to each MCP's own security docs; Agent0 does not duplicate or summarise (e.g. DBHub's readonly mode, Playwright's allowed-domains config — those are the MCP's docs, not ours).
- **Blocking or audit-log behaviour.** Pure recommendation capacity. No `.mcp-audit.jsonl`, no exit-2 paths. The agent already has runtime-introspect for evidence; this spec just expands the toolset.

## Open questions

- [ ] **`.mcp.json.example` location** — repo root (parallel to where forks place their `.mcp.json`) OR `.claude/mcp-recipes/example.json` (under the harness tree, consistent with rules/skills/hooks)? Proposal: **repo root** — copy-paste workflow is one `cp .mcp.json.example .mcp.json` away from working; placement under `.claude/` would require an extra hop and is less discoverable.
- [ ] **Hint format** — one combined SessionStart block listing all suggested recipes, OR one block per suggested recipe? Proposal: **combined block**, since SessionStart context budget is shared with SESSION.md, COMPACT_NOTES, runtime-introspect hint, and reminders.
- [ ] **Stack-detector scope** — v1 lists the 4 in scope; should detection also point forks at MCPs we did NOT bundle (e.g. detect a `pyproject.toml` and suggest a Python MCP we know exists)? Proposal: **no in v1** — the spec advertises only what's in the recipe doc. Pointing at unbundled MCPs leaks scope and creates "this MCP that I didn't ship is broken" support burden.
- [ ] **Recipe versioning** — should the `.mcp.json.example` pin package versions (e.g. `@playwright/mcp@0.0.30`) or use `@latest`? Proposal: **omit version, document as `@latest`** in v1, with a Gotcha noting forks that hit churn should pin manually. Spec is descriptive, not stability-guaranteeing.

## Context / references

- `docs/specs/011-runtime-introspect/` — sibling capacity (build side); this spec covers the adopt side. Shared discovery pattern (`SessionStart` hint when capability artifacts exist).
- `.claude/rules/runtime-introspect.md` § Non-goals — explicitly defers browser introspection (Playwright, Chrome DevTools) and DB introspection (DBHub) to "future `.mcp.json.example` follow-up" — this is that follow-up.
- Web research session 2026-05-11:
  - [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) — 32k★ browser automation/observation MCP, the dominant choice
  - [Chrome DevTools MCP](https://developer.chrome.com/blog/chrome-devtools-mcp) — Google, public preview Sept 2025, ~29 tools (network, console, Lighthouse, V8 heap, Core Web Vitals)
  - [bytebase/dbhub](https://github.com/bytebase/dbhub) — multi-engine DB MCP gateway (Postgres / MySQL / SQLite / MSSQL / MariaDB)
  - [vercel/next-devtools-mcp](https://github.com/vercel/next-devtools-mcp) — v0.3.10 Jan 2026, MIT, Next.js framework introspection (build errors, routes, server actions, dev logs)
- [MCP protocol overview](https://modelcontextprotocol.io/) — `.mcp.json` per-project convention
- Memory: `project_visibility_intent.md` — frames why this complements 011 rather than duplicating it
