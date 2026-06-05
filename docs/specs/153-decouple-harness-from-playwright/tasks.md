# 153 — decouple-harness-from-playwright — tasks

_Generated from `plan.md` on 2026-06-05. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Band 1 — routing/policy code (the contract everything asserts against)
- [ ] 1. `agent-browser.sh route()`: remove the 3 `fallback:*` lanes → emit `primary` | `unavailable:no-binary` | `unavailable:no-chrome`; `AGENT0_BROWSER=mcp` → `unavailable:mcp-removed`. Update `CAPABILITY_GAPS` comment.
- [ ] 2. `agent-browser.sh` command layer: `run()`, `verify_contract()`, `audit_pages()` refusals → fail-closed `rc 4` with an install/`doctor`/`caps` message (no "MCP fallback"). For `AGENT0_BROWSER=mcp` print the explicit `unsupported: … MCP routing removed in spec 153 …` and exit 3.
- [ ] 3. `agent-browser.sh` header comment (`:1-28`): drop the "PERMANENT fallback" sentences; restate exclusive-primitive + fail-closed.
- [ ] 4. `audit_pages()`: add `--structure strict|optional` (default `strict` = unchanged gate). In `optional`, `h1`/`main` advisory; gate on `console<=max` only.
- [ ] 5. `audit_pages()`: add 375 + 1280 viewport screenshots and a `scrollWidth>clientWidth` overflow field per page into `report.{json,md}` (both modes, advisory). **Spike + decide** the non-`eval` overflow-read mechanism; record the choice in `notes.md`.
- [ ] 6. `doctor.sh` (`:143-162`): absent-binary → report browser functionality unavailable WITHOUT offering MCP; drop "falls back to Playwright/DevTools MCP".

### Band 2 — tests rewritten to the new contract (kept green continuously)
- [ ] 7. Rewrite `02-route.sh` to the new `route` contract (4 cases incl. `unavailable:mcp-removed`).
- [ ] 8. Rewrite `04-audit.sh` no-binary case (`:26-29`) → rc 4, message asserts NO "fallback"/"MCP".
- [ ] 9. Extend `12-dogfood-audit.sh` (+ `06-structure.sh` if needed) for `--structure optional` + the overflow field; check `fixtures/auth-slice.sh` for stale `storageState`.
- [ ] 10. Create `08-no-mcp-coupling.sh` grep-guard (forbidden: `mcp__playwright__`, `mcp__chrome-devtools__`, `fallback:no-binary|no-chrome|override`, `serve-hifi`; allow `*.example`, `docs/specs/`, the guard file). Must PASS only after Bands 3-4 land.

### Band 3 — /product visual gate + docs conversion
- [ ] 11. `product/SKILL.md:58`: remove the `.mcp.json` Playwright seed (Phase 0 step 3).
- [ ] 12. `product/SKILL.md:147-164`: replace serve-hifi + `mcp__playwright__*` loop with `agent-browser.sh audit … --structure optional` over `file://`; loud `visual-gate-skipped: agent-browser unavailable …`; no MCP seed/mention. `:171`: standing-constraint wording → agent-browser.
- [ ] 13. Reword `product/references/{quality-checklist.md:133,sdd-handoff.md:69,state-machine.md:113}` + `templates/report.md.tmpl:77-79` to agent-browser.
- [ ] 14. Delete `product/scripts/serve-hifi.sh` + remove every remaining reference.
- [ ] 15. Convert `browser-auth.md` to the agent-browser-native flow: `browser-login.sh` → `adopt`; `BROWSER_LOGIN_REQUIRED` signal; state path `.agent0/.runtime-state/agent-browser/state/<host>.json`; drop Playwright `--headed`/`storageState`/`browser_run_code_unsafe`/`--storage-state` + the Chrome-DevTools-observer section.
- [ ] 16. `browser-primitive.md` § Routing → "agent-browser or fail-closed"; fix the `:53` `.browser-state` cross-ref.
- [ ] 17. `runtime-capabilities.md:56-57`: drop MCP-fallback framing on both rows; signal + state-path update.
- [ ] 18. `secrets-scan.md:97`: reframe credential-class state as agent-browser-produced at the new path.

### Band 4 — entrypoints, state plumbing, garbage removal
- [ ] 19. `CLAUDE.md:116` + `AGENTS.md:96` managed "Browser auth" block → new flow + `BROWSER_LOGIN_REQUIRED` + new state path (keep both in parity).
- [ ] 20. `context-inject.sh:122`: drop `*playwright*` from the browser-auth selector (keep `*browser*|*auth*|*login*`).
- [ ] 21. Retire `.agent0/.browser-state/` scaffold: `.gitignore:28`, `sync-harness.sh:173,218`, `harness-sync.md:230`, `.runtime-state/README.md:11`; ensure the new `state/` path is gitignored. Delete the tracked `.gitkeep`.
- [ ] 22. **HUMAN-GATED:** surface the stale credential files `.agent0/.browser-state/{linkedin.com,x.com}.json` for founder confirmation; delete only on explicit approval (never in an autonomous turn).
- [ ] 23. `site/src/i18n/capacities.ts:411-413` (+ `strings.ts` sibling if any): update en/pt/es browser-auth copy to the new flow.

## Verification

- [ ] 24. `bash .agent0/tests/agent-browser/run-all.sh` green (incl. new `08-no-mcp-coupling.sh`).
- [ ] 25. `bash .agent0/tests/harness-sync/run-all.sh` green — proves `11`/`35` (template untouched) still pass and the manifest change is consistent.
- [ ] 26. `bash .agent0/tools/doctor.sh` exits 0 and offers no MCP remedy for the browser row; `bash .agent0/validators/run.sh` clean.
- [ ] 27. Grep-guard manual cross-check: `grep -rIn 'mcp__playwright__\|serve-hifi\|fallback:no-binary' .agent0 .claude --include=*.sh --include=*.md` returns only `*.example`/`docs/specs` hits.
- [ ] 28. Spec acceptance walk: every `spec.md` § Acceptance criteria box ticked; `notes.md` records the overflow-read decision + the credential-file disposition.
