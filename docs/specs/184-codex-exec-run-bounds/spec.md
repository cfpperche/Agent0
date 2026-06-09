# 184 — codex-exec-run-bounds

_Created 2026-06-09._

**Status:** shipped

**Closure:** 2026-06-09 — shipped; `bash .agent0/tests/codex-exec-skill/run-all.sh`; `bash -n .agent0/skills/codex-exec/scripts/codex-exec.sh`; `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/codex-exec`; `bash .agent0/skills/skill/scripts/check-rubric.sh .agent0/skills/codex-exec`; `bash .agent0/tools/spec-verify.sh docs/specs/184-codex-exec-run-bounds`; live smoke `.agent0/.runtime-state/codex-exec/20260609T154938Z-live-smoke-184/metadata.json`; residual: Codex CLI still has no native budget guard, so timeout is an operational bound rather than a spend ceiling.

**UI impact:** none

## Intent

Harden the shipped `codex-exec` bridge so Claude Code, another parent runtime, or Agent0 orchestration can call Codex CLI as a second-model subprocess without creating an unbounded silent wait. The helper already defaults to a read-only sandbox and records run artifacts, but its child execution currently waits until `codex exec` exits. If Codex stalls before writing stdout/stderr, the caller has no heartbeat, no elapsed-time metadata, and no helper-owned timeout.

This follows the operational lesson from spec 181 (`claude-exec-run-bounds`) while respecting Codex CLI's current local surface. On 2026-06-09, `codex exec --help` showed no native budget flag comparable to Claude's `--max-budget-usd`, so this spec adds wall-clock bounds and observability only. It does not invent a fake spend guard.

Admission brief: **Layer:** first-party runtime bridge hardening. **Boundary:** Agent0 owns the `codex-exec` skill and deterministic test harness. **Evidence:** local `codex exec --help` confirms the absence of native budget control; existing helper lacks timeout/progress fields despite being documented as bounded. **V1 posture:** small safety/observability improvement, no new orchestration model. **Blast radius:** `.agent0/skills/codex-exec`, its tests, and this spec. **Validation:** shell tests with a fake slow Codex, syntax/skill checks, spec verification, and one tiny live smoke if local Codex auth is usable.

## Acceptance Criteria

- [x] **Scenario: long Codex subprocess times out with a useful artifact trail**
  - **Given** a caller invokes `codex-exec` with a prompt whose child `codex` process runs longer than the configured timeout
  - **When** the timeout elapses
  - **Then** the helper terminates the child, exits with timeout status `124`, records timeout settings and timeout outcome in `metadata.json` and `runs.jsonl`, preserves partial stdout/stderr artifacts, and does not leave the fake Codex process running in deterministic tests

- [x] **Scenario: long Codex runs are not silent**
  - **Given** a Codex subprocess is still running after the configured progress interval
  - **When** the helper is waiting for completion
  - **Then** it emits a concise progress heartbeat to helper stderr naming elapsed seconds and current stdout/stderr byte counts, while keeping final machine-readable artifacts under the run directory

- [x] **Scenario: existing safety and capture contracts do not regress**
  - **Given** existing callers use default read-only sandboxing, explicit model/profile/reasoning flags, resume, JSON capture, output containment, cwd containment, or Codex non-zero exit propagation
  - **When** the helper parses and runs those invocations
  - **Then** the original spec 128 behavior still holds: the default sandbox remains `read-only`, argv arrays are used, containment checks fail before invocation, JSON capture uses `events.jsonl`, and metadata/run-log output still records the child exit code

- [x] `.agent0/skills/codex-exec/SKILL.md` documents `--timeout`, `--progress-interval`, timeout exit semantics, progress behavior, and the absence of a native Codex CLI budget guard.

- [x] `.agent0/tests/codex-exec-skill/` contains deterministic tests for timeout, progress heartbeat, timeout/progress validation, and preservation of existing behavior.

## Non-goals

- Adding a Codex budget guard while the local CLI has no native `--max-budget-usd` or equivalent verified surface.
- Guaranteeing that Codex can finish arbitrary repo-scale static analysis within a configured timeout.
- Changing the default read-only sandbox or weakening output/cwd containment.
- Adding Codex CLI flags unrelated to run bounds, such as `--add-dir`, `--ephemeral`, `--ignore-rules`, or `--output-schema`.
- Proving interactive Codex TUI hook behavior or native subagent semantics.
- Syncing these harness changes into consumer projects.

## Open Questions

- [x] Confirm the default timeout and heartbeat interval during implementation. Resolved: `--timeout` defaults to 600 seconds and `--progress-interval` defaults to 30 seconds, with `CODEX_EXEC_TIMEOUT_SECONDS` / `CODEX_EXEC_PROGRESS_INTERVAL_SECONDS` available for tests or local experiments.
- [x] Decide whether `--timeout 0` should be allowed as an explicit unbounded escape hatch. Resolved: no; `--timeout` must be a positive integer because the bridge contract is bounded.

## Context / References

- `docs/specs/128-codex-exec-skill/` — shipped `codex-exec` bridge contract and original acceptance.
- `docs/specs/181-claude-exec-run-bounds/` — sibling runtime bridge hardening pattern.
- `.agent0/skills/codex-exec/scripts/codex-exec.sh` — current helper; runs `codex exec` and waits without helper-owned timeout.
- `.agent0/skills/codex-exec/SKILL.md` — public skill contract to update.
- `.agent0/tests/codex-exec-skill/` — existing deterministic shell suite to extend.
- `codex exec --help` observed 2026-06-09 — confirms `--model`, `--profile`, `--sandbox`, `--cd`, `--json`, and `--output-last-message`; no native budget flag was present.
