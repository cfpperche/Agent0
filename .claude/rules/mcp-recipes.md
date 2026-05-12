# MCP recipes

A curated, opt-in set of `.mcp.json` server blocks for four mature external MCPs that complement spec 011's runtime-introspect. The recipes are documentation + a copy-paste example file at repo root; a `SessionStart` companion hook detects the fork's stack and emits a one-block hint naming the applicable recipes when matches exist. Pure recommendation capacity — no auto-installs, no audit log, no blocks. Spec: `docs/specs/012-mcp-recipes/`.

## How it works

Three artifacts plus one hook:

- **`.claude/rules/mcp-recipes.md`** (this file) — authoritative per-MCP reference.
- **`.mcp.json.example`** at repo root — copy-paste-ready file with all four blocks commented out by leading `//` markers. Workflow: `cp .mcp.json.example .mcp.json`, then remove `//` lines on the blocks you want active.
- **`.claude/hooks/mcp-recipes-hint.sh`** (`SessionStart`) — runs the signal table below and emits a single `=== mcp-recipes ===` block listing applicable recipes when ≥1 signal fires. Silent when no signals match (Agent0 base case). Honors `CLAUDE_SKIP_MCP_RECIPES=1` to suppress regardless.

The fork chooses what to enable. Recipes recommend; the developer activates with one `cp` + uncomment.

## Stack-detector signal table

The hint hook fires when any signal matches. Multiple signals can fire; the suggestion list is the deduplicated union.

| Stack | Signals (any one is sufficient) | Suggested recipes |
| --- | --- | --- |
| Next.js | `next.config.{js,ts,mjs,cjs}` exists, OR `package.json` has `next` in `dependencies` or `devDependencies` | `next-devtools-mcp` + `playwright-mcp` |
| Browser (non-Next) | `package.json` has any of `react` / `vue` / `svelte` / `vite` / `astro` in deps, AND Next signal is absent | `playwright-mcp` + `chrome-devtools-mcp` |
| DB | Any of `schema.prisma`, `drizzle.config.{js,ts,mjs}`, `alembic.ini`, `database/migrations/`, `db/migrate/` exists, OR `.env.example` has a `^DATABASE_URL=` line | `dbhub` |

The list is deliberately small. Same lesson as spec 011's detector allowlist and spec 008's supply-chain manager table: ship a strict shape, extend on real-world signal.

## Recipes

### Playwright MCP

**Source:** [github.com/microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) (Microsoft, 32k★)

**What it provides:** Browser-driving introspection for the agent — navigation, click/fill/type, network mock + inspect, accessibility snapshots, screenshots, trace/video recording. Cross-browser (Chromium / Firefox / WebKit). The dominant choice for E2E and frontend agentic work.

**`.mcp.json` block:**
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

**Install:** `npx @playwright/mcp@latest` is invoked by Claude Code as needed. Playwright manages its own browser binaries on first run (Chromium / Firefox / WebKit / Chrome / Edge).

**When to enable:** any fork doing browser/frontend/E2E work. Also paired with Next.js (see Next.js DevTools MCP below).

**Runtime requirements:** none beyond Node.js + npm.

**Security:** Playwright can navigate anywhere; the MCP inherits that surface. See upstream's [README § security considerations](https://github.com/microsoft/playwright-mcp#security) before opening it to untrusted prompts.

---

### Chrome DevTools MCP

**Source:** [github.com/ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) (Google, public preview since Sept 2025)

**What it provides:** Debugging-oriented browser introspection — listing network requests (with bodies), console logs preserving the last three navigations, Lighthouse audits, V8 heap snapshots, Core Web Vitals tracing (LCP / INP / CLS). Drives an existing Chrome session rather than automating from scratch.

**`.mcp.json` block:**
```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest"]
    }
  }
}
```

**Install:** `npx -y chrome-devtools-mcp@latest`.

**When to enable:** debugging an already-running browser session (network, console, perf). Complements Playwright — Playwright drives, DevTools observes.

**Runtime requirements:** **Google Chrome or Chrome for Testing must be installed on the host.** Other Chromium variants are unsupported. Headless CI environments without Chrome will fail at MCP startup.

**Security:** Chrome DevTools Protocol (CDP) is a debugging interface; treat the MCP's exposure to agent prompts the same as opening DevTools in an untrusted session. See upstream's [README](https://github.com/ChromeDevTools/chrome-devtools-mcp#readme) for connection policies.

**Positioning (debug-only complement to Playwright):** Chrome DevTools MCP is the right tool when you need low-level observation of a running browser session — network bodies, console logs, Lighthouse audits, heap snapshots. It is NOT the default for authenticated content access. For routine auth-gated reads, use Playwright MCP's `headed → save → reuse` pattern documented in `## Authenticated workflow` below. When pairing the two, the recommended setup is a **dedicated `--user-data-dir` Chrome profile** containing only the accounts you need — not `--autoConnect`, which attaches to every open tab in your main Chrome and exposes Gmail, banking, and other active sessions to the agent. `--autoConnect` is opt-in for forks that consciously accept that surface; it should NOT appear in a default `.mcp.json` block. See `## Authenticated workflow` for the per-host state directory convention (`.claude/.browser-state/<host>.json`) that applies to both Playwright state files and Chrome profile directories.

---

### DBHub

**Source:** [github.com/bytebase/dbhub](https://github.com/bytebase/dbhub) (Bytebase)

**What it provides:** Multi-engine database introspection gateway. Supports PostgreSQL / MySQL / SQL Server / MariaDB / SQLite. Tools: `search_objects` for progressive schema exploration (tables, columns, indexes, stored procedures), `execute_sql` with transaction support and readonly-by-default safety, custom reusable queries via `dbhub.toml`. Replaces the now-archived per-engine official MCPs.

**`.mcp.json` block** (inferred — upstream README does not pin one shape; verify against [dbhub.ai/installation](https://dbhub.ai/installation) if upstream evolves):

```json
{
  "mcpServers": {
    "dbhub": {
      "command": "npx",
      "args": ["@bytebase/dbhub@latest"],
      "env": {
        "DATABASE_URL": "postgres://user:password@localhost:5432/dbname?sslmode=disable"
      }
    }
  }
}
```

**Install:** `npx @bytebase/dbhub@latest`. Docker image also available (`bytebase/dbhub`) for containerised deployments — use when the agent host can't run Node directly.

**When to enable:** any fork with a real database (Prisma / Drizzle / Alembic / Rails migrations / a `DATABASE_URL` in `.env.example`).

**Runtime requirements:** `DATABASE_URL` env var with a valid DSN. The connection string controls which engine is targeted (driver prefix). Readonly mode is the default; write-mode is opt-in via config.

**Security:** readonly default is the safety floor — keep it. Connection strings ARE secrets; do NOT commit a populated `DATABASE_URL` in `.mcp.json` to git. Use `.env` files + harness env-var injection, or set the variable in your shell before `claude` launches. See upstream's security section before enabling write mode.

---

### Next.js DevTools MCP

**Source:** [github.com/vercel/next-devtools-mcp](https://github.com/vercel/next-devtools-mcp) (Vercel, MIT)

**What it provides:** Next.js-specific framework introspection — real-time build/runtime errors, route listing, component metadata, server-action introspection, dev-server log file via `get_logs`, `browser_eval` over Playwright. The closest equivalent to zydrex's `laravel-boost` MCP in the JS/TS world.

**`.mcp.json` block:**
```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    }
  }
}
```

**Install:** `npx -y next-devtools-mcp@latest`.

**When to enable:** any Next.js fork (Next 16+ supported). Pairs naturally with Playwright for E2E.

**Runtime requirements:**
- Node.js v20.19 LTS or later.
- A running `next dev` server on the host. The MCP auto-discovers Next dev servers and connects via `/_next/mcp`. Without a running dev server, the MCP fires but most tools return empty.

**Security:** local-only (the MCP introspects the dev server, no remote endpoints). See upstream README for the dev-only positioning — do not run against production builds.

## Hint output shape

When ≥1 stack signal matches and `CLAUDE_SKIP_MCP_RECIPES` is unset, the SessionStart hook emits a single block:

```
=== mcp-recipes ===
Stack signals detected: next.config.js, package.json:next, schema.prisma
Suggested MCP recipes (copy + uncomment from .mcp.json.example):
  - next-devtools-mcp  Next.js framework introspection (build errors, routes, server actions)
  - playwright-mcp     browser observation (DOM, console, network, screenshots)
  - dbhub              multi-engine DB schema + safe query exec
See .claude/rules/mcp-recipes.md for full recipes (install commands, runtime requirements, security).
=== end mcp-recipes ===
```

When no signals match, the block is NOT emitted (silent).

## Escape hatch

- **`CLAUDE_SKIP_MCP_RECIPES=1`** — suppresses the hint block regardless of stack signals. Use in throwaway scratch sessions or when the suggestions are noise.

That's the only env var for this capacity. No `BLOCK` / `ADVISE_ON_EDIT` variants — pure recommendation has nothing to gate.

## Activation workflow

For a fork:

1. Start a session in the fork's repo. The mcp-recipes hint surfaces in additional-context if stack signals match.
2. `cp .mcp.json.example .mcp.json` (or merge into existing `.mcp.json`).
3. Open `.mcp.json` and remove `//` lines on the recipe blocks you want active.
4. For DBHub: also set `DATABASE_URL` in your shell or `.env` (never commit it).
5. For Chrome DevTools: confirm Chrome is installed (`which google-chrome` or `which chrome`).
6. Restart the Claude Code session — `.mcp.json` is loaded at session start.

## Authenticated workflow

Many sites require a logged-in session to return meaningful content. `WebFetch` hits HTTP 401, 402, 403, or 999 (LinkedIn-style anti-bot), or the page silently redirects to a login wall. This section documents the standard workflow for reading auth-gated content using Playwright MCP, the signaling convention that bridges the human login step, and the X/Twitter shortcut that avoids the full auth path for a common case.

### Prerequisites — activating Playwright MCP

The Playwright MCP recipe (spec 012) ships as `.mcp.json.example` — opt-in by design. Forks that have never enabled it will see the agent emit `BROWSER_AUTH_REQUIRED: <host>` correctly, but the suggested next step ("open Playwright MCP in headed mode") cannot run until the MCP is wired up. One-time setup per fork:

```bash
cp .mcp.json.example .mcp.json
# edit .mcp.json — remove the leading `//` markers from the `playwright` block
# (keep the other blocks commented unless you need them)
# then RESTART the Claude Code session — MCPs are loaded at session start, not hot-reloaded
```

After restart, the agent has `mcp__playwright__*` tools available and can drive the headed-login flow described below. The state files produced by `browser_storage_state` persist across sessions; activation is a one-time cost per fork.

Diagnostic: if a session shows `BROWSER_AUTH_REQUIRED` but the agent has no `mcp__playwright__*` tools listed, the prerequisite is incomplete — complete activation first, then re-issue the request in a fresh session.

### X/Twitter shortcut (try first)

Before invoking the full auth workflow for an X/Twitter URL of the form `x.com/<user>/status/<id>` or `twitter.com/<user>/status/<id>`, try the public thread-reader services first. Nitter is dead in 2026; use:

1. **Primary:** `https://unrollnow.com/status/<id>` — fetch via `WebFetch`. If the response body is non-empty and contains the thread text, the read succeeds without any auth step.
2. **Backup:** `https://threadreaderapp.com/thread/<id>.html` — same `WebFetch` approach. Use when unrollnow returns empty or an error.

Only if both fail (empty body, HTTP error, or no thread content) fall back to the `BROWSER_AUTH_REQUIRED` signal below. The shortcut covers public posts; locked accounts and DM-only content require the full workflow regardless.

### Signaling convention — `BROWSER_AUTH_REQUIRED: <host>`

When the agent encounters a URL that requires authentication and no saved state exists for that host, it emits the following phrase to the chat:

```
BROWSER_AUTH_REQUIRED: <host>
```

where `<host>` is the bare hostname (e.g. `x.com`, `linkedin.com`). The agent follows the phrase with a one-line next step pointing the human at this section and naming the exact save command. Example:

```
BROWSER_AUTH_REQUIRED: x.com
Next step: open Playwright MCP in headed mode, log in at x.com, then run
  browser_storage_state → save output to .claude/.browser-state/x.com.json
See .claude/rules/mcp-recipes.md § Authenticated workflow.
```

The phrase is all-caps with a colon-space separator — agents and humans alike can grep for it. The agent does NOT retry the same host until the human signals the state was saved (e.g. by replying "done" or by the agent detecting the state file exists on disk).

### Storage state — `.claude/.browser-state/<host>.json`

Session state is stored one file per host under `.claude/.browser-state/`. The directory ships as an empty scaffold (`.gitkeep` sentinel committed); individual state files are gitignored because they contain session cookies and localStorage — equivalent blast radius to a leaked password. Convention:

- Filename: lowercase hostname, `.json` extension. Examples: `x.com.json`, `linkedin.com.json`, `github.com.json`.
- Path: `.claude/.browser-state/<host>.json` relative to the project root.
- Never commit these files. The `.gitignore` entry `.claude/.browser-state/*.json` excludes the state files while leaving the `.gitkeep` sentinel tracked (the sentinel does not match `*.json`, so no `!`-exclusion is needed). See `.claude/rules/secrets-scan.md` for the credential-class framing.

### Playwright MCP — headed login, then headless reuse

The full auth lifecycle with Playwright MCP is three steps:

**Step 1 — headed login (human action required)**

Launch Playwright in headed mode so the human can interact with the login form. The MCP block does not need modification; headed vs headless is a per-invocation argument:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--headed"]
    }
  }
}
```

Navigate to the target site, complete the login flow in the browser window. The agent waits for the human to signal completion.

**Step 2 — save state**

Once the human is logged in, ask the agent to call the Playwright MCP tool `browser_storage_state`. Save the returned JSON to the per-host path:

```
browser_storage_state → .claude/.browser-state/<host>.json
```

(The tool name may evolve; verify against the [Playwright MCP tool reference](https://playwright.dev/mcp/tools/storage) if the command is rejected.)

**Step 3 — headless reuse**

Subsequent agent reads against the same host load the state file silently — no human interaction needed. The agent calls `browser_set_storage_state` with the file contents before navigating, or passes `--storage-state=.claude/.browser-state/<host>.json` to Playwright MCP at startup when using a persistent configuration. The page loads as authenticated.

The reuse step is silent: when `.claude/.browser-state/<host>.json` exists, the agent loads it and proceeds. `BROWSER_AUTH_REQUIRED: <host>` is NOT emitted when valid state is on disk.

### Expired-state recovery

Storage state expires when the site rotates session tokens — typically within days to weeks depending on the site. The agent recognises expiry when a navigation that previously succeeded now returns 401, 403, or redirects to a login page. On detection:

1. Delete or archive the stale state file: `rm .claude/.browser-state/<host>.json`.
2. Re-emit `BROWSER_AUTH_REQUIRED: <host>` to the chat.
3. Repeat the headed-login → save cycle.

The agent does NOT retry silently or guess at token refresh; re-authentication requires the human. This is by design — session cookies are credentials, not config.

### When to reach for Chrome DevTools MCP instead

Chrome DevTools MCP is the right choice when you need **observation**, not **driving**: watching network requests during a Playwright-driven session, capturing console logs, running Lighthouse audits, or taking heap snapshots. It is NOT the default for authenticated content reads. When you need both (drive + observe), run Playwright MCP as the driver and Chrome DevTools MCP as the observer, using a **dedicated `--user-data-dir` Chrome profile** that contains only the accounts relevant to the task. Avoid `--autoConnect` — see the positioning note in `### Chrome DevTools MCP` above.

## Gotchas

- **`.mcp.json.example` is JSON-with-comments.** Strict JSON parsers reject `//` line comments. The `.example` suffix is the universal "this is a template, do not parse directly" signal. The header comment in the file explicitly says: copy, rename, remove `//` markers before activation. Do NOT just `mv .mcp.json.example .mcp.json` — the result wouldn't parse.
- **Package-name drift.** MCP packages are early-stage (most v0.x). A package can rename or restructure across minor releases. Each recipe section links to the upstream's source-of-truth README; if your `.mcp.json` block stops working after `@latest` resolves to a newer version, **check the upstream README first**, then update the recipe block. v1 of this spec uses `@latest` throughout; forks that hit churn pain can pin manually (e.g. `@playwright/mcp@0.0.30`) — Agent0 does not maintain a version manifest.
- **Monorepo blind spot.** The stack detector scans `CLAUDE_PROJECT_DIR` at the top level only. A monorepo with `apps/web/next.config.js` and `apps/api/schema.prisma` but a bare root won't trigger the hint. Workarounds: (a) symlink the relevant config to root, (b) point `CLAUDE_PROJECT_DIR` at the workspace you're actively working in, (c) read this rule doc directly and copy the recipes you need.
- **Bring-your-own-bundler blind spot.** A fork using esbuild / rollup / parcel / swc without React / Vue / Svelte / Vite / Astro deps in `package.json` won't trigger the "browser-stack non-Next" branch. Acceptable — the recipe doc is one click away. The hint is a convenience, not a contract.
- **Chrome DevTools MCP needs Chrome installed.** Headless CI runners and minimal Linux containers usually lack it. The hint blindly suggests the recipe based on stack; if your environment can't run Chrome, ignore the suggestion and stick with Playwright (which manages its own binaries).
- **DBHub `DATABASE_URL` false-positive.** A fork with `DATABASE_URL=` only in `.env.example` for documentation purposes may not actually use a database yet. The hint will still suggest DBHub. Acceptable since the hint is *suggestion*, not auto-activation — you decide whether to copy the block.
- **`.mcp.json` is a secret-adjacent file.** DBHub's `DATABASE_URL` is the obvious case, but other MCPs may grow env-var requirements. Treat `.mcp.json` like `.env`: never commit a populated copy with credentials. Use env-var indirection (`"env": {"DATABASE_URL": "${DATABASE_URL}"}` when supported, or set the variable in your shell before launching `claude`).
- **Settings.json mutation surface.** Forks that have already customised `.claude/settings.json` may hit merge conflicts when adopting this spec via `git pull`. The diff is small (one SessionStart entry); the conflict is mechanical. Same caveat as every other hook-shipping spec.
- **Recipe security docs are NOT duplicated here.** Each MCP has its own security stance (Playwright navigation policy, Chrome CDP scope, DBHub readonly default, Next dev-only positioning). The recipe sections link to upstream; Agent0 does NOT re-summarise (those summaries would rot). A fork enabling an MCP should read the linked upstream section.
- **No new audit log.** This capacity is pure recommendation. The supply-chain / secrets / delegation / runtime-introspect capacities all write JSONL audit lines for their decisions; mcp-recipes writes nothing. If forensic analysis of "which MCPs forks have enabled" ever becomes a real need, that's a follow-up spec.
