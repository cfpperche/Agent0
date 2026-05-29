# Tasks — 114 remove compaction-continuity

## Recon (confirm the exact reference set)
- [ ] 1. Grep the repo (case-insensitive) for `pre-compact|precompact|compact-history|compacthistory|compaction-continuity|compact_notes`, excluding `.git/`, `*.jsonl`, design-systems, product/templates. Record the file list.
- [ ] 2. Read the uncertain files (`runtime-capabilities.md`, `harness-home.md`, `.runtime-state/README.md`, `cc-platform-hooks.md`, `harness-sync-baseline.json`, `.codex/config.toml.example`) to classify each match as remove vs retain-as-platform-fact.

## Deregister + delete
- [ ] 3. `.claude/settings.json` — remove the `PreCompact` property; verify valid JSON.
- [ ] 4. Delete `.claude/hooks/pre-compact.sh` (`git rm`).
- [ ] 5. Delete `.claude/tests/compaction-continuity/` (`git rm -r` the tracked files; the dir goes with them).
- [ ] 6. Delete `.agent0/memory/compaction-continuity.md` (`git rm`), then run `bash .agent0/tools/memory-project.sh` to regenerate `MEMORY.md`.
- [ ] 7. Remove the runtime dir `.claude/.compact-history/` if it exists (gitignored, ephemeral).

## Edit the consumer + pointers
- [ ] 8. `.agent0/hooks/session-start.sh` — remove the compact header comment lines, the `COMPACT_HISTORY_DIR` assignment, and the `if [[ "$SOURCE" == "compact" ]] … fi` block. Keep `SOURCE` parsing and all other banners.
- [ ] 9. `.gitignore` — remove the `.claude/.compact-history/` line.
- [ ] 10. `CLAUDE.md` — § Compact Instructions: remove the snapshot-dependency sentence.
- [ ] 11. `.claude/rules/session-handoff.md` — § SessionStart fallback + § Reader-side defense: remove compact-history clauses.
- [ ] 12. `.claude/rules/artifact-budgets.md` — § Where this applies: remove the compact-history clause.
- [ ] 13. `.claude/harness-sync-baseline.json` — remove the `pre-compact.sh` entry; verify valid JSON.
- [ ] 14. Apply the verify-then-edit changes from task 2 (only files that matched).

## Validate
- [ ] 15. `bash -n .agent0/hooks/session-start.sh` — clean.
- [ ] 16. `printf '{"source":"compact","session_id":"t114"}' | bash .agent0/hooks/session-start.sh` — emits the HANDOFF block, no `.compact-history` reference, exit 0.
- [ ] 17. `python3 -m json.tool .claude/settings.json` and `… .claude/harness-sync-baseline.json` — both parse.
- [ ] 18. No-dangling-pointers grep (acceptance scenario 2) — only allowed survivors remain.
- [ ] 19. Confirm no remaining test runner references the deleted `compaction-continuity` suite.
- [ ] 20. Flip `spec.md` Status to `shipped`; note the removal in HANDOFF.md.
