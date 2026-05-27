# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Specs 093 (runtime-capability-registry) and 094 (hook-chain-latency) shipped in prior sessions; **NOT yet synced to consumer projects** by design — see Decisions below. This session bundled four commits:

- `5d7ad0c` — `.claude/routines/hook-chain-bench.md` added; cron registered via `install-routines.sh` (idempotent, this machine = leader).
- `d24c79b` — spec 093 leak fix (`094-mcp-parity` → `NNN-mcp-parity`).
- `83a4ed7` — **hook-chain-latency split**: `.claude/rules/hook-chain-latency.md` trimmed to consumer-facing (195→119 LoC); `.claude/memory/hook-chain-maintenance.md` (new, 85 LoC, NOT shipped) carries optimization techniques + 5-step contract for adding a new `PreToolUse(Bash)` hook. Test suite 3/3 PASS.
- `d5da2a4` — **spec 095 (`harness-consumer-vocab`) scaffolded**: rename "fork" → "consumer project" across shipped surface. Open Q #5 (sync timing) resolved this session — defer sync until rename ships.

Repo dirty: 1 M (`.agent0/HANDOFF.md` this session) + 2 ?? pre-existing (`.claude/memory/agent0-core-thesis.md`, `docs/specs/091-sdd-debate-runner/` paused).

## Active Work

_None._

## Next Actions

1. **Drive `/sdd plan` for spec 095** before doing anything else with consumer projects. 4 open questions remain in `docs/specs/095-harness-consumer-vocab/spec.md` (exact replacement term, propagation-hygiene memory scope, single vs incremental PR, glossary location). Plan can't lock until these are decided.
2. **Implement the rename** per the locked plan. Single PR mass-rename recommended — ~50 occurrences across `.claude/rules/*`, `.claude/hooks/*`, `.claude/tools/sync-harness.sh` (CLI flag), `.claude/tests/harness-sync/*`, `AGENTS.md`, `CLAUDE.md`.
3. **Then sync consumer projects** (mei-saas + codexeng) in ONE cycle covering 093 + 094 + 095 — `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 <consumer-path>` first to see drift, then `--apply`. Codexeng has 1 customized file (`.claude/skills/image/SKILL.md`) — will refuse without `--force` (correct default behavior).
4. Keep spec 091 paused and untracked unless explicitly resumed.

## Decisions & Gotchas

- **Sync to consumer projects DEFERRED until 095 ships.** User chose option (b): rename first, sync everything in one cycle. Trade: 093 + 094 propagation blocked on 095 timeline (open questions unanswered). Acceptable — mei-saas + codexeng are dogfood targets, not external deps. Recorded as resolved Open Q #5 in `docs/specs/095-harness-consumer-vocab/spec.md`.
- **Hook-chain-latency split mirrors the propagation-hygiene rule↔memory pair.** The rule keeps consumer-facing operational surface (budget, bench, baseline shape, regression check); the memory carries maintainer-only discipline (optimization playbook + new-hook contract). Consumer projects don't author `PreToolUse(Bash)` hooks, so the maintainer half was inert ship-cruft. Same pattern applies to any future capacity where the discipline binds upstream maintainer ≠ what consumers see.
- **`hook-chain-bench` routine does NOT auto-re-baseline.** On `--check` non-zero, it reports + stops; human decides revert / optimize / re-baseline. Silent re-baselining would mask the regression.
- **Spec-094 follow-up #6 (real-session command-shape distribution) remains deferred** — synthetic bench set is faithful-enough proxy per prior `if`-field empirical verification.
- **`.agent0/HANDOFF.md` is git-tracked but outside `sync-harness.sh`'s manifest by design** — per-project state, never consumer-managed.
