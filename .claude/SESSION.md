# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Spec 020 closed (Agent0 `462fb15` + all 3 forks propagated, 12/12 GREEN). This session was research-only — no code changes. Triggered by user asking Agent0 to read an X/Twitter thread (`@ClaudeCodeLog` 2.1.139 release notes). WebFetch hit 402 on `x.com`; Nitter is dead in 2026; `unrollnow.com/status/<id>` worked as the X-specific shortcut.

Broadened to "how do we give Agent0 the capacity to read any site, with human-in-the-loop." Pesquisa concluída; direção definida com o usuário; spec a abrir.

## WIP

**Pending: open spec 021 `browser-auth-workflow`** (or lighter touch on `.claude/rules/mcp-recipes.md` — usuário ainda não escolheu entre as duas formas). User-confirmed direction:
- **Playwright MCP como default** para acesso autenticado rotineiro (headed-login → save `storage-state.json` → reuse). Recipe já existe no `.mcp.json.example` + `.claude/rules/mcp-recipes.md`; falta documentar o workflow + onde salvar (`.claude/.browser-state/<host>.json`, gitignored).
- **Chrome DevTools MCP como camada de debug**, perfil dedicado via `--user-data-dir`. NÃO `--autoConnect` por default (superfície grande demais).
- **Sinalização ao humano: apenas via chat** (zero infra nova). Convenção textual tipo `BROWSER_AUTH_REQUIRED: <host>` para grep no scrollback.
- **Caso X/Twitter:** documentar `unrollnow.com/status/<id>` como atalho antes de qualquer login flow.

## Next steps

1. **Decidir: spec 021 formal vs. update direto em `.claude/rules/mcp-recipes.md`** (pergunta aberta no fim da sessão de pesquisa). Spec é mais defensivo; rule-update é mais barato e suficiente se o escopo for só doc + `.gitignore`.
2. **Pyshrnk dogfood pass 2** — failure-path verification per `~/pyshrnk/docs/dogfood-plan.md § checkpoint 7`. Primeiro candidato a 0-finding pós spec 011+020.
3. **Pyshrnk pass 3** se pass 2 limpa → yield-decay graduation.
4. **Dogfood B2 (shrnk)** e **B3 (rshrnk gap-finding)** — mesmo formato.
5. **Specs 014 + 015** podem entrar a qualquer ponto.
6. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption documentado com spec-009 OVERRIDE marker mas regra "no frameworks" ainda diz o oposto. Amend rule ou revert Starlette.

Untracked carryovers:
- `docs/specs/010-audit-forensics/` (sessão prévia, sem review)

## Decisions & gotchas

- **X/Twitter readability em 2026: Nitter morto, ThreadReader exige sua própria URL, `unrollnow.com/status/<id>` funcionou direto.** Atalho específico do domínio — não é estratégia geral, mas resolve o caso comum de "agente precisa ler thread do X".
- **MCPs maduros para auth: Playwright (`storage-state.json`) e Chrome DevTools (`--user-data-dir` profile).** Ambos já são recipes no Agent0 desde spec 012; o gap é workflow doc, não capacidade.
- **`storage-state.json` é credencial.** Vai em `.gitignore`, possivelmente menção em `.claude/rules/secrets-scan.md`. Pasta sugerida: `.claude/.browser-state/<host>.json` (uma por host = blast radius mínimo).
- **PostToolUseFailure payload DIVERGES from PostToolUse.** Empírico (spec 020 dump-probe). `runtime-capture.sh` keys on `hook_event_name`. Doc em `.claude/memory/cc-platform-hooks.md`.
- **Mid-session settings.json reload works.** Spec 020 Phase 3.
- **`core.hooksPath` activation MANUAL by design** (Lazarus). Spec 018 hint silences once activated.
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is audit trail.
