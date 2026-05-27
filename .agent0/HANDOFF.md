# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 099 (`memory-multi-runtime`) reviewed and post-review fixes applied.** Review by Claude Code surfaced one real design finding (double-fire of `memory-frontmatter-advisory:` — both `memory-events-journal.sh` and `memory-frontmatter-validate.sh` were calling `MAINTAIN validate` on the same edit) and one prose ambiguity in the migration playbook step 5. Both fixed in working tree, **NOT yet staged**.

**Fixes applied this session:**

1. `.agent0/hooks/memory-events-journal.sh` — removed the `MAINTAIN validate` block; ownership of frontmatter validation belongs solely to `memory-frontmatter-validate.sh`. Verified single-fire empirically: 0 advisories from events-journal + 1 from frontmatter-validate on a synthetic malformed entry.
2. `docs/specs/099-memory-multi-runtime/migration-playbook.md` step 5 — rewrote from ambiguous "remove or replace if local scripts call them" to concrete reconciliation flow against `sync-harness`'s upstream-removed propagation.

**Tests pass post-fix:** `.claude/tests/memory-multi-runtime/run-all.sh` 5/5 PASS; `.claude/tests/project-memory/run-all.sh` 5/5 PASS.

**Agent0 is 2 commits ahead of `origin/main`.** Staged index = original spec-099 implementation (88 files). Working tree adds the two fixes above. No commit was created this session.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked; `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None active._ Spec 099 ready to land — 2 unstaged fixes + the staged tree compose the final commit.

## Next Actions

1. `git add .agent0/hooks/memory-events-journal.sh docs/specs/099-memory-multi-runtime/migration-playbook.md` to fold the two review fixes into the spec-099 staged set.
2. Commit. Suggested message: `feat(memory): port project memory to multi-runtime hooks` (body should mention the double-fire fix + playbook step 5 polish).
3. Optional pre-push validation: live fresh-session Codex smoke (`.codex/config.toml.example` hook block uncommented + `apply_patch` against temp memory entry) to confirm `tool_input.command` payload shape against the tolerant parser. Synthetic tests already cover it.
4. Keep consumer migrations (`mei-saas`, `codexeng`) as downstream operator work per `docs/specs/099-memory-multi-runtime/migration-playbook.md`.
5. Shim-removal follow-up commit on Agent0 upstream after both known consumers migrate (track via reminder, not this session).
6. Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- **Frontmatter validation is single-owner.** `memory-frontmatter-validate.sh` owns the advisory; `memory-events-journal.sh` is journal+project only. Re-introducing validate calls from other hooks would re-create the double-fire.
- **Spec 099 transitional-state shape: Option A (compat shims).** Old `.claude/hooks/memory-*.sh` paths are 2-line `exec` shims. Existing consumers keep working post-sync; manual migration removes shims later.
- **Spec 099 namespace lock: `.agent0/memory/`.** User-ratified Scenario B; OQ-1 became plan-phase enumeration only.
- **Codex payload parser is tolerant, live probe was not run.** Primary `tool_input.command`, fallbacks `input` / `patch` / `content` / string `tool_input`; synthetic tests cover real patch headers.
- **Project-memory git-tracked tests require staged rename state.** The spec-099 paths are staged intentionally so `git ls-files .agent0/memory/` sees the moved corpus.
- **Re-audit pending in `runtime-capabilities.md`.** Codex lifecycle-hooks promotion implies adjacent rows (`delegation/subagents`, `runtime introspect`, `session handoff`) may also need promotion. Track via next competitive-harness audit cycle.
