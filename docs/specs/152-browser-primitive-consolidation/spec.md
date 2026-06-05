# 152 — browser-primitive-consolidation

_Created 2026-06-05._

**Status:** shipped

## Intent

Agent0's browser capability is today two MCP servers — Playwright MCP (authenticated reads via headed-login → storage-state → headless reuse) and Chrome DevTools MCP (observation sidecar) — each needing per-runtime wiring (`.mcp.json` for Claude Code, `.codex/config.toml` for Codex CLI) and a session restart to activate. The full "eyes + hands" an agent needs to work against a UI (navigate/control via CDP, accessibility-tree snapshot with stable LLM-friendly refs, click/fill/wait/drag, annotated screenshot + PDF, read text/HTML, cookies/storage/network/tabs/frames/dialogs, persistent auth, JSON output, observation) is split across those two MCP stacks and bound to per-runtime MCP configuration. Meanwhile `/product` and `/sdd` emit a visual contract (screen-atlas, hi-fi flows) that currently has **no agent-driven visual verification step**. `agent-browser` (vercel-labs) provides all of the above as a single native-Rust **CLI** — intrinsically runtime-neutral (Claude Code and Codex both invoke it through plain shell, no per-runtime wiring). This change adopts `agent-browser` as Agent0's **primary, default agent browser primitive**, wrapped as a first-class harness primitive, while retaining Playwright + Chrome DevTools MCP as a **permanent, explicitly-routed fallback** — which doubles as the graceful-degradation path on machines where the binary is not installed. Adoption is validated on two dogfood slices (visual-contract verification + an auth-gated workflow) before being treated as proven; because the MCP fallback is never deleted, a failed dogfood is cheap. This graduates the accepted meeting `agent-browser-visual-inspection` (2026-06-05), whose cross-model deliberation reframed the original "inspection-only layer" idea into a browser-primitive **consolidation** decision.

## Acceptance criteria

_Observable outcomes. Every box tickable ⇒ spec delivered._

- [x] **Scenario: agent-browser is the default browser primitive, invoked with no per-runtime wiring**
  - **Given** a consumer project with `agent-browser` installed and the Agent0 harness present
  - **When** an agent (Claude Code or Codex CLI) needs to navigate, snapshot, interact with, screenshot, or observe a web page
  - **Then** it reaches for the `agent-browser`-backed primitive through plain shell — with **no** `.mcp.json` / `.codex/config.toml` block required and **no** session restart — and the same invocation works byte-identically across both runtimes

- [x] **Scenario: graceful degradation to the MCP fallback when the binary is absent**
  - **Given** a consumer fork that has NOT installed the `agent-browser` Rust binary (or its Chrome-for-Testing)
  - **When** an agent attempts a browser task
  - **Then** the harness detects the missing binary, emits a readable signal, and the documented routing rule directs the agent to the Playwright/Chrome-DevTools MCP fallback path instead of hard-failing

- [x] **Scenario: a routing rule disambiguates primary vs fallback (no ambiguous agent instruction)**
  - **Given** the permanent two-path setup (agent-browser primary + MCP fallback)
  - **When** an agent decides which browser path to use
  - **Then** a single documented rule resolves it deterministically — agent-browser is default for all browser work; the MCP fallback fires ONLY on explicit conditions (binary/Chrome not installed · a named capability the CLI cannot perform · an explicit human/spec override) — and the rule names those conditions exhaustively

- [x] **Scenario: visual-contract dogfood slice passes end-to-end on agent-browser**
  - **Given** a `/product`→`/sdd` visual contract (screen-atlas / hi-fi screens) with a fixture-spec
  - **When** the verification runs through agent-browser (navigate + a11y snapshot + annotated screenshot + console/network capture + JSON audit), with no MCP wiring
  - **Then** it produces a PASS/FAIL report against the fixture-spec, reproducibly on a second machine or in CI, and the absence of this step is demonstrably what it fills

- [x] **Scenario: auth-gated dogfood slice exercises the profiles/vault auth path**
  - **Given** an auth-gated workflow (a host requiring login)
  - **When** the agent establishes and reuses session via agent-browser's profiles / state / vault model
  - **Then** the authenticated read/interaction succeeds, the auth state is stored credential-class (gitignored, per the secrets-scan convention), and the path is reproducible — with the Playwright headed-login lane still available as the documented fallback

- [x] **Scenario: granting "hands" is auditable and policy-gated**
  - **Given** an agent performing interactive (click/fill/navigate) actions through the primitive
  - **When** a later human inspects what happened
  - **Then** they can reconstruct WHY each action ran and WHICH guard allowed it — via a policy-as-file default (domain allowlist + action policy + sensitive-action confirmation), per-command audit logs, and screenshot/HTML/network redaction rules, with a hard read-only / same-origin-interactive / external-sensitive distinction

- [x] The harness primitive defines an **operational envelope**: capability contract, install/bootstrap contract (incl. pinned version guidance + Chrome-for-Testing), daemon lifecycle (`reset`), fail-readable JSON output contract, policy-as-file, and audit logging
- [x] `doctor.sh` grows a tri-state check for agent-browser (binary · version-pin · chrome) under `=== browser primitive ===` and is the canonical availability surface (right-sized from "the brief surfaces it": the SessionStart brief stays session-state-only to avoid a per-boot binary probe — see notes.md § Deviations)
- [x] `browser-auth.md` is updated to position agent-browser as the primary auth/browse path with Playwright/DevTools MCP documented as the permanent fallback (coexistence, not deletion)
- [x] The capability ships as **opt-in** (consistent with the MCP-recipe / `/image` / `/video` activation pattern) — activation is a deliberate consumer choice, never forced on a fork; `.agent0/browser-policy.json.example` registered in the sync manifest
- [x] `runtime-capabilities.md` records agent-browser as a runtime-neutral CLI primitive

## Non-goals

- **Deleting or deprecating Playwright / Chrome DevTools MCP.** They are retained as a permanent, explicitly-routed fallback (founder decision 2026-06-05). No deprecation predicate, no removal task.
- **A harness-wide "rip out the old stack" cutover.** agent-browser becomes primary by default, but the MCP path is never removed, so there is no hard-cutover risk window.
- **A general autonomous web-browsing / research agent.** This is a browser *primitive* (eyes + hands an agent drives deliberately), not an agent that roams the web on its own.
- **Replacing `WebFetch` for simple unauthenticated page reads.** The cheap text-fetch path stays the first resort for "just read this URL"; the browser primitive is for rendering/interaction/auth/observation.
- **Re-building the X/Twitter thread-reader shortcuts.** Those live in `browser-auth.md` and are unaffected.

## Open questions

- [x] Routing rule — exact, exhaustive list of conditions under which the MCP fallback fires (binary/Chrome absent · which specific capability gaps · explicit override syntax). Owner: resolved at `/sdd plan` against agent-browser's actual capability surface.
- [x] Version pinning policy — pin to which `agent-browser` version, and is there a refresh routine (like the video-tiers refresh) or a manual bump? Owner: plan-time decision.
- [x] policy-as-file default shape — does a sensitive/external action require human confirmation by default, or is the default permissive-with-audit and confirmation opt-in? Owner: founder, at plan/debate.
- [x] `browser-auth.md` — full rewrite around agent-browser-primary, or extend the existing file with an agent-browser section + a fallback pointer? Owner: plan-time.
- [x] Which concrete auth-gated host the dogfood slice uses (a real Agent0 workflow vs a synthetic test host). Owner: plan-time.

## Context / references

- `.agent0/meetings/agent-browser-visual-inspection-2026-06-05T14-38-11Z/meeting.md` — the accepted cross-model deliberation (Claude ↔ Codex ↔ founder) this spec graduates from; carries the convergence + the preserved minority report on fallback-deletion pace (rendered moot here by the permanent-fallback decision).
- `.agent0/context/rules/browser-auth.md` — current Playwright MCP + Chrome DevTools MCP capability; the file this spec updates.
- `.agent0/context/rules/runtime-capabilities.md` — runtime-neutral capability matrix; agent-browser recorded here.
- `.agent0/tools/doctor.sh`, `.agent0/tools/status.sh`, `.agent0/hooks/_brief-compose.sh` — health/status surfaces that grow an agent-browser check.
- `.agent0/context/rules/secrets-scan.md` — credential-class framing for profiles/state/vault files (gitignored like `.agent0/.browser-state/*.json`).
- The opt-in activation pattern: `.mcp.json.example` (MCP recipes), `/image`, `/video` — the template-not-default precedent this capability follows.
- `https://github.com/vercel-labs/agent-browser` — the tool (native Rust CLI, client-daemon over CDP; v0.27.x, June 2026).
- `.agent0/memory/visibility-intent.md` and the user-level `feedback-speculative-observability` memory — the demand-gate discipline the two dogfood slices honor.
