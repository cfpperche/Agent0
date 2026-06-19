# 209 — unused-code-python-go

_Created 2026-06-18._

**Status:** shipped
**Closure:** 2026-06-18 — shipped on main; extended `.agent0/tools/unused-code.sh` with Python (vulture) + Go (deadcode) branches + `--stack` + structured `unaudited_stacks` + per-finding `confidence`; generalized `unconfigured`; updated rule + SKILL.md + CLAUDE.md/AGENTS.md. `verify.sh` 20/20 (Python findings/clean/unavailable + confidence + unreachable-null + multi-finding guard; Go findings/clean/unconfigured-no-main/unavailable + unreachable-kind; polyglot note + unaudited_stacks default & forced; --stack; no-stack); spec-208 parity 22/22; doctor 25/0/0; skill validates. Codex-reviewed twice (engine BLOCK→all folded; final diff SHIP-WITH-CHANGES→all folded). Residual: none for this scope (Rust/PHP deferred — deps≠code).

**UI impact:** none

## Intent

Extend the spec-208 `/unused-code` capability beyond JS/TS to the two further stacks that have a genuine **unused/dead-code** engine: **Python via [vulture](https://github.com/jendrikseipp/vulture)** and **Go via [`golang.org/x/tools/cmd/deadcode`](https://pkg.go.dev/golang.org/x/tools/cmd/deadcode)**. The maintainer asked to evolve to Python/PHP/Rust/Go; a codex adversarial review (2026-06-18) established that Rust (`cargo-machete`) and PHP (`composer-unused`) tools detect unused **dependencies**, not dead **code** — bolting them onto `/unused-code` would make `status=clean` lie ("no dead code" when only deps were scanned). So this spec ships **only the two real unused-code engines**; Rust/PHP are deferred without committing to a shape (likely a sibling `/unused-deps` capability if demand lands). The architecture stays single-engine-per-stack (the v1 ruling); this is the next stack increment, not a multi-stack rewrite.

## Acceptance criteria

- [x] **Scenario: Python findings via vulture**
  - **Given** a Python project (`pyproject.toml`/`requirements.txt`) with vulture available and unused code (unused function/import/variable)
  - **When** `bash .agent0/tools/unused-code.sh` runs
  - **Then** it reports status `findings` with per-finding records carrying `kind` and the vulture **`confidence`** value, worded as candidate/heuristic — never as certain dead code

- [x] **Scenario: Go findings via deadcode**
  - **Given** a Go module (`go.mod`) with `deadcode` available, an executable `main`, and an unreachable function
  - **When** the audit runs
  - **Then** it reports status `findings` with the unreachable function as kind `unreachable code`

- [x] **Scenario: Go with no reachability root is `unconfigured`, not a false `clean`**
  - **Given** a library-only Go module with no `main` package and no analyzable test root
  - **When** the audit runs (including the `-test` default)
  - **Then** it reports `unconfigured` with a hint that deadcode needs an executable/test entry — it does NOT report `clean` (which would falsely imply "analyzed, nothing dead")

- [x] **Scenario: engine absent fails open per ecosystem**
  - **Given** a Python or Go project where the engine (vulture / deadcode) is not locally available
  - **When** the audit runs
  - **Then** it reports `unavailable` with the ecosystem-correct install hint (`pip install vulture` / `go install golang.org/x/tools/cmd/deadcode@latest`) and exits 0 — and it NEVER triggers an install/fetch to resolve the engine

- [x] **Scenario: polyglot repo never reports silent partial coverage**
  - **Given** a repo where more than one supported stack is detected (e.g. Python + Go + JS)
  - **When** the audit runs without `--stack`
  - **Then** it audits one stack AND surfaces a note naming the other detected-but-unaudited stacks with the `--stack <name>` override — a top-level `clean` never silently hides skipped stacks

- [x] `--stack <js|python|go>` forces the stack to audit, overriding first-match detection.
- [x] vulture findings preserve `confidence` in both human output and `--json`; the `--json` finding object gains an optional `confidence` field (absent for engines that have no confidence notion).
- [x] The cross-stack `kind` vocabulary stays semantic and shared — `unused file | unused export | unused dependency | unreferenced member | unreachable code | other` — with NO per-stack kind names (no `go dead function`, no `vulture attribute`).
- [x] No-fetch/no-modify contract holds per engine: local-binary resolution only (`vulture` on PATH / in venv; `deadcode` on PATH); no `go install`, no `pip install`, no lockfile/source mutation.
- [x] `.agent0/context/rules/unused-code-audit.md` is updated to document the Python/Go engines, the `unconfigured` generalization (engine lacks the boundary/entry model it needs), the `--stack` flag + polyglot note, and the Rust/PHP deferral rationale (deps ≠ code).

## Non-goals

- **No Rust or PHP.** Their tools (`cargo-machete`, `composer-unused`) find unused *dependencies*, not dead *code* — a different capability. Deferred; if demand lands, a sibling `/unused-deps` surface is the likely shape (not decided here). Rust dead *code* is already the rustc `dead_code` lint.
- **No PHPStan/Psalm/ShipMonk dead-code path.** That needs a configured project contract — a consumer-owned analyzer, not a stack-neutral default (the v1 "trap" ruling stands).
- **No full multi-run `{runs:[...]}` JSON / simultaneous all-stack audit.** Polyglot coverage is handled by the `--stack` override + an explicit unaudited-stacks note, not by auditing every stack in one pass. A `{runs:[]}` rewrite is deferred behind demand.
- **No new status beyond the v1 set.** `no-stack | clean | findings | unconfigured | unavailable | failed` is reused; Go's "no reachability root" maps onto `unconfigured` (generalized meaning).
- **No confidence threshold gating.** vulture's `--min-confidence` is not imposed by Agent0; all findings are reported with their confidence surfaced for human triage (consumer can pass engine-native flags if they want a floor).
- **No auto-deletion, no per-edit/commit/install gating.** Unchanged from v1.

## Open questions

- [x] **Go `-test` default:** RESOLVED — yes, `-test` on by default; include `-test` by default (so test-only-reachable code isn't falsely flagged dead)? Lean: yes, default `-test` on — it reduces false positives; document it.
- [x] **vulture venv resolution order:** RESOLVED at build — `.venv/bin/vulture` then PATH `vulture` only. Deliberately NOT `uv run`/`poetry run`/`pdm run` (unlike the validator's `py_prefix`): those can sync/fetch, violating the no-fetch contract. vulture is pure-AST static analysis so it does not need the project interpreter to import code.
- [x] **vulture noise floor in output:** RESOLVED — report all, confidence per line, no filtering; do we display all confidences or visually separate low-confidence (e.g. <60%)? Lean: report all, sort/annotate by confidence, no filtering — the human triages; `--json` carries the raw number.

## Context / references

- Builds on spec 208 (`docs/specs/208-unused-code-audit/`) — the shipped JS/TS engine + status model + skill + rule this extends. `.agent0/tools/unused-code.sh`.
- Codex CLI adversarial design review (read-only, high effort), 2026-06-18 — verdict: ship Python+Go only, defer Rust/PHP (deps≠code category error), preserve vulture confidence, Go entrypoint/`-test` policy + `unconfigured` for no-root, per-engine no-fetch resolution, polyglot `--stack`/note. Transcript: `.agent0/.runtime-state/codex-exec/20260619T010015Z-design-position-to-pressure-test-extend-unused-c/last-message.md`. Maintainer scope decision: Python+Go now, Rust/PHP later (shape TBD).
- vulture — https://github.com/jendrikseipp/vulture (confidence model, whitelist, `--min-confidence`).
- Go deadcode — https://pkg.go.dev/golang.org/x/tools/cmd/deadcode (RTA reachability from executable `main`; `-test` flag).
