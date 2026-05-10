# 005 — tdd

_Created 2026-05-10. Status: spec ready (open questions resolved; ready for plan)._

## Intent

Add a TDD working agreement to the context layer — red/green/refactor as a *cultural* discipline, reinforced by the existing `post-edit-validate.sh` validator chain rather than enforced by a new blocking hook. The discipline says: when a delegated sub-agent (or the parent) modifies production code, a test should land in the same diff that exercises the change. The validator's job is to *notice* a prod-edit-without-test-edit and surface it as a **warning** (not a block); the human or agent reading the warning decides whether the change is genuinely test-exempt (typo, comment, doc) or whether the test was forgotten.

This spec is the natural follow-up to 004-bdd: BDD scenarios in `spec.md` describe observable behavior; TDD makes those scenarios into test cases that *outlive* the spec dir. A scenario titled "validator emits warning when prod files touched without test changes" maps near-directly to a test name like `validator emits warning when prod files touched without test changes`. The bridge from spec to tests becomes mechanical.

The reason this is a rule + validator extension and not a blocking hook: enforced TDD via `PreToolUse(Edit)` is gameable in 30 seconds (`expect(true).toBe(true)`) and false-positives on legitimate test-exempt edits (rename, doc, refactor that doesn't change behavior). A warning-shaped signal preserves the auditability without inviting the bypass arms race.

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan. See `.claude/rules/spec-driven.md` § Acceptance scenarios for shape guidance._

- [ ] **Scenario: A working-agreement rule documents the TDD discipline**
  - **Given** a fresh agent reads `.claude/rules/tdd.md`
  - **When** the agent considers writing or modifying production code
  - **Then** the rule clearly states the red→green→refactor loop, when TDD applies (production code paths, public API changes), when to skip (typos, doc-only, formatting, refactors with no behavior change), how the discipline interacts with the BDD scenarios in `spec.md`, and how the validator-warning signal closes the loop

- [ ] **Scenario: Validator emits a warning when prod files were edited without test files in the same agent session**
  - **Given** a delegated sub-agent (`agent_id` present in payload) edits a production file in a project that has a detected language stack and a test directory convention
  - **When** `post-edit-validate.sh` runs the extended validator
  - **Then** the validator output JSON includes a `warnings` array containing an entry like `{"kind":"no_test_change_for_prod_edit","files":[...]}`, the hook does NOT block (exit 0), the warning text surfaces in stderr or audit so the agent sees it on its next turn

- [ ] **Scenario: The validator stays inert in this base repo (no regression)**
  - **Given** the validator runs in the Agent0 base repo (no language stack present)
  - **When** any sub-agent edit triggers `post-edit-validate.sh`
  - **Then** the validator returns `ok=true, command="no-stack-detected"` exactly as before, with NO `warnings` field added — warning logic only runs when a real stack is detected

- [ ] **Scenario: BDD scenarios from spec.md map naturally to test case names**
  - **Given** a spec uses scenarios like `**Scenario: foo when bar**`
  - **When** the implementer (or sub-agent) writes tests for those scenarios
  - **Then** the test names mirror the scenario titles verbatim (e.g. `test('foo when bar', ...)` in JS, `def test_foo_when_bar(...)` in Python), and `.claude/rules/tdd.md` documents this mapping convention with a one-paragraph guide

- [ ] **Scenario: An override marker on a delegated brief documents a deliberate TDD-skip**
  - **Given** a sub-agent dispatch where the work is genuinely test-exempt (e.g. comment-only edit, dependency bump)
  - **When** the parent includes `# OVERRIDE: tdd-exempt: <reason ≥10 chars>` (or the reason text plainly says why no test) in the brief, AND the validator surfaces a warning anyway
  - **Then** the rule documents that the warning is informational in this case — no further action required, the audit log captures the override reason, and reviewers can confirm intent

- [ ] `.claude/rules/tdd.md` exists, follows the same voice/structure as `.claude/rules/spec-driven.md` (~60-100 lines, terse imperative tone, h2 sections), and cross-references both `spec-driven.md` (for the SDD/BDD relationship) and `delegation.md` (for the validator chain that surfaces the warning).

## Non-goals

- **No new blocking hook.** TDD is enforced culturally; no `PreToolUse(Edit)` rejects un-tested production edits. Reason: gameable, false-positives, and adds friction to legitimate exempt cases. Warnings are the right channel.
- **No test framework recommendation or scaffolding.** Each project picks its own (`jest` / `vitest` / `pytest` / `go test` / `cargo test`). The validator already detects the stack; the rule just documents the convention.
- **No retroactive backfill of tests for existing untested code.** Specs 001-004 shipped without TDD; that's the historical record. TDD applies forward; legacy code stays as-is until intentionally touched.
- **No metrics, scoring, or "TDD compliance %" dashboard.** The audit log + warnings are the trail; no further reporting layer.
- **No redesign of `post-edit-validate.sh` or the validator JSON contract beyond an additive `warnings` field.** Extension only — the existing `ok` / `command` / `exit` / `duration_ms` / `stdout` / `stderr` fields stay unchanged. Hooks consuming the contract today must continue to work.
- **No replacement of the BDD discipline.** TDD complements BDD (scenario titles → test names); it does not subsume it. Specs still get scenarios; tests are the executable form.
- **No language-specific test-name conventions enforced.** The mapping guide in the rule is illustrative; projects can adapt it (e.g., kebab-case test files vs snake_case methods) without violating the rule.

## Open questions

All three resolved 2026-05-10 by user approval of the suggested defaults:

- [x] **Warning surfacing channel.** Default (a): extend the validator JSON contract with an additive `warnings: [{kind, files, message}]` array. The post-edit-validate.sh hook gains logic to read the array and echo each warning's message to stderr on the exit-0 (allow) path, so the agent sees the warning on its next turn — same surfacing pattern as the delegation-gate's `additionalContext` advisory. Existing consumers of the contract (the hook reads `ok`) continue to work unchanged.
- [x] **Production-vs-test heuristic.** Default (a) + env var override: language-detected patterns are the default (e.g. `*.test.ts` / `__tests__/` for JS, `*_test.py` / `tests/` for Python, `*_test.go` for Go, `tests/` for Rust). A `CLAUDE_TDD_TEST_PATTERNS="<pattern> <pattern> ..."` env var lets a project override when its conventions differ.
- [x] **Skip path inheritance.** Default (a): TDD inherits the SDD skip list by reference, plus two TDD-specific additions (comment-only edits and dependency bumps). Single source of truth, less drift risk.

## Context / references

- `docs/specs/002-delegation/` — establishes the `post-edit-validate.sh` validator chain that this spec extends. The `agent_id` actor detection and the validator JSON contract documented there are the foundation.
- `docs/specs/004-bdd/` — establishes the scenario shape that TDD test names mirror. The "BDD scenarios → test case names" mapping is what makes the bridge mechanical.
- `.claude/rules/spec-driven.md` § *When to skip* — the source of truth for "skip" semantics that TDD inherits.
- `.claude/rules/delegation.md` — the gate-and-validator overview that this spec adds a warning channel to.
- `.claude/validators/run.sh` — the script that gains the per-stack test-pattern detection and the `warnings` array. Currently inert in Agent0 base; extension is also inert until a project plugs in a stack.
- `.claude/hooks/post-edit-validate.sh` — receives the extended validator output; gains the warning-forwarding logic (stderr echo on exit-0 paths) per open question 1.
- TDD background reading (no tooling adoption implied): Kent Beck, *Test-Driven Development: By Example* (2002); the original "red-green-refactor" formulation. Cited so future readers see the lineage; spec adopts no specific framework or test runner.
