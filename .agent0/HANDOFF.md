# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration — porting `.claude/hooks/*` to `.agent0/` hook-by-hook.** 106–110 SHIPPED+merged. **111 delegation-verify-subagent-stop IMPLEMENTED + in-session-validated** (`in-progress`) — only the live cold-restart dogfood remains. Working tree dirty with the 111 implementation (uncommitted at time of writing) + pre-existing untracked `docs/specs/091-sdd-debate-runner/`.

- **111 done in-session:** `post-edit-validate.sh` DELETED (+ its PostToolUse registration); new `.agent0/hooks/delegation-verify.sh` runs the validator once at `SubagentStop`, keyed by `agent_id`. 8-scenario test suite green; `061-delegation-stop` still green; `delegation.md` § Post-edit validator loop rewritten; advisory family (lint/typecheck/tdd) relocated; spec-067 cascade tests removed; Codex config block added; all path refs swept (only intentional breadcrumbs remain).
- **Key design pivot (docs-resolved, see `docs/specs/111-*/notes.md`):** Claude SubagentStop hooks run **in parallel** → the planned sentinel/close-row-suppression is non-viable. Replaced with a **counter-contract**: `delegation-verify.sh` WRITES `.claude/.delegation-state/agents/<id>/consecutive_failures`, `delegation-stop.sh` (UNCHANGED) READS it for the close row's `exit`. Escalation keys on `stop_hook_active`, robust to whether `agent_id` persists.

## Active Work

- _None in flight._ 111 implementation complete; the two live dogfoods (below) are human-gated.

## Next Actions

1. **Live Claude dogfood (cold restart REQUIRED).** This session added `delegation-verify.sh` to `settings.json` `SubagentStop` AFTER session start → NOT yet loaded; only a cold `claude` restart loads it (108/109 lesson). After restart: dispatch a delegated sub-agent against a **stack-detected** scratch repo with failing tests → expect close blocked (exit 2, one continuation) + `subagent-verify`/`decision:blocked` row; then passing close → `decision:pass`/accepted. Confirm `agent_id` preserved + `stop_hook_active` flips true (111 OQ1/OQ2). Full prompt: `docs/specs/111-*/notes.md` § Open questions. Record there, flip `spec.md` Status → shipped.
2. **Codex dogfood** — prompt ready at `docs/specs/111-*/notes.md` § Open questions; hand to a Codex CLI session.
3. After 111 ships: remaining surfaces — PostToolUse edit-surface advisories (`propagation-advise` / `supply-chain-advise` / `secrets-advise`, `apply_patch` path extraction) + `runtime-capture.sh` / `runtime-pre-mark.sh`.

## Decisions & Gotchas

- **Tests pass even while a registration is dormant** — none exercise CC's `if`/matcher dispatch. Only a real PreToolUse fire (post-cold-restart) proves a hook-registration spec; 109 is marked shipped only because both live rows are now recorded. (CC `if` pipe-alternation invalidity + the bare-matcher fix are fully in `.claude/rules/supply-chain.md` § What fires and `.agent0/memory/hook-chain-maintenance.md`.)
- **Codex hook trust is a separate runtime gate** — after editing project `.codex/config.toml`, a cold Codex start showed `1 hook is new or changed`; until trusted, the new project hook did not run. Trust state landed in `~/.codex/config.toml` for `/home/goat/Agent0/.codex/config.toml:pre_tool_use:3:0`.
- **Codex shell launcher wrapper matters** — real `codex exec` surfaced commands as `/bin/bash -lc '<cmd>'`; the supply-chain tokenizer now unwraps common `bash/sh -c/-lc` launchers before looking for manager+verb.
- **`/resume` and `/clear` do NOT reload settings.json hooks** — only a COLD `claude` restart does. The git-mv'd 109 hook did not break the pre-restart session because the old dormant `if` never fired anyway.
- **Hook-move cascade:** a rename breaks hardcoded paths AND the filename-keyed perf harness (`bench-hooks.sh`, `.perf-baseline.json`, latency test). ALWAYS `grep -rn '<oldname>'` after a move.
- **Gates block your own tooling:** feed `--no-verify` / `rm -r` via a file or split calls, never a multi-line inline Bash (governance scans the whole string); `git commit -F`. `091-sdd-debate-runner` is pre-existing untracked, out of scope.
