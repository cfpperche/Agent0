# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Prompt-time context injection remains paused.** `UserPromptSubmit` hook registration is still absent from `.codex/hooks.json` and `.claude/settings.json`; `SessionStart` still points at `startup-brief.sh`.
- **Specs 173/174/175 shipped locally:** project-core source/example, bootstrap advisories, and local project-core renderer are implemented. `.agent0/tools/project-core-sync.sh` renders `AGENT0:PROJECT`; edit hooks run it after normal agent edits; `sync-harness.sh` delegates to it.
- **Bootstrap cleanup contract:** alerts appear only when `.agent0/project-core.md.example` exists and `.agent0/project-core.md` is missing. After the consumer creates `.agent0/project-core.md` and runs `.agent0/tools/project-core-sync.sh --apply`, those alerts must disappear; persistent warnings are false-positive context.
- **`mei-saas` synced and configured:** it has `.agent0/project-core.md` for pt-BR product artifacts under `docs/`, local renderer/hooks installed, and `CLAUDE.md`/`AGENTS.md` hydrated from its own source.
- **Validation passed:** project-core-sync, bootstrap advisory, Agent0 status, harness-sync 37/47, full harness-sync, instruction-drift suite/check, doctor, and `git diff --check` in Agent0 + `mei-saas`.

## Active Work

- Codex CLI — specs 173/174/175 are implemented and validated, awaiting review/commit. Key paths: project-core source/example, entrypoints, hook configs, local renderer/sync/status/doctor/drift tools, language/harness/status/runtime rules, project-core tests, and spec dirs 173/174/175.
- Pre-existing/unrelated dirty state is still present and left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`.

## Next Actions

- If accepting specs 173/174/175, commit the Agent0 change only; do not include unrelated meeting state.
- If accepting the `mei-saas` sync/configuration, commit that consumer change separately from Agent0.
- For other consumers, sync one by one and configure `.agent0/project-core.md` with the correct project-specific language/core guidance.
- Spec 171 remains the next context-injection redesign work: implement URL/article/gated-host prompt routing plus hookable Bash/MCP auth-wall routing with explicit uncovered/rule-only labels.

## Decisions & Gotchas

- Project-core language/locale is static always-on framing, not prompt-time hydration. Keep it in `.agent0/project-core.md`; do not re-enable `UserPromptSubmit` for this.
- `sync-harness.sh` strips Agent0's own `AGENT0:PROJECT` region from plain-tracked entrypoint copies so Agent0 language settings do not leak into consumers without their own source.
- `project-core-sync.sh` is local derived-output maintenance. Do not require `--agent0-path` or upstream sync just to refresh mirrors after a consumer `.agent0/project-core.md` edit.
- Project-core bootstrap advisory is a cleanup signal, not a permanent nag: example-present/source-missing warns; source-present silences.
- `AGENTS.override.md` and nested `AGENTS.md` still win for Codex-local customization after the mirrored root project core.
- Real consumer `.agent0/project-core.md` is never written by sync. Only `.agent0/project-core.md.example` ships as the placeholder.
