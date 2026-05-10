# Delegation

Sub-agent dispatches via the `Agent` tool are gated. Two cooperating hooks enforce the discipline so under-specified briefs and unverified "done" claims surface immediately instead of after the fact:

- **`PreToolUse(Agent)`** → `.claude/hooks/delegation-gate.sh` validates a 5-field handoff, honours an `# OVERRIDE:` marker, appends an audit line, and may attach a complexity advisory.
- **`PostToolUse(Edit|Write|MultiEdit)`** → `.claude/hooks/post-edit-validate.sh` re-runs the project validator after a *delegated* agent edits a file. Parent edits are exempt by design.

Spec: `docs/specs/002-delegation/`.

## The 5-field handoff

Every `Agent` prompt must include four required fields and one of two outcome fields. Field names are case-insensitive; order is free; any text after the colon counts. Missing fields → `exit 2` with the canonical template printed to stderr below.

- **TASK** — one sentence stating what the sub-agent is to do. No background, no rationale; the verb and object.
- **CONTEXT** — files, paths, links, prior decisions the sub-agent should read first. This is what keeps the sub-agent from inventing its own framing.
- **CONSTRAINTS** — what NOT to do; budgets (time, file count); style; scope guardrails; "do not modify X". The negative space matters as much as the task.
- **DELIVERABLE** — concrete artifact the sub-agent produces (file path, PR, summary shape). Use this when there is a thing.
- **DONE_WHEN** — verifiable condition (tests pass, file exists, command succeeds). Use this when there is a state. Either DELIVERABLE or DONE_WHEN satisfies the outcome slot — both are accepted, neither is required alongside the other.

Canonical template (verbatim from `delegation-gate.sh` stderr):

```
  TASK: <one sentence — what to do>
  CONTEXT: <files/paths/links the sub-agent should read first>
  CONSTRAINTS: <what NOT to do; budgets; style; scope guardrails>
  DELIVERABLE: <concrete artifact — file path, PR, summary shape>
  DONE_WHEN: <verifiable condition — tests pass, file exists, etc.>
```

## Override marker

Same shape as the governance gate (see `docs/specs/001-governance-gate/`): a line `# OVERRIDE: <reason ≥10 chars>`, case-sensitive, terminated by end-of-line. The reason is the audit trail — write something a future maintainer can grep for. "skip", "bypass", "n/a" are not reasons. A reason shorter than 10 chars after trimming is rejected and the gate blocks as if no marker were present (with a hint that the reason is too short).

The marker skips ONLY the 5-field validation. It does NOT skip the audit append (the marker reason is recorded in the `override` field) and does NOT skip the escalation-advisory pass. There is no silent bypass.

## Post-edit validator loop

When a delegated sub-agent edits a file, the post-edit hook runs the project validator (`.claude/validators/run.sh` by default, auto-detecting bun / pnpm / npm / python / go / rust). The validator emits a JSON object with an `ok` field. Fail → `exit 2` with the validator stdout/stderr tail surfaced to the sub-agent, which then has to fix the failing checks and re-edit.

Counters are per-`agent_id` under `.claude/.delegation-state/agents/`. After `CLAUDE_DELEGATION_LOOP_BUDGET` consecutive failures (default 5), stderr switches to `LOOP BUDGET EXCEEDED` and the sub-agent is directed to **stop editing and report a partial result** describing what worked, what failed validation, and what remains for a fresh delegation or a human to finish. A passing validation resets the counter — recovery in-flight is fine; the cap exists to stop fix-loops that aren't converging.

Parent agents do NOT trigger the validator (actor detection keys on the `agent_id` payload field, which is absent for parent edits). This is by design — the parent is expected to be running tests directly.

Tuning:

- `CLAUDE_DELEGATION_VALIDATOR=/abs/path/to/script` — override the validator path. The script must emit a JSON `{ ok, command, exit, duration_ms, stdout, stderr }` object on stdout.
- `CLAUDE_DELEGATION_LOOP_BUDGET=N` — change the consecutive-failure cap. Default 5.

If the validator is missing, non-executable, or emits unparseable output, the hook fails open (no block). A broken validator must never permanently lock the agent out of editing.

The validator may also append a `warnings` array to its JSON output on stack-detected paths. The post-edit hook reads any warnings and echoes each one to stderr with a `tdd-advisory:` prefix on the exit-0 path — non-blocking advisories that surface to the agent on its next turn. This is how TDD test-coverage advisories reach the agent today; see `.claude/rules/tdd.md` for the warning shape and the response convention.

## Audit log

`.claude/delegation-audit.jsonl` (gitignored, append-only). One JSON object per line, ten fields: `ts`, `session_id`, `subagent_type`, `model`, `model_specified`, `formatted`, `override`, `advisory_emitted`, `escalation_signals`, `task_summary`. Read with `jq -c .` or `tail -f`. Blocked calls are NOT logged — only allowed dispatches reach the audit phase.

## Escalation advisory

The gate scores 5 signals against the prompt: `large-fileset`, `multi-integration`, `cross-domain`, `schema-data`, `security`. If two or more fire AND the call is on a non-opus model (or no model was specified), an advisory is attached to the call's `additionalContext` suggesting `model: "opus"`. The advisory is informational — the call is always allowed. Treat it as a nudge to reconsider model choice, not a verdict.

## Gotchas (for hook maintainers)

- **`jq '.field // empty'` collapses `false` and missing into the same empty string.** When reading the validator's `ok`, use `if type=="object" and has("ok") then (.ok|tostring) else "" end` so `false` (real failure) and missing (broken validator → fail open) stay distinguishable.
- **`exec 9>file 2>/dev/null` is a sticky redirect.** A bare `exec` with no command applies the redirections to the current shell — `2>/dev/null` would permanently silence stderr for the rest of the script and eat every block message. Probe writability in a subshell (`( : >>"$path" ) 2>/dev/null || exit 0`) before the bare `exec`.
