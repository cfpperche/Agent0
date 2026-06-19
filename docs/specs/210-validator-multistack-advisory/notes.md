# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-19 — parent — codex engine review (gate task 7): SHIP-WITH-CHANGES → folded

Codex confirmed the JSON contract is safe (advisory is stderr-only, declarative path stays silent via `stack=declared`), hot-path cost acceptable (one bounded `git ls-files`, skipped for declared/opt-out). Two findings folded:
- **Medium — detector vocabulary must mirror the fallback exactly.** Original detector counted `setup.py`/`setup.cfg`/`requirements*.txt` (not fallback Python markers → false "python unaudited" from a stray `tools/setup.py`) and mapped js only via `package.json` (a lockfile-only audited js could be missed). Fix: (a) detector markers = exactly the fallback's (`pyproject.toml`/`requirements.txt`, `package.json`, `go.mod`, `Cargo.toml`, `composer.json`); (b) **always include the audited `$stack` in the set before counting** so a lockfile-only audited stack is never missed. Guarded by verify.sh (f).
- **Low — tracked vendored/generated manifests counted → noise.** Fix: prune `vendor|node_modules|dist|build|out|coverage|.venv|venv|target|testdata|fixtures?|__fixtures__` from `git ls-files` output. Guarded by verify.sh (g).

Transcript: `.agent0/.runtime-state/codex-exec/20260619T150841Z-read-only-adversarial-review-for-agent0-spec-210/`. Post-fold: verify.sh 10/10, all validator suites green.

### 2026-06-19 — parent — codex final diff review (task 11): SHIP-WITH-CHANGES → folded

Codex confirmed no rule-doc drift (the 3 rewrites correctly represent detection-only/fallback-only/non-blocking/validator.json-as-execution-contract/opt-out). Three findings folded:
- **Medium — JS fallback markers not fully mirrored.** Detector scanned only `*package.json` for js; the fallback also audits js via lockfiles. Fix: added `bun.lockb`/`bun.lock`/`bunfig.toml`/`pnpm-lock.yaml`/`package-lock.json` to the git-ls-files globs + root-degrade + case map → js (true superset-mirror; a lockfile-only js subtree is now detected).
- **Low — verify.sh under-proved non-blocking.** Added: compare `.ok`/`.exit` between advisory-on and `SKIP=1` (must be identical → proved `{"ok":false,"exit":1}` both); and assert the off-git root-degrade path actually fires the advisory (not just emits valid JSON).
- **Low — spec/plan/tasks carried pre-fold Python markers.** Updated all three to the folded marker set.

Transcript: `.agent0/.runtime-state/codex-exec/20260619T152129Z-final-read-only-review-for-agent0-spec-210-the-m/`. Post-fold: verify.sh 11/11.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

## Verification log

### 2026-06-19T15:31:32Z — pass (1/1) — source: tasks.md
- `bash docs/specs/210-validator-multistack-advisory/verify.sh` — pass
