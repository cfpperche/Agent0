# 052 — plan

## Approach

Three coupled but independent fixes; each can ship alone but the bundle saves one commit + one spec dir. All work is parent-side editing of skill files + skeleton template additions. No sub-agent dispatches needed. Validation defers to "next real `/product` run" rather than re-running the full pipeline against /tmp/dogfood-erp/ (retro-fix surgery too heavy — moving 24 routes into `app/(app)/` + writing layout + 24 state files = bigger than the validation win).

## Files to touch

### Skill (committed)

| File | Change | Phase |
|---|---|---|
| `.claude/skills/product/references/delegation-briefs.md` § Step 15 atlas brief | Add atlas-writes-layout discipline + CONSTRAINTS forbidding chrome invention by per-route writers | A |
| `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer § Next.js | Category→route-group mapping; state-file convention; ban inline chips | A + B |
| `.claude/skills/product/SKILL.md` § Phase 4 | Reorder step 1 (atlas) vs step 2 (per-route writers) to make atlas-first explicit; add smoke-test as new step 4-c | A + C |
| `.claude/skills/product/templates/monorepo-skeleton/next/app/loading.tsx` | NEW — minimal root-level loading skeleton | B |
| `.claude/skills/product/templates/monorepo-skeleton/next/app/error.tsx` | NEW — minimal root-level error boundary | B |
| `.claude/skills/product/templates/monorepo-skeleton/next/app/not-found.tsx` | NEW — minimal root-level 404 | B |
| `.claude/skills/product/templates/monorepo-skeleton/next/app/globals.css` | Verify no change needed (token import still works through new route groups) | — |

### Not touched (deliberate)

- Expo skeleton — out of scope per Non-goals
- Sitemap schema (`.claude/skills/product/references/sitemap-schema.md`) — `category` field already exists per spec 045; no schema change
- Validator (`.claude/validators/run.sh`) — chip-pattern grep extension deferred
- `/tmp/dogfood-erp/` — too much surgery to retro-fix; next real run is the cross-check

## Alternatives considered

1. **Shared `<AppShell>` component imported by every page** (initial framing in audit critique). Rejected: that's the *anti-pattern* this spec exists to escape. Component-import discipline failed in the spec-048 run because sub-agents had no enforced contract to import it. Route groups make chrome inheritance implicit via routing — no contract to break.
2. **Add a SHELL.md doc spec'ing the chrome contract** and brief sub-agents to read it. Rejected: same problem one layer up — sub-agents have to remember to read it. Framework-native conventions need no doc-reading.
3. **Storybook for state showcase** (instead of sibling `loading.tsx`/`error.tsx`). Rejected: heavy dependency for prototype tier; Next.js native files ARE the showcase mechanism.
4. **Smoke-test crawls all sitemap routes.** Considered, deferred. One per category catches structural breakage at ~10s probe budget; full crawl scales linearly and adds flake risk. Revisit if class-bug recurrence justifies it.
5. **Smoke-test failure aborts Phase 4.** Considered, deferred. Spec 045 set the precedent: tsc/biome failures record + continue, don't abort. Smoke-test inherits the posture — REPORT highlights failures so founder cannot miss; aborting would block legitimate prototypes whose smoke-test fails on environment quirk (port-in-use, network jank). Revisit if smoke-test false-positives are negligible after some runs.
6. **Probe via headless Playwright (full console-error scrape) instead of curl + body-grep.** Heavier, slower, MCP dependency. Considered for richer signal but rejected for v1 — HTTP-200 + body-string check catches the runtime-error class. Upgrade to Playwright is a follow-on if the body-grep heuristic misses cases.
7. **Run smoke-test on the production build (`pnpm build && pnpm start`)** instead of dev server. Production build is closer to ship-truth but takes 2-3× longer + masks dev-time errors that the React strict-mode + dev overlay surface. Dev server is the right probe for catching *the bug class spec 051 patched*.

## Risks

1. **Atlas + screen-writers sequence change.** Currently the atlas runs in parallel with screen-writers (per spec 048 — both are "step 15" sub-agents (a) + (b)). Moving atlas to BEFORE writers means longer Phase 4 wall-clock (~30-60s added). Acceptable; the gain is the chrome contract becomes inheritable instead of inventable.
2. **Route-group existing files in dogfood become orphans.** /tmp/dogfood-erp/app/dashboard/page.tsx etc. live flat; this spec's brief tells the NEXT run to nest them under `(app)/`. Not retro-fixing here (per Non-goals) — explicit choice.
3. **`pnpm dev` port collision.** Probe port `--port 3099` reduces clash risk but doesn't eliminate. Spec documents the port; if collision becomes recurring, escalate to random-port + `lsof` check.
4. **Dev server slow boot on first compile.** Cold-cache Turbopack typically 2-5s. Smoke-test polls "Ready" marker with timeout — 30s budget is generous but could be tighter or longer based on real measurements.
5. **Error-overlay marker drift across Next.js versions.** `__next-dev-overlay-error` substring matched a specific version's HTML. If Next.js renames it in 17.x, smoke-test silently misses runtime errors. Mitigation: combine with HTTP status check (errors return 500); rely on overlay-grep as secondary signal only.
6. **REPORT.md size grows.** New smoke-test subsection adds ~10 lines per run; trivial.
7. **Skeleton root-level state files trump custom per-route files?** Nope — Next.js convention: nearest sibling wins. Root `loading.tsx` is fallback; per-route override beats it. Documented in the brief.

## Execution order

1. Scaffold spec 052 (this file + spec.md + tasks.md) — done.
2. Write 3 new skeleton state files: `loading.tsx`, `error.tsx`, `not-found.tsx`. Token-only, minimal, PT-BR-neutral (sub-agent localises if needed; default copy is English).
3. Edit delegation-briefs.md atlas brief — atlas-writes-layout requirement + DONE_WHEN extension.
4. Edit delegation-briefs.md per-stack screen-writer brief — category→route-group table; state-file convention; ban inline chips.
5. Edit SKILL.md Phase 4 — sequence atlas-before-writers; add smoke-test subroutine to step 4 with port + poll + probe + kill discipline.
6. Run skill validator (gate D).
7. Commit.

## Notes

- Per CLAUDE.md governance gate, no destructive operations.
- Per `.claude/rules/delegation.md`, no sub-agent dispatches in this spec (parent-side edits + new template files).
- Per `.claude/rules/tdd.md`, the skill changes are documentation/brief text + template scaffolds — no separate test file needed. The "test" is the next real `/product` run that exercises the new conventions.
- Per `.claude/rules/research-before-proposing.md`, Next.js 16 idioms verified via official docs (route groups, loading/error/not-found conventions — cited in spec.md § Lineage).
- Per spec 048's "Validator scope is REPO-WIDE" note: new skeleton state files will be in the per-prototype `<out>/` so don't compete with the repo-wide validator scope.
