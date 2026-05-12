# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 021 (browser-auth-workflow) delivered + propagated.** Agent0 `8e07e1f` (spec) + `1da9437` (manifest fix: ship `.browser-state/.gitkeep` to forks). All 3 forks adopted at: pyshrnk `b665795`, shrnk `9bc0c44`, rshrnk `42fdb12`. Drift-zero (only `.gitignore` "customized" by design — fork-specific stack patterns). 4 doc edits + 1 scaffold + 1 gitignore line; pure documentation + convention, zero new hooks/MCPs/env-vars/audit logs.

Direction implemented as agreed: Playwright MCP default for auth-gated reads (`headed → save → reuse`); Chrome DevTools MCP debug-only with `--user-data-dir` profile (NOT `--autoConnect` default); human-in-the-loop is chat-only via `BROWSER_AUTH_REQUIRED: <host>` phrase; X/Twitter shortcut via `unrollnow.com/status/<id>` documented as first-try before falling back to auth flow.

## WIP

None — spec 021 closed loop in Agent0 + 3 forks.

## Next steps

1. **Pyshrnk dogfood pass 2** — failure-path verification per `~/pyshrnk/docs/dogfood-plan.md § checkpoint 7`. Primeiro candidato a 0-finding pós spec 011+020.
2. **Pyshrnk pass 3** se pass 2 limpa → yield-decay graduation.
3. **Dogfood B2 (shrnk)** e **B3 (rshrnk gap-finding)** — mesmo formato.
4. **Specs 014 + 015** podem entrar a qualquer ponto.
5. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption documentado com spec-009 OVERRIDE marker mas regra "no frameworks" ainda diz o oposto. Amend rule ou revert Starlette.
6. **rshrnk Cargo.{lock,toml} dirty** — pre-existing WIP, unrelated to spec 021, deixado sem stage no commit `42fdb12`. Decidir destino.

Untracked carryovers:
- `docs/specs/010-audit-forensics/` (sessão prévia, sem review)

## Decisions & gotchas

- **Spec 021 added a guard comment in `sync-harness.sh` naming `.browser-state/` AND `memory/` as project-local, but the sub-agent that wrote the comment forgot to add `.claude/.browser-state/.gitkeep` to `COPY_CHECK_FILES`.** Fixed in `1da9437` mirroring the existing `.claude/memory/.gitkeep` manifest entry. Caught during fork propagation — forks would have received everything else but the empty bucket. Lesson: manifest entries and guard comments are linked; review both together when adding a new project-local bucket.
- **`.gitignore` permanently "customized" in forks by design.** Each fork has stack-specific patterns (Python: `.venv/`, Node: `node_modules/`, Rust: `target/`). Canonical sync flag: `--apply --force --force-except='.gitignore'` (then manually patch each fork's gitignore for new Agent0 ephemeral entries).
- **X/Twitter readability em 2026: Nitter morto, ThreadReader exige sua própria URL, `unrollnow.com/status/<id>` funcionou direto.** Documentado como atalho no rule doc; agent tenta antes do auth flow.
- **MCPs maduros para auth: Playwright (`storage-state.json`) default e Chrome DevTools (`--user-data-dir` profile) debug-only.** Ambos recipes já existiam (spec 012); spec 021 fechou o gap operacional (workflow doc + bucket + sinalização).
- **`storage-state.json` é credencial.** `.claude/.browser-state/*.json` gitignored, cross-referenced em `.claude/rules/secrets-scan.md § Gotchas`.
- **PostToolUseFailure payload DIVERGES from PostToolUse.** (spec 020.) `runtime-capture.sh` keys on `hook_event_name`. Doc em `.claude/memory/cc-platform-hooks.md`.
- **Mid-session settings.json reload works** (spec 020 Phase 3).
- **`core.hooksPath` activation MANUAL by design** (Lazarus). Spec 018 hint silences once activated.
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is audit trail.
