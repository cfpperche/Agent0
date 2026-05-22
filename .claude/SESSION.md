# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-21 (cont.) — spec 073 product-report-html shipped (uncommitted).**

`/product` now generates a navigable HTML reading surface. Built via `/goal` end-to-end: spec → plan → tasks → implement → validate → retroactive mei-saas run.

- **Spec 073 (`docs/specs/073-product-report-html/`) — status `shipped`.** All 13 tasks checked.
- **What it does:** a deterministic, zero-npm-dep generator (`scripts/build-report.ts`) reads `/product`'s `docs/` artifacts, packs them into one script-safe JSON blob, injects into `templates/report.html.tmpl` → `docs/REPORT.html`. Markdown renders client-side (CDN `marked`/`DOMPurify`/`highlight.js`/`mermaid@11`); mood screens embed as `<iframe>`. Single file, no server, no build.
- **SKILL.md wired** at 4 moments — `build-report.ts` runs before the 3 gates (steps 04/12/14) + terminal Phase 5; gate prose + handoff message point at `REPORT.html`. Best-effort, never blocks.
- **Validated:** 16/16 `bun:test`; Playwright-verified render (markdown→HTML, mermaid→SVG, hljs, iframes); idempotent (only `generated_at` differs) + partial-run-safe.
- **Retroactive mei-saas run done:** `/home/goat/mei-saas/docs/REPORT.html` (15/15, 17 entries `ok`) — generated after the parallel mei-saas dogfood reached `completed_at` (2026-05-22T01:58:15Z).
- **Post-ship QA hardening (2026-05-22):** browser QA surfaced 2 gaps, both fixed in `report.html.tmpl` + verified: #2 `hashchange` listener (back/forward + address-bar nav now work); #1 responsive `@media` drawer (sidebar collapses to a `☰` off-canvas drawer ≤720px). Suite 16→18. mei-saas `REPORT.html` regenerated with the fixes. QA #3 (favicon 404, cosmetic) left open.

## WIP (uncommitted)

Spec 073 — all in working tree, **not committed** (no commit was requested):
- New: `.claude/skills/product/scripts/build-report.ts`, `build-report.test.ts`, `.claude/skills/product/templates/report.html.tmpl`, `docs/specs/073-product-report-html/`
- Modified: `.claude/skills/product/SKILL.md`, `.claude/skills/product/references/pipeline-coverage.md`, `.claude/SESSION.md`

## Next steps

1. **Commit spec 073** (suggested: `feat(073): product-report-html — navigable HTML reading surface for /product`).
2. Spec 063 audit (worktree-isolated-subagents) — was open from a prior session; if already shipped+committed, skip.
3. Dated reminders: spec 029 05-30 · spec 035 06-07 · spec 046 07-01 · spec 060 07-19.

## Decisions & gotchas

- **`build-report.ts` reads `slug`/`stack` from `.state.json`** (fallback tier below `--slug`/`--stack` opts) — added after seeing the real mei-saas `.state.json` carries them. See `073/notes.md`.
- **Status from file presence, not `completed_steps`** — `.state.json.completed_steps` has an ambiguous element format; on-disk artifact presence is ground truth. `.state.json` consulted only for `blocked_steps`.
- **Playwright `file:` protocol is blocked** — browser verification used a local `python -m http.server`.
- **mei-saas dogfood Agent0-feedback** (from its `.state.json` partial_results, not actioned here): lo-fi + hi-fi per-screen budgets systematically miscalibrated for data-dense screens; Step 11 cost brief contradicts its own `schema.md`. Captured in mei-saas `docs/REPORT.md` § Dogfood findings — a future Agent0 calibration pass.

## Carryover (orthogonal — not touched this session)

- `.claude/REMINDERS.md` items per startup readout.
- Parked discussion: SOUL.md per sub-agent (delegation brief); `/product` full-stack expansion (caminhos A/B/C).
