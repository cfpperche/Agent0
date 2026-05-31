# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Specs 132 and 133 are shipped and pushed (`288f17e`/`42d0891` video skill; `69cdf2c` image fal REST migration).
Spec 091 debate runner is deferred and pushed (`31a6930`). Prior clean state is now superseded by new draft work.

**Spec 134 — context-layer-rag-hydration: SHIPPED.** Added deterministic local context retrieval
(`.agent0/tools/context-retrieve.sh` + helper) over context rules, memory projection/metadata, specs, and handoff.
`context-inject.sh` now preserves deterministic rule capsules as a floor, then fills remaining prompt budget with
retrieval pointers. V1 is lexical/source-pointer based only: no embeddings/vector DB, product-code indexing, daemon,
or cross-project retrieval. Claude/Codex debate captured in `debate.md`; acceptance marked shipped after validation.

## Active Work

No active implementation work. Spec 134 is implemented and validated. Working tree still contains uncommitted spec 134
changes; commit/push not requested yet.

## Next Actions

1. Optional: commit spec 134 changes if the user asks.
2. Optional paid validations from prior work remain: real `/video --mode=generative` and real `/image --tier=draft`
   need `FAL_KEY` + user-authorized spend.

## Decisions & Gotchas

- **Spec 134 emerging stance:** RAG vocabulary is secondary; the feature should consolidate the context layer. Hydrated
  snippets are evidence/pointers, not source of truth; source files remain canonical.
- **Budget stance:** retrieval should be substitutive inside existing `AGENT0_CONTEXT_INJECTION` budgets, not an added
  model-visible dump. Diagnostics should reuse `AGENT0_CONTEXT_DIAGNOSTIC=1` or an explicit debug command.
- **Memory stance:** do not create a second canonical memory index. Either adapt existing `MEMORY.md`/`memory-query.sh`
  or keep memory out of v1 until the non-memory corpus path is proven.
- **Generated context index:** likely gitignored under `.agent0/.context-index/`; shipped mechanisms/config stay under
  `.agent0/` and sync-harness baseline-managed.
- **Validation evidence for 134:** context-retrieval, context-injection, memory-multi-runtime, runtime-capabilities,
  harness-sync, session-handoff-multi-runtime, project-memory, instruction-drift, and `git diff --check` passed.
  Live dogfood also passed in a real Claude Code session: `retrieval: enabled floor_fragments=3` left two retrieval
  slots, which hydrated spec evidence-pointers with `source_class`/`authority`/`reason`/`freshness`/`anchor`.
- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks).
- **Env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` (combined `-r`+`-f`) + blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (stage + commit as separate calls); commits user-gated.
