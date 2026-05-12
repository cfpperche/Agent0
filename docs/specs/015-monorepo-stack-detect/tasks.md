# 015 — monorepo-stack-detect — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Refactor existing detection into a path-parameterised function

- [x] 1. Open `.claude/hooks/mcp-recipes-hint.sh`. Pull the existing per-signal branches (Next file/dep, browser-non-Next dep, DB file/dir/env) into a shell function `detect_at <abs_path>` that populates locals (`have_next` / `have_browser` / `have_db`) plus appends signal labels to a passed-in accumulator. Keep ALL existing behaviour identical.
- [x] 2. Re-run `bash .claude/tests/mcp-recipes/run-all.sh`. Expected: 6/6 PASS — the refactor must be behaviour-preserving.
- [x] 3. Commit the refactor as a single atomic change: `refactor(015): extract detect_at function (no behaviour change)`. Establishes the function as the basis for the walk.

### Phase 2 — RED test suite for workspace walk

- [x] 4. Create `.claude/tests/monorepo-stack-detect/run-all.sh` driver.
- [x] 5. Write `01-next-in-apps-web.sh`. Fixture: `apps/web/next.config.js`. Asserts hint contains `next-devtools-mcp` AND `playwright-mcp` AND signal label `apps/web/next.config.js`.
- [x] 6. Write `02-db-in-apps-api.sh`. Fixture: `apps/api/schema.prisma`. Asserts hint contains `dbhub` AND signal label `apps/api/schema.prisma`.
- [x] 7. Write `03-combined-dedupe.sh`. Fixture: `apps/web/next.config.js` + `apps/api/schema.prisma` + `packages/ui/package.json` (with react dep). Asserts hint lists each recipe exactly once (next-devtools-mcp, playwright-mcp, dbhub) even though playwright is added by both Next and browser branches.
- [x] 8. Write `04-default-layouts.sh`. Cycle through each default workspace dir (`apps`, `packages`, `services`, `workspaces`), each with `next.config.js` in a child. Each iteration asserts hint fires.
- [x] 9. Write `05-custom-workspace-dirs.sh`. With `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS="modules subprojects"` and `modules/web/next.config.js` + an irrelevant `apps/foo/next.config.js` (which should be skipped because the env var REPLACES the default set). Assert hint fires on the modules signal and does NOT include the apps signal.
- [x] 10. Write `06-root-still-works.sh`. Root `next.config.js` (no workspaces). Asserts hint fires unchanged — regression guard for spec 012's pre-015 behaviour.
- [x] 11. Write `07-depth-cap.sh`. Fixture: `apps/web/nested/deep/next.config.js`. Asserts hint does NOT fire (depth-2+ ignored).
- [x] 12. Write `08-opt-out.sh`. Monorepo with strong signals + `CLAUDE_SKIP_MCP_RECIPES=1`. Asserts hint silent (regression guard for spec 012's escape hatch).
- [x] 13. Write `09-empty-env-disables-walk.sh`. `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""` + monorepo with workspace signals. Asserts walk skipped (no `apps/...` labels in output), but root signals still detected if present.
- [x] 14. Run `bash .claude/tests/monorepo-stack-detect/run-all.sh`. Expected: tests 01-05, 09 FAIL (no walk yet), test 06 PASS (root case unchanged), tests 07-08 PASS (depth cap N/A without walk; opt-out unchanged). Document the partial RED state.

### Phase 3 — Implementation: workspace walk

- [x] 15. In `.claude/hooks/mcp-recipes-hint.sh`, after the root `detect_at "$PROJECT_DIR"` call, add a workspace-walk loop. Default workspace set: `apps packages services workspaces`. Override: `${CLAUDE_MCP_RECIPES_WORKSPACE_DIRS-}` (if set even to empty, replaces default). For each workspace dir, glob the direct children (depth-1) and call `detect_at` on each. Aggregate the recipe set + signal labels across all calls.
- [x] 16. Add the empty-set semantics: `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""` → no walk (root-only detection). Distinct from "unset" which uses the default set.
- [x] 17. Run `bash .claude/tests/monorepo-stack-detect/run-all.sh`. Expected: 9/9 PASS — GREEN.
- [x] 18. Run `bash .claude/tests/mcp-recipes/run-all.sh`. Expected: 6/6 PASS — spec 012 regression-free.
- [x] 19. Update `.claude/rules/mcp-recipes.md`: add "Walk scope" subsection naming the default workspace dirs + the env var. Add a depth-cap gotcha. Update the hint output shape example with a workspace-prefixed signal label.
- [x] 20. Update `CLAUDE.md` § MCP recipes: append a sentence on monorepo walk.

### Phase 4 — Live verification

- [x] 21. Live-verify pass 1. Create a tmp monorepo fixture with `apps/web/next.config.js` + `apps/api/schema.prisma`. Run the hook directly. Confirm hint surfaces both recipes with correctly prefixed signal labels.
- [x] 22. Live-verify pass 2. Set `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""` on the same fixture. Confirm hint goes silent (empty-set semantics work).
- [x] 23. Live-verify pass 3. Set `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS="modules"` + put a `modules/foo/next.config.js`. Confirm only the modules signal fires; `apps/*` from default set is skipped.
- [x] 24. Apply yield-decay: two consecutive 0-finding live-verify passes graduate.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] V1. Next in `apps/web/` — task 17 PASS for 01 + live-verify pass 1.
- [x] V2. DB in `apps/api/` — task 17 PASS for 02 + live-verify pass 1.
- [x] V3. Combined dedup — task 17 PASS for 03.
- [x] V4. All default layouts — task 17 PASS for 04.
- [x] V5. Custom workspace dirs — task 17 PASS for 05 + live-verify pass 3.
- [x] V6. Root still works — task 17 PASS for 06 + task 18 spec-012 regression suite.
- [x] V7. Depth cap — task 17 PASS for 07.
- [x] V8. Opt-out still works — task 17 PASS for 08.
- [x] V9. Empty-env disables walk — task 17 PASS for 09 + live-verify pass 2.
- [x] V10. Static facts — hook function refactored, env var honored, rule doc updated, CLAUDE.md block updated.

## Notes

### Commit cadence

1. `refactor(015): extract detect_at function (no behaviour change)` — after task 3 (spec 012 suite still 6/6)
2. `tests(015): RED — monorepo workspace-walk scenarios` — after task 14
3. `feat(015): workspace-walk in stack detector` — after tasks 15-18 (9/9 GREEN, 012 suite regression-free)
4. `docs(015): rule doc + CLAUDE.md updates` — after tasks 19-20
5. `fix(015): live-verify adjustments` (if any) — after task 24
6. `chore: SESSION refresh — spec 015 delivered`

### Live-verify findings

Three live-verify passes on 2026-05-12, 0 findings each → graduates.

- **Pass 1** — `apps/web/next.config.ts` + `apps/api/schema.prisma` + `packages/ui/package.json` (react). Hint surfaced 4 recipes (next-devtools-mcp, playwright-mcp, chrome-devtools-mcp, dbhub) with all three workspace-prefixed signal labels. Confirms walk + dedup + per-workspace browser detection (packages/ui flipped have_browser even though apps/web set have_next).
- **Pass 2** — same fixture + `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS=""`. Hint completely silent. Confirms empty-env semantics (walk disabled; root has no signals → silent).
- **Pass 3** — `modules/foo/next.config.js` + decoy `apps/decoy/next.config.js` + `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS="modules"`. Hint shows `modules/foo/next.config.js` only; `apps/decoy` correctly suppressed. Confirms env var REPLACES (not merges with) default set.

### Delivery commits

- `63953cb refactor(015): extract detect_at(<path>) — no behaviour change`
- `f62aa16 tests(015): RED — monorepo workspace-walk scenarios`
- `052c9d8 feat(015): workspace walk in mcp-recipes-hint.sh`
- `e5c3ba4 docs(015): rule doc walk-scope subsection + CLAUDE.md monorepo mention`
