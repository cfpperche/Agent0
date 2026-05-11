# 012 — mcp-recipes — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Pure-recommendation capacity in the same grain as the existing capacities: rule doc + example file + SessionStart hook + settings wiring + CLAUDE.md block. No blocks, no audits, no auto-installs. Three artifacts do the real work:

1. **`.claude/rules/mcp-recipes.md`** — the authoritative doc. Four sections (Playwright, Chrome DevTools, DBHub, Next.js DevTools), each with: official source link, what runtime introspection it provides, the verbatim `.mcp.json` block to paste, install command (`npx -y` / `bunx` shape), when-to-enable signals, security notes link (to the upstream's own docs — not duplicated here).
2. **`.mcp.json.example` at repo root** — copy-paste-ready file. Header comment explains the workflow (`cp .mcp.json.example .mcp.json` then uncomment desired blocks). JSON-with-line-comments at the top, with each MCP's block guarded by `//` markers; standard editors strip them or the developer deletes manually before parsing.
3. **`.claude/hooks/mcp-recipes-hint.sh`** — SessionStart helper. Detects stack signals from a tiny fixed list (top-level files + `package.json` dependency keys, no recursive walks), emits a single combined hint block listing applicable recipes. Silent when no signals match (Agent0 base case) and when `CLAUDE_SKIP_MCP_RECIPES=1`. Co-exists with the runtime-introspect SessionStart hint — both blocks are independent.

Build order: rule doc draft → `.mcp.json.example` → RED test suite → hook → settings wiring → CLAUDE.md → live verification by simulating each detection scenario via temp dirs (no real fork dogfood needed since v1 is purely a recommendation surface — there's no "did the MCP install" to verify; we verify the *recommendation*).

## Files to touch

**Create:**

- `.claude/rules/mcp-recipes.md` — capacity doc with four MCP sections + workflow notes + gotchas (Chrome binary requirement, DATABASE_URL setup, package-name drift, monorepo caveat).
- `.mcp.json.example` — repo-root JSON-with-comments file. Header explains copy-and-uncomment.
- `.claude/hooks/mcp-recipes-hint.sh` — SessionStart helper. Reads `CLAUDE_PROJECT_DIR`, runs stack signals, emits the hint block when ≥1 matches.
- `.claude/tests/mcp-recipes/run-all.sh` — driver (mirrors supply-chain / runtime-introspect shape).
- `.claude/tests/mcp-recipes/01-next-detection.sh` — RED: fixture with `next.config.js` OR `next` in deps → hint contains `next-devtools` AND `playwright`.
- `.claude/tests/mcp-recipes/02-browser-non-next.sh` — RED: fixture with `react`/`vue`/`svelte`/`vite`/`astro` (any), no `next` → hint contains `playwright` AND `chrome-devtools`.
- `.claude/tests/mcp-recipes/03-db-detection.sh` — RED: fixture with `schema.prisma` OR `drizzle.config.ts` OR `DATABASE_URL` in `.env.example` → hint contains `dbhub`.
- `.claude/tests/mcp-recipes/04-silent-no-signals.sh` — RED: fixture with only markdown files (Agent0 base shape) → hint block NOT emitted.
- `.claude/tests/mcp-recipes/05-co-exists-with-011.sh` — RED: fixture with both runtime-introspect probe present AND stack signals → SessionStart output contains BOTH hint blocks.
- `.claude/tests/mcp-recipes/06-opt-out-env.sh` — RED: `CLAUDE_SKIP_MCP_RECIPES=1` + matching stack → hint NOT emitted.

**Modify:**

- `.claude/settings.json` — register `mcp-recipes-hint.sh` on `SessionStart` (alongside existing `session-start.sh` and `reminders-readout.sh`).
- `CLAUDE.md` — new § Mcp recipes block after the Runtime introspect block. One paragraph + link to the rule doc.

**Delete:** none.

## Alternatives considered

### Auto-generate `.mcp.json` from stack detection

Rejected. Forks would clone Agent0 and find a populated `.mcp.json` they didn't write, potentially installing MCPs they didn't consent to. Same Lazarus-vector reasoning as `core.hooksPath` manual activation (`.claude/rules/secrets-scan.md` § Gotchas): the per-fork developer must do one conscious step. Recipes recommend; the developer activates. The cost is one `cp` + uncomment; the benefit is no surprise auto-installation.

### One SessionStart block per suggested recipe

Rejected. SessionStart context budget is shared with SESSION.md, COMPACT_NOTES, runtime-introspect hint, reminders — emitting 2-3 separate framed blocks for "playwright is suggested" / "next-devtools is suggested" doubles noise without adding signal. A single combined block listing applicable recipes is denser and more scannable.

### Parse `package.json` transitive dependencies via lockfile

Rejected. Different package managers (npm/pnpm/yarn/bun) have different lockfile formats; transitive deps are also a poor signal (a transitive `react` doesn't mean the fork does React work). Top-level `dependencies` + `devDependencies` keys in `package.json` are accurate enough for recommendation purposes; lockfile walking adds complexity and runtime cost (some lockfiles are MB-scale) without proportional accuracy gain.

### Ship `.mcp.json` directly (no `.example` suffix)

Rejected. Forks would inherit ALL 4 MCPs on clone, including Chrome DevTools (needs Chrome binary) and DBHub (needs DATABASE_URL). The `.example` suffix is the universal "this is a template, copy and edit" signal — same shape as `.env.example` everywhere.

### Detect from running processes (`ps` / `lsof`)

Rejected. Dev server might not be running at SessionStart. File-existence (the package.json, next.config.js, schema.prisma) is stable across "fork is at rest" and "fork is mid-dev". Process detection might add value as a v2 enrichment, but v1 file-only is sufficient.

### Bundle a curated MCP-version manifest

Rejected for v1. The recipes link to upstream package names; the example file uses `@latest`. A manifest like `recipes.lock.json` pinning each MCP to a known-good version would help with churn, but maintaining it across MCP releases is its own burden — open question 4 in spec.md proposes documentation-only with a "pin manually if churn hurts" gotcha, which mirrors the cargo-flag-allowlist evolution: ship narrow, extend on real-world signal.

## Risks and unknowns

- **MCP package names / install commands drift.** A v0.x package can rename or reshape its stdio invocation across minor releases. The recipe doc links to each upstream's README/install page for the source of truth; the gotcha explicitly tells forks to verify before committing the recipe. Risk is real but low-cost (one paragraph drift in our recipe doc, caught on next fork's first use).
- **Stack-detector false-positive on monorepos.** A fork like `apps/web` + `apps/api` + `apps/docs` may have `next.config.js` in `apps/web/` but the agent's `CLAUDE_PROJECT_DIR` is the monorepo root. The detector won't fire. Mitigation: v1 scans top-level only; gotcha tells monorepo forks to symlink or set `CLAUDE_PROJECT_DIR` to the relevant workspace. v2 could walk a configurable depth.
- **Stack-detector false-negative on bring-your-own-bundler.** A project using esbuild/rollup/parcel/swc without React/Vue/Svelte/Vite/Astro deps won't trigger the browser-stack branch. Acceptable — the recipe doc is one click away. The hint is a convenience, not a contract.
- **Chrome DevTools MCP needs Chrome installed.** Not all dev machines have it (especially headless CI). Recipe must surface the requirement in the **when-to-enable** section, not buried at the bottom.
- **DBHub needs `DATABASE_URL`.** Recipe must surface the env-var template AND the readonly-mode-default note. False-positive risk: a fork with `DATABASE_URL` in `.env.example` for documentation purposes might not actually run DBHub yet. Acceptable since the hint is *suggestion*, not auto-activation.
- **`.mcp.json.example` is JSON-with-comments.** Strict JSON parsers reject `//` line comments. Mitigation: the `.example` suffix is the universal escape hatch ("don't parse this directly"). The header comment explicitly says: copy, rename, remove `//` lines before activation.
- **`settings.json` mutation surface.** Forks that have already customised `settings.json` may hit merge conflicts when adopting this spec via `git pull`. Mitigation: same as every other hook-shipping spec — diff is small, conflict is mechanical, document the addition's location in the array.
- **Sandbox / capability scope per MCP.** Each external MCP has its own security posture (Playwright can navigate anywhere; DBHub defaults to readonly; Chrome DevTools needs CDP access). The rule doc points to upstream security docs; Agent0 does NOT re-summarise (those summaries would rot). Risk: a fork enables an MCP without reading the upstream's security section. Documented warning, not an actionable gate.

## Research / citations

- `.claude/rules/runtime-introspect.md` — sibling capacity; the SessionStart hint shape and stack-aware-without-blocking pattern are inherited. Also explicitly defers the four MCPs in scope to "future `.mcp.json.example` follow-up" — this is that follow-up.
- `.claude/rules/supply-chain.md` § Gotchas — Agent0's general lesson that strict allowlists + env-var extension beat generous heuristics, applied here as "ship recipes only for the 4 mature MCPs in v1".
- [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp) — Microsoft, 32k★, browser observation MCP. Tools: navigation, DOM, console, network, screenshots, trace recording. Cross-browser (Chromium / Firefox / WebKit).
- [Chrome DevTools MCP](https://developer.chrome.com/blog/chrome-devtools-mcp) + [github.com/ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) — Google, public preview Sept 2025. Tools: network inspect, console logs, Lighthouse audits, V8 heap snapshots, Core Web Vitals. Debugging-oriented (driving an existing session) versus Playwright's automation focus.
- [bytebase/dbhub](https://github.com/bytebase/dbhub) — multi-engine DB MCP gateway. Postgres / MySQL / SQLite / MSSQL / MariaDB. Tools: schema introspection (`search_objects`), safe SQL execution, custom queries via `dbhub.toml`. Readonly mode by default.
- [vercel/next-devtools-mcp](https://github.com/vercel/next-devtools-mcp) — Vercel-backed, MIT, v0.3.10 Jan 2026. Tools: build/runtime errors, route listing, server-action introspection, `get_logs` against the dev log file, `browser_eval` via Playwright.
- [MCP protocol overview](https://modelcontextprotocol.io/) — `.mcp.json` per-project convention, stdio + HTTP transports.
- Spec 011 (runtime-introspect) `docs/specs/011-runtime-introspect/` — for the SessionStart hint pattern, stack-detection conventions, and the build-vs-adopt rationale.
- Memory: `~/.claude/projects/-home-goat-Agent0/memory/project_visibility_intent.md` — frames why this complements 011 instead of duplicating it.
