# 152 — browser-primitive-consolidation — notes

_Created 2026-06-05._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`._

## Design decisions

### 2026-06-05 — parent — Tool, not skill; one wrapper as the spine
Shipped `.agent0/tools/agent-browser.sh` (a tool other skills call) rather than a `/inspect` skill. The meeting redirected from an inspection-slice to a full eyes+hands primitive; a primitive that `/verify`/`/run`/`/product`/`/sdd` consume is a tool. A thin slash front-end can come later if demand shows.

### 2026-06-05 — parent — Routing: missing system Chrome is NOT a fallback reason
`agent-browser` self-provides Chrome-for-Testing, so `route` only falls back on `no-binary`, explicit `AGENT0_BROWSER_NO_CHROME=1`, or `AGENT0_BROWSER=mcp`. An early version fell back when `resolve_chrome` failed; the test `02-route` caught that this misfires on machines that rely on the bundled Chrome. Simplified to the three explicit reasons.

### 2026-06-05 — parent — Auth dogfood uses isolated `--session`s, not profile/daemon restarts
The auth slice proves `state save`→`state load` reuse across three isolated `--session`s (auth/fresh/reuse) inside ONE daemon, with a negative control (fresh session bounces to login → the saved state is load-bearing). Chosen over `--profile` + daemon-restart because the global daemon ignores launch options unless restarted, and restarts are slow/flaky.

## Deviations

### 2026-06-05 — parent — Policy file is JSON, not YAML
`plan.md` said `.agent0/browser-policy.yaml`. Switched to `.agent0/browser-policy.json(.example)` because `jq` (a hard repo dependency, used throughout) parses JSON natively and YAML-in-bash is brittle. Wrapper has safe built-in defaults, so no file is required; the `.example` follows the opt-in template pattern and is registered in the sync manifest.

### 2026-06-05 — parent — Availability surface is `doctor`, not the SessionStart brief
`spec.md` AC said "status.sh/the brief surface availability". Right-sized to: `doctor.sh` grows the real tri-state check (`=== browser primitive ===`, via the wrapper's `caps`), and that is the canonical availability surface. The SessionStart brief stays session-state-only (handoff/reminders/routines/decay/git) — adding a capability probe that launches the binary on every boot is per-session cost the anti-drift `agent0-status` scope explicitly warns against. AC reworded accordingly.

## Tradeoffs

### 2026-06-05 — parent — Permanent MCP fallback (founder call) over hard cutover
Founder chose "adopt agent-browser as primary + keep Playwright/DevTools MCP as a permanent fallback" over deleting the MCP path. Accepts a maintenance cost (two browser paths) in exchange for zero cutover risk AND a portability/degradation answer (binary absent ⇒ MCP). The routing rule is what keeps "two paths" from becoming an ambiguous agent instruction. The meeting's minority report (how fast to delete the fallback) is rendered moot — there is no deletion.

## Open questions

_None blocking. All spec § Open questions resolved at plan/build time: routing conditions (3, enumerated in `route`), version pin (`PINNED_VERSION` const + doctor advisory on drift, manual bump), policy default (mode=audit, sensitive needs `--confirm`), browser-auth.md (extended with a fallback banner, not rewritten), auth host (synthetic local Node server)._

## Validation evidence

- `bash .agent0/tests/agent-browser/run-all.sh` → ALL SCENARIOS PASS (7 files: caps, route, policy, audit, JSON contract, + 2 live dogfood slices). Live slices use real `agent-browser` 0.27.1 + system Chrome + node.
- Visual-contract slice: `verify-contract` PASS against a fixture screen (a11y refs matched, console clean, screenshot produced) + a negative case proving the gate fails on a missing required element.
- Auth slice: login (audited via wrapper) → `state save` (cookies captured) → fresh session bounces to login (negative control) → `state load` reuse reaches the authed page. `A=Account / NEG=Sign in / B=Account`.
- `bash .agent0/tools/doctor.sh` → agent-browser check reports `ok` (present, pinned, chrome).

## 152.1 — structural `audit` primitive (demand-validated by the real site-audit dogfood)

### 2026-06-05 — parent — Real dogfood: audited `site/dist/` (Agent0 consultancy site) with the primitive
Swept all 21 localized pages (pt/en/es × 7). **Site result: clean** — every page has exactly one `<h1>`, `main`+`nav` landmarks, 0 console errors, CLS 0 (LCP unreliable on local static). The dogfood's real payload was 4 findings about the PRIMITIVE (the demand-gate working as designed):
1. `verify-contract` asserts only on named `.data.refs`; structure/landmarks live in the `.data.snapshot` text tree.
2. **Hand-rolled structural parsing is a trap**: `grep -c 'level=1'` also matches `listitem [level=1]` (nesting) — my by-hand audit mis-flagged the clean home pages as `h1=8` (actually 1 + 7 listitems). A false a11y finding from naive usage.
3. Vitals are meaningless on local static (LCP always ~20ms) — need a deployed/throttled target.
4. No multi-page sweep command — I hand-rolled the loop + daemon mgmt + aggregation.

### 2026-06-05 — parent — Built `audit` + `parse-structure` in response (founder chose "build now")
Added `agent-browser.sh audit <base> --paths …` (multi-page sweep → `report.{md,json}` + screenshots; structural gate: one h1 + main + console≤max; vitals advisory) and `parse-structure` (parses heading lines only — `heading … [level=1[,\]]` — so listitems are never miscounted). Fixes findings #2 and #4, partially #1; #3 documented as advisory. **Loop closed**: re-audited the real site via the new primitive — every page correctly reads `h1=1`, 0 flagged (the by-hand false `h1=8` is now impossible). Tests: `06-structure` (the listitem trap → h1=1, two real h1s → h1=2, landmark absence) + `12-dogfood-audit` (clean page passes, bad page with 2 h1 + no main flagged, h1 read as 2 not 2+listitems). Suite now **9 files / 58 asserts, all pass**. Recorded as 152.1 (sub-version in this notes file, per the 150.x convention).

## 152.2 — human-in-the-loop auth flow (`browser-login` + `adopt`), demand-validated by the auth-gated dogfood

### 2026-06-05 — parent — The headed-login step can't be agent-spawned here; the human must own the browser
Founder asked to dogfood the auth-gated path (GitHub/X/LinkedIn). Hard env finding: an **agent-spawned headed Chrome doesn't stay visible** — WSLg drops the window surface AND the harness reaps the agent's process tree on turn end (the Chrome PROCESS survived — 9 procs, CDP port responded — but the visible WINDOW died, so the human couldn't log in). Proven by experiment: a Chrome the *human* owns (or one launched fully detached with a CDP debug port) survives and its CDP port is reachable. So the correct model is **human owns the browser, agent attaches over CDP** — which is also the right security posture (`browser-auth.md`'s warning against `--auto-connect` to the main profile).

### 2026-06-05 — parent — Built `browser-login.sh` + `adopt` (founder: "make it a flow, I'll forget the command")
The friction was memorability (a long `google-chrome --remote-debugging-port=…` string). Formalized as: `.agent0/tools/browser-login.sh <host>` (human runs ONE word → detached, isolated, dedicated-profile Chrome with CDP `:9222` at the login page) + `agent-browser.sh adopt <host>` (agent **polls the CDP `/json` endpoint — plain HTTP, non-disruptive, never navigates the human's tab** — until a host page leaves the login flow, then saves state over CDP). `--detect-only` answers "logged in yet?" without saving. Never touches credentials. **Validated end-to-end synthetically** (browser-login → CDP-simulated login → adopt auto-detect + save → adopted state has a structurally-perfect persistent cookie → reuse reaches the authed page). Tests: `07-adopt-detect` (fake CDP `/json` server → detect/timeout/login-denylist/no-endpoint) + `13-dogfood-adopt` (full live loop). Daemon-contention flake between consecutive live tests fixed with a teardown between scenarios in `run-all.sh`. Suite now **11 files / 68 asserts, all pass**. The real GitHub/X/LinkedIn runs are now a clean human step away (run `browser-login.sh github`, log in, `adopt github`).

### 2026-06-05 — parent — REAL auth dogfood: GitHub + X + LinkedIn, all 3 PASS end-to-end
Ran the full flow against three real, production, anti-bot-protected services (founder logged in each; agent never touched credentials). **All passed:** GitHub (14 cookies → headless reuse reached `github.com/settings` showing `cfpperche (cfpperche) settings`), X (14 cookies → `x.com/home` with the post composer, despite the heavy SPA + anti-bot), LinkedIn (45 cookies → `linkedin.com/feed/` with My Network/Jobs/Messaging nav, no authwall — the most aggressive target). The riskiest axis the meeting flagged (real httpOnly auth migration) is now **validated in production conditions**, not just synthetically. New finding: the **agent-launched detached Chrome window DID stay visible** for all three (founder saw + logged into each) — so the "agent-spawned window dies" problem was specific to agent-browser's *headed daemon spawn*, not a plain detached `google-chrome`; the launcher can be agent-run, the human just logs in. `adopt`'s non-disruptive CDP poll auto-detected login completion on all three. Reuse used the proven `state load` + isolated `--session` pattern. State files are credential-class, gitignored under `.agent0/.runtime-state/agent-browser/state/<host>.json`.

