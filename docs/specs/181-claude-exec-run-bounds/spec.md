# 181 — claude-exec-run-bounds

_Created 2026-06-09._

**Status:** shipped

**Closure:** 2026-06-09 — shipped; `bash .agent0/tests/claude-exec-skill/run-all.sh`; `bash -n .agent0/skills/claude-exec/scripts/claude-exec.sh`; `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/claude-exec`; `bash .agent0/skills/skill/scripts/check-rubric.sh .agent0/skills/claude-exec`; live smoke `.agent0/.runtime-state/claude-exec/20260609T152815Z-live-smoke-181/metadata.json`; residual: native `--max-budget-usd` is a budget guard, not a hard billing ceiling.

**UI impact:** none

## Intent

Harden the shipped `claude-exec` bridge so a parent runtime can use Claude Code as a second-model subprocess without silent multi-minute hangs or opaque spend failures. The current helper is documented as a bounded subprocess, but the live OpenClaude reverse-engineering dogfood showed a real gap: a broad read-only review with `--output-format json`, `--effort high`, tool access, and no timeout produced no `stdout`/`stderr` for several minutes and had to be killed externally with exit 143. Follow-up probes proved the Claude CLI, auth, `jq`, and the helper work for small prompts; the failure mode is broad toolful work with no native helper timeout, no budget guard forwarding, and no progress signal while Claude is still thinking or reading.

This spec is a hardening of an already-admitted Agent0 runtime bridge, not a new delegation model. V1 adds explicit run bounds and better observability while preserving the existing safety invariant: `--permission-mode` remains required and write-capable modes still require `--allow-writes`.

Admission brief: **Layer:** transversal constraint and governance substrate for multi-runtime work. **Boundary:** Agent0 owns this bridge because it is first-party harness tooling. **Evidence:** dogfood failure plus repeated prior review-surface hangs. **V1 posture:** tool hardening plus docs/tests, not a new gate. **Blast radius:** Agent0-owned skill/tool surface; consumer-propagated if/when harness sync is explicitly run. **Validation:** shell tests with stubbed Claude, syntax checks, skill validation, and one small live smoke bounded by timeout and a native budget guard. **Non-goal:** making Claude non-interactive review fully reliable for arbitrary repo-scale reverse engineering.

## Acceptance criteria

- [x] **Scenario: long Claude subprocess times out with a useful artifact trail**
  - **Given** a caller invokes `claude-exec` with a prompt whose child `claude` process runs longer than the configured timeout
  - **When** the timeout elapses
  - **Then** the helper terminates the child, exits non-zero with a timeout-specific code, records the timeout setting and timeout outcome in `metadata.json` and `runs.jsonl`, preserves any partial stdout/stderr artifacts, and does not leave an orphaned Claude process

- [x] **Scenario: caller can set a native Claude budget guard**
  - **Given** a caller passes `--max-budget-usd <amount>`
  - **When** the helper builds the `claude -p` invocation
  - **Then** it forwards the value to Claude's native `--max-budget-usd`, validates obvious malformed values before invoking Claude, records the configured budget guard in metadata, and surfaces Claude's non-zero budget-exceeded result without reporting success

- [x] **Scenario: long runs are not silent**
  - **Given** a Claude subprocess is still running after the configured progress interval
  - **When** the helper is waiting for completion
  - **Then** it emits a concise progress heartbeat to stderr naming elapsed seconds and current artifact byte counts, while keeping the final machine-readable artifacts under the run directory

- [x] **Scenario: streaming capture is documented and preserved**
  - **Given** the caller requests streamed JSON capture with `--json`
  - **When** the helper runs Claude
  - **Then** it continues to use `--output-format stream-json --verbose`, writes `events.jsonl`, extracts the final `result` into `last-message.md` when present, and documents that `--json` is the preferred mode for broad read-only reviews because the event file can grow during the run

- [x] **Scenario: existing safety and capture contracts do not regress**
  - **Given** existing callers use required `--permission-mode`, read-only tool allowlists, resume, `--output` containment, `--add-dir` containment, or `--allow-writes`
  - **When** the helper parses and runs those invocations
  - **Then** the spec-129 behavior still holds: no default permission mode is assumed, write-capable modes are refused without `--allow-writes`, argv arrays are used, dependencies fail cleanly, and metadata/last-message extraction still work

- [x] `.agent0/skills/claude-exec/SKILL.md` documents `--timeout`, `--max-budget-usd`, progress behavior, and the recommended scoped-review invocation for broad repository analysis.

- [x] `.agent0/tests/claude-exec-skill/` contains deterministic tests for timeout, budget flag mapping, progress heartbeat, and preservation of existing behavior.

## Non-goals

- Guaranteeing that Claude can complete arbitrary repo-scale static analysis within a fixed time or exact spend amount.
- Guaranteeing that Claude's native `--max-budget-usd` is a hard billing ceiling. The helper forwards and records the guard; Claude owns actual budget-exceeded semantics and may report startup/context cost above the configured guard.
- Replacing scoped prompts, local verification, or explicit fallback handling when Claude review is unavailable.
- Changing the `--permission-mode` pass-through design or weakening the `--allow-writes` floor gate.
- Adding a daemon, queue, broker, MCP server, or native subagent integration.
- Adding consumer sync in this spec. Sync remains a separate, explicit operation after Agent0 implementation is shipped.

## Open questions

- [x] Choose the default timeout and progress interval during implementation. Resolved: 600 seconds timeout and 30 seconds progress interval, with explicit CLI overrides.
- [x] Decide whether `--timeout 0` should be allowed as an explicit local escape hatch. Resolved: no unbounded escape hatch in v1; callers can choose a larger positive timeout.
- [x] Decide whether `--json` should remain opt-in or become the default for toolful runs. Resolved: keep it opt-in for compatibility, but update docs/examples to use it for broad reviews.

## Context / references

- `docs/specs/129-claude-exec/` — shipped bridge contract and non-goals this spec hardens.
- `.agent0/skills/claude-exec/scripts/claude-exec.sh` — current helper; runs `claude` directly and only records metadata after the child exits.
- `.agent0/skills/claude-exec/SKILL.md` — public skill contract to update.
- `.agent0/tests/claude-exec-skill/` — existing shell suite to extend.
- `.agent0/.runtime-state/claude-exec/20260609T144017Z-openclaude-reverse-review/` — failed dogfood run; `exit_code=143`, empty stdout/stderr/last-message.
- `.agent0/.runtime-state/claude-exec/20260609T150708Z-probe-helper-minimal/` — helper sanity probe; `exit_code=0`, non-empty last message.
- `claude -p --help` observed 2026-06-09 — confirms native `--max-budget-usd`, `--output-format json|stream-json`, `--include-partial-messages`, `--model`, `--effort`, `--permission-mode`, and `--add-dir` surfaces.
