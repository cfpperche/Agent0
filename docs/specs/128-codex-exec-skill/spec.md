# 128 — codex-exec-skill

_Created 2026-05-30._

**Status:** shipped

## Intent

Create a first-party `codex-exec` skill that lets Claude Code hand a bounded task to the local Codex CLI via `codex exec`, with structured parameter passing, captured output, and a repeatable audit trail. The skill is intentionally an orchestration bridge, not a replacement for native subagents: Claude remains the parent runtime, Codex runs as a separate non-interactive process, and the output contract is a file + summary that Claude can read back into the current workflow.

The user decision for v1 is that Codex-side metadata defaults to `policy.allow_implicit_invocation: true`. That makes the skill easier to discover and reuse from Codex-compatible skill UIs, but it raises the cost of vague triggers. The implementation must therefore keep the skill description precise and make the wrapper defaults conservative: no approval/sandbox bypass by default, `--sandbox read-only` unless the caller explicitly asks for a different sandbox, and captured output under gitignored runtime state.

The shape should follow the existing Agent0 multi-runtime skill model: canonical source in `.agent0/skills/codex-exec/`, Claude discovery symlink in `.claude/skills/codex-exec`, Codex discovery symlink in `.agents/skills/codex-exec`, and deterministic shell logic in a bundled helper script. The helper must call the existing repo-local launcher `.agent0/tools/codex-local-env.sh` so local Codex config, MCP env, and repo root handling stay centralized.

## Acceptance criteria

- [x] **Scenario: Claude delegates a read-only Codex probe**
  - **Given** the `codex-exec` skill is available through `.claude/skills/codex-exec`
  - **When** Claude invokes it with a task prompt and no explicit sandbox parameter
  - **Then** the helper runs `bash .agent0/tools/codex-local-env.sh --sandbox read-only exec -`, passes the task through stdin, captures Codex's final message, and reports the output path plus exit status back to Claude

- [x] **Scenario: structured parameters map to stable Codex CLI flags**
  - **Given** a caller supplies supported parameters such as `--model`, `--sandbox`, `--profile`, `--json`, `--resume`, `--output`, or `--cwd`
  - **When** the helper builds the Codex invocation
  - **Then** it uses argv arrays rather than shell string interpolation, places top-level Codex flags before `exec` when required by the launcher, places `exec` subcommand flags after `exec`, and rejects unknown parameters with a concise usage error

- [x] **Scenario: resume preserves an existing Codex session**
  - **Given** the caller provides a Codex session id through `--resume <session_id>`
  - **When** the helper invokes Codex
  - **Then** it calls `codex exec resume <session_id> -` through the repo-local launcher, passes the new task through stdin, preserves the selected sandbox/profile/model behavior, and records the resumed session id in the run metadata

- [x] **Scenario: implicit invocation remains enabled**
  - **Given** `.agent0/skills/codex-exec/agents/openai.yaml` exists
  - **When** a maintainer reads the policy block
  - **Then** it declares `allow_implicit_invocation: true` by default, with no paid-service dependency and no hidden network dependency beyond the local Codex CLI doing its normal provider call

- [x] **Scenario: write-capable Codex runs require explicit caller intent**
  - **Given** a caller wants Codex to edit files rather than inspect or critique
  - **When** they invoke the skill
  - **Then** they must pass an explicit non-read-only sandbox value such as `--sandbox workspace-write` or `--sandbox danger-full-access`; absent that parameter, the helper never grants write access

- [x] **Scenario: outputs are auditable and gitignored**
  - **Given** any `codex-exec` run completes or fails
  - **When** the helper exits
  - **Then** it writes the last Codex message to `.agent0/.runtime-state/codex-exec/<timestamp>-<slug>/last-message.md`, optionally writes JSONL events when `--json` is requested, appends one metadata line containing timestamp, prompt slug, sandbox, model/profile if provided, exit code, and output paths, and rejects `--output` values that resolve outside the state directory

- [x] **Scenario: missing Codex dependency fails cleanly**
  - **Given** `codex` is not on `PATH` or `.agent0/tools/codex-local-env.sh` is missing
  - **When** the helper is invoked
  - **Then** it exits non-zero before running any task, prints an actionable setup error, and does not create a success-looking output directory

- [x] **Scenario: skill validation and discovery pass**
  - **Given** the skill is implemented
  - **When** the maintainer runs the relevant Agent0 skill and multi-runtime checks
  - **Then** `SKILL.md` passes `/skill validate codex-exec`, the `.claude/skills` and `.agents/skills` symlinks resolve to the one canonical `.agent0/skills/codex-exec` source, and any new tests under `.agent0/tests/codex-exec-skill/` pass

- [x] `.agent0/skills/codex-exec/SKILL.md` exists, uses agentskills.io frontmatter, and documents the bridge as a subprocess orchestration tool rather than a native shared-memory delegation primitive.

- [x] `.agent0/skills/codex-exec/scripts/codex-exec.sh` exists, is executable, uses `set -euo pipefail`, and never builds the Codex command via `eval`.

- [x] `.agent0/skills/codex-exec/agents/openai.yaml` exists with `policy.allow_implicit_invocation: true`.

- [x] `.gitignore` already covers the chosen runtime-state path, so `codex-exec` run outputs do not enter normal git status.

## Non-goals

- Native Claude `Agent` integration. The skill does not make Codex a Claude subagent; it only launches `codex exec` as a local subprocess.
- Proving interactive Codex TUI hook behavior. Prior Agent0 dogfood showed `codex exec` is not a faithful proof surface for some lifecycle hooks; this skill is for non-interactive work, review, and probes.
- Building a long-lived broker, daemon, queue, or RPC server. The v1 bridge is one command in, files out.
- Replacing `/sdd debate`. Debate artifacts remain file-based and human-orchestrated; `codex-exec` may help invoke Codex, but it does not own the debate protocol.
- Bypassing approvals or sandboxing by default. The helper must not pass `--dangerously-bypass-approvals-and-sandbox` unless a future spec explicitly introduces and gates that mode.
- Shipping provider credentials. The helper reuses the local Codex install and config; no OpenAI keys or Codex auth files are copied into Agent0.
- Hiding failures behind a polished summary. Non-zero Codex exit status and stderr must remain visible to the parent agent.

## Open questions

- [x] **Invocation syntax — RESOLVED.** V1 exposes shell flags plus `--task` / `--task-file` / stdin / `-- <prompt...>`. No strict JSON envelope until a caller needs it.
- [x] **`--cwd` scope — RESOLVED.** `--cwd` must resolve under the repo root; arbitrary external paths are rejected.
- [x] **Metadata shape — RESOLVED.** Each run writes `metadata.json`; the aggregate audit trail is `.agent0/.runtime-state/codex-exec/runs.jsonl`.
- [x] **JSONL surfacing — RESOLVED.** The helper captures JSONL to `events.jsonl` when `--json` is passed and reports the path; the parent agent summarizes the final message only when needed.

## Context / references

- `docs/specs/121-multi-runtime-skills/` — canonical skill source lives in `.agent0/skills/<slug>/` with `.claude/skills` and `.agents/skills` discovery symlinks.
- `.agent0/context/rules/runtime-capabilities.md` — Codex skills are `native-opt-in`; `agents/openai.yaml` can control implicit invocation policy.
- `.agent0/tools/codex-local-env.sh` — existing repo-local launcher that loads `.codex/.env.local` and runs Codex from the repo root.
- `.agent0/skills/image/agents/openai.yaml` — current local example of Codex skill metadata and `allow_implicit_invocation` policy, though this spec deliberately chooses `true`.
- Prior Codex memory: `codex exec resume <SESSION_ID>` preserves continuity, and Codex top-level flags must be placed before `exec` when using the repo-local launcher.
- Prior Codex memory: `codex exec` is not a faithful proof surface for some interactive lifecycle-hook behavior; do not use this skill as live TUI hook proof.
- Local proof, 2026-05-30:
  - `bash .agent0/tests/codex-exec-skill/run-all.sh` — all 4 scenarios passed.
  - `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/codex-exec` — passed.
  - `bash .agent0/skills/skill/scripts/check-rubric.sh .agent0/skills/codex-exec` — passed with no advisories after adding freedom annotations and eval scenarios.
  - `bash -n .agent0/skills/codex-exec/scripts/codex-exec.sh .agent0/tests/codex-exec-skill/*.sh` — passed.
  - `.claude/skills/codex-exec` and `.agents/skills/codex-exec` resolve to `../../.agent0/skills/codex-exec`.
  - `bash .agent0/tests/multi-runtime-skills/run-all.sh` — existing multi-runtime skill suite passed.
  - `bash .agent0/tools/codex-local-env.sh debug prompt-input | rg codex-exec` — Codex discovered the skill at `.agent0/skills/codex-exec/SKILL.md`.
  - `bash .agent0/skills/codex-exec/scripts/codex-exec.sh --slug live-smoke-2 --task 'Reply exactly CODEX_EXEC_LIVE_OK. Do not inspect files. Do not run shell commands.'` — real Codex CLI smoke passed with `exit_code=0`, `sandbox=read-only`, and `last-message.md` containing `CODEX_EXEC_LIVE_OK`.
  - Claude Code dogfood (`claude-dogfood-readonly`) passed and found one real follow-up defect: unrestricted `--output` could write artifacts outside gitignored runtime state. Fixed in-place by constraining `--output` under the state directory and adding regression coverage.
  - `bash .agent0/skills/codex-exec/scripts/codex-exec.sh --slug live-smoke-output-fix --task 'Reply exactly CODEX_EXEC_OUTPUT_FIX_OK. Do not inspect files. Do not run shell commands.'` — post-fix real Codex CLI smoke passed with `exit_code=0`, `sandbox=read-only`, and default artifacts still under `.agent0/.runtime-state/codex-exec/`.
