# 005 — tdd — plan

_Drafted from `spec.md` on 2026-05-10. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Three surgical changes plus two cross-doc updates — no new hook, no new gate, the JSON contract grows by one additive field.

1. **Write `.claude/rules/tdd.md`** — the working agreement. ~70 lines, voice and structure mirror `.claude/rules/spec-driven.md`. Covers: red→green→refactor, when TDD applies, when to skip (inheriting SDD's skip list by reference), the BDD-scenario-to-test-name mapping, the warning channel produced by the validator, and the override semantics for genuinely test-exempt edits.

2. **Extend `.claude/validators/run.sh`** — add per-stack test/prod pattern detection and a `warnings: []` field to the JSON output. The warnings field is **always present** in the output of stack-detected runs (often as `[]`), and is **omitted entirely** in the no-stack-detected path so this base repo continues to emit byte-identical output (acceptance scenario 3). Within stack-detected runs, the validator runs `git diff --name-only` (with no args, picking up unstaged work) to see what changed in the session, classifies each file as prod or test using language-aware patterns plus the `CLAUDE_TDD_TEST_PATTERNS` env var override, and if any prod files changed but no test files did, appends `{"kind":"no_test_change_for_prod_edit","files":[...],"message":"..."}` to `warnings`.

3. **Extend `.claude/hooks/post-edit-validate.sh`** — after parsing the validator JSON for `ok`, also read `warnings` if present. On the exit-0 (allow) path, echo each warning's `message` to stderr in a clearly-labeled block (e.g., `tdd-advisory: <message>`). The hook still exits 0 — warnings never block. This mirrors the delegation-gate's `additionalContext` shape semantically: the agent sees the advisory on its next turn but can proceed.

4. **Cross-link from `.claude/rules/delegation.md`** — add a short paragraph noting that the validator now also surfaces non-blocking advisories through the same pipeline (specifically the TDD test-coverage advisory), so anyone reading delegation.md sees the warning channel exists and points at `tdd.md` for details. ~5 lines, minimal surgery.

5. **Add a `## Test-driven development` section to `CLAUDE.md`** — same shape as the existing `## Delegation` and `## Spec-driven development` sections (one paragraph, links the rule, no implementation detail).

The reason this design works without a new hook: the existing `post-edit-validate.sh` already runs on every sub-agent edit, already invokes the validator, already has a stderr channel that surfaces to the agent. Wiring TDD warnings through this pipeline is strictly additive — no new hook surface, no new state file, no new env-var-conventions to teach. The validator gains one section; the hook gains five lines of "if warnings, echo each".

## Files to touch

**Create:**
- `.claude/rules/tdd.md` — the working agreement (~70 lines).

**Modify:**
- `.claude/validators/run.sh` — per-stack test pattern detection, `git diff --name-only` classification, additive `warnings` array in JSON output (only when a stack is detected).
- `.claude/hooks/post-edit-validate.sh` — parse `warnings` array on exit-0 path, echo each `message` to stderr with a `tdd-advisory:` prefix (or similar consistent label).
- `.claude/rules/delegation.md` — add ~5 lines noting the validator-warning channel and pointing at `tdd.md`.
- `CLAUDE.md` — add `## Test-driven development` paragraph, mirroring the existing Delegation and SDD sections.

**Delete:** none.

## Validator JSON contract — additive change

Today's contract:

```json
{ "ok": true|false, "command": "...", "exit": 0, "duration_ms": 0, "stdout": "...", "stderr": "..." }
```

After this spec, when a stack is detected:

```json
{
  "ok": true,
  "command": "bun test && bun tsc --noEmit",
  "exit": 0,
  "duration_ms": 8421,
  "stdout": "...last 4 KB...",
  "stderr": "...last 4 KB...",
  "warnings": [
    {
      "kind": "no_test_change_for_prod_edit",
      "files": ["src/foo.ts", "src/bar.ts"],
      "message": "Production files changed without any test changes in this session diff. If the change is genuinely test-exempt (rename, comment, refactor without behavior change), no action needed; otherwise, consider adding a test. See .claude/rules/tdd.md."
    }
  ]
}
```

When no stack is detected (Agent0 base today), the output stays exactly:

```json
{ "ok": true, "command": "no-stack-detected", "exit": 0, "duration_ms": 0, "stdout": "", "stderr": "" }
```

— no `warnings` field, no behavior change.

The hook treats `warnings` as optional (`jq has("warnings")` check). Old validators continue to work; new validators in projects without TDD-relevant warnings emit `warnings: []` and the hook's loop simply doesn't print anything.

## Per-stack test patterns

Initial detection table (all case-sensitive glob patterns, matched against `git diff --name-only` output):

| Stack | Test patterns (any match → file is "test") |
|---|---|
| bun, pnpm, npm | `*.test.ts`, `*.test.tsx`, `*.test.js`, `*.test.jsx`, `*.spec.ts`, `*.spec.tsx`, `*.spec.js`, `*.spec.jsx`, `__tests__/**`, `tests/**`, `test/**` |
| python | `*_test.py`, `test_*.py`, `tests/**`, `test/**` |
| go | `*_test.go` |
| rust | `tests/**`, `*_test.rs`, `*_tests.rs` |

Files not matching any test pattern (and not a doc/config — see below) are classified as **prod**.

A small exclusion list keeps obvious non-code out of the prod set: `*.md`, `*.txt`, `*.json` (configs), `*.yml`, `*.yaml`, `*.toml`, `LICENSE`, `*.gitignore`, `.gitkeep`. Edits to these never trigger the warning. Document files that are genuinely behavior-bearing (rare — e.g., generated code committed under `*.json`) are out of scope; user can override via the env var pattern (effectively excluding their patterns from "prod" by including them in "test", a defensible bend).

`CLAUDE_TDD_TEST_PATTERNS="<glob1> <glob2> ..."` (space-separated globs) overrides the language-detected list entirely when set. The validator parses with `read -ra` (bash-3.2 compatible).

## Hook change — stderr surfacing

In `post-edit-validate.sh`, after the existing `ok=true` branch (where the script currently writes `0` to the state file and exits 0), add a stanza that reads any `warnings` array from the validator output and echoes each `message` to stderr with a `tdd-advisory:` prefix. The exact bash is short — the validator output is already in scope as a captured variable, jq is already a hard dep, and the surfacing happens before the `exit 0` so the harness picks up the stderr.

Exit 0 stays. The advisory shows up in the agent's next turn just like any other stderr from a non-blocking hook (per the empirically-confirmed harness behavior from spec 002's live test, the harness surfaces hook stderr to the agent context).

## Alternatives considered

### Blocking hook on missing test (`PreToolUse(Edit)` rejects untested prod edits)

Rejected. Spec explicitly forbids ("No new blocking hook") and the conversation that drove this spec specifically rejected this design. Reason: gameable in 30 seconds (a trivial passing test), false-positives on legitimate test-exempt edits (rename, doc, formatting refactor), and creates an arms race between the gate and the agent's ability to bypass via override or trivial test stubs. Warnings preserve auditability without inviting that arms race.

### Separate audit log (`.claude/tdd-audit.jsonl`)

Considered (spec open question 1, option c). Rejected. Adds a new file, a new state, a new place to look. The audit-log-only surfacing depends on the agent reading the file — but the agent doesn't have a routine "tail the TDD log" reflex. Stderr surfacing through the existing hook pipeline reuses behavior the agent already responds to (advisory text in the next turn).

### Embed warnings in the `stderr` field of validator JSON (no contract change)

Considered (spec open question 1, option b). Rejected. Mixes the warning signal with diagnostic output (compiler errors, test runner stderr). Parsing later would require regex-fishing the warning lines back out. Explicit `warnings` array is structured, machine-friendly, and adds ~3 lines to the validator and ~3 lines to the hook.

### Per-language test patterns hardcoded with no env-var override

Considered (spec open question 2, option b — the inverse). Rejected. Real projects have weird conventions (some teams put tests next to source as `Foo.tests.ts`, some put them under `spec/`). An override is cheap insurance. Default detection still works for the 80% case; the env var unblocks the rest without code changes.

### Restate skip rules independently in `tdd.md`

Considered (spec open question 3, option b). Rejected. SDD's `## When to skip` is the canonical list; restating creates two sources of truth that drift. Inheriting by reference keeps `tdd.md` shorter and forces the skip discipline to evolve in one place.

### Recommend a specific test framework per language

Rejected. Spec explicitly: "no test framework recommendation." Reason: project preference. The validator already detects the stack; whether the project uses jest, vitest, ava, mocha (JS) or pytest, unittest, nose (Python) is a choice the project owns. The rule documents the BDD-to-test-name mapping in framework-agnostic prose.

### Track per-agent edited files via `.claude/.delegation-state/agents/<agent_id>.files`

Considered as a more precise alternative to `git diff --name-only`. Rejected for the first iteration. The git-diff approach is one bash command, requires no new state file, and gives the right answer for the common case (sub-agent edits prod, no tests in the diff → warning). The per-agent-tracking version is more precise for nested-sub-agent or parent-mixed-with-sub-agent cases, but those are rare and the first iteration accepts the imprecision (documented as a known limitation in the rule). Revisit if real usage shows false-positives or false-negatives often.

## Risks and unknowns

- **Warning gets ignored.** A non-blocking advisory only works if agents pay attention. Mitigation: stderr surfaces to the agent's context (empirically confirmed in spec 002), and the rule explicitly says "if you saw a tdd-advisory and the change is not exempt, add a test before declaring done." If a future audit shows agents routinely ignoring warnings, the design might need to escalate (e.g., audit log of ignored warnings, or escalation to block on N consecutive ignores per agent_id). Not in scope for this spec.
- **Pattern table drift.** Test-naming conventions evolve (e.g., new JS frameworks introduce `.bench.ts` etc.). The patterns table in the validator will need maintenance. Mitigation: the env-var override exists as a fast escape hatch when the built-in patterns fall behind. Document maintenance expectation in the rule.
- **`git diff --name-only` includes parent + sub-agent edits in the same set.** Documented limitation: if the parent makes prod edits and the sub-agent makes only test edits, the warning won't fire (correct outcome). If the parent makes test edits and the sub-agent makes prod edits, also no warning (incorrect — sub-agent should have written its own tests). Real-world impact is low because parent + sub-agent collaboration on the same diff is unusual; revisit if observed.
- **`git diff --name-only` does NOT include untracked files** (discovered during dogfood, fix landed before spec close). A sub-agent that uses the `Write` tool to create a *new* test file leaves it untracked — plain `git diff` would miss it and the warning would falsely fire even though a test was added. Fix: the validator unions `git diff --name-only` with `git ls-files --others --exclude-standard` and dedupes via `sort -u`. Renames (the `R` status in porcelain) are handled correctly because both the old and new paths appear under one or the other source. Files with spaces in paths still work because the loop iterates with newline-IFS, not whitespace.
- **`git diff --name-only` may not run if the project isn't a git repo.** Defensive: if `git rev-parse --git-dir` fails, skip the warning logic entirely (no warnings emitted). Document this fallback in the rule.
- **`CLAUDE_TDD_TEST_PATTERNS` parsing.** Space-separated globs work for most cases; if a user has a glob with literal spaces in a path (rare), it breaks. Accepted: globs with literal spaces are pathological enough to ignore in v1.
- **Behavior in this base repo (validator inert).** Warnings logic only fires when a stack is detected. The base repo has no stack, so this entire spec is *also* inert here — the rule and the validator extension ship, but no warning will fire until a project plugs in a stack. This is the same dogfood-baseline state as 002-delegation: the discipline exists, the trigger is dormant.

## Research / citations

- `docs/specs/005-tdd/spec.md` — primary source for intent and the open-question defaults.
- `docs/specs/002-delegation/plan.md` § *Validator JSON contract* and § *Stack auto-detect order* — the contract being extended; this spec preserves all existing field semantics and adds one optional field.
- `docs/specs/002-delegation/spec.md` § *Acceptance criteria* — the no-stack-detected behavior (`ok=true, command="no-stack-detected"`) is preserved verbatim, satisfying spec 005 acceptance scenario 3 (no regression in this base repo).
- `docs/specs/004-bdd/spec.md` § *Acceptance criteria* — scenarios are the source of test names per spec 005 acceptance scenario 4. The mapping is documented in the new `tdd.md` rule.
- `.claude/validators/run.sh` — current implementation; the warning-extension surgery is localized to the per-stack branches plus a new "warnings collection" helper.
- `.claude/hooks/post-edit-validate.sh` — current implementation; the warning-surfacing surgery is a short addition on the exit-0 path, after the existing reset-counter logic.
- `.claude/rules/spec-driven.md` § *When to skip* — the source of truth that `tdd.md` inherits.
- TDD background reading (informational, no tooling adoption): Kent Beck, *Test-Driven Development: By Example* (2002); the original red-green-refactor formulation. Cited for lineage in `tdd.md`; this spec adopts no specific framework.
