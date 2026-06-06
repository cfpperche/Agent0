# 162 — diagram — tasks

_Generated from `plan.md` on 2026-06-06. Work top-to-bottom._

## Implementation

- [x] 1. **`diagram.sh` engine** (`.agent0/tools/`) — arg parse (`<source.mmd|"text">`, `--kind`, `--format svg|png|pdf`, `--out`, `--theme`, `--json`, `--exit-code`); source resolve (file or inline→temp `.mmd`); browser-detect (`google-chrome|chromium|chromium-browser`, env override `DIAGRAM_CHROME_BIN`/`DIAGRAM_MMDC`); puppeteer-config write (executablePath + `--no-sandbox`); render via `npx -p @mermaid-js/mermaid-cli mmdc -i -o --puppeteerConfigFile [-t theme]` (env `PUPPETEER_SKIP_DOWNLOAD=1`); validation-only degradation when no chrome (preserve source + `status=unavailable`); storage placement (spec-dir default vs `--out`); provenance manifest JSONL (one line/call incl failure, `stayed_local:true`, no key); status `ok|unavailable|error` decoupled from exit; `doctor`/`caps`.
- [x] 2. **SKILL.md + symlinks** — `.agent0/skills/diagram/SKILL.md` (`agentskills-portable`, desc ≤1024); `.claude/skills/diagram` + `.agents/skills/diagram` symlinks.
- [x] 3. **`diagram.md` rule** (`.agent0/context/rules/`) — deterministic technical visuals, `/transcribe`-class local/free, Mermaid-only v1 (d2 reopen-trigger), system-chrome reuse, validation-only degradation, storage split, boundary vs /image + /video code-mode + /frontend-designer, non-goals.
- [x] 4. **Offline tests** (`.agent0/tests/diagram/`) — fake `mmdc` + fake browser detection: render-ok-svg, no-chrome→validation-only-degrade, invalid-source→error, `--format png`, storage split (spec-dir vs `--out`), manifest one-line-per-call + key-never-recorded, `--kind`/`--json`/`--exit-code` mapping.
- [x] 5. **Wiring** — `.gitignore` (manifest `assets/generated/.diagram-manifest.jsonl`; `assets/diagrams/` NOT ignored); `doctor.sh` diagram check; `CLAUDE.md`+`AGENTS.md` `## Diagram` block; `sync-harness.sh` `COPY_CHECK_FILES` `assets/diagrams/.gitkeep`.

## Verification

- [x] render Mermaid → tracked SVG, manifest `stayed_local:true`, no cost/key (AC 1)
- [x] no chrome → validation-only degrade, source preserved, `status=unavailable` (AC 2)
- [x] invalid source → `status=error`, no corrupt output (AC 3)
- [x] `--format png` produces png (AC 4)
- [x] storage split: spec-dir default vs `assets/diagrams/` via `--out` (AC 5)
- [x] `/skill validate` exit 0; `doctor` reports diagram tri-state; full suite green
- [x] **dogfood: render 3 real diagrams** (architecture + sequence + ERD) via real mmdc+system-chrome (env capable). Stop before harness-sync (minority-report gate).

## Notes

- Build order per plan: engine → SKILL/rule/symlinks → tests → wiring → validate → dogfood 3. Consumer harness-sync is founder-triggered AFTER the dogfood gate.
