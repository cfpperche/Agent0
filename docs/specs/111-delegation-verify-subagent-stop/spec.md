# 111 — delegation-verify-subagent-stop

_Created 2026-05-29._

**Status:** shipped — fully dogfooded on BOTH runtimes. Claude pass path LIVE (real `SubagentStop`, parallel execution confirmed); Codex block + exhausted paths LIVE (Codex TUI 0.135.0, real audit rows). Both runtime OQs resolved by live evidence (`agent_id` preserved across the continuation; `stop_hook_active` flips true → `exhausted`, no infinite loop). 8-scenario suite + `061-delegation-stop` green; `post-edit-validate.sh` deleted; cascade removed; docs swept.

## Intent

Implement the decision reached in spec 110 (`post-edit-validate-multi-runtime`, resolved via Claude↔Codex debate + human override): **delete the per-edit `post-edit-validate.sh` hook entirely and replace it with a single runtime-neutral `delegation-verify.sh` that runs the project validator once at `SubagentStop`** on both Claude Code and Codex CLI.

Why: `post-edit-validate.sh` runs the full project test suite + typecheck on *every* delegated sub-agent edit (expensive, validator-cascade-prone) and is Claude-only (its `agent_id`-presence entry gate has no Codex `PostToolUse(apply_patch)` equivalent — verified against the Codex hooks docs in spec 110). Moving verification to `SubagentStop` makes it (a) cheap — the suite runs once at delegated-task close, not per-edit; (b) runtime-neutral — `SubagentStop` carries documented `agent_id`/`agent_type` on both runtimes; (c) honest about its trigger. The conscious tradeoff (accepted in 110): mid-flight thrash detection is given up.

## Acceptance criteria

- [x] **Scenario: delegated sub-agent closes with a passing tree (Claude)** _(LIVE-dogfooded 2026-05-29: real `Agent` dispatch `acb46fdc0a91cab59` → `SubagentStop` fired `delegation-verify.sh` → `decision:pass`/`validator_exit:0` row, in parallel with the `subagent-stop` close row; evidence in `notes.md`)_
  - **Given** a stack-detected project and a delegated Claude sub-agent that has finished its task with the validator passing
  - **When** the sub-agent reaches `SubagentStop`
  - **Then** `delegation-verify.sh` runs the validator once, it returns `ok=true`, the failure counter is reset, the advisory family is surfaced, and closure is accepted (exit 0); `delegation-stop.sh` appends its `subagent-stop` close row in parallel

- [x] **Scenario: delegated sub-agent closes with a failing tree (Claude)** _(logic validated via test `02-fail-blocks.sh`; live cold-restart fire pending)_
  - **Given** the same setup but the validator fails (`ok=false`) on the first stop (`stop_hook_active=false`)
  - **When** the sub-agent reaches `SubagentStop`
  - **Then** the hook blocks closure (exit 2) with the validator tail surfaced, requests one focused continuation, and appends a `subagent-verify` row with `decision=blocked`. _(Design pivot: the hooks run in parallel, so `delegation-stop.sh` still writes its close row — suppression is not achievable without a race; the close row's `exit` field reflects the verify-failure counter instead. See `notes.md`.)_

- [x] **Scenario: second consecutive failing stop escalates** _(synthetic test `03-exhausted-partial.sh` + **LIVE-confirmed on Codex** 2026-05-29: `decision:exhausted`, `stop_hook_active:true`, no infinite loop)_
  - **Given** a sub-agent that was continued once after a block and still fails the validator (`stop_hook_active=true`)
  - **When** it reaches `SubagentStop` again
  - **Then** the hook accepts the closure as a partial result (exit 0, `decision=exhausted`) rather than blocking again — `stop_hook_active` is the loop guard

- [x] **Scenario: Codex delegated sub-agent close (live dogfood)** _(LIVE-dogfooded 2026-05-29, Codex TUI 0.135.0)_
  - **Given** the Codex `.codex/config.toml` `SubagentStop` block enabled + cold restart/trust
  - **When** a Codex sub-agent closes after a delegated task with a failing validator
  - **Then** `delegation-verify.sh` fired via the real `SubagentStop`, keyed by `agent_id`, → `decision:blocked` (`validator_exit:1`, `stop_hook_active:false`) at 14:23:42, then `decision:exhausted` (`stop_hook_active:true`, same `agent_id`) at 14:23:55 — both `runtime:"codex-cli"`, recorded in `notes.md`. Proven by real audit rows, not fixtures (108/109 lesson)

- [x] `.claude/hooks/post-edit-validate.sh` is deleted and its `PostToolUse(Edit|Write|MultiEdit)` registration removed from `.claude/settings.json`
- [x] No LIVE `post-edit-validate` references remain (deleted hook + registration); only intentional "replaced by / removed in 111" breadcrumbs persist in rules/memory/config — same convention as 109's "moved from" breadcrumbs
- [x] The `tdd-advisory:` coverage signal still reaches the agent — relocated to `delegation-verify.sh`, surfaced once at stop (test `01-pass.sh` asserts it; `lint-`/`typecheck-advisory:` family relocated too)
- [x] `.claude/rules/delegation.md` § *Post-edit validator loop* rewritten as a stop-time delegated-verification section; advisory-channel refs in `tdd.md` / `lint-validator.md` / `typecheck-advisory.md` repointed
- [x] All 8 new `delegation-verify` tests pass + the existing `061-delegation-stop` suite stays green

## Non-goals

- **Per-edit validation in any form.** No fast per-edit check, no advisory per-edit, no two-hook split — explicitly rejected in spec 110. One hook, stop-time only.
- **A validator `--mode` contract** (`edit-fast` vs `done-full`). Dropped in 110 — there is no per-edit check left to make fast; the verifier runs the existing full-suite command.
- **Redesigning `.claude/validators/run.sh`'s command set.** `delegation-verify.sh` invokes it as-is.
- **Folding verification into `delegation-stop.sh`.** That hook is audit-only/fail-open; verification is a separate hook to keep the audit reliability contract clean.
- **Changing the parent-edit exemption.** Naturally preserved — `SubagentStop` only fires for delegated sub-agents; parents never trigger it.

## Open questions

_Two facts MUST be resolved by live dogfood before the budget/continuation design is locked — carried forward from spec 110 OQ2._

- [x] **OQ1: does a continued sub-agent preserve its `agent_id`? RESOLVED — yes** (Codex live dogfood 2026-05-29): the `blocked` and `exhausted` rows carry the same `agent_id:"019e741e-4344-7b93-b782-a1f10484e1da"`. The counter keeps its key across the continuation. (Note: the design keys escalation on `stop_hook_active`, not the counter, so it is robust even if a runtime ever does NOT preserve `agent_id`.)
- [x] **OQ2: how does `stop_hook_active` behave across a validation-blocked stop? RESOLVED — flips false→true** (Codex live dogfood): first failing close `stop_hook_active:false`/`decision:blocked`; continued failing close `stop_hook_active:true`/`decision:exhausted`; Codex returned to the parent prompt — no infinite stop loop. The escalation guard works as designed.
- [x] **OQ3: audit ordering edge — RESOLVED by the parallel-execution pivot** (see `notes.md`). There is no `verify-blocked`-instead-of-`subagent-stop` suppression: the hooks run in parallel, so `delegation-stop.sh` still writes its `subagent-stop` close row and `delegation-verify.sh` writes a separate `subagent-verify` row. The dispatch↔stop correlation in `delegation.md` § Audit log is unchanged; the verify row is additive.

## Context / references

- `docs/specs/110-post-edit-validate-multi-runtime/` — the decision spec: `spec.md` § Follow-up path is this spec's brief; `debate.md` is the full Claude↔Codex rationale (resolved `converged` + human override to full removal)
- `.claude/hooks/post-edit-validate.sh` — the hook being **deleted** (current source of the per-edit validator loop + `tdd-advisory:` surfacing + loop-budget)
- `.agent0/hooks/delegation-stop.sh` — the audit-only `SubagentStop` close hook; `delegation-verify.sh` runs adjacent to it (verify-before-close-row ordering), NOT inside it
- `.agent0/hooks/_memory-hook-lib.sh` — `memory_project_dir` / `memory_runtime` / `memory_actor` for runtime-neutral resolution
- `.claude/validators/run.sh` — the validator invoked at stop (full suite + typecheck per stack)
- `.claude/rules/delegation.md` § *Post-edit validator loop* / § *Why DONE_WHEN exists* / § *Audit log* — sections to rewrite
- `docs/specs/106..109` — the `.agent0/` multi-runtime hook migration pattern + the 108/109 dormant-registration lesson (live dogfood on both runtimes is mandatory before shipping)
- <https://developers.openai.com/codex/hooks> — `SubagentStop` carries `agent_id`/`agent_type` + supports `decision:"block"`/exit-2 to continue the subagent flow
