# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 097 (`borderline-rules-disposition`) SHIPPED this session** (commit pending). 26/26 tasks, 9/9 ACs PASS. 3 rules split into thin CF slice + `<slug>-maintenance.md` memory companion: `runtime-capabilities`, `propagation-advisory`, `runtime-introspect`. 4 cross-refs rewired (`runtime-capture.sh`, `cc-platform-hooks.md`, `user-global-hooks-shadow.md` ×2). `memory-placement.md § Why three buckets` gained 3rd trigger codifying the **split** criterion — text in spec 097 task 19 is the operative definition for the next borderline audit.

Verification all green (drift-check, upstream + mei-saas sync, runtime-capabilities tests, memory-query). Repo dirty pre-commit: 097 deliverables + 3 pre-existing `??` carry-overs (`agent0-core-thesis.md`, spec 091 paused, spec 098 from another session — leave alone).

## Active Work

_None._

## Next Actions

1. **Commit spec 097.** Single PR by design (atomicity argument mirrors 096). New files: 3 memory entries + auto-regen of MEMORY.md. Modified: 3 rules + memory-placement.md + 1 hook + 2 memory entries (cross-ref rewires) + spec/tasks/notes for 097.
2. **Sync mei-saas `--apply`** (now covering 096 + 097): expect 2 of 097's thinned rules as stale-updated + 096's residue (3 removed orphan rules + governance/runtime hooks + memory-placement + AGENTS.md + CLAUDE.md + bench-hooks.sh + runtime-state/README). 0 customized-refused confirmed. Mei-saas-side review + commit is the human's call.
3. **Sync codexeng** (separate cycle, now covering 093+094+095+096+097): `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/codexeng` first; expect 1 customized-refuse on `.claude/skills/image/SKILL.md`.
4. **Investigate `docs/specs/098-codex-mcp-recipes-parity/`** — appeared untracked from another session; not touched this session.
5. **Spec 091** stays paused unless explicitly resumed.

## Decisions & Gotchas

- **Split discipline is now the canonical 3rd disposition.** `memory-placement.md § Why three buckets` codifies the rule: when consumer-binding (override grammar, env vars, behavior the agent invokes) mixes with maintainer-binding (extension contract, internal mechanism, drift tooling) in one rule file, split is the right disposition. Move-full only when ZERO consumer-binding content exists. Precedent file pair cited inline: `.claude/rules/runtime-introspect.md` ↔ `.claude/memory/runtime-introspect-maintenance.md`.
- **`propagation-advisory.md` is excluded from sync** by `COPY_CHECK_EXCLUDE` in `sync-harness.sh` (upstream-maintainer-only hook — shipping the discipline to consumers would emit FP advisories on their legitimate own-spec content). Spec 097's thinning of this rule therefore has zero downstream effect; only `runtime-capabilities.md` + `runtime-introspect.md` ship to mei-saas/codexeng.
- **Drift-check anchors all survive split.** `check-instruction-drift.sh` keys on path existence + 6 vocab terms + 12 minimum-set capability labels in `runtime-capabilities.md` — all live in the CF slice after split. No drift-check edit needed. Verified by Phase 6 task 21 run.
- **Cross-ref rewires are anchor-sensitive, not path-sensitive.** Of ~26 cross-refs to the 3 source rules, only 4 needed rewriting — the ones that cited a moved section name explicitly (`§ Inference heuristics`, `§ Gotchas` archaeology). Bare rule pointers + pointers to surviving CF sections stay valid. Future split audits should grep for `§ <heading>` anchors per moved section to find rewrite targets.
- **`<slug>-maintenance.md` naming locked at scale.** 3 new entries + existing `hook-chain-maintenance.md` precedent. `<slug>-internals.md` rejected in plan § Alternatives considered.
