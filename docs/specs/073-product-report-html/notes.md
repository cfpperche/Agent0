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

### 2026-05-22 — parent — Post-ship fix: Step 15 leads with the hi-fi screens, not the atlas

A founder review of the mei-saas `REPORT.html` reported the hi-fi screens "missing". They were not missing — they were buried. Step 15's `ARTIFACT_MANIFEST` entry ordered the parts `screen-atlas.md` → `screens/hifi/` (iframe-dir) → `fixture-spec.md`. On the real mei-saas run `screen-atlas.md` renders **~10,283 px tall** (27-route index table + several sections), pushing the first hi-fi iframe to offset **~10,429 px** — roughly 7 viewports below the fold. A reader clicking Step 15 sees only markdown tables and concludes the only screens in the run are Step 02's lo-fi set. Fix: reorder the Step 15 parts so the `screens/hifi/` iframe-dir leads, mirroring Step 02 (which already puts `direction-a.html` + `screens/` first). Principle, recorded in a code comment on the entry: *within a step, iframe parts precede long prose.* Verified via Playwright — the first hi-fi iframe now sits at offset **76 px**. One regression test added (`step 15 leads with the hi-fi screens, before screen-atlas.md`, asserting `firstIframe < firstMd`); suite 18→19. Pure ordering fix — no new scenario, spec stays `shipped`.

### 2026-05-22 — parent — Post-ship feature: per-step sub-tabs

The Step 15 reorder above made the hi-fi screens visible but did not fix the root cause — a multi-part step renders all its parts stacked in one pane. On the mei-saas run Step 15 was a 20,797 px scroll (5 hi-fi iframes + a ~10,283 px `screen-atlas.md` + `fixture-spec.md`). A founder review asked for a real fix.

Three approaches were considered (sticky jump-nav / parts as nested sidebar entries / sub-tabs); the founder picked sub-tabs. Each manifest part becomes one tab; clicking a tab renders only that tab's parts, so the active view is never the whole step. The tab is deep-linkable — the hash grammar extended from `#<id>` to `#<id>/<tab-slug>`, consistent with the QA #2 "hash is the single source of truth" model, so back / forward cycle tabs as well as artifacts. Slugs are computed deterministically from the manifest path (`tabSlugFor`), so a deep link survives regeneration.

Build-side: the payload gained a `tabs` list per artifact + a `tabSlug` per part; `resolveEntry` tags every resolved part (an `iframe-dir` still fans out to N parts, all sharing the parent tab). The two `iframe-dir` manifest labels were shortened to `Lo-fi screens` / `Hi-fi screens` so they read as tab labels. Verified via Playwright: Step 15 dropped **20,797 px → 4,186 px**; single-part steps render no tab row (unchanged); tab clicks drive the hash; `#15/screen-atlas` deep-links cleanly. Four tests added (suite 19→23). Spec stays `shipped` — one post-ship `[x]` scenario added to `spec.md`, mirroring the QA-hardening precedent.

### 2026-05-22 — parent — Post-ship feature: HTML artifacts inlined via `srcdoc` (filesystem portability)

The mei-saas dogfood flagged a real asymmetry: text artifacts (`.md`/`.json`/`.yaml`/`.css`) were inlined as strings in the payload — portable — but HTML artifacts (`direction-a.html`, `screens/`, `screens/hifi/`) were embedded via `<iframe src="relative-path">`. So `REPORT.html` *looked* like a shareable single file (13/15 steps survive a move) but the 2 visual steps broke **silently** — blank iframe, no error — the moment the file was separated from its siblings. Partial self-containment is the trap.

This reverses the `plan.md` "relative `src`" alternative (the § Alternatives entry now records the reversal). Each iframe artifact's verbatim HTML is read at build time and carried in the payload as `srcdoc`; the client sets `iframe.srcdoc` as a DOM property. Key simplification over the original dogfood suggestion: because the value is set as a *property* (not interpolated into an HTML-attribute string), **no manual `&`/`"` escaping is needed** — the existing `JSON.stringify` + `escapeForScriptTag` layers cover it, and `JSON.parse` + property-set round-trips cleanly (a screen containing `</script>` stays contained — regression-tested).

Sandbox moved `allow-same-origin` → `allow-scripts`: `srcdoc` content with its own JS runs in an opaque-origin sandbox; the two tokens are never paired (pairing them lets framed content drop its own sandbox). The per-iframe "open ↗" link — the last non-portable thread — became a blob-URL opener.

Scope is deliberate: this closes **filesystem-move** portability, not offline. The CDN libs (`marked`/`highlight.js`/`mermaid`) remain a network dependency — a separate, already-deferred non-goal. Cost: mei-saas `REPORT.html` 420 KB → 769 KB; no `artifact-budgets` impact (spec 075 retired the budget cascade, and `REPORT.html` is script-generated, not a sub-agent artifact, so the catastrophe cap does not apply). Verified via Playwright including the decisive move test — `REPORT.html` copied alone to a bare directory still renders steps 02/15. Two tests added + one updated (suite 23→25). Spec stays `shipped`; the `spec.md` HTML-embed scenario was corrected and one post-ship `[x]` scenario added.

### 2026-05-21 — parent — Status derived from file presence, not `completed_steps`

`plan.md` § Risks said the script "reads `completed_steps` / `blocked_steps`". In practice `completed_steps` has an ambiguous element format (observed in the real mei-saas run as `"15-screen-atlas"`, `"02-prototype"` — step-number-plus-slug, not a bare number). Rather than parse that, status is derived purely from on-disk artifact presence (`ok` = all parts present, `partial` = some, `pending` = none). `.state.json` is consulted **only** for `blocked_steps` (the one signal not inferable from the filesystem). This is more robust — a file on disk is ground truth that the step produced output — and sidesteps the format-drift risk entirely.

## Deviations

### 2026-05-21 — parent — `build-report.ts` reads slug + stack from `.state.json`

`plan.md` specified `main()` defaults: slug → `basename`, stack → `"—"`. Inspecting the real mei-saas `.state.json` showed it already carries `slug` and `flags.stack`. Added a fallback tier so the resolution order is `--slug`/`--stack` opt → `.state.json` → `basename`/`"—"`. This makes the retroactive / manual invocation produce correct run metadata without the caller having to pass flags. `SKILL.md` still passes `--slug`/`--stack` explicitly at the pipeline call sites (they win). Covered by two added tests (`slug/stack metadata` describe) — suite is 16/16.

## Tradeoffs

_None surfaced beyond those weighed at plan time (`plan.md` § Alternatives considered)._

## Open questions

_None open. The `file:` protocol is blocked for the Playwright MCP, so browser verification was done over a local `python -m http.server` — noted here only as the verification method, not a blocker._
