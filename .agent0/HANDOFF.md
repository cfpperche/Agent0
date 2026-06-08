# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Prompt-time context injection remains paused.** `UserPromptSubmit` hook registration is still absent from `.codex/hooks.json` and `.claude/settings.json`; `SessionStart` still points at `startup-brief.sh`.
- **Specs 173/174/175 shipped locally:** project-core source/example, bootstrap advisories, and local renderer are implemented. `.agent0/tools/project-core-sync.sh` renders `AGENT0:PROJECT`; edit hooks and `sync-harness.sh` delegate to it.
- **Spec 176 shipped locally:** `.agent0/project-core.md.example` carries marker `2026-06-08-1`; configured consumers preserve `.agent0/project-core.md` and see template-review advisory until their source marker matches.
- **Bootstrap cleanup contract:** source missing warns; source present silences bootstrap. Template-review is separate and clears only when source/example markers match.
- **`mei-saas` synced/configured:** project-core is pt-BR for product artifacts under `docs/`; entrypoints are hydrated from its source.
- **Browser verifier promotion in progress:** CognixSE had generic `agent-browser.sh verify-contract` hardening; ported to Agent0, visual-contract and agent-browser suites pass.
- **Validation passed:** project-core, bootstrap/template-review, status/doctor, harness-sync, instruction-drift, visual-contract, agent-browser, and `git diff --check`.

## Active Work

- Codex CLI — CognixSE sync is in progress. Spec 176 is committed; `agent-browser.sh` hardening is validated and awaiting commit, then CognixSE should re-sync without the previous customized refusal.
- Pre-existing/unrelated dirty state is still present and left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`.

## Next Actions

- Commit the Agent0 `agent-browser.sh` promotion only; do not include unrelated meeting state.
- Re-sync `cognixse`. Expected: preserve `.agent0/project-core.md`, keep `.agent0/project-core.md.example` marker `2026-06-08-1`, no `agent-browser.sh` refusal, and emit only template-review advisory until review.
- For other consumers, sync one by one and configure/review `.agent0/project-core.md` with the correct project-specific language/core guidance.

## Decisions & Gotchas

- Project-core language/locale is static always-on framing in `.agent0/project-core.md`; do not re-enable `UserPromptSubmit` for this.
- `sync-harness.sh` strips Agent0's own `AGENT0:PROJECT` region from entrypoint copies so Agent0 language settings do not leak into consumers without source.
- `project-core-sync.sh` is local derived-output maintenance; no `--agent0-path` just to refresh mirrors after a consumer source edit.
- Project-core bootstrap and template-review advisories are temporary cleanup signals, not permanent nags.
- Do not force-overwrite CognixSE `.agent0/tools/agent-browser.sh`; its diff was generic robustness and should converge by upstreaming through Agent0.
- `AGENTS.override.md` and nested `AGENTS.md` still win for Codex-local customization after the mirrored root project core.
- Real consumer `.agent0/project-core.md` is never written by sync. Only `.agent0/project-core.md.example` ships as the placeholder.
