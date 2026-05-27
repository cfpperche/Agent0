# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 096 (`maintainer-rules-to-memory`) SHIPPED + committed this session** (d1f13a0). All 23 tasks done, all 10 ACs verified. 3 rules moved rule→memory, ~14 rewires, CLAUDE.md/AGENTS.md pruned, memory-placement.md routing-tree tightened. AGENTS.md `## Hook chain latency` drift incidentally closed.

**Spec 097 (`borderline-rules-disposition`) SCAFFOLDED + spec/plan/tasks FILLED this session** (commit pending). ZERO implementation yet. 26 tasks across 6 phases. All 3 borderlines (`runtime-capabilities`, `propagation-advisory`, `runtime-introspect`) locked to `split` disposition in `plan.md § Per-file disposition` — each carves a `<slug>-maintenance.md` memory entry for the MB sections (extension contracts, inference heuristics, drift tooling, audit-log policy, dogfood archaeology) while the consumer-facing slice (override grammar, env vars, schema/probe/matrix the agent invokes) stays in `.claude/rules/`. Move-full and keep-as-is alternatives rejected in `plan.md § Alternatives considered`. `runtime-capabilities` surfaced as the third borderline mid-session by applying spec 096's criterion to a rule not in the original 25-rule audit.

Repo dirty post-commits: only the 3 pre-existing `??` carry-overs (`.claude/memory/agent0-core-thesis.md`, `docs/specs/091-sdd-debate-runner/` paused, `docs/specs/098-codex-mcp-recipes-parity/` from another session — leave alone).

## Active Work

_None._

## Next Actions

1. **Implement spec 097 Phase 1** (`docs/specs/097-borderline-rules-disposition/tasks.md`): repo-wide pre-flight grep (task 1, lesson from 096 applied — NOT per-dir), read `check-instruction-drift.sh` anchor checks (task 2), re-confirm CF/MB section boundaries on the 3 source rules cold (task 3). Cheap; decides whether plan stands.
2. **Phase 2 (create 3 memory entries)** → **Phase 3 (thin 3 rules)** → **Phase 4 (rewire 8 surfaces)** → **Phase 5 (memory-placement.md trigger #3)** → **Phase 6 (verification)** per `tasks.md`. Single PR by design (atomicity argument; mirrors 096).
3. **Sync codexeng** (separate cycle, now covering 093+094+095+096): `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/codexeng` first; expect 1 customized-refuse on `.claude/skills/image/SKILL.md`.
4. **Sync mei-saas apply.** Today's `--check` showed 4 stales + 3 removed (orphan rules from 096) + 0 customized-refused. `--apply` is safe; mei-saas-side review + commit is the human's call.
5. **Investigate `docs/specs/098-codex-mcp-recipes-parity/`** — appeared untracked from another session; not part of this session's work. Read before deciding what to do.

Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- **Spec 097 disposition: all 3 are split.** Move-full rejected per `plan.md § Alternatives considered` — each carries non-trivial consumer-facing surface (matrix Q&A, override grammar, probe schema) that consumers actively load. Split delivers the maintainer-binding extraction without breaking consumer load-bearing paths.
- **Spec 097 introduces `<slug>-maintenance.md` precedent** at scale (3 entries this PR) — first uses are `hook-chain-maintenance.md` (precedent) + `propagation-hygiene.md` (sibling). Naming locked to this shape; alternative `<slug>-internals.md` rejected in plan.
- **Repo-wide grep is canonical now.** Spec 096's notes-recorded lesson (per-dir grep missed `.claude/.runtime-state/README.md` + `site/src/i18n/capacities.ts`) is encoded in task 1 of spec 097 + task 20 (re-grep). Implementation must NOT regress to per-dir.
- **`memory-placement.md § Why three buckets, not two` gains 3rd trigger** in 097: the SPLIT discipline (096 established move-full; 097 establishes split as a distinct legitimate disposition). The wording in task 19 is the operative definition for the next borderline audit.
- **Drift-check anchor migration is the biggest risk.** If `check-instruction-drift.sh` anchors on a heading that moves (e.g. § *Update rule*), the drift check breaks. Task 2 verifies BEFORE Phase 2 starts.
