# 017 — session-state-isolation — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Pre-impl audit

- [x] 1. Auditar `.claude/tests/` por testes existentes que hardcodam `.claude/.session-state/started-at` ou `.claude/.session-state/nagged` na raiz. **Resultado:** 2 testes afetados — `runtime-introspect/05-stale-flag.sh` (linha 22) e `mcp-recipes/05-co-exists-with-011.sh` (linha 30). Adicional: **`.claude/tools/probe.sh:43` é outro consumer** de `started-at` (cross-capacity dependency) — usuário aprovou Option B (max-mtime entre subdirs). Plan.md + Files to touch atualizados pra refletir.

### RED tests (TDD discipline — escrever todos ANTES de tocar nos hooks)

- [x] 2. Criar `.claude/tests/session-state-isolation/01-parallel-isolation.sh` — sessão A com `<id-A>/nagged` criado, SessionStart pra `id-B` → `<id-A>/nagged` intacto + `<id-B>/started-at` criado
- [x] 3. Criar `.claude/tests/session-state-isolation/02-sessions-independent-blocks.sh` — cada sessão bloqueia 1x na própria lifecycle; detecta block via stdout JSON pattern
- [x] 4. Criar `.claude/tests/session-state-isolation/03-session-start-creates-subdir.sh` — SessionStart de `foo` toca `foo/started-at`, remove `foo/nagged`, deixa `bar/` intacto
- [x] 5. Criar `.claude/tests/session-state-isolation/04-stop-reads-from-subdir.sh` — Stop de `foo` silencia (foo/nagged newer); Stop de `baz` bloqueia independentemente
- [x] 6. Criar `.claude/tests/session-state-isolation/05-missing-session-id-fallback.sh` — 4 variants (no-field, null, empty-string, empty-stdin) caem todas pra `unknown/started-at`
- [x] 7. Criar `.claude/tests/session-state-isolation/06-cleanup-old-subdirs.sh` — 2 ancient + 1 recent fixture; SessionStart limpa os 2 antigos; valida fail-open com `chmod 000`
- [x] 8. Criar `.claude/tests/session-state-isolation/07-session-id-sanitization.sh` — 5 variants (path-traversal, embedded-slash, shell-meta, spaces, legitimate-uuid); todos malformed caem pra `unknown`, uuid válido passa
- [x] 9. Criar `.claude/tests/session-state-isolation/run-all.sh` — orchestrator mirror do pattern de runtime-introspect
- [x] 10. RED baseline: 7/7 FAIL contra código atual (confirmado antes da impl)

### Impl

- [x] 11. Refatorar `.claude/hooks/session-start.sh`: parse session_id do stdin via jq, sanitize com `^[a-zA-Z0-9_-]+$`, fallback `unknown`. STATE_DIR per-session_id. Restante intacto.
- [x] 12. Refatorar `.claude/hooks/session-stop.sh`: mesmo parse/sanitize (inline-duplicado, decisão registrada em Notes). STATE_DIR per-session_id. Restante intacto.
- [x] 13. Cleanup time-based no fim de session-start.sh: `find ... -mtime +7 -exec rm -rf {} + 2>/dev/null || true`. Fail-open garantido.
- [x] 13a. Refatorar `.claude/tools/probe.sh` (Option B): loop cross-platform `"$SESSION_STATE_DIR"/*/started-at` capturando max mtime. Fallback: sem subdirs → sem stale check.
- [x] 13b. Atualizar fixtures de `runtime-introspect/05-stale-flag.sh` e `mcp-recipes/05-co-exists-with-011.sh` pro layout novo (`<.session-state>/V5-test-session/started-at`).

### Validation

- [x] 14. spec 017 suite: **7/7 GREEN**.
- [x] 15. Re-rodar suites completas das capacities afetadas — **zero regressão**:
  - runtime-introspect: 10/10 PASS (incluindo 05-stale-flag.sh atualizado)
  - mcp-recipes: 6/6 PASS (incluindo 05-co-exists-with-011.sh atualizado)
  - secrets-scan: 7/7 PASS
  - supply-chain: 12/12 PASS
  - harness-sync: 12/12 PASS
- [x] 16. `.claude/rules/session-handoff.md` atualizado com (a) § State files re-escrito pro layout per-session_id, (b) novo § Parallel sessions and other start triggers cobrindo /compact, /resume, /clear, (c) § Cross-capacity dependency documentando probe.sh integração.
- [x] 17. **Dogfood manual — VALIDADO 2026-05-11** pela sessão B em paralelo. Relatório:
  - Sessão A (pré-017, hooks atualizados mid-session) tinha markers legacy na raiz: `started-at` (16:04) + `nagged` (16:08). Sessão B abriu às 17:11.
  - B's SessionStart criou `<e7cc7da9-...>/started-at` (subdir próprio); **NÃO** tocou nos markers legacy de A na raiz (mtimes preservados intactos).
  - Isolation property confirmada empiricamente — pré-017 o SessionStart de B teria limpado o nagged compartilhado.
  - Caveat: teste do lado de A (re-block esperado-NÃO-ocorrer) pulado conscientemente — A está em estado misto (hooks novos + markers legacy na raiz), Stop fala-bail-out no `[[ -f "$STARTED_AT" ]] || exit 0` por ausência de `<A-id>/started-at`. Evidência muda. Validação real cumprida pelo lado de B.
  - Markers legacy ficam na raiz como lixo benigno (cleanup `-type d` não pega arquivos); removidos no próximo SessionStart fresco de A (compact/clear/restart) ou pelo sweep de 7d.

## Verification

_Cada item mapeia 1:1 a um critério de `spec.md` § Acceptance criteria._

- [x] **Spec scenario 1** — `01-parallel-isolation.sh` GREEN. Dogfood manual pendente (task 17).
- [x] **Spec scenario 2** — `02-sessions-independent-blocks.sh` GREEN. Dogfood manual pendente (task 17).
- [x] **Spec scenario 3** — `03-session-start-creates-subdir.sh` GREEN.
- [x] **Spec scenario 4** — `04-stop-reads-from-subdir.sh` GREEN.
- [x] **Spec scenario 5** — `05-missing-session-id-fallback.sh` GREEN (4 variants: no-field, null, empty-string, empty-stdin).
- [x] **Spec scenario 6** — `06-cleanup-old-subdirs.sh` GREEN (incluindo fail-open com chmod 000).
- [x] **Spec static — `.claude/.session-state/` continua gitignored** — confirmado: `.gitignore` cobre o prefix; nenhum subdir é tracked.
- [x] **Spec static — `.claude/rules/session-handoff.md` atualizada** — § State files reescrito + novos §s "Parallel sessions" e "Cross-capacity dependency".
- [x] **Spec static — 6+ RED tests escritos antes da impl** — task 10 confirmou 7/7 RED contra código pre-refator.
- [x] **Spec static — schema legado coexiste sem crash** — arquivos diretos na raiz (`<.session-state>/started-at`) não são lidos por hooks pós-017 (path mudou) nem por probe.sh (glob `*/started-at` não casa com raiz). Cleanup `-mindepth 1 -maxdepth 1 -type d` ignora arquivos não-dir. Verificado implicitamente.
- [x] **Defense static — sanitização contra path traversal** — `07-session-id-sanitization.sh` GREEN com 5 variants (path-traversal, embedded-slash, shell-meta, spaces, legitimate-uuid).

## Notes

_Anotações que surgiram durante execução; não pertencem ao plan.md mas úteis pra PR description ou leitor futuro._

- **Decisão inline-duplicar-vs-source (tasks 11/12):** escolhido **inline duplicado**. Os ~6 linhas de parse + sanitize aparecem em 2 lugares; extrair pra `.claude/hooks/lib/session-id.sh` adicionaria um arquivo extra + `source` overhead + acoplamento de path-time. Vendoring é trivial; refactor pra helper só se um terceiro consumer aparecer.
- **Auditoria do passo 1:** 2 testes existentes afetados (`runtime-introspect/05-stale-flag.sh`, `mcp-recipes/05-co-exists-with-011.sh`) — ambos atualizados na mesma diff. ADICIONAL descoberta crítica: `.claude/tools/probe.sh:43` era um consumer cross-capacity de `started-at`. Adoção da Option B resolveu sem quebrar runtime-introspect.
- **Decisão exit code vs JSON do Stop hook (tasks 02/04):** versão inicial dos testes checava exit code != 0 pra detectar block. ERRADO — Stop hook sinaliza block via stdout JSON `{"decision":"block"}` mantendo exit 0. Testes corrigidos pra grep no JSON output. Pattern documentado nos testes pra leitores futuros.
- **`sleep 1` em test 02:** filesystem mtimes têm resolução de segundo (ext4/FAT). Sem `sleep`, `nagged -nt started-at` pode dar tie/false em sequências de turnos rápidos. Adicionado conservadoramente.
- **Cleanup time-based timing:** não medido empiricamente nesta sessão. Implementação usa `find -mtime +7` em depth=1 — O(N) onde N = subdirs ativos. Pra projeto típico com <100 sessões/semana, custo desprezível.
- **`claude --continue` não testado explicitamente:** pesquisa Q5 cobriu `/resume`. `--continue` é inferido como mesmo path. Dogfood manual (task 17) é a chance de validar; se falhar, follow-up spec.
- **Para o leitor futuro:** o Stop hook bloqueia via JSON output, não via exit code. Se for adicionar novos testes que checam block, use a pattern `grep '"decision":"block"'` no stdout.
