# Spec 099 Consumer Migration Playbook

Use this after Agent0 upstream lands spec 099 and a consumer project has pulled the refreshed harness files through `sync-harness.sh`.

## Preconditions

- Consumer has received the new `.agent0/hooks/memory-*.sh`, `.agent0/tools/memory-*`, `.agent0/memory/.gitkeep`, `.agent0/memory.config.json`, and updated entrypoint/rule docs.
- Existing `.claude/hooks/memory-*.sh` shims still delegate to `.agent0/hooks/memory-*.sh`, so migration can happen later without breaking current hooks.
- Activate native git hooks before verifying drift checks: `git config core.hooksPath .githooks`.

## Ordered Steps

1. Pull the harness update and confirm the old setup still works: `bash .claude/hooks/memory-decay-readout.sh` should delegate without error.
2. Create the new bucket if sync did not already do it: `mkdir -p .agent0/memory`.
3. Move consumer memory content: `git mv .claude/memory/*.md .agent0/memory/` and `git mv .claude/memory/.gitkeep .agent0/memory/.gitkeep` when present.
4. Move consumer memory config if customized: `git mv .claude/memory.config.json .agent0/memory.config.json`.
5. Reconcile `.claude/tools/memory-*` removal. The spec 099 rename triggers `sync-harness`'s upstream-removed propagation: clean copies are auto-deleted; consumer-customized copies are refused as `!! customized <path> (upstream-removed)`. For each refusal, port the local diff onto the matching `.agent0/tools/memory-*`, then `git rm` the stale `.claude/tools/memory-*` file. Same for `.claude/memory.config.json` if the consumer customized it.
6. Update `.claude/settings.json` memory hook commands from `.claude/hooks/memory-*.sh` to `.agent0/hooks/memory-*.sh`.
7. Remove `.claude/hooks/memory-*.sh` shims only after step 6 is committed and verified.
8. Regenerate the index: `bash .agent0/tools/memory-maintain.sh finalize`.
9. Verify projection and sync health: `bash .agent0/tools/memory-project.sh`, `bash .agent0/tools/memory-query.sh decay --readout`, and the consumer's relevant `.claude/tests/harness-sync/*` checks.
10. Stage the moved memory files, config, settings, and removed shims; commit the migration.

## Rollback

Revert the migration commit. If rollback happens before commit, move files back with `git mv .agent0/memory/*.md .claude/memory/`, restore `.claude/settings.json`, and rerun `bash .claude/hooks/memory-decay-readout.sh`.

## Known Consumers

`mei-saas`: no migration is performed by Agent0 spec 099 itself. Before applying, audit local customization with:

```bash
git log --all --diff-filter=M -- .claude/hooks/memory-* .claude/tools/memory-* .claude/memory.config.json | head -30
```

`codexeng`: same migration path and customization audit as `mei-saas`.

If either project shows local modifications to old memory hooks or tools, preserve the local diff manually before removing shims.
