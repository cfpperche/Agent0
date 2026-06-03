# 144 — sync-harness-gitignore-aware-walk — tasks

_Generated from `plan.md` on 2026-06-03. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Add `agent0_is_git_worktree()` helper (`git -C "$AGENT0_ROOT" rev-parse --is-inside-work-tree`) and compute a module-level `AGENT0_GIT_SOURCE` flag once at the start of `walk_copy_check`.
- [x] 2. Add `list_tracked_under()` helper: `git -C "$AGENT0_ROOT" ls-files --cached -z -- "$base"`, read NUL-delimited, emit relpaths. (Recursive callers use as-is; glob callers post-filter.)
- [x] 3. Add the static runtime-cache exclude `*/runtime/od-sync/extracted-*` to `COPY_CHECK_EXCLUDE` and confirm `matches_exclude`'s `case` glob matches it (leading `*/`).
- [x] 4. Rewrite the `COPY_CHECK_RECURSIVE` loop: when `AGENT0_GIT_SOURCE` → iterate `list_tracked_under "$base"`; else → keep `find "$base" -type f` and rely on the static exclude + non-git advisory. Preserve the `matches_exclude` + `record_manifest` + `process_file` calls per file.
- [x] 5. Rewrite the `COPY_CHECK_GLOBS` loop: git path → `list_tracked_under "$dir"` filtered to `dirname == dir` (maxdepth-1) AND `basename` matching `$pattern` via shell glob; non-git path → existing `find -maxdepth 1 -name`.
- [x] 6. Add the dirty-source advisory: once per run, if `git -C "$AGENT0_ROOT" status --porcelain -- <recursive+glob roots>` is non-empty, print one stderr advisory line. Add the non-git advisory in the fallback branch.
- [x] 7. Update `reconcile_deletions`: aggregate clean-orphan removals whose relpath matches the runtime-cache glob into a per-root counter; emit one `- removed N runtime-cache orphans under <root>` line instead of per-file lines. Leave `--force`/customized/non-cache branches and exit codes unchanged.
- [x] 8. Create `.agent0/tests/harness-sync/39-gitignore-aware-walk.sh`: build a temp Agent0 **git repo** SRC (init + `.gitignore` with `extracted-*/` + commit) with a recursive root containing a tracked file, a gitignored cache file, an untracked-nonignored file, and a tracked-then-deleted path; assert `--check` manifest includes only the tracked-present file, and `--apply` + `reconcile_deletions` summarizes a baseline-recorded cache-orphan removal.
- [x] 9. Create `.agent0/tests/harness-sync/40-non-git-source-fallback.sh`: SRC is a plain dir (no `.git`) containing a cache-shaped path + a normal tracked-shaped file; assert the cache is excluded (static exclude), the non-git advisory is emitted, and the normal file still copies.
- [x] 10. Update `.agent0/context/rules/harness-sync.md` § Manifest scope to document: the two `find`-based expansions are git-tracked-filtered (managed = tracked), the literal-file allowlist is not, and the non-git guarded fallback. Do NOT touch § Sync baseline's git-history-independence pillar.

## Verification

- [x] Run `bash .agent0/tests/harness-sync/run-all.sh` — all existing tests + 39 + 40 pass.
- [x] Live `--check` against a consumer (`bash .agent0/tools/sync-harness.sh --check --agent0-path="$PWD" ../tese`) — no `runtime/od-sync/extracted-*` paths in output; walked count under `.claude/skills` matches `git ls-files .claude/skills | wc -l` (1324), not 6471. (spec § Scenario 1)
- [x] Confirm tracked content still travels: `vendor/open-design/` (747) + `.gitkeep` sentinels present in the `--check`/`--apply` manifest. (spec § Scenario 2)
- [x] Confirm the dirty-source advisory fires on a dirty Agent0 work-tree and is one non-blocking stderr line. (spec § source-state matrix scenario)
- [x] Confirm `git ls-files <roots> | git check-ignore --stdin` is empty (no tracked file is gitignored) — the safety proof. (spec final criterion)
- [x] `--apply --dry-run` against a polluted consumer shows the summarized cache-orphan removal line, not ~5000 individual lines. (spec § cleanup scenario)

## Notes

- Debate (`debate.md`) resolved all three open questions before planning — Model A ownership-clarified, `git ls-files` index + worktree content, summarize+`--force` cleanup.
- The fixture in task 8 introduces the first git-repo-based SRC in the harness-sync suite (existing tests use plain dirs); keep the `git init` minimal and offline.
