# 014 — mcp-recipes-extras — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Strictly additive extension of spec 012's three artifacts. No new hooks, no new settings entries — just more content in the existing files plus two new detector branches in the existing hook. Mirrors how cargo coverage extended supply-chain without restructuring the capacity.

1. **`.claude/rules/mcp-recipes.md`** — append four new MCP sections + one "Universal recipes" subsection that frames Filesystem and Git as opt-in-by-developer-choice (no stack signal). Update the signal table to add OpenTelemetry + Grafana rows.
2. **`.mcp.json.example`** — append four new commented blocks under a `// === Universal recipes ===` divider for Filesystem and Git; OpenTelemetry and Grafana grouped with the stack-aware ones above.
3. **`.claude/hooks/mcp-recipes-hint.sh`** — add two new signal-detection branches (OpenTelemetry, Grafana). Filesystem and Git are explicitly NOT added — they are universal, documented but not suggested.
4. **Test suite** — `.claude/tests/mcp-recipes-extras/` with RED tests for the two new detection signals + a regression-guard scenario that asserts spec 012's six existing tests still PASS unmodified.

Build order: web-verify the 4 new MCPs' install commands (research before proposing rule applies) → rule doc draft → example file additions → RED tests → hook detector extensions → run both suites (012 + 014) → live-verify against tmp fixtures.

## Files to touch

**Create:**

- `.claude/tests/mcp-recipes-extras/run-all.sh` — driver mirroring spec 012's shape.
- `.claude/tests/mcp-recipes-extras/01-otel-detection.sh` — RED: tmp fixture with `otel-collector.yaml` OR `OTEL_EXPORTER_OTLP_ENDPOINT=` in `.env.example` → hint suggests `opentelemetry-mcp`.
- `.claude/tests/mcp-recipes-extras/02-grafana-detection.sh` — RED: tmp fixture with `GRAFANA_URL=` in `.env.example` OR `grafana/` dir → hint suggests `grafana-mcp`.
- `.claude/tests/mcp-recipes-extras/03-filesystem-git-not-auto.sh` — RED: fixture with various stack signals → hint does NOT include `filesystem-mcp` or `git-mcp` in any case (regression guard for the universal-recipe non-goal).
- `.claude/tests/mcp-recipes-extras/04-012-still-green.sh` — wrapper that re-runs spec 012's full suite (`bash .claude/tests/mcp-recipes/run-all.sh`); asserts 6/6 PASS unchanged.

**Modify:**

- `.claude/rules/mcp-recipes.md` — append 4 MCP sections + new "Universal recipes" subsection + extend the signal table with OTel + Grafana rows. Update the hint output shape example to include possible new lines.
- `.mcp.json.example` — append OTel + Grafana blocks alongside the stack-aware four; add a `// === Universal recipes ===` divider and Filesystem + Git blocks below.
- `.claude/hooks/mcp-recipes-hint.sh` — add two new signal-detection branches (OTel files / env, Grafana env / dir). Add recipe-name printout lines for `opentelemetry-mcp` and `grafana-mcp`. No changes to existing branches.
- `CLAUDE.md` § MCP recipes — append a sentence noting the second leva covers OTel / Grafana / Filesystem / Git.

**Delete:** none.

## Alternatives considered

### One spec per added MCP (spec 014/015/016/017)

Rejected. The four MCPs share the same delivery shape (rule doc section + example block + maybe a hook branch), the same review surface, and the same fork-side activation workflow. Splitting them into four specs would 4x the SDD overhead with no proportional benefit. The "v1 ships 4" precedent in spec 012 supports bundling.

### Adding Filesystem + Git to the stack detector with always-fires logic

Rejected. The hint already fires on stack-aware signals; adding "always-fires for git-tracked / always-fires for any repo" would make it impossible to silent-by-default on uninteresting forks. Universal recipes are documented but not auto-suggested. Developer opts in by reading the rule doc and copying the block.

### Auto-detect Filesystem MCP path-allowlist from `.gitignore` or known project structure

Rejected. The path allowlist is a security boundary; auto-deriving it would (a) be wrong frequently and (b) tempt forks not to think about scope. Recipe documents the shape and notes path scope as the dev's responsibility.

### Grafana MCP via Docker only

Rejected as default. Forks running Claude Code without Docker (most laptops, many CI runners) would be locked out. Recipe ships the Go-binary-or-npm form per upstream README, with Docker as an alternative.

### Stack-detect for OTel via process/port scan

Rejected. Same reasoning as spec 012's "no process detection" decision — env-state dependent, brittle. File-existence + env-var signal is stable.

### Bundle 014 with the monorepo walk (spec 015) into one spec

Rejected. Different concerns: 014 adds recipes; 015 changes how the detector scans the filesystem. Bundling would double the review surface and force-order them. Kept separate; coordinate via the `detect_at <path>` refactor (whichever lands first owns the abstraction).

## Risks and unknowns

- **Git MCP archived status.** The official `@modelcontextprotocol/server-git` is in `servers-archived`. The recipe must either point at a maintained community fork or accept the archived path with a "verify before relying" gotcha. Open question 1 resolves this during research phase.
- **OpenTelemetry MCP backend lock-in.** The recipe likely assumes Jaeger / Tempo / Traceloop cloud at the OTLP endpoint. Forks without an OTel backend on hand will have the MCP fire but tools return empty. Recipe must surface this prominently in the when-to-enable section.
- **Grafana MCP env-var pile.** Likely needs `GRAFANA_URL`, `GRAFANA_API_KEY` minimum. Recipe must show the env-var indirection pattern (same as DBHub `DATABASE_URL` shape) and the no-commit-secret rule.
- **`.mcp.json.example` length growing.** Eight blocks is fine; sixteen would start to be unwieldy. If future specs add more, consider splitting `.mcp.json.example` into themed files (`.mcp.json.frontend.example`, `.mcp.json.observability.example`). Deferred to spec 016+ if real friction surfaces.
- **Test for "regression — spec 012 still GREEN".** Adding the wrapper test makes spec 014's run-all.sh slower (sub-shells out to spec 012's suite). Acceptable since suites are fast and the regression guard is the point. Alternative: run both suites manually in CI and document; reject because automation > discipline.
- **Stack-signal additions cascade into spec 012's gotchas section.** The "no false positives" promise of spec 012 covered the original four signals. Adding OTel + Grafana means more surface for false positives (e.g. a fork with `otel-collector.yaml.example` matches the glob). Mitigation: anchor the glob carefully (`otel-collector*.yaml` not `*otel*`) and document.

## Research / citations

- `docs/specs/012-mcp-recipes/` — sibling capacity, shape inherited.
- `docs/specs/015-monorepo-stack-detect/` — sibling spec; coordinate via the `detect_at <path>` refactor.
- `.claude/rules/mcp-recipes.md` — file being extended; verify the structural patterns before adding.
- [traceloop/opentelemetry-mcp-server](https://github.com/traceloop/opentelemetry-mcp-server) — primary candidate for OTel MCP; verify package name + install command + backend support at plan-execution time.
- [grafana/mcp-grafana](https://github.com/grafana/mcp-grafana) — Grafana MCP; verify Go-binary vs npm vs Docker shipping mode.
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) (active) and [servers-archived](https://github.com/modelcontextprotocol/servers-archived) — Filesystem MCP active; Git MCP archived (the open question).
- [mcpservers.org](https://mcpservers.org) — community catalogue; cross-reference for live alternatives if upstream archives diverge.
- Memory: `project_visibility_intent.md` — confirms this capacity still fits the agent-self-debug intent (Filesystem/Git extend the agent's view of project state; OTel/Grafana extend its view of runtime/observability).
