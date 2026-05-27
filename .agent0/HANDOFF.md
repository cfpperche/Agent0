# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 098 (`codex-mcp-recipes-parity`) propagated end-to-end this session.** Both consumers committed + pushed: `mei-saas fd52239` → `github.com:cfpperche/mei-saas.git` (0 customized-refused) and `codexeng 3c1a9d0` → `github.com:cfpperche/codexeng.git` (1 customized-refused on `image/SKILL.md`, preserved). Identical 17-file / +484 / -28 delta in both. Dogfood validated empirically: real `.codex/config.toml` byte-preservation proven via seeded fake (sha pre/post identical, never appears in dry-run); `codex-mcp-recipes/run-all.sh` 3/3 + `harness-sync/35-codex-config-example-untouched.sh` PASS. **Agent0 is 4 commits ahead of `origin/main`** (spec 098 ship + 3 fixes/handoff); not yet pushed.

Codex initiated spec 099, `docs/specs/099-memory-multi-runtime/`, for a cross-runtime debate on porting Agent0 project memory to Codex/Claude parity.

New evidence changed the direction: Codex CLI has native lifecycle hooks. `debate.md` now has Round 3 Claude critique and Round 4 Codex counter filled. The old synthesis in the file is explicitly invalidated/superseded; do not apply it.

Pre-existing/paused work still present:

- `docs/specs/091-sdd-debate-runner/` is untracked and paused.
- Prior local fal.ai/Codex MCP setup remains machine-local (`.codex/config.toml`, `.codex/.env.local`) and should not be committed.

## Active Work

_None. Spec 099 is intentionally ready for Claude Code to edit `debate.md` next._

## Next Actions

1. **Push Agent0 `main`** (4 commits ahead from spec 098 ship + fixes; cleanly buildable). Operator's call — not auto-pushed this session.
2. Ask either Claude Code or Codex to write a fresh synthesis for `docs/specs/099-memory-multi-runtime/debate.md`, based on Round 3 critique + Round 4 counter, replacing/superseding the old synthesis direction.
3. After synthesis, review and confirm before applying changes to `spec.md`.
4. Keep spec 091 paused unless explicitly resumed.
5. Do not commit `.codex/config.toml` or `.codex/.env.local`; they are local machine state.

## Decisions & Gotchas

- **Spec 098 dogfood: `enabled = false` parseable by `codex-cli 0.134.0`** — verified during the consumer apply phase; no startup noise on disabled servers. Closes spec 098 Round 2 verify-first AC and validates the "real TOML over commented TOML" default.
- **Sync determinism confirmed** — mei-saas and codexeng received byte-identical 17-file deltas (`fd52239` / `3c1a9d0`). The shipped-surface set is genuinely consumer-agnostic for spec 098-shaped changes.
- **`codex mcp add` writes user-global (`~/.codex/config.toml`) by default** in 0.134.0; project-scoped propagation requires copying the `.codex/config.toml.example` template directly. Reflected in spec 098 docs.
- Spec 099 Round 4 counter accepts the new hook-based direction: canonical memory path moves to `.agent0/memory/`; shared memory hook implementations should live under `.agent0/hooks/`; Codex memory capability becomes `native-opt-in`; hook parity replaces the mandatory-finalizer-primary plan; `memory-maintain.sh finalize` remains fallback; `.githooks/pre-commit` projection check remains universal backstop.
- Round 4 precision: Codex hook parity should be guaranteed for `apply_patch` memory edits; arbitrary Bash writes are fallback/backstop territory unless plan proves safe path discovery.
- Codex HTTP MCP bearer auth should use `bearer_token_env_var`; literal `bearer_token` is not a valid fal.ai `streamable_http` path in the tested Codex version. Codex does not auto-load dotenv.
