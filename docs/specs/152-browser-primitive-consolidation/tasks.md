# 152 — browser-primitive-consolidation — tasks

_Generated from `plan.md` on 2026-06-05. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Scaffold `.agent0/tests/agent-browser/` with `run-all.sh` runner + fixtures dir; add the sample screen HTML + `fixture-spec.json` + synthetic `auth-server.js`.
- [x] 2. Write the wrapper's pure-logic tests first (TDD): `caps` JSON shape, `route` resolves primary vs each fallback reason, policy evaluation (read-only allow / sensitive deny / allowlist allow / `--confirm` allow), audit-line emission, JSON-contract assertion.
- [x] 3. Implement `.agent0/tools/agent-browser.sh` core: `caps` (detect binary + chrome + pinned-version advisory, JSON tri-state), `route` (primary | fallback:<reason>), policy loader/evaluator, audit appender. Make tests from task 2 green.
- [x] 4. Add `.agent0/browser-policy.yaml` default (mode: audit, allowlist, sensitive_actions) and wire the evaluator to read it.
- [x] 5. Implement `run -- <args>` (policy-gated passthrough, defaults `AGENT_BROWSER_EXECUTABLE_PATH` to system chrome, audits) and `verify-contract <url> <fixture-spec> <outdir>` (bounded batch: open/snapshot/screenshot/console/vitals + jq asserts → PASS/FAIL report).
- [x] 6. Dogfood slice 1 (visual-contract): run `verify-contract` against the fixture screen end-to-end via real agent-browser; assert PASS, capture artifacts (a11y.json, screen.png, report).
- [x] 7. Dogfood slice 2 (auth-gated): start `auth-server.js`, drive login via the wrapper using `--session-name`/profile, prove session reuse on a second invocation reaches the authed page; assert authed content; confirm state file is gitignored credential-class.
- [x] 8. `doctor.sh`: add the agent-browser tri-state check. `_brief-compose.sh`/`status.sh`: surface availability.
- [x] 9. Create `browser-primitive.md` rule (primary + routing rule + security posture + opt-in). Extend `browser-auth.md` (agent-browser primary, MCP permanent fallback). Add `runtime-capabilities.md` row.
- [x] 10. `CLAUDE.md` managed-block section; `.agent0/memory/agent-browser-primitive.md` + regenerate `MEMORY.md`; `.gitignore` entries (audit dir + profiles/state); register new tracked files in `harness-sync-baseline.json`.

## Verification

_Each maps to a `spec.md` acceptance criterion._

- [x] AC1 (default primitive, no wiring): `route` returns `primary` when binary present; a wrapper `run` of open+snapshot works through plain shell, no `.mcp.json`/`.codex` block, identical invocation shape for both runtimes. → test + live run.
- [x] AC2 (graceful degradation): with binary masked, `route` returns `fallback:no-binary` and the wrapper points at the MCP path instead of hard-failing. → test.
- [x] AC3 (routing rule exhaustive): `route` enumerates exactly {no-binary/chrome, capability-gap, override} as fallback reasons; default otherwise. → test + rule doc.
- [x] AC4 (visual-contract slice): `verify-contract` produces PASS/FAIL vs fixture-spec, reproducible. → live dogfood (slice 1).
- [x] AC5 (auth slice): profiles/state session reuse reaches authed page; state stored gitignored credential-class. → live dogfood (slice 2).
- [x] AC6 (auditable hands): every interactive action emits an audit line (ts/action/target/decision/guard); sensitive action blocked-or-confirmed per policy. → test + audit-log inspection.
- [x] AC7 (static facts): operational envelope present; `doctor`/`status` surface it; `browser-auth.md` updated; opt-in; `runtime-capabilities.md` records it. → file inspection + `doctor.sh` run.
- [x] Final: `bash .agent0/tests/agent-browser/run-all.sh` green; `bash .agent0/tools/doctor.sh` clean; all spec.md AC boxes checked; notes.md filled.

## Notes

_Filled during execution → folded into notes.md._
