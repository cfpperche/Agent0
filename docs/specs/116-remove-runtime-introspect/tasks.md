# 116 — remove-runtime-introspect — tasks

_Generated from `plan.md` on 2026-05-29. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation — sever registrations + entrypoints

- [x] 1. `.claude/settings.json` — drop PreToolUse(Bash) `runtime-pre-mark`, PostToolUse(Bash) `runtime-capture`, and the whole `PostToolUseFailure` event; fix connector commas.
- [x] 2. `CLAUDE.md` + `AGENTS.md` — remove the `## Runtime introspect` section (preserve managed-block markers).
- [x] 3. `.agent0/hooks/session-start.sh` — remove the `=== runtime-introspect ===` readout block.
- [x] 4. `.agent0/hooks/delegation-stop.sh` — reword the `mirror runtime-capture.sh` comment.

## Implementation — sever cross-refs (rules / memory / site / sync)

- [x] 5. `.claude/rules/delegation.md` — § "Why DONE_WHEN exists": drop `probe.sh last-run` verifier citation.
- [x] 6. `.claude/rules/runtime-capabilities.md` — drop the runtime-introspect / local-test-capture matrix row.
- [x] 7. `.claude/rules/{lint-validator,php-laravel-support,session-handoff,memory-placement}.md` — sever cross-refs.
- [x] 8. `.agent0/memory/*` — per-file keep-vs-rewire (cc-platform-hooks, capacity-spec-index, harness-home, hook-chain-latency, hook-chain-maintenance, propagation-hygiene, user-global-hooks-shadow, visibility-intent); record each call in `notes.md`.
- [x] 9. `.agent0/.runtime-state/README.md` — remove the runtime-introspect row (keep the README + sibling rows).
- [x] 10. `site/src/i18n/capacities.ts` — remove the runtime-introspect card.
- [x] 11. `.agent0/tools/sync-harness.sh` — remove the deleted paths from the manifest/COPY_CHECK set.
- [x] 12. `.gitignore` — remove runtime-state ignore lines (preserve README exception).
- [x] 13. `.claude/.perf-baseline.json` — prune the removed hooks' entries.

## Implementation — delete files + regenerate

- [x] 14. `git rm` the hook pair, `probe.sh`, the rule, the maintainer memory, and both test suite dirs.
- [x] 15. `rm -rf .agent0/.runtime-state/in-flight .agent0/.runtime-state/last-run.json` (gitignored runtime state).
- [x] 16. `bash .agent0/tools/memory-project.sh` — regenerate `MEMORY.md`.

## Verification

- [x] 17. `ls` of all deleted paths → gone; `ls .claude/tests/runtime-introspect .claude/tests/runtime-capture-php` → gone. [spec: Scenarios 1, 2]
- [x] 18. `jq .` parses `settings.json`; no runtime-capture/pre-mark string; `PostToolUseFailure` key absent. [spec: Scenario 3]
- [x] 19. Full `.claude/tests/` aggregate runner green (no broken fixtures). [spec: Scenario 4]
- [x] 20. `grep -n runtime-introspect .agent0/memory/MEMORY.md` empty; projection clean. [spec: Scenario 5]
- [x] 21. Repo-wide grep (capacity terms) outside `docs/specs/` → only KEEP-listed lines. [spec: final criteria]
- [x] 22. `CLAUDE.md`/`AGENTS.md` no `## Runtime introspect`; `session-start.sh` no readout; `delegation.md` no probe citation; `runtime-capabilities.md` no row. [spec: per-criterion]
- [x] 23. Site build succeeds; `bench-hooks.sh` runs; hook-chain-latency suite passes. [spec: site + bench criteria]
- [x] 24. `spec.md` Status → `shipped`; outcome recorded; `notes.md` finalized.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
