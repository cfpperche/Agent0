# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 100 committed** (`97159e9`) — three SessionStart readouts now live under `.agent0/hooks/`.

**MCP-recipes curation + SessionStart hint decommissioned this session** (no spec — direct implementation). What remains: `.mcp.json.example` (Claude) and `.codex/config.toml.example` (Codex) keep the 6 MCP server blocks intact (playwright / chrome-devtools / dbhub / laravel-boost / next-devtools / fal-ai). What's gone: `.agent0/hooks/mcp-recipes-hint.sh`, `.claude/rules/mcp-recipes.md` (catalog + signal table + recipe sections + hint output shape), and three test suites (`mcp-recipes`, `mcp-recipes-laravel`, `monorepo-stack-detect`) plus the spec 100 `03-mcp-recipes-fixture.sh`. The § Authenticated workflow content was preserved by renaming → `.claude/rules/browser-auth.md` (slimmer, self-contained).

Hook registration: `.claude/settings.json` SessionStart now has 4 hooks (session-start + reminders + routines + memory-decay); `.codex/config.toml.example` has 3 commented SessionStart blocks (memory-decay + reminders + routines). Multi-runtime-readouts fixture `05-toml-parse.sh` updated to expect 3 SessionStart entries (was 4); `04-subdir-launch.sh` lost the mcp-hint assertion.

Cross-refs updated: `CLAUDE.md` / `AGENTS.md` § MCP recipes (templates-only wording) + § Browser auth (points at new rule), `runtime-capabilities.md` (MCP recipes row drops hook ref, new `browser auth` row added), `php-laravel-support.md` § 6 (template-only Laravel Boost block), `image-gen.md`, `secrets-scan.md`, `.runtime-state/README.md`, `.claude/tests/runtime-capabilities/fixtures.sh`, `.claude/skills/image/SKILL.md`, `.claude/skills/product/SKILL.md`, `.agent0/memory/cc-platform-hooks.md`.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` remains untracked and out of scope. `.codex/config.toml` + `.codex/.env.local` remain machine-local.

## Active Work

_None active._

## Next Actions

1. Review/commit this decommission diff.
2. Push the 4 (now 5) local commits when ready.
3. Continue per-capacity Codex port lineage (session-handoff is the next Tier 2 candidate per `runtime-capabilities.md:45` re-audit).

## Decisions & Gotchas

- **No spec for this decommission** — user invoked `/goal` to skip SDD; trade-off accepted (audit trail lives in commit + this handoff).
- `.claude/rules/browser-auth.md` is the new canonical for `BROWSER_AUTH_REQUIRED:` + `.claude/.browser-state/<host>.json` lifecycle. Self-contained, no longer co-located with MCP catalog.
- Templates (`.mcp.json.example` / `.codex/config.toml.example`) intentionally KEEP all 6 server blocks — `codex-mcp-recipes` test suite (3 scenarios) still passes because it validates the template, not the rule.
- The `mcp-recipes-hint.sh` SessionStart block in `.codex/config.toml.example` was removed; `.codex/config.toml.example` ships 3 commented SessionStart blocks now (was 4).
