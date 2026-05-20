# 067 — parallel-edit-validation — plan

_Drafted from `spec.md` on 2026-05-20. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

**The finding that reshapes this spec: the root-cause fix is already in the tree.** The validator-cascade is project-wide `tsc`/`biome` seeing siblings' in-flight files in a **shared** working tree. The structural fix is to not share the tree — worktree isolation. Spec 063 shipped *both* halves of that: the `isolation: "worktree"` dispatch mechanism (CC 2.1.144-native — parent sets it in the `Agent` call, sub-agent calls `EnterWorktree`), and the validator-side scoping in `.claude/hooks/post-edit-validate.sh` lines 30-42 — the validator's cwd is derived from the git toplevel of the edited file, so a worktree-isolated sub-agent's edit is validated against *its own worktree*, never a sibling's tree. A parallel fan-out where each sub-agent runs `isolation: "worktree"` therefore cannot cascade: distinct trees, distinct `tsc`/`biome` runs, zero sibling interference. **067 introduces NO new validator mechanism** — building one (wave-boundary check, per-actor snapshot-diff) would duplicate 063's already-merged solution.

So 067's genuine residual scope is **discipline + proof + wiring**, in this order: (1) `.claude/rules/delegation.md` § Post-edit validator loop gains an explicit mandate — a parent dispatching ≥2 parallel `Agent` calls that may touch overlapping files MUST declare `isolation: "worktree"` — with the cascade named as the rationale and a cross-reference to § Worktree isolation; (2) a regression test under `.claude/tests/parallel-edit-validation/` that proves the positive case (two worktree-isolated concurrent edits do not cross-fail) and a negative control (two shared-tree concurrent edits *do* cascade), so the property is locked against future hook regressions; (3) the 057 ↔ 063 ↔ 067 relationship stated in `057`'s and `067`'s specs — 057 stays the fallback for *genuine* loop-budget exhaustion, 063 is the mechanism, 067 is the mandate+test. 067 depends on 063 reaching `shipped`; the validator-cwd-scoping half is already merged, so the docs can land regardless.

**Open-question resolutions** (from `spec.md`): **OQ1 (mechanism)** — worktree isolation; and it is spec 063's, already shipped on the validator side. 067 builds no new mechanism; the candidate "wave-boundary" / "snapshot-diff" shapes are rejected (see Alternatives). **OQ2 (vs 057)** — 057 is NOT superseded. 067/063 remove the *sibling-interference* trigger; 057's parent-write degradation remains the correct fallback for *real* `CLAUDE_DELEGATION_LOOP_BUDGET` exhaustion (a sub-agent genuinely unable to converge). The two layer. **OQ3 (vs 063)** — 067 builds ON 063, it does not introduce a parallel mechanism. 063 = the worktree mechanism; 067 = the validator-cascade discipline (when isolation is *mandatory*) + the regression test. Kept as a separate thin spec rather than folded into 063 — see Alternatives.

## Files to touch

**Modify:**
- `.claude/rules/delegation.md` — § Post-edit validator loop: add a paragraph stating that a parallel `Agent` fan-out into a shared tree triggers the validator-cascade (project-wide `tsc`/`biome` sees siblings' in-flight files), and that the parent MUST declare `isolation: "worktree"` for any parallel fan-out that may touch overlapping files. Cross-reference § Worktree isolation (which already documents the mechanism + the validator cwd-scoping). One or two sentences in § Worktree isolation's "When parents SHOULD declare isolation" list may be sharpened to name the cascade explicitly.
- `docs/specs/057-product-fan-out-fallback/spec.md` — add a one-paragraph relationship statement: 057's serial / parent-write degradation is the fallback for genuine loop-budget exhaustion; the *sibling-interference* root cause it was working around is fixed by worktree isolation (063) + the 067 mandate. 057 is not superseded.
- `docs/specs/067-parallel-edit-validation/spec.md` — mark the three open questions resolved (pointing here), and tighten the § Context relationship line to 057/063 per the resolutions above.

**Create:**
- `.claude/tests/parallel-edit-validation/` — regression test directory following the existing `.claude/tests/<name>/` convention (cf. `session-edit-attribution`, `lint-validator`). Asserts: (positive) two concurrent edits in *separate worktrees* each validate against only their own tree → neither flips `ok=false` on the other's churn; (negative control) two concurrent edits in *one shared tree* reproduce the cascade. The test most likely simulates the hook-invocation sequence (synthetic `post-edit-validate.sh` payloads with worktree vs shared `file_path`s) rather than spawning real parallel agents — exact shape resolved in `/sdd tasks`.

**Delete:** none.

**Explicitly NOT touched:** `.claude/hooks/post-edit-validate.sh` (the cwd-scoping is already correct, shipped by 063); `.claude/validators/run.sh` (no mechanism change); no new hook.

## Alternatives considered

### Wave-boundary mechanism — parent runs project-wide `tsc` between waves; sub-agents inside a wave get a lighter (syntax/lint-only) check

Rejected. This is spec 057's serial-degradation re-dressed. If sub-agents inside a wave can't run the real typecheck, cross-induced errors are only caught at the wave boundary — after the loop budget has already been burned, or worse, silently shipped. It does not restore *real* parallel validation; "a paralelização vira teatro" (the mei-saas agent, 2026-05-20) still applies. Worktree isolation gives each sub-agent a real, sound typecheck concurrently.

### A new per-actor snapshot-diff validator — validator diffs the tree and typechecks only the actor's delta

Rejected. `tsc --noEmit` resolves types across the whole project import graph; a delta-only check is not sound (a sub-agent's edit can break a file it didn't touch). And it is redundant with worktree isolation, which delivers a *sound, full* typecheck per actor — cleaner, CC-native, and already shipped (063). Building a fragile diff-validator to approximate what worktree isolation does exactly is negative work.

### A `PreToolUse(Agent)` hook that blocks a parallel fan-out dispatched without `isolation: "worktree"`

Rejected for v1. The delegation-gate fires once per `Agent` call and cannot tell, from a single call, whether it is one of several dispatched in the same message — it has no "parallel" signal to gate on. And per `.claude/memory/feedback_speculative_observability.md`'s rule-of-three demand-test, a hook is built *after* drift is observed ≥3×, not before. Spec 066 just deleted `/product`'s screen-writer fan-out — the only shipping parallel-fan-out consumer — so there is currently **zero** consumer exercising this path. Rule + regression test now; a hook only if a real parallel-fan-out consumer ships and the cascade recurs in dogfood.

### Fold 067 entirely into spec 063

Considered, not chosen as default. 063 is the worktree *mechanism*; 067 is the validator-cascade *discipline* (when isolation is mandatory) — adjacent but distinct, and 057 already exists as its own sibling spec, so a discipline spec reads cleanly standalone. 063 is also `in-progress` — bolting scope onto an in-flight spec is messier than a thin clean sibling. **But:** if 063's tasks have not been worked yet, merging 067's three deliverables into 063's task list is reasonable — flagged for the founder's call at `/sdd tasks` time.

## Risks and unknowns

- **067 depends on 063 reaching `shipped`.** 063 is `in-progress`. The validator-cwd-scoping half is already merged in `post-edit-validate.sh`, and CLAUDE.md § Worktree isolation already documents the behavior — so 067's docs + test can land independently of 063's remaining tasks. But 067's mandate references `isolation: "worktree"` as a parent-declared parameter; if 063 stalls, that reference is to a partially-shipped mechanism. Low risk (the mechanism is CC-native, not Agent0-built).
- **Reproducing the cascade in the negative-control test is non-trivial.** Spawning two genuinely-concurrent real sub-agents in a test harness is hard; the test will likely synthesize the `post-edit-validate.sh` invocation sequence (crafted payloads with shared vs worktree `file_path`s) and assert the validator cwd resolution. Exact shape is a `/sdd tasks` decision.
- **Speculative-scope risk.** With `/product`'s fan-out deleted (066), no shipping skill currently fans out parallel into a shared tree. The rule + test are cheap and document a real harness property, so they are not speculative — but they should be the *whole* of v1. The hook is correctly deferred (see Alternatives); do not let 067 grow a mechanism.
- **`biome` vs `tsc`.** Spec 057 names the repo-wide `biome check` (lint) as the cascading check; 067's spec names `tsc` (typecheck). Both are project-wide and cascade identically; worktree isolation fixes both. The delegation.md paragraph should say "the project-wide validator step (`tsc` and `biome` alike)" so the fix is not misread as typecheck-only.

## Research / citations

- `.claude/hooks/post-edit-validate.sh` lines 23-53 — the spec-063 worktree-aware validator cwd-scoping, **already merged**: `VALIDATOR_CWD` is derived from `git -C "$edit_dir" rev-parse --show-toplevel`, fail-open to `$PROJECT_DIR`. This is the load-bearing evidence that 067's "make the validator scope match the actor" is already done.
- `docs/specs/063-worktree-isolated-subagents/spec.md` — the worktree isolation mechanism (`isolation: "worktree"`, native `EnterWorktree`/`ExitWorktree`); status `in-progress`.
- `docs/specs/057-product-fan-out-fallback/spec.md` (shipped) — the loop-budget-exhaustion fallback; names the repo-wide `biome check` cascade as the trigger it works around.
- `CLAUDE.md` § Worktree isolation — documents the shipped 063 behavior: validator cwd derivation, and "When parents SHOULD declare `isolation: "worktree"`" (≥2 parallel dispatches that may touch overlapping files is already listed).
- `.claude/rules/delegation.md` § Post-edit validator loop + § Worktree isolation — the rule surfaces 067 edits.
- `.claude/memory/feedback_speculative_observability.md` — the rule-of-three demand-test gating the deferred `PreToolUse(Agent)` hook.
- TypeScript behavior: `tsc --noEmit` type-resolves across the project import graph; a single-file or delta-only check is unsound — which is why "scope the check to the actor" is *worktree isolation* (a full sound check on an isolated tree), not a narrowed `tsc`.
