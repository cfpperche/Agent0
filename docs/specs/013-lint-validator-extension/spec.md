# 013 — lint-validator-extension

_Created 2026-05-11._

**Status:** shipped

## Intent

O validator de Agent0 (`.claude/validators/run.sh`) hoje cobre execução — testes + typecheck por stack — mas não cobre lint/style. Sub-agents podem deixar passar unused vars, imports sujos, complexidade explosiva, naming inconsistente em JS/TS e Python sem que o post-edit hook bloqueie, porque `bun test && bun tsc --noEmit` (ou equivalente Python) não vê nada disso. Spec 013 estende o validator pra rodar o linter idiomático de cada stack quando **o manifesto de dependências declara o linter** — sinal nativo do ecossistema, mais forte que inferência por config file presente.

Operação em 3 estados: (a) **declared + installed** → roda linter, falha bloqueia o post-edit loop como tsc/clippy já fazem; (b) **declared + not installed** → advisory acionável em stderr com o comando idiomático pro manager detectado (ex: `lint-advisory: biome declared in package.json but not installed — run \`bun install\``), NÃO bloqueia, NÃO incrementa loop-budget; (c) **not declared** → skip silencioso, fork não sinalizou intenção. Mantém o piso domain-agnostic (Agent0 não prescreve regras nem nomeia o linter — descobre via manifesto) e stack-aware (não roda onde não cabe).

Escopo v1: **single-stack** apenas — espelha o stack-detect monolítico do validator atual (primeiro `if/elif` match vence). Multi-stack monorepo é prerequisite via spec 015 (monorepo-stack-detect); 013 herda automaticamente quando 015 land. Sem duplicação de responsabilidade.

## Acceptance criteria

- [ ] **Scenario: Biome roda quando JS/TS detectado E declarado no manifesto E instalado**
  - **Given** um projeto onde o validator já detecta `bun` / `pnpm` / `npm` AND `package.json` contém `@biomejs/biome` em `devDependencies` ou `dependencies` AND `node_modules/@biomejs/biome/package.json` existe
  - **When** o post-edit validator dispara após edit de sub-agent
  - **Then** o pipeline composto inclui `<runner> biome check` (`bunx` / `pnpm exec` / `npx` conforme manager detectado) e o resultado contribui pro campo `ok` do JSON

- [ ] **Scenario: Skip silencioso quando manifesto JS/TS NÃO declara biome**
  - **Given** projeto JS/TS sem `@biomejs/biome` em qualquer seção do `package.json`
  - **When** validator dispara
  - **Then** nenhuma invocação de biome é tentada; JSON de saída idêntico ao pré-013; nenhum stderr emitido

- [ ] **Scenario: Advisory forte quando JS/TS declara biome mas não instalou**
  - **Given** projeto JS/TS + `package.json` declara `@biomejs/biome` em devDeps + `node_modules/@biomejs/biome/` NÃO existe
  - **When** validator dispara
  - **Then** stderr inclui `lint-advisory: biome declared in package.json but not installed — run \`<install-cmd>\`` onde `<install-cmd>` é específico do manager (`bun install` / `pnpm install` / `npm install`); validator NÃO falha (ok=true preservado se test+tsc passam); nenhum incremento ao loop-budget de delegation

- [ ] **Scenario: Ruff roda quando Python detectado E declarado E instalado**
  - **Given** projeto Python AND `ruff` declarado em `pyproject.toml` ou `requirements*.txt` AND `<py_prefix> -m ruff --version` retorna exit 0
  - **When** validator dispara
  - **Then** `<py_prefix> -m ruff check .` é executado e contribui pro `ok`

- [ ] **Scenario: Skip silencioso quando manifesto Python NÃO declara ruff**
  - **Given** projeto Python sem `ruff` em pyproject.toml/requirements
  - **When** validator dispara
  - **Then** nenhuma invocação de ruff; JSON de saída idêntico ao pré-013

- [ ] **Scenario: Advisory forte quando Python declara ruff mas não instalou**
  - **Given** projeto Python + manifesto declara ruff + binário ausente (`-m ruff --version` retorna 127 ou error)
  - **When** validator dispara
  - **Then** stderr inclui `lint-advisory: ruff declared but not installed — run \`<install-cmd>\`` (uv: `uv sync`; poetry: `poetry install`; pdm: `pdm install`; pip: `pip install ruff`); validator NÃO falha
  - **Note (amendment 2026-05-12, dogfood F1):** sob `py_prefix = "uv run python"`, o probe `uv run python -m ruff --version` triggers uv's auto-resolve a partir do manifesto antes de invocar python, instalando ruff transparentemente. Resultado: em projetos uv-managed sob uso default de `uv run`, a precondição "binário ausente" deixa de ser alcançável imediatamente após declarar ruff no manifesto — state-b colapsa em state-a dentro de um único `uv run`. Cenário permanece válido (e empiricamente verificado) em poetry, pdm, pip-only flows, e CI sem uv no PATH. Comportamento sob uv considerado *desejável* pra ergonomia de adoção (declarar = instalar = rodar em uma operação); a verificabilidade do advisory neste caso é o trade-off.

- [ ] **Scenario: Falha do linter (quando roda) bloqueia sub-agent**
  - **Given** qualquer stack onde linter está rodando (estado a) AND um edit de sub-agent introduz erro de lint
  - **When** post-edit validator dispara
  - **Then** `ok=false`, exit não-zero, stderr tail carrega output do linter, hook retorna exit 2; loop budget de delegation se aplica normalmente (igual tsc/clippy/test failure)

- [ ] **Scenario: Env var opt-out desliga lint sem mexer no resto**
  - **Given** `CLAUDE_VALIDATOR_SKIP_LINT=1` no ambiente
  - **When** validator dispara
  - **Then** etapa de lint é pulada independentemente de manifesto/instalação; test + typecheck continuam normalmente; nenhum advisory emitido

- [ ] `.claude/validators/run.sh` continua emitindo JSON válido conforme contrato spec-002 (`ok`, `command`, `exit`, `duration_ms`, `stdout`, `stderr`) + extensão `warnings` opcional do spec-005
- [ ] Campo `command` reflete o pipeline composto quando linter roda (ex: `bun test && bun tsc --noEmit && bunx biome check`); reflete o pipeline base quando não roda
- [ ] Nenhum config de linter (`biome.json`, `ruff.toml`, etc.) é commitado ao Agent0 base — forks ownham a configuração e seus manifestos
- [ ] Single-stack v1 — primeiro `if/elif` do validator vence; manifestos não detectados pela branch escolhida são ignorados; documentado como non-goal explícito a ser fechado por spec 015
- [ ] Tests RED criados antes da implementação (8+ cenários cobertos seguindo TDD pattern dos specs anteriores)

## Non-goals

- **Prescrever rule sets.** Agent0 ship zero config de linter; forks decidem.
- **ESLint na v1.** Biome é a escolha pra JS/TS (single binary, formatter+linter unified). ESLint vira follow-up se um fork pedir.
- **Multi-stack monorepo lint detection.** Stack-detect single-stack hoje é limitação do validator inteiro, NÃO de 013. Spec 015 (monorepo-stack-detect) é prerequisite pra resolver isso pra todo o validator (tests + typecheck + lint). 013 herda multi-stack automaticamente após 015 land. Não duplicar a lógica de walk em 013.
- **Arch-lint / boundaries** (`dependency-cruiser`, etc.) — pressupõem modelo de camadas que viola domain-agnostic. Spec separada de "recipes" se demandado.
- **Auto-format on edit.** Lint check OK; auto-rewrite do arquivo do sub-agent fere o contrato post-edit.
- **Extensão pra Go/Rust.** `go vet` e `cargo clippy -D warnings` já cobrem no piso atual.
- **Auto-install do linter quando declarado mas ausente.** Agent0 nunca muta o host env silenciosamente — viola supply-chain (spec 009). Advisory acionável é o caminho.
- **Granularidade fina de opt-out** (per-tool env vars). Single `CLAUDE_VALIDATOR_SKIP_LINT=1` é suficiente.
- **`peerDependencies` em package.json.** Linters em peerDeps é raríssimo e idiomaticamente errado. Não escaneamos essa seção.
- **State-b advisory observability em projetos uv-managed sob default `uv run`.** Amendment 2026-05-12. `uv run` faz auto-sync do manifesto antes de invocar o subcomando, então o probe `uv run python -m ruff --version` faz uv instalar ruff antes do probe completar — state-b colapsa em state-a transparentemente. Não é um bug da impl: é uma propriedade de uv's auto-resolve semantics interagindo com a probe shape escolhida (runtime check via `<py_prefix> -m ruff --version`). Alternativa filesystem-only (`[ -f .venv/lib/python*/site-packages/ruff/__init__.py ]`) foi rejeitada no design pivot pra evitar config-file noise. Advisory continua observable em poetry/pdm/pip-only/PATH-isolated-CI flows. Documentado em `.claude/rules/lint-validator.md` § Gotchas + `dogfood-findings.md` F1.
- **Promover TDD/SDD de cultural pra blocking.** Fora do escopo.

## Open questions

_Todas resolvidas 2026-05-11 — usuário ratificou via dois turnos de iteração (5 originais + 4 surgidas após pivot manifest-as-intent). Plan.md pode prosseguir._

- [x] **Q1 (antiga: filesystem probe single OR dual)** — **substituída** pela abordagem manifest-as-intent. Filesystem probe vira sinal complementar ("instalado?") usado apenas após confirmação de declaração no manifesto.
- [x] **Q2 (antiga: Python `-m ruff --version` capturando exit)** — **mantida em essência**: check de binário continua sendo o sinal #3 da árvore de estados; só importa se passou do sinal #1 (declarado no manifesto). Probe = `<py_prefix> -m ruff --version` capturando exit 127.
- [x] **Q3 (antiga: grep `^\[tool\.ruff`)** — **encerrada**. Detect de config-file não é necessário pra inferir intent. Manifest-declaration é o sinal correto.
- [x] **Q4 (sem audit log próprio)** — **mantida**. Coerente com spec 011 ("snapshot é a verdade, sem audit per-call"). Stderr advisory já é suficiente como signal acionável; volume de Bash audit log do supply-chain (spec 009) é cautionary tale.
- [x] **Q5 — Parse de `package.json`**. **Resolved**: `jq -e '.devDependencies["@biomejs/biome"] // .dependencies["@biomejs/biome"] // empty' package.json` — olha devDeps + deps; `peerDependencies` ignorado (linter em peerDeps é antipattern). `-e` define exit code 0 se achou.
- [x] **Q6 — Parse de manifestos Python**. **Resolved**: grep pragmático ancorado: `grep -qE '(^\s*ruff\s*[=>]|"ruff"|"ruff[<>=~]|''ruff)' pyproject.toml requirements*.txt 2>/dev/null`. Cobre poetry (`ruff = "x"`), PEP 621 array (`"ruff>=x"`), requirements.txt (`ruff>=x`). False positive em comentário TOML aceitável — só vai dar advisory se o usuário declarou de verdade.
- [x] **Q7 — Declared+missing: advisory ou block?** **Resolved: advisory-only, não block, não incrementa loop-budget.** Ambiente quebrado não é responsabilidade do agente fixar via post-edit loop; instalar dep é supply-chain action separada (spec 009). Stderr line acionável pelo operador. Mesmo pattern de tdd-advisory / secrets-advisory.
- [x] **Q8 — Stderr message contém comando exato.** **Resolved: sim, manager-specific**: `bun install` / `pnpm install` / `npm install` / `uv sync` / `poetry install` / `pdm install` / `pip install ruff`. Pattern coerente com supply-chain (corrected-form verbatim).

## Context / references

- `.claude/validators/run.sh` — o arquivo a estender (cobre 6 stacks com test + type/vet/clippy)
- `docs/specs/002-delegation/` — contrato JSON do validator
- `docs/specs/005-tdd/` — extensão `warnings` aditiva (pattern pra `lint-advisory:` em stderr)
- `docs/specs/009-supply-chain-block/` — pattern de stderr template com corrected-form pro agente copia-pasta
- `docs/specs/011-runtime-introspect/` — pattern de stack-detect (mas note: 013 NÃO duplica config-detect, usa manifest-as-intent)
- `docs/specs/015-monorepo-stack-detect/` — **dependência soft**: quando 015 land, 013 herda multi-stack automaticamente
- Conversa desta sessão (turnos do design pivot): single-signal manifest-as-intent + single-stack v1 ratificados via Opção A
- Biome docs (biomejs.dev) — convenções de CLI (`biome check`)
- Ruff docs (docs.astral.sh/ruff) — convenções de CLI (`ruff check .`)
