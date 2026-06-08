# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Session 2026-06-08 (latest) — UserPromptSubmit context injection removed from runtime hook configs.** Removed the `UserPromptSubmit` hook blocks from `.codex/hooks.json` and `.claude/settings.json`, so `.agent0/hooks/context-inject.sh` is no longer registered as the recurring prompt-time context injector in either runtime config. `SessionStart` remains registered in both configs and still points at `startup-brief.sh` for startup/resume continuity.
- **Post-restart confirmation:** the human restarted the Codex session to force hook reload. The fresh session displayed only the startup brief from `SessionStart`; no prompt-time context-injection block appeared. Re-checked configs with `jq empty .codex/hooks.json && jq empty .claude/settings.json` and `rg 'UserPromptSubmit|context-inject.sh|startup-brief.sh' .codex/hooks.json .claude/settings.json`; only `startup-brief.sh` remains in those runtime hook configs.
- **Session 2026-06-08 (latest) — spec 171 context-injection reformulation drafted.** Opened `docs/specs/171-context-injection-reformulation/` to reframe context injection beyond prompt-only keywording. Web/docs research confirmed Codex hook limits (`PostToolUse` does not universally intercept WebSearch/non-shell/non-MCP), and Claude critique succeeded through `claude-exec` run `20260608T150344Z-context-injection-reformulation-claude`. Spec 171 now requires `(runtime, tool)` coverage labels and a v1 cut of prompt-time URL/article/gated-host routing plus hookable post-tool auth-wall routing.
- **Spec 170 context-injection qualification abandoned before commit.** Its rule/test/spec artifacts were removed because they qualified the old prompt-hook model. The decision is recorded in `docs/specs/171-context-injection-reformulation/notes.md`; spec 171 now owns the replacement design.
- Latest hook-config cut validated with `jq empty .codex/hooks.json && jq empty .claude/settings.json` and `rg 'UserPromptSubmit|context-inject.sh|startup-brief.sh' .codex/hooks.json .claude/settings.json` (only `startup-brief.sh` remains).
- Claude convergence review was attempted twice through `claude-exec`; both attempts timed out without usable output. Treat as unavailable, not as cross-model convergence.
- Prior local commits from the session arc remain unpushed unless the human has pushed externally: Agent0 compaction (`d2d1aec`) and spec 169 (`fda6594`), plus the three consumer bring-current commits noted in older handoff state.

## Active Work

- Active spec: `docs/specs/171-context-injection-reformulation/` is draft/planning only; implementation has not started.
- Pre-existing/unrelated dirty state is still present and was left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`.

## Next Actions

- Decide whether to treat the `UserPromptSubmit` removal as a simple immediate mitigation commit, or fold it into the broader spec 171 context-injection reformulation work.
- For spec 171, implement the smallest v1 only after review: extend `context-inject.sh` with URL/article/gated-host prompt routing, then add hookable Bash/MCP post-tool auth-wall routing with explicit uncovered/rule-only labels.
- When ready to publish the broader session arc: `git push` on Agent0 and the three consumers with local commits.

## Decisions & Gotchas

- `UserPromptSubmit` was the recurring prompt-time context injector in the runtime configs. Post-restart evidence now confirms the prompt-time context-injection block stopped in the fresh Codex session.
- `SessionStart` intentionally remains because it is the continuity/startup brief path, not the keyword-based prompt hydrator.
- The suite intentionally avoids telemetry/frequency scoring. Agent0 is stack-neutral; repo-local frequency is not a reliable importance signal for consumers.
- Spec 170's qualification artifacts were intentionally removed before commit; do not look for `.agent0/context/rules/context-injection-qualification.md` or `.agent0/tests/context-qualification/` in the current intended state.
- For spec 171, do not claim the X/article silent-substitution class is closed from a curl-only fixture. Label coverage by `(runtime, tool)` and keep non-hookable web-fetch paths as `rule-only` until live evidence proves otherwise.
