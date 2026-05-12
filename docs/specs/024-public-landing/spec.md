# 024 — public-landing

_Created 2026-05-12. Status: draft._

## Intent

Agent0 is a public open-source harness for Claude Code with 23 shipped specs and 10+ capacities, but it has zero public-facing presence beyond the GitHub repo's README. Newcomers landing on the repo have to read a 10 KB README + drill into 23 spec dirs + 17 rule files to understand what Agent0 is, why it exists, and how to use it. This spec ships a public landing page at `https://cfpperche.github.io/Agent0/` — multilingual (en/pt/es), light editorial design, built with Astro 5 + Tailwind v4, deployed via GitHub Actions to GitHub Pages. The page presents Agent0 to the world: what it is, why it was built (the spec-driven + capacity-extension philosophy), how to start using it in your own projects (the per-fork checklist condensed), how to extend its capacities (the SDD workflow), and the full capacity catalog. The site itself ships as a new `site/` subtree in the repo, independent of Agent0's harness (it does not consume Agent0's hooks or validators — it is a sibling artifact for marketing/onboarding, not part of the harness).

## Acceptance criteria

- [ ] **Scenario: site builds locally**
  - **Given** the `site/` directory is scaffolded with Astro 5 + Tailwind v4 + i18n config (en/pt/es)
  - **When** the developer runs `bun install && bun run build` from `site/`
  - **Then** the build succeeds with exit 0 and produces `site/dist/` containing `en/index.html`, `pt/index.html`, `es/index.html`

- [ ] **Scenario: three locales render full content**
  - **Given** the built site is served locally (`bun run preview` or static server on `site/dist/`)
  - **When** the user navigates to `/en/`, `/pt/`, and `/es/` paths
  - **Then** each locale renders the full page (hero, why-built, capacity catalog, quick start, how-to-extend, FAQ, CTA) in the corresponding language, with no untranslated placeholder strings

- [ ] **Scenario: language switcher works**
  - **Given** the user is on `/en/`
  - **When** they click the language switcher and select Português
  - **Then** they navigate to `/pt/` with the equivalent content rendered

- [ ] **Scenario: GitHub Pages deploy succeeds**
  - **Given** the workflow `.github/workflows/deploy-pages.yml` is committed to `main`
  - **When** a push to `main` triggers the workflow
  - **Then** the site deploys successfully to `https://cfpperche.github.io/Agent0/` and the root URL redirects to the default locale `/en/`

- [ ] **Scenario: capacity catalog reflects current state**
  - **Given** Agent0 has 14+ documented capacities (compaction continuity, SDD, governance gate, delegation+post-edit validator, reminders, BDD, TDD, secrets scan, supply chain scan, runtime introspect, MCP recipes, harness sync, lint validator, memory, browser auth, session handoff)
  - **When** the user lands on the page
  - **Then** the capacity grid lists each capacity with name + one-line description + link to its rule doc on GitHub

- [ ] **Scenario: design language matches reference**
  - **Given** the editorial / Vercel-Resend visual direction was chosen
  - **When** the user views any locale
  - **Then** the page uses Inter (or system-ui fallback) for prose, JetBrains Mono (or fallback) for code, off-white background, warm gray hierarchy, hairline borders, and a single accent color (blue-violet family); no dark theme in v1

- [ ] **Scenario: page is responsive at 375px**
  - **Given** the built site
  - **When** viewed at 375px viewport width
  - **Then** all sections reflow without horizontal overflow; the language switcher remains accessible; the hero CTA is tappable (≥44px)

- [ ] `site/` is git-tracked and committed alongside the spec
- [ ] `site/package.json` declares Astro 5.x + Tailwind v4 (Vite plugin) + dev/build scripts
- [ ] `.github/workflows/deploy-pages.yml` exists with GitHub Pages permissions and uses Astro's official `withastro/action` (or equivalent)
- [ ] Astro config sets `base: '/Agent0/'` and `site: 'https://cfpperche.github.io'`
- [ ] `<html lang="...">` is set per-locale; `<link rel="alternate" hreflang="...">` tags link the three locales together
- [ ] All site source code stays in English (per `.claude/rules/language.md`) — only the rendered content has pt/es localizations

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
