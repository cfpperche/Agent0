# 024 — public-landing — tasks

_Generated from `plan.md` on 2026-05-12. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Scaffold `site/` directory with `package.json`, `astro.config.mjs`, `tsconfig.json`, `.gitignore`.
- [x] 2. Install Astro 5 + Tailwind v4 + fontsource packages via `bun install` (with supply-chain `# OVERRIDE` marker — this is a deliberate new-dep introduction).
- [x] 3. Configure i18n in `astro.config.mjs` (locales=[en,pt,es], defaultLocale=en, prefixDefaultLocale=true, redirectToDefaultLocale=true) + `site`+`base` for GH Pages.
- [x] 4. Create `src/styles/global.css` with Tailwind v4 import + `@theme` design tokens (off-white bg, warm grays, blue-violet accent, Inter/JBMono fonts).
- [x] 5. Author `src/i18n/strings.ts` — Strings type + `strings: Record<Locale, Strings>` with all section copy (hero, why, capacities-intro, quickstart, extend, faq, footer) in en/pt/es.
- [x] 6. Author `src/i18n/capacities.ts` — full capacity catalog (15+ capacities) with name, rule-doc link, per-locale description.
- [x] 7. Build `src/components/{Hero,CapacityGrid,LanguageSwitcher,Footer,CodeBlock}.astro` — section components, all locale-driven via props.
- [x] 8. Build `src/layouts/Landing.astro` — full page layout, takes `locale` prop, renders all sections with `<html lang>` + hreflang `<link>` tags.
- [x] 9. Create per-locale page stubs `src/pages/en/index.astro`, `pt/index.astro`, `es/index.astro` and root `src/pages/index.astro` redirect.
- [x] 10. Add `public/favicon.svg` — minimal `a0` monogram in accent color.
- [x] 11. Run `bun run build` from `site/`, confirm zero errors, inspect `dist/` for `en/index.html`, `pt/index.html`, `es/index.html`.
- [x] 12. Add `.github/workflows/deploy-pages.yml` with `withastro/action@v6` + `path: ./site` + `package-manager: bun@latest`.
- [x] 13. Add top-of-file landing link to `README.md`.
- [x] 14. Commit everything in one logical commit (spec + plan + tasks + site/ + workflow + README link).
- [x] 15. Push to `main` (with user's explicit ok) and verify the workflow run succeeds + the page renders at `https://cfpperche.github.io/Agent0/`.

## Verification

- [x] **A.C. scenario 1** — `bun run build` exits 0 and produces dist with all 3 locale index.html files (task 11 satisfies).
- [x] **A.C. scenario 2** — `bun run preview` (or static-serve `dist/`) and load `/en/`, `/pt/`, `/es/` in browser; all sections render in matching language with no `{{TODO}}` markers (Playwright MCP verification, task 11 follow-up).
- [x] **A.C. scenario 3** — Click language switcher on `/en/` → navigates to `/pt/`, content changes accordingly.
- [x] **A.C. scenario 4** — GH Action run succeeds (task 15); page is live at the project Pages URL.
- [x] **A.C. scenario 5** — Capacity catalog matches Agent0's current state (15+ capacities, links resolve to GitHub blob URLs).
- [x] **A.C. scenario 6** — Visual inspection: Inter font in prose, JBMono in code blocks, off-white bg, warm grays, blue-violet accent, hairline borders.
- [x] **A.C. scenario 7** — Resize browser to 375px width via Playwright; verify no horizontal overflow, language switcher accessible, CTAs ≥44px.

## Notes

- Supply-chain block fires on the `bun install` step (task 2). Use `# OVERRIDE: introducing Astro/Tailwind/font deps for new site/ subtree per spec 024` on the line above the install command. Decision will be audited as `block-override` in `.claude/supply-chain-audit.jsonl`.
- The Edit/Write supply-chain advisory may also fire on `site/package.json` writes; that's expected and informational.
- Lint validator: the site is its own subtree; if it grows we may want a Biome config there, but for v1 zero lint config in `site/` keeps the validator silent on the new files (no `@biomejs/biome` declared in `site/package.json` → state c = silent skip).
- Tests: this spec has no test-driven shape — it's a static site whose acceptance is visual + build-exit + deploy-success. The TDD advisory should not fire (site files don't match any test pattern, and the validator's stack-detect for `site/` will pick up bun but the test-pattern table will see no tests, so the advisory only fires when prod files change without matching test changes — which doesn't apply on a greenfield scaffold). If it does fire, the advisory carries no block and we proceed.
