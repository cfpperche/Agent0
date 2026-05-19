# 052 — tasks

Execute top-to-bottom.

## Phase B-prep — skeleton state files (root-level defaults)

- [x] BP1. Write `.claude/skills/product/templates/monorepo-skeleton/next/app/loading.tsx` (minimal Server Component skeleton; tokens-only; ≤30 LOC; English copy).
- [x] BP2. Write `.claude/skills/product/templates/monorepo-skeleton/next/app/error.tsx` (Client Component per Next.js convention; `'use client'` at top; reset + try-again button; tokens-only; ≤40 LOC).
- [x] BP3. Write `.claude/skills/product/templates/monorepo-skeleton/next/app/not-found.tsx` (Server Component; link back to `/`; tokens-only; ≤30 LOC).

## Phase A — delegation-briefs.md atlas brief

- [x] A1. Edit Step 15 atlas brief CONTEXT to read sitemap categories explicitly.
- [x] A2. Edit Step 15 atlas brief DELIVERABLE to include the layout files: `<out>/app/(app)/layout.tsx` (shared sidebar+topbar for primary+admin routes); optionally `<out>/app/(marketing)/layout.tsx` if sitemap marketing has ≥3 routes.
- [x] A3. Edit Step 15 atlas brief DONE_WHEN to list the layout file existence + chrome match against sitemap + tokens-only + no `'use client'` directive at top of layout.

## Phase A — delegation-briefs.md screen-writer (Next.js)

- [x] A4. Edit § Per-stack screen-writer § Next.js stack target-file table to declare the category→route-group mapping: `primary` + `admin` → `<out>/app/(app)/<route>/page.tsx`; `marketing` + `auth` + `booking` → `<out>/app/<route>/page.tsx`; root marketing landing → `<out>/app/page.tsx`.
- [x] A5. Add CONSTRAINTS bullet: "Do NOT define sidebar / topbar / shell chrome in `page.tsx` — the route-group layout owns the chrome. Pages render their unique content; chrome inheritance is implicit via Next.js nested-layout cascade."

## Phase B — delegation-briefs.md states convention

- [x] B1. Add CONSTRAINTS bullet banning inline state-mode toggle chips in production page bodies (no `useState<"default" | "loading" | "empty" | "error">` toggles; no chip rows showing those words as developer-mode switches).
- [x] B2. Add CONSTRAINTS bullet prescribing Next.js sibling-file convention: sitemap entry `states: [loading]` → emit `<route>/loading.tsx`; `states: [error]` → emit `<route>/error.tsx` (with `'use client'` + reset handler); `states: [404]` or `states: [not-found]` → emit `<route>/not-found.tsx`; empty state is page-internal data-driven rendering, NOT a toggle.
- [x] B3. Mention root-level defaults (skeleton ships `app/{loading,error,not-found}.tsx`) — per-route sibling file overrides root default when present (nearest-wins per Next.js convention).

## Phase C — SKILL.md Phase 4 dev-server smoke-test

- [x] C1. Edit SKILL.md § Phase 4 step 1 + 2 to make the atlas-before-writers sequence explicit: "Step 15 — Atlas (sub-agent a) runs FIRST and writes `app/(app)/layout.tsx` (and optional `app/(marketing)/layout.tsx`); per-route screen-writers (sub-agent b) dispatch only AFTER atlas returns."
- [x] C2. Extend SKILL.md § Phase 4 step 4 (build verification) with smoke-test subroutine: `pnpm dev --port 3099 &` background; poll dev-server stdout for "Ready" (30s timeout); for each unique sitemap category, pick 1 representative route + curl `http://localhost:3099<route>` (10s timeout); check HTTP 200 + body does NOT contain `__next-dev-overlay-error` OR `nextjs__container_errors`; capture (status, latency_ms) per route; kill the dev-server PID at the end.
- [x] C3. Document the smoke-test result reporting: each probed route gets a row in `<out>/docs/REPORT.md` § "Build health" § "Dev-server smoke-test"; failures get a `## Action required` callout the founder cannot miss; smoke-test failure does NOT abort the run (consistent with tsc/biome posture).

## Phase D — Validator + commit

- [x] D1. `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` → exit 0.
- [x] D2. `git status` + `git diff --stat` → confirm only skill files + skeleton additions + spec 052 scaffold staged.
- [x] D3. Commit with HEREDOC body: `fix(052): /product skill — route-group chrome + idiomatic states + Phase-4 dev-server smoke-test`.
- [x] D4. `git status` → confirm clean.
- [x] D5. Flip spec 052 `Status:` to `shipped`; mark all checkboxes in this tasks.md.
