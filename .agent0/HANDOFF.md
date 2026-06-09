# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Spec 186 (`tachyon-vscode-extension`) shipped this session (Claude, Fable 5).** ⚡ Tachyon — a VSCode extension cloning HiveTerm's (hiveterm.com) multi-agent orchestration functionality, re-architected around tmux + native editor-area terminals + an embedded MCP server ("the Bridge"). Lives at `packages/tachyon/` — the **first member of the new monorepo `packages/` tree** (self-contained products, never shipped by sync-harness, never touching `.agent0/`/`.claude/`). Commits: `195a2e4` (spec artifacts), `a388732` (package, 31 files / ~8.3k lines incl. lockfile), plus the closing docs commit after this handoff.
- **Validation evidence:** 58/58 vitest (unit + real-tmux integration: lifecycle, env injection, headless persistence, scrollback) · 7/7 `@vscode/test-cli` host integration under xvfb (activation, real spawn, survivor re-attach without restart, 2up grid via tab groups, watch-restart, Stop All) · **live E2E: a real `claude -p` session connected to the Bridge over streamable HTTP and drove spawn_agent → write_input → read_output (`tachyon-e2e-42` shell-evaluated round-trip) → notify → list_agents** · spec-verify pass logged in notes.md.
- Architecture decisions of record (spec 186 spec.md/plan.md/notes.md): tmux as process source of truth on a dedicated `-L tachyon` socket (sessions survive VSCode restarts — HiveTerm can't do that); display via native terminals (`TerminalLocation.Editor`) attached with `attach -d`; Bridge = stateless streamable-HTTP McpServer per request, loopback only, 7 tools, `maxAgents` guardrail; WSL/Linux/macOS only (native Windows excluded by user decision); nomenclature is Tachyon-original (no hive/bee/queen).
- Previous session's harness audit results remain as documented in git history (`b999412`…`573a07a`); audit verdict: exceptionally healthy.
- **Pre-existing / unrelated dirty state remains untouched:** `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/` (do not stage unless explicitly requested).

## Active Work

- None in flight as code. Spec 186 went idea → reverse-engineering → spec → plan → tasks → implementation → validation → shipped within this session.

## Next Actions

- **Tachyon human steps (optional, user-paced):** (1) try it for real — `cd packages/tachyon && npm ci && npm run build`, open the folder in VSCode, F5 (Extension Development Host), open a workspace with a `tachyon.yml` (see `examples/`); (2) publish when desired — create publisher `cfpperche` at marketplace.visualstudio.com/manage, then `npx vsce login cfpperche && npx vsce publish` (recipe in package README).
- **Tachyon v2 candidates (deferred in spec § Non-goals):** pins/notes checklist, CPU/mem monitor + crash auto-restart, voice input, stack detection, standalone headless Bridge binary, native-Windows `PtyBackend`.
- **Spec 186 small residual:** Codex/OpenCode registration snippets are unit-tested against documented shapes but not exercised against live runtimes — verify on first real use (`mcp-remote` stdio fallback documented in README/snippet).
- **Audit item 2 (user decision, still open):** decide spec 171 (`context-injection-reformulation`, 2/19 tasks, stalled) — resume, re-scope, or formally close. Prompt-time context injection stays paused meanwhile.
- **Audit item 6 / spec 183 residual (optional):** live Codex `/hooks` matcher test (interactive Codex session + `.codex/hooks.json` change — hand the user a copy-paste recipe).
- **Consumer sync NOT run this session** (three shipped rules changed in the previous audit session still pending a `sync-harness.sh --apply` to mei-saas/acmeyard/cognixse on explicit request; Tachyon itself is never synced).

## Decisions & Gotchas

- **`packages/` convention established:** monorepo product packages are self-contained (own package.json/build/tests/README), documented in root README § Packages; sync-harness ignores them. The `mcp-product-pipeline` precedent cited in early spec drafts lives in a *different* repo — Agent0's `packages/` started empty.
- **tmux exact-target syntax differs per command class** (bit us twice): `=name` for session targets (`has-session`, `kill-session`, `attach-session`) but `=name:` (trailing colon) for pane targets (`capture-pane`, `send-keys`, `display-message`). Real-tmux tests pin both shapes.
- **Alt-screen TUIs (Claude Code) have no scrollback** — `capture-pane -S` silently returns just the visible pane for them; `read_output`'s `lines` param degrades gracefully (documented in tool description + README).
- **`@vscode/test-cli` mocha defaults to `tdd` ui** — `describe/it` tests need `mocha: { ui: "bdd" }` in `.vscode-test.mjs`.
- The secrets-preflight hook blocks compound `git add … && git commit …` — stage and commit in separate Bash invocations.
- HiveTerm reconnaissance gotcha: GitHub `trsdn/HiveTerm` is an unrelated Swift/macOS homonym, NOT the hiveterm.com product (which is closed-source Tauri+Rust+React by Ebrahim P. Leite). Feature inventory captured in spec 186 § Context.
- Agent0 remains positioned as a **portable governance/evidence harness for existing coding-agent runtimes**; Tachyon is a product package within the monorepo, not harness capacity (governance doctrine § packages distinction respected — no scope-admission needed since it's not first-party harness surface).
