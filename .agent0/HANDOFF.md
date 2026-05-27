# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 096 (`maintainer-rules-to-memory`) SHIPPED this session, status shipped.** All 23 tasks done; all 10 acceptance criteria verified. Three rules moved `.claude/rules/` → `.claude/memory/` (`hook-chain-latency`, `compaction-continuity`, `rule-load-debug`); 11 cross-refs rewired across hooks/tools/memory/routines/tests + `.claude/.runtime-state/README.md` + `site/src/i18n/capacities.ts`; `CLAUDE.md` lost 2 managed-block sections (`## Hook chain latency`, `## Rule load debug`); `AGENTS.md` lost `## Rule load debug` (drift on `## Hook chain latency` incidentally closed); `memory-placement.md § Routing decision tree` tightened with the "consumer-side agent acts on it" test + explicit example list; `§ Why three buckets, not two` cites spec 096 as the second empirical trigger. Tests + upstream `--check` + `check-instruction-drift.sh` + `memory-query.sh list --type=reference` all clean.

Repo dirty: `.agent0/HANDOFF.md` (this update) + the modified spec 096 dir (`spec/plan/tasks/notes.md`) + the 14 source-tree changes from this spec + the 2 pre-existing `??` carried from before (`.claude/memory/agent0-core-thesis.md`, `docs/specs/091-sdd-debate-runner/` paused).

## Active Work

_None._

## Next Actions

1. **Commit + push spec 096.** Logical commit shape: one atomic change ("docs(096): ship maintainer-rules-to-memory — 3 rules → memory + ~14 rewires"). Repo is currently 18+ commits ahead from prior sessions plus this one.
2. **Sync codexeng** (one cycle now covering 093+094+095+096): `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/codexeng` first; expect 1 customized-refuse on `.claude/skills/image/SKILL.md`.
3. **Sync mei-saas apply.** Today's `--check` showed 4 stales + 3 removed (the three orphan rules) + 0 customized-refused. `--apply` is safe; mei-saas-side review + commit is the human's call.
4. **Consider follow-up spec for `propagation-advisory.md` + `runtime-introspect.md`** (the two BORDERLINE rules deferred from the 25-rule audit). Both carry user-facing override grammar mixed with maintainer-only extension mechanism — splits are non-trivial. Defer until a separate trigger surfaces.

Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- **Phase 1 grep was scoped too tightly.** Inherited the per-dir scope from `.claude/rules/propagation-hygiene.md § The shipped file class` (which is propagation-leak-focused). Missed `.claude/.runtime-state/README.md` (synced, ships) + `site/src/i18n/capacities.ts` (marketing-site URLs). Both caught at Phase 5 re-grep and fixed in flight. Lesson recorded in `docs/specs/096-maintainer-rules-to-memory/notes.md § Notes`: rewire-completeness greps should be repo-wide minus `.git`/`node_modules`/`docs/specs/`, not per-dir.
- **AGENTS.md drift closed incidentally.** `## Hook chain latency` was in `CLAUDE.md` but never propagated to `AGENTS.md` when spec 094 shipped. The CLAUDE.md prune of that section in this spec closes the drift with no separate change.
- **Minimal-touch (spec § OQ1) held.** Body content of the 3 moved files is verbatim except for self-referential "this rule" → "this entry" + 1 framing sentence on `hook-chain-latency.md` describing its now-peer relationship with `hook-chain-maintenance.md`. Decay engine will surface any further stale phrasings over time.
- **`memory-placement.md`'s routing tree now cites the moved slugs + spec 096 by number.** Propagation-advisory hook fired silently (informational, not blocking) — the citation is the canonical legitimate use the override exists for. Re-confirm at next propagation-hygiene audit; if it flags as drift, add `# OVERRIDE: propagation-exempt: routing-tree-example-list ...` then.
