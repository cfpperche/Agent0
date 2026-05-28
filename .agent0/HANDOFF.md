# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration — porting `.claude/hooks/*` to `.agent0/` hook-by-hook.** 106 delegation + 107 governance shipped (committed + pushed, live-dogfooded both runtimes). This session: **108 `secrets-scan-multi-runtime`** committed on branch `feat/108-secrets-preflight-multi-runtime` (`e036491`), NOT yet pushed/merged.

- **108** — `git mv .claude/hooks/secrets-scan.sh → .agent0/hooks/secrets-preflight.sh` (renamed: it scans no secrets, it gates commit shape + bridges the override). Ran a cross-model debate with Codex first (`docs/specs/108-*/debate.md`, converged) — surfaced real refinements, so NOT a pure move. Key design: **runtime-aware override output** (Codex needs `permissionDecision:"allow"`+`updatedInput`; Claude keeps `updatedInput`-only to not bypass its permission prompt) via `memory_runtime()`; root via `memory_project_dir()`; non-commit Bash now silent (no `skip-not-commit` row, would flood under Codex `^Bash$`); audit → `.agent0/secrets-audit.jsonl` + `runtime` field (hard cutover).
- **Validated:** all 10 secrets-scan scenarios green (7 existing + 3 new: 08 runtime-shape, 09 silent-noncommit, 10 subdir-cwd); hook-chain latency baseline green; full harness-sync suite green; grep clean of stale refs; both hooks `bash -n` OK.

## Active Work

_None active._

## Next Actions

1. **108 remaining: live Codex dogfood (the ONE unverified acceptance scenario, V8).** Enable the `secrets-preflight` `[[hooks.PreToolUse]]` block in local `.codex/config.toml` (template is in `.codex/config.toml.example`), restart Codex, then prove (a) a dangerous commit shape blocks exit-2 and (b) an overridden commit's rewrite actually reached Bash with `CLAUDE_SECRETS_OVERRIDE_REASON` set. Then flip spec 108 status → shipped and push/merge the branch. **Also restart THIS Claude session** so settings.json picks up the new `.agent0/hooks/secrets-preflight.sh` path (the old active hook path is stale post-`git mv`).
2. **NEXT PORT — `supply-chain-scan.sh` → `.agent0/` (spec 109).** 108 is its template: it copies the same primitives (override grammar, `skip-not-*` discipline, matcher breadth). Apply the same decisions — runtime-aware output IF it rewrites (check; it has no env-var bridge today, so likely no `permissionDecision` need), `.agent0/supply-chain-audit.jsonl` + `runtime` field, silent non-match under broad matcher, root via `_memory-hook-lib.sh`, file rename if "scan" is inaccurate. Per-port checklist as 107/108.
3. After that: `post-edit-validate.sh` (delegation-family), PostToolUse edit-surface advisories (`apply_patch` path extraction), runtime-capture/pre-mark, `rule-load-debug.sh` (Claude-only InstructionsLoaded, stays).

## Decisions & Gotchas

- **`permissionDecision:"allow"` is required WITH `updatedInput` on Codex** (verified vs official Codex hooks docs 2026-05-28) — else the rewrite is silently ignored. On Claude, `"allow"` auto-approves + bypasses the permission prompt, so Claude keeps `updatedInput`-only. The hook branches via `memory_runtime()`. This is the load-bearing lesson for any future PreToolUse hook that rewrites a command.
- **`git mv` of an active hook leaves THIS session's hook registration pointing at the moved-away path** until settings.json reload (next session). Commits still worked (missing-file PreToolUse hook exits non-2, doesn't block), but restart before relying on the new path. Same stale-active-hook trap will hit the 109 supply-chain port.
- **The hook-move cascade is real (107/108 lesson):** renaming a hook breaks anything hardcoding the old path/name. 108 also hit the **filename-keyed perf harness** (`bench-hooks.sh` HOOK_NAMES + `.perf-baseline.json` key + latency test) — easy to miss. ALWAYS `grep -rn '<oldname>'` after a move.
- **Gates block your own tooling:** feed `--no-verify` / `rm -r -f` content via a file (`git commit -F`, `.sh` fixtures), never inline Bash. `091-sdd-debate-runner` is pre-existing untracked, out of scope (NOT in the 108 commit).
