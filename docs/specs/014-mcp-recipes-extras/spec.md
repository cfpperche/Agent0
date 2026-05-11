# 014 — mcp-recipes-extras

_Created 2026-05-11. Status: draft._

## Intent

Extend spec 012's `.mcp.json.example` + `.claude/rules/mcp-recipes.md` with four additional curated MCP recipes covering observability, filesystem, and version-control introspection: **OpenTelemetry MCP**, **Grafana MCP**, **Filesystem MCP**, **Git MCP**. Same shape as the v1 four (Playwright / Chrome DevTools / DBHub / Next.js DevTools) — recipes are documentation + commented blocks in the example file; the SessionStart hint suggests them stack-aware when telltale signals exist. Adds new stack-detector signals where applicable (e.g. `otel-collector*.yaml` for OTel MCP) and explicitly marks Filesystem + Git as **universal recipes** (no stack signal — every fork can benefit, the developer chooses manually). This is the second leva of recipes; specs 016+ extend on real-world demand.

## Acceptance criteria

- [ ] **Scenario: OpenTelemetry MCP recipe documented**
  - **Given** the spec ships
  - **When** a developer reads `.claude/rules/mcp-recipes.md`
  - **Then** there is a new section for OpenTelemetry MCP with: official source URL (Traceloop or upstream), tools exposed (search_traces / find_errors / get_llm_usage / get_llm_slow_traces / list_services), the `.mcp.json` block, install command, runtime requirements (OTLP backend reachable — Jaeger / Tempo / Traceloop cloud), and when-to-enable signals

- [ ] **Scenario: Grafana MCP recipe documented**
  - **Given** the spec ships
  - **When** a developer reads the rule doc
  - **Then** Grafana MCP section names the install path (Go binary or container per upstream), tools (Prometheus query / Tempo traces / Loki logs), env requirements (`GRAFANA_URL` + API token), when-to-enable signals

- [ ] **Scenario: Filesystem MCP recipe documented**
  - **Given** the spec ships
  - **When** a developer reads the rule doc
  - **Then** Filesystem MCP section names the official `@modelcontextprotocol/server-filesystem` package, the `.mcp.json` block with a configurable path-allowlist arg, security note about path scope, and explicit "universal recipe — every fork can enable" framing

- [ ] **Scenario: Git MCP recipe documented**
  - **Given** the spec ships
  - **When** a developer reads the rule doc
  - **Then** Git MCP section names the canonical Git MCP source (verified during plan phase — official archive vs maintained community fork), tools (log / diff / blame / status), the `.mcp.json` block, and "universal recipe — every git repo can enable" framing

- [ ] **Scenario: `.mcp.json.example` gains 4 new commented blocks**
  - **Given** the spec ships
  - **When** a developer reads `.mcp.json.example` at repo root
  - **Then** the file contains commented blocks for all 8 recipes (4 from spec 012 + 4 from spec 014); ordering groups the stack-aware ones first, then the universal ones below a divider comment

- [ ] **Scenario: OpenTelemetry stack signal fires when telltale files exist**
  - **Given** a fork has `otel-collector.yaml` (or `otel-collector-config.yaml`, OR `OTEL_EXPORTER_OTLP_ENDPOINT=` in `.env.example`)
  - **When** a session starts
  - **Then** the mcp-recipes hint includes `opentelemetry-mcp` in its suggestions

- [ ] **Scenario: Grafana stack signal fires when `GRAFANA_URL` is referenced**
  - **Given** a fork's `.env.example` mentions `GRAFANA_URL=` OR a `grafana/` config dir exists
  - **When** a session starts
  - **Then** the hint includes `grafana-mcp` in suggestions

- [ ] **Scenario: Filesystem + Git are NOT auto-suggested by stack signals**
  - **Given** any fork shape
  - **When** a session starts
  - **Then** the hint block does NOT include `filesystem-mcp` or `git-mcp` (universal recipes are manual-opt-in — recommending them on every session is noise)

- [ ] **Scenario: regression — existing 4 recipes still suggested for their stacks**
  - **Given** a Next.js fork (or any fixture from spec 012's test suite)
  - **When** a session starts
  - **Then** the v1 recipes (playwright / next-devtools / etc.) still appear; spec 014's additions DO NOT replace them

- [ ] `.claude/rules/mcp-recipes.md` gains four new MCP sections + one "Universal recipes" subsection framing
- [ ] `.mcp.json.example` gains four new commented blocks in a clear visual grouping
- [ ] `.claude/hooks/mcp-recipes-hint.sh` gains two new stack-signal branches (OpenTelemetry, Grafana); no Filesystem or Git auto-detection
- [ ] Existing spec 012 test suite (6/6) still PASS — regression guard for the v1 detection paths
- [ ] New test suite under `.claude/tests/mcp-recipes-extras/` covers the four new detection scenarios + the "universal recipes are NOT auto-suggested" guarantee

## Non-goals

- **Per-fork auto-install of any MCP.** Same Lazarus reasoning as every other capacity — developer activates.
- **Filesystem MCP path-allowlist auto-derivation.** The recipe documents the shape; the developer picks the paths.
- **Grafana datasource configuration.** Recipe links to upstream config docs; Agent0 does not duplicate.
- **Auto-detection of running OTel collectors / Grafana instances** (process or port scans). File-existence signals only, same shape as spec 012.
- **More than 4 MCPs in this spec.** Adding more grows scope; defer to spec 016+ if real demand surfaces.
- **Replacement of any v1 recipe.** Spec 014 is strictly additive.
- **Monorepo workspace-walk for the new signals.** That is spec 015's scope; 014 ships root-level detection only. Spec 015's refactor will pull 014's new branches into the workspace walk when it lands.

## Open questions

- [ ] **Git MCP authoritative source** — the original `@modelcontextprotocol/server-git` is in `servers-archived`. Is the community fork the right pointer, or should we link to one of the actively maintained forks (e.g. via `mcpservers.org`)? Resolve during the WebFetch phase of plan execution (tasks 1-4).
- [ ] **Grafana MCP install path** — Go binary (`grafana/mcp-grafana`) vs Docker vs npm community wrapper. Pick the lowest-friction-for-fork-developer path. Verify upstream README.
- [ ] **Stack signal for OpenTelemetry** — `otel-collector.yaml` is canonical for the OTel Collector config, but agents may use `otel-config.yaml`, `OTEL_*` env vars, or instrumented code without a collector. Proposed minimal signal: any file matching `otel-collector*.yaml` OR `^OTEL_EXPORTER_OTLP_ENDPOINT=` in `.env.example`. Confirm before plan.
- [ ] **Universal-recipe framing in `.mcp.json.example`** — should Filesystem + Git blocks have a header comment differentiating them from stack-aware ones? Proposed: yes, use a `// === Universal recipes (always applicable, opt-in manually) ===` divider.

## Context / references

- Spec 012 (`docs/specs/012-mcp-recipes/`) — the v1 capacity this extends. Same shape: rule doc + example file + SessionStart hook + settings wiring.
- Spec 015 (`docs/specs/015-monorepo-stack-detect/`) — sibling extension; closes the monorepo blind spot by walking workspace dirs. Coordinates with 014 via the `detect_at <path>` refactor (whichever lands first owns the abstraction; the other inherits).
- Spec 011 (`docs/specs/011-runtime-introspect/`) — sibling build-side capacity; mcp-recipes-extras strictly adopt-side.
- Research session 2026-05-11 (delegated, summarised in spec 012 references) — identified OTel MCP (Traceloop), Grafana MCP, Filesystem + Git MCPs (official servers repo) as the next-tier candidates.
- [traceloop/opentelemetry-mcp-server](https://github.com/traceloop/opentelemetry-mcp-server) — OTel MCP candidate.
- [grafana/mcp-grafana](https://github.com/grafana/mcp-grafana) — Grafana MCP.
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) — official Filesystem reference (current).
- [modelcontextprotocol/servers-archived](https://github.com/modelcontextprotocol/servers-archived) — Git MCP archived; needs replacement decision.
