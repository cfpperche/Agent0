# 132 — video-skill — notes

_Created 2026-05-31._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building**._

## Design decisions

### 2026-05-31 — parent — HyperFrames is project-based; we own a minimal offline composition template

Spike (`npx hyperframes@0.6.64 --help` + `init` + `doctor`) confirmed HyperFrames is **project-scaffold-based**, not loose-HTML. `hyperframes init <dir>` writes: `index.html` (the composition), `hyperframes.json` (project config — schema/registry/paths), `package.json` (npm scripts pinning `hyperframes@0.6.64`), `meta.json` (id/name/createdAt), plus its own `CLAUDE.md`/`AGENTS.md` and a prompt to run `npx skills add heygen-com/hyperframes` (the upstream agent-skill we deliberately do NOT depend on — debate R1).

Composition format: `<div id="root" data-composition-id="main" data-start data-duration data-width data-height>` containing `.clip` divs with `data-start`/`data-duration`/`data-track-index`, animated via a paused GSAP timeline at `window.__timelines["main"]`.

**Decision:** `code.sh scaffold` copies our **own** `references/composition-template/` (a hand-authored, pinned, minimal HyperFrames project) into `assets/video/compositions/<slug>/`, rather than calling `hyperframes init` (which is interactive-ish, pulls registry, and injects the upstream-skill nudge). This is the "owned authoring layer" — we depend on the npm **engine** (`render`/`doctor`/`lint`) but ship our own starter + `authoring.md`. `code.sh render` runs `npx hyperframes@<pin> render -o <abs.mp4>` from the composition dir.

### 2026-05-31 — parent — dep-check delegates to `hyperframes doctor`

`hyperframes doctor` already checks Node/ffmpeg/ffprobe/Chrome/disk/shm and exits non-zero on missing deps. `code.sh doctor` wraps it instead of re-implementing dep detection. This env passed all checks (Node 24, ffmpeg 7, puppeteer Chrome) — enabling a real gold-standard render during validation.

## Deviations

_(none yet)_

## Tradeoffs

### 2026-05-31 — parent — GSAP via CDN in the starter = a determinism caveat, accepted for v1

The HyperFrames starter loads GSAP from `cdn.jsdelivr.net`. That is an external URL → render needs network and is not hermetic (exactly the "external URLs" fingerprint risk Codex raised in debate Q4). v1 keeps the CDN for simplicity but the render fingerprint records it; vendoring GSAP locally is a documented future hardening, not a v1 blocker.

## Open questions

### 2026-05-31 — parent — exact `render` output flag confirmed; default-path behavior not

`render -o <path>` sets output (from `--help` examples). Whether bare `render` writes a deterministic default path is unconfirmed; `code.sh` always passes `-o` so it never relies on the default.
