# 047 — php-laravel-support

_Created 2026-05-18._

**Status:** shipped

## Intent

Agent0's harness capacities — post-edit validator, supply-chain gate, runtime-introspect, TDD advisory, lint validator, MCP recipes hint, and the CLAUDE.md capacity index — currently detect six stacks (bun / pnpm / npm / python / go / rust) but not PHP/Laravel. The inspection done 2026-05-18 (conversation tail: Acme Yard project bootstrap) confirms seven distinct gaps: 3 silent-failure blockers (validator, supply-chain, runtime-introspect) and 4 advisory misses (TDD patterns, lint, MCP recipes, CLAUDE.md). The trigger for this spec is the Acme Yard project — a 12-microSaaS/year portfolio on Laravel 11 + Filament 3 + Livewire 3 + Prism PHP — that needs the same governance discipline Agent0 provides for other stacks. Goal: make Agent0 PHP/Laravel-aware end-to-end so a fork of Agent0 targeting a Laravel codebase fires every capacity correctly with zero manual tuning.

## Acceptance criteria

- [ ] **Scenario: validator detects PHP via composer.json**
  - **Given** a fork with `composer.json` at root, no JS/Python/Go/Rust manifest, and `phpunit.xml` (or `phpunit.xml.dist`) present
  - **When** `.claude/validators/run.sh` is invoked
  - **Then** validator emits a JSON object with `stack="php"`, `command` containing `vendor/bin/phpunit` (or `vendor/bin/pest` if Pest is declared), and `ok` reflects actual phpunit exit code

- [ ] **Scenario: supply-chain blocks `composer require` by default**
  - **Given** a Bash tool call with command `composer require laravel/cashier` and no `# OVERRIDE: <reason>` marker
  - **When** `.claude/hooks/supply-chain-scan.sh` runs in block mode (default)
  - **Then** the hook exits 2, emits the corrective stderr template naming the manager `composer` and the package `laravel/cashier`, and appends one audit row with `decision="block"`, `manager="composer"`, `action="require"`, `packages=["laravel/cashier"]`

- [ ] **Scenario: supply-chain advises on bare `composer install` with dirty composer.json**
  - **Given** `composer.json` is uncommitted-modified in the working tree
  - **When** a Bash tool call runs `composer install` (no packages)
  - **Then** the hook emits the `supply-chain-advisory: bare composer install with uncommitted manifest(s)` line and audits `decision="advisory-bare-install"` with `manager="composer"`, `action="install"`

- [ ] **Scenario: Edit on composer.json triggers sub-agent advisory**
  - **Given** a delegated sub-agent's Edit/Write/MultiEdit tool call writes to `composer.json` (or `composer.lock`)
  - **When** `.claude/hooks/supply-chain-advise.sh` runs
  - **Then** the hook emits `supply-chain-advisory: edit composer.json — manifest may have new dep` on stderr and audits `decision="advisory"`, `scope="edit"`, `file="composer.json"`

- [ ] **Scenario: runtime-introspect captures `vendor/bin/phpunit`**
  - **Given** a Bash tool call running `vendor/bin/phpunit --colors=never`
  - **When** the PostToolUse `.claude/hooks/runtime-capture.sh` fires
  - **Then** `.claude/.runtime-state/last-run.json` is written with `detector="phpunit"`, captured stdout/stderr clamped to 4 KB head + tail, and `inferred_status` reflects the run (PASS on "OK" or "Tests: N, Assertions: M", FAIL on "FAILURES!" / "Errors:")

- [ ] **Scenario: runtime-introspect captures `php artisan test`**
  - **Given** a Bash tool call running `php artisan test`
  - **When** the capture hook fires
  - **Then** the snapshot has `detector="artisan-test"` and inference resolves PASS/FAIL using the Laravel/PHPUnit summary line shapes

- [ ] **Scenario: runtime-introspect captures `vendor/bin/pest`**
  - **Given** a Bash tool call running `vendor/bin/pest` (or `./vendor/bin/pest`)
  - **When** the capture hook fires
  - **Then** the snapshot has `detector="pest"` and inference resolves PASS/FAIL using Pest output shapes (`✓` / `✗` / `Tests: N passed`)

- [ ] **Scenario: TDD advisory fires when prod-PHP edits land without test edits**
  - **Given** a sub-agent's edits include changes to `app/Models/User.php` (prod) and no changes to any file matching the PHP test patterns
  - **When** validator runs the post-edit TDD diff classification
  - **Then** the `warnings` array contains one `no_test_change_for_prod_edit` entry naming the prod file, and `post-edit-validate.sh` surfaces the `tdd-advisory:` line to stderr

- [ ] **Scenario: lint validator runs Pint when declared**
  - **Given** `composer.json` declares `laravel/pint` in `require-dev` and `vendor/bin/pint` is installed
  - **When** validator composes the command
  - **Then** `command` includes `&& vendor/bin/pint --test` (test mode — no auto-fix), and failure flips `ok=false`

- [ ] **Scenario: lint advisory fires when Pint declared but missing**
  - **Given** `composer.json` declares `laravel/pint` in `require-dev` but `vendor/bin/pint` does not exist
  - **When** validator runs lint detection
  - **Then** validator stderr emits `lint-advisory: pint declared in composer.json but not installed — run \`composer install\``, the command runs without Pint, and `ok` reflects only the test step

- [ ] **Scenario: PHPStan runs when declared (Larastan or vanilla)**
  - **Given** `composer.json` declares `phpstan/phpstan` OR `larastan/larastan` in `require-dev`
  - **When** validator composes the command
  - **Then** `command` includes `&& vendor/bin/phpstan analyse --no-progress`, and failure flips `ok=false`

- [ ] **Scenario: MCP recipes hint suggests laravel-boost for Laravel forks**
  - **Given** a fork with `artisan` executable file at root OR `composer.json` declaring `laravel/framework` as a dep
  - **When** the SessionStart hook `.claude/hooks/mcp-recipes-hint.sh` runs
  - **Then** the emitted `=== mcp-recipes ===` block lists `laravel-boost-mcp` (with one-line description) plus existing `playwright-mcp` if browser deps coexist

- [ ] **Scenario: end-to-end smoke after sync to a Laravel fork**
  - **Given** a fresh Laravel 11 fork created by `composer create-project laravel/laravel <name>` plus Agent0 harness synced via `.claude/tools/sync-harness.sh --apply --agent0-path=<Agent0>`
  - **When** an agent edits an `app/` file, then runs `vendor/bin/phpunit`
  - **Then** validator emits a real command (not `no-stack-detected`); supply-chain audit log records subsequent composer commands; `bash .claude/tools/probe.sh last-run` returns the phpunit snapshot

- [ ] `.claude/rules/php-laravel-support.md` exists, documents the seven capacities' PHP-specific behavior, and is referenced from `CLAUDE.md`'s new `## PHP / Laravel` capacity section.

- [ ] `.claude/tests/test-validator-php.sh`, `.claude/tests/test-supply-chain-composer.sh`, `.claude/tests/test-runtime-capture-php.sh`, `.claude/tests/test-mcp-recipes-laravel.sh` exist and pass.

- [ ] `.mcp.json.example` includes a `laravel-boost` server block (commented-out, copy-paste-ready).

## Non-goals

- **Symfony detection.** This spec is Laravel-first. Symfony shares some signals (composer.json) but has distinct conventions (no `artisan`, different test runner defaults). Add as a follow-up if real-world demand surfaces.
- **CodeIgniter / Yii / other PHP frameworks.** Same reasoning — Laravel dominates the PHP-SaaS niche this work is motivated by.
- **Auto-installing Pint / PHPStan / Larastan when missing.** Manifest-as-intent only — same posture as Biome/Ruff. Declared + missing → advisory; not declared → silent skip.
- **`php-cs-fixer` detection separate from Pint.** Pint wraps php-cs-fixer; supporting both would duplicate signal without adding value for Laravel forks (Pint is canonical). Vanilla PHP projects using php-cs-fixer directly are out of v1 scope.
- **Multi-stack PHP+JS monorepo support.** Validator's first-lockfile-wins logic means a Laravel fork with a Next.js workspace would route to PHP only (or JS only, depending on order). Spec 015 (monorepo-stack-detect) is the canonical place to fix this; not duplicating that work here.
- **Inline / on-save linting feedback.** Validator runs at sub-agent edit boundaries; not extending to editor-time integration.

## Open questions

- [ ] **Pest detection precedence over PHPUnit when both are declared.** A project that declares `pestphp/pest` AND `phpunit/phpunit` (Pest depends on PHPUnit) — which test runner does the validator pick? Default: Pest if `pestphp/pest` is declared, otherwise PHPUnit. Verify in implementation; document in `.claude/rules/php-laravel-support.md`.
- [ ] **Composer scripts pattern detection.** When `composer.json` defines `scripts.test`, should validator prefer `composer test` over `vendor/bin/phpunit` (similar to JS validator preferring `bun test` over direct invocation)? Lean toward yes for parity, but the composer script wrapping may hide actual exit codes — confirm during dogfood.
- [ ] **Exact runtime-introspect detector pair list.** Single-token vs pair detection: should `vendor/bin/phpunit` (with path) be a single-token match, or do we detect just `phpunit` as a token-suffix? Same Q for `vendor/bin/pest`. Decision affects how forks that alias the binary (e.g. via composer scripts) are captured.
- [ ] **Laravel-boost MCP exact package name and runtime requirements.** Mentioned in `.claude/rules/runtime-introspect.md` and `.claude/rules/mcp-recipes.md` as "the laravel-boost MCP" without recipe details. Verify upstream (likely `github.com/laravel/boost`) for actual `.mcp.json` block shape, npm/composer install path, version pinning, and security stance. Block scaffolding the recipe section until verified.
- [ ] **Inference patterns for PHPUnit + Pest output.** Need real-world output samples (passing run, failing run, fatal error) to write inference rules. Capture during dogfood against a real Laravel test suite, document in `.claude/rules/runtime-introspect.md`.

## Context / references

- **Conversation 2026-05-18 (Acme Yard project bootstrap)** — establishes the user need (12-microSaaS portfolio on Laravel) and the inspection findings that motivate this spec.
- **`.claude/validators/run.sh`** — current 6-stack detection, lint extension, TDD patterns table. The single largest surface to modify.
- **`.claude/hooks/supply-chain-scan.sh`** — manager+verb table, manifest+lockfile basename allowlist, bare-install detection sub-path.
- **`.claude/hooks/supply-chain-advise.sh`** — Edit/Write basename allowlist (sibling to scan.sh — kept in sync).
- **`.claude/hooks/runtime-capture.sh`** — detector pair list, inference table per detector.
- **`.claude/hooks/mcp-recipes-hint.sh`** — stack signal table, recipe suggestion union.
- **`.claude/rules/{lint-validator,typecheck-advisory,supply-chain,runtime-introspect,mcp-recipes,tdd}.md`** — capacity behavior docs that need PHP/Laravel sections (or new dedicated `.claude/rules/php-laravel-support.md` umbrella).
- **`.claude/rules/memory-placement.md`** + memory entry `feedback_agent0_changes_ship_via_rules_not_memory.md` — confirms this work ships via `.claude/{hooks,rules,validators,tools}` (which propagate to forks), not memory (which doesn't).
- **`.claude/memory/cc-platform-hooks.md`** — the 29-event surface; PostToolUse + PostToolUseFailure dual registration pattern (spec 020) applies symmetrically to PHP detector additions.
- **Spec 013** (`docs/specs/013-lint-validator-extension/`) — the prior art for adding a stack-specific linter (Biome for JS, Ruff for Python). The PHP branch (Pint + PHPStan) follows the same manifest-as-intent shape.
- **Spec 015** (`docs/specs/015-monorepo-stack-detect/`) — the monorepo walk pattern; relevant to the non-goal "multi-stack monorepo" exclusion.
- **Spec 020** (PostToolUseFailure dual-registration) — applies to runtime-capture's new PHP detectors.
- **Laravel canonical signals** — `artisan` executable file at repo root, `composer.json` with `laravel/framework` dep, `bootstrap/app.php`. These mirror the canonical Next.js signals (`next.config.{js,ts}` etc.).
- **Laravel-boost MCP** (upstream verification pending) — github.com/laravel/boost (to confirm).
