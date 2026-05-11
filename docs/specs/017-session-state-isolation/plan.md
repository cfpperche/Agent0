# 017 — session-state-isolation — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Mudança em **três artefatos** (não dois, conforme descoberto na fase de auditoria):

1. **`session-start.sh`** e **`session-stop.sh`** passam a parsear `session_id` do payload JSON via stdin (`jq -r '.session_id'`), aplicam sanitização (regex `[a-zA-Z0-9_-]+`, fallback `"unknown"` se ausente/inválido), e operam contra `STATE_DIR/<session_id>/` em vez de `STATE_DIR/` raiz. Cada sessão escreve no seu próprio subdir; nenhuma sessão A pode mais resetar markers de uma sessão B.

2. **`probe.sh`** (runtime-introspect) lê `started-at` como sinal de "session boundary" pra detectar snapshots stale. Adapta-se pra **Option B aprovada**: em vez de ler `<.session-state>/started-at` na raiz, faz scan dos `<.session-state>/*/started-at` e usa o **maior mtime** como a fronteira. Sessão única: comportamento idêntico ao atual. Sessões paralelas: stale=true pode trigger mais cedo (falso positivo conservador, agente re-roda verifier, direção segura).

3. **`session-start.sh`** ganha cleanup time-based best-effort no fim — apaga subdirs com `started-at` mais antigo que 7 dias. Falha silenciosa nunca bloqueia o fluxo principal.

Disciplina TDD-first preservada: 7 testes RED cobrem os 7 cenários do spec escritos antes de qualquer alteração no código. Adicionalmente, dois testes existentes (`runtime-introspect/05-stale-flag.sh`, `mcp-recipes/05-co-exists-with-011.sh`) precisam de update na mesma diff porque hardcodam o path antigo nos fixtures — vão de "passa contra layout antigo" pra "passa contra layout novo".

Ordem do trabalho: 7 testes RED novos → atualizar 2 testes existentes pro layout novo → refator dos 2 hooks → refator do probe.sh → cleanup time-based → atualizar `.claude/rules/session-handoff.md` → dogfood pass (abrir duas Claude Code paralelas, verificar comportamento).

## Files to touch

**Create:**

- `.claude/tests/session-state-isolation/01-parallel-isolation.sh` — RED: simula sessão A já com `nagged` criado, sessão B dispara SessionStart, valida que `<.session-state>/A/nagged` continua intacto
- `.claude/tests/session-state-isolation/02-sessions-independent-blocks.sh` — RED: duas sessões A+B independentemente disparam Stop com uncommitted changes; cada uma bloqueia exatamente uma vez na própria lifecycle
- `.claude/tests/session-state-isolation/03-session-start-creates-subdir.sh` — RED: SessionStart cria `<session_id>/started-at`, remove `<session_id>/nagged` se existir, não toca em outros `<X>/` siblings
- `.claude/tests/session-state-isolation/04-stop-reads-from-subdir.sh` — RED: Stop hook usa apenas `<session_id>/` pros markers; ignora `<.session-state>/` raiz ou subdirs alheios
- `.claude/tests/session-state-isolation/05-missing-session-id-fallback.sh` — RED: payload sem `.session_id` → hook opera contra `<.session-state>/unknown/` sem crashar
- `.claude/tests/session-state-isolation/06-cleanup-old-subdirs.sh` — RED: cria 3 subdirs (2 com `started-at` > 7d, 1 recente); SessionStart limpa os 2 antigos e preserva o recente; falha de cleanup (ex: permissão) não bloqueia hook
- `.claude/tests/session-state-isolation/07-session-id-sanitization.sh` — RED: payloads com `session_id` contendo `../foo`, `foo/bar`, caracteres especiais → caem pro fallback `"unknown"`; sem path traversal
- `.claude/tests/session-state-isolation/run-all.sh` — runner shell que executa os 7 scripts e reporta pass/fail

**Modify:**

- `.claude/hooks/session-start.sh` — adicionar:
  - Parse `session_id` do stdin JSON via `jq -r '.session_id // empty'`
  - Função `sanitize_session_id()` que aplica regex `^[a-zA-Z0-9_-]+$` e retorna `"unknown"` se não matcher
  - Reescrever `STATE_DIR` pra `$PROJECT_DIR/.claude/.session-state/$SESSION_ID`
  - Seção de cleanup best-effort no fim: `find "$PROJECT_DIR/.claude/.session-state" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true`
- `.claude/hooks/session-stop.sh` — adicionar:
  - Mesmo parser/sanitizer (extrair pra função compartilhada via `source` de um helper, OR duplicar inline — decidir no momento da impl pelo tradeoff DRY vs. simplicity-of-vendoring)
  - Reescrever `STATE_DIR` pro path per-session_id
- `.claude/tools/probe.sh` — refatorar a stale detection (Option B aprovada):
  - Substituir `SESSION_MARK="$PROJECT_DIR/.claude/.session-state/started-at"` por scan dos subdirs
  - Loop cross-platform sobre `"$SESSION_DIR"/*/started-at` (glob), capturando max mtime via `date -u -r` ou `stat -c '%Y'` (já-presente fallback pattern)
  - Stale check usa o max-mtime como boundary; se nenhum subdir tem `started-at`, fallback: snapshot nunca-stale (preservar fail-open atual)
- `.claude/tests/runtime-introspect/05-stale-flag.sh` — fixture atualiza pra criar `<.session-state>/<some-id>/started-at` em vez da raiz; valida que probe.sh detecta staleness pelo novo layout
- `.claude/tests/mcp-recipes/05-co-exists-with-011.sh` — fixture mesma update
- `.claude/rules/session-handoff.md` — adicionar nota:
  - § State files — `<.session-state>/<session_id>/{started-at,nagged}` substitui o layout raiz
  - § Gotchas — sessões paralelas no mesmo projeto agora isoladas; auto-compact do Opus 1M context preserva session_id então nag-once-per-conversa real
  - Mencionar a integração cross-capacity com probe.sh (usa max-mtime de session-state subdirs)

**Delete:** nenhum. Arquivos legados em `.claude/.session-state/{started-at,nagged}` (schema pré-017) coexistem benignamente — não são lidos por hooks pós-017 nem pelo probe.sh pós-refator (o glob `*/started-at` casa apenas com paths em subdir), viram lixo e o cleanup time-based eventualmente remove (TTL 7d aplica à modificação do arquivo).

## Alternatives considered

### `transcript_path` em vez de `session_id` como discriminador

Rejected: `transcript_path` codifica session_id no próprio path (`~/.claude/projects/<project>/<session_id>.jsonl`), então é redundante e adiciona uma camada de indireção. `session_id` é mais direto, mais legível em debug, e a doc confirmou persistência através de /compact e /resume. `transcript_path` permanece como **fallback de emergência** se um dia descobrirmos que session_id quebra em algum cenário não documentado.

### PID como discriminador

Rejected: PID é estável dentro de uma sessão MAS não está documentado nos campos do SessionStart input schema. Adicionalmente, dois processos Claude Code distintos podem ter PIDs reciclados pelo sistema operacional ao longo de horas/dias — sem garantia de unicidade. session_id é UUID por design.

### Coordenar sessões via `flock` num marker compartilhado

Rejected: introduz block-wait entre sessões (uma esperando a outra liberar o lock pra escrever no marker) — pior UX, mais latência no SessionStart, e complexidade adicional. O problema é interferência, não coordenação; isolation resolve com menos código.

### Migrar markers legados automaticamente no primeiro SessionStart pós-017

Rejected: schema antigo (`<.session-state>/{started-at,nagged}` direto na raiz) coexiste sem conflito com o novo (`<.session-state>/<id>/{...}`). Hooks pós-017 ignoram a raiz e leem apenas do subdir. Cleanup time-based eventualmente remove os arquivos órfãos. Migração explícita = código extra pra zero benefício real; preservar simplicidade.

### Marker baseado em hash de `git status` (alternativa discutida turno anterior)

Rejected nesta spec: era proposta alternativa pra resolver o mesmo bug ("nag uma vez por estado-do-repo"). Per-`session_id` é solução mais simples, direta, e cobre os 3 cenários (parallel + auto-compact + resume) com mecanismo único. Hash-de-git é variant válido mas resolve outro problema (nag baseado em estado vs. ciclo) que pode virar spec separada se demanda real surgir.

## Risks and unknowns

- **Função compartilhada de parse/sanitize entre os dois hooks: extract ou duplicate?** Pequena (≤10 linhas), usada em 2 lugares. Vendoring duplicado é simples e remove dependência de source-time path. Extrair pra `.claude/hooks/lib/session-id.sh` adiciona um arquivo a mais e o overhead de `source`. Inclinação na impl: duplicar inline; refatorar pra helper se um terceiro consumer aparecer. Documentar na rule doc qualquer que seja a decisão pra coerência futura.
- **Test fixtures pra "duas sessões em paralelo"** (cenários 01 e 02). Estratégia: simular duas sessões executando os hooks com `session_id` diferentes em sequência (não verdadeiramente concorrente), validando que markers ficam isolados. Concorrência real (via background processes + sleep) é overkill — o ponto é verificar isolation, não race conditions.
- **Cleanup pode rodar com permissão restrita** (em fork que mounta `.claude/` read-only por algum motivo). Mitigação: `2>/dev/null || true` garante fail-open. Risco residual: subdirs órfãos acumulam silenciosamente. Aceitável; usuário pode diagnosticar via `ls -la .claude/.session-state/` se suspeitar.
- **`find ... -mtime +7` precisão.** `-mtime` em GNU find usa unit "24-hour periods" rounded down. Subdirs entre 6.5 e 7.5 dias podem ser ambíguos. Aceitável (cleanup é best-effort, não exato).
- **Backward compat de testes existentes em `.claude/tests/`.** Auditoria realizada — DOIS testes hardcodam o path antigo: `runtime-introspect/05-stale-flag.sh` e `mcp-recipes/05-co-exists-with-011.sh`. Ambos usam `started-at` como fixture pra testar comportamento de outra capacity (probe.sh staleness, mcp-recipes co-existence). Update inline na mesma diff (já refletido em "Files to touch").
- **Cross-capacity coupling: probe.sh depende de `started-at`.** Descoberta durante auditoria de impl. Resolvida via Option B — probe.sh passa a usar max-mtime entre subdirs em vez de path fixo. Implicação: o spec 017 não é "renomear arquivo", é "introduzir layout per-session_id pra dois consumers (hooks de session + probe de runtime-introspect)". Outros consumers do `.session-state/` no futuro precisarão seguir o mesmo padrão de scan.
- **Race entre SessionStart de duas sessões simultâneas.** `mkdir -p` é atomic, `touch` em paths distintos não conflita, `rm -f` em paths distintos não conflita. Não identifiquei race real. Se um dia aparecer, `flock` no subdir resolve.
- **Cenários não testados pela 017**: `claude --continue` (caso de uso comum) — produz `source=resume` no SessionStart? Pesquisa confirmou que `/resume` preserva session_id mas não testou `--continue` explicitamente. Tratar como mesmo path. Validar no dogfood final.

## Research / citations

- claude-code-guide agent research (esta sessão, 2026-05-11) — confirmação empírica via docs Claude Code de que `session_id` persiste em `/compact` (source muda, id idem), `/resume` (source muda, id idem), e gera novo em `source=startup` ou `/clear`. Citações:
  - https://code.claude.com/docs/en/hooks.md — SessionStart input schema, `source` values, payload field list
  - https://code.claude.com/docs/en/sessions.md — semântica de resume, file `~/.claude/projects/<project>/<session_id>.jsonl`
- `.claude/hooks/session-start.sh` (estado atual lido linhas 1-44 esta sessão) — base que está sendo refatorada
- `.claude/hooks/session-stop.sh` (estado atual lido linhas 1-42 esta sessão) — base que está sendo refatorada
- `.claude/rules/session-handoff.md` — documentação do contrato atual; será extendida pra refletir layout per-`session_id`
- `docs/specs/002-delegation/` — pattern de path per-id (`.claude/.delegation-state/agents/<agent_id>/`); spec 017 trazendo o mesmo shape pro session-state
- Esta conversa, turnos em que o usuário (a) identificou o duplo-block do Stop hook, (b) levantou a hipótese correta de sessões paralelas, (c) confirmou a investigação Q5 deve rodar antes do plan
