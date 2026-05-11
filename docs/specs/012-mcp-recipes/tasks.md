# 012 — mcp-recipes — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Documented contract

- [x] 1. Draft `.claude/rules/mcp-recipes.md`. Sections: capacity intent (one paragraph), four MCP sub-sections (Playwright / Chrome DevTools / DBHub / Next.js DevTools — each with **what it provides** / **install command** / **`.mcp.json` block** / **when to enable** / **runtime requirements** / **security link to upstream**), the SessionStart hint shape (with example output), stack-detector signal table, env-var escape hatches (`CLAUDE_SKIP_MCP_RECIPES`), explicit non-goals (mirror `spec.md`), and gotchas (monorepo caveat, package-name drift, `.mcp.json.example` JSON-with-comments, settings.json mutation, security-doc deferral to upstreams).
- [x] 2. Draft `.mcp.json.example` at repo root. Top header comment explains: copy to `.mcp.json` (no `.example`), remove `//` lines, uncomment one or more blocks. Four blocks (Playwright / Chrome DevTools / DBHub / Next.js DevTools), each commented-out by a per-block `//` prefix. Each block uses `@latest` per the open-question 4 ratification.

### Phase 2 — RED test suite (no implementation yet)

- [x] 3. Create `.claude/tests/mcp-recipes/run-all.sh` mirroring `.claude/tests/runtime-introspect/run-all.sh` (same driver shape — lex-ordered NN-*.sh scenarios, `-v` verbose pass-through, PASS/FAIL table).
- [x] 4. Write `01-next-detection.sh`. Fixture: tmp dir with `next.config.js` (or `package.json` whose `dependencies.next` is set). Invokes the hint hook with `CLAUDE_PROJECT_DIR` pointed at the fixture. Asserts stdout contains `next-devtools-mcp` AND `playwright-mcp` recipe names in a single hint block.
- [x] 5. Write `02-browser-non-next.sh`. Fixture: tmp dir with `package.json` containing `react` or `vite` or `vue` or `svelte` or `astro` in deps, NO `next`. Asserts hint contains `playwright-mcp` AND `chrome-devtools-mcp`, does NOT contain `next-devtools-mcp`.
- [x] 6. Write `03-db-detection.sh`. Three sub-cases: (a) tmp dir with `schema.prisma`; (b) tmp dir with `drizzle.config.ts`; (c) tmp dir with `.env.example` containing a `DATABASE_URL=` line. Each asserts hint contains `dbhub`.
- [x] 7. Write `04-silent-no-signals.sh`. Fixture: tmp dir with only `README.md` and `LICENSE` (no stack signals). Asserts hint block is NOT emitted in stdout (no `=== mcp-recipes ===` framing line).
- [x] 8. Write `05-co-exists-with-011.sh`. Fixture: tmp dir with both stack signal (e.g. `next.config.js`) AND a fake `.claude/tools/probe.sh` (executable touch is sufficient). Pipes the same SessionStart payload through `.claude/hooks/session-start.sh` (which now should emit BOTH the runtime-introspect hint AND the mcp-recipes hint). Asserts both `=== runtime-introspect ===` AND `=== mcp-recipes ===` framing lines appear in stdout.
- [x] 9. Write `06-opt-out-env.sh`. Fixture: tmp dir with stack signal. With `CLAUDE_SKIP_MCP_RECIPES=1`, asserts hint NOT emitted. Without the env var, same fixture, asserts hint IS emitted (regression guard).
- [x] 10. Run `bash .claude/tests/mcp-recipes/run-all.sh`. Confirmed 0/6 PASS — all RED (hook absent at this phase).

### Phase 3 — Implementation

- [x] 11. Implement `.claude/hooks/mcp-recipes-hint.sh`. Phases: env-var escape hatch (`CLAUDE_SKIP_MCP_RECIPES=1` → exit 0 silent); resolve `CLAUDE_PROJECT_DIR`; run signal detection (see signal table below); if no signals match → exit 0 silent; emit single `=== mcp-recipes ===` block listing applicable recipes + the pointer to `.claude/rules/mcp-recipes.md`. Always exit 0.

   **Signal table:**
   - **Next.js:** any of `next.config.js`, `next.config.ts`, `next.config.mjs`, `next.config.cjs` exists OR `jq '.dependencies.next // .devDependencies.next // empty' package.json` non-empty → suggest `next-devtools-mcp` + `playwright-mcp`.
   - **Browser (non-Next):** `jq` on `package.json` matches any of `react`/`vue`/`svelte`/`vite`/`astro` in `dependencies` or `devDependencies`, AND Next signal is absent → suggest `playwright-mcp` + `chrome-devtools-mcp`.
   - **DB:** any of `schema.prisma`, `drizzle.config.{js,ts,mjs}`, `alembic.ini`, `database/migrations/`, `db/migrate/` exists OR `.env.example` contains a line matching `^DATABASE_URL=` → suggest `dbhub`.
   - Multiple signals can fire; the hint block lists the union of suggested recipes (Set-like dedup).

- [x] 12. Wire `.claude/settings.json`. Register `mcp-recipes-hint.sh` on `SessionStart`, after `session-start.sh` so the mcp-recipes block appears AFTER the SESSION.md / probe-hint block in the additional-context stream.
- [x] 13. Add new **Mcp recipes** § block to `CLAUDE.md` after the Runtime introspect block. One paragraph: what the capacity does, where the recipes live (`.claude/rules/mcp-recipes.md`), what the workflow is (`cp .mcp.json.example .mcp.json` + uncomment), how to opt out (`CLAUDE_SKIP_MCP_RECIPES=1`).
- [x] 14. Run `bash .claude/tests/mcp-recipes/run-all.sh`. Confirmed 6/6 PASS — GREEN (first-attempt, no impl bugs). Any failures → fix the implementation (not the tests), re-run until green.

### Phase 4 — Live verification on real-shape fixtures

Spec 011 had a real-fork dogfood pass. Spec 012 has no MCP-running dogfood (we ship recipes, not active servers), but we DO live-verify the hint shape against fixtures that closely resemble real forks. Adjustments here add to the test suite (per the "documented gotchas need defended counterparts" lesson from 011).

- [x] 15. Live-verify pass 1. Agent0 root → silent exit 0, no hint emitted. ✓
- [x] 16. Live-verify pass 2. Direct invocation against `/home/goat/shrnk` (Bun + TS, no signals expected) → silent exit 0. ✓ Should the hint fire? Walk the signal table — Bun project with a TS test stack, no react/vue/svelte/vite/astro deps, no Next. Hint should NOT fire. Confirm. If hint fires unexpectedly, that's a finding → write RED test → fix detector → re-run suite.
- [x] 17. Live-verify pass 3. Tmp fixture: `next.config.js` + `package.json` with `next` + `schema.prisma` → suggested `next-devtools-mcp` + `playwright-mcp` + `dbhub`, browser-non-Next branch correctly suppressed (Next signal dominates), playwright listed exactly once (dedup works). ✓ Should suggest `next-devtools` + `playwright` (Next branch) AND `dbhub` (DB branch). Confirm dedup works (no duplicate recipe names; both branches fire and merge cleanly).
- [x] 18. Live-verify pass 4. Co-existence with spec 011 — already exhaustively covered by test 05 (running both hooks + asserting both framing lines appear in combined SessionStart output). Plus additional ad-hoc passes: Vue + Vite (browser-non-Next branch fires correctly with playwright + chrome-devtools, no next-devtools), monorepo blind spot (next.config.js in apps/web/ correctly NOT detected at root — gotcha behaves as documented). ✓ stack signal + `.claude/tools/probe.sh` present. Invoke the full `session-start.sh` (not the mcp-hint hook alone) with synthetic stdin and confirm BOTH `=== runtime-introspect ===` AND `=== mcp-recipes ===` blocks appear.
- [x] 19. Passes 15-18 + ad-hoc 19-20 all 0-finding. No adjustments needed. Yield-decay satisfied (6 consecutive 0-finding live-verify passes).

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

### Live-verify pass 1 (Agent0 root, 2026-05-11)

0 findings. No stack signals at the Agent0 base → silent exit 0, no hint emitted. Confirms the "no false suggestions" non-goal.

### Live-verify pass 2 (`/home/goat/shrnk`, 2026-05-11)

0 findings. shrnk has `package.json` with only `@types/bun` + `typescript` in devDependencies — no Next, no react/vue/svelte/vite/astro, no `schema.prisma`, no DATABASE_URL. Detector correctly returns silent. Bun-only TS projects do NOT trigger the browser-non-Next branch by design (TS without a frontend framework isn't a browser-stack).

### Live-verify pass 3 (combined Next + Prisma fixture, 2026-05-11)

0 findings. Tmp fixture with `next.config.js` + `{"dependencies":{"next":...,"react":...,"prisma":...}}` + `schema.prisma` → hint surfaces 3 recipes (next-devtools-mcp + playwright-mcp + dbhub) without duplication. Browser-non-Next branch correctly suppressed (Next dominates). Signal label list reads: `next.config.js package.json:next schema.prisma`.

### Live-verify pass 4 (Vue + Vite, 2026-05-11)

0 findings. `{"devDependencies":{"vue":"^3.4","vite":"^5"}}` → browser-non-Next branch fires → playwright-mcp + chrome-devtools-mcp. No next-devtools-mcp (correctly skipped). Signal list stops at first dep match (`package.json:vue`) — deliberate to avoid signal-list bloat on fixtures with all five frameworks.

### Live-verify pass 5 (monorepo blind spot gotcha, 2026-05-11)

0 findings — gotcha behaves as documented. `apps/web/next.config.js` at depth-1 from `CLAUDE_PROJECT_DIR` is NOT detected (root-scan only). Hint silent. This is the documented monorepo caveat in `.claude/rules/mcp-recipes.md`; forks symlink or set `CLAUDE_PROJECT_DIR` at workspace level.

### Live-verify pass 6 (co-existence with spec 011)

0 findings. Covered exhaustively by test 05 (`05-co-exists-with-011.sh`) which invokes both `session-start.sh` AND `mcp-recipes-hint.sh` and asserts both framing lines appear. settings.json registers all three SessionStart hooks (session-start.sh + reminders-readout.sh + mcp-recipes-hint.sh) in order — real harness fires the full chain.

### Live-verify pass 7 (`/home/goat/pyshrnk`, 2026-05-11)

0 findings. **Pre-product-work** (Python-only project, `pyproject.toml` lists only `pytest>=8.0` + `mypy>=1.10`, no `next.config.*`, no `schema.prisma`, no `DATABASE_URL=` line in `.env*`): SessionStart fired with `=== REMINDERS ===`, `=== SESSION.md ===`, and `=== runtime-introspect ===` blocks but NO `=== mcp-recipes ===` block — confirming silent on no-signals as designed. **Post-product-work** (added Starlette + uvicorn + httpx via `uv add`, src/pyshrnk/web.py + tests/test_web.py): pyproject.toml gained Python ASGI dep entries — STILL no signals fired in the spec 012 detector table (no JS frameworks, no DB), so SessionStart correctly remained silent. Confirms the documented "Python web frameworks not in the signal table" design choice from `.claude/rules/mcp-recipes.md` § Stack-detector signal table — Starlette/FastAPI/uvicorn don't map to any of the four mature MCPs (Playwright still useful for the running Starlette server, but the table's browser-non-Next branch keys on JS deps in `package.json`, not Python ASGI).

**Cross-spec consideration (NOT a finding for spec 012, but worth recording):** when a Python project DOES grow a frontend that warrants Playwright validation (Starlette serving HTML, like pyshrnk now), the agent has no automated nudge to copy the Playwright recipe — they must read `.claude/rules/mcp-recipes.md` directly. Acceptable v1 trade-off: the recipe doc is one rule-doc click away, and Playwright auto-installs its own browser binaries so the friction is low. If a future signal shows Python forks consistently miss the Playwright opportunity, candidates to consider: (a) extend the detector table to fire on `pyproject.toml` deps `starlette|fastapi|flask|django` AND-gate with the existence of a template/static dir; (b) leave it documentation-only and trust the agent to pattern-match. v1 keeps it documentation-only; revisit on signal.
