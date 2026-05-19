# 055 — Tasks

1. [x] Resolve open question #1 — **DECIDED: default-inference from category** when `chrome:` omitted (back-compat fallback only). Default-inference is mechanical and CANNOT decide booking-vs-app correctly without help — new sitemaps SHOULD always emit `chrome` explicitly.
2. [x] Resolve open question #2 — **DECIDED: optional with default-inference**. Schema does not require `chrome` to keep back-compat with pre-055 sitemaps; Step 07 prompt instructs sub-agents to always emit it on new generation.
3. [x] Resolve open question #3 — **DECIDED: `chrome: auth` with own `(auth)/layout.tsx`** group layout (logo + lang switcher + back-to-marketing link). Consistent with the other chrome values having their own shell.
4. [x] Define category→chrome default-inference table: `primary → app`, `admin → app`, `marketing → marketing`, `auth → auth`, `error → chromeless`. Documented in `sitemap-schema.md § chrome`.
5. [x] Edit `sitemap-schema.md`: added `chrome` to optional fields table + dedicated `## chrome — orthogonal to category (spec 055)` section with enum closure + default-inference table + explicit-divergence example.
6. [x] Edit `templates/pipeline/07-sitemap-ia/prompt.md`: added `chrome` to per-route field requirements table + updated YAML example with explicit `chrome` on every route (including booking-divergence pattern).
7. [x] Edit `delegation-briefs.md § Per-stack screen-writer`: replaced category-based path resolution with chrome-based (5 enum values → 5 path patterns); default-inference fallback noted.
8. [x] Edit `delegation-briefs.md § Step 15a atlas`: chrome-aware layout emission (one `app/(<chrome>)/layout.tsx` per distinct chrome with ≥1 route).
9. [x] Edit `SKILL.md § Phase 4 Step 15`: updated orchestrator narrative for atlas to write N chrome-layouts + per-route writer to use `chrome` for path resolution.
10. [ ] Verify with a dry-run on a multi-chrome sitemap — confirm correct route-group placement. **Deferred to next /product invocation**; spec 055 ships docs-only.
11. [ ] Commit: `feat(055): /product sitemap chrome field — orthogonal to category`.
