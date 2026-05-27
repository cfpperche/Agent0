# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 099 (`memory-multi-runtime`) shipped end-to-end and pushed.** Implementation, post-review fixes, live Codex smoke validation, consumer migrations, and a surfaced test-bug fix all landed and pushed:

- Agent0 → `59fa0e6..43d8539` (5 commits): statusline extract, handoff, spec 099 impl (`d4d171b`), Codex smoke note (`fe8ac33`), test 01 generic-assert fix (`43d8539`).
- mei-saas → `fd52239..ef768c3` (2 commits): statusline + spec 099 migration (1 entry moved, 8→4 settings, shims rm).
- codexeng → `6d44929..5824ebe` (1 commit): spec 099 migration (3 entries moved, manual SKILL.md merge to preserve `codexeng fork hardening` bullet).

All three repos at **0 commits ahead** of `origin/main`. Working trees clean except pre-existing untracked items.

Memory infra empirically validated in a live fresh Codex session: journal recorded `actor:"Codex CLI"` + `runtime:"codex-cli"` + `tool_use_id:"call_*"` (sinal 1); PreToolUse gate blocked a raw `apply_patch` against `MEMORY.md` with exit 2 + corrective template (sinal 2). Both gaps `notes.md` had registered as not-validated are now closed.

**Shim-removal follow-up consumed (2026-05-27, same-day skip of the 30-60d window).** The 4 `.claude/hooks/memory-*.sh` compat shims are deleted from the working tree (`D` in `git status`); settings.json had already pointed exclusively at `.agent0/hooks/`. Only remaining references are in frozen spec history (`docs/specs/083|099/`). Pending commit: `chore(memory): remove memory hook compat shims (spec 099 follow-up)`.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked in Agent0; `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._

## Next Actions

1. **mei-saas test 01 staleness.** mei-saas's `.claude/tests/project-memory/01-files-are-git-tracked.sh` is still the pre-fix version (its sync happened before `43d8539`). Cosmetic — picks up on the next regular `sync-harness --apply`.
2. Spec 091 stays paused unless explicitly resumed.

## Decisions & Gotchas

- **Spec 099 shipped Option A (compat shims).** Validated empirically: both consumers migrated with zero downtime, ~3 min each (sync → reconcile → mv → settings cleanup → shim rm → verify → commit).
- **codexeng carries 1 load-bearing customization** in `.claude/skills/image/SKILL.md § Notes`: the `codexeng fork hardening` bullet promoting upstream "should compose" to "must" for brand-tier prompts. Re-apply on every sync via the consumer-extension convention (take upstream verbatim, re-add the bullet at end of § Notes).
- **Tests that ship to consumers must use generic property assertions, not hardcoded entry names.** `01-files-are-git-tracked.sh` originally asserted specific Agent0-only entries (`agent0-purpose.md` + `visibility-intent.md`); fix in `43d8539` switched to "≥1 entry .md (excluding MEMORY.md) git-tracked". Pattern worth re-auditing across other shipped tests.
- **Codex `apply_patch` empirical contract confirmed.** `tool_input.command` is the primary payload field (parser fallbacks never triggered); `tool_use_id` shape is `call_*` (vs Claude's `toolu_*`); patch-header parsing (`*** Add File:` / `*** Update File:`) works against real payloads.
- **Frontmatter validation is single-owner.** `memory-frontmatter-validate.sh` emits the advisory; `memory-events-journal.sh` is journal+project only. Re-introducing validate calls from other hooks would re-create the spec-099-review double-fire bug.
- **Re-audit pending in `runtime-capabilities.md`.** Codex lifecycle-hooks promotion implies adjacent rows (`delegation/subagents`, `runtime introspect`, `session handoff`) may also need promotion. Track via next competitive-harness audit cycle.
