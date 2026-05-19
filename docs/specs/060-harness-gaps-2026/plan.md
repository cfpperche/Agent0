# 060 — harness-gaps-2026 — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

This is an umbrella spec — there is no implementation in `060/` itself. The plan is procedural: scaffold the top-3 follow-up specs immediately (specs 061/062/063), document the `**Type:** umbrella` convention in `.claude/rules/spec-driven.md`, and leave the remaining §A/§B rows in a "pending follow-up spec" state to be scaffolded when prioritized.

The umbrella is delivered when every row in §A/§B has either a follow-up spec or an explicit close-decision recorded inline in `spec.md` § Gap matrix. §C is documentation-only and requires no further action.

## Files to touch

**Create:** (follow-up specs scaffolded alongside this umbrella)
- `docs/specs/061-subagent-stop-hook/{spec,plan,tasks,notes}.md` — top pick #1
- `docs/specs/062-goal-skill/{spec,plan,tasks,notes}.md` — top pick #2
- `docs/specs/063-worktree-isolated-subagents/{spec,plan,tasks,notes}.md` — top pick #3

**Modify:**
- `.claude/rules/spec-driven.md` — add one paragraph under § The four artifacts documenting `**Type:**` convention (values: omitted default vs `umbrella`)

**Delete:** none

## Alternatives considered

### Open all 17 §A+§B follow-up specs immediately

Rejected because (a) most rows are média/baixa priority and would create stale draft specs that rot, (b) the user explicitly asked for "por ordem de prioridade", which implies iterative scaffold-as-prioritized, (c) the top-3 cover all alta priority items — the rest can wait for the next prioritization conversation.

### Convert this spec into a tracking issue instead of an umbrella spec

Rejected because Agent0 is OSS-spec-shaped, not ticketing-shaped — `docs/specs/` is the design memory, `.claude/REMINDERS.md` is the lightweight deferred-todo surface, and the gap between those (multi-item tracker with discipline) is what `umbrella` fills. Issues are also fork-local (no GitHub assumption in Agent0 base).

### YAML frontmatter for spec type instead of `**Type:**` line

Rejected because the existing convention uses `**Status:**` as a bolded inline line, not frontmatter. Adopting YAML would force migrating 59 existing specs OR live with mixed shapes. The bolded line is convention-light, matches `**Status:**`, costs one line.

## Risks and unknowns

- **Risk: §A/§B rows go stale.** If no follow-up specs are scaffolded for medium-priority rows within ~60 days, the umbrella becomes documentation of inaction. Mitigation: add a reminder in `.claude/REMINDERS.md` to re-review the matrix after spec 061 ships.
- **Risk: spec 061/062/063 reveal that the gap matrix priorities are wrong.** Empirical signal from the first follow-up may demote/promote rows. Mitigation: the umbrella is a `draft` artifact — `spec.md` is editable; revise the matrix when evidence arrives.
- **Unknown: does Claude Code's `SubagentStop` hook event actually carry the fields spec 061 assumes (`tool_use_id`, exit code)?** The agentic-AI hooks reference cited in research describes it but the schema needs verification before 061 plan is locked. Spec 061's plan flags this as its own open question.
- **Unknown: `/goal` skill (062) wants to assert termination after each assistant turn — Claude Code does not expose a "before user response" hook to the skill code.** The skill may need to surface a per-turn rule instead of a hook, similar to `user-prompt-framing.md`. Spec 062 plan resolves this.

## Research / citations

Audit performed 2026-05-19 via general-purpose agent (opus model). Primary sources:

- Claude Code hooks 2026 reference: https://thepromptshelf.dev/blog/claude-code-hooks-complete-reference-2026/
- Claude Code worktrees: https://code.claude.com/docs/en/worktrees
- Claude Code channels: https://georgetaskos.medium.com/claude-code-channels-the-async-agent-you-already-wanted-31eb5f95b143
- PermissionRequest hook: https://claude-blog.setec.rs/blog/permission-request-hook-automation
- `/cost` v2.1.92+: https://www.verdent.ai/guides/claude-code-pricing-2026
- Codex `/goal`: https://simonwillison.net/2026/Apr/30/codex-goals/
- `/goal` three components: https://apidog.com/blog/goal-command-codex-claude-code-autonomous-agents/
- Codex/Claude Code harness teardown: https://medium.com/jonathans-musings/inside-the-agent-harness-how-codex-and-claude-code-actually-work-63593e26c176
- Hermes SOUL.md: https://hermes-agent.nousresearch.com/docs/user-guide/features/personality
- Honcho integration: https://docs.honcho.dev/v3/guides/integrations/hermes
- Hermes cost accounting: https://kenhuangus.substack.com/p/chapter-1-cost-and-token-usage-accounting
- OpenSpec delta-spec: https://intent-driven.dev/knowledge/openspec/
- Spec-Kit constitution: https://github.com/github/spec-kit
- BMAD-METHOD: https://github.com/bmad-code-org/BMAD-METHOD
- SDD framework comparison 2026: https://dev.to/willtorber/spec-kit-vs-bmad-vs-openspec-choosing-an-sdd-framework-in-2026-d3j
- AGENTS.md standard: https://www.morphllm.com/agents-md-guide
- agentskills.io spec: https://agentskills.io/specification
- Goose recipes/sub-recipes: https://github.com/aaif-goose/goose/discussions/6973
- Harness comparison 2026: https://thoughts.jock.pl/p/ai-coding-harness-agents-2026
- Eval harness comparison: https://atlan.com/know/how-to-test-ai-agent-harness/
