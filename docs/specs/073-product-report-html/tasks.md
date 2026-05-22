# 073 — product-report-html — tasks

_Generated from `plan.md` on 2026-05-21. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Write `.claude/skills/product/templates/report.html.tmpl` — HTML shell with CSS (sidebar/main/topbar, light+dark), pinned CDN tags (marked, DOMPurify, highlight.js, mermaid), client JS, and the `{{GENERATED_AT}}` `{{SLUG}}` `{{STACK}}` `{{COVERAGE}}` `{{NAV}}` `{{REPORT_DATA}}` placeholders.
- [x] 2. Write `.claude/skills/product/scripts/build-report.ts` — exported pure core (`ARTIFACT_MANIFEST`, `escapeForScriptTag`, `classifyArtifact`, `buildReportHtml`) + thin `main()` parsing `--out`, resolving `<out>/docs`, writing `REPORT.html`.
- [x] 3. Write `.claude/skills/product/scripts/build-report.test.ts` — `bun:test` suite: full run, partial run (missing artifacts → placeholders, no crash), idempotency (byte-identical except `generated_at`), `escapeForScriptTag` safety, blocked-step status.
- [x] 4. Wire `SKILL.md` invocation 1 — new sub-step before `gate_discovery` (Phase 1) running `build-report.ts`; gate prose points the user at `docs/REPORT.html`.
- [x] 5. Wire `SKILL.md` invocation 2 — before `gate_specification` (Phase 2).
- [x] 6. Wire `SKILL.md` invocation 3 — before `gate_identity` (Phase 3).
- [x] 7. Wire `SKILL.md` invocation 4 — terminal, Phase 5 after `.state.json` finalized; add `docs/REPORT.html` to the handoff message.
- [x] 8. Add the one-line `ARTIFACT_MANIFEST` ordering-source note to `references/pipeline-coverage.md`.

## Verification

- [x] 9. Run `bun test scripts/build-report.test.ts` from the skill dir — all tests pass (14 pass / 0 fail).
- [x] 10. Run `build-report.ts` against a synthetic full fixture `docs/` — `REPORT.html` exists; browser-verified via Playwright: 17 nav items (overview + 15 + sdd), markdown rendered (table), mermaid → SVG, hljs applied, mood-screen `<iframe>` loaded.
- [x] 11. Run `build-report.ts` against a partial fixture (steps 01-04 only) — steps 01-04 `ok`, 05-15 + sdd `pending`, no crash.
- [x] 12. Run `build-report.ts` twice against the same fixture — outputs differ only on the `generated_at` line (2 diff lines).
- [x] 13. Generated `REPORT.html` retroactively for the mei-saas dogfood — `/home/goat/mei-saas/docs/REPORT.html` (418 KB), run `completed_at` 2026-05-22T01:58:15Z. Browser-verified: 15/15 coverage, all 17 nav entries `ok`, `REPORT.md` rendered as Overview (7 tables), 5 hi-fi screens as `<iframe>`s, both Phase 5 SDD specs render via the `001-*` glob.

## Post-ship QA hardening (2026-05-22)

- [x] 14. QA finding #2 — `hashchange` listener: nav restructured so the URL hash is the single source of truth (cold load + address-bar edit + back/forward all re-render). Browser-verified.
- [x] 15. QA finding #1 — responsive `@media (max-width: 720px)` drawer: sidebar collapses to an off-canvas drawer with `☰` toggle + tap-to-close backdrop; pane full-width; no horizontal overflow. Browser-verified at 390px; desktop layout unchanged. Suite 16→18 (2 regression tests for the wiring).

## Post-ship fixes (2026-05-22)

- [x] 16. Step 15 ordering fix — reorder the Step 15 `ARTIFACT_MANIFEST` parts so the `screens/hifi/` iframe-dir leads `screen-atlas.md` (on the mei-saas run the hi-fi screens were buried ~10,429 px below the fold). One regression test; suite 18→19. Committed `675c3da`.
- [x] 17. Per-step sub-tabs — a multi-part step renders a sub-tab row; only the active tab's parts enter the DOM; the hash grammar extends to `#<id>/<tab-slug>` so tabs are deep-linkable and back/forward cycle them. Playwright-verified (Step 15 20,797 px → 4,186 px); 4 tests, suite 19→23. Committed `43f9d9f`.

## Notes

_Populated during execution — see `notes.md` for in-flight design decisions._
