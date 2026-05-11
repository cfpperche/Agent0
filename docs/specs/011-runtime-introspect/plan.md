# 011 — runtime-introspect — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Three-piece capacity in the same grain as governance / delegation / supply-chain / secrets — hook (capture) + shell tool (probe) + audit-free state file (single-snapshot truth). No new transports, no MCP server, no daemons.

1. **`PostToolUse(Bash)` capture hook** tokenises `tool_input.command` against a strict `<tool> <verb>` detector allowlist (mirroring the supply-chain manager table shape). On a match it parses `tool_response` for `exit`, stdout, stderr, computes duration from `tool_use_id`-keyed start timestamp (cached at `PreToolUse`), clamps each stream to 4 KB head + 4 KB tail, and atomically writes `.claude/.runtime-state/last-run.json` via `mktemp + mv`. Non-matches exit silently with no write. Always exit 0 — capture failure is invisible to the underlying Bash, with one optional stderr diagnostic gated by `CLAUDE_RUNTIME_INTROSPECT_DEBUG=1`.
2. **`.claude/tools/probe.sh`** is a bash + jq script that reads `last-run.json` and emits a structured summary the agent can pattern-match without re-running tests. Subcommand `last-run` is v1's only verb. Computes age from `started_at`, compares against `.claude/.session-state/started-at` to set the `stale` flag, renders explicit head/tail markers on the captured streams. Missing-state path prints a friendly "no snapshot yet — invoke `bun test` (or similar) and re-query" line and exits 0.
3. **`SessionStart` hook** extends the existing `session-start.sh` to append one additional context line naming the probe path and one example invocation. Discoverability without forcing the agent to read `.claude/rules/runtime-introspect.md` cold.

Build order: rule doc draft → RED test suite → capture hook → probe tool → SessionStart hint → settings wiring → `.gitignore` + CLAUDE.md → live-dogfood pass on `/home/goat/shrnk` (Bun + TypeScript link-shortener: `bun test`, `bun tsc --noEmit`, `bun run start`). Yield-decay rule applies — graduate at two consecutive 0-finding passes.

## Files to touch

**Create:**

- `.claude/hooks/runtime-capture.sh` — PostToolUse(Bash) capture hook. Reads stdin JSON, tokenises command, matches detector allowlist, writes `last-run.json` on match. Exit 0 always.
- `.claude/hooks/runtime-pre-mark.sh` — PreToolUse(Bash) companion (tiny, optional). Stamps `started_at` per `tool_use_id` to `.claude/.runtime-state/in-flight/<id>.t` so PostToolUse can compute duration. Skip path if `tool_use_id` is absent.
- `.claude/tools/probe.sh` — shell tool, single `last-run` subcommand in v1.
- `.claude/rules/runtime-introspect.md` — capacity doc: detector table, probe output shape, env-var escape hatches, explicit non-goals, dogfood discipline link.
- `.claude/tests/runtime-introspect/run-all.sh` — driver script (same shape as `.claude/tests/supply-chain/run-all.sh`).
- `.claude/tests/runtime-introspect/01-bun-test-capture.sh` — RED: simulate stdin JSON for a `bun test` PostToolUse, assert `last-run.json` shape.
- `.claude/tests/runtime-introspect/02-pytest-capture.sh` — RED: same for `pytest`.
- `.claude/tests/runtime-introspect/03-skip-non-detect.sh` — RED: `ls -la` produces no state write and no audit row.
- `.claude/tests/runtime-introspect/04-tail-size-cap.sh` — RED: 64 KB stdout collapses to 4 KB head + 4 KB tail with explicit truncation marker.
- `.claude/tests/runtime-introspect/05-stale-flag.sh` — RED: snapshot older than session-started-at flips `stale: true` in probe output.
- `.claude/tests/runtime-introspect/06-never-block.sh` — RED: hook exits 0 even when state dir is read-only.
- `.claude/tests/runtime-introspect/07-probe-missing-state.sh` — RED: `probe.sh last-run` on absent file prints friendly empty-state message, exit 0.
- `.claude/tests/runtime-introspect/08-env-extra-detect.sh` — RED: `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="make test"` enables `make test` capture without touching the core allowlist.

**Modify:**

- `.claude/hooks/session-start.sh` — append one hint line to stdout after the SESSION.md / COMPACT_NOTES.md block when the probe tool exists.
- `.claude/settings.json` — register `runtime-pre-mark.sh` on `PreToolUse(Bash)` and `runtime-capture.sh` on `PostToolUse(Bash)`. Order matters only relative to existing supply-chain entries (theirs runs first, established).
- `.gitignore` — add `.claude/.runtime-state/`.
- `CLAUDE.md` — new § Runtime introspect block (one paragraph, links to the rule doc).

**Delete:** none.

## Alternatives considered

### MCP server in v1

Rejected. Introducing a stdio MCP transport requires either a Node `@modelcontextprotocol/sdk` dependency or a Python `mcp` SDK dependency — neither exists in Agent0 today. Every other capacity is hook-only. Mirroring the supply-chain / delegation / secrets evolution, the shell-tool primitive is the v1 wedge; promote to MCP in a follow-up spec **only if** real friction shows up (agents struggling to discover the Bash invocation, or needing structured tool-call returns instead of stdout parsing). Same path delegation-gate took — and four capacities in, no MCP is needed yet.

### Generous detector fallback (any `*test*` / `*build*` / `*run*`)

Rejected. Would capture `cat README.md | grep test`, `git log --grep build`, `npm run dev` (which is long-lived), and `make run` (which may not produce test signal). False-positive snapshots dilute the signal exactly when the agent needs trust. Strict pair list + env-var extension (`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT`) covers real custom-runner cases like `make test` or `just check` without polluting the default path.

### Rolling N snapshots (history)

Rejected. Cross-session history is an explicit non-goal in `spec.md`. One snapshot is the minimum that closes the edit→verify loop; more snapshots would tempt the agent to scan history instead of just re-running the test. `git log` already serves chronological-history needs when commits land tests (TDD discipline, spec 005). Revisit only if a use case surfaces that needs the prior snapshot specifically.

### Read from `transcript_path` JSONL instead of capturing in-hook

Rejected. Couples the capacity to Claude Code's transcript schema, which has shifted in past releases. Direct in-hook capture from `tool_response` is one-step and format-independent — and PostToolUse hooks already receive the response payload, so the data is in hand. Transcript-read remains a fallback we can wire in if `tool_response` turns out to be unreliable (see Risks below).

### Per-Bash audit JSONL (mirror supply-chain pattern)

Rejected. The supply-chain audit log writes one row per Bash call (including `skip-not-install`), producing 100s of rows per session and well-documented forensic noise (see `.claude/rules/supply-chain.md` § Gotchas — "Audit-log volume on the Bash side is HIGH"). Spec 011's value is the *latest* snapshot, not the history. If forensics is needed later, the follow-up spec adds the audit layer separately rather than co-mingling concerns.

## Risks and unknowns

- **PostToolUse `tool_response` payload shape and truncation.** The plan assumes PostToolUse(Bash) carries the captured stdout/stderr and exit code in `tool_response`. If the harness truncates large outputs before the hook sees them, the in-hook tail clamping happens against pre-truncated data — the snapshot reflects what reached the hook, not what the underlying process actually emitted. Mitigation: probe in a quick test against a known-noisy `bun test` invocation before committing to this approach; if truncated, fall back to transcript-file read or to wrapping the command (rejected for invasiveness — would change the Bash semantics).
- **Tokenizer drift versus supply-chain-scan.** Both hooks tokenise `tool_input.command`. Different drift means a fork pulling one fix won't get the other. Mitigation for v1: duplicate-with-cross-reference comment in both hooks. If a third tokeniser-consumer arrives, extract to `.claude/lib/tokenize.sh` then.
- **`bun run <script>` is wide-open.** `bun run dev` is a long-running server (NOT a verifier) but `bun run test` and `bun run build` are. Plan: detector requires the script name itself to contain `test`, `build`, `typecheck`, or `lint` to match — keyword-allowlist, not free pass. `bun run dev` won't match. `bun run frontend:test` will. Documented in the rule doc + tested.
- **Concurrent Bash invocations.** Two parallel matched runs race on the state file. POSIX rename atomicity means no torn writes, but last-writer-wins. Documented as design intent (snapshot = latest, not all). The in-flight directory (`<tool_use_id>.t` start markers) is per-invocation, not shared.
- **Agent discoverability beyond the SessionStart hint.** One line in additional-context may be ignored mid-session. Mitigation considered (PostToolUse(Edit) nudge to suggest running tests) but deferred — additive in v2 if dogfood shows under-use. The rule doc must explicitly position probe as "the way to check your work without asking the user."
- **Detector noise on commit messages mentioning test runners.** Same shape as the supply-chain "commit message FP" gotcha — a heredoc'd commit message containing literal `bun test` would tokenise as a runner. Mitigation: detector requires the matched pair to be a top-level command segment (after `&&`/`||`/`;` separators, not inside quoted strings). Tokeniser already handles this for supply-chain — reuse the same logic.
- **`bun` is the dogfood target's runtime but the hook runs from any host.** `bun` may not be installed in CI or in another agent's environment. The hook itself doesn't invoke `bun` — it only parses tokens. No runtime dependency on detected binaries. (Tests use stubbed `tool_response` payloads.)

## Research / citations

- `.claude/rules/supply-chain.md` — tokenisation pattern, strict-allowlist + extension-env-var design, audit log shape (the one we are deliberately not duplicating), Gotchas section on tokenisation traps.
- `.claude/rules/delegation.md` — hook-+-audit-grain that this spec mirrors structurally.
- `.claude/rules/secrets-scan.md` — fail-open-on-error pattern, `CLAUDE_SKIP_*` opt-out shape, multi-line OVERRIDE conventions inherited unchanged.
- `.claude/rules/session-handoff.md` + `.claude/hooks/session-start.sh` — the existing additional-context injection point this spec extends.
- `docs/specs/005-tdd/` — TDD discipline that the probe reinforces (red→green loop becomes observable without a human re-running tests).
- zydrex `laravel-boost` MCP (`/home/goat/zydrex/.mcp.json` + `.claude/agents/test-engineer.md`) — framework-specific runtime introspection inspiration. Deliberately not duplicated; capacity is the framework-agnostic complement.
- Anthropic Claude Code hooks reference — [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks) — PostToolUse payload shape (`tool_input`, `tool_response`, `session_id`, `agent_id`, `tool_use_id`).
- Web research session 2026-05-11 (delegated): [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp), [vercel/next-devtools-mcp](https://github.com/vercel/next-devtools-mcp), [bytebase/dbhub](https://github.com/bytebase/dbhub), [ColeMurray/claude-code-otel](https://github.com/ColeMurray/claude-code-otel), [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery), [opentelemetry.io/docs/specs/semconv/gen-ai/](https://opentelemetry.io/docs/specs/semconv/gen-ai/). Gap analysis confirmed no mature MCP covers generic local-process test/build capture — the wedge is real.
