---
name: codex-cli-hooks
description: Codex CLI lifecycle hook surface (10 events) and the payload-shape / tool-name compatibility profile vs Claude Code — read before designing any cross-runtime hook capacity
metadata:
  type: reference
  created_at: '2026-05-27T15:35:00-03:00'
  last_accessed: '2026-05-29'
  confirmed_count: 1
---

# Codex CLI hooks

Codex CLI ships a lifecycle-hook system covering 10 events: `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`, `SessionStart`, `SubagentStart`, `SubagentStop`, `UserPromptSubmit`, `Stop`. Configurable in `.codex/config.toml` under `[hooks]` or `.codex/hooks.json` (project or user scope), with plugin-bundled hooks via `hooks/hooks.json`. Disabled globally via `[features] hooks = false`.

Canonical source: <https://developers.openai.com/codex/hooks> (verified 2026-05-27 against `/hooks` command output in a real Codex CLI session — events column matched docs verbatim; re-audited 2026-06-09 via runtime-platform-audit — 10-event list unchanged, the one drift was matcher aliasing: see § tool-name surface).

## Why this memory exists

`.agent0/context/rules/runtime-capabilities.md` matrix row `lifecycle hooks` carried `Codex CLI = unsupported` until 2026-05-27. That cell was correct at Codex CLI's open-source moment (April 2025) but drifted as OpenAI shipped the hook surface (issue `openai/codex#14882` is the proposal trail). The drift went uncaught because the quarterly competitive-harness audit (`r-2026-05-19-re-rodar-auditoria`) treats matrix maintenance as a separate workflow from spec design — a spec design conversation will trust the matrix without re-verifying against upstream docs.

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

**Matcher aliasing (updated 2026-06-09, doc-stated):** Codex now lets an `Edit` or `Write` *matcher* fire on `apply_patch` edits. Docs verbatim: *"For file edits through `apply_patch`, `matcher` values can use `apply_patch`, `Edit`, or `Write`; hook input still reports `tool_name: "apply_patch"`."* So at the **registration** layer, a matcher `Edit|Write` (no longer `MultiEdit` — not a documented alias) DOES match on Codex, improving cross-runtime matcher portability. **But the payload `tool_name` stays `apply_patch`** — so a hook *script* that branches on `tool_name == "Edit"`/`"Write"` still won't match, and affected paths still aren't in a `tool_input.file_path` field; the script discovers them by parsing the `apply_patch` patch text or running `git diff --name-only`. (Earlier snapshot, verified 2026-05-27 against a live `/hooks` session, said an `Edit|Write|MultiEdit` matcher "will not fire in Codex" — that was correct then; the matcher-alias support is the drift. This correction is **doc-stated**. An empirical confirmation was attempted 2026-06-09 via `codex exec` (disposable repo, matcher `^Edit$` + control `^apply_patch$`, `--dangerously-bypass-hook-trust`, both project- and user-scope `hooks.json`) but was **inconclusive**: `apply_patch` demonstrably ran yet NO hook fired — not the `^apply_patch$` control, nor a `SessionStart` probe. So **lifecycle hooks did not observably fire under `codex exec` (non-interactive)** in this test, whether the cause is an exec-mode limitation, a project-trust/config-load nuance, or hook scoping. **Operational takeaway:** do not expect to validate Codex hook behavior headlessly via `codex exec`; definitive verification of the matcher-alias claim needs an **interactive** Codex `/hooks` session.)

Other tool-name differences: Claude `Glob` / `Grep` ≠ Codex's tool surface (Codex relies more on Bash for these); MCP tools follow `mcp__<server>__<tool>` naming on both runtimes — identical.

## Subagent dispatch surface (verified 2026-05-28 against official docs)

Codex **does** have subagents — the `runtime-capabilities.md` matrix cell `delegation/subagents | Codex = unsupported` is **stale** (same drift class as the spec 099 lifecycle-hooks cell). Verified facts:

- **Dispatch exists, but is conversational, not a tool.** Codex spawns subagents only on explicit request ("spawn two agents", "delegate this in parallel", `/agent`). There is **no `Agent` tool** with a structured `tool_input.prompt` — so there is nothing field-shaped to validate at dispatch time the way Claude's `delegation-gate.sh` validates the 5-field handoff against `tool_input.prompt`. Subagents carry `agent_id`/`agent_type`, not a tool-name. `agents.max_depth` defaults to `1` (a child can spawn, deeper nesting blocked).
- **`SubagentStart` CANNOT block.** This is the load-bearing asymmetry for any delegation-gate port. Docs verbatim: *"continue: false is parsed for compatibility, but it doesn't stop the subagent from starting."* Exit 2 / `continue:false` are accepted syntactically but do **not** prevent launch. Claude's `PreToolUse(Agent)` blocks (exit 2 → re-prompt); Codex has no pre-dispatch blocking equivalent. A "gate" on Codex can only be a non-blocking advisory or convention-only discipline.
- **`SubagentStop` is symmetric and portable.** Fires on both runtimes with near-identical payloads (`agent_id`/`agent_type`). Pure observation/audit — no blocking semantics needed — so a close-row audit hook ports cleanly. The Claude-specific part is only the dispatch↔stop bridge (`tool_use_id` ↔ sidecar `.meta.json`); Codex correlates via `agent_id` directly.

Canonical sources: <https://developers.openai.com/codex/subagents> + <https://developers.openai.com/codex/hooks>. This finding drives spec 106 (delegation-hooks-multi-runtime).

## No per-edit actor attribution → delegated verification must live at SubagentStop (verified 2026-05-29, spec 110)

The payload table above lists `agent_id`/`agent_type` under **Subagent events only** — spec 110 made the design consequence explicit and load-bearing. Docs verbatim: `PostToolUse(apply_patch)` input is `turn_id` / `tool_name` / `tool_use_id` / `tool_input` / `tool_response` (+ the common session/cwd/model/permission fields). There is **no parent-vs-subagent discriminator on `PostToolUse(apply_patch)`** — `agent_id`/`agent_type` appear only on `SubagentStart`/`SubagentStop`.

**Consequence for any per-edit hook that needs to know "was this a delegated sub-agent edit?":** it cannot be ported to Codex. Claude's `post-edit-validate.sh` gates on `agent_id` presence in the `PostToolUse(Edit)` payload ("present → delegated; absent → parent, exempt"); Codex `PostToolUse(apply_patch)` has no equivalent, so a faithful per-edit port is non-viable. The two escape hatches are both rejected: validating *all* Codex edits silently deletes the parent-edit exemption (and verifies ordinary parent iteration); transcript/session heuristics violate the docs-not-training-data discipline and create a brittle hidden contract.

**The portable boundary for delegated verification is therefore `SubagentStop`** (carries `agent_id`/`agent_type`; supports `decision:"block"`/exit-2 to continue the subagent flow). This is exactly the spec 106 finding (`SubagentStop` is symmetric/portable) applied to the *validation* use case rather than the *audit* use case. Spec 110 resolved it as: delete the per-edit hook entirely, run the validator once at `SubagentStop` via a new `delegation-verify.sh` (impl tracked in spec 111).

Two facts still UNVERIFIED (flagged for spec 111 live dogfood, not assumed): (a) does a continued sub-agent preserve its `agent_id` across a validation-blocked stop (the Agent0 continuation counter is keyed on it)? (b) how does `stop_hook_active` behave across a blocked stop? Both gate the budget/continuation design.

## Matcher syntax: identical

Both runtimes use regex on `tool_name` for matching: `Edit|Write|MultiEdit` (Claude), `apply_patch|Bash` (Codex). Catch-all is `"*"`, `""`, or omitted.

## Exit-code semantics (mostly identical; PostToolUse needs JSON stdout on Codex)

| Exit | Behavior |
| --- | --- |
| `0` (plain stdout) | **Codex PostToolUse:** ignored. **Codex UserPromptSubmit:** added as developer context. Do not generalize plain stdout behavior across events. |
| `0` (JSON stdout) | For Codex `PostToolUse`, `hookSpecificOutput.additionalContext` is added as developer context. Live-proven 2026-05-29 by spec 113 after switching from plain stdout to JSON stdout. |
| `0` (stderr) | **Claude:** surfaced to the agent's next-turn context. **Codex:** NOT surfaced — exit-0 stderr is dropped. (Empirically verified 2026-05-29, spec 113 live dogfood.) |
| `2` (stderr) | Blocks the tool call; stderr text becomes reason (both runtimes) |

Override grammars and block-with-corrective-template patterns (exit 2) port cleanly. **Advisory patterns (`<kind>-advisory:` exit-0 lines) do NOT port cleanly via stderr or plain stdout on Codex PostToolUse.** A hook that writes its advisory to stderr and exits 0 is visible to the agent on Claude but invisible on Codex; a hook that writes plain stdout is also ignored by Codex PostToolUse. The portable pattern for non-blocking edit advisories is: Claude path writes advisory lines to stderr; Codex `PostToolUse` path accumulates advisory lines and emits one JSON object on stdout:

```json
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"propagation-advisory: ...\n"}}
```

Spec 113 live dogfood proved this end-to-end: a real Codex `apply_patch` creating `.agent0/context/rules/_dogfood-113d.md` surfaced `propagation-advisory: spec-NNN in .agent0/context/rules/_dogfood-113d.md:1 — this refs spec 080` as developer context.

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

- `.agent0/context/rules/runtime-capabilities.md` — matrix row `lifecycle hooks` updated 2026-05-27 to reflect this finding.
- `docs/specs/099-memory-multi-runtime/` — first spec that re-opened after the discovery; Round 3 critique invalidates the v1 "Codex convention-only" premise.
- `.codex/config.toml.example` — already-shipped template (spec 098); extend with `[hooks]` block when porting first-party Agent0 hooks.
- [[cc-platform-hooks]] — Claude Code's 29-event surface; the meta-lesson on validating event lists against canonical docs applies symmetrically.
- [[verify-runtime-capabilities]] (user-level feedback) — behavioral discipline that prevents this class of drift in future spec design.
- `docs/specs/110-post-edit-validate-multi-runtime/` — decision spec where the "no per-edit actor on Codex" consequence was nailed (Claude↔Codex debate); `docs/specs/111-delegation-verify-subagent-stop/` — the `SubagentStop` verifier implementation that replaces `post-edit-validate.sh`.
