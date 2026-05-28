# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration — porting `.claude/hooks/*` to `.agent0/` hook-by-hook.** 106 delegation + 107 governance + **108 secrets-preflight all SHIPPED + merged to `main`** (live-dogfooded both runtimes). 108 merged fast-forward (`8ccaf20 → 7d0ff53`) and its `feat/108-…` branch was deleted (local + remote). Working tree clean except the pre-existing untracked `docs/specs/091-sdd-debate-runner/`.

- **108 done** — `git mv .claude/hooks/secrets-scan.sh → .agent0/hooks/secrets-preflight.sh`; runtime-aware override output via `memory_runtime()`; root via `memory_project_dir()`; silent non-commit; audit → `.agent0/secrets-audit.jsonl` + `runtime` field. **V8 live dogfood PASS on both runtimes (2026-05-28).** Headline finding: the Claude registration's `if: "Bash(git commit *|…)"` filter used **pipe-alternation, which CC does not support** (`|` is a shell separator) → the preflight was DORMANT (zero `claude-code` rows ever); harness tests + direct invocation passed while it was dead because neither exercises CC's real `if` evaluation. Fixed → bare `"matcher": "Bash"`; re-verified live (block + override end-to-end). Rule/spec/notes/memory all reconciled.

## Active Work

_None active._

## Next Actions

1. **NEXT PORT — `supply-chain-scan.sh` → `.agent0/` (spec 109).** 108 is its template (override grammar, `skip-not-*` discipline, matcher breadth). **⚠️ Its current registration has the SAME dormant `if`-pipe bug** (`if: "Bash(npm *|pnpm *|...)"`, settings.json ~line 80) — pipe-alternation never matches, so the supply-chain hook is firing on NOTHING today; the 109 port MUST drop the `if` for a bare `"matcher": "Bash"` + in-script keyword probe (mirror the 108 fix). Apply same decisions: runtime-aware output IF it rewrites (it has no env-var bridge today, likely no `permissionDecision` need), `.agent0/supply-chain-audit.jsonl` + `runtime` field, silent non-match under broad matcher, root via `_memory-hook-lib.sh`, file rename if "scan" is inaccurate. Per-port checklist as 107/108.
2. After that: `post-edit-validate.sh` (delegation-family), PostToolUse edit-surface advisories (`apply_patch` path extraction), runtime-capture/pre-mark, `rule-load-debug.sh` (Claude-only InstructionsLoaded, stays).

## Decisions & Gotchas

- **CC `"if"` filters do NOT support pipe-alternation inside one `Bash(...)`** (confirmed vs official permissions docs 2026-05-28). `Bash(git commit *|git commit|...)` never matches — `|` is a shell command separator in permission-rule syntax, and multi-pattern rules must be separate array elements, not `Bash(a|b|c)`. A hook registered with such an `if` silently never fires (no error). Use a bare `"matcher": "Bash"` + in-script command filtering instead (the 108 script already self-filters: silent on non-commit). **The supply-chain registration (`Bash(npm *|pnpm *|...)`, settings.json ~line 80) has this SAME latent bug — fix it during the 109 port.**
- **`permissionDecision:"allow"` is required WITH `updatedInput` on Codex** (verified vs official Codex hooks docs 2026-05-28) — else the rewrite is silently ignored. On Claude, `"allow"` auto-approves + bypasses the permission prompt, so Claude keeps `updatedInput`-only. The hook branches via `memory_runtime()`. This is the load-bearing lesson for any future PreToolUse hook that rewrites a command.
- **`/resume` and `/clear` do NOT reload settings.json hook registrations** — only a COLD `claude` restart does. After `git mv`-ing a hook mid-session it won't dispatch until a full restart. Relevant when verifying the 109 port live.
- **Verifying a hook live needs a real PreToolUse fire, not just tests.** 108's dormant `if`-pipe shipped through 11/11 harness tests + direct invocation because none of those exercise CC's `if`-filter. Always do a live scratch-repo dogfood through the Bash tool before marking a hook-registration spec shipped. (108 audit evidence is in `docs/specs/108-*/notes.md`.)
- **Hook-move cascade:** renaming a hook breaks hardcoded paths AND the filename-keyed perf harness (`bench-hooks.sh`, `.perf-baseline.json`, latency test). ALWAYS `grep -rn '<oldname>'` after a move.
- **Gates block your own tooling:** feed `--no-verify` / `rm -r` content via a file or split calls, never a multi-line inline Bash (governance scans the whole string). `git commit` via `git commit -F`. `091-sdd-debate-runner` is pre-existing untracked, out of scope.
