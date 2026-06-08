# 171 - context-injection-reformulation - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Design a small event router rather than making `UserPromptSubmit` smarter by unbounded keyword accretion. The router should preserve the existing deterministic prompt floor and retrieval lane, then add event-specific selectors only where the runtime exposes useful evidence. The first v1 slice is deliberately narrow: prompt-time URL/article/gated-host routing plus hookable post-tool auth-wall routing.

V1 should be advisory/context-only and fail-open. The immediate slice is the browser auth-wall class because it has a real dogfood incident, a clear rule target, and deterministic text/status signatures. Subagent context stays in the coverage matrix and parent-brief discipline for this spec unless live evidence shows a portable start-time context surface; otherwise it should become a follow-up spec.

## Admission brief

- **Layer:** context/replication substrate, with runtime-parity as a transversal constraint.
- **Boundary:** Agent0 owns harness context routing and instruments delegated/browser workflows; it does not own consumer web content retrieval or account authentication.
- **Evidence:** explicit founder directive plus dogfood failure on 2026-06-08 where an X article auth-wall/tool-result signal did not cause `agent-browser` escalation.
- **V1 posture:** prompt-routing improvement plus bounded context/advisory injection, not a hard gate.
- **Blast radius:** Agent0 hook/rule/test surface, sync-propagated to consumers once committed.
- **Validation:** fixture tests for prompt and tool-result routing, hook registration checks, and optional live interactive readback per spec 170.
- **Non-goals:** no semantic RAG, no daemon, no universal WebSearch interception claim, no hard block.

## Event matrix

| Event | Current Agent0 behavior | V1 target | Key limitation |
| --- | --- | --- | --- |
| `SessionStart` | `startup-brief.sh` emits handoff/state; `context-inject.sh` emits pointer outside prompt events | Keep startup focused on working state and context inventory pointer | Should not dump rule corpus every resume |
| `UserPromptSubmit` | Keyword/path/retrieval over prompt text only | Add URL/article/gated-host selectors that route `browser-primitive` and `browser-auth` before the first fetch | Cannot see future tool outputs |
| `PostToolUse` | Used for edit tracking and memory projection only | Add auth-wall browser context for hook-observable Bash/MCP outputs | Codex docs say WebSearch/non-shell/non-MCP interception is incomplete |
| `SubagentStart` | Codex start audit only; no brief observability | Document runtime limits and parent-brief discipline; no broad v1 implementation unless payload supports it | Codex start payload does not expose brief text |
| `SubagentStop` | Delegation verification/close audit | Verify delegated outputs and surface context drift, not initial task context | Too late to fix missing start context except by continuation |

## Files to touch

**Create:**
- `.agent0/context/rules/context-injection-reformulation.md` - event-scoped routing contract, coverage matrix, and guarantees.
- `.agent0/tests/context-routing/` - fixtures for URL/article prompt routing, hookable auth-wall post-tool routing, uncovered incident-path labelling, and unsupported-event behavior.

**Modify:**
- `.agent0/hooks/context-inject.sh` - extend the existing event branch and transport logic rather than creating a second router unless implementation proves separation is cleaner.
- `.codex/hooks.json` - register `PostToolUse` routing for supported hook-observable tool names only if needed after the script branch exists.
- `.claude/settings.json` - register equivalent `PostToolUse` routing for supported hook-observable tool names only.
- `.agent0/context/rules/browser-primitive.md` - cross-reference the new routing rule rather than expanding browser logic further.
- `.agent0/context/rules/delegation.md` - clarify subagent context injection/brief discipline if needed.
- `.agent0/context/rules/runtime-capabilities.md` - update matrix with event-scoped context guarantees/limitations.
- `.agent0/HANDOFF.md` - record active spec and validation state while uncommitted.

**Delete:**
- None planned.

## Alternatives considered

### Add only more auth/login prompt keywords

Rejected because it repeats the old failure mode: prompts that say "browser", "auth", or "login" up front improve, while URL/article prompts and later `402`, login redirects, and no-JS stubs still miss. The accepted prompt-time slice is not generic keyword accretion; it is a structured URL/article/gated-host selector plus explicit post-tool coverage limits.

### Ignore prompt-time URL/article routing and build only `PostToolUse`

Rejected because it would not cover the motivating path if the agent uses a non-hookable web-fetch surface. URL/article/gated-host routing is cheap, deterministic, and works before the first fetch on both runtimes, so it is the first slice.

### Create a new `context-route.sh`

Deferred/rejected for v1. `context-inject.sh` already owns event detection, prompt sanitation, source selection, byte/fragment caps, and Claude-vs-Codex output transport. A second script would duplicate that machinery unless implementation exposes real complexity that warrants separation.

### Inject all browser/delegation rules on every prompt

Rejected because it trades misses for context pollution. Codex subagent docs explicitly frame subagents as a way to reduce context pollution/rot, and Agent0 already uses bounded capsules. Always-on injection would make long sessions noisier without proving the model attends to the right rule at the right moment.

### Hard-block when an auth wall appears

Rejected for v1 because runtime coverage is incomplete and the hook surfaces differ. The correct first step is model-visible context with deterministic fixtures; hard gates need the scope-admission hardening bar.

### Build semantic RAG

Rejected because the problem is event selection, not retrieval quality. Agent0 v1 context retrieval intentionally uses deterministic pointers; adding embeddings or a hosted index would expand scope without addressing tool-result timing.

## Risks and unknowns

- Codex hook docs state `PostToolUse` does not intercept all WebSearch/non-shell/non-MCP tool calls; we must not overstate live coverage.
- Claude and Codex have different hook output semantics. Plain stdout works for prompt/session context in both, but structured JSON is safer for event-specific context.
- Subagent context can easily become duplicated between parent briefs, custom agent developer instructions, and hook output.
- Auth-wall detection can false-positive on docs that mention `401`/`403` examples unless the router parses actual tool output/status fields narrowly.
- Existing spec 170 dirty state is uncommitted; implementation should avoid mixing unrelated changes until the user decides commit scope.
- The motivating incident path may remain `rule-only` if no official hook can observe the web-fetch tool output; the test/report must say that plainly.

## Research / citations

- OpenAI Codex hooks docs: `PostToolUse` supports Bash, `apply_patch`, and MCP tool calls, carries `tool_response`, can return `additionalContext`, and does not fully intercept WebSearch/non-shell/non-MCP tools. https://developers.openai.com/codex/hooks
- OpenAI Codex hooks docs: `UserPromptSubmit` receives the prompt and adds stdout/`additionalContext` as developer context, but matcher is ignored. https://developers.openai.com/codex/hooks
- OpenAI Codex subagents docs: subagents are explicit, inherit sandbox policy, and custom agents use `developer_instructions`; they should be narrow and opinionated. https://developers.openai.com/codex/subagents
- Claude Code hooks docs: `additionalContext` placement differs by event; `PostToolUse` context appears next to the tool result and `UserPromptSubmit` context appears alongside the submitted prompt. https://code.claude.com/docs/en/hooks
- Claude Code SDK hooks docs: callbacks receive event-specific input, and `PostToolUse` can append `additionalContext` to the tool result. https://code.claude.com/docs/en/agent-sdk/hooks
