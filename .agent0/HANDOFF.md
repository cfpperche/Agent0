# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration in progress — porting `.claude/hooks/*` to `.agent0/` (dual-runtime) hook-by-hook.** Two shipped this session, both committed + pushed (in sync with `origin/main`), both live-dogfooded on Claude AND Codex:

- **Spec 106 `delegation-hooks-multi-runtime`** (`e8908cf`) — delegation discipline split into two layers: Claude `delegation-gate.sh` blocks (stays `.claude/`); Codex convention-only (no hook can block a spawn). Observability via `.agent0/hooks/delegation-start-audit.sh` + shared `.agent0/hooks/delegation-stop.sh` → one canonical `.agent0/delegation-audit.jsonl` (hard cutover; old `.claude/` log removed).
- **Spec 107 `governance-gate-refinement`** (`1632bea` + `6666e5a`) — refined `governance-gate.sh` (rm separate-flag fix, git clean, whole-tree checkout/restore, fast-path drift-guard) + moved it to `.agent0/hooks/`. The clean Bash-surface port (zero runtime asymmetry).

Walkthrough order: 1-2 delegation (106 ✓), 3 governance (107 ✓).

## Active Work

_None active._

## Next Actions

1. **NEXT HOOK BATCH — port `secrets-scan.sh` + `supply-chain-scan.sh` to `.agent0/`.** Both are `PreToolUse(Bash)` gates with the SAME clean shape as governance (107): read `tool_input.command`, exit-2 blocks identically on both runtimes, no spawn-asymmetry. Likely one combined spec. Path is paved — `bench-hooks.sh` already resolves `.agent0/hooks/` then `.claude/hooks/`, so the move needs no bench change. Per-port checklist (from 107): `git mv` → repoint `settings.json` (they use `if Bash(...)` matchers) → add commented `[[hooks.PreToolUse]]` blocks to `.codex/config.toml.example` → grep for + fix stale `.claude/hooks/<name>.sh` refs across tests/rules (the cascade governance hit) → update test path refs → dogfood both runtimes. Decide debate-or-not: governance got one for *refinement*; these may be straight ports if no refinement surfaces — ask the user.
2. After the Bash-gate batch: `post-edit-validate.sh` (delegation-coupled loop-budget → delegation-family unit, not this batch); PostToolUse edit-surface advisories (need `apply_patch` path extraction); runtime-capture/pre-mark (Bash-surface, portable); `rule-load-debug.sh` (InstructionsLoaded — Claude-only event, stays).

## Decisions & Gotchas

- **The hook-move cascade is real (107 lesson):** moving a hook out of `.claude/hooks/` breaks anything that hardcodes the old path. `bench-hooks.sh` (latency harness) and `.claude/tests/hook-chain-latency/03-regression-fires.sh` both did; fixed via dual-dir resolution. ALWAYS `grep -rn '.claude/hooks/<name>.sh'` after a move and repoint live refs (doc refs in rules too). 091-sdd-debate-runner is pre-existing untracked, out of scope.
- **The gates block your own tooling (dogfood irony, 2× this session):** secrets-scan blocked a test command containing `--no-verify`; governance blocked a `git commit` whose message body contained `rm -r -f`. Fix: feed such content via a file (Write tool → `git commit -F file`, test commands in `.sh` fixtures), not inline Bash. Expect the same when porting secrets-scan/supply-chain.
- **Codex config gotcha:** `.codex/config.toml` is gitignored + session-loaded. A new hook block must be added there + Codex restarted BEFORE the dogfood, or the hook never fires. The `.example` carries the commented template; the local `.codex/config.toml` is the live copy.
- **Codex subagent facts (verified 2026-05-28, `.agent0/memory/codex-cli-hooks.md`):** SubagentStart carries no brief → can't validate the 5-field contract → Codex delegation discipline is convention-only; no hook can block a spawn. Bash-surface gates have NO such asymmetry (exit-2 blocks on both).
- **Dispatch audit rows now carry `event:"dispatch"`** (106) — any audit query must use explicit `.event` values, never absence.
