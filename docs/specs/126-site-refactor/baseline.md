# 126 — site-refactor — pre-refactor baseline (Phase 0)

_Captured 2026-05-30, before any refactor edit, against the existing `site/` build. The non-regression acceptance scenario compares the post-refactor state to this artifact. **Equal-or-better on every line below.**_

## Tool / command

- **Performance (intended tool):** Lighthouse.
  ```bash
  cd site && bun run build && bun run preview --port 4399 &
  npx --yes lighthouse http://localhost:4399/Agent0/<locale>/ \
    --only-categories=performance,accessibility,seo \
    --chrome-flags="--headless --no-sandbox" --output=json
  ```
  **Env caveat:** in this WSL session Lighthouse could not connect to Chrome (`Unable to connect to Chrome`), so numeric perf scores were not captured here — run the command in CI or a Chrome-connectable env to record them. The dimensions below were captured statically from the built HTML + `dist/`, which is sufficient for non-regression on SEO/meta/a11y/bundle.
- **Viewport (when run):** default Lighthouse mobile.
- **URLs:** `/Agent0/en/`, `/Agent0/pt/`, `/Agent0/es/` (+ root `/Agent0/` redirect).

## Captured metrics (static, reproducible)

| Dimension | Baseline | Post-refactor target |
|---|---|---|
| Build | `bun run build` green, 3 pages + redirect, ~834ms | green |
| `dist/` total | 488 KB | ≤ ~ (no large regression; note if intentional) |
| Page HTML size | en 40257 B / pt 40667 B / es 40944 B; root redirect 324 B | comparable |
| `<title>` + `description` | present, both locales-localized | present |
| `og:title` / `og:description` / `og:type` / `og:url` | present | present |
| **`og:image`** | **ABSENT (gap)** | **present (Phase 4 adds asset + tag)** |
| `twitter:card` | `summary_large_image` | present |
| `twitter:title` / `twitter:description` | ABSENT | present (Phase 4) |
| hreflang alternates + x-default | present | present |
| Skip-to-content link | present (1) | present |
| `<html lang>` | set per locale | set |
| `<h1>` count | 1 per page | exactly 1 |

## Known pre-refactor deficiencies (to fix, tracked as targets above)

- No `og:image` and no `twitter:title`/`twitter:description` → social cards render bare. **Phase 4.**
- Copy/data drift: hero/meta say "harness for AI coding agents", `whatYouGet.title` = "Eighteen capacities", but `capacities.ts` has 14 entries and the repo ships 20+ → see the inventory audit in `notes.md`. **Phase 1.**
- Copy is Claude-Code-only; the repo is multi-runtime (Claude + Codex, spec 121). **Phase 1.**
