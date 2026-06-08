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
- **Browser verifier promotion shipped locally:** CognixSE had generic `agent-browser.sh verify-contract` hardening; it was ported to Agent0 and validated with visual-contract + agent-browser suites.
- **Consumers synced this section:** `cognixse` is synced with template-review advisory pending by design; `acmeyard` is synced and bootstrapped with marker `2026-06-08-1`; `mei-saas` was synced/configured earlier.
- **Validation passed:** project-core, bootstrap/template-review, status/doctor, harness-sync, instruction-drift, visual-contract, agent-browser, and `git diff --check`.

## Active Work

- Codex CLI — current sync wave is complete for `mei-saas`, `cognixse`, and `acmeyard`; no active harness implementation work remains in this section.
- Pre-existing/unrelated dirty state is still present and left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`.

## Next Actions

- Push Agent0 and consumer commits when ready; no push has been performed.
- For other consumers, sync one by one and configure/review `.agent0/project-core.md` with the correct project-specific language/core guidance.

## Decisions & Gotchas

- Project-core language/locale is static always-on framing in `.agent0/project-core.md`; do not re-enable `UserPromptSubmit` for this.
- `sync-harness.sh` strips Agent0's own `AGENT0:PROJECT` region from entrypoint copies so Agent0 language settings do not leak into consumers without source.
- `project-core-sync.sh` is local derived-output maintenance; no `--agent0-path` just to refresh mirrors after a consumer source edit.
- Project-core bootstrap and template-review advisories are temporary cleanup signals, not permanent nags.
- CognixSE keeps a template-review advisory until its project-core source is reviewed and marker `2026-06-08-1` is copied. Acmeyard has already copied the marker and should have no project-core advisory.
- `AGENTS.override.md` and nested `AGENTS.md` still win for Codex-local customization after the mirrored root project core.
- Real consumer `.agent0/project-core.md` is never written by sync. Only `.agent0/project-core.md.example` ships as the placeholder.
