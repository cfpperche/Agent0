# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 015 (monorepo-stack-detect) delivered + dogfood graduated 2026-05-12.** Stack-detector hook (`.claude/hooks/mcp-recipes-hint.sh`) now walks depth-1 into common monorepo workspace dirs (default set: `apps packages services workspaces`) after the root scan, closing the monorepo blind spot documented in spec 012 § Gotchas. Override via `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` (space-separated; replaces default; empty string disables walk → root-only behaviour equivalent to spec 012 pre-015). Workspace-detected signals carry path prefix; root signals stay bare. Per-call `local_have_next` ensures a non-Next workspace still flips `have_browser`. **15/15 tests green** + **2 real-world dogfoods graduated**: (a) `/home/goat/workout/` surfaced 3 signals where pre-015 saw 1, plus bonus per-workspace `.env.example` detection; (b) synthetic `/home/goat/shrnk-mono/` (full-matrix fixture, root commit `49fe1fd`) exercised all 4 default workspace dirs with 7 signals + 4 recipes — end-to-end SessionStart fired clean (hook 251 ms, no collateral noise), Stop hook PASS no-op (spec 023 cross-validated). Open question #3 (perf instrumentation) **validated as unneeded** — ~100 syscalls in ~150 ms walk overhead. 4 commits: `63953cb refactor`, `f62aa16 tests RED`, `052c9d8 feat walk`, `e5c3ba4 docs`.

**Spec 023 (session-stop-noop-aware) delivered + dogfood graduated 2026-05-12.** Stop hook snapshots `git status --porcelain` at SessionStart and exits 0 silently when end-of-session porcelain is byte-identical — closes false-positive on no-op or carryover-only sessions. Commit `d696135`.

**Spec 013 dogfood cycle closed — 7/7 applicable checkpoints PASS across 3 forks** (pyshrnk uv/ruff, shrnk bun/biome, rshrnk rust). 7 findings recorded in `docs/specs/013-lint-validator-extension/dogfood-findings.md`.

Prior context (unchanged): B-series complete per spec 022/020/011 stack; spec 021 delivered + 2 dogfoods; spec 019 scaffold in all forks; Parallel WIP convention registered.

## WIP

Nothing in flight. Spec 015 delivered + 3 synthetic live-verify + 2 real-world dogfoods (workout + shrnk-mono) graduated. Findings appended to `docs/specs/015-monorepo-stack-detect/tasks.md` § Real-world dogfood.

## Next steps

1. **Spec 014 (mcp-recipes-extras)** — sibling to 015, now that the `detect_at` refactor is in place + dogfooded. 4 new recipes (OpenTelemetry, Grafana, Filesystem, Git). Inherits the path-parameterised function for free; **the shrnk-mono fixture is the ready-made target** to exercise the new branches against (already has OTel deps in apps/api candidate territory + alembic that could surface OTel etc.). Needs WebFetch research pass on 4 open questions (Git MCP authoritative source, Grafana install path, OTel signal, universal-recipes divider) before plan execution.
2. **shrnk-mono as recurring dogfood target.** `/home/goat/shrnk-mono/` (root commit `49fe1fd` in that repo) is a full-matrix synthetic fork — 9 workspaces across all 4 default dirs, Agent0 harness installed but NOT auto-tracked as a fork. Reuse for spec 014, future monorepo-related capacity tests, or as a baseline to compare against single-stack forks (shrnk/pyshrnk/rshrnk). Native git hooks NOT activated (Lazarus design) — activate manually before any real commit there.
3. **Spec 0YY runtime-introspect-extra-detect-injection (deferred).** Finding #6 from rshrnk B3. Revisit when new undetected stack appears (gleam, deno, hatch, bazel).
4. **Spec 021 in-fork dogfood** — low priority; Agent0-host runs validated end-to-end.
5. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption vs "no frameworks" rule conflict.

## Decisions & gotchas

- **Spec 015 design: per-workspace `local_have_next` not global.** The browser-non-Next branch's "skip if Next" check must be local to each `detect_at` call, not the global flag. Otherwise a non-Next workspace (e.g. `apps/api/` with just react) would NOT flip `have_browser` once another workspace already set `have_next`. Spec 015's locality preserves the "this workspace is a non-Next browser project" semantic across the walk.
- **Spec 015 default set is JS/TS-flavored.** `apps packages services workspaces` covers pnpm/Turborepo/Nx/Yarn but NOT Cargo (`crates/`), Python `src/<pkg>/`, Bazel. Forks override via env var. Cargo `crates/` deliberately omitted in v1 — revisit only if a real Cargo monorepo with embedded JS/Python sub-projects surfaces.
- **Spec 015 doc-vs-code drift fixed inline.** Pre-015 `mcp-recipes.md` showed `Stack signals detected: a, b, c` (CSV) but the hook always emitted space-separated. Updated the example to match actual code (space-separated). Format change is orthogonal to spec 015's behaviour; if anyone wants CSV later, that's a separate spec.
- **Spec 023 dogfood evidence shape.** Parallel session JSONL at `~/.claude/projects/-home-goat-Agent0/<sessionId>.jsonl` contains `system` entries with `subtype: "stop_hook_summary"`; `preventedContinuation` + `hasOutput` booleans are canonical Stop-hook decision signal.
- **Spec 023 design: porcelain snapshot beats mtime walk / transcript inspection.** Discriminates "this session changed something" via `git status --porcelain` snapshot at SessionStart vs Stop — strictly stronger than mtime walks.
- **Spec 022 design: native detector extension beats EXTRA_DETECT workaround.** Rshrnk finding #6 exposed that EXTRA_DETECT can only be set by the human pre-launch.
- **Cargo PASS heuristic: `Finished` line, NOT 500-char cap.** Cargo output frequently exceeds 500 chars in multi-crate projects.
- **Spec 013 dogfood F1 — uv auto-sync collapses state-b.** `uv run python -m ruff --version` triggers uv's auto-resolve before invoking python; declaring ruff in `[dependency-groups]` causes transparent install on next run.
- **Spec 013 dogfood F4 — `.claude/` must be linter-ignored.** Forks adopting biome must ship `biome.json` with `files.ignore: [".claude/**"]`.
- **`browser_storage_state` / `browser_set_storage_state` do NOT exist in `@playwright/mcp@latest`** (spec 021). Save path: `browser_run_code_unsafe` + `page.context().storageState({ path })`.
- **`core.hooksPath` activation remains MANUAL by design** (Lazarus 2025).
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is the audit trail.
