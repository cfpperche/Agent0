# 013 — lint-validator-extension — tasks

_Generated from `plan.md` on 2026-05-11 (reformulado após design pivot: manifest-as-intent + single-stack v1). Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Pre-impl audit

- [ ] 1. Auditar `.claude/tests/` + `.claude/hooks/` + `.claude/tools/` por código pré-existente que faça parsing de `package.json` / `pyproject.toml` / `requirements*.txt` pra fins de lint. Esperado: nenhum (spec é nova). Reportar achados se houver — podem afetar Files to touch.

### RED tests (TDD discipline — escrever todos ANTES de tocar em run.sh)

- [ ] 2. Criar `.claude/tests/lint-validator/01-biome-declared-installed-runs.sh` — fixture com `package.json` declarando `@biomejs/biome` em devDeps + `node_modules/@biomejs/biome/package.json` fake; assert `command_str` do validator inclui `biome check` + ok=true
- [ ] 3. Criar `02-biome-not-declared-skips.sh` — fixture sem biome em deps; assert `command_str` SEM biome + stderr vazio (zero advisories)
- [ ] 4. Criar `03-biome-declared-missing-advisory.sh` — fixture com biome em devDeps mas sem `node_modules/`; assert stderr contém `lint-advisory: biome declared in package.json but not installed — run \`bun install\`` (ou variant manager) + ok=true (porque test+tsc passam mock) + `command_str` SEM biome
- [ ] 5. Criar `04-ruff-declared-installed-runs.sh` — fixture com `ruff` em `pyproject.toml` `[tool.poetry.dev-dependencies]` (ou variant PEP 621) + ruff binary mockable disponível; assert `command_str` inclui `ruff check .`
- [ ] 6. Criar `05-ruff-not-declared-skips.sh` — fixture sem ruff em manifestos; assert ausência de ruff no pipeline + zero advisories
- [ ] 7. Criar `06-ruff-declared-missing-advisory.sh` — declared em manifesto + binary 127; assert stderr advisory + comando install manager-specific. Cobrir pelo menos 2 managers (uv vs poetry) com variantes do mesmo cenário
- [ ] 8. Criar `07-lint-failure-blocks.sh` — fixture declared+installed + arquivo source com erro de lint (unused var, etc.); biome check fails; assert `ok=false`, exit não-zero, stderr tail carrega output do linter
- [ ] 9. Criar `08-opt-out-env-var.sh` — `CLAUDE_VALIDATOR_SKIP_LINT=1`; assert lint pulado independente de manifesto + advisory NÃO emitido + test/tsc continuam
- [ ] 10. Criar `.claude/tests/lint-validator/run-all.sh` — orchestrator mirror do pattern session-state-isolation/runtime-introspect
- [ ] 11. RED baseline: rodar `bash .claude/tests/lint-validator/run-all.sh` contra `run.sh` atual → confirmar **8/8 FAIL**

### Impl

- [ ] 12. Implementar helpers JS no `.claude/validators/run.sh` (block que roda condicionalmente no JS branch):
  - `biome_in_manifest()`: `[ -f package.json ] && jq -e '.devDependencies["@biomejs/biome"] // .dependencies["@biomejs/biome"] // empty' package.json >/dev/null 2>&1`
  - `biome_installed()`: `[ -f node_modules/@biomejs/biome/package.json ]`
  - `manager_install_cmd_js()`: case `$stack_subtype` (`bun` → `bun install`; `pnpm` → `pnpm install`; `npm` → `npm install`)
  - State dispatch inline (não-helper): se opt-out, skip; declared+installed → append ao `command_str`; declared+missing → emit advisory; not declared → noop
- [ ] 13. Implementar helpers Python análogos:
  - `ruff_in_manifest()`: grep ancorado em pyproject.toml + requirements*.txt
  - `ruff_installed()`: `$py_prefix -m ruff --version >/dev/null 2>&1`
  - `python_manager_install_cmd()`: case do lockfile (`uv.lock` → `uv sync`; `poetry.lock` → `poetry install`; `pdm.lock` → `pdm install`; default → `pip install ruff`)
  - State dispatch análogo
- [ ] 14. Compor stderr advisory templates pros 2 stacks:
  - `lint-advisory: biome declared in package.json but not installed — run \`<cmd>\``
  - `lint-advisory: ruff declared in <manifest> but not installed — run \`<cmd>\``
  - Emitidos VIA stderr antes do `bash -c "$command_str"` rodar
- [ ] 15. Adicionar opt-out env var no topo das duas branches (após stack detect, antes do manifest-detect):
  - `if [ "${CLAUDE_VALIDATOR_SKIP_LINT:-0}" = "1" ]; then : ; else <manifest+dispatch>; fi`

### Validation

- [ ] 16. Rodar `bash .claude/tests/lint-validator/run-all.sh` pós-impl → confirmar **8/8 GREEN**
- [ ] 17. Re-rodar suites completas pra zero-regressão:
  - runtime-introspect: should be 10/10 PASS (lint extension não toca probe.sh path)
  - mcp-recipes: 6/6 PASS
  - secrets-scan: 7/7 PASS
  - supply-chain: 12/12 PASS
  - harness-sync: 12/12 PASS
  - session-state-isolation: 7/7 PASS
- [ ] 18. Criar `.claude/rules/lint-validator.md` cobrindo:
  - § What fires, what advises (3 estados explicitados)
  - § Manifest-as-intent (rationale: manifesto é sinal nativo do ecossistema)
  - § Advisory format (manager-specific install commands)
  - § Opt-out (CLAUDE_VALIDATOR_SKIP_LINT=1)
  - § Single-stack v1 (referencia spec 015 como prerequisite pra multi-stack)
  - § Gotchas: peerDeps ignored, Python multi-dialect grep, uv tool install não cobre, requirements.txt case-insensitive
- [ ] 19. Adicionar § "Lint validator" em CLAUDE.md (~150 palavras, densidade dos outros §s — Spec-driven, Delegation, Secrets scan, Supply chain, Runtime introspect)
- [ ] 20. **Dogfood manual** — criar um fork-fixture (ou usar pyshrnk/shrnk se já sincado) com biome declarado em package.json mas não instalado; verificar empiricamente que validator emite advisory + não bloqueia. Mesmo pra ruff em projeto Python. Registrar resultado.

## Verification

_Cada item mapeia 1:1 a um critério de `spec.md` § Acceptance criteria._

- [ ] **Spec scenario 1 — Biome declared+installed roda** — `01-biome-declared-installed-runs.sh` GREEN
- [ ] **Spec scenario 2 — Biome not declared skip** — `02-biome-not-declared-skips.sh` GREEN
- [ ] **Spec scenario 3 — Biome declared+missing advisory** — `03-biome-declared-missing-advisory.sh` GREEN
- [ ] **Spec scenario 4 — Ruff declared+installed roda** — `04-ruff-declared-installed-runs.sh` GREEN
- [ ] **Spec scenario 5 — Ruff not declared skip** — `05-ruff-not-declared-skips.sh` GREEN
- [ ] **Spec scenario 6 — Ruff declared+missing advisory** — `06-ruff-declared-missing-advisory.sh` GREEN
- [ ] **Spec scenario 7 — Lint failure (running) blocks** — `07-lint-failure-blocks.sh` GREEN
- [ ] **Spec scenario 8 — Env var opt-out** — `08-opt-out-env-var.sh` GREEN
- [ ] **Spec static — Contrato JSON spec-002 preserved** — verificável via `jq` na saída do validator pós-impl
- [ ] **Spec static — `command` field reflete pipeline composto** — visível nos testes 01 + 04 (verificar substring)
- [ ] **Spec static — Zero config de linter committed** — `git ls-files | grep -E '(biome\.json|biome\.jsonc|ruff\.toml|\.ruff\.toml)'` retorna vazio
- [ ] **Spec static — Single-stack v1 documented as non-goal** — `spec.md` § Non-goals já cobre; rule doc reforça
- [ ] **Spec static — 6+ RED tests escritos antes da impl** — task 11 confirma 8/8 RED antes do refator

## Notes

_Anotações que surgirem durante execução; não pertencem ao plan.md mas úteis pra PR description ou leitor futuro._

- Decisão helpers compartilhados vs inline (task 12-13) — registrar qual e por quê
- Auditoria do task 1 — número de pre-existing consumers; previsão é zero
- Tempo de manifest-detect adicionado ao pipeline — medir se ficar > 50ms (jq + grep deveriam ser <20ms juntos)
- Fixture pra `node_modules/@biomejs/biome/package.json` fake (test 01) — criar mock minimal `{"name":"@biomejs/biome","version":"x"}` é suficiente
- Resultados do dogfood manual (task 20) — particularmente se a advisory message foi clara o suficiente pra ação imediata
- Caso de uso não coberto: fork que usa `bun --bun` runtime + biome instalado globalmente fora do node_modules. Aceitável skip; documentar no rule doc § Gotchas se virar problema
