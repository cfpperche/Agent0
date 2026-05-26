# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Spec 094 (hook-chain-latency) is **plan+tasks ready**, implementation deferred to next session. `spec.md` filled with empirical baseline from the 2026-05-26 diagnostic; `plan.md` carries a 3-phase measure-first / data-driven / validate-and-regress structure; `tasks.md` has 27 numbered tasks across 7 layers + verification, with explicit decision gates at every conditional layer (L4 only if L0 confirms harness matcher support; L5 only if L3+L4 don't close budget). Target budget proposed at p95 ≤ 80 ms for fast-path Bash (3× improvement over current ~250 ms perceived; movable to ≤120 ms if Phase 1 shows IPC floor is higher).

Spec 093 (runtime-capability-registry) shipped + audited OK earlier this session; full validation suite green. Spec 094-pre (`chore(harness-sync)`) landed mid-session: removed `permissions.defaultMode: bypassPermissions` from upstream `.claude/settings.json`, added `.claude/tests/harness-sync/34-no-permission-bypass-in-upstream.sh` enforcement, extended `harness-sync.md` § settings.json merge strategy with the upstream-side discipline. User's `~/.claude/settings.json` already carries the bypass globally — ergonomics unchanged.

Specs 090, 092, 093 shipped. Spec 091 (sdd-debate-runner) remains paused and **untracked**.

## Active Work

_None._

## Next Actions

1. **Start spec 094 implementation at `tasks.md` Layer 0 task 1** — verify Claude Code's `matcher` field syntax for `PreToolUse(Bash)` hooks (payload-shape vs tool-name only). Pure research; no code change. Sources: official CC hook docs via `WebFetch` / `claude-code-guide` agent, or empirical sandbox probe if docs ambiguous. The finding gates L4 viability — record in `notes.md`.
2. After L0: work `tasks.md` top-to-bottom honoring the decision gates. L1+L2 (bench tooling + baseline capture) are unconditional; L3 (pre-jq probe) is unconditional; L4 (matcher narrowing) is conditional on L0; L5 (orchestrator consolidation) is conditional on L3+L4 not closing the budget. Don't skip the conditional language — each gate exists to prevent over-engineering.
3. The illustrative `planned: 094-mcp-parity` example in `docs/specs/093-runtime-capability-registry/spec.md § Scenario 1` is now misleading since 094 is hook-chain-latency. Cleanup deferred: leave as-is (`e.g.` example, not declaration) or rewrite to `NNN-mcp-parity`. Maintainer call.
4. Keep spec 091 paused and untracked unless explicitly resumed.

## Decisions & Gotchas

- 094 plan targets p95 ≤ 80 ms for fast-path Bash; budget is a Phase 2 proposal, not Phase 1 commitment. WSL2 fork+exec floor (~3-5 ms extra per spawn × 4 hooks) is the known risk to the math; document machine + OS in baseline JSON for honest cross-machine comparison.
- Language port (intervention c, bash → Go/Rust/Python binary) is categorically out of v1. Build step + deploy artifact + maintenance surface aren't earned until measurement proves bash short-circuit is the floor. Separate spec if needed.
- All 4 PreToolUse(Bash) hooks follow the identical `cat → jq → CMD → pattern → decide` pattern; consolidation (intervention b) is mechanically straightforward IF L3+L4 don't close budget. Held as fallback.
- Permission-mode bypass removed from project settings.json — fresh clones / template forks of Agent0 no longer inherit the bypass. Existing forks running `sync-harness.sh` were never affected (merge already excluded `permissions`); test 34 catches future drift.
- `.agent0/HANDOFF.md` is git-tracked but **outside** `sync-harness.sh`'s manifest by design — per-project state, never fork-managed.
- Block-once Stop semantics, edit-attribution tracker, porcelain-compare fallback unchanged from 092.
