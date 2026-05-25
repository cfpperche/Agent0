# 024 — public-landing

_Created 2026-05-12._

**Status:** shipped

## Intent

Agent0 is a public open-source harness for Claude Code with 23 shipped specs and 10+ capacities, but it has zero public-facing presence beyond the GitHub repo's README. Newcomers landing on the repo have to read a 10 KB README + drill into 23 spec dirs + 17 rule files to understand what Agent0 is, why it exists, and how to use it. This spec ships a public landing page at `https://cfpperche.github.io/Agent0/` — multilingual (en/pt/es), light editorial design, built with Astro 5 + Tailwind v4, deployed via GitHub Actions to GitHub Pages. The page presents Agent0 to the world: what it is, why it was built (the spec-driven + capacity-extension philosophy), how to start using it in your own projects (the per-fork checklist condensed), how to extend its capacities (the SDD workflow), and the full capacity catalog. The site itself ships as a new `site/` subtree in the repo, independent of Agent0's harness (it does not consume Agent0's hooks or validators — it is a sibling artifact for marketing/onboarding, not part of the harness).

## Acceptance criteria

- [x] **Scenario: site builds locally** — `bun run build` from `site/` exits 0 in ~640 ms, emits `dist/en/index.html`, `dist/pt/index.html`, `dist/es/index.html`, plus a meta-refresh `dist/index.html`. Verified `2026-05-12`.

- [x] **Scenario: three locales render full content** — Local preview + live URL both serve full sections per locale. Live titles: `Agent0 — the harness for AI coding agents` / `Agent0 — o harness para agentes de código IA` / `Agent0 — el harness para agentes de código IA`.

- [x] **Scenario: language switcher works** — `LanguageSwitcher` renders `/Agent0/{en,pt,es}/` anchors with `aria-current="page"` on the active locale; verified via DOM snapshot at the three live URLs.

- [x] **Scenario: GitHub Pages deploy succeeds** — Workflow run `25753105230` PASS (build 12 s + deploy 11 s). `https://cfpperche.github.io/Agent0/` returns 200 with Astro's meta-refresh to `/Agent0/en/`. Pages source = `workflow` (set via `gh api -X POST repos/cfpperche/Agent0/pages -f build_type=workflow`).

- [x] **Scenario: capacity catalog reflects current state** — `site/src/i18n/capacities.ts` lists 16 capacities (SDD, governance, delegation, reminders, BDD, TDD, secrets-scan, supply-chain, runtime-introspect, mcp-recipes, lint-validator, harness-sync, session-handoff, compaction-continuity, memory, browser-auth) with per-locale descriptions and GitHub blob links to `.claude/rules/` or `docs/specs/`.

- [x] **Scenario: design language matches reference** — Inter Variable (self-hosted via `@fontsource-variable/inter`) for prose, JetBrains Mono Variable for code, `--color-bg: #fafaf9`, `--color-ink: #1c1917 → #78716c` hierarchy, `--color-line: #e7e5e4` hairlines, `--color-accent: #6366f1` single accent. No dark theme.

- [x] **Scenario: page is responsive at 375px** — `docW=360, winW=375` after `min-w-0` fixes in `QuickStart` + `HowToExtend` grids and `overflow-x-clip` on body. Primary CTA bounding rect 134×44 px.

- [x] `site/` is git-tracked and committed alongside the spec (commit `34d2bf1`)
- [x] `site/package.json` declares Astro 5.18 + Tailwind v4 (Vite plugin) + dev/build/preview scripts
- [x] `.github/workflows/deploy-pages.yml` exists, uses `withastro/action@v3` + `actions/deploy-pages@v4`
- [x] Astro config sets `base: '/Agent0/'` and `site: 'https://cfpperche.github.io'`
- [x] `<html lang="...">` is set per-locale; `<link rel="alternate" hreflang="...">` tags link en/pt/es + `x-default → en`
- [x] All site source code stays in English (per `.claude/rules/language.md`) — only rendered content has pt/es localizations

## Non-goals

- Dark theme — light only in v1; add later if community demand surfaces.
- Search / full docs site — the landing is a single-page introduction with CTAs to GitHub. The actual docs live in the repo (CLAUDE.md, rule docs, spec dirs).
- Blog / changelog page — `git log` and the spec catalog are the changelog.
- Custom domain (e.g. agent0.dev) — `cfpperche.github.io/Agent0` is the v1 URL; custom domain is a follow-up.
- Analytics / tracking pixels — privacy-respecting OSS site, no GA / Plausible / Fathom in v1.
- Auto-updating capacity catalog from `.claude/rules/*.md` — v1 has the catalog as static content in the page source. Auto-generation is a follow-up if the catalog drifts often.
- Interactive demos / playgrounds — the landing links to the GitHub repo for hands-on; no in-page agent-replay or terminal-emulator.
- More than 3 locales — adding fr/de/etc. is a future spec.
- Hosting the rule docs themselves — links go to the GitHub blob view; no MDX docs portal.

## Open questions

- [x] **SSG choice** — resolved: Astro 5 + Tailwind v4 (user confirmed via AskUserQuestion).
- [x] **Design direction** — resolved: editorial / Vercel-Resend (user confirmed).
- [x] **GH Pages target** — resolved: project Pages at `cfpperche.github.io/Agent0/` with `base: '/Agent0/'`.
- [x] **Language fallback order** — `en` is the default; root `/` redirects to `/en/`.
- [x] **Tailwind version** — Tailwind v4 (Vite plugin). If toolchain friction surfaces during scaffold, fall back to v3.4 with `@astrojs/tailwind` (no spec change needed).

## Context / references

- [Astro i18n docs](https://docs.astro.build/en/guides/internationalization/)
- [Astro GitHub Pages deploy guide](https://docs.astro.build/en/guides/deploy/github/)
- [withastro/action — official deploy action](https://github.com/withastro/action)
- [Tailwind v4 with Astro](https://tailwindcss.com/docs/installation/framework-guides/astro)
- [Linear](https://linear.app), [Vercel](https://vercel.com), [Resend](https://resend.com) — design references
- Agent0 README (`README.md`) and CLAUDE.md — source-of-truth for capacity catalog content
