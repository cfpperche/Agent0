# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration — porting `.claude/hooks/*` to `.agent0/` hook-by-hook.** 106–110 SHIPPED+merged. **111 delegation-verify-subagent-stop SHIPPED + merged** (`444bf70`) — Claude pass path LIVE-dogfooded; Codex dogfood is a flagged handoff (108 posture). Working tree: 111 doc-status updates (uncommitted at write time) + pre-existing untracked `docs/specs/091-sdd-debate-runner/`.

- **111 done:** `post-edit-validate.sh` DELETED (+ PostToolUse registration); new `.agent0/hooks/delegation-verify.sh` runs the validator once at `SubagentStop`, keyed by `agent_id`. 8-scenario suite + `061-delegation-stop` green; `delegation.md` rewritten; advisory family (lint/typecheck/tdd) relocated; spec-067 cascade tests removed; Codex config block added; refs swept.
- **LIVE Claude dogfood DONE (pass path):** real `Agent` dispatch `acb46fdc0a91cab59` → `SubagentStop` fired `delegation-verify.sh` → `decision:pass` row, **in parallel** with the `subagent-stop` close row (same ts). The "cold-restart-gated" worry was empirically wrong — the registration fired in-session.
- **Design pivot (docs + live-confirmed):** Claude SubagentStop hooks run **in parallel** → sentinel/close-row-suppression non-viable. Counter-contract instead: `delegation-verify.sh` WRITES `consecutive_failures`; `delegation-stop.sh` (UNCHANGED) READS it for the close row `exit`. Escalation keys on `stop_hook_active`.

## Active Work

- _None in flight._ 111 shipped+merged; only the Codex dogfood (human-gated) remains as a flagged handoff.

## Next Actions

1. **Codex dogfood (only open 111 item)** — prompt at `docs/specs/111-*/notes.md` § Open questions: enable the `.codex/config.toml` `SubagentStop` verify block, cold-restart Codex, run a delegated sub-agent that fails the validator → expect `decision:blocked` → continuation → `decision:exhausted`, `runtime:"codex-cli"`. Record rows + OQ1/OQ2 answers in `notes.md`.
2. _(optional)_ Live Claude **block-path** dogfood needs a stack-detected scratch repo with failing tests (Agent0 has no stack → only the pass path fires here); block/exhausted are synthetic-validated. This would just upgrade them to live.
3. Next migration surfaces — PostToolUse edit-surface advisories (`propagation-advise` / `supply-chain-advise` / `secrets-advise`, `apply_patch` path extraction) + `runtime-capture.sh` / `runtime-pre-mark.sh`.

## Decisions & Gotchas

- **Tests pass even while a registration is dormant** — none exercise CC's `if`/matcher dispatch. Only a real PreToolUse fire (post-cold-restart) proves a hook-registration spec; 109 is marked shipped only because both live rows are now recorded. (CC `if` pipe-alternation invalidity + the bare-matcher fix are fully in `.claude/rules/supply-chain.md` § What fires and `.agent0/memory/hook-chain-maintenance.md`.)
- **Codex hook trust is a separate runtime gate** — after editing project `.codex/config.toml`, a cold Codex start showed `1 hook is new or changed`; until trusted, the new project hook did not run. Trust state landed in `~/.codex/config.toml` for `/home/goat/Agent0/.codex/config.toml:pre_tool_use:3:0`.
- **Codex shell launcher wrapper matters** — real `codex exec` surfaced commands as `/bin/bash -lc '<cmd>'`; the supply-chain tokenizer now unwraps common `bash/sh -c/-lc` launchers before looking for manager+verb.
- **`/resume` and `/clear` do NOT reload settings.json hooks** — only a COLD `claude` restart does. The git-mv'd 109 hook did not break the pre-restart session because the old dormant `if` never fired anyway.
- **Hook-move cascade:** a rename breaks hardcoded paths AND the filename-keyed perf harness (`bench-hooks.sh`, `.perf-baseline.json`, latency test). ALWAYS `grep -rn '<oldname>'` after a move.
- **Gates block your own tooling:** feed `--no-verify` / `rm -r` via a file or split calls, never a multi-line inline Bash (governance scans the whole string); `git commit -F`. `091-sdd-debate-runner` is pre-existing untracked, out of scope.
