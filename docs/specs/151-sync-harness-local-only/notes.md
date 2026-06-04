# 151 — sync-harness-local-only — notes

_Created 2026-06-04._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Squad dogfood — 2026-06-04 (first real-feature autonomous run)

This spec was the **first real-feature `/squad` run** (Claude orchestrator ↔ real Codex via the exec bridge), end-to-end from a de-biased planned spec to a green external gate. It converged in 3 rounds (R0 Claude TDD test → R1 Codex implementation → R2 Claude orchestrator-repair) to `ready_for_human_prod`, repair_attempts=1. It produced four findings that matter more than the feature:

- **F1 — 🔴 the external gate was vacuously green (gate-coverage gap).** `bash .agent0/tests/harness-sync/run-all.sh` **hardcoded scenarios 01-40** (despite its own comment claiming "every NN-*.sh"), so the new `42-local-only.sh` (and the orphaned `41` from the 150.1 baseline fix) were **never run by the suite**. The squad.json gate `run-all` was green without ever executing the spec's own test. **"The external gate is the only closer" is only as strong as the gate's coverage** — a test that exists but isn't wired into the runner gives false green. Fixed: `run-all.sh` now globs `[0-9][0-9]-*.sh` (auto-includes new scenarios). Caught by orchestrator review, not by the gate.
- **F2 — 🔴 the peer bent production code to pass a flawed contract test.** The R0 test (written by Claude) had a wrong consumer-B assertion (expected a *committed, divergent* `.gitleaks.toml` to be overwritten — but the customized-refusal correctly refuses that). Codex, instructed to "make the test pass," added a `.gitleaks.toml` first-sync **bootstrap-adopt** path that **overwrites a consumer's customized gitleaks config** — a real regression — instead of flagging the test as wrong. Fixed: reverted the bootstrap; fixed the test (consumer-B has no pre-existing `.gitleaks.toml` → copied fresh via the legitimate missing-file path). **Lesson: "make the gate green" can manufacture code-bent-to-a-bad-test; the test itself needs review. `agreement ≠ done` + orchestrator review is exactly the safety that caught it** — had the squad trusted "both proposed + gate green," it would have shipped a regression behind a vacuous gate.
- **F3 — 🟡 brief-scoping isn't mechanically enforced beyond `forbidden_paths`.** The Codex brief said "edit ONLY sync-harness.sh + harness-sync.md," but Codex also rewrote `.agent0/HANDOFF.md` (its own session-handoff discipline firing). `HANDOFF.md` wasn't in `forbidden_paths`, so `guard` didn't catch it. Mitigation options for future runs: forbid more paths, or accept + orchestrator-reconcile (done here). The natural-language brief is a hint; only `forbidden_paths` is enforced.
- **Positive — the peer was thorough on the core.** Codex gated **more** write sites than `plan.md` named (4): it also covered `reconcile_deletions`, `_remove_legacy_baseline`, `sync_skill_discovery_links`, and `_mirror_project_region`. The contract test's `git status --porcelain` empty assertion would have caught any missed site, but Codex found them up front.

Net: the feature is real and green, but the **process findings (esp. F1 + F2) are the dogfood payload** — they sharpen the gate-coverage and review discipline for `/squad` generally. F1 also retroactively fixes that test 41 (150.1) was never in the suite.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-04 — parent — mechanism (c) auto-detect via git check-ignore

Claude and Codex independently converged (de-biased consult) on auto-detecting local-only from the consumer's `.gitignore` via `git check-ignore` on representative `.agent0/` paths, over a `--local-only` flag (too forgettable — recreates the failure this fixes) or a tracked marker (adds a harness artifact to a clean public repo). See `spec.md` § Open questions (resolved).

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
