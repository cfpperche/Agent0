# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 013 (lint-validator-extension) dogfooded em pyshrnk + shrnk — 6/6 state checkpoints PASS.** 7 findings documentadas em `docs/specs/013-lint-validator-extension/dogfood-findings.md`; 4 viraram amendments em `.claude/rules/lint-validator.md` § Gotchas.

Fork commits:
- pyshrnk `f2d002c chore(dogfood-013): adopt ruff via uv + fix unused import`
- shrnk `542d55c chore(dogfood-013): adopt biome via bun`

Specs antes deste ciclo (sem mudança): 021 delivered + 2 dogfoods (Agent0 host), 020 delivered + 3 dogfood passes (pyshrnk graduado, shrnk B2.2 graduado, rshrnk em andamento), 019 scaffold em todos forks.

## WIP

Nada em flight. Spec 013 totalmente fechado: design (`0626642`) → impl (`3677807`) → dogfood (`f2d002c` + `542d55c`) → rule amendments + findings doc (este ciclo).

## Next steps

1. **Aguardar rshrnk completar dogfood spec 020.** Quando libertar, rodar dogfood spec 013 em rshrnk — note: rshrnk é Rust, NÃO entra em scope de 013 (lint-validator-extension cobre JS/TS+Python; clippy já está no validator base). Spec 013 dogfood em rshrnk = confirmar state-c silent-skip para Rust stack + ler dogfood-findings.md pra contexto sobre `.claude/` ignore se rshrnk adicionar lint scripts custom.
2. **Spec 021 in-fork dogfood** (LinkedIn/X dogfood foi em Agent0 host; in-fork pendente). Baixa prioridade — workflow funciona, só falta validar fork-grade activation cycle.
3. **Spec 022+ (a definir).** Spec 014 + 015 ainda em queue.
4. **Pyshrnk CLAUDE.md reconciliation** (carryover do SESSION anterior) — Starlette adoption documentado com spec-009 OVERRIDE marker mas regra "no frameworks" ainda diz o oposto. Amend rule ou revert Starlette.
5. **rshrnk Cargo.{lock,toml} dirty** (carryover) — pre-existing WIP. Decidir destino.

## Parallel WIP

- **paused (since 2026-05-11) — spec 010 audit-forensics scaffolded but never committed.** Paths: `docs/specs/010-audit-forensics/` (`spec.md` + `plan.md` + `tasks.md` stub). Owner-session ended in joint abandonment ("demanda real é zero — speculative observability, não 'preciso responder X e não consigo'"). Left untracked pending decision. **Other sessions: leave untouched.** Revisit only if a concrete forensic question against `.claude/*-audit.jsonl` surfaces; otherwise the next cleanup pass can delete the scaffold.

## Decisions & gotchas

- **Spec 013 dogfood finding F1 — uv auto-sync collapses state-b.** Sob `<py_prefix> = "uv run python"`, o probe `uv run python -m ruff --version` triggers uv's auto-resolve antes de invocar python. Adicionar ruff em `[dependency-groups]` faz uv instalar transparentemente no próximo run, bypass da state-b advisory. Comportamento desejável pra ergonomia de adoção em projetos uv. Advisory ainda fire em poetry/pdm/pip-only/PATH-isolated CI. Documentado em `.claude/rules/lint-validator.md` § Gotchas.
- **Spec 013 dogfood finding F4 — `.claude/` deve ser linter-ignored.** Biome scan default inclui `.claude/`; `biome check --write` reformata harness files que sync-harness depois flag como customized hash drift. Forks adotando biome precisam shippar `biome.json` ignorando `.claude/**`. Documentado em rule doc com snippet pronto.
- **Spec 013 dogfood finding F5 — biome defaults são opinionados (tabs).** Primeira `biome check --write` reformatou 11 arquivos em shrnk. Forks devem configurar `formatter.indentStyle` no `biome.json` se quiserem preservar convenções. Documentado.
- **Spec 013 dogfood finding F6 — supply-chain composição com state-a.** Advisory diz "run `bun install`", agente acha bate em spec 009 block, precisa de OVERRIDE marker multi-line. Inter-spec composition validada (spec 013 dogfood respeita spec 009).
- **Spec 013 dogfood F2+F3 — lint debt real surfacado imediatamente.** Pyshrnk: 1 unused import em `tests/test_server.py` (corrigido no commit). Shrnk: 15 erros (3 reais + 12 formatting). Valor delivered no day-one da adoção.
- **`browser_storage_state` / `browser_set_storage_state` NÃO existem em `@playwright/mcp@latest`** (carryover spec 021). Save path: `browser_run_code_unsafe` chamando `await page.context().storageState({ path })`. Reuse: `--storage-state=<file>` startup flag.
- **Sandbox do Playwright MCP bloqueia `require('fs')` / `await import('fs/promises')`** com `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`. `--storage-state` startup é a via canônica.
- **`core.hooksPath` activation continua MANUAL por design** (Lazarus 2025). Spec 018 SessionStart hint surfaces o comando passivamente.
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is audit trail.
