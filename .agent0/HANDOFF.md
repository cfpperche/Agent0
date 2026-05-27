# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 095 (`harness-consumer-vocab`) SHIPPED this session.** Single-PR mass-rename of `fork` → `consumer project` across the entire shipped surface — 9 implementation commits + spec/plan/tasks closure, all 7 ACs verified PASS. Empirical scope was **~700 occurrences** (handoff's 494 estimate was low — the bug-fix passes for adjectival compounds and shell-var leftovers added ~200 more touches). Specs 093 + 094 + 095 now ready for ONE consumer-side sync cycle.

Commits this session (top-to-bottom): `4764112` harness-sync.md + glossary, `c31e0ec` CLI tool, `ea0607b` rules-heavy, `9003ee2` rules-medium, `0b2a5ea` rules-light, `162e52f` propagation-pair (rule+hook+memory+test, atomic), `5f91494` hooks, `4b9f676` skills, `9f87f95` tests + adjectival-bug cleanup, `15ed5a4` CLAUDE.md + AGENTS.md + validator. (Plus task closure commit pending.)

Repo dirty: spec.md (status draft→shipped) + tasks.md (all `[x]`) + HANDOFF (this session) + 2 pre-existing `??` (`.claude/memory/agent0-core-thesis.md`, `docs/specs/091-sdd-debate-runner/` paused).

## Active Work

_None._

## Next Actions

1. **Sync mei-saas + codexeng** in ONE cycle covering 093 + 094 + 095. Dry-run first: `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/mei-saas` — verified clean this session (81 stale auto-updates, 22 new copies, 3 removed-orphan, **0 customized-refused from vocabulary**). Then `--apply`. Codexeng has 1 customized file (`.claude/skills/image/SKILL.md`) — expected refuse without `--force`.
2. **Push the 9 commits + closure commit** to origin/main when ready. Currently 18 commits ahead.
3. Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- **Bulk sed for renames is safe ONLY with post-rename audits.** Per-occurrence Edit was infeasible at ~700-occurrence scale; sed produced ~6 distinct bug classes (broken paths with embedded spaces, jq `$variable` mangled to `$consumer project`, process-fork meaning conflated with consumer-fork meaning, capitalized plurals missed, adjectival-compound bug where `\bfork\b` → `consumer project` made `fork-X` become `consumer project-X`, shell `FORK_ROOT`/`FORK_ARG`/`FORK_A`/`FORK_B`/`FORK_C` vars missed by `FORK_PATH`-only pattern). All caught and fixed via grep-audit + test-suite-as-oracle. **Lesson:** any future bulk rename needs at minimum: word-boundary patterns, longest-first ordering, separate protection for process-fork semantics (`__PROCESS_FORK_EXEC__` placeholder), separate shell-script-specific pre-pass for `$VAR` references, post-pass cleanup for `noun-` → `adjective-` compounds.
- **Task 12 (re-bake baseline) was N/A.** Plan misunderstanding — the baseline file (`.claude/harness-sync-baseline.json`) lives in the CONSUMER project (`$CONSUMER_ROOT/.claude/`), not upstream. There's no `--baseline` standalone mode in sync-harness.sh; `write_baseline()` runs automatically on every `--apply`. Consumer-side baseline regenerates on the next mei-saas / codexeng `--apply`.
- **Process-fork carve-out documented inline.** `.claude/rules/hook-chain-latency.md § Gotchas` keeps "WSL2 fork+exec overhead" — the only legitimate Unix-fork mention in shipped surface. `.claude/rules/harness-sync.md § Glossary` documents the third carve-out for git-operation "fork" usage.
- **Sync to consumer projects DEFERRED to next session** (still active from prior decision — now unblocked). The 3-spec batch (093 + 094 + 095) is ready as one cycle.
- **`.agent0/HANDOFF.md` is git-tracked but outside `sync-harness.sh`'s manifest by design** — per-project state, never consumer-managed.
