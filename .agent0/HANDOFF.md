# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-05 — spec 153 `decouple-harness-from-playwright` BUILT + VALIDATED via `/squad`, `ready_for_human_prod` (UNCOMMITTED on branch `153-decouple-harness-from-playwright`).** Founder follow-up to spec 152: the harness now depends on `agent-browser` **exclusively** — Playwright/Chrome-DevTools MCP survive ONLY as opt-in `.mcp.json.example`/`.codex/config.toml.example` templates, never a fallback the routing or any first-party skill degrades to. Flow: `/meeting` (Codex validated + hardened the scope — "coupling is in CODE, not just prose", `synthesis: accepted`) → `/sdd refine` (all 4 OQs resolved at plan time, 0 follow-ups) → **`/squad`** autonomous build (Claude↔Codex ping-pong, 4 bands), `ready_for_human_prod` at round 8, **repair_attempts 0**.
  - **What changed (27 files):** `agent-browser.sh` `route` is fail-closed (`primary`|`unavailable:{no-binary,no-chrome,mcp-removed}`; explicit cmds `run`/`verify-contract`/`audit`/`adopt` → rc 4, or rc 3 for the removed `AGENT0_BROWSER=mcp` override — **no MCP lane**); `audit` gained `--structure strict|optional` (strict = unchanged 152.1 gate; optional = h1/main advisory for fragments) + responsive 375/1280 screenshots & `scrollWidth>clientWidth` overflow fields (via a fixed internal `eval`). `/product` Phase 4 now sweeps hi-fi via `agent-browser.sh audit --structure optional` over `file://` (no `.mcp.json` seed, no HTTP server, loud skip when unavailable). `browser-auth.md` rewritten agent-browser-native (`browser-login.sh`→`adopt`; signal renamed `BROWSER_AUTH_REQUIRED`→**`BROWSER_LOGIN_REQUIRED`**; state at `.agent0/.runtime-state/agent-browser/state/<host>.json`). `serve-hifi.sh` deleted. `.browser-state/` scaffold retired (manifest/README/gitignore). Converted: `browser-primitive.md`, `runtime-capabilities.md`, `secrets-scan.md`, `doctor.sh`, `context-inject.sh`, `CLAUDE.md`+`AGENTS.md` (managed blocks, parity), `site/i18n/capacities.ts`. New `08-no-mcp-coupling.sh` grep-guard + `02`/`04` rewritten + `12` extended.
  - **Validated:** agent-browser suite **GREEN incl. live dogfood** (`run-all.sh`), harness-sync **42 PASS** (templates byte-stable — `11`/`35` green), validator + doctor (rc 0, no MCP remedy). Squad gate green; both agents propose-done. **Codex's adversarial review caught a real gap** — `adopt` was missing the fail-closed guard (AC#1 names it) → repaired + tested (`04-audit` 16/0). The 151-F2 peer-review value, realized.
  - **Predecessors 152/152.1/152.2 shipped + committed** (`f31e6b8`+`ef6b815`). Live new-mechanism auth state (`{github,x,linkedin}.json`) exists, gitignored.

_Prior — 149/149.1/150.x + 151 + 152.x shipped (harness arc + browser primitive); see git log._

## Active Work

- **Spec 153 is on branch `153-decouple-harness-from-playwright`, UNCOMMITTED working tree** (squad `ready_for_human_prod`). The squad PREPARED; the **human triggers production** (commit the implementation + merge to `main`). Planning baseline already committed (`cd670d0`); the 27-file implementation is staged-ready in the working tree.
- **One HUMAN-GATED residue item:** the OLD Playwright credential files `.agent0/.browser-state/{linkedin.com,x.com}.json` (May 12, superseded by the validated new-mechanism `state/{github,x,linkedin}.json`) — kept gitignored, NOT auto-deleted. Awaiting founder go to delete the dir. (Squad `forbidden_paths` blocked any agent from touching them.)

## Next Actions

1. **Human: commit + merge spec 153** (the squad's prepared change set on branch `153-decouple-harness-from-playwright`) → `main`, then set spec `Status: shipped`.
2. **Human decision: delete the stale `.agent0/.browser-state/` credential dir?** (recommended — superseded + re-login is one `browser-login.sh` command).
3. **`/meeting` (deferred follow-up #2 to 152):** incorporate visual contracts into SDD + the delegation gate, where pertinent — treat a `verify-contract`/`audit` pass as a UI-task acceptance artifact. Scope the "UI-producing" trigger so it doesn't over-gate.
- `/squad` worktree-per-agent (v2) remains noted in `rules/squad.md`, unbuilt — no demand yet.

## Decisions & Gotchas

- **agent-browser daemon/port gotchas (in `.agent0/memory/agent-browser-primitive.md`):** `close --all` HANGS with no daemon (wrapper `reset` guards it); global daemon ignores `--profile`/`--state` if up (`reset` or isolated `--session`); kill by argv0 (`agent-browser-linux*`), NEVER `pkill -f agent-browser` (self-kill, exit 144). JSON envelope `{success,data,error}`; `eval --json` → `.data.result`. Pinned 0.27.1.
- **Routing is now fail-closed (spec 153 — reverses 152's permanent fallback):** `route` → `primary` | `unavailable:{no-binary,no-chrome,mcp-removed}`; explicit commands fail closed (rc 4; rc 3 for the removed mcp override). NO MCP lane in the wrapper. The `08-no-mcp-coupling.sh` grep-guard + the squad gate's inline grep prevent reintroduction.
- **`/squad` operational lessons (this run):** the default `squad.json.example` `forbidden_paths` pattern `"secrets"` is too broad — it matches `secrets-scan.md`; spec 153's contract uses `(^|/)secrets?/` + `\.secrets?(\.[^/]+)?$` instead. Codex's Stop hook repeatedly rewrites `.agent0/HANDOFF.md` (a forbidden path) at turn close — the orchestrator must `git checkout -- HANDOFF.md` after each Codex turn and re-baseline. Out-of-turn edits (even reverts) trip `aborted_conflict`; recover with a no-op re-baseline turn (turn-start→turn-end captures the current tree as the boundary with empty delta).
- **Removing a `.gitignore` line for a dir that still holds gitignored credential files UN-hides them** (they become untracked/stageable) — keep the retired `.browser-state/` dir gitignored until it's physically deleted.
