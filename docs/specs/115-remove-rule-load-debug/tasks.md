# 115 — remove-rule-load-debug — tasks

_Generated from `plan.md` on 2026-05-29. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation — sever live references

- [x] 1. `.claude/settings.json` — remove the `InstructionsLoaded` block; fix the trailing comma on the preceding `PostToolUseFailure` block.
- [x] 2. `.agent0/tools/probe.sh` — remove the `rule-loads)` case branch, the `rule-loads` usage-block lines, and the `CLAUDE_RULE_LOAD_DEBUG` example/hint.
- [x] 3. `.gitignore` — remove the two `.claude/.rule-load-debug.jsonl*` lines.
- [x] 4. `.agent0/.runtime-state/README.md` — drop the `.rule-load-debug.jsonl` row; remove `rule-load-debug` from the intro's Claude-exclusive-state list.
- [x] 5. `.agent0/memory/cc-platform-hooks.md` — `7 of these 29` → `6 of these 29`; remove the `InstructionsLoaded (rule-load-debug, opt-in)` bullet; sever the two `rule-load-debug.md` cross-refs; KEEP event-table row + empirical dedup finding (drop only the dead pointer phrasing).
- [x] 6. `.agent0/memory/capacity-spec-index.md` — remove the `Rule load debug` row.
- [x] 7. `site/src/i18n/capacities.ts` — remove the `id: "rule-load-debug"` capacity object.

## Implementation — delete files + regenerate

- [x] 8. `git rm .claude/hooks/rule-load-debug.sh`.
- [x] 9. `git rm .agent0/memory/rule-load-debug.md`.
- [x] 10. `rm -f .claude/.rule-load-debug.jsonl .claude/.rule-load-debug.jsonl.lock` (gitignored runtime files).
- [x] 11. `bash .agent0/tools/memory-project.sh` — regenerate `MEMORY.md` without the entry.

## Verification

- [x] 12. `jq -e '.hooks | has("InstructionsLoaded") | not' .claude/settings.json` exits 0 (parses + key absent). [spec: Scenario "InstructionsLoaded registration removed"]
- [x] 13. `bash -n .agent0/tools/probe.sh` clean; `probe.sh last-run` exits 0; `probe.sh rule-loads` → unknown-subcommand (exit 2). [spec: Scenario "probe.sh no longer exposes rule-loads"]
- [x] 14. `ls` of hook/doc/log paths → all gone; `grep rule-load-debug .gitignore` empty. [spec: Scenarios "hook+doc gone", "runtime log deleted"]
- [x] 15. Repo-wide grep for `rule-load-debug`/`CLAUDE_RULE_LOAD_DEBUG` → only `docs/specs/*` + KEEP-listed `cc-platform-hooks.md` lines. [spec: final criterion]
- [x] 16. `grep -n rule-load-debug .agent0/memory/MEMORY.md` empty. [spec: Scenario "MEMORY.md regenerated"]
- [x] 17. Site build succeeds OR record deferral + parse sanity check in `notes.md`. [spec: site criterion]
- [x] 18. `spec.md` Status → `shipped`; outcome recorded.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
