# 171 - context-injection-reformulation

_Created 2026-06-08._

**Status:** draft
**UI impact:** none

## Intent

Reform Agent0 context injection from a prompt-only keyword hydrator into a bounded, event-scoped context routing protocol. The immediate dogfood failure was a request to read an X article: the agent hit an auth-wall/no-JS/HTTP failure shape and silently substituted weaker sources instead of escalating to `agent-browser`. The first fix is not a broad router for its own sake; it is to make URL/article/gated-host prompts route browser context up front and to add an honest mid-session lane only where runtime hooks can actually observe tool results. `UserPromptSubmit` remains useful for initial intent routing, but it cannot see future tool failures or Codex subagent brief content. This spec defines the coverage matrix and the smallest v1 implementation that improves the real failure class without pretending unsupported runtime paths are covered.

## Acceptance criteria

- [ ] **Scenario: Prompt-only routing is not treated as sufficient**
  - **Given** the current `context-inject.sh` receives only a prompt at `UserPromptSubmit`
  - **When** the prompt asks to read an external article without mentioning browser/auth/login
  - **Then** the initial prompt route still selects browser read/auth guidance when the prompt contains a URL, `x.com`/`twitter.com`, or "read this article" style intent.

- [ ] **Scenario: Hookable tool-result auth wall triggers browser context**
  - **Given** a post-tool payload from a supported runtime/tool contains HTTP `401`, `402`, or `403`, an auth redirect/login page, or the X no-JS stub text
  - **When** the context router evaluates the tool result
  - **Then** it emits bounded model-visible context pointing to `browser-primitive.md` and `browser-auth.md`, including the instruction to attempt `agent-browser` or emit `BROWSER_LOGIN_REQUIRED: <host>` before substituting weaker sources.

- [ ] **Scenario: Motivating incident path is labelled by runtime/tool coverage**
  - **Given** the 2026-06-08 X-article failure path reached an HTTP `402`/auth-wall through a non-Bash web-fetch path
  - **When** v1 validation reports coverage for that incident class
  - **Then** each relevant `(runtime, tool)` path is labelled `covered`, `uncovered`, or `rule-only`, and no fixture-only PASS may claim the silent-substitution class is closed while the incident's own path remains uncovered.

- [ ] **Scenario: Unsupported mid-session events are called out**
  - **Given** Codex currently documents `PostToolUse` support for Bash, `apply_patch`, and MCP tool calls, with incomplete interception for WebSearch and other non-shell/non-MCP tools
  - **When** the v1 mechanism is planned
  - **Then** its guarantees distinguish hookable Bash/MCP output from non-hookable web/tool surfaces and avoid claiming universal mid-session coverage.

- [ ] **Scenario: Subagents receive task-relevant context without fake enforcement**
  - **Given** Claude has a blocking `PreToolUse(Agent)` discipline but Codex `SubagentStart` does not expose the dispatch brief text
  - **When** the design routes context for delegated work
  - **Then** it specifies the strongest portable mechanism: parent brief discipline plus start/stop observability, and separately names any Claude-only enforcement or Codex-only limitation.

- [ ] **Scenario: Context budget stays bounded**
  - **Given** multiple event lanes can inject context in a long session
  - **When** routing decisions fire on prompt, tool result, startup/resume, or subagent boundary
  - **Then** each lane has explicit byte/fragment limits, source pointers, and dedupe rules so context does not become a noisy always-on dump.

- [ ] **Scenario: Validation separates fixture, registration, and live evidence**
  - **Given** spec 170 established context-injection qualification language
  - **When** this reformulation adds or changes hook routing
  - **Then** tests and notes label each result as fixture evidence, hook registration evidence, or live interactive evidence, with no fixture-only PASS presented as live proof.

- [ ] A context-event matrix exists in repo docs/rules and covers `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `SubagentStart`, and `SubagentStop`.

- [ ] The X/article auth-wall failure class is represented by at least one deterministic fixture.

- [ ] Claude critique from 2026-06-08 is recorded in `notes.md` and either accepted, rejected, or deferred in the plan.

## Non-goals

- Building semantic/vector RAG, embeddings, a hosted context service, or a daemon.
- Injecting every rule into every prompt or subagent.
- Treating file frequency, telemetry volume, or recent edit counts as importance scoring.
- Claiming Codex can block or inspect subagent dispatch briefs until an official runtime surface exposes that data.
- Replacing `agent-browser` with WebFetch, browser MCP, or a generic web search fallback.
- Hard-blocking normal tool use in v1; the initial posture is bounded context/advisory unless a later spec proves the hardening bar.

## Open questions

- [ ] Can any Claude/Codex web-fetch path beyond Bash/MCP be hook-observed in the live TUI, or must those paths remain rule-only in v1?
- [ ] Should subagent context remain documentation/brief discipline in this spec, or be split to a follow-up spec after the browser/article slice is shipped?

## Context / references

- Local incident and rule: `.agent0/context/rules/browser-primitive.md` - auth-wall signal as tool result, X article 402/no-JS failure class, no silent weaker-source substitution.
- Local auth rule: `.agent0/context/rules/browser-auth.md` - `BROWSER_LOGIN_REQUIRED: <host>` and saved state reuse.
- Local current hydrator: `.agent0/hooks/context-inject.sh` - prompt-only keyword/path selection plus bounded retrieval.
- Local hook wiring: `.codex/hooks.json`, `.claude/settings.json`.
- Local delegation runtime distinction: `.agent0/context/rules/delegation.md`, `.agent0/context/rules/runtime-capabilities.md`.
- Prior qualification contract: `docs/specs/170-context-injection-qualification/`.
- OpenAI Codex hooks docs: https://developers.openai.com/codex/hooks
- OpenAI Codex subagents docs: https://developers.openai.com/codex/subagents
- Claude Code hooks docs: https://code.claude.com/docs/en/hooks
- Claude Code SDK hooks docs: https://code.claude.com/docs/en/agent-sdk/hooks
