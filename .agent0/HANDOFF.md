# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 096 (`maintainer-rules-to-memory`) SCAFFOLDED this session, status draft.** `spec.md` + `plan.md` + `tasks.md` drafted; ZERO implementation yet. 23 tasks across 5 phases. Triggered by a 25-rule audit (this session): 3 maintainer-binding capacity docs (`hook-chain-latency.md`, `compaction-continuity.md`, `rule-load-debug.md`) need to move from `.claude/rules/` → `.claude/memory/` because consumers never act on them. 2 BORDERLINE rules (`propagation-advisory.md`, `runtime-introspect.md`) deferred — split is non-trivial. 20 KEEP confirmed as-is.

**mei-saas sync APPLIED this session.** `bash sync-harness.sh --apply --agent0-path=/home/goat/Agent0 /home/goat/mei-saas` → 22 copied + 81 stale-updated + 3 removed + 0 customized-refused + 0 overwritten. 97 files modified in mei-saas working tree; review + commit there is the human's call. Codexeng NOT YET synced (1 known customized file `.claude/skills/image/SKILL.md` — expected refuse without `--force`).

Repo dirty: `.agent0/HANDOFF.md` (this update) + the new `docs/specs/096-maintainer-rules-to-memory/` (4 files) + 2 pre-existing `??` carried from before (`.claude/memory/agent0-core-thesis.md`, `docs/specs/091-sdd-debate-runner/` paused).

## Active Work

_None._

## Next Actions

1. **Implement spec 096 Phase 1** (`docs/specs/096-maintainer-rules-to-memory/tasks.md`): pre-flight grep — task 1 inventories the rewire surface, task 2 verifies no runtime `cat`/`head` reads on the 3 paths (blocker check). Cheap, decides whether plan stands.
2. **Phase 2-4 implementation** after Phase 1 clears: create 3 memory files with frontmatter → rewire ~7 cross-refs in `.claude/{hooks,tools}/` + other rules → delete 3 rule files → prune `CLAUDE.md` (`## Rule load debug` line 99, `## Hook chain latency` line 115) + `AGENTS.md` (`## Rule load debug` line 79 only; `## Hook chain latency` never propagated to AGENTS.md — pre-existing drift this spec closes) + tighten `memory-placement.md` § Routing decision tree.
3. **Phase 5 verification**: re-grep, run `.claude/tests/{hook-chain-latency,compaction-continuity}/run-all.sh`, sync `--check` upstream + against mei-saas.
4. **Sync codexeng** (separate cycle covering 093+094+095+096): `bash sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/codexeng` first; expect 1 customized refuse.
5. **Push origin/main** when 096 lands (currently 18+ commits ahead from prior session + the new commit from this one).

Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- **Audit criterion that drove the 3 MOVEs:** "does a consumer that only CONSUMES the harness (not extends) benefit from this content being in their agent's context?" Sub-agent classification mis-labeled `harness-sync.md` / `secrets-scan.md` / `supply-chain.md` as maintainer-only — they actually carry user-facing override grammar. Recalibrated to KEEP. Lesson: classify-by-criterion is right, but trust own context over a sub-agent's labels on rules already loaded.
- **AGENTS.md drift discovered mid-plan.** `## Hook chain latency` exists in `CLAUDE.md` but NOT in `AGENTS.md` — never added when spec 094 shipped. Spec 096 incidentally closes this.
- **mei-saas sync prediction was exact** (81 stale + 22 new + 3 removed-orphan + 0 customized-refused; actual matched 1:1). The 3 removed are vocab-rename orphans from spec 095 (`*-fork-*.sh` → `*-consumer-*.sh`).
- **`.agent0/HANDOFF.md` is git-tracked but outside `sync-harness.sh`'s manifest by design** — per-project state, never consumer-managed.
