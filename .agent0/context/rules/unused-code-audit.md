---
paths:
  - ".agent0/tools/unused-code.sh"
  - "knip.json"
  - "**/knip.json"
  - "**/package.json"
  - "**/pyproject.toml"
  - "**/go.mod"
---

# Unused-code audit

`/unused-code` (and its engine `.agent0/tools/unused-code.sh`) detects **unused/dead code** in a project — unused files, unused exports, unused dependencies, unreferenced members, and unreachable code — on demand, and surfaces them with enough context to act. It is the deliberate twin of `/vuln-audit`: the same on-demand, stack-aware, report-never-act shape, for the same reasons. It answers one narrow, high-signal question — "what does this project ship but never reference?" — and proposes candidates for a human to remove. It never deletes, never gates an edit/commit/install. It covers **JS/TS via [knip](https://knip.dev), Python via [vulture](https://github.com/jendrikseipp/vulture), and Go via [deadcode](https://pkg.go.dev/golang.org/x/tools/cmd/deadcode)** — one engine per stack. Rust/PHP and the complexity/code-smell axis are deferred (see § Non-goals). Specs: `docs/specs/208-unused-code-audit/` (JS/TS), `docs/specs/209-unused-code-python-go/` (Python, Go).

## Trigger surface — on-demand only

The audit runs **only when invoked** — via `/unused-code` in Claude Code, or `bash .agent0/tools/unused-code.sh` directly (Codex CLI / any runtime / CI). It is deliberately **not** on the `PostToolUse`/`SubagentStop` post-edit validator path, **not** on the `.githooks/pre-commit` path, **not** on any install path, and **not** scheduled.

This is the load-bearing design decision (codex-reviewed at refine, 2026-06-18). Unused-code detection is **whole-program graph analysis** (knip builds the full module graph), its findings are **noisy and need human triage** (dynamic imports, framework entry points, deliberately-unused public API, generated files), and its cadence is **periodic housekeeping**. Putting it on the hot per-edit/commit path would slow every turn and spam false positives — the same argument `/vuln-audit` already litigated and won (don't gate; detect on demand and act).

**Inline enforcement is consumer-owned.** A consumer that genuinely wants unused-code on the validator path declares a custom command in `.agent0/validator.json` (e.g. `{ "name": "deadcode", "run": "npx knip" }`, per the spec-207 ordered-command array). Agent0 ships **no** new first-class validator category and **no** per-edit advisory for this — the consumer owns the proportionality call.

**Staleness limitation (honest by design):** the audit reflects the codebase at run time only. A recurring cadence is the documented deferred path via the generic `/routine` capacity — point a routine at `bash .agent0/tools/unused-code.sh` if you want periodic scans. No v1 code ships for this; see `.agent0/context/rules/routines.md`.

## Engines — one per stack

Single engine per stack (no second-engine-per-stack fallback matrix — that reintroduces the divergent-definitions / duplicate-findings problem `/vuln-audit` explicitly rejected). Stacks ship incrementally, the same path the lint validator took.

| Stack | Engine | Finds | Resolution (no-fetch) |
|---|---|---|---|
| JS/TS | knip | files, exports, types, deps, members | local `node_modules/.bin/knip`, else `npx --no-install knip` |
| Python | vulture | functions, classes, methods, variables, imports, unreachable code (heuristic, with a confidence value) | project `.venv/bin/vulture`, else PATH `vulture` |
| Go | deadcode | unreachable functions (RTA reachability from an executable `main`) | PATH `deadcode` only |

Each engine resolves a **no-fetch** invocation and never installs (`go install`/`pip install`/`pnpm exec`/bare `bunx` are all avoided). A repo with no supported stack reports `no-stack` and never claims coverage it does not have.

**Rust/PHP are deliberately excluded** (deferred, shape TBD): their tooling (`cargo-machete`, `composer-unused`) detects unused **dependencies**, not dead **code** — reporting `status=clean` from a deps-only scan under `/unused-code` would be a contract lie no prose caveat fixes (codex ruling, 2026-06-18). Rust dead *code* is already the rustc `dead_code` lint; PHP dead code needs a configured PHPStan/Psalm contract (a consumer-owned analyzer, not a stack-neutral default). If demand lands, a sibling `/unused-deps` capability is the likely home.

## Polyglot repos — `--stack` and the unaudited-stacks note

Detection finds **all** supported stacks but audits **one** per run (first-match in js→python→go order, or the `--stack <js|python|go>` override). When more than one stack is detected, the output carries both a human `note` and a structured `unaudited_stacks` array naming the stacks not audited this run — so a top-level `status=clean` can never silently hide partial coverage. Re-run with `--stack=<name>` to audit each.

## The `unconfigured` status — engine lacks its boundary/entry model

`unconfigured` means **the engine lacks the boundary/entry model it needs to produce sound results**, so the tool hard-stops rather than emit a misleading `clean`. It has two triggers today:

- **knip (JS/TS):** no knip config (none of `knip.{json,jsonc,ts,js}`, `.knip.*`, `knip.config.{ts,js}`, or a `knip` key in `package.json`). knip needs the project's entry points / project globs to tell genuinely-unused code from legitimate entry points; running its bare defaults flags real entry points as unused — false positives with the appearance of truth ("bad-deletion confidence"). Hard-stop over defaults-with-banner was the maintainer ruling (2026-06-18).
- **deadcode (Go):** no executable `main` package (a library-only module). deadcode computes reachability from an executable entry point; with no root it has nothing sound to analyze, so `clean` would be misleading. The tool runs with `-test` (so test-reachable code isn't falsely flagged) and reports `unconfigured` when there is still no main.

vulture (Python) has no such requirement — it is a pure-AST heuristic and never reports `unconfigured`.

## Result status vs process exit code

The tool reports exactly one first-class **result status**, decoupled from the process exit code:

| Status | Meaning |
|---|---|
| `no-stack` | no supported (JS/TS, Python, Go) stack detected — clean no-op, no claim of coverage |
| `clean` | engine ran, no unused code in its corpus |
| `findings` | engine ran, ≥1 unused-code finding |
| `unconfigured` | engine resolvable but lacks its boundary/entry model (knip: no config; Go: no main) — hard-stop, not a misleading `clean` |
| `unavailable` | the stack's engine not resolvable locally — advisory + install hint |
| `failed` | engine ran but errored / produced unparseable output |

**The process exit code defaults to `0` for every result status** — this is the non-blocking advisory family (`lint-advisory:` / `typecheck-advisory:` / `tdd-advisory:` / `/vuln-audit`). An opt-in `--exit-code` maps statuses → non-zero codes for **consumer-owned CI** (`clean`=0, `findings`=1, `unconfigured`=2, `unavailable`=3, `failed`=4); it is never wired into any Agent0 gate. Usage errors (unknown flag, non-directory path) exit `64` (EX_USAGE) regardless — they signal a wrong invocation, not a scan result, and are deliberately exempt from the advisory model (same posture as `/vuln-audit`). `jq`-absent also fails open (advisory).

## Never installs, never modifies

Every engine resolves a **no-fetch** invocation and reuses the same resolved invocation for both the probe and the real run, so the no-fetch guarantee cannot drift: knip prefers the local binary then `npx --no-install` (never `pnpm exec`/bare `bunx`, which can install/sync); vulture prefers the project `.venv` binary then PATH (never `uv run`/`poetry run`, which can sync); deadcode is PATH-only (never `go install`). All run read-only and **modify no file** — no source, manifest, config, or lockfile.

## Output

- **Human-readable (default)** — a `status=` line, optional reason/hint/note, and per-finding records: `[kind] file — name (NN% confidence) — candidate unused` (confidence shown only for vulture). Findings end with a standing reminder that they are **candidates** (verify before removing); vulture output additionally flags that its findings are heuristic.
- **`--json`** — a deterministic structured document (`{status, engine, stack, reason?, hint?, note?, unaudited_stacks?, findings[]}`); each finding is `{file, kind, name, confidence?}`. **Shape-only convenience, not a versioned wire contract** — the field set may evolve and there is no schema-version key, deliberately (same posture as `/vuln-audit` and `/sdd list --json`).

## Finding taxonomy — distinct risk classes, shared across stacks

The kinds are semantic and **cross-stack** (no per-stack kind names), and not equivalent in deletion risk, so the output keeps them distinct rather than flattening to "unused":

- **unused file** — an orphaned module never imported (knip). Usually safe, but may be a dynamic-import or framework-convention entry point.
- **unused export** — a definition exported/declared but never referenced (knip exports/types; vulture functions/classes/methods). May be **intentional public API** — the highest-false-positive class for libraries.
- **unused dependency** — declared but never imported (knip deps/devDeps).
- **unreferenced member** — members never read (knip enum/namespace members; vulture variables/attributes/properties).
- **unreachable code** — code that cannot be reached (Go deadcode unreachable functions; vulture unreachable blocks). Carries no symbol `name` for vulture unreachable blocks (the message has no symbol).
- **other** — knip's `unlisted`/`unresolved`/`duplicates`, vulture unused imports. Surfaced but grouped — different problems than deletable-unused, not removal candidates.

**vulture findings carry a `confidence`** (0–100). It is preserved verbatim in JSON and human output and never stripped — vulture is heuristic (Python's dynamism means it can both miss dead code and flag implicitly-used code), so laundering its guess into a fact would be dishonest. Agent0 imposes no `--min-confidence` floor; the human (or a consumer-passed engine flag) decides.

## Suppression — engine-native, no Agent0 marker

There is no `# OVERRIDE:` grammar and no skip env-var — because the audit never blocks anything, there is no gate to bypass. Suppressing individual false positives is **engine-native**: knip config (`entry`, `ignore`, `ignoreDependencies`), vulture whitelist files / `--min-confidence`, or deadcode's reachability model. This absence is deliberate, not an omission.

## Non-goals

- **No per-edit validator advisory and no new first-class validator category.** Inline enforcement is consumer-owned via an existing `.agent0/validator.json` custom command.
- **No auto-deletion / no `--fix`.** "Unused" may be intentional public API; removal is a human decision. Report and propose only — same posture as `/vuln-audit`'s propose-never-apply.
- **No Rust / PHP, and no unused-dependency-only stacks under this command.** Their tools detect unused *dependencies*, not dead *code*; conflating the two under `/unused-code` would make `status=clean` lie. Deferred (likely a sibling `/unused-deps` capability if demand lands).
- **No simultaneous all-stack audit / `{runs:[...]}` JSON.** Polyglot repos audit one stack per run; the `--stack` override + `unaudited_stacks` field handle coverage honestly. A multi-run rewrite is deferred behind demand.
- **No complexity / code-smell detection** (long functions, large classes, cyclomatic/cognitive complexity, maintainability index). It is threshold-politics requiring local taste and stack norms; bundling it would poison the high-signal unused-code part. Deferred to a future `/code-health` recipe or a consumer-declared analyzer command.
- **No built-in scheduling.** Recurring scans are a documented `/routine` recipe, not tool-resident cron.
- **No second-engine-per-stack fallback matrix.** Single engine per supported stack.

## Gotchas

- **`clean` is engine-and-config-scoped.** It means "no unused code found by the stack's engine under its configured boundaries," not "there is no dead code." For knip a too-narrow `project` glob hides findings; for vulture confidence is heuristic; for Go deadcode reachability is bounded by the executable entry. Engine + config quality bounds result quality.
- **Entry-file exports are treated as used by knip** (they are the public surface) — not a bug. To find an unused export, it must live in a non-entry module.
- **`unconfigured` vs `clean` are very different.** A project with no knip config gets `unconfigured`, never a falsely-reassuring `clean`. Do not "fix" this by adding `--no-config-hint` defaults.
- **Monorepos / polyglot:** knip is workspace-aware; the tool invokes each engine at the scan-path root. A repo with several supported stacks audits one per run — check `unaudited_stacks` and re-run with `--stack` for the rest. No Agent0-side workspace walk.
- **vulture runs in the project environment.** It resolves `.venv/bin/vulture` before PATH; running it outside the project's env (or with a stale venv) inflates findings. Confidence is heuristic — treat low-confidence items as weak signals, not facts.
- **vulture exit code is unreliable.** It can exit 0 even on a missing-path error, so the tool keys on output shape, not exit status: any `:N:` diagnostic line that is not a recognized finding → `failed` (never a false `clean`). Verified against vulture 2.16.
- **Go deadcode needs an executable main.** Library-only modules → `unconfigured`, not `clean` (nothing to analyze from). deadcode exits 0 even with findings, so the tool parses the JSON array, not the exit code. The tool runs `-test` so test-reachable code isn't flagged.
- **Engine output schema drift.** Each parser depends only on documented fields, tolerates missing/extra keys, and degrades to `failed` (never crashes) on unparseable output. Verified against knip 6.17.1, vulture 2.16, Go deadcode (golang.org/x/tools) — see `docs/specs/208-...` and `docs/specs/209-...` notes for the captured contracts.
