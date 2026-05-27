# 095 — harness-consumer-vocab — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

_Order = plan.md's commit-per-category structure. Each task = one commit-shaped unit; `git commit` after each completes so the PR diff is reviewable per category._

- [ ] 1. **Add canonical glossary section to `.claude/rules/harness-sync.md`.** Insert a `## Glossary` block near the top defining: `harness` (Agent0 itself, the plugin/framework being consumed), `consumer project` (a project that installs Agent0's capacity bundle via `sync-harness.sh`), `shipped surface` (the file set the manifest propagates to consumer projects), and the surviving git-operation usage of "fork" ("fork the Agent0 repo on GitHub to contribute upstream" — correct, stays). This block is the contract every subsequent rename hunk references.
- [ ] 2. **Rename `.claude/rules/harness-sync.md` (84 occurrences).** Heaviest single file; do this after the glossary lands so cross-references inside the rule resolve consistently. Per-occurrence reviewed — flag any remaining "fork" that turns out to be legitimate git-operation usage. Commit: `refactor(rule): rename fork → consumer project in harness-sync.md (095)`.
- [ ] 3. **Rename the CLI in `.claude/tools/sync-harness.sh` (61 occurrences) + `.claude/tools/memory-project.sh` (1).** Positional arg `<fork-path>` → `<consumer-path>`; shell variable `FORK_PATH` → `CONSUMER_PATH` (all ~60 internal refs in sync-harness.sh); usage / help / error message strings (`missing <fork-path>` → `missing <consumer-path>`); in-script comments. Run `bash .claude/tools/sync-harness.sh --help` after edit; confirm help renders the new names. Commit: `refactor(cli): rename <fork-path> → <consumer-path> in sync-harness (095)`.
- [ ] 4. **Rename rules-heavy (5 files, ≥10 occurrences each).** `mcp-recipes.md` (21), `memory-placement.md` (14), `image-gen.md` (12), `lint-validator.md` (11). Per-occurrence reviewed. Commit: `refactor(rules): rename fork → consumer project across heavy-load rules (095)`.
- [ ] 5. **Rename rules-medium (3 files, 5-10 occurrences each).** `typecheck-advisory.md` (8), `php-laravel-support.md` (8), `secrets-scan.md` (6). Watch for `first-fork friction` → `first-consumer friction` in `secrets-scan.md` and `supply-chain.md` prose. Commit: `refactor(rules): rename fork → consumer in medium-load rules (095)`.
- [ ] 6. **Rename rules-light (6 files, ≤5 occurrences each).** `runtime-introspect.md` (4), `supply-chain.md` (3), `routines.md` (3), `rule-load-debug.md` (2), `hook-chain-latency.md` (1), `compaction-continuity.md` (1). Commit: `refactor(rules): rename fork → consumer in light-load rules (095)`.
- [ ] 7. **Propagation pair — atomic sub-commit (4 surfaces).** Rename `fork-bound surface` → `shipped surface` and `fork-bound files` → `shipped files` consistently across the pair:
  - `.claude/rules/propagation-advisory.md` (5 occurrences) — rename surface terminology + body prose.
  - `.claude/hooks/propagation-advise.sh` (5 occurrences) — internal comment refs; regex labels stay unchanged (they target leak-pattern classes, not destination vocabulary).
  - `.claude/tests/propagation-advisory/06-non-fork-path-silent.sh` → rename file to `06-non-shipped-path-silent.sh`; update assertion strings.
  - `.claude/memory/propagation-hygiene.md` (22 occurrences, per OQ #3 carve-out) — body + frontmatter `description:`.
  Run `bash .claude/tests/propagation-advisory/*.sh` after; all PASS. Commit: `refactor(propagation-pair): fork-bound → shipped surface; sync rule + memory pair (095)`.
- [ ] 8. **Rename hooks (3 files).** `session-start.sh`, `session-stop.sh`, `mcp-recipes-hint.sh` — 1 occurrence each in stderr text or comment. Commit: `refactor(hooks): rename fork → consumer in hook prose (095)`.
- [ ] 9. **Rename skills (15 files).** All SKILL.md files (`brainstorm`, `image`, `product`, `remind`, `routine`, `sdd`, `skill`) plus references and pipeline templates listed in `plan.md § Files to touch § Skills`. Mostly 1-3 occurrences each. Commit: `refactor(skills): rename fork → consumer in SKILL.md prose + product pipeline (095)`.
- [ ] 10. **Rename tests (~40 files under `.claude/tests/`).** Local shell variable `FORK="$TMPDIR/fork"` → `CONSUMER="$TMPDIR/consumer"` consistently across all `.claude/tests/harness-sync/*.sh`; mkdir paths `fork/` → `consumer/`; assertion message strings. Rename files:
  - `13-gitignore-merge-fork-missing.sh` → `13-gitignore-merge-consumer-missing.sh`
  - `14-gitignore-merge-fork-customized.sh` → `14-gitignore-merge-consumer-customized.sh`
  - `.claude/tests/project-memory/02-no-fork-propagation.sh` → `02-no-consumer-propagation.sh`
  Also touch `.claude/tests/harness-sync/README.md`, `.claude/tests/secrets-scan/07-template-portable.sh` (21 occurrences — "fresh fork" prose), `.claude/tests/typecheck-advisory/{01,06}-*.sh`, `.claude/tests/instruction-drift/05-sync-harness-detects-agents-md-drift.sh`, `.claude/tests/mcp-recipes/05-co-exists-with-011.sh`, `.claude/tests/propagation-advisory/{01,02,05}-*.sh` (the 06 file already renamed in task 7). After rename, run **every renamed test file** and the full `.claude/tests/harness-sync/` suite; all PASS. Verify zero hits from `grep -rn '\bfork\b\|FORK' .claude/tests/` except intentional git-operation prose. Commit: `refactor(tests): rename fork → consumer in test fixtures + filenames (095)`.
- [ ] 11. **Rename entrypoints + validator (3 files).** `CLAUDE.md` (7 occurrences) and `AGENTS.md` (8) — sections covering harness sync, propagation, runtime entrypoints. Edit CLAUDE.md first, then mirror the renamed sections verbatim into AGENTS.md (they are baseline-tracked siblings — drift triggers `.claude/tests/instruction-drift/05-sync-harness-detects-agents-md-drift.sh` failure). `.claude/validators/run.sh` — 1 comment occurrence. Run instruction-drift test after; PASS. Commit: `refactor(entrypoints): rename fork → consumer in CLAUDE.md + AGENTS.md (095)`.
- [ ] 12. **Re-bake sync-harness baseline.** Run `bash .claude/tools/sync-harness.sh --baseline` to regenerate `.claude/harness-sync-baseline.json`. Every shipped file has a new hash because every shipped file changed text. This commit is the LAST one in the PR — separate so reviewers see baseline-only churn vs vocabulary churn. Commit: `chore(095): re-bake harness-sync baseline post-rename`.

## Verification

_Acceptance checks tied to `spec.md` § Acceptance criteria. Run all from repo root after task 12 lands._

- [ ] **AC #1 — consumer project reads no fork-of-consumer vocabulary.** Run `grep -rn '\bfork\b\|\bforks\b' .claude/rules/ CLAUDE.md AGENTS.md 2>/dev/null | grep -v -E '(fork the .*(repo|on GitHub)|on GitHub to (fork|contribute))'`. Manually audit each remaining hit: it must be legitimate git-operation prose. Zero consumer-relationship usages.
- [ ] **AC #2 — CLI exposes renamed vocabulary.** Run `bash .claude/tools/sync-harness.sh --help`. Output mentions `<consumer-path>` as positional arg name; `--force-except` description references "consumer customization"; error messages on missing arg say `missing <consumer-path>`.
- [ ] **AC #3 — entrypoints frame Agent0 as harness.** Read § Harness sync + § Runtime entrypoints in both `CLAUDE.md` and `AGENTS.md`. Wording frames Agent0 as a harness/framework consumed by consumer projects, not as a repo to be forked.
- [ ] **AC #4 — propagation-advisory wording matches.** Edit any shipped-surface file (sample: `.claude/rules/harness-sync.md`) with a trivial whitespace change; trigger `propagation-advise.sh`. Advisory message references `shipped surface`. `.claude/rules/propagation-advisory.md` body uses the same vocabulary. Revert the trivial edit.
- [ ] **AC #5 — canonical glossary defined.** `.claude/rules/harness-sync.md` contains `## Glossary` (or equivalent named section) defining `harness`, `consumer project`, `shipped surface`, and the surviving git-operation "fork" carve-out.
- [ ] **AC #6 — test suite green.** Run `bash .claude/tests/harness-sync/run-all.sh` (or each `01-...sh` through `34-...sh` individually) — all PASS. Same for `.claude/tests/propagation-advisory/*.sh`, `.claude/tests/instruction-drift/*.sh`, `.claude/tests/project-memory/*.sh`, `.claude/tests/secrets-scan/07-template-portable.sh`, `.claude/tests/typecheck-advisory/{01,06}-*.sh`, `.claude/tests/mcp-recipes/05-co-exists-with-011.sh`.
- [ ] **AC #7 — sync drift-check is clean against a real consumer.** Run `bash .claude/tools/sync-harness.sh --check --agent0-path=. /home/goat/mei-saas` (or codexeng). Output reports every shipped file as `stale` (expected — every file changed text) and zero spurious `customized-refused` from vocabulary in places consumers haven't touched. After consumer-side `--apply` (run by next session, not as part of this PR), `--check` reports clean.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- PR body should warn: "every shipped file's hash changes; consumer-side next sync expects 'stale' on every entry — that's the OQ #5 deferred sync paying off in one big `--apply`, not a regression."
- Per-occurrence review is non-negotiable per plan.md § Alternatives considered (blind sed rejected). Reviewers should sample at least 5 hunks per commit for legitimate-fork-usage compliance.
- If task 11 fails the `instruction-drift` test, CLAUDE.md and AGENTS.md drifted textually; the canonical recovery is to copy the renamed section from CLAUDE.md to AGENTS.md verbatim (CLAUDE.md is source of truth for shared sections).
