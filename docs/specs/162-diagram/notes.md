# 162 — diagram — notes

_Created 2026-06-06._

_In-flight design memory for this spec — decisions, deviations, tradeoffs surfaced while building._

## Design decisions

### 2026-06-06 — parent — Chrome-less validation = deterministic structural check (not jsdom)

The meeting's "validation-only degradation" left open *how* to validate without Chrome. The research surfaced `mermaid.parse()` but that needs a DOM/jsdom in pure node — scope creep for v1. Chose a **deterministic structural check**: the first non-comment line (after stripping `%%` comments + blanks) must match a known Mermaid diagram-type keyword (`flowchart|sequenceDiagram|erDiagram|classDiagram|stateDiagram|...`). Real teeth (catches empty/garbage → `status=error`), zero deps, runs identically with or without Chrome. The full mmdc parse still catches deeper syntax errors when Chrome is present.

### 2026-06-06 — parent — system-Chrome reuse over puppeteer's bundled Chromium

`npx @mermaid-js/mermaid-cli` would otherwise download a full Chromium. The engine detects system Chrome (`google-chrome`/`chromium`/...), writes a puppeteer config `{"executablePath":...,"args":["--no-sandbox","--disable-gpu"]}` passed via `--puppeteerConfigFile`, and sets `PUPPETEER_SKIP_DOWNLOAD=1` so npx pulls only the JS package. Keeps acquisition light; absent Chrome → validation-only degrade.

### 2026-06-06 — parent — inline text persisted as a tracked .mmd

Diagrams are keepers (meeting decision), so when the source is inline text (not a file), the engine writes `<out>/<stem>.mmd` next to the render — the source is the durable, editable artifact and belongs in git. File sources are used in place (not duplicated); the manifest `source` points at the original path.

## Deviations

### 2026-06-06 — parent — no Agent0 self-baseline; COPY_CHECK gitkeep is the only sync wiring

As with specs 160/161, `.agent0/harness-sync-baseline.json` is consumer-side (written on `--apply`); Agent0 has none. The `*.sh` tool glob + recursive skills/context/tests globs already carry `diagram.sh`/SKILL/rule/tests; only `assets/diagrams/.gitkeep` needed an explicit `COPY_CHECK_FILES` entry. **Consumer sync is founder-triggered AFTER this dogfood** (minority-report gate — now satisfied).

## Tradeoffs

### 2026-06-06 — parent — Mermaid-only despite d2 being installed locally

`d2` is present on this dev box (single Go binary, no Chrome — operationally cleaner). Held the meeting's accepted decision: Mermaid for v1 (agent authoring fluency + one-syntax family coverage); d2-first stays the documented reopen-trigger if Chrome-dep pain dominates. Did not deviate to the locally-convenient engine.

## Open questions

_None outstanding — all four spec OQs resolved at build/dogfood (see spec.md § Open questions)._

---

**Dogfood evidence (real fal-free local renders, env had google-chrome):**
- architecture (Agent0 capability family) → `assets/diagrams/diagram-architecture-d41cd180.svg` (20 KB)
- sequence (/diagram render+degrade flow) → `.../diagram-sequence-46b67ece.svg` (28 KB)
- ERD (Agent0 spec artifact model) → `.../diagram-erd-39584a72.svg` (34 KB)
- **Error path proven LIVE:** the first architecture attempt used `[/image...]` (Mermaid parallelogram-shape collision) → real `mmdc` syntax error → `status=error`, source kept, diagnostic surfaced (not just my structural pre-check — the deep mmdc parse). Fixed with quoted labels → rendered.
- No-Chrome degrade + structural-error paths proven in the offline suite (39 assertions, 5 scenarios).

**Validation:** offline 39 assertions / 5 scenarios PASS; `/skill validate` rc 0 (desc trimmed ≤1024); `doctor` 22 ok / 0 advisory / 0 broken (`diagram` = render-ready).

**Family position:** `/diagram` joins the structured-capacity family as the deterministic technical-visual member — `/transcribe`-class local/free, sibling of `/video --mode code`, counterpart to `/image`. Consumer-facing → founder-triggered harness-sync (dogfood gate satisfied).
