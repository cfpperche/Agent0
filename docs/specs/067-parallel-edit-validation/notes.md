# 067 — parallel-edit-validation — notes

_Created 2026-05-20._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-20 — parent — regression test uses real `git worktree`, not two `git init` repos

`plan.md § Files to touch` said the test "asserts ... two concurrent edits in *separate worktrees* each validate against only their own tree" but left the fixture shape to `/sdd tasks`. Two separate `git init` repos would also give distinct `git rev-parse --show-toplevel` results and would have been simpler — but `isolation: "worktree"` (spec 063) is *specifically* a linked git worktree, and `post-edit-validate.sh:41` keys on `git -C "$edit_dir" rev-parse --show-toplevel`. A linked worktree shares `.git` with its parent yet returns its own path from `--show-toplevel`; two unrelated repos do not exercise that exact behavior. Decision: the test does real `git worktree add --detach`, so it validates the precise mechanism 063 ships and 067 mandates — not an approximation of it.

### 2026-05-20 — parent — `bun`/`tsc` shimmed; the "type error" is a sentinel string

`tasks.md` task 3 said "minimal TS fixture project ... write a file with a type error". Running real `tsc` would require installing `typescript` into `node_modules` — a network dependency and a non-hermetic test. Every existing `.claude/tests/` scenario for the validator (`lint-validator`, `typecheck-advisory`) shims the runner instead. Decision: shim `bun` so `bun test` passes and `bun tsc --noEmit` models a *project-wide* typecheck by `grep -r`-scanning the cwd subtree for a sentinel (`TYPE_ERROR_SENTINEL_067`) that the broken fixture file carries. This is faithful to the property under test — `tsc` is whole-tree, so a type error anywhere in the cwd fails the check — without the install. The sentinel abstraction is honest: 067 is about the *hook's cwd-scoping*, not about TypeScript's type system.

### 2026-05-20 — parent — scenario 01 carries its own non-vacuous guard

A positive-only test ("worktree B validated clean → exit 0") could pass for the wrong reason — a dead/fail-open validator also yields exit 0. Two guards were added so a green result is trustworthy: (a) scenario 01 assert 2 runs the *same hook* scoped to worktree A and requires exit 2 — proving the error is real and the validator is live; (b) scenario 02 is the negative control — the same two edits in one *shared* tree must cascade (exit 2). Scenario 01 cannot be vacuously green unless scenario 02 also (wrongly) passes, and vice versa.

### 2026-05-20 — parent — spec closed `draft → in-progress → shipped` in one session

`plan.md` had already de-risked 067 to a thin docs+test spec (the root-cause fix shipped via 063). Implementation was 5 small doc edits + a 3-file test dir; nothing surfaced that warranted pausing at `in-progress`. The spec moved straight to `shipped` once the test passed and the AC3/AC5 greps confirmed.

## Deviations

_None. `plan.md § Files to touch` matched implementation exactly: 3 files modified (`delegation.md`, `057/spec.md`, `067/spec.md`), 1 dir created (`.claude/tests/parallel-edit-validation/`), nothing in the explicit "NOT touched" list (`post-edit-validate.sh`, `run.sh`) was touched._

## Tradeoffs

### 2026-05-20 — parent — test depth: hook cwd-scoping, not real TypeScript resolution

The shimmed-`tsc` decision (see §1) trades away coverage of real TypeScript cross-file type resolution. Accepted because that coverage would test `tsc`, not the hook — and 067's whole subject is the hook running the validator in the *right tree*. The negative control (scenario 02) anchors the claim that the project-wide check genuinely cascades across a shared tree; the positive case proves isolation prevents it. Adding real `tsc` would add a `typescript` install + network dependency for zero additional signal about the property 067 owns.

## Open questions

_None outstanding. The three `spec.md` open questions were resolved at `/sdd plan` time (OQ1 → worktree isolation is 063's, already shipped; OQ2 → 057 not superseded, layered; OQ3 → 067 builds on 063) and are marked resolved in `spec.md`. The deferred `PreToolUse(Agent)` parallel-guard hook is correctly out of scope per the rule-of-three demand-test — re-evaluate only if a real parallel-fan-out consumer ships and the cascade recurs in dogfood._
