# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 012-mcp-recipes delivered and validated.** Thirteen shipped capacities on `main`, all green. 6/6 scenario suite PASS first attempt; six 0-finding live-verify passes (Agent0 root silent / shrnk silent / Next+Prisma combined dedup / Vue+Vite browser-non-Next / monorepo blind spot gotcha / co-existence with 011) — yield-decay graduated. Commits: `7211855` → `9f70dd4`.

Two specs still draft, untracked carryovers from earlier work:
- **010-audit-forensics** — `spec.md` filled, awaiting user review.
- **013-lint-validator-extension** — `spec.md` filled out-of-band (today, 2026-05-11), I did not author it; treat as someone else's WIP.

## WIP

None on 012. The capacity ships as: `mcp-recipes-hint.sh` SessionStart hook + `.mcp.json.example` at repo root + `.claude/rules/mcp-recipes.md` full reference + 6 test scenarios + CLAUDE.md § block + settings.json wiring. Forks adopt Playwright / Chrome DevTools / DBHub / Next.js DevTools by copying `.mcp.json.example → .mcp.json` and uncommenting blocks.

## Next steps

1. **010-audit-forensics** still awaits user review of `spec.md`. Plan/tasks blocked until then.
2. **013-lint-validator-extension** out-of-band scaffold — needs context from whoever drafted it.
3. Possible follow-ups (no spec yet):
   - OpenTelemetry MCP, Grafana MCP, Filesystem MCP, Git MCP as additional recipes (spec 014?).
   - Per-stack `.mcp.json.<stack>.example` variants if the single-file approach hits friction.
   - Stack-detector v2: monorepo walk for `apps/*/` and `packages/*/` (deferred per spec 012 § Gotchas).

Deferred (carryover queue):
- Second cargo dogfood pass (graduation by yield-decay rule).
- Go dogfood pass (low expected yield).

## Decisions & gotchas

- **Spec 012 is pure recommendation, no audit log, no blocks.** Distinct shape from spec 011's runtime probe (which captures state). Recommendation capacities have a lower bar — they just suggest, the developer activates. No new gating primitives introduced.
- **MCP package names verified via WebFetch before authoring recipes** (Playwright `@playwright/mcp`, Chrome DevTools `chrome-devtools-mcp`, DBHub `@bytebase/dbhub`, Next.js DevTools `next-devtools-mcp`). Recipes use `@latest`; gotcha documents pin-manually-if-churn-hurts. Same lesson as 011 dogfood: verify upstream-source-of-truth before committing.
- **Stack-detector is shallow by design** (top-level files + `package.json` deps only). Monorepo blind spot is documented and ratified — fork developers symlink configs to root or point `CLAUDE_PROJECT_DIR` at the active workspace. v2 could walk depth-1 (`apps/*/`, `packages/*/`); deferred until real signal demands it.
- **jq is optional in mcp-recipes-hint.sh.** Falls back to permissive grep on `package.json` regex when jq is absent. Same fail-open shape as all other hooks. Verified by `02-browser-non-next.sh` running in test env without jq dependence.
- **`.mcp.json.example` is JSON-with-comments.** Strict JSON parsers reject `//` lines. The `.example` suffix is the universal "do not parse directly" signal; copy step is where the file becomes valid JSON. Documented prominently in the file's header AND in the rule doc gotchas.
- **DBHub `DATABASE_URL` is secret-adjacent.** Recipe documents: never commit `.mcp.json` with a populated `DATABASE_URL`; use env-var indirection or shell-export-before-launch. Same hygiene posture as `.env` handling.
- **TDD pattern held cleanly third time in a row** (specs 011, 012, plus the earlier secrets-scan and supply-chain rounds): RED tests written → impl → GREEN. Spec 012 was the cleanest run yet — 6/6 GREEN first attempt with no impl bugs surfacing. Indicates the spec quality + plan quality combo is paying off; the impl is mechanical when the RED tests are precise.
- **SessionStart hook count is now 3** (`session-start.sh` + `reminders-readout.sh` + `mcp-recipes-hint.sh`). Each emits its own block, independent. Order in settings.json controls visual order in additional-context.
- **SESSION.md auto-injection has a ~2KB preview budget.** Replace stale content rather than appending — `git log` is the audit trail.
