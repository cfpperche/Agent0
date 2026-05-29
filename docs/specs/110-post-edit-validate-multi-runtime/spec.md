# 110 — post-edit-validate-multi-runtime

_Created 2026-05-29._

**Status:** shipped — decision spec delivered; all 4 OQs resolved via Codex debate (`converged`); human-in-loop chose **full removal** over the debate's two-hook split; one successor implementation spec declared
**Type:** research

## Intent

`post-edit-validate.sh` is the last gate-class hook still living in `.claude/hooks/` (Claude-only) after the 106–109 migration moved delegation/governance/secrets/supply-chain to runtime-neutral `.agent0/` hooks. Before mechanically applying the same cutover pattern, three questions need resolving — and the third may invalidate the hook's current shape entirely, so this is a **decision spec driven by a Codex CLI debate**, not a port-it-now spec.

The three axes: **(1) Viability** — is a runtime-neutral port even possible, given the hook's core discriminator (presence of `agent_id` → "this is a delegated sub-agent edit") and its loop-budget counter are documented as Claude-only in `delegation.md`? **(2) Trigger/cost redesign** — the validator runs the *full project test suite + typecheck* (`bun test && bun tsc --noEmit`, `pytest && mypy`, `go test ./... && go vet`, etc.) on **every** sub-agent `Edit`/`Write`/`MultiEdit`. Running the whole suite per-edit is expensive and arguably the wrong shape; a better trigger must be found. **(3) Nomenclature** — `post-edit-validate` names the *trigger* (post-edit), not the function; if the trigger moves (e.g. to `SubagentStop`), the name lies. Siblings were renamed on move (`supply-chain-scan` → `supply-chain-preflight`). The name decision is coupled to axis 2.

**Debate outcome (2026-05-29, resolved `converged` — see `debate.md`):** the Claude↔Codex debate verified that the per-edit `apply_patch` port is non-viable (Codex `PostToolUse(apply_patch)` carries no actor discriminator) and recommended a two-hook split (keep `post-edit-validate.sh` Claude-only + add a runtime-neutral `SubagentStop` verifier).

**Final decision (2026-05-29, human-in-loop):** simplify further than the debate's recommendation — **remove `post-edit-validate.sh` entirely** and replace it with a single runtime-neutral **`delegation-verify.sh` at `SubagentStop`**. The per-edit validation layer is dropped outright on both runtimes; stop-time DONE_WHEN verification is deemed sufficient. This accepts the loss of mid-flight thrash detection in exchange for one honest, runtime-neutral hook and zero per-edit suite cost.

## Acceptance criteria

_This is a decision spec: "delivered" means the debate produced documented, research-backed resolutions for all three axes plus a declared follow-up path. Implementation is a separate, gated step._

- [x] **Scenario: viability resolved against real Codex payload**
  - **Given** the actual field set of the Codex `PostToolUse(apply_patch)` payload (verified against official Codex hooks docs per `research-before-proposing.md`, NOT assumed)
  - **When** the debate concludes
  - **Then** `spec.md` records whether a runtime-neutral port is `viable` / `partial` / `rejected (keep Claude-only)`, with the `agent_id`-equivalent actor-detection question explicitly answered
  - _Resolved: per-edit port **rejected**; portable boundary is `SubagentStop` (OQ1)._

- [x] **Scenario: per-edit cost redesigned**
  - **Given** the current design runs the full suite + typecheck on every sub-agent edit
  - **When** the debate concludes
  - **Then** a specific better trigger is chosen and documented (named alternative + rationale), with the tradeoff against the DONE_WHEN enforcement contract (`delegation.md` § Why DONE_WHEN exists) spelled out
  - _Resolved: the per-edit validation layer is **removed entirely**; the full suite runs once at `SubagentStop` via `delegation-verify.sh`. No per-edit check remains on either runtime (human-in-loop decision over the debate's demote-to-advisory)._

- [x] The hook's name decision is recorded — keep `post-edit-validate` or rename to a chosen value — with rationale, and explicitly coupled to the axis-2 trigger choice _(keep `post-edit-validate.sh`; new `delegation-verify.sh` — OQ4)_
- [x] A follow-up path is declared: either this spec proceeds to `/sdd plan` + `tasks` for implementation, or a successor spec number is named _(two successor specs declared below)_
- [x] `docs/specs/110-post-edit-validate-multi-runtime/debate.md` exists with ≥1 completed Codex critique round and a synthesis _(2 Codex critique rounds + converged synthesis)_
- [ ] The follow-up implementation spec MUST carry a **real Codex `SubagentStop` dogfood** (108/109 lesson — fixtures alone don't prove a registration fires) and dogfood `agent_id`-preservation + `stop_hook_active` behavior across a validation-blocked stop _(carried forward to the successor spec; not satisfiable in this decision spec)_

## Non-goals

- **Implementing the port.** This spec resolves the three decisions; the code move is gated on the outcome (and may be rejected outright).
- **Redesigning the validator command set** (`.claude/validators/run.sh`). Axis 2 is about *when/whether* to run, not *what* the validator runs per stack.
- **Changing the parent-edit exemption.** The parent agent is verified by running tests directly; that asymmetry is intentional and out of scope.
- **Touching the shipped 106 delegation observability hooks** (`delegation-start-audit.sh` / `delegation-stop.sh`). Those already cover the Codex dispatch/close surface.
- **A per-edit `apply_patch` port (REJECTED — debate outcome).** Codex `PostToolUse(apply_patch)` carries no parent-vs-subagent discriminator (verified, see § Context), so a per-edit port cannot know who edited.
- **Validating all Codex edits / removing the parent-edit exemption (REJECTED).** Would run full validators during ordinary parent iteration, verifying iteration rather than delegated DONE_WHEN claims.
- **Undocumented transcript/session heuristics for actor detection (REJECTED).** Violates the docs-not-training-data constraint; brittle hidden contract.
- **Keeping any per-edit validation layer, including the debate's two-hook split (REJECTED — final decision).** The debate recommended keeping `post-edit-validate.sh` Claude-only (demoted to advisory) alongside the new stop verifier. The human-in-loop rejected that in favor of full removal: one hook, stop-time only. Mid-flight thrash detection is consciously given up.
- **The validator `--mode` contract / fast per-edit follow-up (DROPPED).** With no per-edit check surviving, there is nothing to make "fast"; the second successor spec the debate proposed is cancelled.

## Open questions

_The three axes, made explicit. These are the debate agenda._

- [x] **OQ1 (viability — the gating question). RESOLVED:** Codex `PostToolUse(apply_patch)` carries **no** `agent_id` or parent-vs-subagent discriminator (verified against the official Codex hooks reference — `agent_id`/`agent_type` documented only on `SubagentStart`/`SubagentStop`). The per-edit gate cannot be replicated on Codex → per-edit port rejected; portable boundary is `SubagentStop`.
- [x] **OQ2 (block + loop-budget semantics on Codex). RESOLVED:** the real limitation is "no per-edit actor + no free Claude-style loop-budget," not "Codex can only advise." `SubagentStop` `decision:"block"`/exit-2 *can* block closure and request a continuation. A stop-time budget is a new Agent0-owned primitive (first failing stop → block + one continuation; second → force partial-result), **dogfood-gated** on `agent_id` preservation across a continued stop + `stop_hook_active` behavior.
- [x] **OQ3 (trigger redesign — the "suite per edit is bad" question). RESOLVED:** the per-edit validation layer is **removed**, not redesigned. The full suite runs once at `SubagentStop` via `delegation-verify.sh`. There is no per-edit check on either runtime, so the validator `--mode` contract (`edit-fast` vs `done-full`) the debate floated is **dropped** — there is no fast per-edit check left to define. `delegation-verify.sh` is a standalone hook, NOT folded into the audit-only/fail-open `delegation-stop.sh`.
- [x] **OQ4 (nomenclature). RESOLVED:** `post-edit-validate.sh` is **deleted** (no per-edit hook survives, so the trigger-named file has nothing to name). The single hook is `delegation-verify.sh` — a function/actor name honest about its `SubagentStop` trigger and delegated-verification role.

## Context / references

- `.claude/hooks/post-edit-validate.sh` — the hook under discussion (PostToolUse(Edit|Write|MultiEdit), delegated-edit only, full-suite validator + loop-budget)
- `.claude/validators/run.sh` — the validator it invokes (runs full test suite + typecheck per detected stack: bun/pnpm/npm/python/go/rust/Laravel)
- `.claude/rules/delegation.md` § *Post-edit validator loop* + § *Why DONE_WHEN exists* — the enforcement contract this hook materializes
- `.agent0/hooks/_memory-hook-lib.sh` — `memory_extract_paths` / `memory_patch_body` / `memory_runtime` / `memory_actor` already solve `apply_patch` path + runtime + actor extraction (so path-extraction is NOT the hard part; OQ1 is)
- `docs/specs/106..109` — the migration pattern + rename precedent (`supply-chain-scan` → `supply-chain-preflight`); the 108 dormant-`if` lesson (tests passing ≠ registration fires)
- `.agent0/memory/codex-cli-hooks.md` — Codex hook surface notes (input for OQ1/OQ2)
- `.claude/rules/research-before-proposing.md` + `feedback_verify_runtime_capabilities` — verify Codex payload shape via official docs before asserting
- <https://developers.openai.com/codex/hooks> — **OQ1 source of record**: `PostToolUse(apply_patch)` input fields carry no actor discriminator; `agent_id`/`agent_type` only on `SubagentStart`/`SubagentStop` (verified by the Codex CLI reviewing agent, 2026-05-29)
- `debate.md` (this spec dir) — full cross-model debate transcript (Claude ↔ Codex CLI), resolved `converged`

## Follow-up path

This decision spec is delivered. Implementation is **one** successor spec (declared, not yet scaffolded):

**`delegation-verify.sh` — runtime-neutral `SubagentStop` delegated-verification hook (+ removal of `post-edit-validate.sh`).** Scope:

- **Add** `.agent0/hooks/delegation-verify.sh` — fires on `SubagentStop` (Claude) / `SubagentStop` (Codex, opt-in via `.codex/config.toml`); resolves the project validator (`.claude/validators/run.sh`) and runs the full suite once at delegated-task close, keyed by documented `agent_id`; sources `_memory-hook-lib.sh` for `memory_project_dir`/`memory_runtime`. Block-on-fail via exit-2 (Claude) / `decision:"block"` (Codex) → request one focused continuation; a second failing stop forces partial-result. Agent0-owned counter keyed by `agent_id`, state under `.agent0/.delegation-state/`.
- **Verify-before-close-row ordering** vs `delegation-stop.sh`: verification runs first; a blocked closure writes a `verify-blocked` status; the `subagent-stop` audit close row is appended only when closure is accepted (don't record a stop for a sub-agent that didn't close).
- **Delete** `.claude/hooks/post-edit-validate.sh` + its `PostToolUse(Edit|Write|MultiEdit)` registration in `.claude/settings.json`.
- **Relocate the `tdd-advisory:` surfacing** — currently emitted by `post-edit-validate.sh` on the exit-0 path. It moves to `delegation-verify.sh` (surfaced once at stop) so the TDD coverage signal is not lost with the removal.
- **Rewrite `delegation.md`** § *Post-edit validator loop* → a stop-time *delegated-verification* section (new trigger, new budget semantics, both-runtime); update the `loop-budget`/`exit` fields in § *Audit log* accordingly.
- **Clean up Claude-only per-edit state** — `.claude/.delegation-state/agents/` per-edit counters are superseded by the stop-keyed counter.
- **Sweep** stale `post-edit-validate` refs across `CLAUDE.md`, `.claude/rules/*`, `.claude/rules/runtime-capabilities.md` matrix, `.agent0/memory/*`, the perf harness, and tests; add `.claude/tests/delegation-verify/`.
- **MUST** include a real Codex `SubagentStop` live dogfood + verification of `agent_id`-preservation and `stop_hook_active` behavior across a validation-blocked stop (108/109 lesson — fixtures don't prove a registration fires).
