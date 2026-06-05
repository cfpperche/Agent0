# 153 — decouple-harness-from-playwright — plan

_Drafted from `spec.md` on 2026-06-05. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Remove every first-party harness code path that drives, observes, or degrades to Playwright / Chrome DevTools MCP, leaving `agent-browser` as the sole browser primitive and the MCP recipes as opt-in `.example` templates only. The work is in four bands — (1) **routing/policy code** in `agent-browser.sh` + `doctor.sh` (the load-bearing change: fail-closed instead of MCP-fallback), (2) the **`/product` visual gate** repointed to an extended `audit`, (3) **auth + rules + entrypoint docs** converted to the agent-browser-native flow, and (4) **old-mechanism garbage removal** (the retired `.agent0/.browser-state/` scaffold, `serve-hifi.sh`, stale public site copy). A new **grep-guard test** makes the decoupling durable, and the existing route/audit tests are rewritten to the fail-closed contract (not deleted). All four resolved open-questions (below) are baked in so nothing is left for a follow-up — the goal is a fully-closed spec.

Order matters: the `agent-browser.sh` route/policy change + `audit --structure` extension land first (they're the contract everything else asserts against), then the tests are rewritten green, then the doc/skill/site conversions, then the garbage removal, then the grep-guard seals it. The `/squad` loop (Claude ↔ Codex) implements turn-by-turn against the `squad.json` gate.

### Resolved open questions (decided at plan time — no follow-ups)

- **OQ1 — `AGENT0_BROWSER=mcp` behavior:** becomes an **explicit unsupported error**. `route()` no longer emits any `fallback:*`; it returns `primary` or `unavailable:<no-binary|no-chrome>`. When `AGENT0_BROWSER=mcp` is set, `route` returns `unavailable:mcp-removed` and the command layer prints `unsupported: AGENT0_BROWSER=mcp — MCP routing removed in spec 153; Playwright survives only as an opt-in .mcp.json.example template` and exits 3. Louder than a silent no-op; matches the fail-closed philosophy.
- **OQ2 — `audit --structure strict|optional`:** default `strict` = today's gate verbatim (`h1==1 && main==1 && console<=max`) so site-audit and `04`/`12` tests don't regress. `optional` makes `h1`/`main` **advisory** (recorded in report JSON/MD, never gating); the only hard gate in `optional` mode is `console<=max`. The 375/1280 responsive screenshots + `scrollWidth>clientWidth` overflow field are **additive recorded fields in both modes** (advisory — `/product` Phase 4 is best-effort/non-blocking anyway). Codex's objection respected: `strict` is untouched; `optional` + overflow are purely additive.
- **OQ3 — auth signal:** replace `BROWSER_AUTH_REQUIRED: <host>` with **`BROWSER_LOGIN_REQUIRED: <host>`** (the remedy is literally `bash .agent0/tools/browser-login.sh <host>` → `agent-browser.sh adopt <host>`). Stays greppable by `context-inject.sh` (matches the existing `*login*` and `*browser*` cases); the `*playwright*` case is dropped from that selector.
- **OQ4 — grep-guard scope + allowlist:** new `.agent0/tests/agent-browser/08-no-mcp-coupling.sh`. Sweeps `.agent0/tools`, `.agent0/hooks`, `.agent0/context/rules`, `.claude/skills`, `.agent0/tests`. **Forbidden tokens:** `mcp__playwright__`, `mcp__chrome-devtools__`, the `fallback:no-binary|fallback:no-chrome|fallback:override` lane markers, and `serve-hifi`. **Allowlist:** paths matching `*.example`, anything under `docs/specs/`, and the guard test file itself. Keys on the MCP **tool-call tokens + code markers**, NOT the word "Playwright" — so `.example` template prose and "Playwright is an opt-in template" doc sentences stay legal.

## Files to touch

**Create:**
- `.agent0/tests/agent-browser/08-no-mcp-coupling.sh` — grep-guard anti-regression (auto-discovered by `run-all.sh` glob `[0-9][0-9]-*.sh`).
- `docs/specs/153-decouple-harness-from-playwright/squad.json` — the executable gate contract.

**Modify — code:**
- `.agent0/tools/agent-browser.sh` —
  - `route()` (`:150-163`): delete the 3 `fallback:*` lanes; emit `primary` | `unavailable:no-binary` | `unavailable:no-chrome`; `AGENT0_BROWSER=mcp` → `unavailable:mcp-removed`.
  - `run()` (`:213-217`), `verify_contract()` (`:257-258`), `audit_pages()` (`:401`): refusal message → fail-closed `rc 4`, point at install / `doctor` / `caps` (NOT "use the MCP fallback").
  - `audit_pages()` (`:382-451`): add `--structure strict|optional` (default `strict`); in `optional`, `h1`/`main` advisory; gate on `console<=max`. Add 375/1280 viewport screenshots + a `scrollWidth>clientWidth` overflow field per page into `report.{json,md}`. Resolve the overflow-read mechanism (agent-browser viewport sizing + a non-`eval` overflow read — `box`/`styles`/a viewport flag; if only `eval` works, scope it to a fixed internal read-only expression, audited, never user input) — **a small spike inside the task, decided not deferred.**
  - Header comment block (`:1-28`): drop the "Playwright / Chrome DevTools MCP remain a PERMANENT fallback" sentences; restate exclusive-primitive + fail-closed.
- `.agent0/tools/doctor.sh` (`:143-162`): absent-binary check → report browser functionality **unavailable** without offering MCP as the remedy; drop "falls back to Playwright/DevTools MCP".

**Modify — `/product` skill:**
- `.claude/skills/product/SKILL.md` — `:58` (Phase 0 step 3): remove the `.mcp.json` Playwright seed entirely. `:147-164` (Phase 4): replace the serve-hifi + `mcp__playwright__*` loop with `agent-browser.sh audit … --structure optional` over `file://` paths; loud `visual-gate-skipped: agent-browser unavailable …` in REPORT; never seed/mention MCP. `:171`: standing-constraint wording "Playwright visual verification" → agent-browser.
- `.claude/skills/product/references/quality-checklist.md` (`:133`), `references/sdd-handoff.md` (`:69`), `references/state-machine.md` (`:113`), `templates/report.md.tmpl` (`:77-79`): reword visual-check to agent-browser.

**Modify — rules:**
- `.agent0/context/rules/browser-auth.md` — full conversion to the agent-browser-native flow (`browser-login.sh` → `adopt`); new `BROWSER_LOGIN_REQUIRED` signal; state path → `.agent0/.runtime-state/agent-browser/state/<host>.json`; remove Playwright `--headed`/`storageState`/`browser_run_code_unsafe`/`--storage-state` and the Chrome-DevTools-observer section.
- `.agent0/context/rules/browser-primitive.md` — § Routing collapses to "agent-browser or fail-closed"; fix the `:53` `.browser-state` cross-ref to the new path.
- `.agent0/context/rules/runtime-capabilities.md` (`:56-57`): browser-primitive + browser-auth rows — drop MCP-fallback framing; signal + state-path update.
- `.agent0/context/rules/secrets-scan.md` (`:97`): reframe credential-class state as agent-browser-produced at the new path (drop "Playwright MCP's browser_storage_state").

**Modify — entrypoints + state plumbing (garbage removal):**
- `CLAUDE.md` (`:116`) + `AGENTS.md` (`:96`): managed "Browser auth" block → new flow + `BROWSER_LOGIN_REQUIRED` + new state path.
- `.gitignore` (`:28`): retire `.agent0/.browser-state/*.json`; ensure `.agent0/.runtime-state/agent-browser/state/*.json` is ignored (verify; `.runtime-state` may already be broadly ignored).
- `.agent0/tools/sync-harness.sh` (`:173`, `:218`) + `.agent0/context/rules/harness-sync.md` (`:230`): drop `.agent0/.browser-state/.gitkeep` from the manifest/COPY_CHECK_FILES + its comment.
- `.agent0/.runtime-state/README.md` (`:11`): replace the `.agent0/.browser-state/` row with the agent-browser `state/` row (the new credential-class home).
- `.agent0/hooks/context-inject.sh` (`:122`): drop `*playwright*` from the browser-auth selector (keep `*browser*|*auth*|*login*`).
- `site/src/i18n/capacities.ts` (`:411-413`): update the en/pt/es browser-auth capability copy to the new flow (no headed Playwright MCP / `.browser-state`). Check `site/src/i18n/strings.ts` for a sibling string.

**Modify — tests:**
- `.agent0/tests/agent-browser/02-route.sh`: rewrite to the new `route` contract (`primary` | `unavailable:no-binary` | `unavailable:no-chrome` | `unavailable:mcp-removed`).
- `.agent0/tests/agent-browser/04-audit.sh` (`:26-29`): the no-binary `run` case → rc 4 with a fail-closed message that does NOT say "fallback"/"MCP".
- Extend `12-dogfood-audit.sh` (and `06-structure.sh` if affected) to cover `--structure optional` + the overflow field. Check `fixtures/auth-slice.sh` for stale `storageState` references.

**Delete:**
- `.claude/skills/product/scripts/serve-hifi.sh` — agent-browser navigates `file://` directly (`agent-browser.sh:100-104`, `:413-416`); the localhost-HTTP shim is dead.
- `.agent0/.browser-state/.gitkeep` — the retired scaffold sentinel (tracked).
- **`.agent0/.browser-state/{linkedin.com,x.com}.json`** — stale old-mechanism credential files (gitignored; superseded by `.agent0/.runtime-state/agent-browser/state/`). **HUMAN-GATED:** credential-class, not agent-created → surfaced for founder confirmation at a squad checkpoint, NOT auto-deleted in an autonomous turn.

## Alternatives considered

### Keep the explicit `AGENT0_BROWSER=mcp` override lane (remove only no-binary/no-chrome)
Rejected (founder decision, AskUserQuestion 2026-06-05): "remove ALL MCP lanes from the wrapper" — maximum purity of "depends exclusively on agent-browser". A retained override lane is still a first-party harness code path to MCP; the template path covers a consumer who deliberately wants MCP.

### Repoint `/product` Phase 4 to per-screen `verify-contract` instead of `audit`
Rejected (Claude + Codex conviction, meeting Q2 probe `20260605T181854Z`): Phase 4 IS an N-screen sweep — `audit` already owns the sweep/report/shots loop (`agent-browser.sh:382-451`) and produces the `report.{md,json}` REPORT.md wants; `verify-contract` is single-URL fixture assertions (`:251-308`), so N invocations would duplicate what `audit` does once. Extend `audit` (the false-fail on landmark-less fragments is fixed by `--structure optional`).

### Delete the Playwright `.mcp.json.example` / `.codex/config.toml.example` recipes too
Rejected: out of scope + against the founder boundary — keep-the-template ≠ keep-the-harness-dependency. The harness-sync untouched-tests (`11`, `35`) must stay green, proving the recipes are byte-stable.

## Risks and unknowns

- **Overflow-read mechanism in agent-browser.** The old probe used Playwright `browser_evaluate(scrollWidth>clientWidth)`; `eval` is policy-sensitive/denied in the wrapper. Need a non-`eval` read (viewport flag + `box`/`styles`, or a narrowly-scoped internal `eval`). This is the one genuine implementation spike — resolve it in-task, do not defer to a follow-up.
- **`audit` daemon/viewport behavior.** Adding 375/1280 screenshots means re-sizing the viewport per page; agent-browser's daemon ignores relaunch options if already up (`:165-181`) — the resize must happen per-open or via `reset`. Watch for flakiness; the suite already tears the daemon down between scenarios.
- **Credential-file deletion.** The stale `.browser-state/*.json` are the founder's real session cookies. Surfaced for confirmation, never auto-deleted — the safe handling of the goal's "eliminate garbage" directive for credential-class residue.
- **Site copy scope.** `capacities.ts` is public marketing copy; updating it keeps it truthful but is the lowest-risk band — if the squad budget is tight, it's the last task.
- **Vacuous-green gate.** Mitigated per `squad-contract.md` F1: the gate `test -f`s the new grep-guard + asserts `run-all.sh` discovers by glob, and includes the guard run itself so removing the decoupling would fail the gate.

## Research / citations

- Scoping meeting + Codex scope validation: `.agent0/meetings/descacoplar-harness-agent0-do-playwright-2026-06-05T17-44-39Z/meeting.md` (`synthesis: accepted`).
- Q2 mechanism probe: `.agent0/.runtime-state/codex-exec/20260605T181854Z-sdd153-q2-product-mechanism/last-message.md`.
- Code anchors verified this session: `agent-browser.sh` (`route` :150-163, `audit` :382-451, local-path :100-104), `doctor.sh:143-162`, `02-route.sh`, `04-audit.sh`, `_lib.sh`, `run-all.sh` (glob discovery), `product/SKILL.md:58,147-164`.
- Gate-authoring discipline: `.agent0/skills/squad/references/squad-contract.md` § F1/F3.
