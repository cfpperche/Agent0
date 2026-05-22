# 073 — product-report-html — notes

_Created 2026-05-21._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention._

## Design decisions

### 2026-05-21 — parent — A 16th `sdd` manifest entry for the Phase 5 handoff specs

`plan.md` framed the report around "the fixed 15-step pipeline". While writing `ARTIFACT_MANIFEST` it was clear the founder also wants the Phase 5 output visible — the umbrella + foundation specs are the engineering entry point. Added a 16th entry (`id: 'sdd'`, `phase: 5`) pointing at `specs/001-*/spec.md` + `specs/002-foundation/spec.md`. The `001-*` path needs a glob, so a minimal `globRelative()` helper resolves a single `*` segment by directory listing. Coverage stays `N/15` (only the numbered pipeline steps count); the `sdd` and `overview` entries are navigable but excluded from the coverage figure.

### 2026-05-22 — parent — Post-ship QA hardening: hashchange nav + responsive drawer

A browser QA pass on the mei-saas `REPORT.html` (2026-05-22) surfaced two gaps not caught by the unit tests (which assert generator output, not runtime page behaviour):

- **No `hashchange` listener** — deep-linking worked on cold load, but once open, address-bar hash edits and browser back/forward didn't re-render. Fixed by making the URL hash the single source of truth: nav clicks set `location.hash`, a `hashchange` listener calls `openArtifact()`. The old `replaceState`-per-click is kept only for the initial-load default. Back/forward now cycle artifacts.
- **No responsive layout** — at ≤720px the fixed 270px sidebar crushed the content pane to ~105px. Fixed with a `@media (max-width: 720px)` block: the sidebar becomes an off-canvas drawer (`position: fixed`, `translateX(-100%)`), toggled by a `☰` button in the topbar, with a tap-to-close backdrop. Desktop layout unchanged.

Both verified via Playwright (cold-load / address-bar / back / forward; drawer open-close via hamburger, backdrop, and nav-click; desktop sticky sidebar intact). Two regression tests added asserting the generated HTML carries the wiring — suite 16→18. Spec was already `shipped`; the two scenarios were added to `spec.md` § Acceptance criteria as post-ship `[x]` entries rather than reopening the spec.

### 2026-05-21 — parent — Status derived from file presence, not `completed_steps`

`plan.md` § Risks said the script "reads `completed_steps` / `blocked_steps`". In practice `completed_steps` has an ambiguous element format (observed in the real mei-saas run as `"15-screen-atlas"`, `"02-prototype"` — step-number-plus-slug, not a bare number). Rather than parse that, status is derived purely from on-disk artifact presence (`ok` = all parts present, `partial` = some, `pending` = none). `.state.json` is consulted **only** for `blocked_steps` (the one signal not inferable from the filesystem). This is more robust — a file on disk is ground truth that the step produced output — and sidesteps the format-drift risk entirely.

## Deviations

### 2026-05-21 — parent — `build-report.ts` reads slug + stack from `.state.json`

`plan.md` specified `main()` defaults: slug → `basename`, stack → `"—"`. Inspecting the real mei-saas `.state.json` showed it already carries `slug` and `flags.stack`. Added a fallback tier so the resolution order is `--slug`/`--stack` opt → `.state.json` → `basename`/`"—"`. This makes the retroactive / manual invocation produce correct run metadata without the caller having to pass flags. `SKILL.md` still passes `--slug`/`--stack` explicitly at the pipeline call sites (they win). Covered by two added tests (`slug/stack metadata` describe) — suite is 16/16.

## Tradeoffs

_None surfaced beyond those weighed at plan time (`plan.md` § Alternatives considered)._

## Open questions

_None open. The `file:` protocol is blocked for the Playwright MCP, so browser verification was done over a local `python -m http.server` — noted here only as the verification method, not a blocker._
