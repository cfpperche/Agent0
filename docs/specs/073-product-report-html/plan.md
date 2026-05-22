# 073 — product-report-html — plan

_Drafted from `spec.md` on 2026-05-21. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build a deterministic generator script plus an HTML shell template, then wire the script into `/product`'s four reading moments.

The load-bearing design decision: **the build script never parses markdown.** It does file-IO + string templating only — reads each raw artifact, packs them into one script-safe JSON blob, injects it into `templates/report.html.tmpl`, writes `docs/REPORT.html`. The markdown→HTML rendering happens client-side in the browser via `marked` (loaded from CDN). This keeps the script at zero npm dependencies (Node/Bun stdlib only — `node:fs`, `node:path`), idempotent by construction, and matches the existing `sync-open-design.ts` convention (`bun scripts/<name>.ts`, no shebang, root resolved via `import.meta.url`).

`REPORT.html` is a single self-contained file living in `<out>/docs/` alongside its sibling artifacts. Layout: a left sidebar listing the 15 pipeline steps grouped by the 5 phases (each with a `✓ ◐ ✗ ·` status icon from `.state.json`), a main pane that renders the selected artifact, and a top bar with run metadata + coverage. The Overview entry renders the generated `REPORT.md`. Markdown artifacts render via `marked` → `DOMPurify` → `highlight.js` (+ `mermaid` for any fenced mermaid blocks); visual-contract HTML (`screens/*.html`, `screens/hifi/*.html`) embeds via relative-path `<iframe>`; `sitemap.yaml` / `data-flow.json` / `tokens.css` render as highlighted code blocks.

Build order: (1) `report.html.tmpl` shell, (2) `build-report.ts` generator with an exported pure core, (3) `build-report.test.ts` against a temp fixture, (4) wire the 4 invocations into `SKILL.md`, (5) one-line note in `pipeline-coverage.md`.

## Files to touch

**Create:**
- `.claude/skills/product/scripts/build-report.ts` — the generator. Exports a pure core (`buildReportHtml(docsDir, template) → string`, `ARTIFACT_MANIFEST`, `escapeForScriptTag`, `classifyArtifact`) for testability; a thin `main()` parses `--out`, resolves `<out>/docs`, writes `REPORT.html`. Invocation: `bun scripts/build-report.ts --out=<project-root>`.
- `.claude/skills/product/templates/report.html.tmpl` — the HTML shell: CSS (sidebar/main/topbar, light+dark), pinned CDN `<script>` tags (marked, DOMPurify, highlight.js, mermaid), client JS (parse the JSON blob, wire nav clicks, render on demand), and `{{GENERATED_AT}}` `{{SLUG}}` `{{STACK}}` `{{COVERAGE}}` `{{NAV}}` `{{REPORT_DATA}}` placeholders.
- `.claude/skills/product/scripts/build-report.test.ts` — `bun:test` suite against a temp fixture `docs/` dir (full run, partial run, idempotency, script-safety of the JSON blob, blocked-step status).

**Modify:**
- `.claude/skills/product/SKILL.md` — 4 invocation points: a new sub-step before `gate_discovery` (Phase 1), before `gate_specification` (Phase 2), before `gate_identity` (Phase 3), and a terminal invocation in Phase 5 after `.state.json` is finalized; the gate prose tells the user to review `docs/REPORT.html`, and the Phase 5 handoff message advertises it.
- `.claude/skills/product/references/pipeline-coverage.md` — one line noting `build-report.ts` consumes the artifact manifest and that `ARTIFACT_MANIFEST` in the script is the rendering-order source of truth.

**Delete:** none.

## Alternatives considered

### Build-time markdown rendering (script runs `marked` in Node, bakes HTML into `REPORT.html`)

Rejected. It would give a zero-runtime-dependency output file (pure HTML/CSS, no CDN), but it forces the build script to take an npm dependency on a markdown parser — breaking the "runs like `sync-open-design.ts`, stdlib only" property and requiring an install step in every fork. It also makes client-side mermaid rendering much harder (mermaid genuinely needs a browser). Client-side rendering keeps the script trivial and idempotent; the cost (a CDN fetch on open) is acceptable since `spec.md` § Non-goals already drops the offline-first requirement for v1.

### Vendored libs inlined into the template instead of CDN

Rejected for v1. Inlining `marked` (~12 KB) is cheap, but `mermaid` is ~3 MB — inlining it would bloat every `REPORT.html`. The user explicitly relaxed the offline constraint and approved third-party libs. CDN with pinned majors is simpler; vendoring stays documented as a later option (`spec.md` § Non-goals).

### A separate `references/artifact-manifest.json` file as the ordering source

Rejected. The 15-step pipeline is fixed; it only changes via a spec that already touches the script. A separate JSON file adds an indirection and a second thing to keep in sync with `pipeline-coverage.md`. A typed `const ARTIFACT_MANIFEST` inside `build-report.ts` is the single source; `pipeline-coverage.md` gets a one-line pointer to it.

### Mood screens base64-inlined via `<iframe srcdoc>` instead of relative `src`

Rejected. It would make `REPORT.html` portable in isolation, but the whole `docs/` tree already travels together and `REPORT.html` lives inside it. Relative-path `<iframe src>` is simpler and avoids escaping a full HTML document into an attribute.

## Risks and unknowns

- **CDN version drift / 404.** Pinned majors (`marked@14`, `dompurify@3`, `@highlightjs/cdn-assets@11`, `mermaid@11`) could move or a CDN could be unreachable. Mitigation: the report degrades to showing raw markdown in `<pre>` if `marked` fails to load (client JS guards `typeof marked`). Vendoring is the documented escape hatch.
- **`<script>`-tag escaping.** The raw markdown blob embedded as JSON must not contain a literal `</script>` or `<!--` that breaks out of the tag. Mitigation: `JSON.stringify(...)` then `.replace(/</g, '\\u003c')` — `escapeForScriptTag`, directly unit-tested.
- **Artifact path variance.** `screens/` holds a variable count of files (3-5); `design-system/` is a 3-file dir. The manifest entries must glob a directory, not assume a fixed filename. Handled by per-entry `kind` (`markdown` / `iframe-dir` / `code` / `dir-group`).
- **`.state.json` shape drift.** The script reads `completed_steps` / `blocked_steps`. If absent or malformed, it must degrade (treat every present file as `✓`, none blocked) — not crash.
- **Runtime assumption.** The script assumes `bun` is available, same as `sync-open-design.ts`. Acceptable — the skill already depends on it.

## Research / citations

- [marked vs markdown-it vs remark — PkgPulse 2026](https://www.pkgpulse.com/guides/marked-vs-remark-vs-markdown-it-parsers-2026) — `marked` is 12 KB gzip vs `markdown-it` 43 KB, ~34M weekly downloads, health 85/100; the fastest minimal-dependency choice for read-only HTML conversion.
- [npm-compare: markdown parsers](https://npm-compare.com/markdown-it,marked,remark,remarkable,showdown,turndown) — corroborates bundle size + adoption.
- [Mermaid — Usage / CDN](https://mermaid.ai/open-source/config/usage.html) — mermaid@11 ESM module from jsdelivr; custom `marked` renderer detects mermaid code blocks → `<pre class="mermaid">` for `mermaid.run()`.
- [mdp — marked + highlight.js + mermaid](https://ericlink.github.io/mdp/) — reference stack confirming `marked.parse()` → `DOMPurify.sanitize()` → `hljs.highlightElement()` is the standard client-side pipeline.
- `.claude/skills/product/scripts/sync-open-design.ts` — the in-repo precedent for a `bun`-run, stdlib-only, `import.meta.url`-rooted skill script with an exported pure core + `bun:test` suite.
