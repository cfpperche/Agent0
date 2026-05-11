# Runtime introspect

A capacity that gives the agent runtime evidence about its own work so it can close edit→verify loops without depending on human ratification or static-code reading alone. A `PostToolUse(Bash)` hook captures the last test/build/typecheck command output to a single state file; a shell tool reads it back in a shape the agent can pattern-match. Spec: `docs/specs/011-runtime-introspect/`.

The wedge is deliberately framework-agnostic and minimal — it complements mature external MCPs (Laravel boost, Playwright MCP, Chrome DevTools MCP, DBHub, next-devtools-mcp, rails-mcp-server) by filling the gap none of them covers: generic local test/build capture. Forks layer the external MCPs into their own `.mcp.json` when they need browser/DB introspection.

## What fires, what captures

**Pre-mark — `PreToolUse(Bash)` → `.claude/hooks/runtime-pre-mark.sh`.** Tiny hook. Stamps `started_at` (ISO-8601 UTC) for the current `tool_use_id` into `.claude/.runtime-state/in-flight/<id>.t` so the post hook can compute `duration_ms`. Silent skip when `tool_use_id` is absent. Always exits 0.

**Capture — `PostToolUse(Bash)` → `.claude/hooks/runtime-capture.sh`.** Reads stdin JSON, escape-hatches on `CLAUDE_SKIP_RUNTIME_INTROSPECT=1`, tokenises `tool_input.command` (twin to `.claude/hooks/supply-chain-scan.sh`'s tokeniser — same chain/pipe/redirect terminators and value-taking flag skip), matches against the v1 detector pair list plus `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` globs. On a match: reads `tool_response.exit_code` / `stdout` / `stderr`, computes duration from the in-flight start mark (best-effort, `null` if missing), clamps each stream to 4 KB head + 4 KB tail with a `*_truncated` flag, and writes `.claude/.runtime-state/last-run.json` atomically (`mktemp + mv`). Removes the in-flight mark. Non-matches exit silently with no state write. Always exits 0 — capture failure is invisible to the underlying Bash; one diagnostic line goes to stderr only when `CLAUDE_RUNTIME_INTROSPECT_DEBUG=1`.

**Probe — `.claude/tools/probe.sh`.** Bash + jq. Single `last-run` subcommand in v1. Reads the state file, computes status (`PASS` exit==0, `FAIL` exit!=0, `UNKNOWN` exit missing/non-numeric), computes age from `started_at` vs now, computes `stale` by comparing `started_at` against `.claude/.session-state/started-at`, emits a structured plain-text block the agent can pattern-match (status / command / exit / age / stale header, then `--- stdout (head) ---` / `--- stdout (tail) ---` / `--- stderr ---` markers). Missing state → friendly empty-state message naming an example invocation (`bun test`, `pytest`, etc.); exit 0. Unknown subcommand → exit 2 with one-line usage hint.

**SessionStart hint — `.claude/hooks/session-start.sh`.** Existing hook is extended to append one line after the SESSION.md / COMPACT_NOTES.md block, naming the probe path and example invocation, so the agent discovers the capability without reading this rule cold.

## Detector pair list (v1)

Detection is tokenisation-based, twin to `.claude/hooks/supply-chain-scan.sh`. Matches at least one non-flag positional after the verb (otherwise the command is a no-op like `bun install` without args). Pair list:

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

**Extension via env var.** `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="<space-separated globs>"` adds custom runners without modifying the hook. Example: `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="make-test just-check"` accepts `make test` and `just check`. The hook normalises the matched pair to `extra:<glob>` in the `detector` field so audits stay distinguishable from core detections.

The list is deliberately small. The supply-chain capacity proved that strict pair lists with env-var extension beat generous regex fallbacks — the latter consistently leaks false positives (e.g. `cat README | grep test` would match a `*test*` heuristic).

## `last-run.json` schema

Single snapshot, overwritten on every matched capture. JSON shape:

```json
{
  "command": "bun test src/server.test.ts",
  "detector": "bun-test",
  "exit": 1,
  "started_at": "2026-05-11T14:23:10Z",
  "ended_at": "2026-05-11T14:23:12Z",
  "duration_ms": 1830,
  "session_id": "01HZX...",
  "agent_id": null,
  "stdout_head": "bun test v1.2.0...",
  "stdout_tail": "...3 fail, 2 pass\n",
  "stdout_truncated": false,
  "stderr_head": "",
  "stderr_tail": "",
  "stderr_truncated": false
}
```

- `command` — raw `tool_input.command` (no shell rewrite).
- `detector` — pair-list key that matched (`bun-test`, `pytest`, `python-pytest`, `npm-run-build`, `extra:<glob>`, …).
- `exit` — integer from `tool_response.exit_code`. `null` if absent.
- `started_at` / `ended_at` — ISO-8601 UTC. `started_at` from the in-flight mark; `ended_at` is hook-write time.
- `duration_ms` — integer or `null`.
- `session_id` / `agent_id` — pass-through from the hook payload (`agent_id` is `null` for parent edits).
- `stdout_head` / `stdout_tail` — first 4096 bytes / last 4096 bytes of `tool_response.stdout`. When total length ≤ 8192 bytes, `stdout_head` holds the whole stream and `stdout_tail` is `""`.
- `stdout_truncated` — `true` iff clamping engaged (`len > 8192`). Same shape for `stderr_*`.

## Probe output shape

`bash .claude/tools/probe.sh last-run` emits plain text:

```
status: FAIL
command: bun test src/server.test.ts
detector: bun-test
exit: 1
age: 47s
stale: false

--- stdout (head) ---
bun test v1.2.0
...
--- stdout (tail) ---
...3 fail, 2 pass

--- stderr ---
(empty)
```

When the state file is missing:

```
status: no-snapshot
hint: run a recognised verifier (e.g. `bun test`, `pytest`) then re-query with `bash .claude/tools/probe.sh last-run`.
```

The shape is plain text by design — agents read stdout, not structured tool returns, in v1. JSON output is a candidate v2 if MCP promotion happens.

## Escape hatches

- **`CLAUDE_SKIP_RUNTIME_INTROSPECT=1`** — disables both hooks silently. No capture, no probe writes. For throwaway scratch sessions; do NOT set in long-lived shell config (silent permanent disable).
- **`CLAUDE_RUNTIME_INTROSPECT_DEBUG=1`** — opts INTO stderr diagnostic lines from the capture hook (default off — never pollute stderr in normal use). One line per noteworthy event: detector match, write success, tail-clamp engaged. Default is silent because PostToolUse stderr is ingested into the agent's next-turn context (issue #24327) and noise would dilute real signal.
- **`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="<globs>"`** — adds custom pair detections (see § Detector pair list).

Missing `jq`: both hooks fail open (`exit 0`, no capture). The probe tool prints a one-line "jq not found — probe disabled" message and exits 0. A broken dependency must never permanently lock the agent out.

## State file (no audit log)

`.claude/.runtime-state/last-run.json` — single file, gitignored, overwritten on every matched capture. Concurrent matched runs race on `mktemp + mv` semantics; POSIX rename atomicity guarantees no torn writes, and last-writer-wins is the design (snapshot = latest, not history).

In-flight start marks live at `.claude/.runtime-state/in-flight/<tool_use_id>.t` (touched by the pre-mark hook, removed by the capture hook). Stale marks (older than 1h) are not auto-pruned in v1 — disk impact is negligible (one zero-byte file per Bash invocation) and pruning complexity isn't paying for itself yet.

**Deliberate non-feature: no per-Bash audit JSONL.** The supply-chain capacity writes one row per Bash call (including `skip-not-install`) and the well-documented forensic noise that follows (see `.claude/rules/supply-chain.md` § Gotchas). This capacity does NOT mirror that pattern — `last-run.json` is self-sufficient for the "latest evidence" use case the agent has, and adding an audit layer would dilute the signal-to-noise ratio at the same scale. A follow-up spec adds an audit layer if forensic queries become a real need.

## Gotchas

- **`tool_response` truncation risk.** PostToolUse(Bash) carries the captured stdout/stderr in `tool_response`, BUT the harness may truncate large outputs before the hook sees them. The hook's tail clamping happens against whatever reached it — if upstream truncation engages, the snapshot reflects the pre-truncated view, not the original. Mitigation: probe with a known-noisy `bun test` invocation before relying on this; the dogfood pass for spec 011 is partly designed to surface this risk. Long-term fallback (not in v1): read the last assistant message's `tool_result` block from `transcript_path`.
- **Tokeniser drift with supply-chain-scan.** Both hooks tokenise `tool_input.command` with the same separator/value-flag rules. They are currently DUPLICATED with a cross-reference comment, not extracted to `.claude/lib/`. If a third consumer arrives, extract to `tokenize.sh` then — see `.claude/rules/supply-chain.md` § Gotchas ("Package-collection terminators") for the rule set both must keep in sync.
- **`bun run <script>` keyword filter is heuristic.** Captures only when the script name contains `test` / `build` / `typecheck` / `lint`. `bun run dev` (long-running server) is correctly skipped; `bun run frontend:test` is correctly captured; `bun run preflight` (a build-shaped script with a non-keyword name) is SKIPPED. The miss is acceptable — the user can extend via `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` or rename the script.
- **SessionStart hint is one line.** Agents may scan past it. The hint exists for discoverability, not for forced behaviour. Reinforce in `.claude/rules/tdd.md` and PR reviews that the probe is the canonical way for the agent to verify its own work; consider PostToolUse(Edit) nudge as a v2 if dogfood shows under-use.
- **Concurrent Bash capture races.** Two parallel matched commands race the state file write. POSIX rename atomicity → no torn writes; last-writer-wins by design. The in-flight directory keeps per-invocation start marks separate so durations stay accurate even under concurrency.
- **Commit-message FP.** Same shape as the supply-chain "commit messages mentioning compound syntax" gotcha. A heredoc'd commit body containing literal `bun test` would tokenise as a runner. The tokeniser only collects pair tokens at top-level command segments (after `&&` / `||` / `;` separators, not inside quoted strings); reuse of the supply-chain tokeniser shape inherits this protection. Recursive dogfood (committing 011 itself) is the canonical test of this — see `.claude/rules/supply-chain.md` § Gotchas for the precedent fix.
- **No `bun install` / `npm install` capture.** Those are dep mutations, not verifiers — they belong to the supply-chain capacity's scope, not this one. Spec 011 captures *the act of verifying*, not *the act of installing*. Don't add install verbs to the detector list; the FP cost (any install would dilute the "latest test result" semantics) would erase the value.
- **`bun tsc --noEmit` exit code is verifier signal.** TypeScript's `tsc` returns 0 on clean, non-zero on errors — clean PASS/FAIL maps. Don't conflate this with the lint advisory in the validator (see `.claude/validators/run.sh`); this capacity surfaces the latest run, not the validator's per-edit signal.
- **`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` glob shape.** Space-separated globs interpreted as `<tool>-<verb>` keys joined by hyphen (e.g. `make-test` → matches `make test`). Glob meta-chars beyond shell word-split are NOT supported in v1 — keep entries flat. If a fork needs richer matching, extend the parser; until then, prefer multiple flat entries.
- **First-fork friction.** A fresh fork that runs `bun test` for the first time will see no probe hint until session start. The capacity activates the moment the hooks are registered and `bun test` matches the allowlist — nothing in the fork's setup blocks this. The escape hatch (`CLAUDE_SKIP_RUNTIME_INTROSPECT=1`) is the per-session opt-out, not a permanent disable.
