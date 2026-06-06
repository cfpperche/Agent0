# 162 — diagram

_Created 2026-06-06._

**Status:** shipped

<!-- Non-UI capacity (a CLI/skill utility that emits diagram asset files). No visual-contract gate. -->
**UI impact:** none

## Intent

Add `/diagram` — **deterministic technical-visual generation** (architecture, flowchart, sequence, ER, class, state diagrams) from a **text source** (Mermaid), rendered **locally, zero-cost, git-trackable**. It is the **deterministic sibling of `/video --mode code`** and the **technical-visual counterpart to `/image`** (which is organic/photo/raster, paid): `/diagram` compiles a text spec → SVG/PNG, statically and reproducibly, with no paid lane. Following the established structured-capacity contract, it is a **`/transcribe`-class LOCAL/FREE utility** (provenance manifest, not a cost ledger; no `FAL_KEY`/tiers/`--confirm-cost-usd`). The pull is structural and consumer-facing: `/product` already emits `system-design`/`sitemap-IA`/`OST` as prose with no diagrams and SDD specs want architecture diagrams (the in-repo consumer), but the principal value is **via consumer products — especially cognixse, which serves software-development companies that ship diagrams as product artifacts** (mei-saas benefits too). Decided in the decision-grade meeting `.agent0/meetings/diagram-capacity-technical-visuals-2026-06-06T22-34-59Z/` (blind openings converged independently; ledger 7 claims / 0 assertion-only; `synthesis: accepted`). Spec graduated from that meeting.

## Acceptance criteria

- [ ] **Scenario: render a Mermaid diagram to a tracked SVG asset (the happy path)**
  - **Given** Node + a usable headless Chrome/Chromium are available and a `.mmd` source (or inline Mermaid text)
  - **When** `/diagram <source.mmd>` (or `/diagram "<mermaid text>" --kind flowchart`)
  - **Then** the source is rendered via `mmdc` (acquired through `npx`, no global install) to an `.svg` placed in the resolved output dir, a provenance manifest line is recorded (source sha, kind, engine, output, `stayed_local:true`), and result `status=ok` — **no cost is printed, no key is required** (this is a free local utility)

- [ ] **Scenario: Chrome/mmdc absent — degrade to validation-only, never a dead capacity**
  - **Given** Node is present but no usable Chrome/Chromium (or `mmdc` cannot be acquired)
  - **When** `/diagram <source.mmd>`
  - **Then** the tool still **parses/validates the Mermaid source and keeps the tracked `.mmd`**, and returns `status=unavailable` **for the render step** with a one-line install hint (Chrome/Node) — it reports, never crashes; the source artifact is preserved

- [ ] **Scenario: invalid Mermaid source — honest error, no broken output**
  - **Given** a `.mmd` with a syntax error
  - **When** `/diagram <source.mmd>`
  - **Then** result `status=error` naming the parse failure; no partial/corrupt SVG is written; the manifest records the failed call

- [ ] **Scenario: format selection (SVG default, PNG/PDF optional)**
  - **Given** a valid source
  - **When** `/diagram <source.mmd> --format png`
  - **Then** a `.png` is produced (SVG is the default; PNG/PDF are optional generated artifacts)

- [ ] **Scenario: storage convention — spec-owned vs reusable product diagram**
  - **Given** a diagram tied to a spec vs a reusable product diagram
  - **When** rendered with the default placement vs `--out <dir>` / an `--asset`-class flag
  - **Then** spec-owned diagrams land under `docs/specs/NNN-*/diagrams/` and reusable product diagrams under `assets/diagrams/`; the `.mmd` source is tracked (it is the real artifact) and the rendered SVG is tracked when embedded in docs — **diagrams are keepers, so there is no gitignored throwaway-draft class by default** (this replaces `/image`'s draft-vs-asset split)

- [ ] `--kind flowchart|sequence|erd|class|state|architecture` (Mermaid families); `--format svg|png|pdf` (default svg); `--out <dir>`; `--theme <mermaid-builtin>` (minimal built-in-theme passthrough only); `--json`; `--exit-code` (`ok=0 unavailable=2 error=3`; default exit 0). Status `ok|unavailable|error` decoupled from exit code.
- [ ] Source language is **Mermaid only** in v1 (LLM fluency + one syntax covers the families). d2 / graphviz / Kroki are **not** in v1.
- [ ] Dual shape: `/diagram` skill + runtime-neutral `.agent0/tools/diagram.sh` (Codex/CI call it directly). `doctor`/`caps` report Node + `mmdc`-acquirability + usable-Chrome (tri-state, never fails the harness).
- [ ] Provenance manifest (gitignored JSONL), one line per call (success AND failure): `{ts,status,source_sha256,kind,format,engine,output,stayed_local:true}`. No cost fields, no key.
- [ ] Passes `/skill` agentskills.io compliance; portability tier `agentskills-portable`. Sibling capacity rule `diagram.md`.
- [ ] **Consumer-ship gate (minority report):** do NOT harness-sync `/diagram` to consumers until a v1 dogfood renders 2–3 real artifacts end-to-end (an architecture diagram, a sequence, an ERD) and proves the asset path.

## Non-goals

- **A second source language (d2 / graphviz / Kroki) in v1** — Mermaid only. d2-first is a documented **reopen-trigger** if dogfood shows Chrome/Puppeteer pain dominates (Kroki violates the local/free posture: remote = network dep, local = a server/container surface before the need is proven).
- **Replacing GitHub/GitLab native Mermaid rendering** — the value is a tracked SVG/PNG **asset** for surfaces with no live renderer (product UI/docs/slides/PDF, marketing) plus `.mmd` validation + pinned reproducibility, NOT a README-renderer substitute.
- **A paid lane / cost apparatus** — `/diagram` is free/local by nature; no `FAL_KEY`, tiers, or `--confirm-cost-usd` (the `/image`-class apparatus does not apply).
- **Design / styling work** — only minimal built-in-theme passthrough; anything past that (custom visual identity, layout craft) is design work belonging to `/frontend-designer`.
- **Semantic/architecture correctness** — the renderer compiles syntax, not truth; `/diagram` produces **generated documentation requiring review**, never proof that an architecture is correct.
- **`/product` auto-emit of diagrams from system-design** — explicitly **v2**, out of v1 scope (don't let it creep the v1).
- **Animated / interactive diagrams** — static output only (motion is `/video --mode code`).

## Open questions

_All resolved at build/dogfood (2026-06-06). See `notes.md` for live-call evidence._

- [x] **Render path + acquisition + the validation-only degradation contract** — RESOLVED: `npx -p @mermaid-js/mermaid-cli mmdc` (the `-p` flag is required), reusing **system Chrome** via a generated puppeteer config + `PUPPETEER_SKIP_DOWNLOAD=1` (no second-browser download). The Chrome-less validation is a **deterministic structural check** (first non-comment line names a known Mermaid diagram type) — real teeth without jsdom. Proven live: real flowchart/sequence/ERD/architecture renders, plus the no-Chrome degrade (source kept, `status=unavailable`).
- [x] **Storage convention exactness** — RESOLVED: default `assets/diagrams/` (tracked, reusable); spec-owned via `--out docs/specs/NNN-*/diagrams/`. The `.mmd` source is always tracked (inline text persisted as `<stem>.mmd`); rendered SVG tracked when embedded. **No draft/throwaway class** — diagrams are keepers; only the manifest is gitignored.
- [x] **Result-JSON / `caps` / `doctor` shape (thin-glue defense)** — RESOLVED: `--json` returns `{status,output,source,kind,format,engine,stayed_local}`; `caps` reports node/mmdc/chrome/formats/source_lang; `doctor` tri-state (render-ready / validation-only / no-node); manifest one-line-per-call incl. failures; status decoupled from exit. The structured surface (not the one-line `mmdc` call) is the capacity.
- [x] **Auto-acquire vs hint** — RESOLVED: npx-ephemeral acquire (the `/video` HyperFrames-npx posture), with `DIAGRAM_MMDC`/`DIAGRAM_CHROME_BIN` overrides; degrades to a hint when Node/Chrome absent.

## Context / references

- **Graduating meeting (decision-grade, spec-149 protocol):** `.agent0/meetings/diagram-capacity-technical-visuals-2026-06-06T22-34-59Z/meeting.md` — blind openings converged independently on build-now/Mermaid/local-free/clean-boundary/spec-graduation/thin-glue-kill-risk; ledger 7 claims / 0 assertion-only (5 supported anchored, 2 unresolved gated on dogfood); minority report (no measured consumer demand yet → dogfood-before-consumer-ship) preserved; `synthesis: accepted`.
- **Structured-capacity pattern to mirror:** `.agent0/context/rules/transcribe.md` + `.agent0/tools/transcribe.sh` (local/free, provenance not cost, status-decoupled, doctor/caps, honest degradation) — the closest sibling. `/video --mode code` (`.agent0/context/rules/video-gen.md`) for the deterministic-source + npx-acquisition + headless-Chrome precedent.
- **Boundary peers:** `.agent0/context/rules/image-gen.md` (organic raster, paid — the contrast); `/frontend-designer` (design work — the styling boundary).
- **In-repo consumer:** `.claude/skills/product/SKILL.md` (`/product` emits system-design/sitemap-IA/OST as prose); SDD specs (architecture diagrams).
- **Mermaid / mmdc:** `@mermaid-js/mermaid-cli` (`mmdc`) — Mermaid → SVG/PNG/PDF, needs headless Chrome/Puppeteer. d2 (Terrastruct, single Go binary) + Graphviz (`dot`) noted as rejected v1 alternatives / reopen-triggers. Verify exact package/flags + Chrome-less validation path at `/sdd plan`.
