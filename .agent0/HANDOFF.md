# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Spec 101 (`session-handoff-multi-runtime`) is implemented, code-reviewed, and marked shipped. Review verdict: implementation correct, all contracts hold. The three session lifecycle scripts live under `.agent0/hooks/`: `session-start.sh`, `session-stop.sh`, `session-track-edits.sh`.

Review found one actionable item (F1) — now fixed: task 9's done-when ("no shipped file references `.claude/SESSION.md`") was not actually met. Cleaned 5 dangling refs across 3 shipped files: `.claude/skills/remind/SKILL.md` (:3, :18, :142 — :142 was the only semantic one, now points in-flight work to `.agent0/HANDOFF.md`), `.claude/skills/skill/references/portability-tiers.md:12`, `.claude/skills/product/templates/pipeline/02-prototype/prompt.md:107`. Grep confirms zero shipped-surface refs remain (negative-assertion tests in `tests/session-handoff/` excluded by design).

Claude registrations in `.claude/settings.json` point at the new shared scripts. Codex has commented opt-in blocks in `.codex/config.toml.example` for `SessionStart`, `Stop`, and `PostToolUse` on `^apply_patch$`. Old `.claude/hooks/session-*.sh` + pointer-only `.claude/SESSION.md` removed; shared state stays at `.claude/.session-state/<session_id>/`.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked, out of scope. `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._

## Next Actions

1. Commit spec 101 implementation + the F1 doc cleanup (bundle or split as preferred). F1 edits are doc-only and propagate to forks via sync-harness.
2. Continue the runtime-capabilities re-audit later with `runtime introspect` and `delegation/subagents`.

## Decisions & Gotchas

- Codex `Stop` uses continue-with-corrective-prompt semantics: `{"decision":"block","reason":...}` continues the turn once; `stop_hook_active=true` exits silently to avoid loops.
- Codex SessionStart emits plain framed stdout; Claude keeps JSON dual-channel (`hookSpecificOutput.additionalContext` + `systemMessage`). The branch keys off `CLAUDE_PROJECT_DIR` being unset = "assume Codex" (heuristic, correct in practice since the harness always sets it for Claude).
- `apply_patch` attribution parses patch headers via `_memory-hook-lib.sh::memory_extract_paths`; Bash/MCP writes fall back to porcelain comparison.
- Residual risk (review): if Codex `session_id` carries chars outside `^[a-zA-Z0-9_-]+$`, all such sessions collapse to the shared `unknown/` state dir → cross-session nag interference. Couldn't verify Codex's charset without live tool — worth a live smoke (pairs with reminder `r-2026-05-18`).
- Validation: all spec 101 fixtures (6/6) + session-handoff (10/10) + edit-attribution (8/8) re-run green this session; full activated `.codex/config.toml.example` parses with correct matchers (SessionStart×4, Stop no-matcher, PostToolUse/PreToolUse `^apply_patch$`).
