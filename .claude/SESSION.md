# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Two specs in flight, both draft, both untracked:

- **010-audit-forensics** — `spec.md` filled (prior session), awaiting user review. `plan.md` / `tasks.md` still template placeholders.
- **011-runtime-introspect** — `spec.md` filled THIS session. Open questions block `/sdd plan`. `plan.md` / `tasks.md` still template placeholders.

Eleven shipped capacities on `main` still green. No code changes this session — only spec + memory.

## WIP

`docs/specs/011-runtime-introspect/spec.md` — capacity that lets the agent close edit→verify loop on its own work without human ratification. v1 = `PostToolUse(Bash)` captures last test/build/run output to `.claude/.runtime-state/last-run.json`; agent reads it via `.claude/tools/probe.sh last-run`. Hook + shell tool grain (NOT MCP); v1 stacks Node + Python only.

4 open questions in spec, all with proposals:
1. Tail size cap (proposal: 4 KB head + 4 KB tail per stream)
2. Detector allowlist boundary (proposal: strict + env-var `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT`)
3. Audit log adicional? (proposal: only `last-run.json`, no per-Bash audit row — avoid the supply-chain skip-not-install noise pattern)
4. Dogfood target (user said "encurtador de links" — pick rshrnk / pyshrnk / new Node fork)

Next user turn: resolve the 4 questions → `/sdd plan`.

## Next steps

1. User resolves 011 open questions → `/sdd plan` → `/sdd tasks` → RED-tests-first implementation
2. 010-audit-forensics also still needs user confirmation (deferred during this session in favour of 011 conversation)
3. Follow-up spec after 011 ships: `.mcp.json.example` documenting Playwright / Chrome DevTools / DBHub as opt-in MCPs forks install for browser/DB introspection (explicit non-goal of 011)

Deferred (still queued from prior sessions):
- Second cargo dogfood pass (graduation by yield-decay rule)
- Go dogfood pass (low expected yield)

## Decisions & gotchas

- **Visibility wedge framed as agent-self-debug, NOT human dashboard.** User explicit 2026-05-11. Saved to memory `project_visibility_intent.md`. OTel / Grafana / Langfuse paths acknowledged as valuable but de-prioritised for this wedge. Future visibility specs should respect this scoping unless user signals otherwise.
- **Scope split: build vs adopt.** 011 builds only what no mature MCP covers (generic local test/build capture). Playwright MCP (Microsoft 32k★), Chrome DevTools MCP (Google), DBHub (Bytebase), laravel-boost, next-devtools-mcp, rails-mcp-server already cover their slices — Agent0 must NOT duplicate; recommends them via `.mcp.json.example` in a follow-up.
- **Hook + shell tool, not MCP server in v1.** Follows the grain of all existing capacities (governance, delegation, supply-chain, secrets — all hook-based, none MCP). Promotion to MCP only if shell-tool friction warrants follow-up; mirrors delegation-gate evolution.
- **Detector allowlist mirrors supply-chain manager table.** Strict list of `<tool> <verb>` pairs (bun test / npm test / pnpm test / yarn test / npm run build / pytest / python -m pytest). Same FP-vs-FN tradeoff conversation as supply-chain. Extension via env var, not hardcode bloat.
- **Two web-research delegations ran this session** (MCP introspection landscape + agent self-observability landscape). Citations live in `011/spec.md` § Context / references and in agent task results — not in SESSION.md (cache pressure).
- **SESSION.md auto-injection has a ~2KB preview budget.** When SESSION.md exceeds it, only the preview reaches context; the full file lands at a persisted path on disk. Keep this file terse — replace stale content rather than appending (`git log` is the audit trail).
