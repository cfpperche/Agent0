# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration — porting `.claude/hooks/*` to `.agent0/` hook-by-hook.** 106 delegation + 107 governance shipped (committed + pushed, live-dogfooded both runtimes). This session: **108 `secrets-scan-multi-runtime`** committed on branch `feat/108-secrets-preflight-multi-runtime` (`e036491`), NOT yet pushed/merged.

- **108** — `git mv .claude/hooks/secrets-scan.sh → .agent0/hooks/secrets-preflight.sh` (renamed: it scans no secrets, it gates commit shape + bridges the override). Ran a cross-model debate with Codex first (`docs/specs/108-*/debate.md`, converged) — surfaced real refinements, so NOT a pure move. Key design: **runtime-aware override output** (Codex needs `permissionDecision:"allow"`+`updatedInput`; Claude keeps `updatedInput`-only to not bypass its permission prompt) via `memory_runtime()`; root via `memory_project_dir()`; non-commit Bash now silent (no `skip-not-commit` row, would flood under Codex `^Bash$`); audit → `.agent0/secrets-audit.jsonl` + `runtime` field (hard cutover).
- **Validated:** 11/11 secrets-scan scenarios green (7 existing + 4 new: 08 runtime-shape, 09 silent-noncommit, 10 subdir-cwd, 11 codex-rewrite-reaches-Bash); latency baseline + harness-sync suites green; grep clean; hook proven by direct invocation (block exit 2). **NOT yet validated: live PreToolUse dispatch on either runtime (V8) — needs a cold restart, see Next Actions #1.**

## Active Work

_None active._

## Next Actions

1. **108 remaining: V8 live-dispatch dogfood on BOTH runtimes — the ONLY unverified acceptance scenario.** Code done + 11/11 harness tests + hook proven by direct invocation; only the live harness-dispatch is unproven. **⚠️ Claude needs a COLD restart first (`/resume`+`/clear` do NOT reload hooks — see Gotchas).** Then, in a scratch repo (`git init` + `core.hooksPath /home/goat/Agent0/.githooks` + copy `.gitleaks.toml`), via the Bash tool: (a) `git add foo.txt && git commit -m x` → expect BLOCK exit 2 (preflight row `reject-shape`/`compound-and`/`claude-code` lands in **`/home/goat/Agent0/.agent0/secrets-audit.jsonl`** — preflight uses `CLAUDE_PROJECT_DIR`, not the scratch cwd); (b) fixture with a non-stopword fake AKIA key + two-line `# OVERRIDE:` commit → lands, preflight `override-pass-through` + native `override`. Codex: uncomment its `[[hooks.PreToolUse]]` secrets block, restart Codex, same checks (override = the crux). Then status → shipped, check V8, push/merge.
2. **NEXT PORT — `supply-chain-scan.sh` → `.agent0/` (spec 109).** 108 is its template: it copies the same primitives (override grammar, `skip-not-*` discipline, matcher breadth). Apply the same decisions — runtime-aware output IF it rewrites (check; it has no env-var bridge today, so likely no `permissionDecision` need), `.agent0/supply-chain-audit.jsonl` + `runtime` field, silent non-match under broad matcher, root via `_memory-hook-lib.sh`, file rename if "scan" is inaccurate. Per-port checklist as 107/108.
3. After that: `post-edit-validate.sh` (delegation-family), PostToolUse edit-surface advisories (`apply_patch` path extraction), runtime-capture/pre-mark, `rule-load-debug.sh` (Claude-only InstructionsLoaded, stays).

## Decisions & Gotchas

- **`permissionDecision:"allow"` is required WITH `updatedInput` on Codex** (verified vs official Codex hooks docs 2026-05-28) — else the rewrite is silently ignored. On Claude, `"allow"` auto-approves + bypasses the permission prompt, so Claude keeps `updatedInput`-only. The hook branches via `memory_runtime()`. This is the load-bearing lesson for any future PreToolUse hook that rewrites a command.
- **`/resume` and `/clear` do NOT reload settings.json hook registrations** (2026-05-28 finding) — only a COLD `claude` restart does. After `git mv`-ing a hook mid-session, the moved hook won't dispatch until a full restart; `--resume`/`--continue` keep stale in-memory registrations. Same trap will hit the 109 supply-chain port.
- **The hook-move cascade is real (107/108 lesson):** renaming a hook breaks anything hardcoding the old path/name. 108 also hit the **filename-keyed perf harness** (`bench-hooks.sh` HOOK_NAMES + `.perf-baseline.json` key + latency test) — easy to miss. ALWAYS `grep -rn '<oldname>'` after a move.
- **Gates block your own tooling:** feed `--no-verify` / `rm -r -f` content via a file (`git commit -F`, `.sh` fixtures), never inline Bash. `091-sdd-debate-runner` is pre-existing untracked, out of scope (NOT in the 108 commit).
