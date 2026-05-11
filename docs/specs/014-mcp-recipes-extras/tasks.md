# 014 — mcp-recipes-extras — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Verify upstream install commands

- [ ] 1. WebFetch `https://github.com/traceloop/opentelemetry-mcp-server` README. Record: exact npm package name, install command, `.mcp.json` server-entry block (verbatim if shown), env-var requirements (OTLP endpoint, backend type), tool list.
- [ ] 2. WebFetch `https://github.com/grafana/mcp-grafana` README. Record: shipping mode (Go binary / npm / Docker), install command, env-var requirements (`GRAFANA_URL`, `GRAFANA_API_KEY`), tool list, datasource compatibility (Prometheus / Tempo / Loki).
- [ ] 3. WebFetch `https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem` (or the archived path if needed). Record: package name, install command, the path-allowlist arg shape.
- [ ] 4. WebFetch the Git MCP source — first try the official archive (`https://github.com/modelcontextprotocol/servers-archived/tree/main/src/git`), then verify against current alternatives on `https://mcpservers.org`. Decide and record which to recommend in the recipe.

### Phase 2 — Documented contract

- [ ] 5. Extend `.claude/rules/mcp-recipes.md` with four new MCP sections (OpenTelemetry / Grafana / Filesystem / Git). Each must have all six sub-sections used in spec 012 (source URL / capabilities / `.mcp.json` block / install command / runtime requirements / security pointer). Add a new "Universal recipes" subsection framing Filesystem + Git. Extend the stack-detector signal table with OTel and Grafana rows. Update the hint output shape example to include the new lines.
- [ ] 6. Extend `.mcp.json.example` with four new commented blocks. OpenTelemetry + Grafana grouped with the stack-aware four. Filesystem + Git below a `// === Universal recipes (always applicable, opt-in manually) ===` divider.

### Phase 3 — RED test suite

- [ ] 7. Create `.claude/tests/mcp-recipes-extras/run-all.sh` (mirror spec 012's driver).
- [ ] 8. Write `01-otel-detection.sh`. Three sub-cases: (a) tmp fixture with `otel-collector.yaml`; (b) `OTEL_EXPORTER_OTLP_ENDPOINT=` in `.env.example`; (c) both at once. Each asserts hint contains `opentelemetry-mcp` recipe name.
- [ ] 9. Write `02-grafana-detection.sh`. Two sub-cases: (a) `GRAFANA_URL=` in `.env.example`; (b) `grafana/` dir at root. Each asserts hint contains `grafana-mcp`.
- [ ] 10. Write `03-filesystem-git-not-auto.sh`. Three fixtures covering different stack shapes. Each asserts hint does NOT contain `filesystem-mcp` or `git-mcp`. This is the universal-recipes-are-manual-only guarantee.
- [ ] 11. Write `04-012-still-green.sh`. Wrapper that invokes `bash .claude/tests/mcp-recipes/run-all.sh` and asserts the exit code is 0. Regression guard for spec 012.
- [ ] 12. Run `bash .claude/tests/mcp-recipes-extras/run-all.sh`. Expected: 0/4 PASS (RED — hook branches don't exist yet, but 04 may PASS since spec 012 tests are independent of 014's hook changes; document the partial RED state in the commit body).

### Phase 4 — Implementation

- [ ] 13. Extend `.claude/hooks/mcp-recipes-hint.sh`. Add two new signal-detection branches: OTel (file glob `otel-collector*.yaml` OR `^OTEL_EXPORTER_OTLP_ENDPOINT=` in `.env.example`) and Grafana (`GRAFANA_URL=` in `.env.example` OR `grafana/` dir). Add recipe-name printout cases for `opentelemetry-mcp` and `grafana-mcp`. DO NOT add Filesystem or Git branches.
- [ ] 14. Update `CLAUDE.md` § MCP recipes to mention the second-leva extension (one sentence appended to the existing block).
- [ ] 15. Run `bash .claude/tests/mcp-recipes-extras/run-all.sh`. Expected: 4/4 PASS — GREEN.
- [ ] 16. Run `bash .claude/tests/mcp-recipes/run-all.sh`. Expected: 6/6 PASS — regression-free.

### Phase 5 — Live verification

- [ ] 17. Live-verify against tmp fixture with `otel-collector.yaml`. Confirm hint surfaces `opentelemetry-mcp`. 0-finding pass = pass; any FP/FN = finding → fix + new RED test.
- [ ] 18. Live-verify against tmp fixture with `GRAFANA_URL` in `.env.example`. Confirm `grafana-mcp` surfaces.
- [ ] 19. Live-verify against Agent0 root (no OTel/Grafana signals). Confirm hint stays silent (Agent0 base case unaffected by 014 additions).
- [ ] 20. Apply yield-decay: two consecutive 0-finding live-verify passes graduate. If pass 17 surfaces findings, fix and re-run.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one maps to a checklist item there._

- [ ] V1. OTel recipe documented — read rule doc, confirm new section with all 6 sub-sections present.
- [ ] V2. Grafana recipe documented — same.
- [ ] V3. Filesystem recipe documented — same, plus universal-recipe framing present.
- [ ] V4. Git recipe documented — same.
- [ ] V5. `.mcp.json.example` has 4 new blocks — confirm by grep for each new recipe name in the example file.
- [ ] V6. OTel stack signal fires — task 15 PASS for `01-otel-detection.sh`.
- [ ] V7. Grafana stack signal fires — task 15 PASS for `02-grafana-detection.sh`.
- [ ] V8. Filesystem + Git NOT auto-suggested — task 15 PASS for `03-filesystem-git-not-auto.sh`.
- [ ] V9. Spec 012 regression-free — task 16 PASS.
- [ ] V10. Static facts — rule doc, example file, hook, tests all present and consistent.

## Notes

_To be filled during execution._

### Commit cadence

1. `docs(014): rule doc additions + .mcp.json.example extension` — after tasks 5-6
2. `tests(014): RED — extras detection scenarios` — after task 12
3. `feat(014): OTel + Grafana stack-detector branches` — after tasks 13-16
4. `fix(014): live-verify adjustments` (if any) — after task 20
5. `chore: SESSION refresh — spec 014 delivered`

### Live-verify findings

_To be filled during execution._
