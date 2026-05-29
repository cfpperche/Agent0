---
paths:
  - ".claude/hooks/runtime-*.sh"
  - ".agent0/tools/probe.sh"
  - ".agent0/.runtime-state/**"
---

# Runtime introspect

A capacity that gives the agent runtime evidence about its own work so it can close edit→verify loops without depending on human ratification or static-code reading alone. A `PostToolUse(Bash)` hook captures the last test/build/typecheck command output to a single state file; a shell tool reads it back in a shape the agent can pattern-match.

The wedge is deliberately framework-agnostic and minimal — it complements mature external MCPs (Laravel boost, Playwright MCP, Chrome DevTools MCP, DBHub, next-devtools-mcp, rails-mcp-server) by filling the gap none of them covers: generic local test/build capture. Consumer projects layer the external MCPs into their own `.mcp.json` when they need browser/DB introspection.

## What fires, what captures

- **Pre-mark — `PreToolUse(Bash)` → `.claude/hooks/runtime-pre-mark.sh`.** Stamps a `started_at` timestamp into `.agent0/.runtime-state/in-flight/<tool_use_id>.t` so the post hook can compute `duration_ms`.
- **Capture — `PostToolUse(Bash)` AND `PostToolUseFailure(Bash)` → `.claude/hooks/runtime-capture.sh`.** Tokenises `tool_input.command`, matches against the detector pair list below, and writes `.agent0/.runtime-state/last-run.json` atomically when a verifier runs. Honours `CLAUDE_SKIP_RUNTIME_INTROSPECT=1`. Always exits 0.
- **Probe — `.agent0/tools/probe.sh last-run`.** Reads the state file and emits a plain-text block the agent pattern-matches. Missing state → friendly empty-state message; exit 0.
- **SessionStart hint — `.agent0/hooks/session-start.sh`.** Appends one line naming the probe path and example invocation.

## Detector pair list (v1)

Detection is tokenisation-based. Matches at least one non-flag positional after the verb (otherwise the command is a no-op like `bun install` without args). Pair list:

| Pair | Notes |
| --- | --- |
| `bun test` | Bun's native test runner |
| `bun tsc` | `bun tsc --noEmit` typecheck; pass-through to TypeScript compiler |
| `bun run <script>` | Only when `<script>` contains `test`, `build`, `typecheck`, or `lint` substring. `bun run dev` is NOT a verifier (long-running server) and is skipped. |
| `npm test` / `npm run test` | npm test conventions |
| `npm run build` / `npm run typecheck` / `npm run lint` | npm's verify-shaped scripts |
| `pnpm test` / `pnpm run test` / `pnpm run build` / `pnpm run typecheck` / `pnpm run lint` | pnpm equivalents |
| `yarn test` / `yarn build` / `yarn typecheck` / `yarn lint` | yarn equivalents |
| `pytest` / `python -m pytest` / `python3 -m pytest` | Python testing |
| `python -m unittest` / `python3 -m unittest` | stdlib unittest |
| `cargo test` | Rust's native test runner (cargo workspaces walk all members by default) |
| `cargo build` | Rust compile (release/dev profile) |
| `cargo check` | Rust typecheck-equivalent (no codegen, fastest verifier) |
| `cargo clippy` | Rust lint analog of biome/ruff; `cargo clippy -- -D warnings` promotes warnings to errors |
| `vendor/bin/phpunit` / `./vendor/bin/phpunit` | Single-token PHP test runner (PHPUnit) |
| `vendor/bin/pest` / `./vendor/bin/pest` | Single-token PHP test runner (Pest, wraps PHPUnit) |
| `php artisan test` | Laravel's `artisan test` command (typically wraps Pest or PHPUnit). Pair-token match on `artisan test` — the leading `php` is the shell context |
| `composer test` / `composer lint` | Composer-script wrappers — common pattern in Laravel consumer projects where `composer.json` `scripts.test` aliases the test runner |

## `last-run.json` schema

Single snapshot at `.agent0/.runtime-state/last-run.json`, gitignored, overwritten on every matched capture via `mktemp + mv` (POSIX rename atomicity → no torn writes). Field semantics:

```json
{
  "command": "bun test src/server.test.ts",
  "detector": "bun-test",
  "exit": null,
  "interrupted": false,
  "inferred_status": "PASS",
  "inference_basis": "bun-test: '0 fail' line",
  "started_at": "2026-05-11T17:14:43Z",
  "ended_at": "2026-05-11T17:14:44Z",
  "duration_ms": 118,
  "session_id": "01HZX...",
  "agent_id": null,
  "stdout_head": " 10 pass\n 0 fail\n 17 expect() calls...",
  "stdout_tail": "",
  "stdout_truncated": false,
  "stderr_head": "",
  "stderr_tail": "",
  "stderr_truncated": false
}
```

- `command` — raw `tool_input.command` (no shell rewrite).
- `detector` — pair-list key that matched. Core: `bun-test`, `bun-tsc`, `bun-run-test`, `bun-run-typecheck`, `bun-run-build`, `bun-run-lint`, `npm-test`, `npm-run-test`, `pnpm-test`, `pnpm-run-typecheck`, `yarn-test`, `yarn-typecheck`, `yarn-build`, `yarn-lint`, `pytest`, `python-pytest`, `python-unittest`, `cargo-test`, `cargo-build`, `cargo-check`, `cargo-clippy`. Extension: `extra:<key>`.
- `exit` — integer from `tool_response.exit_code` when the harness surfaces it; **`null` under Claude Code today** (the Bash tool_response carries `{stdout, stderr, interrupted, isImage, noOutputExpected}` and no exit field). Other harnesses may surface it; the field is read defensively.
- `interrupted` — boolean from `tool_response.interrupted`. `true` overrides everything downstream to status `INTERRUPTED`.
- `inferred_status` — `PASS` / `FAIL` / `UNKNOWN` / `INTERRUPTED`, computed from runner-specific stdout/stderr patterns. Always set; the probe uses it as the canonical status when `exit` is `null`.
- `inference_basis` — short string explaining which pattern matched (e.g. `bun-test: '0 fail' line`). Auditable.
- `started_at` / `ended_at` — ISO-8601 UTC. `started_at` from the PreToolUse in-flight mark; `ended_at` is hook-write time.
- `duration_ms` — integer or `null`. **Prefer the harness's top-level `duration_ms`** when present (real millisecond wall clock); fall back to date-second diff only when absent.
- `session_id` / `agent_id` — pass-through from the hook payload (`agent_id` is `null` for parent edits).
- `stdout_head` / `stdout_tail` — first 4096 bytes / last 4096 bytes of `tool_response.stdout`. When total length ≤ 8192 bytes, `stdout_head` holds the whole stream and `stdout_tail` is `""`.
- `stdout_truncated` — `true` iff clamping engaged (`len > 8192`). Same shape for `stderr_*`.

## Probe output shape

`bash .agent0/tools/probe.sh last-run` emits plain text:

```
status: PASS
command: cd ~/some-consumer && bun test
detector: bun-test
exit: null
inferred_status: PASS
inference_basis: bun-test: '0 fail' line
age: 1s
duration_ms: 118
stale: false

--- stdout (head) ---
 10 pass
 0 fail
 17 expect() calls
Ran 10 tests across 2 files. [34.00ms]

--- stderr ---
(empty)
```

The `status` header is the canonical outcome the agent reads. When `exit` is numeric (some non-Claude harness), `status` mirrors that (`0` → PASS, else FAIL). When `exit` is `null` (Claude Code today), `status` mirrors `inferred_status`. When `interrupted=true`, `status` is `INTERRUPTED` regardless. The `inference_basis` line is only emitted when inference is doing the work — it documents which pattern matched, so a failing inference can be audited.

When the state file is missing:

```
status: no-snapshot
hint: run a recognised verifier (e.g. `bun test`, `pytest`) then re-query with `bash .agent0/tools/probe.sh last-run`.
```

The shape is plain text by design — agents read stdout, not structured tool returns, in v1. JSON output is a candidate v2 if MCP promotion happens.

## Escape hatches

- **`CLAUDE_SKIP_RUNTIME_INTROSPECT=1`** — disables both hooks silently. No capture, no probe writes. For throwaway scratch sessions; do NOT set in long-lived shell config (silent permanent disable).
- **`CLAUDE_RUNTIME_INTROSPECT_DEBUG=1`** — opts INTO stderr diagnostic lines from the capture hook (default off — never pollute stderr in normal use). One line per noteworthy event: detector match, write success, tail-clamp engaged.
- **`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="<globs>"`** — adds custom pair detections. **MUST be set in the shell before `claude` launches** — not settable mid-session by an agent. See the maintenance memory for the extension contract and the underlying sibling-process env-inheritance reason.

Missing `jq`: both hooks fail open (`exit 0`, no capture). The probe tool prints a one-line "jq not found — probe disabled" message and exits 0.

## Gotchas

- **Probe inside the SAME Bash tool call does NOT see its own capture.** PostToolUse fires AFTER the underlying Bash command returns. A command of the shape `bun test && bash .agent0/tools/probe.sh last-run` will probe the PREVIOUS snapshot, not the one being produced. To read the current run's snapshot, the probe must be in the agent's *next* Bash invocation.
- **`PostToolUse(Bash)` fires only on exit-zero.** Failing Bash commands route to `PostToolUseFailure(Bash)` instead. The capture hook is registered on both events.
- **Claude Code's `tool_response.exit_code` does NOT exist.** Status inference IS the canonical signal under Claude Code; the `exit` field stays `null`. The probe reads `inferred_status` accordingly.
- **SessionStart hint is one line.** Agents may scan past it. The hint exists for discoverability, not for forced behaviour. Reinforce in `.claude/rules/tdd.md` and PR reviews that the probe is the canonical way for the agent to verify its own work.

## Maintenance

Maintainer-binding surface (detector extension contract via `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` and why it is human-only, per-detector inference heuristics, state-file design rationale, dogfood archaeology around sibling-process env inheritance, ANSI strip, cargo workspaces, commit-message FP, mid-session extension limits) lives in `.agent0/memory/runtime-introspect-maintenance.md`.

## Cross-references

- `.agent0/memory/runtime-introspect-maintenance.md` — maintainer-binding companion
- `.claude/hooks/runtime-capture.sh` / `.claude/hooks/runtime-pre-mark.sh` — implementation
- `.agent0/tools/probe.sh` — probe surface
- `.claude/rules/tdd.md` — verification convention the probe supports
