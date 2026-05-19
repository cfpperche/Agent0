# 055 — Plan

## Approach

Add `chrome: <enum>` as an orthogonal route field. Keep `category` for PRD-coverage semantics. Per-stack screen-writer + atlas brief read `chrome` for path resolution; everything else (states, covers_us, components) stays as-is. Orchestrator default-infers `chrome` from `category` when omitted, so existing sitemaps don't break.

## Files to touch

- `.claude/skills/product/references/sitemap-schema.md` — add `chrome: app|marketing|booking|auth|chromeless` field. Enum closed for v1.
- `.claude/skills/product/templates/pipeline/07-sitemap-ia/prompt.md` + `schema.md` — instruct Step 07 sub-agent to emit `chrome` (recommend always-emit; document the default-inference fallback).
- `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer — switch path resolution from `category`-derived to `chrome`-derived. Atlas brief gains chrome-aware route-group layout emission rule (already partially there — formalize).
- `.claude/skills/product/SKILL.md` § Phase 4 Step 15 — atlas dispatches based on distinct `chrome` values present in sitemap, replacing the current "≥3 marketing routes" heuristic with "≥1 route in chrome group X".

## Alternatives considered

- **Single combined enum** — e.g. `category: tutor-public`. Rejected — collides with the 5 required_categories schema enforcement that exists to prevent silent undercoverage.
- **Infer from path prefix** — e.g. routes starting with `/[clinicSlug]` are booking. Rejected — too brittle; can't decode `(booking)` semantics from arbitrary URL shapes.
- **Sub-agent invents route-group at write time** (status quo). Rejected — sub-agent screen-writer in dogfood-2 couldn't have known booking was the right group; only the parent (with global PRD context) made that call.

## Risks

- **Sub-agent confusion.** Two fields per route (`category` + `chrome`) feel redundant when they correlate strongly. Mitigation: orchestrator default-inference so sub-agents emit `chrome` only when it diverges from category default.
- **Enum closure.** v1 enum is `{app, marketing, booking, auth, chromeless}`. A future product needing `embed` or `print` chrome would need a spec bump. Acceptable — keep the enum closed until evidence demands more.
- **Atlas dispatch change.** Atlas currently writes `(marketing)/layout.tsx` based on a count of marketing routes ≥3. New rule (≥1 route per chrome) may produce more layouts; cost is small (each layout.tsx is <1 KB).
