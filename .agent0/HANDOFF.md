# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Umbrella 102 (`harness-consolidate-agent0`) consolidating the harness into `.agent0/` as the runtime-neutral home (`.claude/`+`.codex/` keep only runtime-exclusive files). **Phase 1 (103)** shipped: reminders + routines → `.agent0/`. **Phase 2 (104, shipped this session)**: the three shared state dirs relocated `.claude/` → `.agent0/` — `.session-state/` (reverses 101 OQ-E), `.runtime-state/` (path only; producer hooks stay Claude-only), `.browser-state/`. All 8 affected suites green (~102 tests: session-*, runtime-introspect, runtime-capture-php, harness-sync 36, instruction-drift); sync-harness dry-run confirms capacity-only propagation of the two sentinels + `.agent0/.*-state/` gitignore additions. Committed this session (umbrella 102 phase 2).

Specs 100/101 shipped + committed (`e17be90`) + Codex-validated 2026-05-28. Session lifecycle scripts live in `.agent0/hooks/`; Claude registers via `settings.json`, Codex via commented opt-in blocks in `.codex/config.toml.example`. `mcp-recipes-hint.sh` intentionally absent (decommissioned in `25ae1a6`).

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked, out of scope. `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._

## Next Actions

1. **Phase 3 — `105-shared-tools-to-agent0`** (umbrella 102 row 6, the last `move`): `.claude/tools/*.sh` (sync-harness, probe, lib, routines, instruction-drift, `codex-local-env`) → `.agent0/tools/`. Largest blast radius (~85 refs across tests/rules/docs); own spec to avoid a mega-diff. This is the row that flips probe.sh's invocation path — 104 deliberately left every `bash .claude/tools/probe.sh` self-ref untouched, so 105 owns all of them. Run `/sdd new shared-tools-to-agent0` to scaffold.
2. Still open in 102: acceptance criterion 4 (encode § Classification principle durably — new `.claude/rules/harness-home.md` vs extend `memory-placement.md`) + criterion 5 (consumer-migration posture in `harness-sync.md`). Land with 105 or standalone. Umbrella closes once 105 ships + crit 4/5 done.
3. Continue the runtime-capabilities re-audit later with `runtime introspect` and `delegation/subagents`.

## Decisions & Gotchas

- Codex `Stop` uses continue-with-corrective-prompt semantics: `{"decision":"block","reason":...}` continues the turn once; `stop_hook_active=true` exits silently to avoid loops.
- Codex SessionStart emits plain framed stdout; Claude keeps JSON dual-channel (`hookSpecificOutput.additionalContext` + `systemMessage`). The branch keys off `CLAUDE_PROJECT_DIR` being unset = "assume Codex" (heuristic, correct in practice since the harness always sets it for Claude).
- `apply_patch` attribution parses patch headers via `_memory-hook-lib.sh::memory_extract_paths`; Bash/MCP writes fall back to porcelain comparison.
- Residual risk (review): if Codex `session_id` carries chars outside `^[a-zA-Z0-9_-]+$`, all such sessions collapse to the shared `unknown/` state dir → cross-session nag interference. Couldn't verify Codex's charset without live tool — worth a live smoke (pairs with reminder `r-2026-05-18`).
- 104 gotcha: `bash .claude/tools/probe.sh` self-references were left untouched on purpose (probe.sh itself is row 6 / Phase 3); only the state paths probe *reads* moved to `.agent0/`. Harness-sync gitignore-merge test fixtures (13/14/15) were updated to `.agent0/.*-state/` for shipped-fixture fidelity even though they're mechanism-only (they ship to consumers).
