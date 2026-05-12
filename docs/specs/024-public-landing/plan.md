# 024 — public-landing — plan

_Drafted from `spec.md` on 2026-05-12. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship a single-page landing under `site/`, built with Astro 5 + Tailwind v4 (Vite plugin), deployed to GitHub Pages via the official `withastro/action@v6`. Astro's built-in i18n handles routing (`prefixDefaultLocale: true` + `redirectToDefaultLocale: true` so `/` → `/en/`, with `/en/`, `/pt/`, `/es/` as locale roots). Content is **string-table driven**, not file-duplicated: a single `src/layouts/Landing.astro` component renders the full page from a `strings: Record<Locale, Strings>` map in `src/i18n/strings.ts`, and the per-locale entry pages are 3-line stubs that pass their locale to the layout. This keeps content drift impossible — adding a section means updating 3 keys in one file, not editing 3 page files.

Design tokens are CSS variables on `:root` (off-white background `#fafaf9`, warm-gray hierarchy `#1c1917 → #78716c`, blue-violet accent `#6366f1`, hairline border `#e7e5e4`). Typography: Inter (self-hosted via `@fontsource-variable/inter`) for prose, JetBrains Mono (`@fontsource-variable/jetbrains-mono`) for code — variable fonts, no external CDN calls. Tailwind v4 uses CSS-first `@theme` directive to bind the tokens. Layout: hero → tagline → "what you get" capacity grid (3-col on desktop, 1-col mobile) → "why it was built" prose → quick-start code block → "how to extend" prose → FAQ → footer CTA. Single `<main>` element, no client-side routing, zero JS at runtime (Astro's strength).

Deploy workflow: push to `main` triggers `.github/workflows/deploy-pages.yml`, which checks out the repo, runs `withastro/action@v6` with `path: ./site` and `package-manager: bun@latest`, uploads the artifact, then `actions/deploy-pages@v5` publishes it. The `base: '/Agent0/'` setting in `astro.config.mjs` ensures all internal links resolve correctly under the project Pages URL.

## Files to touch

**Create:**

- `site/package.json` — Astro 5, Tailwind v4 Vite plugin, `@fontsource-variable/{inter,jetbrains-mono}`, dev/build/preview scripts.
- `site/astro.config.mjs` — `site`, `base`, `i18n` config (en/pt/es), `vite.plugins: [tailwind()]`.
- `site/tsconfig.json` — strict TS for `.astro` + i18n type-safety.
- `site/src/styles/global.css` — Tailwind v4 `@import "tailwindcss"`, `@theme` block with design tokens, base resets.
- `site/src/i18n/strings.ts` — `Strings` type + `strings: Record<Locale, Strings>` content table (hero, why, capacities, quickstart, extend, faq, footer).
- `site/src/i18n/capacities.ts` — capacity catalog (name, slug for rule doc link, one-line desc per locale).
- `site/src/layouts/Landing.astro` — full page layout, takes `locale` prop, reads strings, renders all sections.
- `site/src/components/Hero.astro`, `CapacityGrid.astro`, `LanguageSwitcher.astro`, `Footer.astro`, `CodeBlock.astro` — section components.
- `site/src/pages/index.astro` — unlocalized stub; with `redirectToDefaultLocale: true` Astro generates the `/` → `/en/` redirect, but a meta-refresh fallback page is still served on static hosts (GH Pages serves static, not redirects via HTTP). Use `Astro.redirect('/Agent0/en/')` server-rendered to meta-refresh.
- `site/src/pages/en/index.astro`, `pt/index.astro`, `es/index.astro` — 3-line stubs: `import Landing from '../../layouts/Landing.astro'; <Landing locale="en|pt|es" />`.
- `site/public/favicon.svg` — minimal monogram (lower-case `a0` glyph, accent color).
- `site/.gitignore` — `dist/`, `node_modules/`, `.astro/`.
- `.github/workflows/deploy-pages.yml` — workflow as in research; `path: ./site`, `package-manager: bun@latest`.

**Modify:**

- `README.md` — add a top-of-file "✨ [agent0.dev landing](https://cfpperche.github.io/Agent0/)" link (one line).
- `docs/specs/024-public-landing/tasks.md` — work through it during implementation.

**Delete:**

- None.

## Alternatives considered

### Next.js static export

Rejected because: heavier toolchain for a single-page landing; ceremony around `output: 'export'` and route handlers when we have zero dynamic content; Tailwind setup is identical so no advantage there; Astro ships less runtime JS by default which matters for a marketing landing's LCP. Astro's i18n is also more idiomatic for static prefix-locale routing than next-intl's middleware approach (the latter only fully works on server runtimes).

### Docusaurus

Rejected because: it's a docs portal with built-in sidebar/TOC/versioning — bending it into a custom hero+grid landing requires fighting the theme. Crowdin-style translations are heavier than our 3-locale string-table need. We'd ship a 200KB+ React runtime for a page that needs zero interactivity beyond a language switcher (a plain `<a>`).

### VitePress

Rejected because: Vue-locked; the i18n DX is good but customization story is locked into VitePress's theme inheritance pattern. Astro's component model is framework-agnostic — if we ever need a React widget on the page we can drop one in via island hydration without reinstalling the stack.

### Plain HTML + CSS

Rejected because: i18n by hand (3 separate HTML files) means content drift is guaranteed within weeks. Tailwind alone needs a build step anyway. The marginal cost of Astro on top of a build step is near-zero.

### Tailwind v3 + `@astrojs/tailwind`

Considered as **fallback** rather than rejected: if the Tailwind v4 Vite plugin hits friction during scaffold (it's relatively new), drop to v3.4 with the official Astro integration. Functionally equivalent for a landing; we lose the CSS-first `@theme` ergonomic but keep all utility classes. Spec criteria don't pin v4 — plan adopts v4 first, falls back without spec amendment.

## Risks and unknowns

- **Tailwind v4 with Astro friction.** Tailwind v4's Vite plugin is current default, but the Astro integration story is fresher than v3+`@astrojs/tailwind`. If `bun run build` errors during scaffold, drop to v3.4 + the official Astro integration. Documented in alternatives; no spec amendment needed.
- **`bun` in GH Action.** `withastro/action@v6` accepts `package-manager: bun@latest`. Locally we use bun; if the action's bun version differs we may see lockfile mismatches. Mitigation: commit `bun.lock` and let the action use it. Fallback: switch the action to `npm` if bun churn surfaces (lockfile is regenerated from `package.json`).
- **GH Pages static-host redirect semantics.** A real HTTP redirect from `/Agent0/` to `/Agent0/en/` requires server-side. On static hosting, Astro emits a meta-refresh + JS fallback HTML at `/Agent0/index.html` when `redirectToDefaultLocale: true`. Crawlers honor meta-refresh well enough for a marketing page; we're not optimizing for legacy clients.
- **`base: '/Agent0/'` everywhere.** Easy to forget on a `<a href="/some-page">` and produce broken local-relative links. Mitigation: use Astro's `getRelativeLocaleUrl()` and `import.meta.env.BASE_URL` exclusively; never hardcode `/`-prefixed paths.
- **Trilingual content quality.** Native pt-BR (the user) and English are fine; Spanish content is machine-grade unless reviewed. The user can flag any awkward phrasing post-deploy; we ship clean professional Spanish in v1 (no slang, no overly clever idioms).
- **Capacity catalog drift.** The catalog is hand-encoded in `capacities.ts` for v1. When Agent0 ships spec 024+ this needs a manual update. Acceptable; if drift becomes a real cost, follow-up spec auto-generates from `.claude/rules/*.md` frontmatter.
- **No image/screenshot assets in v1.** Pure typography + code-block aesthetic. Adds risk of looking sparse. Mitigation: rich typographic hierarchy + careful spacing + one small monogram favicon carries weight in the editorial style.

## Research / citations

- [Astro i18n routing](https://docs.astro.build/en/guides/internationalization/) — `prefixDefaultLocale`, `redirectToDefaultLocale`, `getRelativeLocaleUrl`, `getAbsoluteLocaleUrl`, `Astro.currentLocale`.
- [Astro GitHub Pages deploy guide](https://docs.astro.build/en/guides/deploy/github/) — workflow YAML, `withastro/action@v6`, `actions/deploy-pages@v5`, `site` + `base` config.
- [Tailwind v4 with Astro](https://tailwindcss.com/docs/installation/framework-guides/astro) — Vite plugin, CSS-first `@theme` directive.
- [Linear](https://linear.app), [Vercel](https://vercel.com), [Resend](https://resend.com) — visual references.
- [Inter variable font](https://github.com/rsms/inter) via `@fontsource-variable/inter`; [JetBrains Mono](https://www.jetbrains.com/lp/mono/) via `@fontsource-variable/jetbrains-mono`.
- Agent0 `README.md` + `.claude/rules/*.md` — source-of-truth for capacity catalog content.
