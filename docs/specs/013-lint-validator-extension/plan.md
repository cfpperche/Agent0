# 013 — lint-validator-extension — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Estender `.claude/validators/run.sh` (**arquivo único**) com lógica de 3 estados em duas branches: JS e Python. Lógica única em cada stack:

1. **Manifest-detect** — passa do estado "not declared" pra "declared" se o linter aparece no manifesto. JS: `jq -e` em `package.json` (devDeps + deps). Python: grep ancorado em `pyproject.toml` + `requirements*.txt`.
2. **Binary-probe** — passa de "declared" pra "declared + installed" se o binário responde. JS: `[ -f node_modules/@biomejs/biome/package.json ]`. Python: `<py_prefix> -m ruff --version` capturando exit 127.
3. **State dispatch** — compõe pipeline:
   - **state a (declared + installed)** → append `&& <runner> biome check` (ou ruff check) ao `command_str` existente
   - **state b (declared + missing)** → emit `lint-advisory:` em stderr **antes** de rodar o `command_str` (não bloqueia, não incrementa loop-budget, validator continua rodando test+typecheck normalmente)
   - **state c (not declared)** → noop; pipeline base inalterado

Opt-out global via `CLAUDE_VALIDATOR_SKIP_LINT=1` curtocircuita TUDO antes de qualquer manifest-detect — pula direto pro pipeline base.

Disciplina TDD-first preservada: 8 testes RED cobrem os 8 cenários do spec (4 estado-a felizes + 2 estado-b advisories + 1 estado-c skip + 1 opt-out) escritos ANTES de tocar `run.sh`. Cada teste fixture-isolado com `mktemp` dir + `package.json` (ou `pyproject.toml`) sintético + opcional `node_modules/@biomejs/biome/` fake.

Ordem do trabalho: 8 testes RED → manifest-detect helpers (`biome_in_manifest` / `ruff_in_manifest`) → binary-probe helpers (`biome_installed` / `ruff_installed`) → state dispatcher inline nas branches JS+Python → opt-out env curto-circuito → stderr advisory templates → atualizar `.claude/rules/lint-validator.md` (novo arquivo) + § em CLAUDE.md → dogfood em projeto JS+Python com biome+ruff configurados.

## Files to touch

**Create:**

- `.claude/tests/lint-validator/01-biome-declared-installed-runs.sh` — RED: fixture com package.json declarando biome + node_modules/@biomejs/biome/package.json presente; valida `command_str` contém `biome check` + `ok=true` se biome roda clean
- `.claude/tests/lint-validator/02-biome-not-declared-skips.sh` — RED: package.json sem biome; valida `command_str` SEM biome + zero advisories em stderr
- `.claude/tests/lint-validator/03-biome-declared-missing-advisory.sh` — RED: declarado em devDeps mas node_modules ausente; valida stderr contém `lint-advisory: biome declared in package.json but not installed — run \`bun install\`` + `ok=true` (porque test+tsc passam) + `command_str` SEM biome
- `.claude/tests/lint-validator/04-ruff-declared-installed-runs.sh` — RED: pyproject.toml com `ruff` em deps + binary disponível (mock via PATH ou env shim); valida `command_str` contém `ruff check .`
- `.claude/tests/lint-validator/05-ruff-not-declared-skips.sh` — RED: pyproject.toml sem ruff; valida ausência de ruff no pipeline
- `.claude/tests/lint-validator/06-ruff-declared-missing-advisory.sh` — RED: declarado em pyproject mas binary 127; valida stderr advisory + comando install manager-specific (uv/poetry/pdm/pip)
- `.claude/tests/lint-validator/07-lint-failure-blocks.sh` — RED: declared+installed + arquivo com erro de lint; valida `ok=false`, exit não-zero, stderr carrega output do linter
- `.claude/tests/lint-validator/08-opt-out-env-var.sh` — RED: `CLAUDE_VALIDATOR_SKIP_LINT=1`; valida lint pulado independente de declaração; test+tsc continuam rodando
- `.claude/tests/lint-validator/run-all.sh` — runner
- `.claude/rules/lint-validator.md` — rule doc cobrindo: 3 estados, sinais (manifesto vs install), formato da advisory, opt-out, gotchas (multi-dialect Python, peerDeps ignored, manager-specific advisory cmd)

**Modify:**

- `.claude/validators/run.sh` — adicionar nas branches JS e Python:
  - **JS branch** (após bun/pnpm/npm detect):
    - Função `biome_in_manifest()`: `jq -e '.devDependencies["@biomejs/biome"] // .dependencies["@biomejs/biome"] // empty' package.json` → exit 0 se declarado
    - Função `biome_installed()`: `[ -f node_modules/@biomejs/biome/package.json ]`
    - Função `manager_install_cmd()`: retorna `bun install` / `pnpm install` / `npm install` conforme stack-detect já feito
    - Lógica 3-state: se opt-out, skip. Senão se declared+installed, append `&& <runner> biome check`. Senão se declared+missing, emit advisory pre-pipeline. Senão noop.
  - **Python branch** (após py_prefix detect):
    - Função `ruff_in_manifest()`: grep pragmático ancorado em `pyproject.toml` + `requirements*.txt`
    - Função `ruff_installed()`: `$py_prefix -m ruff --version >/dev/null 2>&1`
    - Função `python_manager_install_cmd()`: retorna `uv sync` / `poetry install` / `pdm install` / `pip install ruff` baseado em qual lockfile foi detectado
    - Lógica 3-state análoga
  - Helpers compartilhados (se ambos branches usam) no topo do arquivo OU duplicados inline (decidir na impl)
- `CLAUDE.md` — adicionar § Lint validator (~150 palavras), explicando: 3 estados, sinais, advisory format, opt-out, link pro rule doc

**Delete:** nenhum.

## Alternatives considered

### Manter "config + manifest" como gate duplo (proposta original)

Rejected na iteração de design (turno user 2026-05-11): biome.json / ruff.toml não são necessários pra rodar o linter (ambos têm defaults razoáveis). Config file representa customização, não intent. Manifest-declaration é o sinal canônico de "este fork quer este linter". Gate duplo era over-engineering — adiciona estado sem ganhar precisão.

### Walk multi-stack (parsear todos manifestos do repo)

Rejected (Opção A ratificada): viola separação de responsabilidades com spec 015 (monorepo-stack-detect). 013 fica single-stack v1; 015 entrega multi-stack pra todo o validator (test + typecheck + lint compostos). 013 herda automaticamente. Inconsistência alternativa (test single-stack + lint multi-stack) seria confusa pra fork.

### `ESLint` em vez de Biome em JS/TS

Rejected: ESLint tem 4+ shapes de config (`.eslintrc.js/.json/.yaml`, `eslint.config.js` flat, variantes `.cjs/.mjs`). Detect robusto = 6+ predicados. Biome usa nome único (`@biomejs/biome` em deps), single binary, formatter+linter unified. Trade-off: forks ESLint têm atrito (não detectado) — aceitar como follow-up se demanda real surgir.

### Auto-install do linter quando declared+missing

Rejected: Agent0 nunca muta o host env silenciosamente. Viola supply-chain (spec 009) — instala dep sem passar pelo gate. Advisory acionável é o caminho correto: operador roda `bun install` conscientemente.

### Advisory ESCALAR pra block após N edits em sequência

Rejected: aumenta complexidade pra ganho marginal. Operador que ignora 5 advisories consecutivas vai ignorar a 6ª também. Mesma filosofia do tdd-advisory.

### Subprocess `pip show ruff` em vez de grep no manifesto

Rejected (Q6 ratificada): grep pragmático é ~10x mais rápido (sem subprocess spawn). False positive em comentário TOML é aceitável pra um sinal que só dispara advisory acionável (não block). Custo do FP é uma linha de stderr; benefício do grep é latência baixa em cada post-edit.

## Risks and unknowns

- **Helpers compartilhados entre branches JS+Python**: `manager_install_cmd` é diferente pra cada (deps vs requirements parsing), `biome_in_manifest` vs `ruff_in_manifest` são totalmente distintos. Provável conclusão: inline em cada branch, sem helpers compartilhados; decidir no momento da impl pelo tradeoff legibilidade vs DRY.
- **Python multi-dialeto** (poetry/PEP 621/pdm/uv/hatch): grep pragmático cobre os 3-4 shapes comuns. Edge case: `hatch` usa `[tool.hatch.envs.<name>.dependencies]` que pode escapar do regex. Se isso aparecer em uso real, ampliar o regex; v1 aceita o gap.
- **`requirements.txt` shapes** (`ruff`, `ruff==0.1`, `ruff>=0.1`, `Ruff` case, `-e ./local-ruff`): regex precisa tolerar versão specs comuns + case-insensitive match. Inclinação: `grep -qiE '^\s*ruff(\s|$|[=<>~!])'` em requirements*.txt.
- **`uv tool install ruff` (ferramenta global)**: ruff instalado globalmente via uv mas não em deps do projeto → manifest-detect retorna false → skip + zero advisory. Aceitável; alternativa seria detectar global install, mas isso vira filesystem probe que evitamos por design.
- **Detect de manager-install-cmd em Python**: precisa observar qual lockfile foi encontrado pelo validator (já tem essa info via `py_prefix`). Mapping: `uv.lock` → `uv sync`; `poetry.lock` → `poetry install`; `pdm.lock` → `pdm install`; sem lock → `pip install ruff`. Estende o switch já existente.
- **Auditoria de testes existentes** afetados: zero esperado (spec é nova, não há código pre-existente lendo manifestos pra fins de lint). Confirmar antes de impl, mas previsão é "nenhum afetado" diferente de spec 017 (que descobriu probe.sh cross-capacity).
- **Custo de iteração**: biome sub-segundo; ruff sub-segundo. Manifest-detect adiciona ~5-20ms (uma `jq` ou grep call). Aceitável.
- **Migração de forks**: forks que já têm biome/ruff configurados via biome.json/ruff.toml MAS não declararam em deps → não vão acionar lint até declararem. Pode causar surpresa ("achei que tinha lint"). Mitigação: rule doc explícita + § no CLAUDE.md menciona o requisito manifesto-declaration.

## Research / citations

- Conversa desta sessão (turnos do design pivot — single-signal manifest-as-intent vs dual config+manifest; Opção A single-stack v1)
- `.claude/validators/run.sh` (estado pós-017, lido nesta sessão) — base a estender
- `docs/specs/002-delegation/plan.md` § "Validator JSON contract" — contrato preservado
- `docs/specs/005-tdd/plan.md` § "Validator JSON contract — additive change" — pattern de stderr advisory aditivo
- `docs/specs/009-supply-chain-block/` — pattern de stderr template com corrected-form pro agente copia-pasta (mesma forma da `lint-advisory:` com `run \`bun install\``)
- `docs/specs/015-monorepo-stack-detect/` — dependência soft; SESSION.md atual marca como carryover; 013 herda multi-stack quando 015 land
- Biome docs (biomejs.dev) — `biome check` CLI, nome canônico `@biomejs/biome`
- Ruff docs (docs.astral.sh/ruff) — `ruff check .` CLI, nome canônico `ruff` em deps
