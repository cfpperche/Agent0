# 091 — sdd-debate-runner

_Created 2026-05-26._

**Status:** superseded 2026-06-09 — decision-grade `/sdd debate` now runs through the meeting bridge (spec 149 protocol, spec 180 policy: blind Round 1 via `meeting.sh` with `codex-exec`/`claude-exec` peer turns), which delivers the orchestration this spec proposed; the standalone automated runner will not be pursued.

## Intent

Automate the SDD debate loop so a human no longer has to copy prompts between Claude Code and Codex sessions. Today `docs/specs/*/debate.md` is already the shared state and audit trail, but turn orchestration is manual: the human reads the next empty slot, writes a prompt for the correct runtime, waits, then repeats. This spec adds a local debate runner that reads a target spec directory, determines the next debate turn from `debate.md`, invokes the correct runtime in headless mode, validates that only the expected debate slot changed, and stops at clear human decision points. V1 stays local and sequential: no broker service, no direct model API, no parallel agents, and no automatic spec edits after synthesis.

## Acceptance criteria

- [ ] **Scenario: automated debate starts from a filled spec**
  - **Given** a `docs/specs/NNN-<slug>/spec.md` with no unfilled template placeholders and no `debate.md`
  - **When** the runner is invoked with explicit initiating and reviewing runtimes
  - **Then** it scaffolds `debate.md`, records the initiating/reviewing runtime identities, invokes the initiating runtime to fill Round 1 position, invokes the reviewing runtime to fill Round 1 critique, and returns without requiring manual prompt copy-paste

- [ ] **Scenario: in-flight debate resumes the next correct turn**
  - **Given** a `debate.md` whose metadata names `Codex CLI` and `Claude Code`, with the next empty slot belonging to one runtime
  - **When** the runner is invoked against that spec directory
  - **Then** it calls only the runtime that owns that slot, passes a generated prompt naming the exact header to fill, and leaves other slots untouched

- [ ] **Scenario: turn validation catches unsafe edits**
  - **Given** a runtime invocation changes `spec.md`, edits a filled debate slot, fills the wrong placeholder, or changes files outside the allowed debate artifact
  - **When** the runner performs post-turn validation
  - **Then** it exits non-zero with a concrete diagnostic, preserves enough information for manual recovery, and does not continue to the other runtime

- [ ] **Scenario: human remains the synthesis gate**
  - **Given** the configured round cap is reached or both agents indicate convergence
  - **When** the runner finishes the last ordinary critique/counter turn
  - **Then** it reports that the debate is ready for synthesis and does not fill `## Synthesis` or apply `spec.md` changes unless the user invokes an explicit synthesis mode

- [ ] **Scenario: missing runtime prerequisites fail before mutation**
  - **Given** `claude` or `codex` is missing, unauthenticated, or unavailable in the current environment
  - **When** the runner is invoked for a debate that needs that runtime
  - **Then** it fails during preflight before editing `debate.md`, with the command and remediation hint needed to continue manually

- [ ] A runner entrypoint exists in the harness and is documented with usage examples for starting, resuming, dry-running, and synthesizing a debate.

- [ ] The runner supports at least `--initiator`, `--reviewer`, `--max-rounds`, `--dry-run`, and an explicit synthesis mode flag.

- [ ] V1 runtime adapters call local CLIs, not provider APIs: Claude through `claude -p`, Codex through `codex exec`.

- [ ] The runner treats `debate.md` as the canonical shared state and writes no separate source-of-truth state file.

- [ ] Any runner logs or captured command output are gitignored or kept under an existing runtime-state location; `debate.md` remains the git-tracked audit trail.

- [ ] The runner has focused tests for slot detection, role selection, dry-run prompt generation, prerequisite failure, and post-turn validation using fake Claude/Codex commands.

## Non-goals

- **Direct model API orchestration.** V1 does not call Anthropic or OpenAI APIs directly and does not implement its own tool loop.
- **A daemon, web UI, or MCP broker.** This is a local command runner, not a long-running service.
- **Parallel debate turns.** Human-style alternating turns remain the model. The runner serializes invocations and should use a lock to avoid concurrent writes.
- **General multi-agent orchestration.** The runner is scoped to SDD `debate.md`, not arbitrary agent workflows.
- **Replacing human judgment.** The runner may stop at synthesis readiness; it does not decide that a spec is accepted, apply synthesis changes, or start `plan.md` without explicit user action.
- **Porting all Codex hooks, skills, subagents, or MCP config.** Those belong to the multi-runtime parity roadmap, not this runner.
- **Neutral namespace migration.** If implemented before a repo-wide `.agent0/` namespace exists, the runner may live under the current `.claude/tools/` harness path.

## Open questions

- [ ] Should the runner default to one initiating runtime, or require `--initiator` on every new debate to avoid hidden Claude/Codex bias? Lean: require the flag when `debate.md` does not exist.
- [ ] Should synthesis be a separate subcommand (`debate-runner synthesize`) or a flag on the same command (`--synthesize`)? Lean: separate mode because it changes the write target and human decision point.
- [ ] Should the first implementation use plain shell for low dependency cost, or Python for safer markdown parsing and subprocess handling? Lean: shell is enough only if parser tests stay simple; Python is likely safer once validation/rollback is included.
- [ ] What is the exact allowed file mutation surface per turn: only `debate.md`, or also a temporary runtime log path? Lean: only `debate.md` during validation, with logs written before/after the turn under gitignored runtime state.

## Context / references

- `docs/specs/089-sdd-debate-artifact/` — introduced `debate.md` as the shared cross-runtime artifact.
- `docs/specs/090-multi-runtime-entrypoints/` — establishes Claude Code and Codex as the first two runtime surfaces Agent0 cares about.
- `.claude/skills/sdd/SKILL.md` — current manual `/sdd debate` protocol, including role detection, slot ownership, and synthesis gate.
- `.claude/tools/sync-harness.sh` — current harness tool location and sync behavior if the runner ships with Agent0.
- OpenAI Codex non-interactive mode — `codex exec`, JSONL output, resume, CI automation: https://www.mintlify.com/openai/codex/concepts/non-interactive-mode
- OpenAI Codex `AGENTS.md` guide — instruction chain and `AGENTS.override.md`: https://developers.openai.com/codex/guides/agents-md
- OpenAI Codex hooks guide — useful for validation/logging, not the primary orchestration mechanism here: https://developers.openai.com/codex/hooks
- OpenAI Codex skills guide — relevant follow-up if the runner becomes a Codex skill/plugin: https://developers.openai.com/codex/skills
- Claude Code headless mode — `claude -p` and structured output flags: https://code.claude.com/docs/en/headless
- Claude Agent SDK overview — future option for deeper orchestration with sessions, hooks, and built-in tools: https://code.claude.com/docs/en/agent-sdk/overview
