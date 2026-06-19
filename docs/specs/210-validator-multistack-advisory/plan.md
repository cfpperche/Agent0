# 210 — validator-multistack-advisory — plan

_Drafted from `spec.md` on 2026-06-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

A small, detection-only addition to `.agent0/validators/run.sh` plus a 3-rule doc rewrite. No execution change, no new pipeline. The validator already: (1) checks `.agent0/validator.json` first and sets `stack="declared"` when present; (2) computes `changed_files` from git early; (3) emits advisory lines to its own stderr before running the pipeline (`lint_advisory_msg`, `typecheck_advisory_msg`, `test_advisory_msg`). I add a fourth advisory in the same emit block, gated to the **fallback path only**.

Mechanism: after the fallback chain has chosen the audited `$stack` (and only when `$stack` is a real detected stack, NOT `declared`), run a `detect_all_stacks` helper that uses `git ls-files` to find tracked manifests across the tree, maps them to the stack vocabulary, and yields the SET of distinct stacks. If that set has >1 entry, build `multi-stack_advisory_msg` naming the audited stack + the others, pointing at `.agent0/validator.json`. Emit it with the other advisories. Opt-out via `CLAUDE_VALIDATOR_SKIP_MULTISTACK=1`. Graceful degrade: not-a-git-repo or `git` absent → fall back to root-marker detection (or skip), never error.

Order: implement `detect_all_stacks` + the advisory wiring, prove it with a focused test script (polyglot-with-subtree / declarative-present / single-stack / git-absent), then rewrite the 3 rules, then run the existing validator test suites to confirm no regression.

## Files to touch

**Modify:**
- `.agent0/validators/run.sh` — add (a) `detect_all_stacks()` using `git ls-files` over manifest globs that MIRROR the fallback chain exactly (`package.json` + js lockfiles `bun.lockb`/`bun.lock`/`bunfig.toml`/`pnpm-lock.yaml`/`package-lock.json`→js; `pyproject.toml`/`requirements.txt`→python; `go.mod`→go; `Cargo.toml`→rust; `composer.json`→php) → distinct stack set, ignore-aware via git + vendored-tree pruned, with a root-marker degrade when not a git repo; [codex fold: NOT setup.py/setup.cfg/requirements-variants — they aren't fallback markers] (b) the `multi-stack_advisory_msg` build, gated on `stack != declared` AND `!CLAUDE_VALIDATOR_SKIP_MULTISTACK` AND `|stacks| > 1`; (c) emit it in the existing advisory stderr block. Reuse the existing `node_modules`/vendor noise-filter posture.
- `.agent0/context/rules/lint-validator.md` — § Single-stack v1: stop promising "inherits multi-stack when the walk lands"; state fallback is compatibility-only, monorepos declare `validator.json`, fallback emits `multi-stack-advisory:` on partial coverage.
- `.agent0/context/rules/typecheck-advisory.md` — § No multi-stack typecheck: same rewrite.
- `.agent0/context/rules/php-laravel-support.md` — § No PHP-aware monorepo walk + the lockfile-precedence gotcha: same rewrite (PHP-in-subtree is exactly the motivating case the advisory now surfaces).
- A new validator rule mention (or extend `typecheck-advisory.md`, which already documents the validator contract) to document `multi-stack-advisory:` + `CLAUDE_VALIDATOR_SKIP_MULTISTACK`. Lean: document it in `typecheck-advisory.md` (the canonical validator-contract rule) to avoid a new rule file for one advisory.

**Create:**
- `docs/specs/210-validator-multistack-advisory/verify.sh` — fixtures: polyglot+subtree (advisory fires, names audited+unaudited), declarative-present (no advisory), single-stack (no advisory), git-absent (graceful), opt-out env (no advisory). Assert the validator JSON `ok`/`exit` are unchanged when the advisory fires.

**Delete:** none.

**Propagation:** `run.sh` + the rules are already under existing sync globs (`.agent0/validators|*.sh`, `.agent0/context/**`) — propagates once committed. No baseline edit.

## Alternatives considered

### Build the execution walk (run every detected stack's pipeline)

Rejected (codex BUILD-WITH-CHANGES + Agent0 hot-path culture). The validator runs every edit; multiplying execution by stack count turns it into mini-CI per edit. And spec 207's declarative contract already owns the monorepo execution case. The honest gap is *silent partial coverage*, which an advisory closes without execution cost.

### Diff-scoped execution (run only the changed files' stack)

Rejected for v1. Attractive (reuses `changed_files`) but semantically slippery: root/shared-file changes, generated clients, lockfiles, renames each need a policy, which recreates CI inside the harness. Deferred behind a real design if execution is ever wanted.

### Root-markers-only detection (no git)

Rejected as the primary path. It misses the motivating case (PHP in `services/api/`). Kept only as the **degrade** path when git is unavailable.

### A new dedicated rule file for the advisory

Rejected. One advisory does not warrant a new rule; fold the doc into `typecheck-advisory.md` (the canonical validator-contract rule) + the 3 rewrites.

## Risks and unknowns

- **`git ls-files` cost / volume.** Huge monorepos return many paths; but we only need the distinct-stack SET, so we map+dedupe and stop caring about count. Cheap string matching; no per-manifest work. Confirm with a multi-manifest fixture.
- **Detection vs audit disagreement.** `detect_all_stacks` must use the SAME markers as the fallback chain or the advisory could name a stack the validator wouldn't have audited (or miss one). Mirror the chain's markers exactly; cross-check in tests.
- **bun.lockb / non-manifest markers.** The fallback chain keys on lockfiles (`bun.lock`, `pnpm-lock.yaml`) AND `package.json`; detection should map JS via `package.json` (the stable cross-manager marker) to avoid lockfile-variant gaps. Note: detection granularity is "stack present", not "which JS runner".
- **Not-a-git-repo degrade.** Must never error. Guard `git rev-parse` (the validator already does this for `changed_files`); reuse that signal.
- **False multi-stack from tooling configs.** A JS repo with a stray `pyproject.toml` for a lint tool (e.g. a Python pre-commit hook) could trip a false "python" stack. Acceptable for an advisory (non-blocking, points at validator.json); note it as a known soft edge.

## Research / citations

- Codex CLI adversarial review, 2026-06-19 — `.agent0/.runtime-state/codex-exec/20260619T134615Z-design-position-to-pressure-test-multi-stack-mon/last-message.md`. Drove advisory-not-walk, git-ls-files subtree detection, declarative-first, 3-rule rewrite.
- `.agent0/validators/run.sh` — existing `validator.json` precedence (`stack="declared"`), `changed_files` git plumbing, and the advisory-stderr emit block this extends.
- `/unused-code` `unaudited_stacks` (`.agent0/tools/unused-code.sh`, specs 208/209) — the honesty pattern mirrored here.
