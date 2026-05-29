# 111 — delegation-verify-subagent-stop

_Created 2026-05-29._

**Status:** in-progress — hook built + 8-scenario suite green + cascade removed + docs swept (in-session validated); live `SubagentStop` dogfood on both runtimes is the only remaining step (cold-restart-gated, 108/109 lesson)

## Intent

Implement the decision reached in spec 110 (`post-edit-validate-multi-runtime`, resolved via Claude↔Codex debate + human override): **delete the per-edit `post-edit-validate.sh` hook entirely and replace it with a single runtime-neutral `delegation-verify.sh` that runs the project validator once at `SubagentStop`** on both Claude Code and Codex CLI.

Why: `post-edit-validate.sh` runs the full project test suite + typecheck on *every* delegated sub-agent edit (expensive, validator-cascade-prone) and is Claude-only (its `agent_id`-presence entry gate has no Codex `PostToolUse(apply_patch)` equivalent — verified against the Codex hooks docs in spec 110). Moving verification to `SubagentStop` makes it (a) cheap — the suite runs once at delegated-task close, not per-edit; (b) runtime-neutral — `SubagentStop` carries documented `agent_id`/`agent_type` on both runtimes; (c) honest about its trigger. The conscious tradeoff (accepted in 110): mid-flight thrash detection is given up.

## Acceptance criteria

- [x] **Scenario: delegated sub-agent closes with a passing tree (Claude)** _(logic validated via test `01-pass.sh`; live cold-restart fire pending)_
  - **Given** a stack-detected project and a delegated Claude sub-agent that has finished its task with the validator passing
  - **When** the sub-agent reaches `SubagentStop`
  - **Then** `delegation-verify.sh` runs the validator once, it returns `ok=true`, the failure counter is reset, the advisory family is surfaced, and closure is accepted (exit 0); `delegation-stop.sh` appends its `subagent-stop` close row in parallel

- [x] **Scenario: delegated sub-agent closes with a failing tree (Claude)** _(logic validated via test `02-fail-blocks.sh`; live cold-restart fire pending)_
  - **Given** the same setup but the validator fails (`ok=false`) on the first stop (`stop_hook_active=false`)
  - **When** the sub-agent reaches `SubagentStop`
  - **Then** the hook blocks closure (exit 2) with the validator tail surfaced, requests one focused continuation, and appends a `subagent-verify` row with `decision=blocked`. _(Design pivot: the hooks run in parallel, so `delegation-stop.sh` still writes its close row — suppression is not achievable without a race; the close row's `exit` field reflects the verify-failure counter instead. See `notes.md`.)_

- [x] **Scenario: second consecutive failing stop escalates** _(logic validated via test `03-exhausted-partial.sh`; live cold-restart fire pending)_
  - **Given** a sub-agent that was continued once after a block and still fails the validator (`stop_hook_active=true`)
  - **When** it reaches `SubagentStop` again
  - **Then** the hook accepts the closure as a partial result (exit 0, `decision=exhausted`) rather than blocking again — `stop_hook_active` is the loop guard

- [ ] **Scenario: Codex delegated sub-agent close (live dogfood)** _(pending — Codex prompt in handoff)_
  - **Given** the Codex `.codex/config.toml` `SubagentStop` block enabled + cold restart/trust
  - **When** a Codex sub-agent closes after a delegated task
  - **Then** `delegation-verify.sh` fires via the real `SubagentStop`, runs the validator keyed by `agent_id`, and blocks via `decision:"block"` on failure — proven by a recorded run, not fixtures (108/109 lesson)

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

- [ ] **OQ1: does a continued sub-agent preserve its `agent_id`?** The Agent0-owned continuation counter is keyed by `agent_id`. If a post-`verify-blocked` continuation runs under a fresh `agent_id`, the counter loses its key and the "second failing stop → partial-result" escalation never trips. Resolve via Claude + Codex live dogfood, not assumption.
- [ ] **OQ2: how does `stop_hook_active` behave across a validation-blocked stop?** Determines whether the hook can distinguish "first close attempt" from "continued after a block" without its own counter, and guards against an infinite block loop. Resolve via dogfood.
- [ ] **OQ3: audit ordering edge** — confirm that emitting `verify-blocked` instead of `subagent-stop` on a blocked closure does not orphan the dispatch row in `delegation-audit.jsonl` (the dispatch↔stop correlation queries in `delegation.md` § Audit log must still resolve).

## Context / references

- `docs/specs/110-post-edit-validate-multi-runtime/` — the decision spec: `spec.md` § Follow-up path is this spec's brief; `debate.md` is the full Claude↔Codex rationale (resolved `converged` + human override to full removal)
- `.claude/hooks/post-edit-validate.sh` — the hook being **deleted** (current source of the per-edit validator loop + `tdd-advisory:` surfacing + loop-budget)
- `.agent0/hooks/delegation-stop.sh` — the audit-only `SubagentStop` close hook; `delegation-verify.sh` runs adjacent to it (verify-before-close-row ordering), NOT inside it
- `.agent0/hooks/_memory-hook-lib.sh` — `memory_project_dir` / `memory_runtime` / `memory_actor` for runtime-neutral resolution
- `.claude/validators/run.sh` — the validator invoked at stop (full suite + typecheck per stack)
- `.claude/rules/delegation.md` § *Post-edit validator loop* / § *Why DONE_WHEN exists* / § *Audit log* — sections to rewrite
- `docs/specs/106..109` — the `.agent0/` multi-runtime hook migration pattern + the 108/109 dormant-registration lesson (live dogfood on both runtimes is mandatory before shipping)
- <https://developers.openai.com/codex/hooks> — `SubagentStop` carries `agent_id`/`agent_type` + supports `decision:"block"`/exit-2 to continue the subagent flow
