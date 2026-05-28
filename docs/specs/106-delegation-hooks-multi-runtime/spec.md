# 106 — delegation-hooks-multi-runtime

_Created 2026-05-28._

**Status:** shipped

## Intent

Agent0's delegation discipline is implemented as two Claude-exclusive hooks: `delegation-gate.sh` on `PreToolUse(Agent)` (enforces the 5-field handoff, blocks under-specified dispatches with exit 2, appends a dispatch row) and `delegation-stop.sh` on `SubagentStop` (appends a close row with duration / edit-count / correlation). Both write `.claude/delegation-audit.jsonl`. The `runtime-capabilities.md` matrix listed `delegation/subagents | Codex = unsupported`, but a 2026-05-28 verification against Codex's official docs found that cell **stale** (same drift class as the spec 099 Codex-hooks incident): Codex ships a mature subagent feature (`/agent`, explicit "spawn N agents" delegation, `agents.max_depth=1` default) and exposes both `SubagentStart` and `SubagentStop` hook events. This spec records the resolution of **how the delegation discipline spans both runtimes**, decided via a 3-round Claude↔Codex debate (converged 2026-05-28): a **two-layer split** — the 5-field *discipline* is enforced by a blocking hook on Claude but is **convention-only on Codex** (no hook can block a Codex spawn; precedent `user-prompt-framing.md`), while *observability* (start/stop lifecycle audit) is consolidated into a **single canonical `.agent0/delegation-audit.jsonl`** — a hard cutover that removes `.claude/delegation-audit.jsonl` from the harness entirely. See § Acceptance criteria for the resolved contract.

## Acceptance criteria

- [x] **Scenario: Claude gate unchanged (no regression)**
  - **Given** a Claude `Agent` dispatch missing a required handoff field
  - **When** the delegation gate runs at `PreToolUse(Agent)`
  - **Then** it still blocks with exit 2 and the canonical 5-field template, exactly as today

- [x] **Scenario: Codex SubagentStart is observability-only (no compliance claim)**
  - **Given** a Codex subagent dispatch with the Agent0 hooks enabled
  - **When** `SubagentStart` fires
  - **Then** `delegation-start-audit.sh` appends a non-blocking `subagent-start` row keyed by `agent_id`/`agent_type`, with `brief_observable: false` and `formatted: null` **always** (the live Codex 0.134.0 payload carries no brief/instruction field), claiming no block and asserting nothing about 5-field compliance

- [x] **Scenario: Codex delegation discipline is convention-only**
  - **Given** a Codex orchestrator about to spawn a subagent
  - **When** it composes the natural-language dispatch instruction
  - **Then** it self-applies `TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN` because `.claude/rules/delegation.md` mandates it as a convention — no hook enforces it (precedent `user-prompt-framing.md`)

- [x] **Scenario: subagent-stop audit is runtime-neutral (3-tier schema)**
  - **Given** a subagent completes under either runtime
  - **When** `SubagentStop` fires
  - **Then** a close row is appended split into three field tiers — runtime-neutral (`ts`, `runtime`, `session_id`, `agent_id`, `agent_type`, `event`); correlation (Claude `tool_use_id` via sidecar / Codex `agent_id-direct` only when a matching start row exists, else `unmatched`); best-effort-null (`edit_count`, `exit=loop-budget-exceeded`, transcript pointer)

- [x] **Scenario: single canonical audit log (hard cutover)**
  - **Given** either runtime writes a delegation audit row (Claude dispatch/close OR Codex start/close)
  - **When** the row is appended
  - **Then** it lands in `.agent0/delegation-audit.jsonl` and nowhere else — both `delegation-gate.sh:48` and `delegation-stop.sh:27` are repointed from `.claude/` to `.agent0/`; rows carry `runtime` + `event` (the dialect discriminators) + a `schema_version` stamp, with explicit `null`/`unavailable` for fields a runtime cannot supply. No implicit-version / legacy-read rule.

- [x] **`.claude/delegation-audit.jsonl` is removed entirely from the harness** (hard cutover, per `.agent0/memory/forks-ephemeral-dogfood.md`): the gitignored file is deleted and every reference repointed to `.agent0/delegation-audit.jsonl` — the jq queries in `delegation.md` § Audit log, the forensics example in `image-gen.md`, the sibling reference in `memory-placement.md`, and the `.gitignore` + `harness-sync.md` entries. No `.claude/` rows are migrated; they are discarded with the file.

- [x] `runtime-capabilities.md` `delegation/subagents` row corrected to *"Codex has native subagents + opt-in start/stop hooks (observability only), but no pre-dispatch blocking gate; the 5-field discipline is convention-only on Codex"* — with owner files + Notes updated

- [x] The two-layer architecture (discipline = convention via rule; observability = start/stop hooks) is recorded in `plan.md` § Alternatives considered, and `.claude/rules/delegation.md` gains a "Codex: convention-only" section

## Non-goals

- Building an automated cross-model debate runner — that is paused spec 091; this spec uses the human-brokered direct-file debate only.
- Porting the other portable Bash/edit hooks (governance, secrets, supply-chain, runtime-introspect, propagation) — scoped to the delegation pair. The architecture decision may generalize, but those ports are separate units of work.
- **`post-edit-validate.sh` loop-budget half** (delegation-coupled) — deferred. Codex close rows carry `exit: null` and best-effort-null `edit_count`; Codex gets no loop-budget enforcement in this spec.
- **`post-edit-validate.sh` validator-run half** (runs the project validator + emits `tdd`/lint/typecheck advisories) — NOT delegation-specific; a separate port unit belonging with the edit-surface advisory hooks (propagation/secrets/supply-chain), explicitly out of scope here.
- Relocating `.claude/.delegation-state/` (the loop-budget counter state — `agents/` + `validate.lock`, produced by `post-edit-validate.sh:23`, read by `delegation-stop.sh:28`) to `.agent0/`. It **stays in `.claude/`**: its producer is the `post-edit-validate.sh` loop-budget half, which this spec defers for Codex. Per `harness-home.md` § Co-location ("state moves with its producer, never ahead"), the state follows the producer only when the loop-budget half ports to Codex. NOTE the asymmetry with the audit log: the log is shared observability (both runtimes write) → `.agent0/`; `.delegation-state` is a Claude-only counter → stays `.claude/`.
- Implementing Codex-side **blocking** of subagent dispatch — verified impossible across all three candidate hook surfaces: `SubagentStart` is observational (`continue:false` doesn't stop the spawn); `PreToolUse` never fires on a spawn (spawn is not a tool call); `PermissionRequest` does not fire on spawn and is an approval allow/deny, not a 5-field validator. Convention-only is the only path, not a gap to close.
- Changing the 5-field handoff content or grammar itself.

## Open questions

- [x] **Core decision** — RESOLVED (debate): split per-hook, not "delegation" as one unit. `delegation-stop` → shared multi-runner; `delegation-gate.sh` stays Claude-only; Codex gets a separate `delegation-start-audit.sh` (different name, different contract).
- [x] **Codex-side behavior** — RESOLVED: observability-only hook (`SubagentStart` start-audit, non-blocking) + convention-only discipline (rule, not hook; precedent `user-prompt-framing.md`).
- [x] **Structured brief in `SubagentStart`?** — RESOLVED: no. Live Codex 0.134.0 capture + official `additionalProperties:false` schema confirm no brief/instruction field → `brief_observable: false` always; `formatted` uncomputable.
- [x] **Audit-log home** — RESOLVED: single canonical `.agent0/delegation-audit.jsonl` via **hard cutover** — both runtimes write only there, `.claude/delegation-audit.jsonl` removed entirely (no freeze, no legacy-read). Both correlation dialects (Claude `tool_use_id` sidecar / Codex `agent_id-direct`) fit one schema, discriminated by `runtime`+`event`.
- [x] **`post-edit-validate.sh` port** — RESOLVED: 2-way split. Loop-budget half deferred; validator-run half is a separate port unit (with edit-surface advisories), out of scope here.

## Context / references

- `.claude/hooks/delegation-gate.sh`, `.claude/hooks/delegation-stop.sh`, `.claude/hooks/post-edit-validate.sh` — current Claude implementation
- `.claude/rules/delegation.md` — the discipline (5-field handoff, audit schema, advisories, worktree isolation)
- `.claude/rules/runtime-capabilities.md` — matrix row `delegation/subagents` to correct (note the re-audit flag already on the row)
- `.agent0/memory/codex-cli-hooks.md` — Codex 10-event surface + payload-shape compatibility
- `.agent0/memory/harness-home.md` — the `.agent0/` vs `.claude/` classification principle
- `.agent0/hooks/_memory-hook-lib.sh` — precedent shared dual-runtime hook library (runtime/actor/path extraction)
- `docs/specs/102-harness-consolidate-agent0/` — umbrella that deferred delegation as Claude-exclusive
- `docs/specs/099-memory-multi-runtime/` — precedent for a dual-runtime hook port (apply_patch surface)
- Codex subagents: <https://developers.openai.com/codex/subagents> ; Codex hooks: <https://developers.openai.com/codex/hooks> (verified 2026-05-28)
- `.claude/rules/user-prompt-framing.md` — precedent for a rule-only self-applied discipline on an un-hookable boundary (the model for the Codex delegation convention)
- **Architecture decided via 3-round Claude↔Codex `/sdd debate`** (`debate.md`, converged 2026-05-28). Codex provided live `SubagentStart` payload evidence (Codex CLI 0.134.0: fields `session_id`, `turn_id`, `transcript_path`, `cwd`, `hook_event_name`, `model`, `permission_mode`, `agent_id`, `agent_type` — no brief). The no-blocking conclusion was confirmed across all three candidate hook surfaces (`SubagentStart` / `PreToolUse` / `PermissionRequest`) against the official Codex hooks docs.
