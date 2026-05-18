# 047 — php-laravel-support — tasks

_Generated from `plan.md` on 2026-05-18. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Validator PHP detection (blocker)

- [ ] 1. Modify `.claude/validators/run.sh`: insert a new elif branch (after `Cargo.toml` / rust, before the empty-`command_str` fallback) that detects `composer.json` → sets `stack="php"`, picks `vendor/bin/pest` when `composer.json` declares `pestphp/pest` in `require-dev` else `vendor/bin/phpunit`, composes `command_str` accordingly. Also adjust the TDD `default_patterns` case (line ~229) to add `php) default_patterns='tests/* *Test.php *_test.php' ;;`
- [ ] 2. Create `.claude/tests/test-validator-php.sh`: fixtures for pure-PHP composer.json, Pest-declared, PHPStan-declared, Pint-declared-but-missing, and TDD diff classification. Assert validator command, advisory lines, and `warnings` array shape.
- [ ] 3. Run `bash .claude/tests/test-validator-php.sh`; assert PASS.

### Phase 2 — Supply-chain composer support (blocker)

- [ ] 4. Modify `.claude/hooks/supply-chain-scan.sh`: add `composer) verbs="require remove update install" ;;` to the case statement (line ~258); extend the bare-install sub-path (line ~325) to include `composer.install` so a bare `composer install` with dirty `composer.json` fires the bare-install advisory; add `composer.json` and `composer.lock` to the manifest basename match (line ~363).
- [ ] 5. Modify `.claude/hooks/supply-chain-advise.sh`: mirror — add `composer.json` and `composer.lock` to its basename allowlist (keep in sync with scan.sh; cross-ref comment).
- [ ] 6. Create `.claude/tests/test-supply-chain-composer.sh`: exercise `composer require pkg`, `composer remove pkg`, `composer update`, bare `composer install` with dirty composer.json, OVERRIDE marker for each, and Edit/Write on composer.json. Assert decision values and audit-log rows.
- [ ] 7. Run `bash .claude/tests/test-supply-chain-composer.sh`; assert PASS.
- [ ] 8. Update `.claude/rules/supply-chain.md`: add composer row to the manager-detection table; add composer.json + composer.lock to the manifest+lockfile basename allowlist section; add a composer gotcha if discovery surfaces one during implementation.

### Phase 3 — Runtime-introspect PHP detectors (blocker)

- [ ] 9. Modify `.claude/hooks/runtime-capture.sh`: add single-token detectors for `vendor/bin/phpunit`, `./vendor/bin/phpunit`, `vendor/bin/pest`, `./vendor/bin/pest` (lines ~190–207); add pair-token detectors `artisan test → artisan-test`, `composer test → composer-test`, `composer lint → composer-lint` (lines ~210–223); extend the inference table with PHPUnit (`OK (`, `Tests: N, Assertions: M`, `FAILURES!`, `Errors:`) and Pest (`✓`, `✗`, `Tests:  N passed`) pattern cases (lines ~282–387).
- [ ] 10. Create `.claude/tests/test-runtime-capture-php.sh`: feed synthetic `tool_input.command` + `tool_response.stdout` for each detector × each status (PASS/FAIL/fatal-error) into the hook, assert detector field and inferred_status in the resulting `last-run.json`.
- [ ] 11. Run `bash .claude/tests/test-runtime-capture-php.sh`; assert PASS.
- [ ] 12. Update `.claude/rules/runtime-introspect.md`: add the new detector pairs to the v1 detector table; add a "PHP test runners" row to the inference heuristics; document the `artisan test` vs `vendor/bin/phpunit` selection logic.

### Phase 4 — TDD test patterns for PHP

- [ ] 13. (already done in task 1 via the `default_patterns` case extension — verify by re-reading the relevant section of `validators/run.sh`). If task 1 inadvertently missed this hunk, add it now.
- [ ] 14. Update `.claude/rules/tdd.md`: add PHP to the per-language test-pattern recognition table near the existing JS/Python/Go/Rust list. Note Pest + PHPUnit conventions.

### Phase 5 — Lint validator (Pint + PHPStan)

- [ ] 15. Modify `.claude/validators/run.sh` lint extension (lines ~113–171): add `elif [ "$stack" = "php" ]; then` branch after the Python branch. Inside: check `composer.json` for `laravel/pint` in `require-dev` → if installed at `vendor/bin/pint` append `&& vendor/bin/pint --test` else emit `lint-advisory: pint declared in composer.json but not installed — run \`composer install\``. Same shape for `phpstan/phpstan` OR `larastan/larastan` → `&& vendor/bin/phpstan analyse --no-progress` (or advisory).
- [ ] 16. Extend `.claude/tests/test-validator-php.sh` (from task 2) with lint cases: Pint declared+installed, Pint declared+missing, PHPStan declared+installed, both declared+installed. Assert the command extension and advisory lines.
- [ ] 17. Run the updated test; assert PASS.
- [ ] 18. Update `.claude/rules/lint-validator.md`: add a `**PHP.**` paragraph mirroring the existing `**JS/TS.**` and `**Python.**` paragraphs. Document Pint + PHPStan detection rules, install-command resolution (`composer install`), and any PHP-specific gotchas surfaced during implementation.

### Phase 6 — MCP recipes Laravel detection

- [ ] 19. Research the Laravel Boost MCP via WebFetch on `https://github.com/laravel/boost` (or equivalent). Capture: package name, install command (`composer require laravel/boost` or `npx`?), runtime requirements, security stance, suggested `.mcp.json` block shape. If upstream is absent/immature, document the gap in `notes.md` and ship the recipe section without the block in v1.
- [ ] 20. Modify `.claude/hooks/mcp-recipes-hint.sh` `detect_at()` function: add `have_laravel=0` global (alongside `have_next` / `have_browser` / `have_db`); inside detect_at, check for `artisan` file at `$path` (canonical), else check `composer.json` for `laravel/framework` dep via `jq` (with jq-free grep fallback mirroring the existing pattern at lines ~93–108); append a `${prefix}artisan` or `${prefix}composer.json:laravel/framework` signal label. After detection, add `if [ "$have_laravel" -eq 1 ]; then add_recipe "laravel-boost-mcp"; add_recipe "playwright-mcp"; fi`.
- [ ] 21. Create `.claude/tests/test-mcp-recipes-laravel.sh`: fixtures for (a) `artisan` file only, (b) `composer.json` with `laravel/framework` only, (c) Laravel + DB signal (DATABASE_URL or `database/migrations/` dir), (d) Laravel inside an `apps/api/` workspace dir, (e) Symfony-only project (negative test — should NOT fire laravel-boost). Assert emitted signals and recipe union.
- [ ] 22. Run `bash .claude/tests/test-mcp-recipes-laravel.sh`; assert PASS.
- [ ] 23. Update `.claude/rules/mcp-recipes.md`: add the stack-signal-table row for Laravel; add a `### Laravel Boost MCP` section mirroring the existing 4 recipes (source, what-it-provides, `.mcp.json` block, install, when-to-enable, runtime requirements, security).
- [ ] 24. Add the `laravel-boost` server block to `.mcp.json.example` (commented out with `//` prefix matching the file's existing convention).

### Phase 7 — Docs umbrella + CLAUDE.md

- [ ] 25. Create `.claude/rules/php-laravel-support.md`: umbrella rule doc that indexes the 7 capacity touchpoints (validator, supply-chain, runtime-introspect, TDD, lint, MCP recipes, CLAUDE.md). Each touchpoint gets a brief paragraph + a link to the canonical capacity rule doc. Doubles as the PR description input.
- [ ] 26. Update `CLAUDE.md`: insert a new `## PHP / Laravel` capacity section between an existing capacity section and `## Compact Instructions`. Mirror the existing capacity-section shape (one paragraph naming the behavior, trailing `See .claude/rules/php-laravel-support.md.`).

### Phase 8 — Sync to Acme Yard fork

- [ ] 27. Coordinate with user: user confirms `acmeyard.com` domain purchased (Cloudflare Registrar or equivalent), then user creates `acmeyard` GitHub repo (private initial). If user wants me to create the repo via `gh repo create`, I do so on their behalf.
- [ ] 28. Initialize Laravel 11 scaffold in `/home/goat/acmeyard` via `composer create-project laravel/laravel acmeyard` (or equivalent). User runs this — composer install is a privileged action gated by supply-chain.
- [ ] 29. Run `.claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0` against `/home/goat/acmeyard` to verify scope; then `--apply` to sync the harness state. Verify diff via `git -C /home/goat/acmeyard diff` before any commit.
- [ ] 30. Smoke test the fork: from `/home/goat/acmeyard`, edit any `app/Models/*.php` file (synthetic edit), run `vendor/bin/phpunit`, then `bash .claude/tools/probe.sh last-run`. Confirm validator command non-empty, audit log records appropriately, probe returns the phpunit snapshot.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [ ] V1. Spec scenario "validator detects PHP via composer.json" verified by task 3 test pass.
- [ ] V2. Spec scenarios for supply-chain composer (4 scenarios) verified by task 7 test pass.
- [ ] V3. Spec scenarios for runtime-introspect (3 scenarios) verified by task 11 test pass.
- [ ] V4. Spec scenario "TDD advisory fires for prod-PHP without test edits" verified by task 3 test (extended in task 13).
- [ ] V5. Spec scenarios for lint (Pint runs + Pint missing advisory + PHPStan runs) verified by task 17 test pass.
- [ ] V6. Spec scenario "MCP recipes hint laravel-boost" verified by task 22 test pass.
- [ ] V7. Spec scenario "end-to-end smoke" verified by task 30 manual execution.
- [ ] V8. Spec static-fact criterion "`.claude/rules/php-laravel-support.md` exists" verified by file presence after task 25.
- [ ] V9. Spec static-fact criterion "test files exist" verified by file presence after tasks 2 + 6 + 10 + 21.
- [ ] V10. Spec static-fact criterion "`.mcp.json.example` has laravel-boost block" verified by file diff after task 24.
- [ ] V11. Run `.claude/tests/test-validator-php.sh && .claude/tests/test-supply-chain-composer.sh && .claude/tests/test-runtime-capture-php.sh && .claude/tests/test-mcp-recipes-laravel.sh` end-to-end; all four exit 0.
- [ ] V12. After task 30 sync, `.claude/delegation-audit.jsonl` and `.claude/supply-chain-audit.jsonl` in `/home/goat/acmeyard` record correctly under the harness.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

(empty at scaffold time — populate as implementation surfaces incidents worth recording at PR-description level; routine in-flight decisions go to `notes.md` instead)
