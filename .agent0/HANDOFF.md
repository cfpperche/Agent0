# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Spec 103 (`reminders-routines-to-agent0`) shipped: reminders + routines data/state relocated `.claude/` → `.agent0/` (`reminders.yaml`, `routines/`, `.routines-state/`). Phase 1 of umbrella 102 (`harness-consolidate-agent0`) — makes `.agent0/` the runtime-neutral harness home; `.claude/`+`.codex/` keep only runtime-exclusive files. Verified green (grep-guard, helper, readout fixtures, harness-sync/runtime-capabilities suites, sync-harness dry-run). Migration capacity-only (forks move own data; see `harness-sync.md`).

Specs 100/101 hook validation re-run in Codex on 2026-05-28. Active hooks behave as planned: spec 100 readouts (`reminders-readout.sh`, `routines-readout.sh`) pass fixtures, spec 101 session handoff passes all multi-runtime fixtures, and local `.codex/config.toml` has `hooks = true` pointing at the shared `.agent0/hooks/` scripts. The earlier spec-100 `mcp-recipes-hint.sh` path is intentionally absent in current harness state because commit `25ae1a6` decommissioned MCP recipe curation + SessionStart hint after spec 100 shipped.

Spec 101 (`session-handoff-multi-runtime`) is implemented, code-reviewed, shipped, committed (`e17be90`), and pushed. The three session lifecycle scripts live under `.agent0/hooks/`: `session-start.sh`, `session-stop.sh`, `session-track-edits.sh`.

Claude registrations in `.claude/settings.json` point at the new shared scripts. Codex has commented opt-in blocks in `.codex/config.toml.example` for `SessionStart`, `Stop`, and `PostToolUse` on `^apply_patch$`. Old `.claude/hooks/session-*.sh` + pointer-only `.claude/SESSION.md` removed; shared state stays at `.claude/.session-state/<session_id>/`.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked, out of scope. `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._

## Next Actions

1. Umbrella 102 next phases (all `undecided`/`deferred` in the gap matrix): decide row 3 (`.claude/.session-state/` → `.agent0/`? reverses 101 OQ-E), then rows 4-6 (runtime-state, browser-state, shared tools). Rows 7-9 (rules/skills/validators) deferred until Codex needs them.
2. Continue the runtime-capabilities re-audit later with `runtime introspect` and `delegation/subagents`.

## Decisions & Gotchas

- Codex `Stop` uses continue-with-corrective-prompt semantics: `{"decision":"block","reason":...}` continues the turn once; `stop_hook_active=true` exits silently to avoid loops.
- Codex SessionStart emits plain framed stdout; Claude keeps JSON dual-channel (`hookSpecificOutput.additionalContext` + `systemMessage`). The branch keys off `CLAUDE_PROJECT_DIR` being unset = "assume Codex" (heuristic, correct in practice since the harness always sets it for Claude).
- `apply_patch` attribution parses patch headers via `_memory-hook-lib.sh::memory_extract_paths`; Bash/MCP writes fall back to porcelain comparison.
- Residual risk (review): if Codex `session_id` carries chars outside `^[a-zA-Z0-9_-]+$`, all such sessions collapse to the shared `unknown/` state dir → cross-session nag interference. Couldn't verify Codex's charset without live tool — worth a live smoke (pairs with reminder `r-2026-05-18`).
- Validation: spec 100 readout fixtures (4/4 current active tests), spec 101 fixtures (6/6), session-handoff (10/10), runtime-capabilities, instruction-drift, codex-mcp-recipes, memory-multi-runtime, `git diff --check`, and TOML parse for `.codex/config.toml{.example,}` all passed this session. Sync-harness dry-run propagates `.agent0/hooks/session-*.sh`, `reminders-readout.sh`, and `routines-readout.sh`.
