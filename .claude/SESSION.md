# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 021 delivered + 2 dogfoods passed end-to-end + 3 patch rounds shipped.** Agent0 HEAD `02e9507`. Forks: pyshrnk `25be721`, shrnk `ee3a175`, rshrnk `8126cea` — all drift-zero (só `.gitignore` "customized" por design).

Dogfood 1 (`linkedin.com/in/cfpperche`): WebFetch 999 → signal → headed login → 48 cookies + `li_at` httpOnly salvos → perfil extraído.

Dogfood 2 (`x.com/ClaudeCodeLog/status/2053913625983692979`): unrollnow cobriu OP thread mas NÃO replies → signal → headed login → 60 cookies + `auth_token` httpOnly salvos → OP (4 tweets) + 9 replies extraídos (de 37 totais; X virtualiza scroll).

## WIP

None — spec 021 fechado em 3 rodadas de patch (v1 base, v2 storage-state correção + gitignore mcp/playwright runtime, v3 X/Twitter shortcut limits + virtualization gotcha). `.mcp.json` ativo localmente no Agent0 (gitignored).

## Next steps

1. **Pyshrnk dogfood pass 2** — failure-path verification per `~/pyshrnk/docs/dogfood-plan.md § checkpoint 7`. Primeiro candidato a 0-finding pós spec 011+020.
2. **Pyshrnk pass 3** se pass 2 limpa → yield-decay graduation.
3. **Dogfood B2 (shrnk)** e **B3 (rshrnk gap-finding)** — mesmo formato.
4. **Specs 014 + 015** podem entrar a qualquer ponto.
5. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption documentado com spec-009 OVERRIDE marker mas regra "no frameworks" ainda diz o oposto. Amend rule ou revert Starlette.
6. **rshrnk Cargo.{lock,toml} dirty** — pre-existing WIP, não staged nas 3 commits de sync deste ciclo. Decidir destino.
7. **Optional spec 021 dogfood passo 5 (reuse end-to-end)** — adicionar `--storage-state=<file>` em `.mcp.json`, restart, verificar que perfil/post carrega sem human-in-the-loop. State files (`linkedin.com.json`, `x.com.json`) prontos em disco.

Untracked carryovers:
- `docs/specs/010-audit-forensics/` (sessão prévia, sem review)

## Decisions & gotchas

- **`browser_storage_state` / `browser_set_storage_state` NÃO existem em `@playwright/mcp@latest` (2026-05).** Save path validado: `browser_run_code_unsafe` chamando `await page.context().storageState({ path })` — Playwright native, captura httpOnly cookies. Reuse: `--storage-state=<file>` no startup (single-host) OR `context.addCookies` mid-session (caveat: sandbox bloqueia `node:fs`).
- **`browser_run_code_unsafe` é RCE-equivalent.** Usar SÓ com shape narrow `storageState({ path })`; nunca com string user/web-derived.
- **Sandbox do Playwright MCP bloqueia `require('fs')` E `await import('fs/promises')`** com `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`. Confirmado empiricamente. `--storage-state` startup flag é a via canônica de reuse.
- **unrollnow/threadreaderapp shortcut cobre só thread do OP** — replies de outros, quote-tweets, sub-threads requerem auth flow mesmo pra posts públicos. Caveat documentado em `mcp-recipes.md § X/Twitter shortcut` (commit `02e9507`).
- **X.com vira reply list com virtualização** — single `browser_snapshot` pega ~10 replies por viewport; pra coletar todas usar `browser_press_key("PageDown")` ou `browser_evaluate(window.scrollBy)` em loop. Documentado mesma commit.
- **`.mcp.json` + `.playwright-mcp/` gitignored** (Agent0 + 3 forks, commit `3c26870`).
- **Lint pass externo pode tocar arquivos durante edição** — Edit falhou com "file modified since read"; remediated by re-reading. Não-bloqueante.
- **Spec 021 validou ponta-a-ponta**: signal → ativação → headed login → save state via `browser_run_code_unsafe` → reuse autenticado. 5 passos do workflow funcionam empiricamente.
- Demais decisões em git log: `8e07e1f`, `1da9437`, `191c5f9`, `3c26870`, `02e9507`.
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is audit trail.
