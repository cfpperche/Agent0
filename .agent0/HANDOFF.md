# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Specs 132/133/134 shipped + pushed. **sync-harness propagation-advise leak fixed** (`dc3a93c`): the dev-only
`propagation-advise.sh` hook was leaking into consumer `.claude/settings.json` (first-sync verbatim copy + sha
early-out both bypassed the jq `strip_excluded`); `merge_settings_json` now always routes through jq (absent file →
`{}` base) and self-heals prior leaks. Regression test 38 added (suite 38/38). Consumers re-synced + pushed: mei-saas
(`f91e714`), cognixse (`f69488e`, leak self-healed).

**Bookkeeping pass (this session): three done-but-unclosed specs verified + flipped to shipped** — 131
(harness-entrypoint-sync; suites harness-sync/instruction-drift/multi-runtime-skills green, 5 open-questions resolved
inline), 099 (memory-multi-runtime; memory-multi-runtime/project-memory/agents-memory-block-budget green), 035
(user-prompt-framing; rule + CLAUDE.md section present, rule-only).

**Open-spec review pass (this session): backlog drained.** 036 → **superseded** (premises gone: `/prototype` became
`/product` via 045→048; `mcp-product-pipeline` discontinued `8cf6c5a`). 060 → **shipped**: A4→131, A5 closed
(defer-until-demand), A7 closed (covered by 075 quality-judge + 087 eval-scenarios); every §A/§B row dispositioned.

## Active Work

No active implementation work. No open specs justify a build right now. Doc-status edits from this session's two
passes are uncommitted (036/060 spec.md + 060 tasks.md + HANDOFF; the bookkeeping-pass files were committed `b4f6cc5`).

## Next Actions

1. Next real work is strategic + parked: **`/product` full-stack expansion** (reminder `r-2026-05-19`, Caminho C —
   a separate `/promote`-style skill, ~spec 064+) when the user prioritizes. Caminho B (extend `/product` into a
   monorepo generator) was rejected; Caminho A (`/sdd new` post-`/product`) is the existing workaround.
2. Optional paid validations: real `/video --mode=generative` + `/image --tier=draft` need `FAL_KEY` + authorized spend.

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
