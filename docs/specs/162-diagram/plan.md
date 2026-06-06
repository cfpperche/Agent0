# 162 — diagram — plan

_Drafted from `spec.md` on 2026-06-06. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build `/diagram` as a `/transcribe`-class dual shape: thin `.agent0/skills/diagram/SKILL.md` over a runtime-neutral `.agent0/tools/diagram.sh`. The engine compiles a **Mermaid** source (`.mmd` file OR inline text) to SVG/PNG/PDF via **`mmdc`**, acquired ephemerally through **`npx -p @mermaid-js/mermaid-cli mmdc`** (the `-p` flag is required because the package name ≠ the command — verified) — the `/video` HyperFrames-npx posture, no global install. No paid lane, no cost apparatus; a provenance manifest, not a cost ledger.

**The render-path decision (THE risk, resolved by research).** `mmdc` renders inside headless Chrome via Puppeteer. Two acquisition-weight traps and their mitigations:
1. Puppeteer would otherwise download its own ~Chromium on `npx` install. We **reuse system Chrome**: detect a system browser (`google-chrome`/`chromium`/`chromium-browser`), write a tiny puppeteer config (`{"executablePath":"<browser>","args":["--no-sandbox"]}`) and pass it via `mmdc --puppeteerConfigFile`, and set `PUPPETEER_SKIP_DOWNLOAD=1` so the npx install pulls only the JS package, not a second browser.
2. **Validation-only degradation (the meeting's key resolution).** When no usable Chrome is found, the capacity does NOT die: it **preserves the tracked `.mmd` source** and returns `status=unavailable` for the *render step* with a one-line install hint. Best-effort syntax validation via Mermaid's `parse()` is attempted where it runs cleanly in node, but the load-bearing promise is "source kept + honest unavailable," not a guaranteed Chrome-less parse.

**Storage (the meeting's adopted split).** Spec-owned diagrams default under `docs/specs/NNN-*/diagrams/`; reusable product diagrams under `assets/diagrams/` (via `--out` / asset placement). The `.mmd` source is always tracked (it is the real artifact); rendered SVG is tracked when embedded in docs. **Diagrams are keepers — no gitignored throwaway-draft class** (the deliberate departure from `/image`'s draft-vs-asset split). The manifest is the only gitignored, per-machine artifact.

Build order: engine skeleton (parse args / caps / doctor) → system-chrome detection + puppeteer-config + npx mmdc render → validation-only degradation + status/exit decoupling → storage placement + provenance manifest → offline tests (fake mmdc + fake browser detection) → SKILL/rule/symlinks → wiring → validate → dogfood 3 real diagrams (env has google-chrome). **Stop before harness-sync** (the minority-report consumer-ship gate).

## Files to touch

**Create:**
- `.agent0/tools/diagram.sh` — engine: arg parse (`--kind`, `--format svg|png|pdf`, `--out`, `--theme`, `--json`, `--exit-code`); source resolve (`.mmd` path or inline text → temp `.mmd`); system-chrome detect → puppeteer-config; `npx -p @mermaid-js/mermaid-cli mmdc -i <src> -o <out> [--puppeteerConfigFile cfg] [-t theme]`; validation-only degradation when no chrome; storage placement (spec-dir default vs `--out`/asset); provenance manifest (JSONL, one line/call incl. failure, `stayed_local:true`); status `ok|unavailable|error` decoupled from exit; `doctor`/`caps`.
- `.agent0/skills/diagram/SKILL.md` — skill entry (tier `agentskills-portable`); surface `/diagram <source.mmd|"<text>"> [--kind ...] [--format svg|png|pdf] [--out <dir>] [--theme <mermaid-builtin>] [--json] [--exit-code]` + `doctor`/`caps`.
- `.agent0/context/rules/diagram.md` — capacity rule (deterministic technical visuals, `/transcribe`-class local/free, Mermaid-only v1, system-chrome reuse, validation-only degradation, storage split, boundary vs /image + /video code-mode + /frontend-designer, non-goals + reopen-triggers incl. d2-first).
- `.agent0/tests/diagram/` — offline suite with a fake `mmdc` + fake browser-detection (env override): render-ok-svg, no-chrome→validation-only-degrade, invalid-source→error, format png, storage split (spec-dir vs `--out`), manifest one-line-per-call + no-key, `--kind`/`--json`/`--exit-code` mapping.
- Symlinks `.claude/skills/diagram` + `.agents/skills/diagram`.
- `assets/diagrams/.gitkeep` — tracked reusable-diagram dir.

**Modify:**
- `.agent0/tools/diagram.sh` deps note in `.agent0/tools/doctor.sh` — `diagram` check (node + npx + mmdc-acquirability + usable-chrome; tri-state, never fails harness).
- `.gitignore` — the per-machine provenance manifest (`assets/generated/.diagram-manifest.jsonl`) + any scratch render temp; `assets/diagrams/` itself is NOT ignored (keepers), only its manifest. (No `assets/generated/diagrams/` throwaway class by design.)
- `CLAUDE.md` + `AGENTS.md` — `## Diagram` managed-index block (parity).
- `.agent0/tools/sync-harness.sh` `COPY_CHECK_FILES` — add `assets/diagrams/.gitkeep`. (The `*.sh` tool glob + recursive skills/context/tests globs already carry the rest.) **But do NOT ship to consumers until the dogfood gate passes** — the COPY_CHECK entry is wiring; the actual consumer sync is founder-triggered after dogfood.
- `.agent0/skills/sdd/templates/` — _(no change v1)_ `/product` auto-emit is v2.

**Delete:** none.

## Alternatives considered

### d2 (single Go binary, no Chrome) as the v1 engine

Rejected for v1 (it is the documented reopen-trigger). d2 is operationally cleaner — a single binary, no Chrome — and is even installed on this dev box. But the meeting converged (independently, both runtimes) on **Mermaid** for v1 because the agent *writes* these and Mermaid is the language LLMs are most fluent in, covering all requested families (flowchart/sequence/ER/class/state) in one syntax. d2-first is the **reopen-trigger** if dogfood shows the Chrome/Puppeteer dependency pain dominates. Choosing d2 now would trade the agent's authoring fluency for an operational convenience the system-chrome-reuse mitigation already blunts.

### Puppeteer downloads its own Chromium (default npx behavior)

Rejected. The default `npx @mermaid-js/mermaid-cli` pulls a full Chromium (~heavy) on first run. We instead reuse the system browser via a puppeteer config `executablePath` + `PUPPETEER_SKIP_DOWNLOAD=1`, keeping acquisition to just the JS package. Falls back to whatever Chrome the user has; if none, the validation-only degradation fires rather than a multi-hundred-MB download.

### Kroki multi-engine server

Rejected (meeting). Remote Kroki violates the local/free posture (network dep); local Kroki adds a server/container surface before the need is proven. Mermaid + local render keeps it a self-contained utility.

### A gitignored draft class like /image

Rejected (meeting). Diagrams are keepers — the `.mmd` source is the durable artifact and belongs in git from the first render. A throwaway-draft class would mis-model the lifecycle; tracked-by-default is correct.

## Risks and unknowns

- **npx first-run latency / acquisition** — `npx -p @mermaid-js/mermaid-cli mmdc` fetches the package on first use (cached after). Mitigated by the `/video` npx precedent; doctor reports acquirability. If a pinned/vendored approach proves better, the engine invocation is the single edit point.
- **System-chrome flags vary** — headless Chrome in CI/containers often needs `--no-sandbox`; the puppeteer config includes it. Sandbox-hardened environments may still refuse — that path degrades to validation-only (acceptable).
- **Mermaid `parse()` in pure node may need a DOM** — so the Chrome-less *validation* is best-effort, not guaranteed; the guaranteed degradation is "preserve source + honest unavailable." Don't over-invest in jsdom plumbing for v1.
- **Theme/styling scope creep** — `--theme` is limited to Mermaid built-ins (`default|dark|forest|neutral`); anything past that is `/frontend-designer` work. Hold the line.
- **Thin-glue kill-risk** — the capacity earns its place via the standardized contract (paths/provenance/caps/doctor/result-JSON/degradation/skill-guidance), not the one-line `mmdc` call. The tests + dogfood must demonstrate that surface, or downgrade to a documented snippet.

## Research / citations

- `@mermaid-js/mermaid-cli` (`mmdc`) — CLI for Mermaid; npx usage requires `-p` because package name ≠ command (`npx -p @mermaid-js/mermaid-cli mmdc -h`); renders via Puppeteer + headless Chrome. https://github.com/mermaid-js/mermaid-cli
- Mermaid `parse(text, {suppressErrors})` validates a definition without rendering (returns `{diagramType}` or throws/false) — the basis for best-effort Chrome-less validation. https://mermaid.ai/open-source/config/usage.html
- Local toolchain probe (2026-06-06): node v24.11.1, npx 11.6.4, `google-chrome`/`google-chrome-stable` present, `d2` present, no graphviz — env is fully render-capable, so the dogfood exercises the real mmdc+system-chrome path.
- Reused precedent: `.agent0/context/rules/video-gen.md` (npx + headless-Chrome acquisition), `.agent0/context/rules/transcribe.md` (local/free, provenance, status-decoupled, degradation), `.agent0/tools/transcribe.sh` + `.agent0/tools/sound.sh` (engine shape mirrored).
- Graduating meeting: `.agent0/meetings/diagram-capacity-technical-visuals-2026-06-06T22-34-59Z/meeting.md`.
