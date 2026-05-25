# 002 — delegation

_Created 2026-05-10._

**Status:** shipped

## Intent

A "delegation capacity" for this Claude Code project: harness-level guardrails around how the parent agent dispatches sub-agents via the `Agent` tool, and around what happens when those sub-agents edit files.

It addresses three observed failure modes:

1. **Under-specified briefs.** Sub-agents are dispatched with one-line prompts that omit scope, constraints, and done-criteria. The sub-agent invents its own framing and drifts from intent.
2. **"Done" without verification.** A sub-agent edits files, declares the task complete, and the parent only discovers later that types or tests are broken.
3. **Habitual model selection.** Genuinely complex delegations (cross-domain, security-sensitive, schema-touching, many-file) default to the same model as trivial ones because the parent picks defaults out of habit, not signal.

The capacity forces a structured 5-field handoff before dispatch, logs every delegation with a model-escalation advisory, and re-runs the project's validation suite after a delegated agent edits files — blocking the sub-agent into a fix-then-retry loop instead of letting half-done work surface as "done".

## Acceptance criteria

Each item below must be demonstrable live against the implemented hooks.

- [ ] One-liner `Agent` call (no 5 fields, no override marker) → blocked with `exit 2`; canonical 5-field template printed to stderr so the parent can reformat and retry.
- [ ] Full 5-field `Agent` call (TASK + CONTEXT + CONSTRAINTS + DELIVERABLE-or-DONE_WHEN, case-insensitive) → passes; audit log gains a JSONL line marked as formatted.
- [ ] `Agent` call carrying a valid override marker (`# OVERRIDE: <reason ≥10 chars>`) → passes without 5-field validation; audit still logs the call (marker recorded, not bypass-silent).
- [ ] `Agent` prompt mentioning auth + payment + tokens + 3 APIs (≥2 escalation signals) on a non-opus model → advisory surfaces in `additionalContext` suggesting opus; call is NOT blocked.
- [ ] When a delegated agent edits a file and the validator returns failure → `PostToolUse` blocks with `exit 2` and the tail of validator stdout/stderr; repeat past `CLAUDE_DELEGATION_LOOP_BUDGET` (default 5) → stderr switches to `LOOP BUDGET EXCEEDED` with directive to stop editing and report partial.
- [ ] Parent (non-delegated) edits never trigger the post-edit validator — actor detection is load-bearing.
- [ ] Validator missing or broken → fails open (no block); validator script must auto-detect bun / pnpm / npm / python / go / rust and emit a passing result when no stack matches.
- [ ] Concurrent edits don't pile up validations — non-blocking lock; if a validation is in flight, second edit exits 0.

## Non-goals

- **Filtering by sub-agent type.** Every `Agent` call is gated regardless of `subagent_type` (Explore, Plan, general-purpose, etc.). No allowlist of "trusted" sub-agents.
- **Requiring both DELIVERABLE and DONE_WHEN.** Either alone satisfies the 5-field check. They are alternative phrasings of the same intent (artifact vs condition).
- **Blocking on the audit hook.** PreToolUse only blocks on missing fields (and only when no override). Logging and the model advisory never block.
- **Applying the post-edit validator to the parent agent.** Parent direct edits are exempt by design — actor detection gates the entire validator path.
- **Fail-closed on missing/broken validator.** A broken or absent validator must never permanently block the agent from editing. Fail-open is the contract.
- **Replacing the Governance capacity.** Delegation gates `Agent`-tool dispatch and post-edit validation; Governance gates `Bash`-tool destructive patterns. They are independent hooks with shared conventions, not a merger.

## Open questions

All three resolved 2026-05-10 by docs research (`claude-code-guide` agent against `https://code.claude.com/docs/en/hooks.md`) plus an empirical probe hook (registered temporarily via `.claude/settings.local.json`, fired on PreToolUse(Agent) and PostToolUse(Edit) for both a parent edit and a delegated sub-agent edit, then removed). Findings inform `plan.md` directly; no remaining unknowns block implementation.

- [x] **Tool-name matcher for sub-agent dispatch.** Resolved: `Agent`. Renamed from `Task` in Claude Code v2.1.63; `Task` still works as an alias but `Agent` is canonical.
- [x] **Payload shape for `PreToolUse(Agent)`.** Resolved: `tool_input` exposes `prompt`, `description`, `subagent_type`, and `model` — but `model` is **absent** from `tool_input` when the parent does not specify a model (it is not present-as-null; the key is missing). The 5-field validator reads `tool_input.prompt`; the model-advisory must treat absent `model` as "inherited / unspecified" and skip rather than fail. `additionalContext` from this hook is emitted as `{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "allow", "additionalContext": "..." } }`.
- [x] **Actor detection for `PostToolUse(Edit|Write|MultiEdit)`.** Resolved: the `PostToolUse` payload includes `agent_id` and `agent_type` keys when the actor is a delegated sub-agent, and **omits both keys entirely** when the actor is the parent. This is the discriminating signal. `session_id` and `transcript_path` are **identical** between parent and sub-agent in the same Claude Code session (both inherit the parent's transcript), so they are NOT useful for actor detection — only `agent_id` is. Loop-budget counters key on `agent_id`. Docs (`code.claude.com/docs/en/hooks.md`) did not mention this; the signal was confirmed only by probe.

## Context / references

- `docs/specs/001-governance-gate/` — sibling capacity. Establishes the override-marker shape, jq-on-stdin convention, and fail-open posture this spec inherits.
- `.claude/hooks/governance-gate.sh` — reference implementation of a `PreToolUse` blocker with override support.
- `.claude/rules/spec-driven.md` — why this work is spec-first (new module, 4+ files, new behavior contract).
- `.claude/rules/research-before-proposing.md` — drives the open-questions resolution flow before `plan.md`.
- Claude Code hooks documentation (to be fetched during open-question resolution): `https://docs.anthropic.com/en/docs/claude-code/hooks` (URL to confirm via guide agent).
