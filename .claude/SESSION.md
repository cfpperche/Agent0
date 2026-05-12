# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 021 delivered + propagated + dogfood passed end-to-end + v2 fix shipped.** Agent0 HEAD `3c26870`. Forks: pyshrnk `8903b88`, shrnk `55d143f`, rshrnk `fbcdb09` — all drift-zero (só `.gitignore` "customized" por design).

Live dogfood lendo `linkedin.com/in/cfpperche` foi end-to-end success: WebFetch detectou 999 → signal emitido → user logou headed → 48 cookies + 3 origins (incluindo `li_at` httpOnly) salvos em `.claude/.browser-state/linkedin.com.json` (24 KB, gitignored) → navegação autenticada → perfil extraído via snapshot. Findings do dogfood já corrigidos no spec 021 v2 (commit `3c26870`).

## WIP

None — spec 021 v2 closed loop em Agent0 + 3 forks. `.mcp.json` ativo localmente no Agent0 (não commit, gitignored).

## Next steps

1. **Decidir destino do `.mcp.json` local em Agent0.** Ativo com bloco `playwright`-only. Opções: (a) deixar como está (gitignored, dev-local) — útil pra futuros dogfoods; (b) `rm .mcp.json` pra voltar ao base puro "fork opta in". `.gitignore` agora protege ambos os destinos contra commit acidental.
2. **Pyshrnk dogfood pass 2** — failure-path verification per `~/pyshrnk/docs/dogfood-plan.md § checkpoint 7`. Primeiro candidato a 0-finding pós spec 011+020.
3. **Pyshrnk pass 3** se pass 2 limpa → yield-decay graduation.
4. **Dogfood B2 (shrnk)** e **B3 (rshrnk gap-finding)** — mesmo formato.
5. **Specs 014 + 015** podem entrar a qualquer ponto.
6. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption documentado com spec-009 OVERRIDE marker mas regra "no frameworks" ainda diz o oposto. Amend rule ou revert Starlette.
7. **rshrnk Cargo.{lock,toml} dirty** — pre-existing WIP, não staged em `42fdb12` nem `fbcdb09`. Decidir destino.

Untracked carryovers:
- `docs/specs/010-audit-forensics/` (sessão prévia, sem review)

## Decisions & gotchas

- **`browser_storage_state` / `browser_set_storage_state` NÃO existem em `@playwright/mcp@latest` (2026-05).** Save path validado: `browser_run_code_unsafe` chamando `await page.context().storageState({ path })` — Playwright native, captura httpOnly cookies. Reuse: `--storage-state=<file>` no startup do Playwright MCP (single-host) OR `context.addCookies` mid-session (caveat: sandbox bloqueia `node:fs` import; veja rule doc).
- **`browser_run_code_unsafe` é RCE-equivalent.** Usar SÓ com o shape narrow `storageState({ path })`; nunca com string user/web-derived.
- **Sandbox do Playwright MCP bloqueia `require('fs')` E `await import('fs/promises')`** com `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`. Confirmado empiricamente. Por isso o `--storage-state` startup flag é a via canônica de reuse multi-host (ou merge prévio dos state files num só).
- **`.mcp.json` agora gitignored** (Agent0 + 3 forks, commit `3c26870` + propagação).
- **`.playwright-mcp/` runtime artifacts gitignored** (Agent0 + 3 forks, mesma commit). Snapshots/console logs do MCP acumulam ali; nunca commit.
- **Pattern: lint pass externo pode tocar `.gitignore` enquanto agente trabalha** — Edit falhou com "file modified since read"; remediated by re-reading. Não-bloqueante mas vale lembrar em edits long-running.
- **Spec 021 dogfood validou os 5 passos do workflow ponta-a-ponta.** signal → ativação → headed login → save state → reuse autenticado. Patches v2 atualizam o doc pra refletir API real.
- Demais decisões/gotchas preservadas em git log: `8e07e1f`, `1da9437`, `191c5f9`, `3c26870`.
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is audit trail.
