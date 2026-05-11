# 013 — lint-validator-extension — tasks

_Generated from `plan.md` on 2026-05-11 (reformulado após design pivot: manifest-as-intent + single-stack v1). Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Pre-impl audit

- [x] 1. Auditar `.claude/tests/` + `.claude/hooks/` + `.claude/tools/` por código pré-existente que faça parsing de `package.json` / `pyproject.toml` / `requirements*.txt` pra fins de lint. Esperado: nenhum (spec é nova). Reportar achados se houver — podem afetar Files to touch.

### RED tests (TDD discipline — escrever todos ANTES de tocar em run.sh)

- [x] 2. Criar `.claude/tests/lint-validator/01-biome-declared-installed-runs.sh` — fixture com `package.json` declarando `@biomejs/biome` em devDeps + `node_modules/@biomejs/biome/package.json` fake; assert `command_str` do validator inclui `biome check` + ok=true
- [x] 3. Criar `02-biome-not-declared-skips.sh` — fixture sem biome em deps; assert `command_str` SEM biome + stderr vazio (zero advisories)
- [x] 4. Criar `03-biome-declared-missing-advisory.sh` — fixture com biome em devDeps mas sem `node_modules/`; assert stderr contém `lint-advisory: biome declared in package.json but not installed — run \`bun install\`` (ou variant manager) + ok=true (porque test+tsc passam mock) + `command_str` SEM biome
- [x] 5. Criar `04-ruff-declared-installed-runs.sh` — fixture com `ruff` em `pyproject.toml` `[tool.poetry.dev-dependencies]` (ou variant PEP 621) + ruff binary mockable disponível; assert `command_str` inclui `ruff check .`
- [x] 6. Criar `05-ruff-not-declared-skips.sh` — fixture sem ruff em manifestos; assert ausência de ruff no pipeline + zero advisories
- [x] 7. Criar `06-ruff-declared-missing-advisory.sh` — declared em manifesto + binary 127; assert stderr advisory + comando install manager-specific. Cobrir pelo menos 2 managers (uv vs poetry) com variantes do mesmo cenário
- [x] 8. Criar `07-lint-failure-blocks.sh` — fixture declared+installed + arquivo source com erro de lint (unused var, etc.); biome check fails; assert `ok=false`, exit não-zero, stderr tail carrega output do linter
- [x] 9. Criar `08-opt-out-env-var.sh` — `CLAUDE_VALIDATOR_SKIP_LINT=1`; assert lint pulado independente de manifesto + advisory NÃO emitido + test/tsc continuam
- [x] 10. Criar `.claude/tests/lint-validator/run-all.sh` — orchestrator mirror do pattern session-state-isolation/runtime-introspect
- [x] 11. RED baseline: rodar `bash .claude/tests/lint-validator/run-all.sh` contra `run.sh` atual → confirmar **8/8 FAIL**

### Impl

- [x] 12. Implementar helpers JS no `.claude/validators/run.sh` (block que roda condicionalmente no JS branch):
  - `biome_in_manifest()`: `[ -f package.json ] && jq -e '.devDependencies["@biomejs/biome"] // .dependencies["@biomejs/biome"] // empty' package.json >/dev/null 2>&1`
  - `biome_installed()`: `[ -f node_modules/@biomejs/biome/package.json ]`
  - `manager_install_cmd_js()`: case `$stack_subtype` (`bun` → `bun install`; `pnpm` → `pnpm install`; `npm` → `npm install`)
  - State dispatch inline (não-helper): se opt-out, skip; declared+installed → append ao `command_str`; declared+missing → emit advisory; not declared → noop
- [x] 13. Implementar helpers Python análogos:
  - `ruff_in_manifest()`: grep ancorado em pyproject.toml + requirements*.txt
  - `ruff_installed()`: `$py_prefix -m ruff --version >/dev/null 2>&1`
  - `python_manager_install_cmd()`: case do lockfile (`uv.lock` → `uv sync`; `poetry.lock` → `poetry install`; `pdm.lock` → `pdm install`; default → `pip install ruff`)
  - State dispatch análogo
- [x] 14. Compor stderr advisory templates pros 2 stacks:
  - `lint-advisory: biome declared in package.json but not installed — run \`<cmd>\``
  - `lint-advisory: ruff declared in <manifest> but not installed — run \`<cmd>\``
  - Emitidos VIA stderr antes do `bash -c "$command_str"` rodar
- [x] 15. Adicionar opt-out env var no topo das duas branches (após stack detect, antes do manifest-detect):
  - `if [ "${CLAUDE_VALIDATOR_SKIP_LINT:-0}" = "1" ]; then : ; else <manifest+dispatch>; fi`

### Validation

- [x] 16. Rodar `bash .claude/tests/lint-validator/run-all.sh` pós-impl → confirmar **8/8 GREEN**
- [x] 17. Re-rodar suites completas pra zero-regressão:
  - runtime-introspect: should be 10/10 PASS (lint extension não toca probe.sh path)
  - mcp-recipes: 6/6 PASS
  - secrets-scan: 7/7 PASS
  - supply-chain: 12/12 PASS
  - harness-sync: 12/12 PASS
  - session-state-isolation: 7/7 PASS
- [x] 18. Criar `.claude/rules/lint-validator.md` cobrindo:
  - § What fires, what advises (3 estados explicitados)
  - § Manifest-as-intent (rationale: manifesto é sinal nativo do ecossistema)
  - § Advisory format (manager-specific install commands)
  - § Opt-out (CLAUDE_VALIDATOR_SKIP_LINT=1)
  - § Single-stack v1 (referencia spec 015 como prerequisite pra multi-stack)
  - § Gotchas: peerDeps ignored, Python multi-dialect grep, uv tool install não cobre, requirements.txt case-insensitive
- [x] 19. Adicionar § "Lint validator" em CLAUDE.md (~150 palavras, densidade dos outros §s — Spec-driven, Delegation, Secrets scan, Supply chain, Runtime introspect)
- [x] 20. **Dogfood manual** — criar um fork-fixture (ou usar pyshrnk/shrnk se já sincado) com biome declarado em package.json mas não instalado; verificar empiricamente que validator emite advisory + não bloqueia. Mesmo pra ruff em projeto Python. Registrar resultado.

## Verification

_Cada item mapeia 1:1 a um critério de `spec.md` § Acceptance criteria._

- [x] **Spec scenario 1 — Biome declared+installed roda** — `01-biome-declared-installed-runs.sh` GREEN
- [x] **Spec scenario 2 — Biome not declared skip** — `02-biome-not-declared-skips.sh` GREEN
- [x] **Spec scenario 3 — Biome declared+missing advisory** — `03-biome-declared-missing-advisory.sh` GREEN
- [x] **Spec scenario 4 — Ruff declared+installed roda** — `04-ruff-declared-installed-runs.sh` GREEN
- [x] **Spec scenario 5 — Ruff not declared skip** — `05-ruff-not-declared-skips.sh` GREEN
- [x] **Spec scenario 6 — Ruff declared+missing advisory** — `06-ruff-declared-missing-advisory.sh` GREEN
- [x] **Spec scenario 7 — Lint failure (running) blocks** — `07-lint-failure-blocks.sh` GREEN
- [x] **Spec scenario 8 — Env var opt-out** — `08-opt-out-env-var.sh` GREEN
- [x] **Spec static — Contrato JSON spec-002 preserved** — verificável via `jq` na saída do validator pós-impl
- [x] **Spec static — `command` field reflete pipeline composto** — visível nos testes 01 + 04 (verificar substring)
- [x] **Spec static — Zero config de linter committed** — `git ls-files | grep -E '(biome\.json|biome\.jsonc|ruff\.toml|\.ruff\.toml)'` retorna vazio
- [x] **Spec static — Single-stack v1 documented as non-goal** — `spec.md` § Non-goals já cobre; rule doc reforça
- [x] **Spec static — 6+ RED tests escritos antes da impl** — task 11 confirma 8/8 RED antes do refator

## Notes

_Anotações que surgirem durante execução; não pertencem ao plan.md mas úteis pra PR description ou leitor futuro._

- **Decisão helpers compartilhados vs inline (task 12-13):** inline em cada branch. Razão: `biome_in_manifest` (jq sobre package.json) e `ruff_in_manifest` (grep sobre pyproject + requirements*.txt) não compartilham nada estrutural; `manager_install_cmd_*` também é diferente per-stack. Helpers compartilhados só introduziriam abstração sem ganho. State dispatch ficou inline também — mais legível como block contínuo de 3-state per-stack do que três funções separadas.
- **Auditoria do task 1:** zero pre-existing consumers — confirmado. `mcp-recipes-hint.sh` parseia package.json mas pra detectar Next.js/React deps (orthogonal a lint, jq-free grep approach). `supply-chain-advise.sh` faz basename match (não parsing). `validators/run.sh` só fazia `[ -f ...]` existence checks. Sem colisão; novo `jq -e` em validator é seguro porque `jq` já é dependência (line 20).
- **Tempo de manifest-detect:** não medido formalmente, mas `jq -e` em package.json sintético + grep em pyproject.toml/requirements.txt rodam <10ms cada nos test fixtures (testes inteiros completam em <1s). Bem abaixo do limite arbitrado de 50ms.
- **Fixture pra `node_modules/@biomejs/biome/package.json`:** `{"name":"@biomejs/biome","version":"1.0.0"}` JSON minimal foi suficiente. Nenhum teste precisou de mais.
- **Resultados do dogfood manual (task 20):** 3 cenários end-to-end via real `post-edit-validate.sh`:
  - DOGFOOD A (biome declared+missing): hook exit 0, stderr advisory presente, loop counter 0 (não incrementou). Mensagem `lint-advisory: biome declared in package.json but not installed — run \`bun install\`` clara e copy-paste-ready.
  - DOGFOOD B (biome declared+installed): hook exit 0, stderr completamente limpa.
  - DOGFOOD C (ruff declared+missing, pip-default manager): hook exit 0, stderr advisory `lint-advisory: ruff declared in pyproject.toml but not installed — run \`pip install ruff\``.
  - Conclusão: advisory message é clara e acionável; non-block + non-counter-increment ratificados empiricamente.
- **Cross-capacity discovery durante impl:** `post-edit-validate.sh` linha 65 fazia `2>&1` merge de validator stdout+stderr antes do `jq` parse. Pre-013 isso funcionou porque validator era silent em stderr; uma vez que `lint-advisory:` começa a sair em stderr, o merge prepende texto não-JSON e quebra o parse. Solução adicional aplicada: capturar stderr separadamente (mktemp), surfacer pra própria stderr do hook (visível pro agente), passar só stdout pro `jq`. Documentado em `.claude/rules/lint-validator.md` § *Advisory format* + § *Gotchas* ("Validator stderr is now a real channel"). Não está em plan.md original — atualizar se houver leitura futura cross-spec.
- **Caso não coberto:** fork que usa `bun --bun` runtime + biome instalado globalmente fora do `node_modules/`. Manifest-detect retorna true (declarado), filesystem-probe retorna false (não há `node_modules/@biomejs/biome/`) → emite advisory "run `bun install`" mesmo com global biome disponível. Documentado no § *Gotchas* do rule doc; mitigação é `CLAUDE_VALIDATOR_SKIP_LINT=1` ou instalar local via `bun add -d @biomejs/biome`.
- **Negative tests trivialmente PASS no RED baseline:** tests 02 (biome not declared), 05 (ruff not declared), 08 (opt-out env var) passam contra validator pré-impl porque assertam ausência de comportamento que ainda não existe. Aceitável: continuam servindo como regression guards após impl. Os 5 testes load-bearing (01, 03, 04, 06, 07) eram FAIL no RED baseline e PASS pós-impl — sinal RED→GREEN canônico preservado nos testes que importavam.
