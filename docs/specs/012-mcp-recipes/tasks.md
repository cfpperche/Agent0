# 012 — mcp-recipes — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Documented contract

- [ ] 1. Draft `.claude/rules/mcp-recipes.md`. Sections: capacity intent (one paragraph), four MCP sub-sections (Playwright / Chrome DevTools / DBHub / Next.js DevTools — each with **what it provides** / **install command** / **`.mcp.json` block** / **when to enable** / **runtime requirements** / **security link to upstream**), the SessionStart hint shape (with example output), stack-detector signal table, env-var escape hatches (`CLAUDE_SKIP_MCP_RECIPES`), explicit non-goals (mirror `spec.md`), and gotchas (monorepo caveat, package-name drift, `.mcp.json.example` JSON-with-comments, settings.json mutation, security-doc deferral to upstreams).
- [ ] 2. Draft `.mcp.json.example` at repo root. Top header comment explains: copy to `.mcp.json` (no `.example`), remove `//` lines, uncomment one or more blocks. Four blocks (Playwright / Chrome DevTools / DBHub / Next.js DevTools), each commented-out by a per-block `//` prefix. Each block uses `@latest` per the open-question 4 ratification.

### Phase 2 — RED test suite (no implementation yet)

- [ ] 3. Create `.claude/tests/mcp-recipes/run-all.sh` mirroring `.claude/tests/runtime-introspect/run-all.sh` (same driver shape — lex-ordered NN-*.sh scenarios, `-v` verbose pass-through, PASS/FAIL table).
- [ ] 4. Write `01-next-detection.sh`. Fixture: tmp dir with `next.config.js` (or `package.json` whose `dependencies.next` is set). Invokes the hint hook with `CLAUDE_PROJECT_DIR` pointed at the fixture. Asserts stdout contains `next-devtools-mcp` AND `playwright-mcp` recipe names in a single hint block.
- [ ] 5. Write `02-browser-non-next.sh`. Fixture: tmp dir with `package.json` containing `react` or `vite` or `vue` or `svelte` or `astro` in deps, NO `next`. Asserts hint contains `playwright-mcp` AND `chrome-devtools-mcp`, does NOT contain `next-devtools-mcp`.
- [ ] 6. Write `03-db-detection.sh`. Three sub-cases: (a) tmp dir with `schema.prisma`; (b) tmp dir with `drizzle.config.ts`; (c) tmp dir with `.env.example` containing a `DATABASE_URL=` line. Each asserts hint contains `dbhub`.
- [ ] 7. Write `04-silent-no-signals.sh`. Fixture: tmp dir with only `README.md` and `LICENSE` (no stack signals). Asserts hint block is NOT emitted in stdout (no `=== mcp-recipes ===` framing line).
- [ ] 8. Write `05-co-exists-with-011.sh`. Fixture: tmp dir with both stack signal (e.g. `next.config.js`) AND a fake `.claude/tools/probe.sh` (executable touch is sufficient). Pipes the same SessionStart payload through `.claude/hooks/session-start.sh` (which now should emit BOTH the runtime-introspect hint AND the mcp-recipes hint). Asserts both `=== runtime-introspect ===` AND `=== mcp-recipes ===` framing lines appear in stdout.
- [ ] 9. Write `06-opt-out-env.sh`. Fixture: tmp dir with stack signal. With `CLAUDE_SKIP_MCP_RECIPES=1`, asserts hint NOT emitted. Without the env var, same fixture, asserts hint IS emitted (regression guard).
- [ ] 10. Run `bash .claude/tests/mcp-recipes/run-all.sh`. Expected: 0/6 PASS — all RED (`mcp-recipes-hint.sh` doesn't exist yet).

### Phase 3 — Implementation

- [ ] 11. Implement `.claude/hooks/mcp-recipes-hint.sh`. Phases: env-var escape hatch (`CLAUDE_SKIP_MCP_RECIPES=1` → exit 0 silent); resolve `CLAUDE_PROJECT_DIR`; run signal detection (see signal table below); if no signals match → exit 0 silent; emit single `=== mcp-recipes ===` block listing applicable recipes + the pointer to `.claude/rules/mcp-recipes.md`. Always exit 0.

   **Signal table:**
   - **Next.js:** any of `next.config.js`, `next.config.ts`, `next.config.mjs`, `next.config.cjs` exists OR `jq '.dependencies.next // .devDependencies.next // empty' package.json` non-empty → suggest `next-devtools-mcp` + `playwright-mcp`.
   - **Browser (non-Next):** `jq` on `package.json` matches any of `react`/`vue`/`svelte`/`vite`/`astro` in `dependencies` or `devDependencies`, AND Next signal is absent → suggest `playwright-mcp` + `chrome-devtools-mcp`.
   - **DB:** any of `schema.prisma`, `drizzle.config.{js,ts,mjs}`, `alembic.ini`, `database/migrations/`, `db/migrate/` exists OR `.env.example` contains a line matching `^DATABASE_URL=` → suggest `dbhub`.
   - Multiple signals can fire; the hint block lists the union of suggested recipes (Set-like dedup).

- [ ] 12. Wire `.claude/settings.json`. Register `mcp-recipes-hint.sh` on `SessionStart`, after `session-start.sh` so the mcp-recipes block appears AFTER the SESSION.md / probe-hint block in the additional-context stream.
- [ ] 13. Add new **Mcp recipes** § block to `CLAUDE.md` after the Runtime introspect block. One paragraph: what the capacity does, where the recipes live (`.claude/rules/mcp-recipes.md`), what the workflow is (`cp .mcp.json.example .mcp.json` + uncomment), how to opt out (`CLAUDE_SKIP_MCP_RECIPES=1`).
- [ ] 14. Run `bash .claude/tests/mcp-recipes/run-all.sh`. Expected: 6/6 PASS — GREEN. Any failures → fix the implementation (not the tests), re-run until green.

### Phase 4 — Live verification on real-shape fixtures

Spec 011 had a real-fork dogfood pass. Spec 012 has no MCP-running dogfood (we ship recipes, not active servers), but we DO live-verify the hint shape against fixtures that closely resemble real forks. Adjustments here add to the test suite (per the "documented gotchas need defended counterparts" lesson from 011).

- [ ] 15. Live-verify pass 1. From this Agent0 repo (no stack signals at root), run `bash .claude/hooks/mcp-recipes-hint.sh` directly. Confirm: silent exit 0, no hint block emitted.
- [ ] 16. Live-verify pass 2. Create a tmp fixture resembling `/home/goat/shrnk` (Bun + TS, no Next, no DB). Should the hint fire? Walk the signal table — Bun project with a TS test stack, no react/vue/svelte/vite/astro deps, no Next. Hint should NOT fire. Confirm. If hint fires unexpectedly, that's a finding → write RED test → fix detector → re-run suite.
- [ ] 17. Live-verify pass 3. Create a tmp fixture with `next.config.js` + `package.json` listing `next` + `prisma`. Should suggest `next-devtools` + `playwright` (Next branch) AND `dbhub` (DB branch). Confirm dedup works (no duplicate recipe names; both branches fire and merge cleanly).
- [ ] 18. Live-verify pass 4. Create a tmp fixture matching the spec-011 sibling test `05-co-exists-with-011.sh` shape: stack signal + `.claude/tools/probe.sh` present. Invoke the full `session-start.sh` (not the mcp-hint hook alone) with synthetic stdin and confirm BOTH `=== runtime-introspect ===` AND `=== mcp-recipes ===` blocks appear.
- [ ] 19. If passes 15-18 surfaced findings, write RED tests, fix, re-run full suite to GREEN. Apply yield-decay: two consecutive 0-finding live-verify passes graduate the capacity.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one maps to a checklist item there._

- [ ] V1. Scenario "recipe documented for each of the 4 v1 MCPs" — read `.claude/rules/mcp-recipes.md`; confirm each MCP has the six required sub-sections (source URL / capabilities / `.mcp.json` block / install command / when-to-enable / security link).
- [ ] V2. Scenario "`.mcp.json.example` ships at repo root" — `ls .mcp.json.example` returns the file; head shows the workflow header comment.
- [ ] V3. Scenario "Next.js project detection" — task 14 PASS for `01-next-detection.sh` + live-verify pass 3.
- [ ] V4. Scenario "non-Next browser-stack detection" — task 14 PASS for `02-browser-non-next.sh`.
- [ ] V5. Scenario "DB-shaped project detection" — task 14 PASS for `03-db-detection.sh` + live-verify pass 3 (dedup case).
- [ ] V6. Scenario "no stack signals → silent" — task 14 PASS for `04-silent-no-signals.sh` + live-verify pass 1 (Agent0 root) + live-verify pass 2 (shrnk-shape).
- [ ] V7. Scenario "hint co-exists with spec 011's probe hint" — task 14 PASS for `05-co-exists-with-011.sh` + live-verify pass 4.
- [ ] V8. Scenario "opt-out" — task 14 PASS for `06-opt-out-env.sh`.
- [ ] V9. Static facts — `.claude/rules/mcp-recipes.md`, `.mcp.json.example` at repo root, `.claude/hooks/mcp-recipes-hint.sh` exists + executable, `.claude/settings.json` SessionStart entry, CLAUDE.md § block — all present.
- [ ] V10. Yield-decay graduation — two consecutive 0-finding live-verify passes recorded in this file's Notes section.
- [ ] V11. SESSION.md refresh — final commit's SESSION.md reflects 012 delivered, graduation status, and any deferred follow-ups.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

### Commit cadence

Suggested commit phases (one per natural rollback boundary, mirroring spec 011):

1. `docs(012): rule doc + .mcp.json.example` — after tasks 1-2
2. `tests(012): RED — mcp-recipes hint scenarios` — after task 10 (with 0/6 PASS confirmed)
3. `feat(012): mcp-recipes SessionStart hint + stack detector` — after task 14 (with 6/6 PASS confirmed)
4. `fix(012): live-verify pass N adjustments` (if any) — after task 19
5. `chore: SESSION refresh — spec 012 delivered + graduation` — after V11

### Live-verify pass-1 findings

_To be filled during execution._

### Live-verify pass-2 findings

_To be filled during execution._
