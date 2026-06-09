# 181 — claude-exec-run-bounds — plan

_Drafted from `spec.md` on 2026-06-09. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Treat this as a narrow reliability hardening pass on the existing `claude-exec` bridge. The core contract from spec 129 stays intact: explicit native `--permission-mode`, write-capable modes gated by `--allow-writes`, argv arrays, prompt via stdin, JSON/JQ extraction, state-dir-contained outputs, and gitignored run artifacts. The new work adds three missing bounds around that contract: wall-clock timeout, native Claude budget-guard forwarding, and progress visibility while the subprocess is still running.

Implementation should be test-first against stubbed `claude`, because the real CLI is paid and slow enough that repeated live probes are the wrong validation loop. Add parser and metadata fields first, then route execution through a small wait wrapper that can emit heartbeats and enforce timeout without changing the command-building semantics. Keep `--json` opt-in for compatibility in v1, but update documentation and examples so broad toolful reviews use `--json`, `--timeout`, `--max-budget-usd`, scoped prompts, and low/medium effort by default.

Recommended CLI additions:

- `--timeout <seconds>` — positive integer, default 600 seconds unless implementation evidence argues for another value.
- `--progress-interval <seconds>` — non-negative integer, default 30 seconds; `0` disables heartbeat only, not timeout.
- `--max-budget-usd <amount>` — positive decimal forwarded to `claude -p --max-budget-usd <amount>` as Claude's native budget guard. This is not documented as a hard billing ceiling.

Timeout should be implemented with the platform `timeout` command if available, returning the conventional timeout status (`124`) for deadline expiry. If `timeout` is not on `PATH`, the helper should fail cleanly before invoking Claude once a timeout is requested/defaulted; silently falling back to unbounded execution would recreate the bug.

## Files to touch

**Create:**
- `.agent0/tests/claude-exec-skill/06-timeout.sh` — stub `claude` sleeps past a short timeout; assert non-zero timeout exit, no orphan child, metadata timeout fields, preserved artifacts.
- `.agent0/tests/claude-exec-skill/07-budget-and-progress.sh` — assert `--max-budget-usd` maps to Claude argv, malformed budget guard values are refused before invocation, and heartbeat text appears on stderr for a slow stub.

**Modify:**
- `.agent0/skills/claude-exec/scripts/claude-exec.sh` — parse new flags, validate values, include budget in Claude argv, wrap execution with timeout/progress, and extend metadata/runs log fields.
- `.agent0/skills/claude-exec/SKILL.md` — document the new flags, timeout/progress behavior, budget guard behavior, and a recommended broad-review pattern.
- `.agent0/tests/claude-exec-skill/run-all.sh` — include the new tests.
- Existing `.agent0/tests/claude-exec-skill/*` tests as needed — adjust expected usage text and metadata assertions without weakening existing spec-129 coverage.
- `docs/specs/181-claude-exec-run-bounds/tasks.md` — check off implementation/verification as work proceeds.
- `docs/specs/181-claude-exec-run-bounds/notes.md` — append decisions if implementation changes the defaults or timeout mechanics.

**Delete:**
- None.

## Alternatives considered

### Tell callers to use shell `timeout` externally

Rejected because the skill already describes itself as launching a bounded subprocess. External `timeout` helps an expert operator, but it leaves `metadata.json`, `runs.jsonl`, and the skill docs unable to distinguish timeout from any other `SIGTERM`/`exit 143` kill. The helper should own the bound it claims.

### Make `--json`/streaming the default for any run with tools or `--add-dir`

Rejected for v1 compatibility. Existing callers may expect the default `stdout.txt` single-object capture path. The safer v1 is to keep `--json` opt-in, document it as the recommended broad-review mode, and pair it with heartbeat output so even non-streaming runs are not silent.

### Add only `--max-budget-usd` and skip timeout/progress

Rejected because the observed failure was wall-clock silence, not only budget visibility. A native budget guard can make Claude return a budget-exceeded result, but a stalled auth/config/tool path can still sit with empty stdout/stderr. Timeout and heartbeat address the operator failure mode directly.

### Use `--bare` by default to lower context cost

Rejected again for the same reason as spec 129: default `--bare` breaks OAuth/subscription auth paths and strips project context that spec/review tasks need. `--bare` remains an opt-in caller decision.

## Risks and unknowns

- **Exit-code semantics.** GNU `timeout` returns 124 on timeout by default, but external termination can still produce 143. Tests should assert helper-owned timeout gives 124 and metadata marks `timed_out: true`; externally killed runs remain a separate failure class.
- **macOS/coreutils variance.** Agent0 is mostly exercised on Linux, but consumers may use platforms where `timeout` differs or is absent. The helper should detect absence clearly; portability can be revisited if a consumer hits it.
- **Progress noise.** Heartbeats should go to stderr and only after the interval elapses, so quick runs stay clean. Machine-readable results remain in run artifacts.
- **Budget validation.** Shell numeric validation should catch obvious malformed values without trying to be a financial parser. Claude remains the authority for accepted precision and budget semantics; the live smoke proved this guard can report total cost above the configured value, so docs must not describe it as a hard billing ceiling.
- **Live smoke cost.** The real Claude smoke must be tiny and budget-guarded, because even minimal Claude Code runs can incur non-trivial startup/context cost.

## Research / citations

- `docs/specs/129-claude-exec/` — shipped bridge behavior and safety invariants.
- `.agent0/skills/claude-exec/scripts/claude-exec.sh` — current implementation lines around command construction and direct child execution.
- `.agent0/skills/claude-exec/SKILL.md` — current public usage contract.
- `.agent0/tests/claude-exec-skill/` — existing deterministic shell test structure.
- `claude -p --help` observed 2026-06-09 — native `--max-budget-usd`, `--output-format stream-json`, and related print-mode flags.
- OpenClaude dogfood artifacts under `.agent0/.runtime-state/claude-exec/20260609T144017Z-openclaude-reverse-review/` — concrete timeout/silence failure.
