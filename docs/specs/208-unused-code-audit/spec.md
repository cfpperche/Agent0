# 208 — unused-code-audit

_Created 2026-06-18._

**Status:** shipped
**Closure:** 2026-06-18 — shipped on main; engine `.agent0/tools/unused-code.sh` + skill `.agent0/skills/unused-code/` (Claude/Codex symlinks) + rule `.agent0/context/rules/unused-code-audit.md` + CLAUDE.md/AGENTS.md index entries; `verify.sh` 22/22 (6 statuses + scenario-2 wording/per-kind/no-mutation + full --exit-code map); codex-reviewed twice (engine BLOCK→all folded; final diff SHIP-WITH-CHANGES→all folded); doctor 25 ok. Residual: none for v1 (JS/TS-knip only; further stacks + complexity/code-smell axis deferred behind demand per § Non-goals).

**UI impact:** none

## Intent

Agent0 has fast, file-local quality signals on the post-edit validator path (lint, typecheck, test, TDD advisory) but nothing for **unused/dead code** — exports/files/dependencies a project locks and ships but never references. The maintainer asked for a capacity "in the style of typecheck/test/lint" for unused-code housekeeping (and, separately, complexity/refactor smells). This spec delivers the unused-code half as an **on-demand audit** — the same shape `/vuln-audit` chose, and for the same reasons: unused-code detection is **whole-program graph analysis** (not a cheap file-local check), its findings are **noisy and need human triage** (dynamic imports, framework entry points, deliberately-unused public API, generated files), and its cadence is **periodic housekeeping**, not per-edit. Putting it on the hot per-edit/commit path would spam false positives and slow every turn — an argument vuln-audit already litigated and won. v1 covers **JS/TS via knip only**; further stacks and the complexity/code-smell axis are deferred behind observed demand (rule-of-three), mirroring how the lint validator shipped incrementally.

## Acceptance criteria

- [x] **Scenario: clean project reports no findings**
  - **Given** a JS/TS project with a knip config and no unused exports/files/deps
  - **When** the operator runs `bash .agent0/tools/unused-code.sh` (or `/unused-code`)
  - **Then** it reports result status `clean` and exits 0

- [x] **Scenario: unused code is reported, never deleted**
  - **Given** a JS/TS project with unused exports/files/dependencies
  - **When** the audit runs
  - **Then** it reports status `findings` with per-finding records classified by kind (unused file / unused export / unused dependency / unreferenced member), worded as **candidate unused** (never "delete this"), and modifies **no** source, manifest, or config file

- [x] **Scenario: missing engine config is surfaced honestly, not silently defaulted into noise**
  - **Given** a JS/TS project that declares/has knip installed but ships **no** knip config (no entry-point/boundary model)
  - **When** the audit runs
  - **Then** it reports status `unconfigured` with a one-line pointer to add a `knip.json`/`knip` config, rather than running bare defaults that flag legitimate entry points as unused

- [x] **Scenario: engine absent fails open with an install hint**
  - **Given** a JS/TS project where knip is not installed/available
  - **When** the audit runs
  - **Then** it reports status `unavailable` with an install hint and exits 0 (advisory, non-blocking)

- [x] **Scenario: non-JS project is a clean no-op, not a false signal**
  - **Given** a project with no JS/TS stack markers
  - **When** the audit runs
  - **Then** it reports that no supported stack was detected (no findings, no error) and exits 0 — it never claims stack-neutral coverage it does not have

- [x] **Scenario: consumer-owned inline enforcement via the existing contract**
  - **Given** a consumer that wants unused-code enforcement on the validator path
  - **When** they declare a custom command (e.g. `{ "name": "deadcode", "run": "npx knip" }`) in `.agent0/validator.json`
  - **Then** the post-edit validator runs it as-is — with **no** new first-class validator category added by this spec

- [x] Result status is one of `no-stack | clean | findings | unconfigured | unavailable | failed`, decoupled from the process exit code; default exit is `0` for all statuses (usage errors exit 64/EX_USAGE), with an opt-in `--exit-code` mapping for consumer-owned CI only (never wired into any Agent0 gate). Mirrors `/vuln-audit`.
- [x] A rule doc (`.agent0/context/rules/unused-code-audit.md`) explains the on-demand posture, the `unconfigured` caveat, the report-never-delete contract, the consumer `validator.json` hybrid, and the `/routine` recipe for periodic scans (scheduling is **not** built into the tool).

## Non-goals

- **No per-edit validator advisory and no new first-class `deadcode`/`unused` validator category.** Inline enforcement is consumer-owned via an existing `.agent0/validator.json` custom command.
- **No auto-deletion / no `--fix`.** "Unused" may be intentional public API; removal is a human decision. Report and propose only — same posture as `/vuln-audit`'s propose-never-apply.
- **No multi-stack coverage in v1.** Python (vulture), Go (`deadcode`/staticcheck), Rust (`cargo-machete` — which is unused *deps*, not unused *code*; rustc already warns on unused code), and PHP (no clean dead-code-only tool without a full PHPStan/Psalm contract) are deferred behind rule-of-three demand, added one engine per stack like lint did.
- **No complexity / code-smell detection** (long functions, large classes, cyclomatic/cognitive complexity, maintainability index). It is threshold-politics requiring local taste and stack norms; combining it with unused-code would poison the high-signal part. Deferred to a future `/code-health` recipe or a consumer-declared analyzer command.
- **No second-engine-per-stack fallback matrix.** Single engine per supported stack (knip for JS/TS) to avoid the divergent-definitions / duplicate-findings problem `/vuln-audit` explicitly rejected.
- **No built-in scheduling.** Recurring scans are a documented `/routine` recipe, not tool-resident cron.
- **No `# OVERRIDE:` grammar / skip env-var.** It never blocks, so there is no gate to bypass. Suppression of individual findings is engine-native (knip config), not an Agent0 marker.

## Open questions

- [x] **Surface form:** RESOLVED — shipped the full `/unused-code` skill + `.agent0/tools/unused-code.sh` engine (the `/vuln-audit` twin) for discoverability and runtime-neutral parity.
- [x] **`unconfigured` strictness:** RESOLVED (maintainer, 2026-06-18) — hard-stop at `unconfigured` rather than run bare defaults that manufacture false positives.
- [x] **Monorepo scope:** RESOLVED — defer to knip's own workspace-awareness; invoke at the scan-path root, no Agent0-side workspace walk in v1 (mirrors validator single-stack v1).
- [x] **Coverage-bucket reporting:** RESOLVED — a minimal stack-detected/engine-status line is enough for v1; full `found/covered/skipped` buckets only when a second stack lands.

## Context / references

- Conversation 2026-06-18: maintainer asked for a typecheck/test/lint-style capacity for unused-code + code-quality/refactor smells; literature/market framing (dead-code detection vs code-smells/static-analysis) established; agreed to start with unused/dead code.
- Codex CLI adversarial design review (read-only, high effort), 2026-06-18 — folded in full: on-demand-not-per-edit, JS-only v1, `unconfigured` status, `unused-code` naming over `dead-code`, complexity deferral, taxonomy/boundary/suppression decisions. Transcript: `.agent0/.runtime-state/codex-exec/20260618T232755Z-design-position-to-pressure-test-agent0-dead-cod/last-message.md`.
- `/vuln-audit` — the on-demand, stack-aware, report-never-block precedent this spec mirrors: `.agent0/context/rules/vuln-audit.md`, `.agent0/tools/vuln-audit.sh`.
- Declarative validator contract (spec 207) — the consumer-owned `validator.json` custom-command path that provides the inline hybrid: `docs/specs/207-declarative-validator-contract/spec.md`, `.agent0/context/rules/typecheck-advisory.md`.
- Lint validator (incremental per-stack rollout precedent): `.agent0/context/rules/lint-validator.md`.
- knip — JS/TS unused files/exports/dependencies engine: https://knip.dev
