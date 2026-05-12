# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 023 (session-stop-noop-aware) delivered + dogfood graduated 2026-05-12.** Stop hook now snapshots `git status --porcelain` at SessionStart and exits 0 silently when end-of-session porcelain is byte-identical to the snapshot — closing the false-positive on no-op or carryover-only sessions. Commit `d696135`. **End-to-end dogfood PASS:** parallel session `2adf213b` opened with identical carryover (`.gitignore` mod + clawd-pngs + `docs/specs/010-audit-forensics/` untracked), received `voltei`-only prompt, no edits during turn; Stop hook ran in 40ms with `preventedContinuation: false` + `hasOutput: false` — zero block. Pre-023 same conditions reproducibly blocked (observed at top of THIS session). Implementation: 2 hook edits + rule doc + 5 new test fixtures under `.claude/tests/session-handoff/`. Spec 017 test 02 also updated — its premise ("carryover state alone triggers Stop block") was the exact bug spec 023 fixed; the test now adds an in-session edit to legitimately exercise the block path. **All 10 capacity test suites green (80+ scenarios).**

**Spec 013 dogfood cycle closed — 7/7 applicable checkpoints PASS across 3 forks.** Last commit `605191a docs(013): close dogfood cycle — rshrnk state-c PASS` (post spec 020 B-series + spec 022 graduation). Coverage matrix:

| State | Pyshrnk (uv/ruff) | Shrnk (bun/biome) | Rshrnk (rust) |
| --- | --- | --- | --- |
| (c) silent skip | PASS | PASS | PASS |
| (b) declared+missing | PASS (uv-forced) | PASS (natural) | N/A by design |
| (a) declared+installed | PASS | PASS | N/A by design |

7 findings recorded in `docs/specs/013-lint-validator-extension/dogfood-findings.md`. 4 became `.claude/rules/lint-validator.md` § Gotchas amendments (`a7074a9`). Spec amendment for uv auto-sync caveat at `466eba5`.

Prior context (unchanged): B-series complete per spec 022/020/011 stack; spec 021 delivered + 2 dogfoods (Agent0 host); spec 019 scaffold in all forks; Parallel WIP convention registered.

## WIP

Nothing in flight. Spec 023 delivered + dogfood graduated, spec 013 cycle closed. Next pickup is spec 015 in a fresh session.

## Next steps

1. **Spec 015 (monorepo-stack-detect)** — **next pickup point.** SDD cycle already committed (spec+plan+tasks). Closes monorepo blind spot in `mcp-recipes-hint.sh` via `detect_at <path>` refactor + workspace-walk loop. Default set: `apps packages services workspaces`; override via `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS`. Depth cap 1. Coordinates with spec 014 — whichever lands first owns the `detect_at` abstraction. Plan/tasks drafted; open questions in spec are pre-impl decisions (default workspace dirs, signal label format, performance ceiling) — resolve before tests.
2. **Spec 014 (mcp-recipes-extras)** — sibling to 015. 4 new recipes (OpenTelemetry, Grafana, Filesystem, Git). Inherits `detect_at` refactor from 015. Needs WebFetch research pass on 4 open questions (Git MCP authoritative source, Grafana install path, OTel signal, universal-recipes divider) before plan execution.
3. **Spec 0YY runtime-introspect-extra-detect-injection (deferred).** Finding #6 from rshrnk B3. Revisit when new undetected stack appears (gleam, deno, hatch, bazel).
4. **Spec 021 in-fork dogfood** — low priority; Agent0-host runs validated end-to-end.
5. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption vs "no frameworks" rule conflict.
6. **Spec 010 closed without merge.** Scaffold deleted 2026-05-12 after re-evaluation with data (logs grew 3-6× but zero forensic queries surfaced; 5+ specs in interim resolved findings by live use, not log analysis). Feedback memory saved at `~/.claude/projects/-home-goat-Agent0/memory/feedback_speculative_observability.md`. Principle: rule-of-three demand test before any audit/observability/forensics tooling. Verified zero context interference from growing logs (no hook reads them; write-only black-box recorders by design).

End-of-session carryover:
- `.gitignore` unstaged (carryover from prior session — `prototypes/` ignore; left for owner-session)
- 7 untracked `clawd-arms-v*.png` files (parallel-session artifact, not from this session's spec 013 work)

## Decisions & gotchas

- **Spec 013 dogfood finding F1 — uv auto-sync collapses state-b.** Under `<py_prefix> = "uv run python"`, the probe `uv run python -m ruff --version` triggers uv's auto-resolve before invoking python. Adding ruff to `[dependency-groups]` causes uv to install transparently on the next run, bypassing the state-b advisory. Desirable ergonomics for uv-managed projects; advisory still fires in poetry/pdm/pip-only/PATH-isolated CI. Documented in spec.md scenario 6 Note + non-goals; rule doc § Gotchas.
- **Spec 013 dogfood finding F4 — `.claude/` must be linter-ignored.** Biome scans `.claude/` by default; `biome check --write` reformats harness files that sync-harness later flags as customized hash drift. Forks adopting biome must ship `biome.json` with `files.ignore: [".claude/**"]`. Recipe in rule doc.
- **Spec 013 dogfood finding F5 — biome defaults are opinionated (tabs).** First `biome check --write` reformatted 11 files in shrnk. Forks should configure `formatter.indentStyle` in `biome.json` if preserving conventions matters.
- **Spec 023 dogfood evidence shape.** Parallel session JSONL at `~/.claude/projects/-home-goat-Agent0/<sessionId>.jsonl` contains `system` entries with `subtype: "stop_hook_summary"`; the booleans `preventedContinuation` and `hasOutput` are the canonical Stop-hook decision signal (both false = clean pass). When validating session-handoff hook behavior in future cycles, query that JSONL rather than trying to instrument the hook itself.
- **Spec 023 design: porcelain snapshot beats mtime walk / transcript inspection.** The fix discriminates "this session changed something" via `git status --porcelain` snapshot at SessionStart vs snapshot at Stop — strictly stronger than mtime-based file-walk (catches `git add` of pre-existing untracked, catches `git restore` reverts) and avoids the transcript-shape coupling/cost of tool-call inspection. Empty-snapshot-on-git-failure is suppressed (write no file → fallback) to keep ambiguity conservative.
- **Spec 023 collateral: spec 017 test 02 needed an in-session edit.** Pre-023 the test relied on "carryover state alone triggers Stop block" — which is the very bug 023 closes. Tests that depend on hook block decisions must now ensure a real porcelain delta during the session, not just at session start.
- **Spec 022 design: native detector extension beats EXTRA_DETECT workaround.** Rshrnk finding #6 exposed that EXTRA_DETECT can only be set by the human pre-launch. The canonical fix is extending the native pair list. Spec 022 did this cleanly for cargo.
- **Cargo PASS heuristic: `Finished` line, NOT 500-char cap.** Cargo output frequently exceeds 500 chars in multi-crate projects due to per-crate `Compiling ...` lines.
- **Spec 022 composes with spec 020.** Failing `cargo test` (exit 101) routes through PostToolUseFailure; spec 020's branch reads `.error` → `stderr_head`, then spec 022's `test result: FAILED` pattern matches.
- **`browser_storage_state` / `browser_set_storage_state` do NOT exist in `@playwright/mcp@latest`** (carryover from spec 021). Save path: `browser_run_code_unsafe` calling `await page.context().storageState({ path })`. Reuse: `--storage-state=<file>` startup flag.
- **`core.hooksPath` activation remains MANUAL by design** (Lazarus 2025).
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is the audit trail.
