# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 098 is implemented and committed.** Agent0 `main` is 2 commits ahead of `origin/main`:

- `2aa23a1` docs(098): ship codex-mcp-recipes-parity — Codex CLI gains native MCP recipes
- `bfd630d` fix(098): ship project-local codex env launcher

Spec 098 now ships the Codex MCP template and consumer-safe local env path:

- `.codex/config.toml.example` is synced to consumers; real `.codex/config.toml` remains local.
- `.claude/tools/codex-local-env.sh` is synced to consumers; it loads `.codex/.env.local` only for that Codex process.
- `.codex/.env.local` is gitignored and not synced.
- Dogfood in Agent0 passed for Playwright, Chrome DevTools, and fal.ai `recommend_model` via local env launcher.

Repo state after the commit is clean except `docs/specs/091-sdd-debate-runner/` (paused, untracked) and ignored local dogfood files under `.codex/`.

## Active Work

_None._

## Next Actions

1. **Resync + dogfood `mei-saas`:**
   - `bash /home/goat/Agent0/.claude/tools/sync-harness.sh --apply --agent0-path=/home/goat/Agent0 /home/goat/mei-saas`
   - Verify `.codex/config.toml.example` and `.claude/tools/codex-local-env.sh` land.
   - In the consumer, create/keep local `.codex/config.toml` + `.codex/.env.local` as needed, then dogfood via `bash .claude/tools/codex-local-env.sh exec ...`.
   - Commit the consumer sync after reviewing diff.

2. **Resync + dogfood `codexeng`:**
   - `bash /home/goat/Agent0/.claude/tools/sync-harness.sh --apply --agent0-path=/home/goat/Agent0 /home/goat/codexeng`
   - Preserve codexeng's known `.claude/skills/image/SKILL.md` customization; do not force it unless explicitly requested.
   - Verify the same Codex MCP local-env flow as `mei-saas`.
   - Commit the consumer sync after reviewing diff.

3. **Push Agent0 `main`** when the local two commits are ready for remote.

4. **Spec 091** stays paused unless explicitly resumed.

## Decisions & Gotchas

- **Do not commit real Codex local files.** `.codex/config.toml`, `.codex/.env.local`, and local launcher experiments are machine/project state. Agent0 only ships `.codex/config.toml.example` and `.claude/tools/codex-local-env.sh`.
- **Codex does not auto-load dotenv.** Consumers must launch through `bash .claude/tools/codex-local-env.sh` if they want project-local MCP keys without OS-level exports.
- **`codex mcp add` writes global config by default** in the tested CLI; for project-scoped MCP recipes, edit `.codex/config.toml` copied from the template.
- **Codexeng's `image/SKILL.md` customization is stable.** It has intentionally refused sync before; keep preserving it without `--force`.
