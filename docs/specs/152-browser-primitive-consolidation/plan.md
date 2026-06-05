# 152 — browser-primitive-consolidation — plan

_Drafted from `spec.md` on 2026-06-05. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship one runtime-neutral shell wrapper — `.agent0/tools/agent-browser.sh` — that turns the raw `agent-browser` CLI into an Agent0 **harness primitive** with the operational envelope the meeting demanded: binary/Chrome detection, deterministic primary-vs-fallback routing, a policy-as-file guard, per-command audit logging, and a fail-readable JSON contract. Agents never call the raw binary directly for first-party work; they call the wrapper, which (a) defaults the browser executable to the system Chrome via `AGENT_BROWSER_EXECUTABLE_PATH`, (b) enforces the policy, (c) appends an audit line, and (d) shells through to `agent-browser`. The wrapper is the spine; everything else hangs off it.

Order of build (dependency-correct, TDD where mechanical): (1) the wrapper's pure-logic core — `caps` (detect + pinned-version), `route` (resolve path + reason), policy evaluation, audit emission — each covered by a shell test against fixtures, no browser needed; (2) the browser-touching surface — `run` (policy-gated passthrough) and `verify-contract` (the bounded visual inspection batch + jq asserts) — validated by a **real** `agent-browser` run against a local HTML page; (3) the two dogfood slices run end-to-end (visual-contract against a local screen + fixture-spec; auth-gated against a **synthetic local login server** so the profiles/state path is exercised with zero real credentials and zero human step, reproducibly in CI); (4) the surrounding harness wiring — `doctor.sh` check, `status`/brief surfacing, the new `browser-primitive.md` rule + `browser-auth.md` fallback-positioning update + `runtime-capabilities.md` row, the `CLAUDE.md` managed block, a memory entry, and `harness-sync-baseline.json` registration so the new tracked files propagate correctly.

Resolved open questions (founder delegated, 2026-06-05): **Routing** — agent-browser is default; the MCP fallback fires on exactly three conditions: binary/Chrome absent, a named capability gap (v1 list is empty — agent-browser is a superset; the slot is reserved), or explicit `AGENT0_BROWSER=mcp` override. **Version pin** — a `PINNED_VERSION` constant in the wrapper; `caps`/`doctor` emit a non-blocking advisory on mismatch; bump is a documented one-liner, no cron/refresh routine. **policy-as-file** — default `mode: audit`: read-only and same-origin-interactive actions run audited without confirmation; sensitive/external actions (upload, download, cross-origin navigation, raw `eval`) are blocked unless the host is allowlisted or `--confirm` is passed; everything is logged. **browser-auth.md** — extend, not rewrite: prepend a short "primary path = agent-browser" section + a pointer to `browser-primitive.md`, and re-label the existing Playwright/DevTools content as the documented permanent fallback. **Auth dogfood host** — synthetic local Node http server with a login form + session cookie (no real host, no credentials, CI-reproducible).

## Files to touch

**Create:**
- `.agent0/tools/agent-browser.sh` — the harness wrapper / operational envelope (caps · route · run · verify-contract · policy · audit).
- `.agent0/context/rules/browser-primitive.md` — canonical rule: agent-browser as primary primitive, the routing rule, security posture, opt-in activation.
- `.agent0/browser-policy.yaml` — tracked default policy (mode, allowlist, sensitive_actions); consumer-overridable.
- `.agent0/tests/agent-browser/run-all.sh` + `NN-*.sh` cases — binary-detect/fallback-route, policy deny/allow, audit emission, JSON contract, doctor check, and the two live dogfood runs (guarded to skip-with-advisory if the binary is absent, so CI without the binary still passes the non-live cases).
- `.agent0/tests/agent-browser/fixtures/` — a sample screen HTML + `fixture-spec.json`; the synthetic auth server (`auth-server.js`).
- `.agent0/memory/agent-browser-primitive.md` — project memory entry.
- `docs/specs/152-browser-primitive-consolidation/notes.md` — in-flight design memory (filled during build).

**Modify:**
- `.agent0/tools/doctor.sh` — add agent-browser tri-state check (binary · chrome · pinned version).
- `.agent0/hooks/_brief-compose.sh` (and thereby `status.sh`) — surface agent-browser availability.
- `.agent0/context/rules/browser-auth.md` — position agent-browser as primary, Playwright/DevTools MCP as documented permanent fallback.
- `.agent0/context/rules/runtime-capabilities.md` — record agent-browser as a runtime-neutral CLI primitive.
- `CLAUDE.md` — add the managed-block section (sibling to the other capability sections).
- `.agent0/memory/MEMORY.md` — pointer to the new memory entry (via projection, not raw edit).
- `.agent0/harness-sync-baseline.json` — register the new tracked files so 3-way sync propagates them.
- `.gitignore` — ignore the runtime-state audit dir + agent-browser profiles/state (credential-class).

**Delete:**
- None — permanent-fallback decision means no MCP removal.

## Alternatives considered

### Ship as a `/inspect` skill instead of a `.agent0/tools/` wrapper

Rejected because the meeting redirected away from an inspection-only slice to a full eyes+hands **primitive**, and because a primitive that other skills (`/verify`, `/run`, `/product`, `/sdd`) call is more naturally a tool than a user-facing slash skill. A skill can be added later as a thin front-end; the tool is the load-bearing artifact and must exist first.

### Use `agent-browser install` (Chrome-for-Testing) as the Chrome source

Rejected as the default because the host already has a system Chrome; defaulting `AGENT_BROWSER_EXECUTABLE_PATH` to it avoids a multi-hundred-MB download per consumer and per CI run. `agent-browser install` remains the documented path for environments with no system Chrome.

### Real third-party auth host for the auth dogfood

Rejected — non-reproducible, needs real credentials and a human login, and couples a harness test to an external site's uptime/anti-bot. A synthetic local login server exercises the exact same profiles/state/cookie-reuse code path deterministically.

## Risks and unknowns

- **agent-browser is young (v0.27.1) and fast-moving** — the JSON envelope (`{success,data,error}`) and ref shape were verified empirically this session, but a future version could change them. Mitigation: pin the version, assert the contract in a test, advisory on drift.
- **Daemon lifecycle** — agent-browser runs a persistent daemon; tests must `close --all` between cases to avoid cross-test state bleed. The wrapper exposes a `close` passthrough and the suite tears down.
- **CI without the binary** — the live dogfood cases must skip-with-advisory (not fail) when `agent-browser` is absent, so a fork that hasn't opted in still passes the suite. The non-live logic cases (route/policy/audit/caps) run everywhere.
- **Policy completeness** — "sensitive action" enumeration is a v1 judgment (upload/download/cross-origin-nav/eval); it is documented as extensible in the policy file, not claimed exhaustive.

## Research / citations

- `https://github.com/vercel-labs/agent-browser` + the installed `agent-browser --help` / `skills get core` (v0.27.1) — command surface and the `AGENT_BROWSER_EXECUTABLE_PATH` / `--engine` / `--profile` / `--session-name` / `auth` knobs.
- Empirical probes this session: `snapshot --json` → `{success,data:{origin,refs:{eN:{name,role}},snapshot},error}`; `console --json` → `{success,data:{messages:[]},error}`; screenshot writes a PNG and prints `✓ Screenshot saved to <path>`.
- `.agent0/context/rules/browser-auth.md`, `secrets-scan.md`, `runtime-capabilities.md`, `harness-sync.md`; `.agent0/tools/doctor.sh`, `vuln-audit.sh` (tool idiom); the accepted meeting transcript.
