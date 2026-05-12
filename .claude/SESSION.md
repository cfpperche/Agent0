# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 024 (public-landing) DELIVERED + LIVE 2026-05-12.** New `site/` subtree (Astro 5.18 + Tailwind v4 + i18n en/pt/es, editorial Vercel-Resend design). Deploy via `.github/workflows/deploy-pages.yml` (withastro/action@v3 + actions/deploy-pages@v4, `path: ./site`, bun pkg manager). Workflow run `25753105230` PASS (build 12s + deploy 11s). Pages source set to `workflow` via `gh api -X POST .../pages -f build_type=workflow`. Live URL serves 200: **https://cfpperche.github.io/Agent0/** redirects to `/en/`, all 3 locales return correct titles. Mobile 375px verified `docW=360 ≤ winW=375` after `min-w-0` fixes in grid items + `overflow-x-clip` on body. Capacity catalog covers 16 capacities with links to `.claude/rules/` / spec dirs. README updated with top-of-file landing link. Commit `34d2bf1`. Tasks 1-15 all PASS; acceptance criteria 1-7 all PASS.

**Spec 015 (monorepo-stack-detect) delivered + dogfood graduated 2026-05-12.** Stack-detector hook walks depth-1 into common monorepo workspace dirs (default `apps packages services workspaces`); override via `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS`. 15/15 tests green + 2 real-world dogfoods (workout, shrnk-mono).

**shrnk-mono first-feature dogfood graduated 2026-05-12.** Real CC session in `/home/goat/shrnk-mono/` (commit `52d0eff`) shipped `apps/api` GET /health endpoint via Elysia + bun:test, exercising 6 capacities end-to-end with full JSONL/audit-log evidence: spec 015 hint (7 signals + 4 recipes), spec 009 supply-chain block→block-override cycle (`bun add elysia`, two-line `# OVERRIDE` marker), spec 011 runtime introspect (`probe.sh` returned `status: PASS, inferred_status: PASS, inference_basis: 'bun-test: 0 fail line'`), spec 007 secrets-scan dual-layer (preflight `passthrough` + native `allow` on 5 staged files), spec 023 Stop hook discrimination (block 1× when SESSION.md missing, clean-pass after), spec 001 governance gate (prevented `git add -A` blanket staging). TDD red→green observed (1 fail → 1 pass). Agent caught `bun install` (no args) ≠ mutation gotcha empirically — asked user via AskUserQuestion before workaround. Audit log volume confirmed: 28 rows in 1h (26 `skip-not-commit`, expected noise).

**Spec 023 (session-stop-noop-aware) delivered 2026-05-12.** Stop hook snapshots `git status --porcelain` at SessionStart and exits 0 silently when end-of-session porcelain is byte-identical. Commit `d696135`.

Prior context: spec 013 dogfood closed 7/7; specs 022/020/011 B-series complete; spec 021 delivered + 2 dogfoods; spec 019 scaffold in all forks; Parallel WIP convention registered.

## WIP

Nothing in flight. Spec 024 closed: live at `https://cfpperche.github.io/Agent0/`.

## Next steps

1. **Spec 014 (mcp-recipes-extras)** — sibling to 015. 4 new recipes (OpenTelemetry, Grafana, Filesystem, Git). Inherits `detect_at` refactor; shrnk-mono is the ready dogfood target.
3. **shrnk-mono as recurring dogfood target.** Full-matrix synthetic fork at `/home/goat/shrnk-mono/`. Reuse for spec 014 + future monorepo capacity tests.
4. **Spec 0YY runtime-introspect-extra-detect-injection (deferred).** Revisit when undetected stack appears.
5. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption vs "no frameworks" rule conflict.

## Decisions & gotchas

- **Spec 024 design: Astro 5 i18n vs Docusaurus/VitePress.** Astro wins for landing — i18n native (`prefixDefaultLocale: true` + `redirectToDefaultLocale: true` → `/` redirects to `/en/`), zero-JS by default, official `withastro/action`, full design flexibility (Docusaurus would lock into doc-sidebar layout, VitePress is Vue-only). Tailwind v4 via `@tailwindcss/vite` plugin (CSS-first `@theme` directive for tokens). Strings/capacities are TS modules keyed by locale, NOT 3 duplicated page files — single `Landing.astro` layout renders from `Record<Locale, Strings>`.
- **Spec 024 CSS layer gotcha — unlayered rules beat all layered utilities (Tailwind v4).** First mobile pass showed the primary CTA button as black-on-black (text invisible). Computed style: `color: var(--color-ink)` (inherited from body) overriding `text-[var(--color-bg)]` utility. Root cause: my custom `a { color: inherit }` rule in `site/src/styles/global.css` was UNLAYERED and the CSS layer cascade puts unlayered styles ABOVE any named layer regardless of specificity. Fix: wrap the entire global.css base styling in `@layer base { ... }`. Lesson for future Tailwind v4 projects: any `body/a/html/etc.` custom base rule MUST live inside `@layer base` or it silently overrides utilities.
- **Spec 024 grid+code overflow gotcha — `min-w-0` on grid items.** A CSS grid with `1fr` columns has children with implicit `min-width: auto` (= fit content), so a `<pre>` inside a `1fr` column expands the grid past viewport even though the `<pre>` has `overflow-x-auto`. Fix: explicit `min-w-0` on the grid item that wraps the code block. Applied in `QuickStart.astro` and `HowToExtend.astro`. Also added `overflow-x-clip` on `<body>` as belt-and-suspenders — `clip` instead of `hidden` preserves `position: sticky` on the header.
- **Spec 024 supply-chain block fired on `bun install` as expected.** Used inline OVERRIDE marker on its own line: `# OVERRIDE: introducing Astro+Tailwind+font deps for new site/ subtree per spec 024 public-landing`. Audited as `block-override`.
- **Spec 015 design: per-workspace `local_have_next` not global.** The browser-non-Next branch's "skip if Next" check must be local to each `detect_at` call, not global.
- **Cargo PASS heuristic: `Finished` line, NOT 500-char cap.** Cargo output frequently exceeds 500 chars.
- **Spec 023 design: porcelain snapshot beats mtime walk.** Discriminates "this session changed something" via `git status --porcelain` snapshot at SessionStart vs Stop.
- **`browser_storage_state` / `browser_set_storage_state` do NOT exist in `@playwright/mcp@latest`** (spec 021). Save path: `browser_run_code_unsafe` + `page.context().storageState({ path })`.
- **`core.hooksPath` activation remains MANUAL by design** (Lazarus 2025).
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is the audit trail.
