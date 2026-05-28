# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Umbrella 102 (`harness-consolidate-agent0`) consolidating the harness into `.agent0/` as the runtime-neutral home (`.claude/`+`.codex/` keep only runtime-exclusive files). **Phase 1 (103)**: reminders + routines. **Phase 2 (104)**: the three shared state dirs (`.session-state/`, `.runtime-state/`, `.browser-state/`). **Phase 3 (105, this session)**: shared shell tools relocated `.claude/tools/` → `.agent0/tools/` — all 8 scripts (`sync-harness`, `probe`, `check-instruction-drift`, `bench-hooks`, `run-routine`, `install`/`uninstall-routines`, `codex-local-env`) + `lib/managed-block.sh`; `.claude/tools/` is gone. All gap-matrix `move` rows (1-6) are now shipped.

105 closed the four delicate spots: sync-harness's manifest glob + lib-source + `_self_rebootstrap` self-ref + `MANAGED_BLOCK_LIB` fallback, and the three path-scoped rule `paths:` triggers (`harness-sync`/`runtime-capabilities`/`runtime-introspect`). 87 affected-suite tests green; smoke + scratch-consumer dry-run confirm capacity-only migration (old `.claude/tools/*.sh` orphan-removed, new `.agent0/tools/*.sh` copied). **Uncommitted — 105 changes are in the working tree, not yet committed** (104 + 100/101 are committed: `1273ed4`, `e17be90`).

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked, out of scope. `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._

## Next Actions

1. **Commit 105** when the founder is ready (working tree currently dirty with the relocation + spec 105 + umbrella row 6 flip).
2. **Close umbrella 102** — only acceptance criteria 4 + 5 remain: (4) encode the § Classification principle durably (new `.claude/rules/harness-home.md` vs extend `memory-placement.md`'s bucket model); (5) document the consumer-migration posture in `.claude/rules/harness-sync.md`. The founder reserved these as part of "other refactoring questions" raised after 105 — do NOT pre-empt the where-to-encode decision.
3. Founder flagged broader refactoring questions to raise post-105 (the "lacuna is not just tests" thread — `.claude/tests/` and `.claude/validators/` placement, the consumer-side `harness-sync-baseline.json` location, etc. — all currently `deferred`/`stays` in 102's matrix).
4. Continue the runtime-capabilities re-audit later (`runtime introspect` + `delegation/subagents` rows).

## Decisions & Gotchas

- **105 live-vs-frozen rule:** rewrote every `.claude/tools/` ref outside `docs/specs/`; left frozen specs AND one historical memory narrative (`.agent0/memory/cc-platform-hooks.md:138`, a past-tense CC hook-dedup observation citing probe.sh) untouched. The acceptance grep whitelists that one line.
- **105 fixture gotcha:** sync-harness's "looks like an Agent0 repo" check needs `.claude/` (still valid post-102); fixtures `harness-sync/33` + `instruction-drift/05` had it only as a side effect of the old `mkdir …/tools/lib` → add explicit `$SRC/.claude`. Three bare-dir `mkdir` refs (no trailing slash) escaped the sed — grep the bare-dir form on future path moves.
- **105 self-rebootstrap:** the relocation `--apply` self-overwrites once (old `.claude/tools/sync-harness.sh` deleted while bash reads it); harmless re-run-completes, documented in `harness-sync.md` § Gotchas. No mitigation code.
- Codex `Stop` uses continue-with-corrective-prompt: `{"decision":"block","reason":...}` continues once; `stop_hook_active=true` exits silently. SessionStart branches on `CLAUDE_PROJECT_DIR` unset = "assume Codex".
- Residual review risk: a Codex `session_id` with chars outside `^[a-zA-Z0-9_-]+$` collapses all such sessions to the shared `unknown/` state dir — worth a live smoke (reminder `r-2026-05-18`).
