# 171 - context-injection-reformulation - notes

_Created 2026-06-08._

_In-flight design memory for this spec - decisions, deviations, tradeoffs, and open questions surfaced while building that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD - <author> - <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

## Design decisions

### 2026-06-08 - parent - Remove spec 170 before commit

Spec 170 (`context-injection-qualification`) was abandoned before commit after the prompt-time `UserPromptSubmit` hook was removed from `.codex/hooks.json` and `.claude/settings.json`. Its rule/test artifacts were removed instead of being committed as a superseded historical suite, because they qualified the old hook model and would add noise while spec 171 owns the replacement design.

### 2026-06-08 - parent - Admit event-scoped reformulation

The change is admitted as a context/replication substrate spec because the observed failure was not lack of a static rule. The missing context appeared after a tool result, so a prompt-only hydrator cannot be the complete mechanism. V1 remains bounded and advisory because runtime hook coverage differs and Codex does not intercept every web/tool surface.

### 2026-06-08 - parent - Accept Claude critique on coverage labels

Claude reviewed the draft through `claude-exec` run `20260608T150344Z-context-injection-reformulation-claude` and identified the key hole: a Bash/curl `PostToolUse` fixture would not prove coverage for the motivating `WebFetch`/non-shell failure path. The spec now requires explicit `(runtime, tool)` labels of `covered`, `uncovered`, or `rule-only`, and forbids claiming the silent-substitution class is closed while the incident path is uncovered.

### 2026-06-08 - parent - V1 extends the existing hydrator

Accepted Claude's implementation-shape recommendation for v1: extend `context-inject.sh` instead of creating a separate `context-route.sh`. The existing script already owns event detection, selection caps, retrieval exclusion, and Claude/Codex output transport. A new script remains possible only if implementation shows real complexity that the current structure cannot absorb cleanly.

## Deviations

_None yet._

## Tradeoffs

### 2026-06-08 - parent - Prefer event routing over more prompt keywords

More `UserPromptSubmit` keywords would be cheap, but they do not address `401`/`402`/`403`, login redirects, no-JS stubs, or other evidence discovered after the first model call. Event routing has more moving parts, but it matches the actual failure timing.

### 2026-06-08 - parent - Prompt URL routing is still the first fix

Claude's strongest counterpoint was that the incident prompt itself likely carried enough signal: a URL/article/X request should have selected browser rules before the first fetch. The plan now treats prompt-time URL/article/gated-host routing as the first slice, with post-tool auth-wall routing as a second, hook-coverage-limited lane.

## Open questions

### 2026-06-08 - parent - Live web-fetch observability

Open question: can any Claude/Codex web-fetch path beyond Bash/MCP be observed by lifecycle hooks in live interactive sessions? Official Codex docs say non-shell/non-MCP interception is incomplete. Until proven otherwise, those paths must be labelled `rule-only`, not fixture-covered.

### 2026-06-08 - parent - Subagent lane split

The user asked about subagents, but the concrete incident is browser/article context and Codex does not expose dispatch brief text at `SubagentStart`. The current plan documents subagent limits and parent-brief discipline; a separate subagent-context spec may be cleaner if implementation scope starts drifting.
