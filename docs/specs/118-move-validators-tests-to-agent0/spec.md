# 118 — move-validators-tests-to-agent0

_Created 2026-05-29._

**Status:** shipped

## Outcome

Shipped 2026-05-29. `.claude/validators/run.sh` → `.agent0/validators/run.sh` and `.claude/tests/` (213 files) → `.agent0/tests/`, both via `git mv` (214 renames staged; validator is `R100`, so `git log --follow` traverses the move post-commit). `.claude/` now holds only the genuinely Claude-exclusive surfaces (agents, hooks, rules, skills, worktrees). All live references repointed via a scoped global sed: the 4 delicate spots verified by hand — sync-harness manifest (`COPY_CHECK_RECURSIVE`/`GLOBS`/`EXCLUDE`), the `lint-validator.md` + `typecheck-advisory.md` `paths:` frontmatter triggers, the `propagation-advise.sh` shipped-surface set (`.agent0/{validators,tests}/*` shipped; `.agent0/tests/propagation-advisory/*` excluded), and the `delegation-verify.sh` default validator path. `CLAUDE_DELEGATION_VALIDATOR` kept its name (non-goal). Validation: 18/19 suites pass from the new location; the lone failure (`typecheck-advisory/08`) is the pre-existing Node-compile-cache git-workspace pollution (HANDOFF-documented), not a regression — the validator ran and emitted its TDD JSON correctly. Repo-wide grep outside `docs/specs/` for `.claude/tests`/`.claude/validators` is empty; sibling `.claude/rules`/`hooks`/`skills` paths intact; `docs/specs/` frozen-clean vs HEAD.

**Incident (recovered):** the first sed pass corrupted 158 frozen committed-spec files — the file-list filter `grep -v '/docs/specs/'` mis-anchored because `grep -r` emits paths without a leading `./`. Recovered cleanly with `git checkout HEAD -- docs/specs/` (all corrupted specs were committed) + re-authoring spec 118's own three files. The plan's Approach now carries the corrected `(^|/)docs/specs/` anchor as a warning. See `notes.md`.

## Intent

Relocate the test suite (`.claude/tests/` → `.agent0/tests/`, 23 dirs / 213 files) and the project validator (`.claude/validators/run.sh` → `.agent0/validators/run.sh`) to the runtime-neutral `.agent0/` home, and repoint every live reference. This continues the umbrella-102 harness consolidation (the § Classification principle in `.agent0/memory/harness-home.md`): a surface belongs under `.agent0/` if both runtimes read/write it through the harness; it stays under `.claude/` only if genuinely Claude-exclusive (`settings.json` format, the `Agent` tool + its audit log).

Both surfaces are runtime-neutral and were parked as `deferred` in spec 102's gap matrix pending a real runtime-neutral consumer. **That trigger is now met for the validator:** `delegation-verify.sh` lives in `.agent0/hooks/` and is registered for **both** Claude (`settings.json`) and Codex (`.codex/config.toml.example`, specs 111 + 106), yet hardcodes the default `$PROJECT_DIR/.claude/validators/run.sh` — so a Codex-only consumer's runtime-neutral hook already reaches into `.claude/`, the exact cross-boundary split the consolidation exists to kill. The tests move alongside for coherence: they are maintainer/CI infrastructure, not Claude-exclusive, and the "shared test" (_would a Codex-only project still read this?_) puts them in `.agent0/`. This is a pure path relocation — same playbook as spec 105 (`.claude/tools` → `.agent0/tools`): `git mv` first, then repoint references in dependency-safe order, leaving `docs/specs/*` frozen.

## Acceptance criteria

- [ ] **Scenario: both surfaces live under `.agent0/`, `.claude/` homes gone**
  - **Given** the repo after this spec ships
  - **When** `ls .agent0/validators/run.sh .agent0/tests/` runs AND `ls .claude/validators .claude/tests` runs
  - **Then** the `.agent0/` paths exist (validator + 23 test dirs) AND both `.claude/` paths report "No such file or directory"

- [ ] **Scenario: git history preserved across the move**
  - **Given** the relocated `run.sh`
  - **When** `git log --follow --oneline .agent0/validators/run.sh` runs
  - **Then** it shows the file's pre-move history (the move used `git mv`, not delete+create)

- [ ] **Scenario: the validator still runs from its new home via the delegation-verify hook**
  - **Given** `.agent0/hooks/delegation-verify.sh`
  - **When** inspected
  - **Then** its default validator path resolves to `$PROJECT_DIR/.agent0/validators/run.sh` (no `.claude/validators` reference remains)

- [ ] **Scenario: full test suite green from the new location**
  - **Given** the relocated `.agent0/tests/`
  - **When** every suite's `run-all.sh` is invoked
  - **Then** each passes — no script references a stale `.claude/tests`/`.claude/validators` path; root-resolution (`$(dirname "$0")/../../..`) still resolves to the project root (depth-preserved)

- [ ] **Scenario: sync-harness manifest carries the new paths**
  - **Given** `.agent0/tools/sync-harness.sh`
  - **When** its `COPY_CHECK_*` arrays are inspected
  - **Then** `COPY_CHECK_RECURSIVE` lists `.agent0/tests`, `COPY_CHECK_GLOBS` lists `.agent0/validators|*.sh`, `COPY_CHECK_EXCLUDE` lists `.agent0/tests/propagation-advisory/*` — no `.claude/tests`/`.claude/validators` manifest entry remains; the harness-sync suite passes

- [ ] **Scenario: path-scoped rule frontmatter follows the validator**
  - **Given** `lint-validator.md` and `typecheck-advisory.md`
  - **When** their `paths:` frontmatter is inspected
  - **Then** both trigger on `.agent0/validators/run.sh` (a functional trigger — if missed, editing the moved validator stops loading its companion rule)

- [ ] No live (non-`docs/specs/`) reference to `.claude/tests` or `.claude/validators` survives: a repo-wide grep outside `docs/specs/` returns nothing (the `.claude/rules`/`.claude/hooks`/`.claude/skills`/`.claude/agents` paths are untouched and distinct).
- [ ] `propagation-advise.sh` shipped-surface classification follows the move (`.agent0/validators/*` + `.agent0/tests/*` shipped; `.agent0/tests/propagation-advisory/*` still excluded from the leak scan).

## Non-goals

- **Not renaming the `CLAUDE_DELEGATION_VALIDATOR` env var.** Its `CLAUDE_` prefix on a now-runtime-neutral path is a real (minor) smell, but renaming it in isolation is inconsistent — the repo has a whole family of `CLAUDE_*` env vars (`CLAUDE_TDD_TEST_PATTERNS`, `CLAUDE_DELEGATION_LOOP_BUDGET`, `CLAUDE_SKIP_*`). A prefix migration is a separate, broader decision; bundling one rename here would be arbitrary. The var keeps its name and behavior.
- **Not moving `.claude/rules` / `.claude/skills` / `.claude/agents`.** Still `deferred` in spec 102 (their trigger — "Codex actually consumes rules/skills" — is not yet met). Out of scope.
- **Not moving `.claude/worktrees/` or `.claude/hooks/`.** `worktrees` is CC-native (`EnterWorktree`); `delegation-gate.sh` is Claude-exclusive (`Agent` tool). Both genuinely Claude-owned per the principle.
- **Not changing what ships to consumers.** Pure relocation — tests + validator still ship via the manifest (just at the new path). Ship-or-not is unchanged; only the path changes.
- **Not adding a back-compat shim** at `.claude/tests`/`.claude/validators`. Violates the repo's no-shim discipline (CLAUDE.md); sync's deletion pass migrates consumers cleanly.
- **Not rewriting `docs/specs/*`** — frozen design memory, except this spec (118).

## Open questions

- [x] Should tests move too, or just the validator (whose trigger is met)? Resolved: move both. The user's directive is explicit ("mover validators e tests"), and splitting would leave `.agent0/validators/run.sh` invoked by tests still under `.claude/tests/` — re-creating a cross-home split. Bundling is less churn (one baseline bump, one coherent relocation), per the spec-105 bundling reasoning.
- [x] Rename the env var? No — see Non-goals.

## Context / references

- `.agent0/memory/harness-home.md` — the § Classification principle + the `deferred` disposition this spec resolves
- `docs/specs/102-harness-consolidate-agent0/` — the consolidation umbrella (gap matrix where validators/tests are `deferred`)
- `docs/specs/105-shared-tools-to-agent0/` — the directly-applicable precedent (`.claude/tools` → `.agent0/tools`); this spec mirrors its playbook
- `docs/specs/{111-delegation-verify-subagent-stop,106-delegation-hooks-multi-runtime}/` — made `delegation-verify.sh` runtime-neutral + Codex-registered (the trigger that vests the validator move)
- `.claude/rules/harness-sync.md` § Path relocations (capacity-only) — the consumer-migration posture
