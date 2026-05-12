# 021 — browser-auth-workflow — plan

_Drafted from `spec.md` on 2026-05-12. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Pure documentation + convention + one gitignore entry. Zero new hooks, zero new MCP servers, zero new env vars, zero new audit logs. The capacities required (Playwright MCP, Chrome DevTools MCP) already ship as recipes from spec 012; what's missing is the workflow that tells the agent and the human how to operate them together when a site requires auth. So the spec ships as five surgical edits plus one new directory scaffold.

Order of operations: (1) gitignore + `.claude/.browser-state/.gitkeep` so the bucket exists and credentials never land in git; (2) `.claude/rules/mcp-recipes.md` gains a `## Authenticated workflow` section (after the existing `## Activation workflow`) that documents the Playwright `headed → save → reuse` lifecycle with concrete commands, the `BROWSER_AUTH_REQUIRED: <host>` signaling convention, and the `unrollnow.com/status/<id>` X/Twitter shortcut; (3) the existing `### Chrome DevTools MCP` recipe entry is updated to position it as debug-only and flag `--autoConnect` as opt-in with a security note; (4) `.claude/rules/secrets-scan.md` § Gotchas (or a new short cross-reference paragraph) names `.claude/.browser-state/*.json` as credential-class; (5) `CLAUDE.md` gains a one-paragraph `## Browser auth` capacity section inserted between `## Memory` and `## Compact Instructions`. The harness sync manifest is **explicitly not touched** — verified by reading the COPY_CHECK arrays after the edits land. No `.mcp.json.example` change is needed since both recipes are already in it; the workflow doc references them.

Shape rationale: the existing rule docs (`mcp-recipes.md`, `secrets-scan.md`) are the right home for both the operational workflow and the credential-class reminder. Splitting browser-auth into its own `.claude/rules/browser-auth.md` was considered (see Alternatives) and rejected — it would fragment what is essentially one concern across two rule docs and weaken the MCP-recipes-as-authoritative-reference property the existing doc carries.

## Files to touch

**Create:**
- `.claude/.browser-state/.gitkeep` — empty sentinel so the directory ships to forks (same pattern spec 019 amendment used for `.claude/memory/.gitkeep`); agent + developer discover the bucket exists without reading docs first

**Modify:**
- `.gitignore` — add `.claude/.browser-state/*.json` line in the "Ephemeral state under .claude/" section (existing block at lines 6-16). The `.gitkeep` sentinel is preserved automatically since the glob targets `*.json` specifically.
- `.claude/rules/mcp-recipes.md` — (a) add `## Authenticated workflow` section after `## Activation workflow` (line 168) with the Playwright lifecycle, the `BROWSER_AUTH_REQUIRED: <host>` signaling phrase, the X/Twitter `unrollnow.com` shortcut, and a sub-section flagging when Chrome DevTools is the better choice; (b) edit `### Chrome DevTools MCP` (within `## Recipes`, line 27 onwards) to add a one-paragraph positioning note: debug-only complement to Playwright; `--autoConnect` is opt-in with a security note pointing at the new section.
- `.claude/rules/secrets-scan.md` — add `.claude/.browser-state/*.json` to the § Gotchas list (or a brief new paragraph) as credential-class files (session cookies + localStorage = the same blast radius as a leaked password)
- `CLAUDE.md` — insert `## Browser auth` capacity section between line 65 (`## Memory`) and line 69 (`## Compact Instructions`). One paragraph in the same shape as `## MCP recipes`: names the capacity, names Playwright as default + Chrome DevTools as debug, names the storage-state path, names the `BROWSER_AUTH_REQUIRED:` signal, points at `.claude/rules/mcp-recipes.md § Authenticated workflow`.

**Delete:**
- _none_

**Verify (no changes — must remain unchanged):**
- `.claude/tools/sync-harness.sh` — the `COPY_CHECK_RECURSIVE`, `COPY_CHECK_GLOBS`, `COPY_CHECK_FILES` arrays must NOT reference `.claude/.browser-state/`. Verified by re-reading the file after spec 021 edits land; documented in the verification task.
- `.claude/settings.json` — no new hook registration; the capacity is doc-only.
- `.mcp.json.example` — both recipes (`playwright`, `chrome-devtools`) are already present; the workflow documentation reuses them as-is.

## Alternatives considered

### Dedicated `.claude/rules/browser-auth.md`

Rejected because the workflow IS the operational documentation of two recipes that already live in `mcp-recipes.md`. Splitting it would create two rule files that have to be read together to understand a single concern; cross-references would multiply; future updates would need to remember to touch both. The existing `mcp-recipes.md` doc is already structured as "per-MCP reference + activation + hint output", so an `## Authenticated workflow` section fits its scope naturally. If a future spec adds a non-MCP browser auth path (e.g. an HTTP cookie jar managed via a hook), THAT might warrant a separate file.

### A new MCP server wrapping Playwright + auth orchestration

Rejected because Playwright MCP already exposes `browser_storage_state` (save) and `browser_set_storage_state` / `--storage-state` (load). A wrapper would add a process layer, a maintenance surface, and a version-skew problem against Playwright MCP's own evolving tool names. The friction the spec addresses is **agent-doesn't-know-the-workflow**, not **the-tools-are-missing**. Docs are the right fix.

### Human-In-the-Loop MCP Server for GUI pop-up signaling

Rejected for v1 per direct user choice in this session: chat-only signaling is sufficient and adds zero new dependencies. The GUI-pop-up option is real (`GongRzhe/Human-In-the-Loop-MCP-Server`) and may be the right call later if long-running unattended runs surface friction — but it adds a dependency, a display-server requirement (WSL2 needs WSLg), and a second signaling channel competing with chat. Revisit only after empirical evidence that chat-only fails.

### Chrome DevTools `--autoConnect` to the user's main Chrome as the default workflow

Rejected because `--autoConnect` exposes EVERY open tab and EVERY active session to the agent in one move. The blast radius (Gmail, banking, internal tools, social) is catastrophic if a malicious or buggy prompt causes the agent to take an action in the wrong tab. The dedicated `--user-data-dir` profile keeps the surface bounded: the agent only sees what the human deliberately logged into in the dedicated profile. The convenience win of `--autoConnect` does not pay for the security loss as a DEFAULT — forks that consciously want it can opt in.

### Hook-based blocking signaling (PreToolUse blocks WebFetch / browser tool calls until a sentinel file exists)

Rejected for v1 because (a) we have no canonical list of "auth-required hosts" — many sites work fine without auth; gating ALL navigation would be wrong, gating selectively requires a registry that doesn't exist; (b) the signal `BROWSER_AUTH_REQUIRED: <host>` in chat is what humans actually need to act on, and it works without any new hook. A hook adds determinism but also rigidity and a new failure mode (hook misfires → agent stuck). The doc + chat convention is the lighter shape; hook-based gating is a candidate v2 if the chat convention proves unreliable.

### A bundled helper script `.claude/tools/browser-state.sh save|list|expire <host>`

Rejected because it would be a thin bash wrapper over Playwright MCP's own `browser_storage_state` / `browser_set_storage_state` tools. Forks invoke the MCP tools directly via the agent; the wrapper adds maintenance surface (drift against Playwright MCP's evolving tool names, path-quoting bugs, etc.) without commensurate value. Revisit only if dogfood surfaces real friction with the raw MCP tool ergonomics.

### Skip the X/Twitter `unrollnow.com` shortcut entirely

Rejected because the shortcut is the lowest-cost path for a common case (the agent literally just hit it). One paragraph in the rule doc + one acceptance scenario costs nothing; the win is "agent reads public X threads without ever invoking Playwright." Risk that unrollnow.com dies is real but the fallback is the same `BROWSER_AUTH_REQUIRED:` path — graceful degradation by design.

## Risks and unknowns

- **Agent compliance with the chat convention.** The `BROWSER_AUTH_REQUIRED: <host>` phrase is only useful if future agent invocations actually emit it instead of silently retrying or giving up. Mitigation: the convention lives in (a) `.claude/rules/mcp-recipes.md § Authenticated workflow` (explicit), and (b) `CLAUDE.md § Browser auth` (auto-loaded into every session). Two reinforcement points should be enough; if dogfood shows agents fail to emit the signal, escalate to a `PostToolUse(WebFetch)` advisory hook in v2.
- **Storage-state expiry handling.** Sites rotate session tokens; `.claude/.browser-state/<host>.json` will eventually be stale. The agent must recognize 401/403/login-redirect as "state is expired" and re-emit the signal rather than retry blindly. Documented explicitly in the new rule section, but it's a discipline, not enforcement. Mitigation: a worked example in the rule doc showing the expired-state pattern.
- **`unrollnow.com` is a single point of failure.** If the service disappears, the X/Twitter shortcut breaks. Mitigation: shortcut is best-effort (try-then-fall-back); main path is unaffected. Optionally name an alternative (`threadreaderapp.com`) in the rule doc as a backup.
- **Forks already using `chrome-devtools --autoConnect`.** They will not be auto-migrated. The updated recipe text is a recommendation, not a forced change. Acceptable — forks made an explicit `.mcp.json` choice and we respect it; the new doc shapes future enablement, not retroactive enforcement.
- **`.claude/.browser-state/.gitkeep` shipping decision.** Spec 019 amendment shipped `.claude/memory/.gitkeep` so forks get the bucket. Same pattern here means `.gitkeep` is committed. Open question in spec.md; decision in tasks: yes ship it (parity with spec 019 amendment).
- **Sync-harness scope verification is a passive check.** Adding `.claude/.browser-state/` to a `COPY_CHECK_*` array is a one-line mistake that could happen in a future PR if a maintainer thinks "all `.claude/` paths sync." Mitigation: add an explicit "out-of-scope" comment in `sync-harness.sh` near the manifest arrays naming `.claude/.browser-state/` (and `.claude/memory/`) as project-local. Cheap forensic protection.
- **gitleaks does not scan storage-state JSON as a credential by default.** A fork that runs `gitleaks detect` over a deliberately uncommitted `.browser-state/*.json` (e.g. via a wrapper script) won't get an alert. Mitigation: the gitignore is the primary defense; the secrets-scan.md cross-reference is doc-level awareness, not engine-level enforcement. Acceptable — the file shouldn't be in git in the first place.
- **Browser MCP package-name churn.** Playwright MCP and Chrome DevTools MCP are early-stage; commands and tool names may evolve. The rule doc cites both upstream READMEs as source-of-truth. Same caveat as the existing `mcp-recipes.md § Gotchas` ("Package-name drift") — no new failure mode introduced.

## Research / citations

Sources consulted during this session's research pass (2026-05-12):

- [Playwright MCP — Storage & Authentication](https://playwright.dev/mcp/tools/storage) — `browser_storage_state` / `browser_set_storage_state` tool reference; the contract this workflow standardizes on
- [Playwright MCP — Profile & State](https://playwright.dev/mcp/configuration/user-profile) — `--persistent` vs `--storage-state=<file>` vs `--isolated` configuration; underpins the headed-login → headless-reuse pattern
- [Using Playwright MCP with Claude Code — Simon Willison's TILs](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code) — practical workflow notes; reinforces the headed-mode-for-login pattern
- [Chrome DevTools MCP — GitHub](https://github.com/ChromeDevTools/chrome-devtools-mcp) — official upstream; `--autoConnect` behavior and security considerations
- [Automating Authenticated Websites with Chrome DevTools MCP and Claude Code — Scalified blog](https://scalified.com/blog/chrome-devtools-mcp-authentication) — `--user-data-dir` dedicated profile setup
- [How to Set Up Chrome DevTools MCP with Claude Code to Automate Websites That Need Authentication — raf.dev](https://raf.dev/blog/chrome-debugging-profile-mcp/) — same `--user-data-dir` pattern from a different angle, with security framing
- [Nitter Alternatives 2026 — Simple Web](https://simple-web.org/guides/nitter-alternatives-2026-view-twitter-x-timelines-anonymously) — establishes that Nitter is no longer a viable general fallback in 2026; informs the "MCP-based auth is the right path" choice
- [UnrollNow — Free Twitter Thread Reader](https://unrollnow.com/) — verified live during this session by successfully fetching the trigger thread; basis for the X/Twitter shortcut acceptance scenario
- [Human-In-the-Loop MCP Server — GongRzhe](https://github.com/GongRzhe/Human-In-the-Loop-MCP-Server) — documented as the v2 candidate for GUI-based signaling; explicitly deferred per user choice

Internal references:

- `docs/specs/012-mcp-recipes/` — the parent spec that introduced the Playwright + Chrome DevTools recipes this spec extends
- `docs/specs/019-project-memory/` (amendment) — pattern precedent for shipping an empty bucket scaffold (`.gitkeep`) to forks
- `docs/specs/016-harness-sync/` — defines the manifest arrays that this spec's directory must remain absent from
- `docs/specs/007-secrets-scan-timing/` and `.claude/rules/secrets-scan.md` — defines the credential-class file mindset that `.browser-state/*.json` joins
- `.claude/rules/mcp-recipes.md` — the rule doc this spec extends with `## Authenticated workflow`
- This session's conversation with the user (2026-05-12) — direction selections: Playwright default + Chrome DevTools debug; chat-only signaling
