# 013 — lint-validator-extension — dogfood findings

_Recorded 2026-05-12 across pyshrnk (Python/ruff), shrnk (JS/TS/biome), and rshrnk (Rust — state-c only, out of 013 scope by design). Three states verified per fork where applicable: (c) silent skip, (b) declared+missing advisory, (a) declared+installed runs._

## Coverage matrix

| State | Pyshrnk (Python/uv) | Shrnk (JS/TS/bun) | Rshrnk (Rust) | Method |
| --- | --- | --- | --- | --- |
| (c) silent skip | PASS — hook exit 0, stderr empty, counter 0 | PASS — hook exit 0, stderr empty, counter 0 | PASS — `command` is pure `cargo test && cargo clippy`, no biome/ruff | Initial state (no manifest declaration). Via real `post-edit-validate.sh` with `agent_id`. |
| (b) declared+missing advisory | PASS (forced) — required hiding `uv` from PATH to bypass auto-sync | PASS (natural) — `bun test` does NOT auto-install; advisory fires directly | N/A — Rust isn't in 013 scope (cargo clippy already in validator base) | Validator direct + via real hook. |
| (a) declared+installed runs | PASS — `uv run python -m ruff check .` composes, finds real bug, blocks; bug fixed → ok=true | PASS — `bunx biome check` composes, finds 15 real bugs, blocks (ok=true happy path observed in lint-validator test suite, not re-run here) | N/A | Validator direct + via real hook. |

All 7 applicable checkpoints PASS — spec 013 behaves as defined. Rshrnk verification 2026-05-12 post spec 020 B3 dogfood graduation.

## Findings

### F1 — `uv run` auto-sync collapses state-b into state-a for uv-managed projects

**What**: When `pyproject.toml` declares ruff and `<py_prefix> = "uv run python"`, the validator probe `uv run python -m ruff --version` returns exit 0 even when ruff was never explicitly installed — because `uv run` auto-resolves the manifest and installs missing deps transparently before invoking the inner command.

**Observed**: In pyshrnk (uv-managed), adding `"ruff>=0.5.0"` to `[dependency-groups].dev` made the validator immediately compose `uv run python -m ruff check .` into the pipeline on the next run — no advisory ever fired. State-b advisory only became observable when `uv` was hidden from PATH (forcing `py_prefix = "python"` bare fallback).

**Implication**: The state-b advisory message is rarely visible in real-world uv-managed dev environments. It WILL fire in:
- Forks not using uv (poetry without `uv` installed; pip-only flows)
- CI environments where uv is absent
- The split-second between manifest edit and first `uv run` invocation in the same session (validator probe runs before the auto-sync triggers)

**Severity**: low. The auto-sync behavior is uv's design choice — it makes lint adoption *easier* in uv projects (no separate install step). The advisory message remains valuable for non-uv forks. Spec 013's invariant ("manifest-as-intent → declared = wants lint") is preserved; the difference is uv compresses (declared → installed) into one step.

**Action**: document in `.claude/rules/lint-validator.md` § Gotchas. No code change. Forks observing "I declared ruff but no advisory and no lint ran" should run `uv sync --dev` explicitly or check `uv run python -m ruff --version` manually.

### F2 — Real lint debt surfaced on first ruff invocation in pyshrnk

**What**: `tests/test_server.py:7:27` had `from wsgiref.types import StartResponse, WSGIApplication, WSGIEnvironment` but `StartResponse` was never referenced. Ruff `F401` (unused import) flagged on the very first run.

**Severity**: low (lint debt, not runtime bug). Fixed in the same dogfood pass to demonstrate the green-path transition.

**Implication**: Validates that spec 013 *immediately* surfaces dormant lint debt the moment a fork adopts a linter. Real value delivered on day one.

### F3 — Real lint debt in shrnk (15 errors → 3 after safe-fix attempt)

**What**: `bunx biome check` on shrnk surfaced 15 errors across 12 files. Running `bunx biome check --write` (safe fixes) reduced to 3 errors but reformatted 11 files (incl. `package.json`, `tsconfig.json`, `.claude/settings.json`, `.claude/presence/statusline.mjs`). The 3 residual: `lint/complexity/useLiteralKeys` (FIXABLE, unsafe), `lint/style/noNonNullAssertion` (real type assertion review needed), `lint/style/useTemplate` (FIXABLE, unsafe).

**Severity**: medium for the residual lint issues (style + one legitimate type review). **High for the side-effect**: biome reformatted `.claude/` harness paths, which would induce sync drift against Agent0.

**Implication**: see F4.

### F4 — Biome's default scan path includes `.claude/` (and other harness dirs)

**What**: Biome by default scans the entire repo (excluding `.git/`, `node_modules/`, `dist/`, `build/`). Shrnk has `.claude/presence/statusline.mjs` (an MJS file managed via Agent0 harness) AND `.claude/settings.json`. Biome reformatted both during `--write`, which would conflict with Agent0's sync-harness expectation that fork's `.claude/` matches Agent0's master copy.

**Severity**: medium. Forks adopting biome without an ignore config will see their `.claude/` reformatted, then sync-harness will flag those files as "customized" (hash drift), refusing to update them without `--force` or `--force-except`.

**Recommendation**: forks adopting biome should ship a `biome.json` with `files.ignore` covering at minimum `.claude/`, plus the usual `node_modules/`, `dist/`, etc. Example:

```json
{
  "files": {
    "ignore": [".claude/**", "node_modules/**", "dist/**", "build/**", "coverage/**"]
  }
}
```

**Action**: document in `.claude/rules/lint-validator.md` § Gotchas — `.claude/` is harness territory, NOT fork product code; forks adopting linters must ignore it to preserve sync compatibility. (Symmetric advice would apply to Python projects adopting ruff — but ruff's default `extend-exclude` already handles `.venv/`, `__pycache__/`, etc., and Python tools generally don't scan `.claude/` because no `.py` files live there in any forks today.)

### F5 — Biome's default style preferences (tabs, etc.) clash with existing fork conventions

**What**: Biome 1.9 defaults to tabs for indentation; shrnk used 2-space throughout. The `--write` pass also reformatted JSON files (package.json) to tabs. Adopting biome with zero config = adopting biome's style opinions wholesale.

**Severity**: low (cosmetic), but produces a noisy first commit (11 files reformatted).

**Recommendation**: forks adopting biome should explicitly declare style preferences in `biome.json` if they want to preserve existing conventions:

```json
{
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2
  }
}
```

**Action**: brief mention in `.claude/rules/lint-validator.md` § Gotchas. Not a spec 013 bug — fork-adoption guidance.

### F6 — Supply-chain gate fires on `bun install` (correctly) during state-a setup

**What**: When running `bun install` to transition from state-b to state-a, the supply-chain PreToolUse hook blocked with `supply-chain-block: bun install detected`. Required two-line `# OVERRIDE: ...` marker on its own line.

**Severity**: zero — this is spec 009 working as designed. Inter-spec composition validated: spec 013 dogfood respects spec 009's discipline.

**Implication**: forks doing real-world state-b → state-a transitions will need OVERRIDE markers on their `<manager> install` calls. The advisory text from spec 013 ends with `run \`bun install\`` (etc.); operators acting on the advisory will hit spec 009's gate and need to add an override. Documented behavior; no action.

### F7 — Inline `# OVERRIDE:` marker fails per spec design

**What**: First attempt at `bun install # OVERRIDE: ...` (inline trailing) was rejected by supply-chain-scan. Required two-line shape.

**Severity**: zero — documented behavior. Reinforces the spec 002 false-positive fix (anchored start-of-line). Worth keeping in mind when authoring dogfood docs for forks.

## State-b reachability summary

| Manager | Auto-sync? | State-b naturally observable? | Workaround needed? |
| --- | --- | --- | --- |
| bun | NO | YES | none |
| pnpm | NO | YES (untested in this pass, inferred from bun parity) | none |
| npm | NO | YES (untested) | none |
| yarn | NO | YES (untested) | none |
| uv | YES (on `uv run`) | NO under default usage | hide uv from PATH OR run between manifest edit and first `uv run` |
| poetry | NO (untested) | YES (inferred) | none |
| pdm | NO (untested) | YES (inferred) | none |
| pip-only | NO | YES (inferred) | none |

The state-b advisory is fully observable in 6/7 supported managers. The uv-collapse caveat (F1) is the only exception.

## Recommended `.claude/rules/lint-validator.md` amendments

Add the following bullets to § Gotchas (in priority order):

1. **uv's auto-sync collapses state-b** (F1). One paragraph, names `uv run`, suggests `uv run python -m ruff --version` as manual probe.
2. **`.claude/` should be linter-ignored** (F4). Recipe `biome.json`/`ruff.toml` snippet showing ignore for `.claude/**`.
3. **Biome's default style is opinionated** (F5). One sentence noting fork should declare `formatter.indentStyle` if it cares.
4. **Supply-chain composition on install** (F6). One sentence noting state-a transition needs OVERRIDE marker.

The amendments are documentation-only — no code changes. Spec 013's behavior is correct as shipped; the amendments capture fork-onboarding wisdom learned in dogfood.

## Follow-up specs

None proposed. The findings are:
- Documentation amendments (covered above)
- Real fork lint debt (the forks' own concern; not Agent0 scope)
- Spec composition validations (already worked correctly)

No spec gap surfaced. Spec 013 ships as-is.

## Artifacts

- pyshrnk: `pyproject.toml` + `uv.lock` + `tests/test_server.py` (unused-import fix) modified
- shrnk: `package.json` + `bun.lock` modified; src reformatting reverted (preserved for fork maintainer's separate decision on adopting biome's default style + ignore config)
- This file: `docs/specs/013-lint-validator-extension/dogfood-findings.md`
