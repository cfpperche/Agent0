# 111 — delegation-verify-subagent-stop — plan

_Drafted from `spec.md` on 2026-05-29. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build the new hook first, dogfood it green on both runtimes, then delete the old one in the same PR — never leave a window where the design is half-applied. `delegation-verify.sh` is a new `SubagentStop` hook (sibling to the existing `delegation-stop.sh`), runtime-neutral via `_memory-hook-lib.sh`, that resolves `.claude/validators/run.sh` and runs the full suite **once** at delegated-task close, keyed by the documented `agent_id`. On `ok=true` it surfaces the validator's advisory family (`lint-advisory:` / `typecheck-advisory:` / `tdd-advisory:`) and exits 0. On `ok=false` it blocks closure (exit 2 on Claude; `{"decision":"block"}` on Codex), surfaces the validator tail, and requests one focused continuation; a second consecutive failing stop for the same `agent_id` forces a partial-result instead of looping.

The verify-before-close-row ordering is the load-bearing wiring decision. `delegation-verify.sh` registers **before** `delegation-stop.sh` in the `SubagentStop` chain. Because the two are independent hook processes that cannot see each other's exit, coordination is via a per-stop sentinel: on a blocked closure, `delegation-verify.sh` writes a `verify-blocked` status row to `delegation-audit.jsonl` AND drops a sentinel under `.agent0/.delegation-state/`; `delegation-stop.sh` checks the sentinel and **skips the `subagent-stop` close row** when present (clearing it), so the audit never records a "stop" for a sub-agent that was sent back to continue. The `.claude/.delegation-state/agents/<agent_id>` counter (today a per-edit failure count that `delegation-stop.sh` already reads for its `exit` field) is reinterpreted as a **stop-keyed** verify-failure count — same file, new semantics, no schema change to the close row.

Once the new hook is green (incl. the mandatory live `SubagentStop` dogfood on both runtimes resolving the two OQs), delete `post-edit-validate.sh`, drop its `PostToolUse(Edit|Write|MultiEdit)` registration, retire the now-moot per-edit cascade tests, rewrite `delegation.md`, and sweep the stale path references.

## Files to touch

**Create:**
- `.agent0/hooks/delegation-verify.sh` — `SubagentStop` verifier (both runtimes). Sources `_memory-hook-lib.sh` (`memory_project_dir` / `memory_runtime`); resolves validator via the same chain `post-edit-validate.sh` used (`CLAUDE_DELEGATION_VALIDATOR` → `.claude/validators/run.sh` → fail-open); runs once; block/continue/escalate logic; advisory-family surfacing; `verify-blocked` row + sentinel on block. Fail-open on every error path.
- `.claude/tests/delegation-verify/*.sh` — scenarios: pass→close-row+accept; fail→block+verify-blocked+no-close-row; second-fail→partial-result; advisory-family surfaced on pass; fail-open on missing/broken validator; Codex-shape payload keyed by `agent_id`.

**Modify:**
- `.claude/settings.json` — add `delegation-verify.sh` to the `SubagentStop` array **before** `delegation-stop.sh`; **remove** the `PostToolUse` `matcher: "Edit|Write|MultiEdit"` entry that runs `post-edit-validate.sh`.
- `.agent0/hooks/delegation-stop.sh` — read the per-stop `verify-blocked` sentinel; skip the close row (and clear the sentinel) when present; reinterpret the `.delegation-state/agents/<agent_id>` counter as stop-keyed verify-failures for the `exit` field.
- `.codex/config.toml.example` — add a commented `[[hooks.SubagentStop]]` block for `delegation-verify.sh`, before the existing `delegation-stop.sh` block, noting block-via-`decision:"block"` + the opt-in/trust step.
- `.claude/rules/delegation.md` — rewrite § *Post-edit validator loop* → a stop-time *delegated-verification* section (new trigger, sentinel/close-row ordering, stop-keyed budget, both-runtime); update § *Audit log* with the `verify-blocked` row shape + the close-row-suppressed-on-block rule.
- `.claude/rules/tdd.md`, `.claude/rules/lint-validator.md`, `.claude/rules/typecheck-advisory.md` — repoint the advisory-surfacing hook from `post-edit-validate.sh` to `delegation-verify.sh`; note advisories now fire once at stop, not per-edit.
- `.claude/rules/{harness-sync,image-gen,runtime-capabilities}.md`, `CLAUDE.md`, `AGENTS.md`, `.agent0/memory/{cc-platform-hooks,codex-cli-hooks}.md`, `.agent0/hooks/session-track-edits.sh`, `.claude/hooks/secrets-advise.sh` — sweep stale `post-edit-validate` path references (most are comments / matrix cells / "sibling hook" mentions).
- `.claude/rules/runtime-capabilities.md` — matrix: the delegated-edit-validation capability moves from Claude-only per-edit to both-runtime stop-time.

**Delete:**
- `.claude/hooks/post-edit-validate.sh` — the per-edit hook, fully replaced.
- `.claude/tests/parallel-edit-validation/01-worktree-isolated-no-cross-fail.sh` + `02-shared-tree-cascade-reproduces.sh` — these guard the per-edit validator-cascade (spec 067), which is structurally impossible once validation is stop-time-only. Remove (or, if a cascade analogue exists at stop, repoint — but a single stop-time run has no sibling-half-write cascade).

## Alternatives considered

### Two-hook split (keep `post-edit-validate.sh` Claude-only + add the stop verifier)

Rejected — this was the *debate's* recommendation (spec 110 Round 2/3), overridden by the human-in-loop in favor of full removal. Keeping a per-edit guard preserves mid-flight thrash detection but reintroduces the per-edit suite cost on Claude and a two-contract maintenance surface. The conscious tradeoff (110): give up mid-flight detection for one honest hook.

### Fold verification into `delegation-stop.sh`

Rejected (spec 110 non-goal). `delegation-stop.sh` is audit-only and fail-open (exits 0 on any error); adding blocking validation corrupts that reliability contract and tangles audit vs. enforcement. Kept separate, coordinated via the sentinel.

### Per-edit `apply_patch` port on Codex

Rejected (spec 110 OQ1, verified): Codex `PostToolUse(apply_patch)` carries no parent-vs-subagent discriminator, so a per-edit port cannot attribute the actor. `SubagentStop` is the only payload that carries `agent_id`.

## Risks and unknowns

- **OQ1 — `agent_id` preservation across a continued stop.** The stop-keyed counter is keyed on `agent_id`; if a post-`verify-blocked` continuation runs under a fresh `agent_id`, the "second failing stop → partial-result" escalation never trips. **Must dogfood, both runtimes.**
- **OQ2 — `stop_hook_active` across a validation-blocked stop.** Guards against an infinite block loop and tells the hook "first close vs. continued-after-block." **Must dogfood.**
- **Hook-chain exit-2 ordering (the crux).** Unknown whether `delegation-verify.sh` exiting 2 in the `SubagentStop` array lets `delegation-stop.sh` still run (so the sentinel can suppress the close row), or whether exit-2 short-circuits the chain entirely (making the sentinel unnecessary — the close row simply never runs). The sentinel design must be validated against real chain semantics on both runtimes; the implementation may simplify if exit-2 short-circuits.
- **Advisory family is broader than the spec named.** `lint-advisory:` + `typecheck-advisory:` ride on `post-edit-validate.sh` alongside `tdd-advisory:`; all three relocate. Spec § Acceptance named only tdd — treat all three as in-scope (plan supersedes; consider a one-line spec amendment).
- **Worktree cwd at stop.** `post-edit-validate.sh` derived the validator cwd from the edited file's git toplevel; at `SubagentStop` there is no single edited file. Derive cwd from the sub-agent's `cwd` (worktree-isolated sub-agents close in their worktree); fail-open to `$PROJECT_DIR`.
- **Loss of the cascade regression guard.** Removing `parallel-edit-validation/*` drops the spec-067 guard, but the cascade it guards is per-edit-only and cannot occur at stop. Acceptable; note in the removal commit.
- **Accepted regression (per 110):** sub-agents get validator feedback only at close, not mid-flight.

## Research / citations

- `docs/specs/110-post-edit-validate-multi-runtime/debate.md` — the full Claude↔Codex rationale + human override to full removal (the decision this plan implements).
- <https://developers.openai.com/codex/hooks> — `SubagentStop` carries `agent_id`/`agent_type` and supports `decision:"block"`/exit-2 to continue the subagent flow (verified spec 110/106).
- `.agent0/memory/codex-cli-hooks.md` § *No per-edit actor attribution* — the portability finding driving the `SubagentStop` boundary.
- `.agent0/hooks/delegation-stop.sh` — the existing `SubagentStop` shared-multi-runner; the sibling pattern `delegation-verify.sh` follows (lib sourcing, runtime branch, fail-open, `.agent0/delegation-audit.jsonl`).
- `.claude/validators/run.sh` — validator JSON contract (`{ok,command,exit,duration_ms,stdout,stderr,warnings}`) consumed unchanged.
- `.claude/hooks/post-edit-validate.sh` — the source of the validator-resolution chain, advisory-family surfacing, and loop-budget logic being relocated/reshaped.
