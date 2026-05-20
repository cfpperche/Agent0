# 067 — parallel-edit-validation

_Created 2026-05-20._

**Status:** shipped

## Intent

The post-edit validator hook (`.claude/hooks/post-edit-validate.sh`) runs the project validator after every edit a delegated sub-agent makes; the validator (`.claude/validators/run.sh`) typechecks the **whole project** (`tsc --noEmit` on JS/TS stacks). When a parent dispatches a parallel fan-out — multiple sub-agents editing one shared working tree at once — each sub-agent's project-wide typecheck sees the half-written files of its siblings and fails on errors it did not cause. This is the **validator-cascade**: sub-agents burn their loop budget on sibling-induced failures, write stubs over each other to silence `tsc`, and leave broken JSX (observed across Waves 3-5 of the mei-saas `/product` dogfood). Spec 057 mitigates it by degrading the fan-out to serial cap=1 + parent-write — which removes the cascade but also removes the parallelism the fan-out exists for; in the mei-saas agent's words, "a paralelização vira teatro" (2026-05-20). This spec fixes the **root cause**: make the post-edit validator's typecheck scope match the actor, so a sub-agent's edit is validated against a stable boundary rather than every sibling's in-flight churn — restoring safe parallel fan-out. It applies to any parallel `Agent` fan-out; `/product`'s own fan-out is being deleted by spec 066, but the harness flaw is independent and outlives that.

_Resolution (2026-05-20, `/sdd plan`): the root-cause fix — making the validator's scope match the actor — **already shipped via spec 063** (`isolation: "worktree"` dispatch + `post-edit-validate.sh` cwd-scoping to the edited file's git toplevel, lines 30-42). 067 introduces **no new validator mechanism**; its residual scope is the **discipline** (mandate that parallel fan-outs declare isolation), the **proof** (a regression test locking the property), and the **cross-spec wiring** (057 ↔ 063 ↔ 067). See `plan.md` § Approach and the resolved open questions below._

## Acceptance criteria

- [x] **Scenario: parallel sub-agents do not fail each other's validation**
  - **Given** a parent dispatches ≥2 sub-agents editing the same working tree concurrently
  - **When** each sub-agent's post-edit validator runs
  - **Then** a sub-agent's validation outcome reflects only its own edits plus stable/committed state — a sibling's half-written file does not flip it to `ok=false`

- [x] **Scenario: serial degradation stops being the only safe mode**
  - **Given** the validator-cascade root cause is fixed
  - **When** a parent runs a parallel fan-out (cap > 1)
  - **Then** the fan-out stays parallel without the cascade; spec 057's serial / parent-write degradation becomes a fallback for genuine loop-budget exhaustion, not a workaround for sibling interference

- [x] The scoping behavior is documented in `.claude/rules/delegation.md` § Post-edit validator loop.
- [x] A regression test under `.claude/tests/` exercises the parallel-edit case (two concurrent edits to one tree → no cross-induced failure).
- [x] The relationship to spec 057 is stated explicitly (superseded / layered / fallback) in both `057` and this spec.

## Non-goals

- **The `/product` screen-writer fan-out** — spec 066 deletes it; this spec fixes the harness validator independent of `/product`.
- **The validator's lint and test steps** — scoped to the typecheck step's project-wide scope only.
- **Replacing the post-edit validator or the delegation loop-budget mechanism** — only the typecheck scope changes.

## Open questions

- [x] **Scoping mechanism — touched-files vs wave-boundary vs worktree.** `tsc` cannot soundly typecheck a single file in isolation (TypeScript needs the import graph), so "scope to the sub-agent's touched files" is not literally a per-file `tsc`. Candidate shapes: (a) **wave-boundary** — the parent runs project-wide `tsc` between waves; sub-agents inside a wave get a lighter check (syntax/lint only); (b) **worktree isolation** — each sub-agent edits an isolated worktree (ties into spec 063's `isolation: "worktree"`), so siblings never share a tree; (c) a snapshot-diff approach. **Resolved (`plan.md` § Approach):** (b) worktree isolation — and it is **spec 063's** mechanism, already shipped on the validator side. 067 builds no new mechanism; (a) and (c) are rejected — see `plan.md` § Alternatives ((a) is 057's serial degradation re-dressed, (c) is unsound for `tsc`'s whole-graph type resolution).
- [x] **Relationship to spec 057.** Supersede 057's serial degradation, or keep 057 as the loop-budget-exhaustion fallback? Lean: keep 057 as fallback; this spec removes the *sibling-interference* trigger, not the budget cap. **Resolved (`plan.md` § Approach):** 057 is **NOT superseded**. 063+067 remove the *sibling-interference* trigger; 057's parent-write degradation remains the correct fallback for *genuine* `CLAUDE_DELEGATION_LOOP_BUDGET` exhaustion (a sub-agent that cannot converge on its own merits). The two layer.
- [x] **Relationship to spec 063 (worktree isolation).** If sub-agents already run under `isolation: "worktree"`, the cascade is structurally avoided (no shared tree). Does this spec build on 063 rather than introduce a new mechanism? **Resolved (`plan.md` § Approach):** 067 builds **ON** 063 — it introduces no parallel mechanism. 063 = the worktree mechanism + the validator cwd-scoping (already merged); 067 = the discipline (when isolation is *mandatory*) + the regression test. Kept as a thin standalone spec rather than folded into 063 — see `plan.md` § Alternatives.

## Context / references

- mei-saas `/product` dogfood — follow-up report from the mei-saas agent (2026-05-20), point 4: "validator project-wide briga com o fan-out paralelo". Transcript `43610f10` under `~/.claude/projects/-home-goat-mei-saas/` (Waves 3-5 cascade).
- `.claude/hooks/post-edit-validate.sh` — the hook that runs the validator after delegated edits.
- `.claude/validators/run.sh` — the validator; runs project-wide `tsc --noEmit` on JS/TS stacks.
- `.claude/rules/delegation.md` § Post-edit validator loop — the loop-budget mechanism and actor detection.
- `docs/specs/057-product-fan-out-fallback/` (shipped) — the loop-budget-exhaustion fallback; 067 **layers on** it (057 stays the fallback for genuine exhaustion, 067 adds the parallel-fan-out mandate). See § Open questions OQ2 and 057's § Relationship to specs 063 / 067.
- `docs/specs/063-worktree-isolated-subagents/` — worktree isolation; **the** mechanism 067 builds on (not a candidate). The validator cwd-scoping half is already merged in `post-edit-validate.sh` (lines 30-42). See § Open questions OQ1/OQ3.
- `docs/specs/066-product-ui-quality/` — deletes `/product`'s screen-writer fan-out (one victim of the cascade); 067's mandate + regression test cover the harness property regardless of whether any skill currently fans out.
