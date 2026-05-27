# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Spec 095 (`harness-consumer-vocab`) **plan locked this session, no commits yet.** All 4 outstanding open questions resolved + `plan.md` filled (was stub). Empirical rename scope: **494 occurrences across ~85 files** in the shipped surface — larger than the prior `~50` handoff estimate. Single-PR mass-rename strategy stands; commit-per-category structure planned for review.

Specs 093 + 094 shipped in prior sessions; still NOT synced to consumer projects by design (deferred until 095 lands — see Decisions).

Repo dirty: `M docs/specs/095-harness-consumer-vocab/spec.md` (OQs resolved) + `M docs/specs/095-harness-consumer-vocab/plan.md` (was stub, now filled) + `M .agent0/HANDOFF.md` (this session) + 2 pre-existing `??` (`.claude/memory/agent0-core-thesis.md`, `docs/specs/091-sdd-debate-runner/` paused).

## Active Work

_None._

## Next Actions

1. **Run `/sdd tasks` on spec 095** to draft `tasks.md` from the locked plan. Each task = one commit-category from `plan.md § Files to touch` (glossary host, CLI tool, rules-heavy, rules-medium, rules-light, propagation-pair, hooks, skills, tests, entrypoints, validator, re-baseline). ~11 task groups.
2. **Implement the rename** per `tasks.md`. Per-occurrence reviewed — NOT blind sed (legitimate git-operation "fork" usages survive). Final step: `bash .claude/tools/sync-harness.sh --baseline` re-bakes hashes; commit alongside the rename.
3. **Sync consumer projects** (mei-saas + codexeng) in one cycle covering 093 + 094 + 095 once rename PR merges. Codexeng has 1 customized file (`.claude/skills/image/SKILL.md`) — refuses without `--force` (correct).
4. Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- **Spec 095 OQ resolutions (2026-05-27):**
  - OQ #1 termo: three forms of `consumer` root — `consumer project` (prose), `consumer` (adjective), `<consumer-path>` (CLI positional).
  - OQ #2 surface: `shipped surface` (describes mechanism, decouples from "consumer" rename — future-proof).
  - OQ #3 paired memory: `.claude/memory/propagation-hygiene.md` IN scope (carve-out from Non-goal #1 — explicit doc-pair with `.claude/rules/propagation-advisory.md`, divergent vocab breaks the pair).
  - OQ #4 PR shape: single PR mass-rename with commit-per-category structure (incremental rejected — leaves codebase in mixed-vocab state for weeks).
- **Sync to consumer projects DEFERRED until 095 ships** (prior session decision, still active). Trade: 093 + 094 propagation blocked on 095 timeline.
- **Hook-chain-latency split = canonical precedent for paired rule↔memory.** Same pattern applies to any future capacity where the discipline binds upstream maintainer ≠ what consumers see.
- **`hook-chain-bench` routine does NOT auto-re-baseline** on `--check` non-zero — human decides revert / optimize / re-baseline.
- **Spec-094 follow-up #6 (real-session command-shape distribution) remains deferred** — synthetic bench set is faithful-enough proxy.
- **`.agent0/HANDOFF.md` is git-tracked but outside `sync-harness.sh`'s manifest by design** — per-project state, never consumer-managed.
- **Sync-baseline re-bake (final rename step) flips hashes on every shipped file.** When consumer-side `--check` runs next, expect "stale" on every shipped file — that's the OQ #5 deferred sync paying off in one big `--apply` cycle, not a regression. Document in PR body so consumer-sync session doesn't panic.
