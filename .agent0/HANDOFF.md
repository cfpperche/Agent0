# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Spec 185 (`harness-evolution-program`) shipped + closed (Claude, Fable 5, 2026-06-09→10).** The 8-point external harness review ran one detailing round per point; all dispositioned: **executed** P4 (rule-corpus discipline adopted: audience test "consumer-facing → rule, else memory or gate"; 3 rules relocated to memory, corpus 39→36, one sync special-case deleted), P7 (CI: `.agent0/tests/run-all-suites.sh` + `.github/workflows/harness-tests.yml`, green in ~3min — first runs caught 4 real defects: stale test, rg dependency, missing skip-guard, SC2034), P8 (doctor `shipped integrity` section verifying executable shipped surface vs sync baseline, advisory-only, suite 5/5); **decided** P2 (Agent0 = personal lab + public showcase; no adoption machinery; reopen on first external interest); **killed** P5 (hook chains measured 7ms/46ms — non-problem), P6 (bash kernel rewrite buys nothing for the operator); **deferred** P1 (evidence bundle — no users yet; ephemerality finding + reopen triggers recorded), P3 (multi-runtime parity stands; Codex re-tier analysis preserved). Full record: docs/specs/185-harness-evolution-program/{tasks,notes}.md.
- **⚡ Tachyon (packages/tachyon/) is shipped and evolving via umbrella spec 187.** v1 (spec 186, `a388732`) + seven shipped children: sidebar increment (`fa59007`), **F1 attention detection** (188, `6dbd6c9`), **F12 stable port + idempotent registration** (189, `f41480b`), **F2 crash lifecycle** (190, `6f3a053`), **F3 Bridge auth** (191, `a4756c0`), **F4 pins & notes** (192, `54db674`), **F13 agent CRUD UI** (193, `25345e3`, closed `2b66f1d`).
- **F13 (latest):** agent CRUD from the sidebar (New/Clone/Rename/Delete/Edit-at-entry) mutating tachyon.yml via comment-preserving yaml Document API; guardrails (rename-while-running refused, last-agent refused, layout cleanup). Suite 114/114 + 14-passing integration. Sequenced BEFORE F9 so per-folder grouping multiplies these actions.
- **F4:** shared human↔agent memory as workspace files (.tachyon/pins.json checklist + notes.md whiteboard); sidebar Pins section with checkboxes; 5 new Bridge tools (12 total: create_pin/list_pins/complete_pin/get_notes/set_notes). Suite now 106/106 vitest + 13-passing integration + live claude -p pins E2E.
- **F3:** Bridge requires `Authorization: Bearer <token>` by default (`settings: {auth: false}` opts out). Token: stable per workspace, extension globalStorage (0600), never in committable files — registrations reference the `TACHYON_BRIDGE_TOKEN` env var (`${VAR}` .mcp.json headers / Codex `bearer_token_env_var` / OpenCode `{env:VAR}` / `mcp-remote --header`); Tachyon injects `TACHYON_BRIDGE_TOKEN`/`TACHYON_BRIDGE_URL` into every session it spawns → agents authenticate with zero manual steps. New command: `Tachyon: Copy Bridge Token`.
- **Validation state (suite as of F3):** 101/101 vitest + 12-passing (1 pending survivor-skip) xvfb host integration + live E2E: real `claude -p` authenticated via `${TACHYON_BRIDGE_TOKEN}` expansion against a tokened Bridge (also proves Claude Code's env-expansion-in-headers works on WSL despite open upstream bug reports). Each child spec has spec-verify pass logged.
- **Dogfood environment prepared** at `~/tachyon-demo/` (outside the repo): `tachyon.yml` (claude/codex/opencode/gemini/shell/fragil agents, layouts, `restart: on-crash` dummy), `.mcp.json` registered with auth header + stable port 41931, `DOGFOOD.md` walkthrough (F1–F4 + F13 scenarios). F5 from the Agent0 window launches it ("Run Tachyon (demo)" config); user validated F1/F2 dogfoods already; F3 dogfood handed off (one ↻ restart of the claude agent needed post-upgrade for env injection).
- Working tree clean; all Tachyon work committed through `2b66f1d`.

## Active Work

- None in flight as code. Umbrella 187 cadence: discuss one F-item → decide (implement/defer/cancel) → ship validated → flip the row.

## Next Actions

- **CI is live:** every push touching harness paths runs all 44 suites (`harness-tests` workflow). If it goes red, fix before continuing — that's the operator-quality bar the maintainer set.
- **Consumer residue from the rule relocation (3 consumers):** stale CLAUDE.md `## Agent0 governance doctrine` section (append-only merge keeps it) + stale copies of the 3 relocated rule files — remove manually on the next sync visit.
- **Next agreed: F9 multi-root (plan discussed in session — 5 phases, Workspace-class extraction first; user is also weighing a Tachyon repo split). Umbrella remaining:** F5 `Tachyon: Init` stack detection (S); F6 CPU/mem monitor (M); F7 publishing kit (S); F8 CI (S); F9 multi-root (M); F10 voice (recommendation: cancel); F11 native Windows PtyBackend (recommendation: defer).
- **F3 small residual (recorded in spec 191 Closure):** OpenCode `{env:VAR}` header substitution not live-driven — verify on first real OpenCode use; mcp-remote fallback documented.
- **Marketplace publishing** remains a human step when desired (publisher `cfpperche` + `vsce publish`; recipe in package README — F7 would polish LICENSE/icon first).
- ~~Audit item 2~~ **DECIDED 2026-06-10:** spec 171 closed as abandoned — the index + on-demand-read context model (no prompt-time injection) is the declared-final design; pause language removed from runtime-capabilities/harness-sync/startup-brief; reopen trigger = a second silent-substitution incident.
- **Consumer sync NOT run** for the rule changes from the earlier audit session (mei-saas/acmeyard/cognixse) — on explicit request only; Tachyon is never synced.

## Decisions & Gotchas

- **Umbrella discipline (187):** every F-item gets its own child spec + explicit decision; no batch approvals. Umbrella table is the source of truth for what's implemented/deferred/cancelled.
- **Tachyon architecture invariants:** tmux on dedicated `-L tachyon` socket is the process source of truth (sessions survive editor restarts); display = native editor-area terminals attached with `-d`; Bridge = stateless streamable-HTTP McpServer per request, loopback only, now Bearer-gated; `packages/` is product land — sync-harness and `.agent0/`/`.claude/` are never touched.
- **tmux exact-target syntax:** `=name` for session targets, `=name:` for pane targets (capture/send/display) — pinned by tests; bit us twice.
- **remain-on-exit semantics (F2):** "session exists" ≠ "process alive" — crash leaves a dead pane (postmortem + `pane_dead_status`), intentional kill removes the session; liveness reads `sessionStates()`. Set globally on the socket inside the same invocation that creates the session (race-free for instantly-dying commands); newSession has a one-shot retry for the server-teardown race.
- **Alt-screen TUIs have no scrollback** — `read_output`'s `lines` degrades to visible capture for them.
- **`@vscode/test-cli` mocha defaults to `tdd` ui** — `describe/it` needs `mocha: { ui: "bdd" }`.
- The secrets-preflight hook blocks compound `git add … && git commit …` — stage and commit in separate Bash invocations.
- Agent0 remains a portable governance/evidence harness; Tachyon is a monorepo product package, not harness capacity.
