# 129 — claude-exec

_Created 2026-05-30._

**Status:** shipped

## Intent

Create the symmetric counterpart to the shipped `codex-exec` skill (spec 128): a first-party `claude-exec` skill that lets a **non-Claude parent runtime — primarily Codex CLI — hand a bounded task to the local Claude Code CLI** via `claude -p` (headless/print mode), with structured parameter passing, captured output, and a repeatable audit trail. Where `codex-exec` lets Claude probe Codex, `claude-exec` closes the loop so Codex (or any agentskills-compatible runtime) can probe Claude. It is an orchestration bridge, not native shared-memory delegation: the parent supplies a bounded prompt, Claude runs as a separate non-interactive subprocess, and the parent reads the produced artifacts. Three confirmed consumers justify building now rather than deferring: (1) **bidirectional `/sdd debate`** cross-model review where Codex is the initiating agent and needs Claude's critique; (2) **Codex cron/headless runs** that want a Claude second-opinion with no human in the loop; (3) **platform parity** keeping the `codex-exec ↔ claude-exec` pair symmetric and discoverable.

**This skill is not a clone of `codex-exec`** — it shares the bridge posture (one command in, files out, gitignored audit trail) but owns Claude's distinct permission surface. The decision for v1 is **pass-through, fail-closed, no default**: the helper forwards Claude's **native** `--permission-mode` value verbatim (no invented abstraction layer) and the caller MUST pass it explicitly, or the helper refuses before invoking Claude. The rationale is twofold: (1) Claude's safety axis is *permission-mode + tool allowlist*, more consequential than a filesystem sandbox, so the wrapper makes no silent assumption about what Claude may do; (2) pass-through keeps the helper thin and free of a mapping table that would drift as Claude's mode set evolves. Because there is no native mode that means "read-only review" by itself, the helper additionally **exposes `--allowedTools` / `--disallowedTools` as opt-in flags** so a caller composes read-only review explicitly (e.g. `--permission-mode default --allowedTools "Read Grep Glob"`). To make "read-only is the floor" a real invariant rather than caller discipline, the helper layers one safety gate on top of the pass-through: **write/execute-capable modes (`acceptEdits`, `bypassPermissions`, `dontAsk`, `auto`) are refused unless the caller also passes `--allow-writes`**; `default`/`plan` are the floor and need no confirmation. The gate is orthogonal to pass-through — the native mode value is still forwarded verbatim. Captured output lives under gitignored runtime state, mirroring `codex-exec`.

The shape follows the existing Agent0 multi-runtime skill model (spec 121): canonical source in `.agent0/skills/claude-exec/`, a Codex discovery symlink in `.agents/skills/claude-exec` (the **primary** discovery path here, since the parent is Codex), a Claude discovery symlink in `.claude/skills/claude-exec`, and deterministic shell logic in a bundled helper script. The helper invokes the local `claude` CLI in `-p` mode and writes artifacts under `.agent0/.runtime-state/claude-exec/` by default.

## Acceptance criteria

- [x] **Scenario: Codex delegates a bounded read-only Claude probe**
  - **Given** the `claude-exec` skill is available through `.agents/skills/claude-exec`
  - **When** a parent runtime invokes the helper with a task prompt, an explicit native `--permission-mode default`, and a read-only tool allowlist (`--allowedTools "Read Grep Glob"`)
  - **Then** the helper runs `claude -p` non-interactively, passes the task through stdin (or `--task`), captures Claude's final message to `last-message.md`, and reports the output path plus exit status back to the parent

- [x] **Scenario: missing permission mode is refused fail-closed**
  - **Given** a caller invokes the helper without specifying the permission/safety mode
  - **When** the helper parses arguments
  - **Then** it exits non-zero with a concise usage error naming the required values, BEFORE invoking Claude, and creates no success-looking output directory

- [x] **Scenario: structured parameters map to stable Claude CLI flags**
  - **Given** a caller supplies supported parameters such as the native `--permission-mode` (required), `--allowedTools`/`--disallowedTools`, `--model`, `--json`, `--resume`/`--session-id`, `--output`, `--add-dir`, or the opt-in `--bare`
  - **When** the helper builds the Claude invocation
  - **Then** it uses argv arrays rather than shell string interpolation, forwards each parameter to the matching native `claude` flag (pass-through — no remapping of permission values), and rejects unknown parameters with a concise usage error

- [x] **Scenario: JSON capture writes a JSONL artifact**
  - **Given** the caller passes `--json`
  - **When** the helper runs Claude with `--output-format stream-json`
  - **Then** it captures the streamed JSONL to `events.jsonl`, extracts the final `result` event to `last-message.md` (Claude has no native `--output-last-message`, so the helper parses the JSON via `jq`), records the returned `session_id` in metadata, and reports both paths

- [x] **Scenario: resume preserves an existing Claude session**
  - **Given** the caller provides a Claude session id through `--resume <session-id>`
  - **When** the helper invokes Claude
  - **Then** it calls `claude -p --resume <session-id>`, passes the new task, preserves the selected permission/model behavior, and records the resumed session id in run metadata

- [x] **Scenario: write-capable Claude runs require explicit caller intent (floor gate)**
  - **Given** a caller selects a write/execute-capable permission mode (`acceptEdits`, `bypassPermissions`, `dontAsk`, or `auto`)
  - **When** they invoke the skill without `--allow-writes`
  - **Then** the helper refuses fail-closed before invoking Claude, with an error naming the mode as write-capable; only with an explicit `--allow-writes` does the run proceed. `default` and `plan` are the read-only floor and run without confirmation. This makes "read-only is the floor" an **invariant of the bridge**, not caller discipline — closing the spec-129 dogfood finding (Codex, 2026-05-31).

- [x] **Scenario: outputs are auditable and gitignored**
  - **Given** any `claude-exec` run completes or fails
  - **When** the helper exits
  - **Then** it writes the last Claude message to `.agent0/.runtime-state/claude-exec/<timestamp>-<slug>/last-message.md`, optionally writes `events.jsonl` when `--json` is requested, writes a per-run `metadata.json` (timestamp, slug, permission mode, model if provided, resume id if provided, the `session_id` Claude returned, exit code, output paths), and appends one line to an aggregate `runs.jsonl`

- [x] **Scenario: `--output` cannot escape the state dir**
  - **Given** a caller passes `--output <path>`
  - **When** the helper resolves the path
  - **Then** it normalizes via `realpath -m` and refuses any path whose parent is not under the runtime-state dir — mirroring the hardened `codex-exec` guard (the gap closed during spec 128 dogfood) rather than re-introducing it

- [x] **Scenario: missing dependency fails cleanly**
  - **Given** `claude` is not on `PATH`, or `jq` (required to extract the final message from Claude's JSON output) is missing
  - **When** the helper is invoked
  - **Then** it exits non-zero before running any task, prints an actionable setup error naming the missing binary, and does not create a success-looking output directory

- [x] **Scenario: skill validation and discovery pass**
  - **Given** the skill is implemented
  - **When** the maintainer runs the Agent0 skill and multi-runtime checks
  - **Then** `SKILL.md` passes `/skill validate claude-exec`, the `.agents/skills` and `.claude/skills` symlinks resolve to the one canonical `.agent0/skills/claude-exec` source, and new tests under `.agent0/tests/claude-exec-skill/` pass

- [x] `.agent0/skills/claude-exec/SKILL.md` exists, uses agentskills.io frontmatter, and documents the bridge as a subprocess orchestration tool rather than a native shared-memory delegation primitive.

- [x] `.agent0/skills/claude-exec/scripts/claude-exec.sh` exists, is executable, uses `set -euo pipefail`, builds the Claude command with argv arrays (never `eval`), and surfaces Claude's non-zero exit and stderr rather than masking them.

- [x] `.agent0/skills/claude-exec/agents/openai.yaml` exists so Codex can discover the skill, with `policy.allow_implicit_invocation: true` (safe because a vague implicit trigger lacking `--permission-mode` is refused before any paid Claude run).

- [x] `.gitignore` already covers `.agent0/.runtime-state/*`, so `claude-exec` run outputs do not enter normal git status.

## Non-goals

- Native subagent integration. The skill does not make Claude a native Codex subagent; it only launches `claude -p` as a local subprocess.
- A long-lived broker, daemon, queue, or RPC server. v1 is one command in, files out — identical posture to `codex-exec`.
- Replacing `/sdd debate`. Debate artifacts stay file-based and human-orchestrated; `claude-exec` may help a Codex-side port invoke Claude, but it does not own the debate protocol.
- Bypassing permissions by default. The helper must never pass `--dangerously-skip-permissions` / `--permission-mode bypassPermissions` unless the caller explicitly and intentionally selects a write/danger mode.
- Shipping provider credentials. The helper reuses the local Claude install and its existing auth (OAuth/subscription or `ANTHROPIC_API_KEY`); no keys are copied into Agent0.
- Proving interactive Claude TUI/hook lifecycle behavior. `claude -p` is non-interactive; like `codex exec` for spec 128, it is not a faithful proof surface for interactive lifecycle hooks.
- Recursion as a feature. The skill is not intended for Claude-invokes-claude-exec-invokes-Claude loops; if the parent is itself Claude, `codex-exec` or a direct Agent call is the right tool.

## Open questions

_All resolved 2026-05-30 (user). Recorded here with rationale; carried into `plan.md`._

- [x] **Permission surface — RESOLVED: native pass-through, fail-closed, no default.** `claude-exec` is **not** a clone of `codex-exec`; it owns Claude's own permission axis. The helper requires `--permission-mode` and forwards the **native** value verbatim (`default | plan | acceptEdits | bypassPermissions | dontAsk | auto`) — no invented `read-only/write/danger` abstraction layer. Read-only review is composed explicitly by the caller via the opt-in `--allowedTools`/`--disallowedTools` flags (e.g. `--permission-mode default --allowedTools "Read Grep Glob"`). Rationale: keeps the helper thin and avoids a mapping table that drifts as Claude's mode set changes.
- [x] **Launcher — RESOLVED: no dedicated launcher.** Invoke `claude` directly from the helper. `claude` already discovers its own config (`~/.claude`, `.claude/settings.json`) and anchors on cwd, so a `claude-local-env.sh` analog would be ceremony (YAGNI). Add one later only if a `.claude/.env.local` load becomes necessary.
- [x] **`--bare` — RESOLVED: not default; opt-in flag.** Default runs full-context (`CLAUDE.md`, rules) because the primary consumer is spec review, which needs project context; default non-bare is also more robust for auth (OAuth/subscription keep working, whereas `--bare` forces strictly `ANTHROPIC_API_KEY`). `--bare` is exposed as an opt-in flag for callers who want a cheap, isolated probe. General principle: required flags (`--permission-mode`) plus opt-in flags (`--bare`, `--json`, allowlists, `--add-dir`, `--model`); no magic defaults.
- [x] **`allow_implicit_invocation` — RESOLVED: `true`.** A vague implicit trigger that omits the required `--permission-mode` is refused before any paid Claude run (fail-closed), so easy discoverability carries no cost-runaway risk. Matches `codex-exec`'s discoverability posture.
- [x] **Final-message extraction — RESOLVED: parse JSON via `jq`, capture `session_id`.** Without `--json`: `--output-format json` → extract `.result` → `last-message.md`, `.session_id` → `metadata.json`. With `--json`: `--output-format stream-json --verbose` → `events.jsonl`, extract the final `result` event → `last-message.md`. Claude lacks a native `--output-last-message`, so `jq` is a hard dependency the helper must check for (fail clean if absent). Capturing `session_id` is what enables the `--resume` consumer (bidirectional debate / continuation).

## Context / references

- `docs/specs/128-codex-exec-skill/` — the symmetric sibling; this spec deliberately mirrors its acceptance shape, audit-trail contract, and the `--output` containment guard hardened during its dogfood (2026-05-30).
- `.agent0/skills/codex-exec/scripts/codex-exec.sh` — reference implementation to port: argv arrays, `set -euo pipefail`, `die()` usage errors, slug/timestamp run dirs, `metadata.json` + `runs.jsonl`, the `realpath -m` `--output` state-dir guard (lines ~252–262).
- `.agent0/skills/codex-exec/agents/openai.yaml` — policy-block shape to mirror for Codex discovery.
- `docs/specs/121-multi-runtime-skills/` — canonical multi-runtime skill model: one source in `.agent0/skills/<slug>/` with `.claude/skills` and `.agents/skills` discovery symlinks.
- `.agent0/context/rules/runtime-capabilities.md` — provider-neutral capability matrix; consult before asserting a native flag exists.
- `claude --help` (verified 2026-05-30): confirmed headless surface — `-p/--print`, `--output-format text|json|stream-json`, `--permission-mode default|plan|acceptEdits|bypassPermissions|dontAsk|auto`, `--model`, `--resume`/`--session-id`/`--continue`, `--add-dir`, `--allowedTools`/`--disallowedTools`, `--mcp-config`, `--bare`, `--dangerously-skip-permissions`.
- Prior dogfood (this session): `codex-exec` ran read-only probe clean (exit 0, sandbox read-only, substantive Codex answer) and correctly refused an out-of-state-dir `--output` — the negative test that validates the guard this spec inherits.
