---
name: codex-cli-hooks
description: Codex CLI lifecycle hook surface (10 events) and the payload-shape / tool-name compatibility profile vs Claude Code — read before designing any cross-runtime hook capacity
metadata:
  type: reference
  created_at: '2026-05-27T15:35:00-03:00'
  last_accessed: '2026-05-27'
  confirmed_count: 0
---

# Codex CLI hooks

Codex CLI ships a lifecycle-hook system covering 10 events: `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`, `SessionStart`, `SubagentStart`, `SubagentStop`, `UserPromptSubmit`, `Stop`. Configurable in `.codex/config.toml` under `[hooks]` or `.codex/hooks.json` (project or user scope), with plugin-bundled hooks via `hooks/hooks.json`. Disabled globally via `[features] hooks = false`.

Canonical source: <https://developers.openai.com/codex/hooks> (verified 2026-05-27 against `/hooks` command output in a real Codex CLI session — events column matched docs verbatim).

## Why this memory exists

`.claude/rules/runtime-capabilities.md` matrix row `lifecycle hooks` carried `Codex CLI = unsupported` until 2026-05-27. That cell was correct at Codex CLI's open-source moment (April 2025) but drifted as OpenAI shipped the hook surface (issue `openai/codex#14882` is the proposal trail). The drift went uncaught because the quarterly competitive-harness audit (`r-2026-05-19-re-rodar-auditoria`) treats matrix maintenance as a separate workflow from spec design — a spec design conversation will trust the matrix without re-verifying against upstream docs.

**The meta-lesson:** for any cross-runtime decision in a spec or plan, verify runtime capabilities via the runtime's official docs BEFORE deriving design assumptions, even when the project matrix asserts the answer. The matrix is a snapshot; the docs are the truth. See [[verify-runtime-capabilities]] (user-level feedback) for the behavioral discipline.

## Payload-shape compatibility with Claude Code

Stdin JSON payload Codex passes to hook scripts is nearly identical to Claude Code's:

| Field | Claude Code | Codex CLI |
| --- | --- | --- |
| `session_id` | ✓ | ✓ |
| `transcript_path` | ✓ | ✓ (nullable) |
| `cwd` | ✓ | ✓ |
| `hook_event_name` | ✓ | ✓ |
| `model` | ✓ | ✓ |
| `permission_mode` | ✓ | ✓ |
| `turn_id` | (n/a) | ✓ (turn-scoped events only) |
| `tool_name` | ✓ | ✓ |
| `tool_use_id` | ✓ | ✓ |
| `tool_input` | ✓ | ✓ |
| `tool_response` (PostToolUse) | ✓ | ✓ |
| `agent_id` / `agent_type` (Subagent events) | ✓ | ✓ |
| `source` (SessionStart) | ✓ | ✓ |

**Implication:** a well-written shell hook script can consume both runtimes' stdin payloads with no source-code changes, provided the script reads from documented fields only. Custom Claude-only fields (e.g., `PostToolUseFailure` divergent shape) need branching.

## Critical asymmetry: tool-name surface differs

The biggest blocker for a 1:1 hook port is the **tool-name catalog**:

- **Claude Code's edit surface:** `Edit`, `Write`, `MultiEdit` — each carries `tool_input.file_path` directly.
- **Codex CLI's edit surface:** `apply_patch` (carries the patch content; affected paths must be parsed from the diff) or `Bash` (path discovered by inspecting the command, or post-hoc via `git status --porcelain`).

A hook that matches on `Edit|Write|MultiEdit` in Claude's `.claude/settings.json` will not fire in Codex. The Codex equivalent registers on `apply_patch` (and possibly `Bash` for non-patch edits) and the script discovers affected paths by parsing `tool_input` patch text or running `git diff --name-only`.

Other tool-name differences: Claude `Glob` / `Grep` ≠ Codex's tool surface (Codex relies more on Bash for these); MCP tools follow `mcp__<server>__<tool>` naming on both runtimes — identical.

## Matcher syntax: identical

Both runtimes use regex on `tool_name` for matching: `Edit|Write|MultiEdit` (Claude), `apply_patch|Bash` (Codex). Catch-all is `"*"`, `""`, or omitted.

## Exit-code semantics: identical

| Exit | Behavior (both runtimes) |
| --- | --- |
| `0` (plain stdout) | Added as developer context |
| `0` (JSON stdout) | Interpreted per `hookSpecificOutput` shape |
| `2` (stderr) | Blocks the tool call; stderr text becomes reason |

Override grammars, advisory patterns (`<kind>-advisory:` stderr lines), and block-with-corrective-template patterns port cleanly.

## Config-file layout: 5-layer discovery, project precedence wins

Codex discovers hooks in precedence order:

1. `~/.codex/hooks.json` (user-level)
2. `~/.codex/config.toml` with `[hooks]` tables
3. `<repo>/.codex/hooks.json` (project-level)
4. `<repo>/.codex/config.toml` with `[hooks]` tables
5. Plugin bundles via manifest or `hooks/hooks.json`

For Agent0 port purposes, **project-level `.codex/config.toml [hooks]`** is the natural counterpart to Claude's project-level `.claude/settings.json` — both opt-in via a `*.example` template (precedent: spec 098 already established the `.codex/config.toml.example` pattern for MCP recipes).

Two user-side escape hatches the spec design must accommodate: `[features] hooks = false` disables hooks globally; `allow_managed_hooks_only = true` in `requirements.toml` bypasses per-hook trust review. Agent0 hooks must fail-open gracefully when either applies.

## Pointers

- `.claude/rules/runtime-capabilities.md` — matrix row `lifecycle hooks` updated 2026-05-27 to reflect this finding.
- `docs/specs/099-memory-multi-runtime/` — first spec that re-opened after the discovery; Round 3 critique invalidates the v1 "Codex convention-only" premise.
- `.codex/config.toml.example` — already-shipped template (spec 098); extend with `[hooks]` block when porting first-party Agent0 hooks.
- [[cc-platform-hooks]] — Claude Code's 29-event surface; the meta-lesson on validating event lists against canonical docs applies symmetrically.
- [[verify-runtime-capabilities]] (user-level feedback) — behavioral discipline that prevents this class of drift in future spec design.
