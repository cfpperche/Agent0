# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Umbrella 102 (`harness-consolidate-agent0`) is CLOSED — `Status: shipped`, all 5 acceptance boxes checked (2026-05-28).** The harness is consolidated into `.agent0/` as the runtime-neutral home; `.claude/`+`.codex/` keep only runtime-exclusive files. Move rows shipped: reminders+routines (103, `1a537e9`), state dirs (104, `1273ed4`), shared shell tools (105, `c4a10a1`). AC4+AC5 + box closure committed in `25c2a0f` / this session's close commit.

Deferred rows remain open **by recorded decision, not as 102 loose ends**: rows 7-9 (rules/skills/validators) + row 14 (brainstorm-state) — all gated on the "Codex actually consumes rules/skills" trigger; revisit decides shared-`.agent0/` vs per-runtime then.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked, out of scope. `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._

## Next Actions

1. **Push** — `main` is ahead of `origin/main` by 5 commits (102 line + closure). Founder hadn't pushed as of session close; not yet authorized.
2. Broader refactoring questions the founder flagged post-105 (the "lacuna is not just tests" thread — `.claude/tests/` and `.claude/validators/` placement, the consumer-side `harness-sync-baseline.json` location). These are NOT 102 rows; they're a fresh decision the founder reserved. Don't pre-empt where-to-encode.
3. Continue the runtime-capabilities re-audit later (`runtime introspect` + `delegation/subagents` rows).

## Decisions & Gotchas

- 105 archaeology (live-vs-frozen rewrite rule, sync-harness fixture `.claude/` dependency, self-rebootstrap self-overwrite) is captured in commit `c4a10a1`, spec 105, and `harness-sync.md` § Gotchas — not duplicated here.
- AC4 placement decision: the § Classification principle went to **project memory** (`.agent0/memory/harness-home.md`), not a shipped rule — it's maintainer-binding, consume-only forks never read it. The spec's original "a rule under `.claude/rules/`" framing was superseded by the `memory-placement.md` rule-vs-memory routing.
- Codex `Stop` uses continue-with-corrective-prompt: `{"decision":"block","reason":...}` continues once; `stop_hook_active=true` exits silently. SessionStart branches on `CLAUDE_PROJECT_DIR` unset = "assume Codex".
- Residual review risk: a Codex `session_id` with chars outside `^[a-zA-Z0-9_-]+$` collapses all such sessions to the shared `unknown/` state dir — worth a live smoke (reminder `r-2026-05-18`).
