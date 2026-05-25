# 011 — runtime-introspect

_Created 2026-05-11._

**Status:** shipped

## Intent

Give the agent runtime evidence about its own work so it can close the edit→verify loop without depending on human ratification or trusting static code alone. The wedge is a generic, stack-agnostic **probe primitive** that captures the last test/build/run command output via a `PostToolUse(Bash)` hook and exposes it through a shell tool the agent can invoke (`bash .claude/tools/probe.sh last-run`). Ships in the same grain as existing Agent0 capacities (hooks + JSONL audit + shell tool, no MCP server in v1); v1 covers Node + Python via a detector allowlist, with plugin shape so Go / Rust / others can be added without touching the core. Complements existing MCPs (Laravel boost, Playwright, DBHub) — does not duplicate them.

## Acceptance criteria

- [ ] **Scenario: test-runner output captured**
  - **Given** the hooks are installed and the project has `package.json` with a `test` script
  - **When** the agent runs `bun test` (or `npm test` / `pnpm test`) via Bash
  - **Then** `.claude/.runtime-state/last-run.json` is created or overwritten with `{command, exit, duration_ms, started_at, stdout_tail, stderr_tail, detector}` and the underlying command's exit code is preserved

- [ ] **Scenario: Python test capture**
  - **Given** the hooks are installed and the project has `pyproject.toml`
  - **When** the agent runs `pytest` (or `python -m pytest`) via Bash
  - **Then** `last-run.json` is written with `detector: "python"` and a non-zero `exit` when the suite fails

- [ ] **Scenario: probe surfaces last failure**
  - **Given** `last-run.json` exists from a failed test command
  - **When** the agent runs `bash .claude/tools/probe.sh last-run`
  - **Then** stdout contains a structured summary (status PASS/FAIL/UNKNOWN, command, exit, age in seconds, stdout/stderr tails) the agent can pattern-match without re-running the test

- [ ] **Scenario: probe flags stale snapshot**
  - **Given** `last-run.json` was written before the current `SESSION_ID`
  - **When** the agent runs `bash .claude/tools/probe.sh last-run`
  - **Then** the summary header includes `stale: true` so the agent knows the evidence is from a prior session

- [ ] **Scenario: capture never blocks the underlying command**
  - **Given** any malformed or unwriteable runtime-state path
  - **When** the capture hook fires
  - **Then** the hook exits 0 silently, the underlying Bash result is unchanged, and a diagnostic line goes to stderr only on opt-in (`CLAUDE_RUNTIME_INTROSPECT_DEBUG=1`)

- [ ] **Scenario: SessionStart hint injected**
  - **Given** the capacity is installed
  - **When** a new Claude Code session starts
  - **Then** the agent's initial context includes one line naming the probe tool path and one example invocation, so it discovers the capability without manual prompting

- [ ] **Scenario: out-of-scope commands ignored**
  - **Given** the agent runs `ls` / `git status` / any command outside the detector allowlist
  - **When** the capture hook fires
  - **Then** no `last-run.json` write occurs and no audit row is emitted (skip silently — runtime-state is for build/test/run signal, not every Bash invocation)

- [ ] `.claude/hooks/runtime-capture.sh` exists and is executable
- [ ] `.claude/tools/probe.sh` exists and is executable
- [ ] `.claude/.runtime-state/` is gitignored
- [ ] `.claude/rules/runtime-introspect.md` documents detection allowlist, probe output shape, env-var escape hatches, and the explicit non-goals
- [ ] `.claude/settings.json` registers the capture hook on `PostToolUse(Bash)` and the hint hook on `SessionStart`
- [ ] Detector allowlist for v1 covers (at minimum): `bun test`, `npm test`, `pnpm test`, `yarn test`, `npm run build`, `pytest`, `python -m pytest`, plus a generic "looks like a runner" fallback when an exact match is missing

## Non-goals

- **Human dashboard / OTel exporter** — observability-for-humans is a separate wedge (see memory `project_visibility_intent.md`). This spec is agent-self-debugging only.
- **Substitute for CI** — CI runs the full suite as a gate; the probe surfaces only the last local snapshot.
- **Cross-session history** — state in `.claude/.runtime-state/` is overwritten, not appended. If the agent wants chronological history, `git log` is the audit trail (commits land tests).
- **Framework-specific introspection** — Laravel-boost, next-devtools-mcp, rails-mcp-server already do this for their stacks; this spec does NOT compete with them. A fork that uses one installs its own `.mcp.json`.
- **Real-time streaming (`tail -f`)** — probe is pull-the-latest-snapshot, not push.
- **Browser introspection** — Playwright MCP and Chrome DevTools MCP are the right tools for DOM/console/network; documented separately in a `.mcp.json.example` follow-up, not built here.
- **PII collection** — capture mirrors stdout/stderr already on the agent's terminal; introduces no new sink. Tails are size-capped (see open questions).
- **MCP server in v1** — promotion to MCP is a follow-up spec if shell-tool friction warrants it; mirrors the delegation-gate evolution path.

## Resolved decisions

Captured here for plan-phase traceability; previously the open-questions block.

- **Tail size cap** — 4 KB head + 4 KB tail per stream (`stdout`, `stderr`). Preserves first/last signal slices and bounds next-turn context cost (max ~16 KB per snapshot). When either stream is ≤8 KB total, store verbatim.
- **Detector allowlist** — strict pair list (`<tool> <verb>` from the v1 table above), with env-var extension `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="<space-separated globs>"` for forks that need custom runners. Matches the supply-chain manager-table grain.
- **Audit log shape** — NO per-Bash audit JSONL. `last-run.json` is self-sufficient. Rationale: avoids the per-Bash noise volume the supply-chain `skip-not-install` rows already produce. If forensic queries surface as a real need, follow-up spec adds it.
- **Dogfood target** — `/home/goat/shrnk` (Bun + TypeScript link-shortener). `bun test`, `bun tsc --noEmit`, `bun run start` exercise the Node-side detector. First 0-finding live-dogfood pass on shrnk graduates v1 toward "delivered"; second pass per yield-decay rule confirms.

## Context / references

- `docs/specs/005-tdd/` — TDD discipline that this probe reinforces. The capacity makes the red→green loop observable to the agent without a human re-running tests.
- `docs/specs/010-audit-forensics/` — sibling capacity for human-side forensics; deliberately distinct goal.
- `.claude/rules/supply-chain.md` — model for shell-tool + hook + audit-log shape; this spec mirrors its grain.
- `~/.claude/projects/-home-goat-Agent0/memory/project_visibility_intent.md` — explicit user intent that frames this wedge as agent-debug-self, not human-dashboard.
- zydrex `laravel-boost` MCP — inspiration; framework-specific predecessor.
- Research session 2026-05-11 — MCP runtime-introspection landscape: [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp), [vercel/next-devtools-mcp](https://github.com/vercel/next-devtools-mcp), [bytebase/dbhub](https://github.com/bytebase/dbhub), [ColeMurray/claude-code-otel](https://github.com/ColeMurray/claude-code-otel). Gap analysis confirmed no mature MCP covers generic local-process test/build capture.
