# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Specs 016 (harness-sync), 017 (session-state-isolation) e 018 (githooks-activation-hint) **delivered + propagated**. Todas committed em Agent0 e nos 3 shrnks.

Agent0:
- `549965e` feat(githooks-activation) — spec 018
- `f33ffa8` fix(session-handoff) — spec 017
- `373ece9` feat(harness-sync) — spec 016

Shrnks (zero drift em todos, 110 files up-to-date):
- pyshrnk `e963ff0` (specs 017+018), `92c7013` (specs 008-012+016)
- shrnk `94912c9`, `c10927a`
- rshrnk `f672358`, `a1a14e8`

Agent0 ativou `core.hooksPath .githooks` localmente como auto-verificação do hint silenciar. Cada shrnk precisa ativar manualmente — o hint do spec 018 vai aparecer no SessionStart do próximo `claude` em cada fork até a ativação rodar.

## WIP

**Spec 013 (lint-validator-extension)** — SDD cycle committed `0626642`. Design fully resolved across two sessions de iteração: manifest-as-intent (single-signal — manifesto declara linter = "fork quer"), 3-state operation (declared+installed roda; declared+missing emite advisory acionável com manager-specific install cmd; not declared skip silencioso), single-stack v1 com spec 015 como prerequisite pra multi-stack monorepo. **Impl pendente** — pickup point é task 1 em `docs/specs/013-lint-validator-extension/tasks.md` (auditoria pre-impl), depois 8 RED tests → 4 impl tasks → 7 validation/docs/dogfood.

Nada mais em flight.

## Next steps

1. **Spec 013 impl em sessão fresca** (sessão atual chama-se "retomar-013" mas ficará no 2 da sequência commit→finalize→fresh-session). Tasks 1-20 prontas pra execução TDD-pure.
2. Dogfood B1 (pyshrnk) per `~/pyshrnk/docs/dogfood-plan.md` — frontend HTTP/HTML + pytest validation + spec 011 probe + spec 012 hint observation + Playwright MCP visual.
3. Dogfood B2 (shrnk).
4. Dogfood B3 (rshrnk) — gap-finding pass (cargo NÃO está em spec 011 detector list).
5. Follow-up specs das findings (provavelmente cargo detector para spec 011 vindo de rshrnk).
6. Spec 014 pode entrar em qualquer ponto.

Untracked carryovers (prior sessions, ainda sem review):
- `docs/specs/010-audit-forensics/`

## Decisions & gotchas

- **`--force-except=GLOB` é o per-file safety hatch.** Forks onde alguns customized são drift-only (`session-start.sh`, `secrets-scan.md`, `validators/run.sh`) e outros são real customization (`.gitignore` com stack patterns). Sem ele, escolha era entre deixar drift OU clobbar customization — neither tenable.
- **`.gitignore` é sempre real customization.** Forks têm `.venv/`, `node_modules/`, `target/` etc. que Agent0 (template) não tem. Hand-merge no mesmo commit do sync.
- **CLAUDE.md merge preserves Agent0 section order** (fix do `grep -Fxv` que substituiu `comm -23 ... sort`).
- **`core.hooksPath` activation continua MANUAL por design** (Lazarus 2025). Spec 018 SessionStart hint surfaces o comando passivamente — discoverable sem cruzar a linha pra automation. `CLAUDE_SKIP_GITHOOKS_HINT=1` opta-out.
- **Spec 018 advisory fires NO Agent0 também antes da ativação.** Esperado: foi exatamente o sinal que motivou o spec; primeira validação foi rodar `git config core.hooksPath .githooks` em Agent0 e ver o block silenciar.
- **Dogfood plans estão atualizados** — referenciam capacities (probe.sh, mcp-recipes-hint.sh, githooks-activation hint) que AGORA EXISTEM nos shrnks. Executáveis de verdade.
- **Spec 013 design pivot importante:** primeira sessão propôs "config + manifest" como gate duplo. Pivot pra "manifest-as-intent" (single signal) veio do usuário questionar "por que não ler o manifesto direto?". Config files (biome.json/[tool.ruff]) deixaram de ser sinal de intent — viraram apenas customização opcional. Implicação: forks que tinham biome.json mas NÃO declararam @biomejs/biome em devDeps NÃO acionam lint até declararem. Trade-off ratificado pra coerência domain-agnostic + intent-via-ecosystem-native-signal.
- **Spec 013 single-stack v1 (Opção A):** validator hoje detecta 1 stack (primeiro if/elif vence). 013 herda essa limitação — multi-stack monorepo lint é problema de stack-detect (spec 015), não de 013. Spec 015 é prerequisite soft; quando land, 013 herda multi-stack automaticamente. Sem duplicar walk em 013.
- **SESSION.md auto-injection ~2KB preview budget** — replace stale content; `git log` é o audit trail.
