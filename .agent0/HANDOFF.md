# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **Spec 177 (spec-verify-advisory) shipped + pushed.** Per-spec rerunnable proof, ported from the studied `repository-harness` project into Agent0's markdown+shell+advisory idiom (no SQLite/CLI). `.agent0/tools/spec-verify.sh` runs a spec's `**Verify:** \`<cmd>\`` lines, records `## Verification log` to notes.md; `.agent0/validators/run.sh` emits non-blocking `spec-verify-advisory:` for a SHIPPED spec declaring a verify command with no passing latest record (opt-in). Built in `/squad` mode with Codex (3 real defects fixed in its peer turn); closed `ready_for_human_prod`. Suite `.agent0/tests/spec-verify/` 8/8 green. Agent0 commit `e31ca6f` on `main`.
- **Consumers synced + pushed for the 177 wave:** `cognixse` (`4c061c1`), `acmeyard` (`7e1849b`), `mei-saas` (`938dac4`) — harness-only commits via `sync-harness`; spec-verify suite verified 8/8 in each. `mei-saas` also caught up on prior pending syncs in the same commit.
- **Prompt-time context injection remains paused.** `UserPromptSubmit` hook registration is still absent from `.codex/hooks.json` and `.claude/settings.json`; `SessionStart` still points at `startup-brief.sh`.
- **Specs 173/174/175 shipped locally:** project-core source/example, bootstrap advisories, and local renderer are implemented. `.agent0/tools/project-core-sync.sh` renders `AGENT0:PROJECT`; edit hooks and `sync-harness.sh` delegate to it.
- **Spec 176 shipped locally:** `.agent0/project-core.md.example` carries marker `2026-06-08-1`; configured consumers preserve `.agent0/project-core.md` and see template-review advisory until their source marker matches.
- **Bootstrap cleanup contract:** source missing warns; source present silences bootstrap. Template-review is separate and clears only when source/example markers match.
- **`mei-saas` synced/configured:** project-core is pt-BR for product artifacts under `docs/`; entrypoints are hydrated from its source.
- **Browser verifier promotion shipped locally:** CognixSE had generic `agent-browser.sh verify-contract` hardening; it was ported to Agent0 and validated with visual-contract + agent-browser suites.
- **Consumers synced this section:** `cognixse` is synced with template-review advisory pending by design; `acmeyard` is synced and bootstrapped with marker `2026-06-08-1`; `mei-saas` was synced/configured earlier.
- **Validation passed:** project-core, bootstrap/template-review, status/doctor, harness-sync, instruction-drift, visual-contract, agent-browser, and `git diff --check`.

## Active Work

- None in flight. Spec 177 is shipped, pushed, and propagated to all three consumers. No open implementation thread.
- Pre-existing/unrelated dirty state is still present and left untouched: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`. Specs 173/174/175/176 remain locally shipped but not yet committed on Agent0 (separate from the 177 commit, which staged explicit paths only).

## Next Actions

- If/when ready, commit the still-uncommitted 173–176 project-core/bootstrap work on Agent0 (it was deliberately excluded from the 177 commit) and sync that wave to consumers.
- Optionally adopt the `**Verify:**` convention in future specs (it is opt-in; declare a command in `tasks.md` to get re-verification + the advisory).
- For other consumers (`codexeng`, `tmux-sentinel`, `ag-antecipa`, `tese`), sync one by one when desired.

## Decisions & Gotchas

- **spec-verify adopted the `repository-harness` *pattern*, not its substrate.** The studied project stores `last_verified_result` in a gitignored SQLite `harness.db` driven by a Rust CLI; Agent0 deliberately rejected that (markdown+hooks center of gravity) and persists the proof as a `## Verification log` block in `notes.md`. Same rejection applies to its intake-lane / trace-ledger / backlog ideas — out of scope for 177. Both Claude and Codex independently ranked verify-command as the #1 fit and flagged the SQLite substrate as a mistake to import.
- **The 177 commit staged explicit paths only** (not `-A`) so the pending 173–176 work and the meeting dir stayed out. Do the same when committing the rest.
- Project-core language/locale is static always-on framing in `.agent0/project-core.md`; do not re-enable `UserPromptSubmit` for this.
- `sync-harness.sh` strips Agent0's own `AGENT0:PROJECT` region from entrypoint copies so Agent0 language settings do not leak into consumers without source.
- `project-core-sync.sh` is local derived-output maintenance; no `--agent0-path` just to refresh mirrors after a consumer source edit.
- Project-core bootstrap and template-review advisories are temporary cleanup signals, not permanent nags.
- CognixSE keeps a template-review advisory until its project-core source is reviewed and marker `2026-06-08-1` is copied. Acmeyard has already copied the marker and should have no project-core advisory.
- `AGENTS.override.md` and nested `AGENTS.md` still win for Codex-local customization after the mirrored root project core.
- Real consumer `.agent0/project-core.md` is never written by sync. Only `.agent0/project-core.md.example` ships as the placeholder.
