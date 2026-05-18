# 047 — php-laravel-support — notes

_Created 2026-05-18._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`._

## Design decisions

### 2026-05-18 — parent — Pest precedence over PHPUnit

Pest declares `phpunit/phpunit` as a transitive dependency. A typical Laravel project running Pest has BOTH packages installed; the validator must decide which binary to invoke. Decision: check for `pestphp/pest` direct declaration in `composer.json` (require OR require-dev) — if present, Pest is the active runner; otherwise PHPUnit. Rationale: Pest's presence as a direct dep signals author intent ("I want Pest-style tests"); the transitive PHPUnit install is implementation-detail. Codified in `validators/run.sh` PHP branch and locked by test `02-pest-declared-uses-pest.sh`.

### 2026-05-18 — parent — PHP slotted late in validator elif chain

The current detection chain (`bun → pnpm → npm → python → go → rust`) was extended by adding `composer.json` detection AFTER `rust`, not before. Rationale: mixed-stack monorepos with `package.json` at root and `composer.json` in a subdir (or vice versa) — first-match-wins routes to whichever stack carries the dominant lockfile at root. JS-leading projects continue to route to JS (preserving existing behavior); only pure-PHP forks (no JS/Python/Go/Rust manifest at root) hit the PHP branch. Multi-stack walking is properly addressed by spec 015; spec 047 does not duplicate that work. Documented in `php-laravel-support.md` § *Gotchas*.

### 2026-05-18 — parent — Multi-linter advisory concatenation

PHP is the first stack where TWO lint primitives (Pint + PHPStan/Larastan) can fire independently. Existing JS/Python branches use a single `lint_advisory_msg` string — last-write-wins would silently overwrite the first advisory if both fired. Decision: concatenate with newline separator when a prior PHP advisory was already set. The validator stderr emit loop `printf '%s\n'` prints multi-line strings correctly. No new variable surface introduced; the existing channel handles it via in-branch concatenation. Locked by tests `07-pint-declared-missing-advisory.sh` (single advisory path); a future test could exercise the dual-advisory case explicitly, deferred to dogfood.

### 2026-05-18 — parent — Laravel Boost MCP install convention

Researched upstream (https://laravel.com/docs/13.x/boost). The boost MCP is unusual among MCPs in that it is INSTALLED INTO the Laravel project (`composer require laravel/boost --dev` + `php artisan boost:install`) rather than run via npx like all other recipes (Playwright, Chrome DevTools, DBHub, Next DevTools all use npx). The `.mcp.json` block invokes `php artisan boost:mcp` — relying on the local Laravel project's artisan binary. This means: (a) the recipe block in `.mcp.json.example` does NOT include an install command in its args (unlike npx-based recipes); (b) the install steps live in `mcp-recipes.md`'s Laravel Boost section + the inline comment in `.mcp.json.example`; (c) running the MCP from a non-Laravel working dir will fail (documented gotcha).

## Deviations

### 2026-05-18 — parent — TDD pattern work merged into Phase 1

`tasks.md` listed TDD pattern wiring as Phase 4 (a separate phase after the 3 blockers). In practice, the validator's TDD `default_patterns` case is in the same file (`validators/run.sh`) edited for Phase 1 (PHP stack detection); landing both edits as one Edit call to the file (one elif append + one case-row append) was simpler than splitting Phase 1 and Phase 4 into separate file modifications. Phase 1 + Phase 4 task checklists are checked off together; the work is correctly attributed in `php-laravel-support.md` § 4. Verification scenario for Phase 4 (`04-tdd-prod-php-without-test.sh`, `05-tdd-no-warning-when-test-edited.sh`) is in the validator-php test dir, not a separate tdd-php dir.

## Tradeoffs

### 2026-05-18 — parent — `--colors=never` flag in command_str for PHP

PHPUnit and Pest both default to ANSI-colored output. The runtime-capture hook already strips ANSI on storage (spec 011 ANSI-strip fix). I could have relied on that downstream strip and kept `command_str` minimal, OR disabled colors at source. Chose disable-at-source for two reasons: (a) inference patterns in `runtime-capture.sh` stay simpler (no need to anticipate every ANSI-prefix permutation across PHPUnit minor versions); (b) when the validator pipeline runs `vendor/bin/phpunit` as part of `command_str`, the captured stdout in the validator's JSON is also cleaner. Cost: one extra flag per command. Worth it.

## Open questions

### 2026-05-18 — parent — Composer-script wrapping of `composer test` — exit-code passthrough verified?

The spec.md open question Q2 asked: when `composer.json` defines `scripts.test`, should validator prefer `composer test` over `vendor/bin/phpunit`? I deferred this decision pending dogfood. Current state: validator unconditionally uses `vendor/bin/phpunit` (or `vendor/bin/pest`) — does NOT detect `scripts.test`. The runtime-capture hook DOES capture `composer test` if the agent invokes it that way (detector="composer-test"). This creates an asymmetry: validator and runtime-capture see different shapes when the fork uses composer scripts. Resolution path: once a real Laravel fork runs both, observe whether `composer test` consistently preserves exit codes from PHPUnit; if yes, switch validator to prefer `composer test` for parity with how a developer would run it. Until verified, the asymmetry stays. Owner: parent agent during Acme Yard dogfood.

### 2026-05-18 — parent — Laravel 11+ phpunit emits JSON output by default (dogfood finding)

Acme Yard end-to-end dogfood surfaced: a vanilla `composer create-project laravel/laravel` ships with PHPUnit configured to emit JSON-shaped output by default — `{"tool":"phpunit","result":"passed","tests":2,...}` — NOT the canonical `OK (N tests, M assertions)` line my original inference table expected. Pre-fix, the probe returned `inferred_status: UNKNOWN`. Fixed by adding a JSON-specific pattern branch at the top of the PHP inference case: `"result":"passed"` → PASS, `"result":"failed"` → FAIL. Placed first because the JSON line is short, often the entire output, and the JSON pattern is more specific than the legacy summary patterns. Two new tests (06-phpunit-laravel-json-pass.sh, 07-phpunit-laravel-json-fail.sh) lock the behavior. Same JSON shape applies to `pint` (`{"tool":"pint","result":"passed"}`) so the pattern is reusable across PHP runners — but Pint's output is captured by the validator pipeline, not the runtime-capture hook (different surface).

### 2026-05-18 — parent — Laravel-canonical-first detection precedence (dogfood finding)

Acme Yard end-to-end dogfood surfaced: a vanilla Laravel 11 scaffold INCLUDES `package.json` (for Vite frontend tooling), and the original elif chain (`bun → pnpm → npm → ... → php`) routed all Laravel forks to the npm branch — completely defeating PHP detection. Pre-fix, validator emitted `npm test --silent` and failed with `exit: 1` (no test script). Fixed by prepending a Laravel-canonical check BEFORE the JS branch: when `artisan` exists at root AND `composer.json` declares `laravel/framework` (in require OR require-dev), route to PHP unconditionally. Pure-PHP non-Laravel projects still hit the late `composer.json` elif. Documented inline in the validator with the surfacing context. Pure non-Laravel forks with both composer.json + package.json (rare — Symfony-with-Vue or similar) still route to JS by default; if that becomes a real problem, spec 015 (monorepo-stack-detect) is the right place.

### 2026-05-18 — parent — sync-harness force-overwrite for in-flight Agent0 evolution

When iterating on Agent0 source AFTER an initial fork sync, the hash-compare logic in `sync-harness.sh --check` flags the fork's older copies of evolving files as "customized" (correctly — they differ from current source) and refuses to overwrite without `--force`. This is correct behavior but confusing during spec-047 development: re-sync after a source edit needed `--force --force-except='.gitignore'` to push the legitimate updates without clobbering Laravel's own .gitignore. NOT a Agent0 bug — the customization detection works as designed; the workflow gotcha is "Agent0 evolves DURING fork bootstrap" which is unusual outside spec dev. Documented for future spec authors.

### 2026-05-18 — parent — Inference for `composer-test` may miss when script wraps non-PHPUnit runners

The inference table for `composer-test` reuses the PHPUnit/Pest pattern set (FAILURES!, Tests: N passed, etc.). If a fork defines `composer test` as wrapping a non-PHPUnit/non-Pest runner (e.g. `infection` for mutation testing, or a custom bash script), the inference will fall through to UNKNOWN. This is a known limitation — the alternative (try to detect what the script wraps) is fragile. Resolution: documented in `php-laravel-support.md`; agents seeing UNKNOWN status should fall back to `exit` field (when present) or stdout inspection. Owner: parent agent during Acme Yard dogfood.
