# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Prompt-time context injection remains paused.** `UserPromptSubmit` hook registration is still absent from `.codex/hooks.json` and `.claude/settings.json`; `SessionStart` still points at `startup-brief.sh`.
- **Specs 173/174/175 shipped locally:** project-core source/example, bootstrap advisories, and local renderer are implemented. `.agent0/tools/project-core-sync.sh` renders `AGENT0:PROJECT`; edit hooks and `sync-harness.sh` delegate to it.
- **Spec 176 implemented locally:** `.agent0/project-core.md.example` carries template marker `2026-06-08-1`; configured consumers preserve `.agent0/project-core.md` and receive template-review advisory until they copy the marker after review.
- **Bootstrap cleanup contract:** alerts appear only when `.agent0/project-core.md.example` exists and `.agent0/project-core.md` is missing. After the consumer creates `.agent0/project-core.md` and runs `.agent0/tools/project-core-sync.sh --apply`, bootstrap alerts must disappear; template-review alerts are separate and clear only after the source marker matches the example.
- **`mei-saas` synced and configured:** it has `.agent0/project-core.md` for pt-BR product artifacts under `docs/`, local renderer/hooks installed, and `CLAUDE.md`/`AGENTS.md` hydrated from its own source.
- **Validation passed:** project-core-sync, bootstrap/template-review advisory, status/doctor, harness-sync 37/47/full suite, instruction-drift suite/check, and `git diff --check`.

## Active Work

- Codex CLI — spec 176 is implemented and validated, awaiting commit and CognixSE sync. Key paths: project-core source/example, `_brief-compose.sh`, `doctor.sh`, `sync-harness.sh`, language/harness/status rules, tests, and `docs/specs/176-project-core-template-review/`.
- Pre-existing/unrelated dirty state is still present and left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`.

## Next Actions

- Commit spec 176 in Agent0 only; do not include unrelated meeting state.
- Sync `cognixse` next. Expected: copy `.agent0/project-core.md.example`, preserve existing `.agent0/project-core.md`, hydrate entrypoints, and emit template-review advisory until CognixSE copies marker `2026-06-08-1` after review.
- For other consumers, sync one by one and configure/review `.agent0/project-core.md` with the correct project-specific language/core guidance.
- Spec 171 remains the next context-injection redesign work: implement URL/article/gated-host prompt routing plus hookable Bash/MCP auth-wall routing with explicit uncovered/rule-only labels.

## Decisions & Gotchas

- Project-core language/locale is static always-on framing, not prompt-time hydration. Keep it in `.agent0/project-core.md`; do not re-enable `UserPromptSubmit` for this.
- `sync-harness.sh` strips Agent0's own `AGENT0:PROJECT` region from plain-tracked entrypoint copies so Agent0 language settings do not leak into consumers without their own source.
- `project-core-sync.sh` is local derived-output maintenance. Do not require `--agent0-path` or upstream sync just to refresh mirrors after a consumer `.agent0/project-core.md` edit.
- Project-core bootstrap advisory is a cleanup signal, not a permanent nag: example-present/source-missing warns; source-present silences. Template-review advisory is also temporary: it exists only while the source marker differs from the example marker.
- `AGENTS.override.md` and nested `AGENTS.md` still win for Codex-local customization after the mirrored root project core.
- Real consumer `.agent0/project-core.md` is never written by sync. Only `.agent0/project-core.md.example` ships as the placeholder.
