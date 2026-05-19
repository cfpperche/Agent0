# 055 — Tasks

1. [ ] Resolve open question #1 (backward compatibility) — recommend default-inference from category when omitted.
2. [ ] Resolve open question #2 (required vs optional `chrome`) — recommend optional-with-default-inference.
3. [ ] Resolve open question #3 (auth chrome decision) — recommend `chrome: auth` with own auth group layout for consistency.
4. [ ] Define the category→chrome default-inference table (e.g. `primary → app`, `admin → app`, `marketing → marketing`, `auth → auth`, `error → chromeless`).
5. [ ] Edit `sitemap-schema.md`: add `chrome` field with enum + default-inference rule documented.
6. [ ] Edit `templates/pipeline/07-sitemap-ia/prompt.md` + `schema.md`: instruct sub-agent to emit `chrome` (recommend always-emit; default-inference is fallback for legacy sitemaps).
7. [ ] Edit `delegation-briefs.md` per-stack screen-writer: replace category-based path resolution with chrome-based.
8. [ ] Edit `delegation-briefs.md` Step 15a atlas: chrome-aware route-group layout emission (one `layout.tsx` per distinct chrome with ≥1 route).
9. [ ] Edit `SKILL.md § Phase 4 Step 15`: update orchestrator dispatch logic for chrome-aware layouts.
10. [ ] Verify with a dry-run on a multi-chrome sitemap — confirm correct route-group placement.
11. [ ] Commit: `feat(055): sitemap chrome field — orthogonal to category, drives route-group placement`.
