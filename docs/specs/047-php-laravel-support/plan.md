# 047 — php-laravel-support — plan

_Drafted from `spec.md` on 2026-05-18. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Implement the seven gaps in severity order, with each step shipping its test file before moving on. The three blockers (validator detection, supply-chain composer support, runtime-introspect detectors) come first — they're the silent-failure modes that turn a Laravel fork into a governance-blind environment. The four advisory gaps (TDD patterns, lint, MCP recipes, CLAUDE.md docs) follow in any order; they degrade signal but don't break the harness.

The work is surgical: 5 shell scripts (validator + 4 hooks) get new detection branches keyed off `composer.json` + Laravel canonical files (`artisan`, `bootstrap/app.php`); 6 rule docs get PHP-specific sections; 1 new umbrella rule doc indexes them; CLAUDE.md gains a `## PHP / Laravel` capacity section mirroring the existing capacity entries; `.mcp.json.example` gains a `laravel-boost` server block. Once Agent0 is PHP-aware, `sync-harness.sh` propagates the changes to the new `acmeyard` fork in one command — closing the loop the user demanded.

## Files to touch

**Create:**

- `.claude/rules/php-laravel-support.md` — umbrella rule doc indexing the 7 capacity touchpoints. Doubles as the PR description input.
- `.claude/tests/test-validator-php.sh` — exercises `validators/run.sh` against a synthetic Laravel fork fixture: pure-PHP project, Pest-declared project, PHPStan-declared project, Pint-declared-but-missing project.
- `.claude/tests/test-supply-chain-composer.sh` — exercises `hooks/supply-chain-scan.sh` for `composer require/remove/update/install` shapes, OVERRIDE marker on each, bare-install + dirty-composer.json advisory.
- `.claude/tests/test-runtime-capture-php.sh` — exercises `hooks/runtime-capture.sh` for `vendor/bin/phpunit`, `vendor/bin/pest`, `php artisan test`, `composer test`. Asserts detector + inferred_status across PASS / FAIL / fatal-error fixtures.
- `.claude/tests/test-mcp-recipes-laravel.sh` — exercises `hooks/mcp-recipes-hint.sh` against fixtures with: `artisan` file only, `composer.json` with `laravel/framework`, Laravel + DB (`DATABASE_URL` in `.env.example`), Laravel + Next.js workspace (multi-stack), Symfony-only (negative test — should NOT fire Laravel recipe).

**Modify:**

- `.claude/validators/run.sh` — add PHP detection branch (slotted after `rust`, before the no-stack fallback so JS-heavy monorepos with composer.json don't accidentally hijack the JS branch); add PHP test patterns to the TDD warnings table (line ~229); add Pint + PHPStan to the lint extension (lines ~113–171, mirroring Biome/Ruff shape).
- `.claude/hooks/supply-chain-scan.sh` — add `composer` to manager set (line ~258 case statement) with verbs `require remove update install`; treat `composer install` (no packages) as a lockfile-resolve in the bare-install path; add `composer.json` + `composer.lock` to the manifest basename match list (line ~363).
- `.claude/hooks/supply-chain-advise.sh` — sibling: add `composer.json` + `composer.lock` to its basename allowlist (kept in sync with scan.sh).
- `.claude/hooks/runtime-capture.sh` — add PHP detector pairs (lines ~190–243): single-token `vendor/bin/phpunit` / `./vendor/bin/phpunit` / `vendor/bin/pest` / `./vendor/bin/pest`; pair-token `artisan test` / `composer test` / `composer lint`; extend inference table with PHPUnit/Pest patterns (`OK`, `Tests: N, Assertions: M`, `FAILURES!`, `Errors:`, Pest's `✓` / `✗`).
- `.claude/hooks/mcp-recipes-hint.sh` — add Laravel signal detection in `detect_at()` (line ~57): canonical signal is `artisan` file existence at the scanned path, secondary is `composer.json` containing `laravel/framework`. Add `have_laravel` global mirroring `have_next`. Add laravel-boost recipe to the union (line ~196).
- `.claude/rules/supply-chain.md` — document composer in the manager table, manifest+lockfile basenames, and audit-log examples.
- `.claude/rules/lint-validator.md` — document the PHP branch with Pint + PHPStan rules (mirror the JS Biome / Python Ruff structure).
- `.claude/rules/runtime-introspect.md` — document the new PHP detector pairs and inference patterns; update the detector-list table.
- `.claude/rules/tdd.md` — add PHP to the per-language test-pattern recognition table.
- `.claude/rules/mcp-recipes.md` — add a `### Laravel Boost MCP` section with install command + runtime requirements + security stance, mirroring the existing 4 recipe sections.
- `.mcp.json.example` — add `laravel-boost` server block, commented out (`//` prefix per the file's existing convention).
- `CLAUDE.md` — add `## PHP / Laravel` capacity section between an existing capacity section and `## Compact Instructions`. Brief paragraph naming the validator/supply-chain/runtime-introspect/lint/TDD/MCP-recipes behavior under PHP, with the trailing `See .claude/rules/php-laravel-support.md.` link.

**Delete:** none.

## Alternatives considered

### Alternative 1: Single big PHP rule doc instead of touching 6 capacity rule docs

Rejected because each capacity's rule doc is the contract for that capacity (lint behavior lives in `lint-validator.md`, supply-chain behavior in `supply-chain.md`, etc.). A new reader investigating "how does the lint validator behave on Laravel?" will look in `lint-validator.md`, not in a separate PHP-specific doc. The umbrella `.claude/rules/php-laravel-support.md` is an **index** pointing readers to each capacity's PHP section — not a replacement. This matches spec 013's pattern (lint extension docs added IN-PLACE to `lint-validator.md`, with the per-stack subsection).

### Alternative 2: Detect via Laravel filename heuristics alone (skip composer.json parse)

Rejected because Agent0's manifest-as-intent posture (codified in spec 013) requires reading the manifest to determine declared tooling intent (Pint? PHPStan? Pest? PHPUnit?). Filename-only detection would catch the canonical `artisan` file but miss the per-project linter/test-runner choices. Composer.json parse is `jq`-based and cheap; no reason to skip it.

### Alternative 3: Wait until Acme Yard hits a real problem in production before adding support

Rejected because silent-failure mode is the worst-of-both-worlds: the agent assumes Agent0's governance fired (validator gated edits, supply-chain blocked bad installs) but nothing actually fired. Sub-agents make decisions based on assumed-fired governance; the assumptions don't hold. The first real failure surfaces a multi-step regression that's hard to debug. Fail-loud (= add PHP detection now) is the discipline.

### Alternative 4: Gate PHP additions behind `CLAUDE_PHP_SUPPORT=1` env var

Rejected because once `composer.json`-based detection is added, the "off" mode is structural: forks without `composer.json` see no behavior change. Env-var gating would add friction (every Laravel fork user has to set it) without solving a real problem.

### Alternative 5: Refactor the validator into per-stack pluggable files before adding PHP

Rejected because it doubles the surface of this spec. The current monolithic `validators/run.sh` is well-understood, has tests, and adding one more elif branch is mechanical. A refactor would defer real value (PHP support) for architectural cleanup that hasn't paid for itself yet. Revisit when a 7th or 8th stack lands (the rule-of-three for premature abstraction).

## Risks and unknowns

- **Laravel-boost MCP upstream details unverified.** Both `.claude/rules/runtime-introspect.md` and `.claude/rules/mcp-recipes.md` mention "the laravel-boost MCP" in passing but neither provides install command, package name, or runtime requirements. The implementer must verify (likely `github.com/laravel/boost`) before writing the recipe section + `.mcp.json.example` block. If upstream is immature or absent, ship without the recipe in v1 and add as a follow-up (mark in `notes.md`).
- **PHPUnit + Pest inference patterns may need 2-3 dogfood iterations.** The inspection found these runners exist; real-world output samples (with/without colors, with/without verbose mode, fatal errors, parallel runner) are not in hand. Implementer should run real test suites against a Laravel fixture and iterate on the inference regex set. Document the final pattern table in `.claude/rules/runtime-introspect.md`.
- **First-lockfile-wins ambiguity in mixed-stack monorepos.** A fork with `composer.json` at root AND `package.json` in `apps/web/` — which stack wins? Current validator logic: first match in the elif chain. Decision: slot PHP detection LATE in the chain (after `rust`, before the no-stack fallback) so JS-leading monorepos route to JS. Document this ordering choice in the rule doc. Spec 015 (monorepo-stack-detect) is the right place for proper multi-stack walking; out of scope here.
- **Tokenizer drift risk in `supply-chain-scan.sh` vs `runtime-capture.sh`.** Adding composer to one and `composer test` to the other doubles the chance of subtle divergence. Mitigation: cross-reference comment in both, and the two test files (test-supply-chain-composer.sh + test-runtime-capture-php.sh) exercise overlapping shapes.
- **Composer-scripts (`composer test` → wraps `vendor/bin/phpunit`) may hide exit codes.** Need to verify composer doesn't swallow non-zero exits when wrapping scripts. If it does, the validator and runtime-capture inference must read stdout/stderr patterns; if it doesn't, exit code suffices. Test fixture should include both shapes.
- **Sync-harness manifest must cover all new files.** The 4 new test files in `.claude/tests/` need to be in the sync scope. Check `.claude/tools/sync-harness.sh`'s file glob set; `.claude/tests/` is already listed (per CLAUDE.md "Harness sync" section). New rule doc `.claude/rules/php-laravel-support.md` is automatically covered (`.claude/rules/*.md` glob).
- **`CLAUDE.md` capacity section ordering.** Where exactly to place the new `## PHP / Laravel` section? Best fit is near the other "stack-specific behavior" capacities: between `## Lint validator` / `## Typecheck advisory` and `## Memory`. The PR diff is mechanical but the ordering should be intentional; document the placement choice in `plan.md` if the implementer revisits.
- **Test runner choice in CI.** The new `.claude/tests/test-*.sh` files use bash + mock fixtures. Agent0 doesn't currently have CI; tests run manually. This is acceptable for v1 but means regressions can land undetected — open question whether to add a `.claude/tests/run-all.sh` as part of this spec or follow-up. Lean follow-up (out of scope here).

## Research / citations

- **Laravel Pint** — https://laravel.com/docs/pint (official docs; confirms `vendor/bin/pint --test` is the no-fix check mode, exits non-zero on style violations).
- **Larastan** — https://github.com/larastan/larastan (PHPStan wrapper with Laravel-aware rules; package name in composer is `larastan/larastan`).
- **PHPStan** — https://phpstan.org/user-guide/getting-started (vanilla PHPStan; package name `phpstan/phpstan`, invocation `vendor/bin/phpstan analyse`).
- **Composer lockfile semantics** — https://getcomposer.org/doc/01-basic-usage.md ("install vs require" distinction; `composer install` resolves the lockfile without mutating dependency declarations).
- **Pest** — https://pestphp.com (test runner; package `pestphp/pest`; invocation `vendor/bin/pest`; output uses `✓` / `✗` glyphs).
- **PHPUnit** — https://phpunit.de (canonical PHP test runner; `vendor/bin/phpunit`; summary lines `OK (N tests, N assertions)` or `Tests: N, Assertions: M, Failures: K`).
- **Laravel Boost MCP** — to verify at https://github.com/laravel/boost (mentioned in Agent0 rules; recipe details pending).
- **Spec 013** (`docs/specs/013-lint-validator-extension/`) — canonical prior art for adding a stack-specific linter. The Biome (JS) and Ruff (Python) shape directly informs the Pint/PHPStan shape.
- **Spec 015** (`docs/specs/015-monorepo-stack-detect/`) — informs the non-goal exclusion for multi-stack PHP+JS forks.
- **Spec 020** (PostToolUse + PostToolUseFailure dual registration) — applies symmetrically to PHP runtime-capture additions.
- **`.claude/memory/feedback_agent0_changes_ship_via_rules_not_memory.md`** — confirms placement of new content under `.claude/rules/` + hooks/validators/tools (not memory).
- **Conversation 2026-05-18 (Acme Yard bootstrap)** — establishes the user need, the 7 gaps inspection, and the goal-loop directive that triggered this spec.
