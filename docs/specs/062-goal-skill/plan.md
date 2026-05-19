# 062 — goal-skill — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Implement `/goal` as a CC-native skill (`.claude/skills/goal/SKILL.md`) with subcommand parsing modeled on `/sdd` and `/remind`. State is a per-session JSON file at `.claude/.goal-state/<session_id>.json`; history is `.claude/.goal-history.jsonl`. The behavioral discipline is rule-only at the agent boundary — a conditional rule (`.claude/rules/goal-active.md` with `paths:` frontmatter restricting it to load only when the state file exists) instructs the agent to run the verifier before claiming completion.

This is intentionally a "rule plus state file" approach rather than a hook-based enforcement. Rationale: same as `user-prompt-framing.md` — the main agent IS the actor being disciplined, and the harness can't intercept "the agent says done" to externally verify. The skill's value is structuring the contract (DONE_WHEN inline in context) and surviving compaction (state file re-injected by `SessionStart`). If empirical dogfood shows the agent prematurely declares done >3 times despite the rule, v2 ships a `UserPromptSubmit` or `Stop` hook (same rule-of-three demand-test the parent rule uses).

Order of operations:

1. Audit existing skill structure (`brainstorm/`, `remind/`, `sdd/`) to identify the conventions for: subcommand parsing, state-file paths, output format.
2. Scaffold `.claude/skills/goal/` directory with `SKILL.md`, `templates/`, `references/`. Use `/skill new goal --tier cc-native`.
3. Implement subcommands in `SKILL.md` body: `start "<description>"`, `status`, `close [--override]`, `list`.
4. Add the conditional rule `.claude/rules/goal-active.md` with `paths:` frontmatter (load only when state file exists — verify Claude Code's `paths:` matcher supports this; if not, fall back to unconditional load with a `if state file exists` runtime check at top).
5. Update `.claude/hooks/session-start.sh` to inject the active goal state into context if present.
6. Update `.claude/hooks/pre-compact.sh` to mark goal state for survival (likely already covered by the state file's persistence — verify).
7. Add `.claude/.goal-state/` and `.claude/.goal-history.jsonl` to `.gitignore`.
8. Add to `CLAUDE.md` § capacity inventory after spec ships.
9. Document the integration with `user-prompt-framing.md` (which is the umbrella discipline; `/goal` is the explicit-contract escalation).

## Files to touch

**Create:**
- `.claude/skills/goal/SKILL.md` — skill body with subcommands
- `.claude/skills/goal/references/loop-budget-tuning.md` — guidance on when to raise/lower budget
- `.claude/skills/goal/templates/state.json.tmpl` — initial state file shape
- `.claude/rules/goal-active.md` — conditional rule loaded when goal is active
- `.claude/.goal-state/.gitkeep` — ship the empty dir scaffold

**Modify:**
- `.gitignore` — add `.claude/.goal-state/*` (keep `.gitkeep`), `.claude/.goal-history.jsonl`, `.claude/.goal-history.jsonl.lock`
- `.claude/hooks/session-start.sh` — emit goal state block alongside SESSION.md
- `CLAUDE.md` § capacity inventory — add `/goal` section (one paragraph)
- `.claude/rules/user-prompt-framing.md` § Cross-references — add pointer to `/goal` as the explicit-contract escalation

**Delete:** none

## Alternatives considered

### Hook-based enforcement (e.g. `Stop` hook that re-runs verifier)

Rejected for v1 because: (a) the `Stop` hook fires after the main agent declares stop, which is after-the-fact rather than gating, (b) same observation as `user-prompt-framing.md` — the actor being disciplined cannot externally enforce on itself, and the loop the agent runs is internal to its turn, not visible to hooks per-turn, (c) starting with a rule-only approach matches the rule-of-three demand-test pattern. If dogfood shows premature-done declarations, v2 reaches for a hook.

### Use the existing `delegation-gate.sh` extended to accept `/goal` as a special pseudo-Agent dispatch

Rejected because conflating user→main contract with main→sub contract muddies the audit log (different `subagent_type`, different lifecycle, different state semantics). Two separate audit surfaces is cleaner.

### Implement `/goal` as a slash-command alias for the Claude Code v2.1.139+ native command instead of a skill

Rejected because the native `/goal` may not exist yet in the user's CC version (verify in tasks step 1), is not configurable per-project, and is opaque to forks. A skill is portable, customizable, and works regardless of CC version. If the native `/goal` ships fully compatible later, we can deprecate the skill and document the transition.

### Store goal state in `SESSION.md` instead of a separate file

Rejected because `SESSION.md` has a hard ~2KB size discipline (`.claude/rules/session-handoff.md`), and a goal frame with verifier description + iteration log would consume disproportionate budget. Separate state file is bounded and only injected when active.

## Risks and unknowns

- **Risk: conditional rule loading via `paths:` may not support "load only if file exists" predicate.** Verify Claude Code's path-glob matcher capabilities. Fallback: load the rule unconditionally with a top-of-rule "this rule only applies when `.claude/.goal-state/<session>.json` exists" check the agent reads.
- **Risk: free-prose verifier interpretation is lossy.** "Tests pass" can mean different things across sessions; the agent might mis-interpret. Mitigation: the skill encourages users to use commands the runtime-introspect probe verifies (`bash .claude/tools/probe.sh last-run` exit_code).
- **Risk: native `/goal` shipping in Claude Code may collide with our skill name.** Skills are namespace-distinct from native commands, but UI confusion is possible. Mitigation: name skill `/goal` deliberately to match; document the relationship in SKILL.md description.
- **Unknown: does `SessionStart` hook output get injected before the next user prompt, or alongside it?** The pre-compact + compact source pattern works for restored state; verify the same path works for `startup` source mid-session.
- **Unknown: how to count "iterations" precisely?** Naive: each "done" declaration that triggers verifier failure increments counter. Edge: agent re-reads verifier mid-loop without declaring done — does that count? Proposed: only "agent stops with done claim" counts; mid-loop reads don't.

## Research / citations

- Codex `/goal` deep-dive: https://simonwillison.net/2026/Apr/30/codex-goals/ — contract-not-promise frame, evaluator loop pattern
- `/goal` three components (work + done-state + constraints): https://apidog.com/blog/goal-command-codex-claude-code-autonomous-agents/
- Harness comparison: https://medium.com/jonathans-musings/inside-the-agent-harness-how-codex-and-claude-code-actually-work-63593e26c176
- agentskills.io spec for cross-runtime portability: https://agentskills.io/specification (skill itself is `cc-native` tier per use of session-scoped state)
- Internal: `.claude/rules/delegation.md` § Why DONE_WHEN exists — the contract framing this externalizes to the user boundary
- Internal: `.claude/rules/user-prompt-framing.md` — the lightweight default `/goal` escalates beyond
