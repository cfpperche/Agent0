# 017 — session-state-isolation

_Created 2026-05-11._

**Status:** shipped

## Intent

O harness usa `.claude/.session-state/` como diretório global por-projeto pra dois markers (`started-at` e `nagged`) consumidos pelos hooks `session-start.sh` e `session-stop.sh`. O contrato implícito é "uma vez por sessão" — bloquear o Stop apenas na primeira vez que termina um turn com `SESSION.md` desatualizado, e silenciar dali pra frente. Esse contrato é **violado quando duas (ou mais) instâncias de Claude Code rodam em paralelo no mesmo projeto**: cada nova `SessionStart` (de qualquer sessão) faz `touch started-at` + `rm -f nagged`, apagando o marker da sessão concorrente sem ela saber. Resultado observado nesta sessão: dois Stop blocks em uma conversa só, o segundo causado por uma sessão paralela aberta no projeto que limpou o nag da sessão atual.

Spec 017 isola o estado por `session_id` — informação que ambos os hooks já recebem no payload JSON da Claude Code via stdin mas nunca usam. Cada sessão passa a ter seu próprio subdiretório `<.session-state>/<session_id>/{started-at,nagged}`, e SessionStart de uma sessão não interfere no marker da outra. Continua o piso de cross-session handoff sem o falso-bloqueio paralelo.

## Acceptance criteria

- [ ] **Scenario: Sessão A nag, Sessão B abre, Sessão A não é re-nagada**
  - **Given** Sessão A está rodando no projeto, já foi bloqueada uma vez pelo Stop hook e atualizou `SESSION.md`
  - **When** o usuário abre Sessão B em paralelo no mesmo projeto (qualquer trigger de SessionStart)
  - **Then** o marker da Sessão A em `<.session-state>/<session-id-A>/nagged` continua intacto; o próximo Stop hook da Sessão A sai silencioso (não bloqueia novamente)

- [ ] **Scenario: Sessões paralelas mantêm markers independentes**
  - **Given** duas sessões A e B rodando concorrentemente
  - **When** ambas terminam turns com `SESSION.md` desatualizado
  - **Then** cada uma bloqueia exatamente uma vez no seu próprio ciclo (Sessão A bloqueia uma vez, Sessão B bloqueia uma vez), e cada uma silencia depois da própria atualização de `SESSION.md`

- [ ] **Scenario: SessionStart cria subdir per-session_id**
  - **Given** uma sessão nova começando (qualquer source: startup / resume / clear / compact)
  - **When** o SessionStart hook dispara
  - **Then** o caminho `<.session-state>/<session_id>/started-at` é criado/atualizado; `<.session-state>/<session_id>/nagged` é removido se existia; nenhum outro `<session_id>/*` diretório é tocado

- [ ] **Scenario: Stop hook lê do subdir per-session_id**
  - **Given** uma sessão com state em `<.session-state>/<session_id>/`
  - **When** o Stop hook dispara
  - **Then** apenas os arquivos sob `<session_id>/` são lidos; markers de outras sessões são ignorados

- [ ] **Scenario: session_id ausente do payload → fallback determinístico**
  - **Given** um payload de hook recebido sem `session_id` (forma defeituosa ou variante futura de Claude Code)
  - **When** qualquer hook dispara
  - **Then** o hook usa fallback `"unknown"` (ou similar), opera contra `<.session-state>/unknown/` sem crashar; comportamento volta a ser o pré-017 (compartilhado entre sessões anônimas) mas não falha aberto

- [ ] **Scenario: Cleanup de subdirs antigos não bloqueia hook**
  - **Given** múltiplas sessões antigas deixaram `<.session-state>/<session_id_X>/` órfãos
  - **When** SessionStart dispara
  - **Then** subdirs com `started-at` mais velho que N dias (proposto: 7) são removidos de forma best-effort; falha no cleanup nunca bloqueia o hook principal

- [ ] `.claude/.session-state/` continua gitignored (já é); nenhum subdir ou conteúdo entra no repo
- [ ] CLAUDE.md § Session handoff (se existir) ou `.claude/rules/session-handoff.md` atualizado com nota sobre isolation per-session_id
- [ ] Tests RED criados antes da implementação seguindo o pattern dos specs anteriores (6+ cenários)
- [ ] Migração: arquivos legados diretamente em `.claude/.session-state/started-at` (schema pré-017) não causam crash em hooks pós-017; podem ser limpos pelo cleanup de SessionStart

## Non-goals

- **Coordenação entre sessões paralelas.** Sessões A e B continuam independentes; spec 017 não tenta sincronizar "fork B deve esperar fork A terminar" nem nada do tipo. Cada uma é responsável pelo próprio `SESSION.md`.
- **Detecção de sessões zumbis.** Se uma sessão crashar sem limpar seu subdir, fica órfão até o cleanup time-based pegá-lo. Não há heartbeat / liveness check.
- **Migração automática de state antigo.** O schema pré-017 (`<.session-state>/started-at`) e o pós-017 (`<.session-state>/<id>/started-at`) coexistem por design — arquivos antigos viram lixo e o cleanup time-based eventualmente remove. Sem migração explícita, sem dual-read.
- **Refatorar outros markers globais.** `.claude/.delegation-state/agents/` é per-`agent_id` já (delegation já fez isso direito) — não está no escopo desta spec. Se algum outro marker global existir no harness, vira spec separada.
- **Renomear ou re-estruturar `.session-state/`** além da nova layer de subdiretórios. Path raiz continua igual.

## Open questions

_Q1-Q4 resolvidas 2026-05-11 — usuário ratificou as 4 propostas as-is. Q5 resolvida via pesquisa em docs Claude Code._

- [x] **Q1 — Fallback quando `session_id` ausente.** **Resolved: `"unknown"` hardcoded.** Determinístico, sem dependência de PID/clock, recupera comportamento pré-017 pra sessões sem id no payload sem introduzir complexidade.
- [x] **Q2 — TTL do cleanup time-based.** **Resolved: 7 dias.** Sessões longas podem durar dias; 1 dia é agressivo demais. Subdirs vazios são baratos (~8KB cada).
- [x] **Q3 — Onde colocar cleanup.** **Resolved: inline no `session-start.sh`, best-effort.** Falha de cleanup nunca bloqueia o hook principal. Sem hook separado, sem cron — simplicidade > pureza.
- [x] **Q4 — Sanitização do `session_id` como path.** **Resolved: regex `[a-zA-Z0-9_-]+` only; resto cai pro fallback `"unknown"`.** Defesa contra `../` injection ou caracteres especiais em payload defeituoso/malicioso.
- [x] **Q5 — `session_id` persiste em /compact e /resume?** **Resolved: SIM, persiste em ambos.** Pesquisa em docs Claude Code confirmou:
  - `/compact` mantém o mesmo `session_id`, muda apenas `source` pra `"compact"` no payload do SessionStart hook
  - `/resume` mantém o mesmo `session_id`, lê do mesmo `~/.claude/projects/<project>/<session-id>.jsonl`
  - Novo `session_id` apenas em `source=startup` (nova conversa) e `/clear` (nova lifecycle)
  - `transcript_path` também persiste em /compact como backup viável (codifica o session_id no path)
  - **Implicação**: fix per-`session_id` resolve auto-compact naturalmente — mesma sessão = mesmo subdir = nag-once-per-conversa-real
  - **Fontes**: https://code.claude.com/docs/en/hooks.md (SessionStart input schema), https://code.claude.com/docs/en/sessions.md (resume + /clear semantics)

## Context / references

- `.claude/hooks/session-start.sh` (estado atual lido nesta sessão)
- `.claude/hooks/session-stop.sh` (estado atual lido nesta sessão)
- `.claude/rules/session-handoff.md` — descreve o contrato "block once per session" que está sendo violado em paralelo
- `docs/specs/002-delegation/` — pattern de marker per-`agent_id` (`.claude/.delegation-state/agents/<agent_id>/`); essa spec é o protótipo do shape per-id que 017 traz pro session-state
- Esta conversa, turno em que o usuário identificou que dois Stop blocks haviam disparado e levantou a hipótese de sessão paralela — diagnóstico inicial e confirmação pelos timestamps de `started-at` / `nagged` em `.claude/.session-state/`
- Claude Code docs sobre payload JSON dos hooks (verificar shape de `session_id` antes do plan — particularmente: persistência através de /compact e /resume)
