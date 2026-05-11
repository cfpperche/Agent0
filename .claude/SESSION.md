# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Specs delivered nesta sessão:** 016 (harness-sync) recap, 017 (session-state-isolation), 018 (githooks-activation-hint), 019 (project-memory) + amendment (memory scaffold ships), 013 (lint-validator) recap. Tudo commitado em Agent0 e propagado para os 3 shrnks.

**Spec 020 (runtime-capture-on-failure) — scaffold pronto, impl pendente.** Spec/plan/tasks completos. Próxima sessão começa direto na Phase 1 (RED tests).

**Pyshrnk dogfood pass 1 deliverable:** Starlette ASGI app + 16 tests (commit `d19212b`). Surfacearia o finding crítico que motivou specs 019+020.

Agent0 recentes:
- `e1a7182` spec 019 amendment (memory scaffold ships)
- `1eb3803` spec 019 project-memory
- `3677807` spec 013 lint-validator
- `91525b6` pyshrnk dogfood pass 1 findings
- `549965e` spec 018 githooks-activation
- `f33ffa8` spec 017 session-state-isolation
- `373ece9` spec 016 harness-sync

Shrnks (todos com `.claude/memory/.gitkeep` empty scaffold + zero drift):
- pyshrnk `0751c6a` (spec 019 amendment), `e963ff0`, `92c7013`, `d19212b` (Starlette dogfood)
- shrnk `8a2de8c`, `7374d1d`, `c10927a`
- rshrnk `c0feba2`, `79637a0`, `a1a14e8`

Agent0 ativou `core.hooksPath .githooks` localmente; hint do spec 018 silencia. Cada shrnk continua precisando ativar manualmente — hint vai aparecer no SessionStart deles até rodar `git config core.hooksPath .githooks`.

## WIP

**Spec 020 (runtime-capture-on-failure)** — pickup point é Phase 1 task 1 em `docs/specs/020-runtime-capture-on-failure/tasks.md`.

Resumo do design:
- Smallest viable patch: 1 entrada nova em `.claude/settings.json` `hooks.PostToolUseFailure` (mirror do PostToolUse(Bash) shape). **Zero code change** em `runtime-capture.sh` — inferência já trata exit≠0 via `inferred_status`.
- 2 RED tests novos: `11-failure-path-capture.sh` (synthesize PostToolUseFailure payload, assert snapshot FAIL) + `12-settings-registration.sh` (jq parse settings).
- Empirical verification em Phase 3: deliberate failure injection em Agent0 (descobre se settings reload mid-session OU rely em pyshrnk dogfood pass 2).
- Docs: rule update + memory cc-platform-hooks.md update de "forthcoming" → past tense.
- Sync 3 shrnks + update pyshrnk dogfood-plan.md com pass-2 checkpoint.

Open assumption sob incerteza: PostToolUseFailure payload shape assumido idêntico ao PostToolUse (docs canônica truncada para esse evento). Plan documenta a assumption + observable signal se quebrar (snapshot com body vazio + UNKNOWN inference).

## Next steps

1. **Spec 020 impl em sessão fresca.** Phase 1 → 5 sequencial. Validar empiricamente em Phase 3 — se settings reload mid-session, fechar loop em Agent0; senão, deferir prova para pyshrnk dogfood pass 2.
2. Pyshrnk dogfood pass 2 — primeiro pass post-fix; deve confirmar `status: FAIL` capturado para pytest falhando, fechando o finding pass-1 do spec 011.
3. Pyshrnk pass 3 (graduação por yield-decay — 2 consecutive 0-finding).
4. Dogfood B2 (shrnk) e B3 (rshrnk gap-finding pass).
5. Specs 014 + 015 podem entrar em qualquer ponto.

Untracked carryovers:
- `docs/specs/010-audit-forensics/` (sessão prévia, sem review)

## Decisions & gotchas

- **Sistema de memória do projeto agora tem 3 buckets (não 2).** CC per-user para preferências apenas. `.claude/memory/<topic>.md` para conhecimento factual do projeto (git-tracked, NÃO shipa para forks via sync-harness — exceto o `.gitkeep` empty scaffold). `.claude/rules/<topic>.md` para mandatos behavior + capacity docs (git-tracked, SHIPA para forks). Spec 019 + amendment formalizou isso.
- **Cada fork ganha capacity de project memory.** Empty `.claude/memory/.gitkeep` shipa via sync-harness manifest; conteúdo é one-source-per-project (Agent0's memories ficam Agent0-only; pyshrnk acumula as suas, etc).
- **Claude Code expõe 29 hook events, não 9.** Documentado em `.claude/memory/cc-platform-hooks.md` com payload shape, exit-code semantics, e a meta-lesson sobre como o spec 011 foi shipado com gap. Cross-referenced de `.claude/rules/runtime-introspect.md`.
- **`PostToolUse` fires só em exit-zero.** `PostToolUseFailure` existe para o caminho FAIL — spec 020 vai registrar `runtime-capture.sh` em ambos. Empiricamente confirmado nesta sessão (mtime test).
- **Pyshrnk adotou Starlette/uvicorn** durante dogfood B1 — desvia de CLAUDE.md "no frameworks". Documentado com OVERRIDE marker do spec 009. CLAUDE.md de pyshrnk precisará reconciliar próxima sessão (manter Starlette + atualizar regra OU reverter).
- **`--force-except=GLOB`** é per-file safety hatch para `--apply --force` (canonical case: `.gitignore` que tem fork-specific stack patterns).
- **`core.hooksPath` activation continua MANUAL por design** (Lazarus). Spec 018 SessionStart hint surfaces o comando passivamente.
- **SESSION.md auto-injection ~2KB preview budget** — replace stale; `git log` é audit trail.
