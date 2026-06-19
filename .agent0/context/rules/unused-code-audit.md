---
paths:
  - ".agent0/tools/unused-code.sh"
  - "knip.json"
  - "**/knip.json"
  - "**/package.json"
---

# Unused-code audit

`/unused-code` (and its engine `.agent0/tools/unused-code.sh`) detects **unused/dead code** in a project — unused files, unused exports, unused dependencies, and unreferenced members — on demand, and surfaces them with enough context to act. It is the deliberate twin of `/vuln-audit`: the same on-demand, stack-aware, report-never-act shape, for the same reasons. It answers one narrow, high-signal question — "what does this project ship but never reference?" — and proposes candidates for a human to remove. It never deletes, never gates an edit/commit/install. v1 covers **JS/TS via [knip](https://knip.dev) only**; further stacks and the complexity/code-smell axis are deferred (see § Non-goals). Spec: `docs/specs/208-unused-code-audit/`.

## Trigger surface — on-demand only

The audit runs **only when invoked** — via `/unused-code` in Claude Code, or `bash .agent0/tools/unused-code.sh` directly (Codex CLI / any runtime / CI). It is deliberately **not** on the `PostToolUse`/`SubagentStop` post-edit validator path, **not** on the `.githooks/pre-commit` path, **not** on any install path, and **not** scheduled.

This is the load-bearing design decision (codex-reviewed at refine, 2026-06-18). Unused-code detection is **whole-program graph analysis** (knip builds the full module graph), its findings are **noisy and need human triage** (dynamic imports, framework entry points, deliberately-unused public API, generated files), and its cadence is **periodic housekeeping**. Putting it on the hot per-edit/commit path would slow every turn and spam false positives — the same argument `/vuln-audit` already litigated and won (don't gate; detect on demand and act).

**Inline enforcement is consumer-owned.** A consumer that genuinely wants unused-code on the validator path declares a custom command in `.agent0/validator.json` (e.g. `{ "name": "deadcode", "run": "npx knip" }`, per the spec-207 ordered-command array). Agent0 ships **no** new first-class validator category and **no** per-edit advisory for this — the consumer owns the proportionality call.

**Staleness limitation (honest by design):** the audit reflects the codebase at run time only. A recurring cadence is the documented deferred path via the generic `/routine` capacity — point a routine at `bash .agent0/tools/unused-code.sh` if you want periodic scans. No v1 code ships for this; see `.agent0/context/rules/routines.md`.

## Engine — knip-only, JS/TS-only (v1)

The engine is **knip** for JS/TS: one tool that finds unused files, exports, types, dependencies, and members from a project's module graph. It is knip-only and JS/TS-only in v1 by deliberate decision:

- **Single engine per stack.** No second-engine-per-stack fallback matrix — that reintroduces the divergent-definitions / duplicate-findings problem `/vuln-audit` explicitly rejected.
- **JS/TS first, further stacks behind demand.** Python (`vulture`), Go (`deadcode`/`staticcheck`), Rust (`cargo-machete` — which finds unused *deps*, not unused *code*; rustc already warns on unused code), and PHP (no clean dead-code-only tool without a full PHPStan/Psalm contract) are deferred behind rule-of-three demand, added one engine per stack — the same incremental path the lint validator took. A non-JS project reports `no-stack` and never claims coverage it does not have.

## knip needs a config — the `unconfigured` status

Unlike `/vuln-audit` (whose source of truth is universal: lockfiles), knip needs the **project's boundary model** — entry points, public API, project globs — to tell genuinely-unused code from legitimate entry points. Dependency-declaration-as-intent is therefore **not** sufficient: intent here is "these are my entry points and boundaries," which is config, not install state.

So when knip is resolvable but the project ships no knip config (none of `knip.{json,jsonc,ts,js}`, `.knip.*`, `knip.config.{ts,js}`, or a `knip` key in `package.json`), the engine **hard-stops at status `unconfigured`** with a pointer to add a `knip.json` — it does **not** run knip's bare defaults. Running defaults without a boundary model flags legitimate entry points as unused — false positives with the appearance of truth ("bad-deletion confidence"). Hard-stop over defaults-with-banner was the maintainer ruling (2026-06-18).

## Result status vs process exit code

The tool reports exactly one first-class **result status**, decoupled from the process exit code:

| Status | Meaning |
|---|---|
| `no-stack` | no supported (JS/TS) stack detected — clean no-op, no claim of coverage |
| `clean` | knip ran, no unused code in its corpus |
| `findings` | knip ran, ≥1 unused-code finding |
| `unconfigured` | knip resolvable but no knip config — hard-stop (would otherwise manufacture false positives) |
| `unavailable` | knip not resolvable (not installed locally) — advisory + install hint |
| `failed` | knip ran but errored / produced unparseable output |

**The process exit code defaults to `0` for every result status** — this is the non-blocking advisory family (`lint-advisory:` / `typecheck-advisory:` / `tdd-advisory:` / `/vuln-audit`). An opt-in `--exit-code` maps statuses → non-zero codes for **consumer-owned CI** (`clean`=0, `findings`=1, `unconfigured`=2, `unavailable`=3, `failed`=4); it is never wired into any Agent0 gate. Usage errors (unknown flag, non-directory path) exit `64` (EX_USAGE) regardless — they signal a wrong invocation, not a scan result, and are deliberately exempt from the advisory model (same posture as `/vuln-audit`). `jq`-absent also fails open (advisory).

## Never installs, never modifies

The engine resolves a **no-fetch** knip invocation — it prefers the local binary (`node_modules/.bin/knip`) and falls back only to an `npx --no-install` probe; it never runs `pnpm exec`/bare `bunx` (which can trigger an install/sync) and reuses the same resolved invocation for both the probe and the real run, so the no-fetch guarantee cannot drift. It runs knip read-only (`--reporter json`) and **modifies no file**: no source, no manifest, no config, no lockfile.

## Output

- **Human-readable (default)** — a `status=` line, an optional reason/hint, and per-finding records: `[kind] file — name — candidate unused`, where kind ∈ unused file / unused export / unused dependency / unreferenced member / other. Findings end with a standing reminder that they are **candidates** (verify before removing).
- **`--json`** — a deterministic structured document (`{status, engine, reason?, hint?, findings[]}`). **Shape-only convenience, not a versioned wire contract** — the field set may evolve and there is no schema-version key, deliberately (same posture as `/vuln-audit` and `/sdd list --json`).

## Finding taxonomy — distinct risk classes

The kinds are not equivalent in deletion risk, and the output keeps them distinct rather than flattening to "unused":

- **unused file** — an orphaned module never imported. Usually safe, but may be a dynamic-import or framework-convention entry point.
- **unused export / type** — exported but never imported internally. May be **intentional public API** of a library — the highest-false-positive class for published packages.
- **unused dependency** — declared in `package.json` but never imported. Usually safe to remove, but watch for deps used only by config/build tooling knip doesn't model.
- **unreferenced member** — enum/namespace members never read.
- **other** — knip's `unlisted` (used but undeclared) / `unresolved` / `duplicates`. Surfaced but grouped — these are different problems than deletable-unused and are not removal candidates.

## Suppression — engine-native, no Agent0 marker

There is no `# OVERRIDE:` grammar and no skip env-var — because the audit never blocks anything, there is no gate to bypass. Suppressing individual false positives (a deliberately-unused public export, a dynamic entry point) is **engine-native**: configure it in `knip.json` (`entry`, `ignore`, `ignoreDependencies`, plugins). This absence is deliberate, not an omission.

## Non-goals

- **No per-edit validator advisory and no new first-class validator category.** Inline enforcement is consumer-owned via an existing `.agent0/validator.json` custom command.
- **No auto-deletion / no `--fix`.** "Unused" may be intentional public API; removal is a human decision. Report and propose only — same posture as `/vuln-audit`'s propose-never-apply.
- **No multi-stack coverage in v1.** JS/TS via knip only; other stacks deferred one-per-stack behind demand.
- **No complexity / code-smell detection** (long functions, large classes, cyclomatic/cognitive complexity, maintainability index). It is threshold-politics requiring local taste and stack norms; bundling it would poison the high-signal unused-code part. Deferred to a future `/code-health` recipe or a consumer-declared analyzer command.
- **No built-in scheduling.** Recurring scans are a documented `/routine` recipe, not tool-resident cron.
- **No second-engine-per-stack fallback matrix.** Single engine per supported stack.

## Gotchas

- **`clean` is engine-and-config-scoped.** It means "no unused code found by knip under its configured boundaries," not "there is no dead code." A too-narrow `knip.json` `project` glob hides real findings; a too-broad `entry` set marks everything used. Config quality bounds result quality.
- **Entry-file exports are treated as used by knip** (they are the public surface) — not a bug. To find an unused export, it must live in a non-entry module.
- **`unconfigured` vs `clean` are very different.** A project with no knip config gets `unconfigured`, never a falsely-reassuring `clean`. Do not "fix" this by adding `--no-config-hint` defaults.
- **Monorepos:** knip is workspace-aware; the tool invokes it at the scan-path root and relies on knip's own workspace handling. Agent0 does not add a workspace walk in v1 (mirrors the validator's single-stack-v1 stance).
- **knip JSON schema drift.** The parser depends only on the documented top-level `.issues[]` + per-file array keys, tolerates missing/extra keys, and degrades to `failed` (never crashes) on unparseable output. Verified against knip 6.17.1 (see `docs/specs/208-unused-code-audit/notes.md` for the schema contract).
