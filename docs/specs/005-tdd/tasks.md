# 005 — tdd — tasks

_Generated from `plan.md` on 2026-05-10. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

Order is dependency-driven: validator first (the new contract surface), then the hook that consumes it, then the rule that documents both, then the cross-doc updates.

- [x] 1. **Extend `.claude/validators/run.sh`** — done (delegated, sub-agent `adcd89122a09f4a77`). Per-stack patterns + `CLAUDE_TDD_TEST_PATTERNS` override + non-git fallback + additive `warnings` array on stack-detected paths. Initial implementation used `git diff --name-only` only; dogfood (task 8) revealed this misses untracked files. Fix landed in this same task: union with `git ls-files --others --exclude-standard | sort -u`. Plan updated with the discovery.
- [x] 2. **Extend `.claude/hooks/post-edit-validate.sh`** — done (parent-direct edit). Post-`ok=true` reset stanza now reads `warnings` (jq `has("warnings")` check), iterates `.warnings[] | "tdd-advisory: " + .message` to stderr, then exits 0.
- [x] 3. **Write `.claude/rules/tdd.md`** — done (delegated, sub-agent `a51dc9b3da6e0e5cf`). 60 lines, 7 h2 sections in mandated order, all 7 cross-refs verified to resolve.
- [x] 4. **Cross-link from `.claude/rules/delegation.md`** — done (parent-direct edit). Paragraph added after the fail-open line of § *Post-edit validator loop*, pointing at `.claude/rules/tdd.md` with the `tdd-advisory:` channel description.
- [x] 5. **Add `## Test-driven development` section to `CLAUDE.md`** — done (parent-direct edit). One paragraph mirroring the existing § *Delegation* shape, pointing at `.claude/rules/tdd.md`.

## Verification

Each verification maps to a numbered scenario or the plain bullet in `spec.md § Acceptance criteria`.

- [x] 6. **Verify scenario 3 (no regression in this base repo)** — `bash .claude/validators/run.sh | jq -e '.command == "no-stack-detected" and (has("warnings") | not)'` returns exit 0. Output is byte-identical to pre-spec-005 (`{"ok":true,"command":"no-stack-detected","exit":0,"duration_ms":0,"stdout":"","stderr":""}`).
- [x] 7. **Verify scenario 2 (warning fires on prod-without-test)** — tmp project (`bun.lockb` + committed `src/foo.ts` + unstaged edit). Validator (run with `cd` into tmpdir — see Notes for the test-setup gotcha) emits `warnings: [{kind:"no_test_change_for_prod_edit", files:["src/foo.ts"], …}]`.
- [x] 8. **Verify scenario 2 corollary (test edit suppresses warning)** — same tmp scenario plus an untracked `src/__tests__/foo.test.ts`. Initial run produced a false-positive warning (the bug fixed in task 1's untracked-files patch); after fix, `warnings: []`. Validates the corollary AND covers the bug-fix regression.
- [x] 9. **Verify hook wiring (synthetic warning surfacing)** — synthesized payload with `agent_id="acc9-agent"` plus stub validator at `/tmp/stub-validator.sh` returning `warnings`. Hook stderr contains `tdd-advisory: Production files changed…`, exit 0, state file `acc9-agent` contains `0` (counter-reset preserved).
- [x] 10. **Verify scenario 1 + plain bullet (rule structural facts)** — `tdd.md` has 60 lines (lower bound of 60-100), 7 h2 sections in the mandated order, all 7 cross-refs (`spec-driven.md`, `delegation.md`, `validators/run.sh`, `post-edit-validate.sh`, `docs/specs/005-tdd/`, `docs/specs/001-governance-gate/`, `governance-gate.sh`) resolve.
- [x] 11. **Verify scenario 4 (BDD→test-name mapping documented)** — `tdd.md § From scenarios to tests` shows the JS (`test('foo when bar', …)`) and Python (`def test_foo_when_bar(…)`) framework-agnostic mappings, plus the per-language test-pattern table embedded inline so readers see what the validator recognises.
- [x] 12. **Verify scenario 5 (override semantics documented)** — `tdd.md § When to override` documents the `# OVERRIDE: <reason ≥10 chars>` shape, the `tdd-exempt:` soft prefix convention, and the validator-still-emits + audit-log-correlation pattern.
- [x] 13. **Cleanup verification artifacts** — tmp dirs from tasks 7/8 removed, `/tmp/stub-validator.sh` removed, `agents/acc9-agent` state file removed. State dir retains 3 legitimate sub-agent IDs from this session (002 rule writer, 005 validator extender, 005 rule writer); audit log retains 4 real dispatch records (none synthetic).

## Notes

The dogfood loop continues to pay off. Two findings surfaced during verification:

1. **Untracked-files gap in `git diff --name-only`** (real bug, fixed in task 1). The plan said "git diff picking up unstaged" — true but incomplete: it covers modifications to *tracked* files only. New files written by `Write` (the common case for sub-agents adding tests) are untracked and invisible to plain `git diff`. Task 8's first run produced a false-positive warning even though the test had been added. Fix: union `git diff --name-only` with `git ls-files --others --exclude-standard`, dedupe via `sort -u`. Plan.md updated under § *Risks and unknowns*. Without this, the warning would routinely false-fire on the natural sub-agent workflow (red: write the test → green: implement → tests stay untracked until commit).

2. **Validator stack-detection is cwd-anchored, not `CLAUDE_PROJECT_DIR`-anchored** (test-setup gotcha, NOT introduced by spec 005). The validator's `[ -f bun.lockb ]` checks resolve relative to the current working directory, ignoring `$CLAUDE_PROJECT_DIR`. In production this is fine — the harness invokes the hook with cwd already set to the project dir, so detection works. But when tested parent-side via `CLAUDE_PROJECT_DIR=/tmp/x bash .claude/validators/run.sh`, the env var has no effect and the validator falls through to `no-stack-detected`. Verified the correct invocation pattern: `(cd $TMP && bash <repo>/.claude/validators/run.sh)`. Not worth fixing now (the validator is small, the gap is parent-side-test-only), but worth knowing if a future maintainer hits the same head-scratcher. Could be closed by adding `cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0` near the top of `run.sh` if it ever matters.

The spec ships fully verified end-to-end: regression intact, behavior fires when expected, behavior suppressed when test added (incl. untracked), hook surfaces advisories with correct prefix and exit 0, rule documents all six required sections plus gotchas with all cross-refs resolved.
