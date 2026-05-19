# 062 — goal-skill

_Created 2026-05-19._

**Status:** draft

## Intent

The 5-field handoff at the main→sub boundary (`.claude/hooks/delegation-gate.sh`) is Agent0's discipline counterpart of `/goal` at the user→main boundary. Codex CLI 0.128+ (April 2026) and Claude Code v2.1.139+ ship `/goal` natively: a done-state declared up front with an evaluator loop that asserts the contract before the agent reports complete. Agent0's `.claude/rules/user-prompt-framing.md` currently encodes a lightweight 3-question check (TASK/CONTEXT/DONE) but has **no auto-loop equivalent** — the agent's report of "done" is taken at face value.

This spec ships `/goal` as a skill in `.claude/skills/goal/`. When invoked, the skill:

1. Parses the user's described work into a goal frame with an explicit `DONE_WHEN:` verifier
2. Sets a session-scoped marker (`.claude/.goal-state/<session_id>.json`) carrying the verifier
3. Adds a rule (`.claude/rules/goal-active.md`, loaded conditionally) that instructs the agent to run the verifier before claiming completion
4. Surfaces the goal state in the next `SessionStart` injection (so it survives compaction)
5. On verifier pass → declares complete; on fail → loops with corrective context until pass or budget exhausts

Parent of the umbrella spec 060 (A1, top pick #2 by ROI). Folds in B7 (`UserPromptExpansion` hook as natural surface — close B7 as duplicate when this ships).

## Acceptance criteria

- [ ] **Scenario: user invokes `/goal "<description>"` with implicit done-state**
  - **Given** the prompt does not contain a `DONE_WHEN:` line
  - **When** the skill runs
  - **Then** it asks 1-2 questions via `AskUserQuestion` to infer the done-state (e.g. "tests pass" / "file exists" / "no validator errors"), then proceeds

- [ ] **Scenario: user invokes `/goal` with explicit DONE_WHEN**
  - **Given** the prompt contains a line `DONE_WHEN: <verifier description>`
  - **When** the skill runs
  - **Then** it writes the verifier to `.claude/.goal-state/<session_id>.json` and proceeds without questions

- [ ] **Scenario: verifier-driven completion loop**
  - **Given** an active goal with `DONE_WHEN: "bash .claude/validators/run.sh shows ok=true"`
  - **When** the agent declares "done"
  - **Then** the goal-active rule directs the agent to run the validator; if `ok=true`, contract closed (state file cleared, `.claude/.goal-history.jsonl` row appended); if `ok=false`, agent receives the failure output and re-iterates

- [ ] **Scenario: loop budget exhaustion**
  - **Given** `CLAUDE_GOAL_LOOP_BUDGET` (default 10) iterations elapsed without verifier pass
  - **When** the next "done" declaration would loop
  - **Then** the skill reports a partial result with: what worked, what failed verification, current state, and recommended next step (fresh `/goal` re-issue with narrower scope, or human takeover)

- [ ] **Scenario: `/goal` resumed across compaction**
  - **Given** an active goal exists in `.claude/.goal-state/<session_id>.json` at compaction time
  - **When** `SessionStart(source=compact)` fires
  - **Then** the goal state is injected into context alongside `SESSION.md` and `COMPACT_NOTES.md`; the agent resumes the loop without losing the verifier contract

- [ ] **Scenario: `/goal list` / `/goal close` / `/goal status` subcommands**
  - **Given** the user wants to inspect or manually close an active goal
  - **When** they invoke `/goal list`, `/goal status`, or `/goal close`
  - **Then** the skill returns the active state (or empty) / marks complete with override reason

- [ ] `.claude/skills/goal/SKILL.md` exists, passes `/skill validate goal` per agentskills.io spec
- [ ] `.claude/skills/goal/SKILL.md` declares `metadata.agent0-portability-tier: cc-native` (uses session-scoped state file, conditional rule load)
- [ ] `.claude/rules/goal-active.md` exists with `paths:` frontmatter limiting load to when goal state is active
- [ ] Goal history JSONL (`.claude/.goal-history.jsonl`) is gitignored; the active state dir `.claude/.goal-state/` is gitignored

## Non-goals

- Native (non-skill) hook implementation — defer until skill proves the shape; if dogfood shows the rule-only verifier doesn't bite (per `user-prompt-framing.md`'s same observation), a `UserPromptSubmit` or `PostToolUse(Stop)` hook becomes v2
- Multi-step goal trees (sub-goals) — single `DONE_WHEN` per invocation in v1
- Cost-based termination (budget is iteration count, not USD); cost tracking belongs in spec 060 §A6
- Cross-session goal persistence beyond compaction (a goal that survives a full session restart) — open it again with `/goal` if needed
- Replacing `user-prompt-framing.md` — the 3-question check stays as the lightweight default; `/goal` is the opt-in for explicit contracts on substantive work
- Integration with `Agent` dispatches (a `/goal` does NOT auto-add `DONE_WHEN` to every sub-agent brief — delegation gate is independent)

## Open questions

- [ ] **Verifier shape: free-prose vs structured?** Free-prose (`DONE_WHEN: tests pass`) requires the agent to interpret the verifier on each loop iteration. Structured (`DONE_WHEN: { command: "bun test", expect_exit: 0 }`) is mechanical but constrains expressiveness. Proposed: free-prose with a strong convention — encourage commands the runtime-introspect probe can verify (`bash .claude/tools/probe.sh last-run` returns `exit_code == 0`).
- [ ] **Loop-budget default = 10. Calibration?** Codex `/goal` uses iteration counts up to ~20-30 reportedly. Agent0's existing `CLAUDE_DELEGATION_LOOP_BUDGET=5` is conservative. 10 is a middle ground for the v1 dogfood window; revisit after 5+ real `/goal` sessions.
- [ ] **State file format: JSON or plain text?** JSON is jq-friendly and matches existing audit-log shape (`.claude/delegation-audit.jsonl`). Plain text is `cat`-friendly and shellable. Lean JSON for consistency.
- [ ] **Should the verifier be re-run automatically every N turns (active polling) or only when the agent declares "done" (lazy)?** Lazy in v1 — active polling adds noise. Re-evaluate if "agent declares done prematurely" is a frequent dogfood failure mode.

## Context / references

- Parent umbrella: `docs/specs/060-harness-gaps-2026/spec.md` § Gap matrix row A1
- `.claude/rules/user-prompt-framing.md` — lightweight 3-question check this complements
- `.claude/rules/delegation.md` § Why DONE_WHEN exists — the contract-not-promise framing already documented at the sub-agent boundary
- `.claude/rules/compaction-continuity.md` — pattern for state surviving compaction (the goal state file must integrate with this)
- Codex `/goal` design: https://simonwillison.net/2026/Apr/30/codex-goals/
- `/goal` three components: https://apidog.com/blog/goal-command-codex-claude-code-autonomous-agents/
- Codex/Claude Code harness comparison: https://medium.com/jonathans-musings/inside-the-agent-harness-how-codex-and-claude-code-actually-work-63593e26c176
- Existing skills as structural reference: `.claude/skills/remind/SKILL.md` (state file + readout), `.claude/skills/sdd/SKILL.md` (subcommand parsing)
