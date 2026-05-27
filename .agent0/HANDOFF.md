# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 100 (`multi-runtime-session-readouts`) scaffold phase complete; implementation Phase A pending.** Three commits land locally on `main`, 3 ahead of `origin`: shim removal follow-up to spec 099 (`c16677d`), spec 100 scaffold + cross-model debate (`b34bdf5`), spec 100 plan + tasks (`991061e`). See `git log --oneline c16677d^..HEAD` for details.

Spec 100 ports 3 SessionStart readout hooks (reminders, routines, mcp-recipes-hint) from `.claude/hooks/` to `.agent0/hooks/` — Tier 1 follow-up to spec 099. Cross-model debate (Claude initiating / Codex reviewing) converged in 1 round; 14 deltas applied to `spec.md`. Three plan-locked OQ resolutions: **hard cutover** (no compat shims, spec 099 proved zero migration cost), **no new readout lib** (source `_memory-hook-lib.sh` for `memory_project_dir`; rule-of-three not met for extraction), **dual env vars** (`CLAUDE_*` canonical + `AGENT0_*` alias; canonical-name flip deferred to separate cross-cutting spec).

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked; `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._

## Next Actions

1. **Spec 100 Phase A.** Tasks 1-2 in `docs/specs/100-multi-runtime-session-readouts/tasks.md`: lift `reminders-readout.sh` + `routines-readout.sh` to `.agent0/hooks/`, source `_memory-hook-lib.sh`, dual-honor env vars. Pure mechanical, ~215 LOC ported total.
2. **Spec 100 Phase B.** Task 3: port `mcp-recipes-hint.sh` with runtime-aware install-pointer wording (Codex sees `.codex/config.toml.example`, Claude sees `.mcp.json.example`) via `memory_runtime` helper.
3. **Spec 100 Phases C-E.** Registrations (`settings.json` + `config.toml.example`), doc updates (`mcp-recipes.md` Claude-only line; `runtime-capabilities.md` 3 rows), 5 fixture tests + Codex dogfood.
4. **Push 3 pending commits when ready.**
5. **mei-saas test 01 staleness.** Pre-fix `01-files-are-git-tracked.sh` picks up on next regular `sync-harness --apply` (cosmetic).
6. Spec 091 stays paused unless explicitly resumed.

## Decisions & Gotchas

- **`mcp-recipes-hint.sh` reverses spec 098's "Claude-only" decision.** Spec 098 kept it Claude-only for scope discipline (MCP activation only, predated multi-runtime hooks). Codex CLI as reviewing agent in spec 100 debate confirmed no runtime reason for the asymmetry. Auditability via § Intent paragraph + resolved-OQ strikethrough in `spec.md`.
- **Codex `apply_patch` empirical contract.** `tool_input.command` is primary payload field; `tool_use_id` shape is `call_*` (vs Claude's `toolu_*`); `tool_name == "apply_patch"` is the canonical runtime signal used by `memory_runtime` helper.
- **Frontmatter validation single-owner.** `memory-frontmatter-validate.sh` emits the advisory; `memory-events-journal.sh` is journal+project only. Re-introducing validate calls from other hooks recreates the spec-099-review double-fire bug.
- **Tests that ship to consumers use generic property assertions, not hardcoded entry names.** Pattern established in commit `43d8539`. Re-audit shipped tests when a regression surfaces.
- **codexeng carries 1 load-bearing customization** in `.claude/skills/image/SKILL.md § Notes` (the `codexeng fork hardening` bullet). Re-apply on every sync via the consumer-extension convention.
- **`runtime-capabilities.md` re-audit shortened by spec 100.** Three rows (`reminders` / `routines` / `mcp recipes` for Codex) close when 100 ships. Remaining pending: `session handoff` (`convention` → likely `native-opt-in`), `runtime introspect` (`read-only`), `delegation/subagents` (`unsupported` — no port path until Codex ships subagents).
