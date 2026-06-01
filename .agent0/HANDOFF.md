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

**`/product` full-stack discussion (this session): closed — already resolved by spec 079.** The reminder
`r-2026-05-19` (Caminho A/B/C) predated **079 product-stack-aware-handoff (shipped 2026-05-23)**, which 079 itself
states "closes the carryover Caminho-A/B/C decision": B rejected, A absorbed into `/product` Phase 5 (stack-aware
umbrella + infra children + research-driven foundation child), no stack code shipped. Caminho C as a code generator
now conflicts with that no-shipped-stack-code principle. Reminder `r-2026-05-19` marked done; residual gap re-filed
as `r-2026-05-31` (deferred).

## Active Work

No active implementation work. No open specs justify a build right now. Uncommitted: HANDOFF + `reminders.yaml`
(036/060 doc-status edits were committed `c215125`).

## Next Actions

1. **Residual gap, deferred** (reminder `r-2026-05-31`, rule-of-three n=1): an **umbrella-execution driver** in `/sdd`
   (e.g. `/sdd run <umbrella>`) — drive a `/product`-scaffolded umbrella's children in dependency order; stack-agnostic,
   ships no stack code. Real gap mei-saas hit (002-foundation stuck draft; materializing ~10 children is manual).
   Reopen as a `/sdd` spec when a 2nd founder stalls at umbrella execution. NOT a `/promote` code generator.
2. Optional paid validations: real `/video --mode=generative` + `/image --tier=draft` need `FAL_KEY` + authorized spend.

## Decisions & Gotchas

- **Context layer (spec 134, shipped):** retrieval is substitutive inside `AGENT0_CONTEXT_INJECTION` budgets, hydrated
  snippets are evidence/pointers (source files canonical), no second memory index; diagnostics via `AGENT0_CONTEXT_DIAGNOSTIC=1`.
- **`/product` stance:** Agent0 ships mechanisms, not stack code (spec 079); the foundation child's `/sdd plan` researches
  the declared stack. A future `/sdd` build-driver must stay stack-agnostic — never a code generator.
- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks).
- **Env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` (combined `-r`+`-f`) + blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (stage + commit as separate calls); commits user-gated.
