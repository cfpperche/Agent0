# 153 — decouple-harness-from-playwright

_Created 2026-06-05._

**Status:** shipped

## Intent

Spec 152 made `agent-browser` the **primary** browser primitive but kept Playwright / Chrome DevTools MCP as a **permanent fallback the harness routing degrades to** (`fallback:{no-binary,no-chrome,override}`). The founder's follow-up intent (2026-06-05, scoping meeting `descacoplar-harness-agent0-do-playwright`) reverses that convergence deliberately: make the Agent0 harness depend on `agent-browser` **exclusively** for every browser-driven capability — visual contracts AND auth-gated reads. Playwright / Chrome DevTools MCP survive **only** as opt-in `.mcp.json.example` / `.codex/config.toml.example` templates a consumer may wire up by hand; **no first-party harness code path drives, observes, or degrades to MCP.** This removes a hidden second browser stack from the harness contract (one primitive to maintain, test, and reason about) and makes "exclusive dependency" true in code, not just in prose. The coupling is in executable code + tests, not only rule docs (Codex's independent sweep, meeting Turn 2) — so this is a code change with doc follow-through, not a doc edit.

## Acceptance criteria

- [ ] **Scenario: explicit browser command with agent-browser unavailable fails closed**
  - **Given** `agent-browser` is unavailable (binary absent, or `AGENT0_BROWSER_NO_CHROME=1`)
  - **When** an explicit browser command runs — `agent-browser.sh run` / `verify-contract` / `audit` / `adopt`
  - **Then** it exits non-zero (rc 4) with an actionable message pointing at install / `doctor` / `caps`, and **never** routes to an MCP fallback

- [ ] **Scenario: no MCP routing lane remains in the wrapper**
  - **Given** `.agent0/tools/agent-browser.sh`
  - **When** `route` resolves a command under any condition (no-binary, no-chrome, or with `AGENT0_BROWSER=mcp` set)
  - **Then** there is no `fallback:*` branch that selects MCP — the `no-binary`/`no-chrome`/`override` MCP lanes are removed; `AGENT0_BROWSER=mcp` no longer selects an MCP path (it is a no-op or an explicit unsupported-error, decided at plan time)

- [ ] **Scenario: `/product` Phase 4 visual check runs through agent-browser, never MCP**
  - **Given** a `/product` run reaching Phase 4 with hi-fi mood screens at `<out>/docs/screens/hifi/`
  - **When** the visual check runs and `agent-browser` IS available
  - **Then** it sweeps the screens via `agent-browser.sh audit … --structure optional` over `file://` paths (no `serve-hifi.sh`, no localhost HTTP server, no `mcp__playwright__*` call), capturing 375 px + 1280 px screenshots and a horizontal-overflow result (`scrollWidth > clientWidth`) per screen into the audit report

- [ ] **Scenario: `/product` Phase 4 skips loudly when agent-browser is unavailable**
  - **Given** a `/product` run reaching Phase 4 and `agent-browser` is unavailable
  - **When** the visual check runs
  - **Then** it emits `visual-gate-skipped: agent-browser unavailable …`, records the skip prominently in `REPORT.md`, **never** seeds or mentions an MCP block, **never** writes a live `<out>/.mcp.json` Playwright server, and never blocks/aborts the run

- [ ] **Scenario: `audit` gains a structure mode without regressing site-audit**
  - **Given** `agent-browser.sh audit`
  - **When** invoked with `--structure strict` (the default, unchanged) vs `--structure optional`
  - **Then** `strict` keeps today's gate (`h1=1 && main=1 && console<=max`); `optional` relaxes the `h1`/`main` landmark requirement so landmark-less hi-fi mood fragments do not false-fail, while still capturing console + overflow + shots

- [ ] **Scenario: auth-gated reads run through the agent-browser-native flow**
  - **Given** an auth-gated host with no saved state
  - **When** the agent needs authenticated content
  - **Then** the flow is `browser-login.sh <host>` (human owns the CDP Chrome) → `agent-browser.sh adopt <host>` (CDP detect + save state) → headless reuse; `browser-auth.md` documents this as the **primary** mechanism with no Playwright `storageState` / `browser_run_code_unsafe` path, and the old `BROWSER_AUTH_REQUIRED: <host>` signal is replaced by an agent-browser-native signal convention

- [ ] **Scenario: anti-regression guard fails on reintroduced MCP browser driving**
  - **Given** the first-party harness surfaces (`.agent0/{tools,hooks,context/rules}`, `.claude/skills`, `.agent0/tests`)
  - **When** the grep-guard test runs
  - **Then** it FAILS if any first-party file (outside `*.example` templates and `docs/specs/**` history) references `mcp__playwright__*` or an MCP browser-fallback lane, and PASSES on the converted tree

- [ ] The 5 surfaces from the meeting synthesis are converted: (1) `/product` visual gate, (2) `browser-auth.md` auth flow, (3) `agent-browser.sh` routing code + the tests that lock it (`tests/agent-browser/02-route.sh`, `04-audit.sh`), (4) `runtime-capabilities.md:56-57` + `doctor.sh:144,152` wording, (5) `secrets-scan.md:97` "Playwright-produced" framing cleanup
- [ ] `doctor.sh` reports browser-functionality availability **without** offering an MCP fallback as the remedy
- [ ] Existing suites stay green after conversion: `.agent0/tests/agent-browser/run-all.sh`, harness-sync, agent0-status (the `02-route.sh` / `04-audit.sh` asserts are rewritten to the fail-closed contract, not deleted)
- [ ] `serve-hifi.sh` is deleted and no `/product` reference to it remains
- [ ] `.mcp.json.example` / `.codex/config.toml.example` Playwright/Chrome-DevTools blocks are **unchanged**; harness-sync untouched-tests (`11-mcp-json-untouched.sh`, `35-codex-config-example-untouched.sh`) stay green

## Non-goals

- **Deleting the MCP templates.** `.mcp.json.example` / `.codex/config.toml.example` keep their Playwright + Chrome DevTools recipes (opt-in consumer choice). Keep-the-template ≠ keep-the-harness-dependency.
- **Removing `agent-browser` itself or its observe/auth capabilities** — this spec changes routing/policy + doc/skill wiring, not the primitive's feature set (beyond the additive `audit --structure` + overflow extension).
- **Touching spec history** — specs 011/012/021/066/075/152…, the spec-152 meeting transcript, and memory entries that reference Playwright stay as written (audit trail).
- **Re-litigating spec 152's primary-primitive decision** — 152 is shipped/committed; 153 only removes the fallback lanes it deliberately kept.
- **A consumer migration tool** for projects already wired to the old `.mcp.json` Playwright visual flow — out of scope; the template path covers them.

## Open questions

_All resolved at plan time (2026-06-05) — see `plan.md` § Resolved open questions. Kept here as a record; none block the build._

- [x] **`AGENT0_BROWSER=mcp` final behavior** → RESOLVED: explicit unsupported error (`route` returns `unavailable:mcp-removed`, command layer prints `unsupported: … MCP routing removed in spec 153 …`, exit 3). Louder than a no-op; matches fail-closed.
- [x] **`audit --structure optional` gate semantics** → RESOLVED: default `strict` = today's gate verbatim (no regression); `optional` makes `h1`/`main` advisory, gates on `console<=max` only. Overflow + 375/1280 shots are additive recorded fields in both modes. Codex's "keep the site-audit primitive clean" objection honored — `strict` untouched, rest purely additive.
- [x] **New auth signal** → RESOLVED: `BROWSER_LOGIN_REQUIRED: <host>` (remedy = `browser-login.sh <host>` → `adopt`). Stays greppable by `context-inject.sh` via the existing `*login*`/`*browser*` cases; `*playwright*` dropped from that selector.
- [x] **Grep-guard scope + allowlist** → RESOLVED: `08-no-mcp-coupling.sh` sweeps `.agent0/{tools,hooks,context/rules}`, `.claude/skills`, `.agent0/tests`; forbids `mcp__playwright__` / `mcp__chrome-devtools__` / the `fallback:*` lane markers / `serve-hifi`; allows `*.example`, `docs/specs/`, and the guard file itself. Yes — it also forbids `serve-hifi`.

## Context / references

- **Scoping meeting (seed):** `.agent0/meetings/descacoplar-harness-agent0-do-playwright-2026-06-05T17-44-39Z/meeting.md` — `synthesis: accepted`. Turn 2 is Codex's independent scope validation (the "coupling is in code + tests" hardening); the synthesis carries the 5-surface decouple-set, the fail-closed-vs-skip-advisory policy, and the minority report (silent visual-evidence degradation + its mitigation, which this spec carries as the "loud skip" + "doctor offers no MCP" criteria).
- **Q2 mechanism decision:** Codex probe `20260605T181854Z-sdd153-q2-product-mechanism` — agreed `audit` over per-screen `verify-contract`, confirmed `audit`'s gate false-fails fragments (`agent-browser.sh:428-432`), confirmed `file://` works without `serve-hifi.sh` (`:100-104`, `:413-416`), overflow belongs inside `audit` (`:415-421`, `:442-449`).
- **Predecessor:** spec 152 `browser-primitive-consolidation` (shipped, `f31e6b8`+`ef6b815`) — the primary-primitive + permanent-fallback baseline this spec partially reverses.
- **Replacement already built (spec 152.2):** `.agent0/tools/browser-login.sh`, `agent-browser.sh adopt` (`:311-364`) — validated end-to-end on real GitHub/X/LinkedIn.
- **Rules touched:** `browser-primitive.md`, `browser-auth.md`, `runtime-capabilities.md`, `secrets-scan.md`. Skill touched: `.claude/skills/product/` (SKILL.md, references/{quality-checklist,sdd-handoff,state-machine}.md, templates/report.md.tmpl, scripts/serve-hifi.sh). Code: `.agent0/tools/{agent-browser.sh,doctor.sh}`. Tests: `.agent0/tests/agent-browser/{02-route.sh,04-audit.sh}` + new grep-guard.
