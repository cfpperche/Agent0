# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Backlog drained** (session 2026-05-31/06-01, all committed + pushed). Highlights:
- **sync-harness propagation-advise leak fixed** (`dc3a93c`): dev-only hook was leaking into consumer
  `.claude/settings.json` (first-sync copy + sha early-out bypassed the jq strip); `merge_settings_json` now always
  routes through jq (absent file → `{}` base) and self-heals priors. Regression 38 (suite 38/38). Consumers re-synced:
  mei-saas `f91e714`, cognixse `f69488e` (self-healed).
- **Specs closed:** 131 / 099 / 035 verified + shipped (`b4f6cc5`); 036 superseded + 060 shipped (`c215125`);
  132/133/134 shipped earlier.
- **`/product` full-stack (Caminho A/B/C) closed** — already resolved by spec **079** (stack-aware Phase-5 handoff:
  umbrella + infra children + research-driven foundation child, no shipped stack code). Reminder `r-2026-05-19` done;
  residual gap (umbrella-execution driver) re-filed deferred. C-as-code-generator conflicts with no-shipped-stack-code.

## Active Work

No active implementation work. No open specs justify a build right now. Roadmap triaged 2026-06-01 (reminders pruned
12→6). Uncommitted: HANDOFF + `reminders.yaml`.

## Next Actions

**Near-term queue (founder-chosen 2026-06-01):**
1. **Fair OD re-match for spec 027** (reminder `r-2026-05-14`): the blind-judge 3.87-vs-4.73 is confounded (1 OD pass
   vs 4 refined iterations) — iterate the OD run to 4 passes OR re-judge vs the first-pass baseline. See
   `.agent0/memory/od-grounding-dogfood.md`.
2. **Test first real OD `--bump`/`--apply`** (reminder `r-2026-05-18`): network write-paths still untested; `--check`
   is verified. See `.claude/skills/product/scripts/sync-open-design.ts`.
3. **Re-evaluate fork-extension → smart-merge** (reminder `r-2026-05-25`): re-assess promoting the doc-only §Notes
   convention to marker-aware merge.

**Deferred / gated:** umbrella-execution driver in `/sdd` (`r-2026-05-31`, until a 2nd founder stalls — NOT a code
generator); agentskills.io re-snapshot (`r-2026-05-17`, due 08-17); agent0-atlas (≥10 forks). Optional paid
validations: real `/video --mode=generative` + `/image --tier=draft` need `FAL_KEY` + authorized spend.

## Decisions & Gotchas

- **Context layer (spec 134, shipped):** retrieval is substitutive inside `AGENT0_CONTEXT_INJECTION` budgets, hydrated
  snippets are evidence/pointers (source files canonical), no second memory index; diagnostics via `AGENT0_CONTEXT_DIAGNOSTIC=1`.
- **`/product` stance:** Agent0 ships mechanisms, not stack code (spec 079); the foundation child's `/sdd plan` researches
  the declared stack. A future `/sdd` build-driver must stay stack-agnostic — never a code generator.
- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks).
- **Env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` (combined `-r`+`-f`) + blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (stage + commit as separate calls); commits user-gated.
