# 210 — validator-multistack-advisory

_Created 2026-06-19._

**Status:** shipped
**Closure:** 2026-06-19 — shipped on main; `.agent0/validators/run.sh` gains `detect_all_stacks()` (git ls-files, fallback-marker-mirroring incl. js lockfiles, vendored-pruned, root-degrade off-git) + the fallback-only, stderr-only, non-blocking `multi-stack-advisory:` (gated `stack != declared`, opt-out `CLAUDE_VALIDATOR_SKIP_MULTISTACK=1`, always includes the audited stack before counting). 3 overpromising rules rewritten (lint-validator/typecheck-advisory/php-laravel-support); advisory documented in typecheck-advisory.md. `verify.sh` 11/11 (incl. ok/exit-identical-on-vs-optout non-blocking proof, off-git root-degrade, stray-marker + vendored-prune guards); all existing validator suites green; doctor clean. Codex-reviewed twice (engine SHIP-WITH-CHANGES→folded; final diff SHIP-WITH-CHANGES→folded). Residual: no execution walk (declarative validator.json owns multi-stack execution); diff-scoped execution deferred.

**UI impact:** none

## Intent

The post-edit validator (`.agent0/validators/run.sh`) has two paths: the **declarative contract** (`.agent0/validator.json`, spec 207 — the recommended monorepo path: consumer-owned commands, stack detection bypassed) and the **legacy stack-detect fallback** (`bun → pnpm → npm → python → go → rust → php`, **first-match-wins, single-stack**). In a polyglot repo with **no** `validator.json`, the fallback silently audits one stack and skips the rest — implying a coverage it does not have (the same silent-partial-coverage hole `/unused-code` fixed with `unaudited_stacks`). Three rules (`lint-validator`, `typecheck-advisory`, `php-laravel-support`) currently **overpromise** that they will "inherit multi-stack automatically when the walk lands". A codex review (2026-06-19) ruled against building an execution walk: it is hot-path overreach (the validator runs every edit; running N stacks' pipelines per edit = mini-CI), and spec 207 already owns the monorepo case declaratively. The honest, proportional fix is **advisory-only**: when the fallback runs and more than one stack is detected across the repo, emit a non-blocking `multi-stack-advisory:` naming the audited stack and the unaudited ones, pointing at the declarative contract — and rewrite the three rules to stop promising a walk. No new execution, declarative-first preserved, hot-path-safe.

## Acceptance criteria

- [x] **Scenario: polyglot fallback surfaces unaudited stacks**
  - **Given** a repo with NO `.agent0/validator.json` and manifests for more than one stack (e.g. root `package.json` + `services/api/composer.json`)
  - **When** `.agent0/validators/run.sh` runs
  - **Then** it still audits the first-match stack AND emits a `multi-stack-advisory:` line on stderr naming the audited stack and the detected-but-unaudited stack(s), with a pointer to declare `.agent0/validator.json` — and the validator's JSON `ok`/`exit` are unchanged (non-blocking)

- [x] **Scenario: declarative contract present → no advisory**
  - **Given** `.agent0/validator.json` exists
  - **When** the validator runs
  - **Then** stack detection is bypassed entirely (unchanged from spec 207) and NO `multi-stack-advisory:` is emitted — the declarative path owns coverage

- [x] **Scenario: single-stack repo → no advisory**
  - **Given** a repo (no `validator.json`) where only one stack is detected
  - **When** the validator runs
  - **Then** no `multi-stack-advisory:` is emitted (nothing was skipped)

- [x] **Scenario: subtree manifest is detected, not just root**
  - **Given** a stack's manifest exists only in a subdirectory (e.g. `services/api/composer.json`) tracked by git, with a different stack at root
  - **When** detection runs
  - **Then** that subtree stack counts toward the multi-stack determination (detection uses `git ls-files`, ignore-aware, not root-markers-only)

- [x] **Scenario: git absent / not a git repo → graceful degrade**
  - **Given** the repo is not a git work-tree (or `git` is unavailable)
  - **When** the validator runs
  - **Then** multi-stack detection degrades to root-marker detection (or is skipped) without breaking the validator — never errors, never blocks

- [x] The advisory is non-blocking: it never changes JSON `ok`, the process exit code, or the delegation-loop budget — identical posture to `lint-advisory:` / `typecheck-advisory:` / `tdd-advisory:`.
- [x] `CLAUDE_VALIDATOR_SKIP_MULTISTACK=1` short-circuits the detection + advisory (family-consistent opt-out).
- [x] `lint-validator.md`, `typecheck-advisory.md`, `php-laravel-support.md` are rewritten: the fallback is **compatibility-only**; serious monorepos declare `.agent0/validator.json`; the fallback emits `multi-stack-advisory:` on detected partial coverage. They stop promising automatic multi-stack inheritance from a future walk.

## Non-goals

- **No execution walk.** The validator does NOT run multiple stacks' test/lint/typecheck pipelines. One stack is audited (first-match, unchanged); the others are only *named*. Running all stacks per edit is hot-path overreach (codex ruling).
- **No diff-scoped execution.** Deferred. If execution ever expands it must be diff-scoped with an explicit shared/root-file policy — out of scope here.
- **No central validation-command construction.** Per-capability branch semantics (JS test gating, typecheck gating, lint manifest-as-intent, PHP runner choice) stay branch-specific; this spec only adds shared *detection* for the advisory, not a shared *executor*.
- **No change to the declarative path.** `validator.json` behavior (spec 207) is untouched; the advisory fires only in the fallback path.
- **No deep monorepo orchestration** (workspace globs, per-package pipelines, dependency graphs).

## Open questions

- [x] **Manifest→stack map for detection:** RESOLVED — mirror `run.sh`'s fallback markers EXACTLY so detection and audit agree on what a "stack" is: `package.json`/`bun.lockb`/`bun.lock`/`bunfig.toml`/`pnpm-lock.yaml`/`package-lock.json`→js, `pyproject.toml`/`requirements.txt`→python, `go.mod`→go, `Cargo.toml`→rust, `composer.json`→php. (Non-fallback markers like `setup.py`/`setup.cfg`/`requirements-*.txt` are deliberately NOT detected — codex fold, so "unaudited" only ever names a stack the fallback genuinely would have audited.)
- [x] **Output volume in huge monorepos:** `git ls-files` could match many manifests. Lean: detection cares only about the SET of distinct stacks (not per-manifest), so the advisory lists at most ~5 stack names — no volume problem.
- [x] **Audited-stack naming:** the advisory should name which stack the fallback actually audited (the first-match) so the human knows what WAS covered, not only what wasn't. Lean: yes, name both sides.

## Context / references

- Codex CLI adversarial design review (read-only, high effort), 2026-06-19 — verdict BUILD-WITH-CHANGES: build the advisory, NOT a walk; mirror `/unused-code`'s `unaudited_stacks`; declarative-first; rewrite the 3 overpromising rules; execution (if ever) diff-scoped only. Transcript: `.agent0/.runtime-state/codex-exec/20260619T134615Z-design-position-to-pressure-test-multi-stack-mon/last-message.md`.
- `.agent0/validators/run.sh` — the fallback `if/elif` chain (`bun→pnpm→npm→python→go→rust→php`) + the `validator.json` precedence + existing `changed_files`/advisory-stderr plumbing this reuses.
- Spec 207 (`docs/specs/207-declarative-validator-contract/`) — the declarative contract that already owns the monorepo case; this advisory points consumers toward it.
- `/unused-code` `unaudited_stacks` (specs 208/209) — the honesty pattern this mirrors at the validator layer.
- Rules to rewrite: `.agent0/context/rules/{lint-validator,typecheck-advisory,php-laravel-support}.md`.
