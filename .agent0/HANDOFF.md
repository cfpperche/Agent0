# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Prompt-time context injection paused.** Agent0 commits `7086bd3` and `2b9f0ce` removed `UserPromptSubmit` hook registration from `.codex/hooks.json` and `.claude/settings.json`; `SessionStart` still points at `startup-brief.sh`.
- **Fresh-session evidence:** after a Codex restart, only the startup brief appeared. Agent0 validation passed with JSON parse checks and hook grep showing only `startup-brief.sh`.
- **Consumers resynced:** `/home/goat/mei-saas` `28a5a0e`, `/home/goat/acmeyard` `de84307`, and `/home/goat/cognixse` `396e1e0` (`chore(harness): sync prompt hook pause`). Each passed JSON parse checks, hook grep, and `bash .agent0/tests/context-injection/run-all.sh`.
- **Spec 172 shipped locally:** `sync-harness.sh` now records Agent0-owned `.claude/settings.json` hook identities in baseline `settings_hooks` (`tool_version: 2`) and prunes removed/renamed Agent0-owned hook entries only when the previous baseline proves ownership. Consumer-only hooks and legacy baselines are preserved.
- **Spec 171 owns the redesign:** `docs/specs/171-context-injection-reformulation/` reframes context injection beyond keyword-only prompt hooks, with explicit `(runtime, tool)` coverage labels. Spec 170 artifacts were removed before commit and are intentionally superseded.
- Claude critique informed spec 171 once; later convergence attempts timed out. Treat current cross-model convergence as unavailable, not confirmed.

## Active Work

- Active spec: `docs/specs/171-context-injection-reformulation/` is draft/planning only; implementation has not started.
- Spec 172 is shipped locally and needs commit/push plus later consumer resync.
- Pre-existing/unrelated dirty state is still present and was left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`.
- `/home/goat/cognixse` also still has unrelated product dirty state left untouched: `apps/web/app/[locale]/(app)/layout.tsx`, `apps/web/components/app/app-nav.tsx`, `apps/web/e2e/email-outbox-health-signal.spec.ts`, and `docs/specs/030-email-outbox-health-signal/`.

## Next Actions

- For spec 171, implement the smallest v1 only after review: extend `context-inject.sh` with URL/article/gated-host prompt routing, then add hookable Bash/MCP post-tool auth-wall routing with explicit uncovered/rule-only labels.
- After committing spec 172 in Agent0, resync consumers so their next baselines seed `settings_hooks` v2.
- When ready: `git push` Agent0 and the three consumers with local commits.

## Decisions & Gotchas

- `UserPromptSubmit` was the recurring prompt-time context injector in the runtime configs. Post-restart evidence now confirms the prompt-time context-injection block stopped in the fresh Codex session.
- `SessionStart` intentionally remains because it is the continuity/startup brief path, not the keyword-based prompt hydrator.
- Spec 170's qualification artifacts were intentionally removed before commit; do not look for `.agent0/context/rules/context-injection-qualification.md` or `.agent0/tests/context-qualification/` in the current intended state.
- For spec 171, do not claim the X/article silent-substitution class is closed from a curl-only fixture. Label coverage by `(runtime, tool)` and keep non-hookable web-fetch paths as `rule-only` until live evidence proves otherwise.
- `settings_hooks` v2 cannot classify pre-existing stale `.claude/settings.json` hooks without prior metadata; this is intentional fail-open behavior. The three known consumers were manually mitigated before this fix.
