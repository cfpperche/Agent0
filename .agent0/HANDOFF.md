# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Codex was updated locally to `codex-cli 0.134.0`.

Agent0 fal.ai MCP is operational when Codex is launched through:

```bash
bash .claude/tools/codex-local-env.sh
```

Local-only state:

- `.codex/config.toml` enables `fal-ai` with `bearer_token_env_var = "FAL_KEY"`.
- `.codex/.env.local` contains `FAL_KEY` and is gitignored.
- `bash .claude/tools/codex-local-env.sh mcp list` shows `fal-ai` enabled with bearer-token auth.

Tracked docs/template were corrected after dogfood found the earlier direct-token advice was wrong: `codex-cli 0.133.0` rejects literal `bearer_token` for `streamable_http`. The documented Codex path is now env-var auth through `bearer_token_env_var`.

Spec 098's fal.ai/Codex bearer-token correction has been committed locally.

Tracked working tree is expected to be clean after this handoff commit.

Pre-existing/paused work still present:

- `docs/specs/091-sdd-debate-runner/` is untracked and paused.

## Active Work

_None._

## Next Actions

1. Do not commit `.codex/config.toml` or `.codex/.env.local`; they are local machine state.
2. Resync/dogfood consumers (`mei-saas`, `codexeng`) after the Agent0 correction is committed, preserving known consumer customizations.
3. Push Agent0 `main` when local commits are ready.
4. Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- Codex HTTP MCP bearer auth should use `bearer_token_env_var`; literal `bearer_token` is not a valid fal.ai `streamable_http` path in the tested Codex version.
- Codex does not auto-load dotenv. Use `bash .claude/tools/codex-local-env.sh` or export `FAL_KEY` before starting Codex directly.
- fal.ai keys are secrets. A key was briefly present in local config during debugging; rotate it in fal.ai if it has not already been rotated.
- `codex mcp add` writes global config by default in the tested CLI; use project `.codex/config.toml` for Agent0-scoped MCP recipes.
- Codexeng's `image/SKILL.md` customization has intentionally refused sync before; preserve it without `--force` unless explicitly requested.
