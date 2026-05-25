# 021 — browser-auth-workflow

_Created 2026-05-12._

**Status:** shipped

## Intent

Agent0 ships browser MCP recipes since spec 012 (Playwright, Chrome DevTools), but does not document the workflow for reading auth-gated sites — when to use which MCP, how to bridge the login with the human in the loop, where to store session state, and what convention the agent uses to signal "I need you to log in now." The gap surfaced when the agent was asked to read an X/Twitter thread: `WebFetch` hit HTTP 402 (X requires login since 2023), the public Nitter network is dead in 2026, and there was no documented fallback. This spec closes that gap. It picks **Playwright MCP as the default** for routine authenticated access (headed-login → save `storageState.json` → headless reuse), keeps **Chrome DevTools MCP as a debug-only layer** (paired with `--user-data-dir` profile; NOT `--autoConnect` by default — too broad a security surface), standardizes a per-host state directory at `.claude/.browser-state/<host>.json` (gitignored, project-local, never propagated by the harness sync), and adopts a **chat-only signaling convention** — `BROWSER_AUTH_REQUIRED: <host>` — for the agent to ask the human to do the login step. As a low-cost special case, the spec also documents `unrollnow.com/status/<id>` as the X/Twitter unrolled-thread shortcut to try before invoking the full auth workflow. Pure documentation + convention + one `.gitignore` entry + one cross-reference; no new hook, no new MCP, no new tool.

## Acceptance criteria

- [x] **Scenario: agent encounters auth-gated site without saved state**
  - **Given** a fork with Playwright MCP recipe enabled and no `.claude/.browser-state/<host>.json` for the target host
  - **When** the agent attempts to read a URL on that host and the page redirects to a login or returns 401/403/402
  - **Then** the agent emits `BROWSER_AUTH_REQUIRED: <host>` to the chat with a one-line next-step pointing at `.claude/rules/mcp-recipes.md § Authenticated workflow`, and does not retry the same host until the human signals the state was saved

- [x] **Scenario: agent reuses saved storage state**
  - **Given** `.claude/.browser-state/<host>.json` exists for the target host
  - **When** the agent invokes Playwright MCP with that storage state and navigates to the host
  - **Then** the page loads as authenticated without prompting the human

- [x] **Scenario: X/Twitter unrolled-thread shortcut**
  - **Given** the agent needs to read a public X/Twitter status URL of the form `x.com/<user>/status/<id>` (or `twitter.com/...`)
  - **When** `.claude/.browser-state/x.com.json` does not exist
  - **Then** the agent first tries `https://unrollnow.com/status/<id>` via `WebFetch`; only on empty/failed response does it fall back to the `BROWSER_AUTH_REQUIRED` signal

- [x] **Scenario: Chrome DevTools MCP recommendation positioning**
  - **Given** a fork enabling browser auth for the first time
  - **When** the developer reads `.claude/rules/mcp-recipes.md`
  - **Then** Playwright is presented as the default for routine authenticated reads and Chrome DevTools is presented as the debug-only complement (perf / network observation), with `--autoConnect` explicitly NOT recommended as default

- [x] `.claude/.browser-state/` exists as a directory with a `.gitkeep` sentinel committed, so the bucket ships to forks; `.claude/.browser-state/*.json` is gitignored
- [x] `.gitignore` includes a `.claude/.browser-state/*.json` (or `!.gitkeep`-style) entry that excludes state files but keeps the sentinel
- [x] `.claude/rules/mcp-recipes.md` gains an `## Authenticated workflow` section documenting the Playwright `headed → save → reuse` lifecycle with concrete commands and the `BROWSER_AUTH_REQUIRED: <host>` signaling phrase
- [x] `.claude/rules/mcp-recipes.md` § Chrome DevTools is updated to position it as debug-only (paired with `--user-data-dir`), and explicitly flag `--autoConnect` as opt-in with a security note
- [x] `.claude/rules/secrets-scan.md` cross-references `.claude/.browser-state/*.json` as credential-class files (cookies + localStorage = session credentials)
- [x] `CLAUDE.md` gains a one-paragraph `## Browser auth` capacity section summarizing the workflow and pointing at the rule doc — same shape as existing capacity sections
- [x] `.claude/tools/sync-harness.sh` manifest is **unchanged** — `.claude/.browser-state/` is project-local and must NOT be in the sync scope (verified by re-reading the COPY_CHECK arrays after the change)
- [x] No new hook, no new MCP server install, no new env var, no new audit log

## Non-goals

- **API-based per-service MCPs** (Twitter MCP via OAuth, GitHub MCP, Slack MCP). They are orthogonal and per-service; this spec is about generic browser-driven access. A fork that needs Twitter posting installs the Twitter MCP separately.
- **A new MCP server or hook.** Pure documentation + convention + gitignore. If we ever need a `BROWSER_AUTH_REQUIRED` machine-readable signal, that is a follow-up spec.
- **GUI-based human-in-the-loop signaling** (e.g. the Human-In-the-Loop MCP Server). Deferred; chat-only is sufficient per user direction in this session. Revisit if long-running unattended runs surface friction.
- **Multi-profile / multi-persona separation.** One storage-state file per host in v1. A fork that needs `host as user-A` vs `host as user-B` extends this in their own rule doc.
- **Proactive expiry / refresh of storage state.** Agent learns the state is expired from the 401/403/login-redirect post-hoc and re-emits `BROWSER_AUTH_REQUIRED`. No background refresh, no TTL field.
- **Reading paywalled content where the human is not entitled.** The workflow assumes the human has a valid subscription/account. Bypassing paywalls is out of scope and contra license.
- **Modifying `.claude/tools/sync-harness.sh`** scope. The `.claude/.browser-state/` directory must remain invisible to the sync tool — credentials are project-local by definition.
- **Bundled helper script `.claude/tools/browser-state.sh`** (save / list / expire). Playwright MCP already exposes `browser_storage_state` / `browser_set_storage_state`; a thin wrapper adds drift surface without commensurate value. Revisit only if dogfood surfaces real friction.

## Open questions

_All resolved during implementation (2026-05-12). Retained as historical record._

- [x] **Exact form of `BROWSER_AUTH_REQUIRED: <host>` signal.** **Resolved:** human-readable phrase, prefix `BROWSER_AUTH_REQUIRED: <host>` followed by a 3-line template (`Next step:` instruction + rule-doc pointer). JSON / machine-parseable alternative rejected — agents grep the prefix; a later spec can add a structured channel if needed.
- [x] **`.gitkeep` shipping decision.** **Resolved:** yes, shipped. `.claude/.browser-state/.gitkeep` committed in parallel with spec 019 amendment's `.claude/memory/.gitkeep`.
- [x] **Worked example of saving X/Twitter state in the rule doc.** **Resolved:** yes. The rule doc uses `x.com.json` as the canonical example throughout the storage-state section and in the signal example block. The example is about filename + save-command convention (robust to changes in X's login flow), not the login flow itself.
- [x] **Cross-fork propagation via sync-harness.** **Resolved:** automatic. All five modified files (`.claude/rules/mcp-recipes.md`, `.claude/rules/secrets-scan.md`, `.claude/tools/sync-harness.sh`, `.gitignore`, `CLAUDE.md`) are already in the sync-harness scope. Forks adopt by `git pull` upstream + next `bash .claude/tools/sync-harness.sh --apply`. No spec-side action needed.

## Context / references

- `.claude/rules/mcp-recipes.md` — existing Playwright + Chrome DevTools recipes (this spec extends, does not rewrite)
- spec 012 (`docs/specs/012-mcp-recipes/`) — original recipe set + stack detection
- spec 019 amendment (`.claude/memory/.gitkeep`) — pattern for shipping an empty bucket scaffold to forks
- spec 007 (`docs/specs/007-secrets-scan-timing/`) and `.claude/rules/secrets-scan.md` — credential-class file mindset; `.browser-state/*.json` fits the same class
- spec 016 (`docs/specs/016-harness-sync/`) — sync-harness scope (`.claude/.browser-state/` must remain out of COPY_CHECK)
- User chat 2026-05-12 — Playwright default + Chrome DevTools debug + chat-only signaling direction
- Sources consulted (full list in `plan.md` § Research / citations): Playwright MCP storage docs, Chrome DevTools MCP profile guide (Scalified, raf.dev), Simon Willison's TIL on Playwright MCP, Nitter 2026 status
