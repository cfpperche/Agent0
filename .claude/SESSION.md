# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 013 (lint-validator-extension) delivered em Agent0** — manifest-driven lint extension live no validator. 8/8 lint-validator scenarios GREEN; 7 outros suites (runtime-introspect, mcp-recipes, secrets-scan, supply-chain, harness-sync, session-state-isolation, githooks-activation) zero regression. Dogfood end-to-end via real `post-edit-validate.sh` ratificou: lint-advisory surfacing, non-block, non-counter-increment.

Specs 016+017+018 ainda **delivered + propagated** (sem mudança) — ver commits Agent0:
- `549965e` (018), `f33ffa8` (017), `373ece9` (016).

Shrnks (pyshrnk/shrnk/rshrnk) estão zero drift relativo aos commits acima — spec 013 ainda **não propagado** pros forks.

## WIP

Nada em flight. Spec 013 fechou completamente em Agent0:
- 8 RED tests + run-all.sh em `.claude/tests/lint-validator/`
- `.claude/validators/run.sh` estendido com 3-state dispatch JS+Python
- `.claude/hooks/post-edit-validate.sh` ajustado pra capturar validator stderr separado de stdout (descoberta cross-capacity mid-impl — ver Decisions)
- `.claude/rules/lint-validator.md` criado
- § "Lint validator" em CLAUDE.md (~210 palavras, densidade dos outros §s)
- `docs/specs/013-lint-validator-extension/tasks.md` 20/20 marcadas + Notes preenchidas

## Next steps

1. **Propagar spec 013 pros 3 shrnks** via `bash .claude/tools/sync-harness.sh --apply ~/<fork>` (precisa rodar em sessão fresca pra ver o sync action; cada fork verifica `git diff` antes de commit).
2. **Dogfood B1 (pyshrnk)** per `~/pyshrnk/docs/dogfood-plan.md` — frontend HTTP/HTML + pytest + spec 011 probe + spec 012 hint + Playwright MCP visual. Após sync de 013, dogfood pode validar lint-extension também (pyshrnk usa ruff?).
3. **Dogfood B2 (shrnk)** — analogous.
4. **Dogfood B3 (rshrnk)** — gap-finding pass (cargo NÃO está em spec 011 detector list; também não está em spec 013 — cargo clippy já está no validator base mas detect manifest-driven seria spec adicional).
5. **Follow-up specs das findings.** Provavelmente cargo detector pra spec 011 + possivelmente clippy-as-extension pra spec 013 (se valer separar).
6. **Spec 014** pode entrar em qualquer ponto.

Untracked carryovers (prior sessions, ainda sem review):
- `docs/specs/010-audit-forensics/`

## Decisions & gotchas

- **Spec 013 cross-capacity discovery: `post-edit-validate.sh` linha 65 fazia `2>&1` merge.** Pre-013 isso funcionou porque validator era silent em stderr. Once `lint-advisory:` started flowing through stderr, o merge prepende texto não-JSON e quebra o `jq` parse. Fix aplicado: capturar stderr separado (mktemp), surfacer pra própria stderr do hook (visível pro agente), passar só stdout pro `jq`. Documentado em `.claude/rules/lint-validator.md` § *Advisory format* + § *Gotchas*. Plan.md original não previu — pattern análogo ao spec 017 que descobriu `probe.sh` cross-capacity mid-impl.
- **Helpers compartilhados vs inline (decisão tasks 12-13):** inline em cada branch JS/Python. `biome_in_manifest` (jq sobre package.json) e `ruff_in_manifest` (grep sobre pyproject + requirements*.txt) não compartilham nada estrutural. State dispatch também inline — block contínuo de 3-state per-stack mais legível que três funções separadas.
- **3 negative tests trivialmente PASS no RED baseline (02, 05, 08).** Asseguram ausência de comportamento ainda inexistente; após impl continuam servindo como regression guards. Sinal RED→GREEN canônico preservado nos 5 testes load-bearing (01, 03, 04, 06, 07).
- **`--force-except=GLOB` é o per-file safety hatch.** Forks onde alguns customized são drift-only e outros são real customization. Hand-merge `.gitignore` é sempre real customization.
- **CLAUDE.md merge preserves Agent0 section order** (fix `grep -Fxv` que substituiu `comm -23 ... sort`).
- **`core.hooksPath` activation continua MANUAL por design** (Lazarus 2025). Spec 018 SessionStart hint surfaces o comando passivamente.
- **Spec 013 design pivot importante:** primeira sessão propôs "config + manifest" como gate duplo. Pivot pra "manifest-as-intent" (single signal). Config files (biome.json/[tool.ruff]) deixaram de ser sinal de intent — viraram customização opcional. Forks com biome.json mas sem `@biomejs/biome` em devDeps NÃO acionam lint até declararem. Trade-off ratificado pra coerência domain-agnostic.
- **Spec 013 single-stack v1 (Opção A):** validator hoje detecta 1 stack (primeiro if/elif vence). 013 herda essa limitação — multi-stack monorepo lint é problema de stack-detect (spec 015), não de 013. Spec 015 é prerequisite soft; quando land, 013 herda multi-stack automaticamente.
- **SESSION.md auto-injection ~2KB preview budget** — replace stale content; `git log` é o audit trail.
