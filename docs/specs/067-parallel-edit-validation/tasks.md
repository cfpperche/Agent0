# 067 — parallel-edit-validation — tasks

_Generated from `plan.md` on 2026-05-20. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

_067 introduces NO new validator mechanism — the root-cause fix (worktree isolation + validator cwd-scoping) already shipped via spec 063. These tasks are the discipline (mandate) + the proof (regression test) + the cross-spec wiring. See `plan.md § Approach`._

## Implementation

- [x] 1. **delegation.md § Post-edit validator loop — document the cascade + mandate.** Add a paragraph: a parallel `Agent` fan-out into a *shared* working tree triggers the validator-cascade — the project-wide validator step (`tsc` and `biome` alike) sees siblings' in-flight files and flips `ok=false` on errors the sub-agent did not cause. A parent dispatching ≥2 parallel `Agent` calls that may touch overlapping files MUST declare `isolation: "worktree"`. Cross-reference § Worktree isolation (the mechanism + the already-shipped validator cwd-scoping). (AC3)
- [x] 2. **delegation.md § Worktree isolation — sharpen the parallel-dispatch bullet.** In the "When parents SHOULD declare `isolation: "worktree"`" list, the existing "≥2 parallel `Agent` dispatches" bullet gains an explicit clause naming the validator-cascade as the concrete failure mode it prevents (not just "last-writer wins"). One sentence. (AC3 support)
- [x] 3. **Create `.claude/tests/parallel-edit-validation/`.** Regression test following the existing `.claude/tests/<name>/` convention (cf. `lint-validator`, `typecheck-advisory`). Stand up a minimal TS fixture project; create two git worktrees of it. **Positive case:** write a file with a type error into worktree A, then invoke `.claude/hooks/post-edit-validate.sh` with a synthetic payload whose `tool_input.file_path` is a clean file in worktree B → assert the validator's `ok` reflects only worktree B (A's error does not leak). **Negative control:** the same two edits in ONE shared tree → assert the cascade reproduces (B's validation flips `ok=false` on A's error). Runner is executable and self-contained. (AC4)
- [x] 4. **057 spec — relationship statement.** In `docs/specs/057-product-fan-out-fallback/spec.md`, add a paragraph: 057's serial / parent-write degradation is the fallback for *genuine* `CLAUDE_DELEGATION_LOOP_BUDGET` exhaustion; the *sibling-interference* root cause it was working around is fixed by worktree isolation (063) + the 067 mandate. 057 is NOT superseded — the two layer. (AC5)
- [x] 5. **067 spec — resolve open questions + tighten Context.** In `docs/specs/067-parallel-edit-validation/spec.md`, mark the 3 open questions resolved (point to `plan.md § Approach` — OQ1 worktree/063, OQ2 057-as-fallback, OQ3 builds-on-063); tighten the § Context 057/063 relationship line to match the resolutions. (AC5)

## Verification

_Acceptance checks tied to `spec.md` § Acceptance criteria._

- [x] 6. **AC3 — docs.** `grep` `.claude/rules/delegation.md` § Post-edit validator loop: the validator-cascade is named, the `isolation: "worktree"` mandate for parallel fan-outs is present, and § Worktree isolation is cross-referenced.
- [x] 7. **AC4 — test runs.** Execute `.claude/tests/parallel-edit-validation/`: the positive case passes (worktree-isolated concurrent edits do not cross-fail) AND the negative control reproduces the cascade (shared-tree concurrent edits do). The test dir + runner exist and are executable.
- [x] 8. **AC1 / AC2 / AC5 — trace.** AC1 (worktree-isolated parallel sub-agents do not fail each other's validation) is proven by task 7's positive case. AC2 (serial degradation is no longer the only safe parallel mode) follows — parallel + isolation is safe. AC5 — confirm the relationship statement is present in BOTH `057` and `067` specs.

## Notes

- **No `post-edit-validate.sh` / `run.sh` edits.** The validator cwd-scoping is already correct (shipped by spec 063, `post-edit-validate.sh:30-42`). A task touching the hook would be a plan deviation — stop and update `plan.md` first.
- **No new hook.** A `PreToolUse(Agent)` guard against parallel-without-isolation was considered and rejected (`plan.md § Alternatives` — the gate can't see parallelism from one call; deferred per the rule-of-three demand-test). If a task starts scaffolding a hook, the plan has drifted.
- **067 depends on spec 063 reaching `shipped`** for the `isolation: "worktree"` mechanism; the docs + test here can land independently (the validator-side scoping is already merged). If 063 stalls, note it but do not block.
- **Fold-into-063 option:** if 063's tasks have not been worked yet, tasks 1-5 here could merge into 063's task list instead — founder's call before starting task 1 (`plan.md § Alternatives`).
