# 144 — sync-harness-gitignore-aware-walk — plan

_Drafted from `spec.md` on 2026-06-03. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Make the two **`find`-based** manifest expansions in `walk_copy_check` (the `COPY_CHECK_RECURSIVE` loop and the `COPY_CHECK_GLOBS` loop) source their file lists from `git ls-files` instead of bare `find`, so "managed = tracked in Agent0". A single new helper resolves the file-set per base, with the work-tree-vs-non-git branch and the dirty-source advisory living in one place. The literal `COPY_CHECK_FILES` loop is untouched (explicit allowlist). Content sourcing is unchanged — `process_file`/`record_manifest` still read the working tree — so the only behavioral change is *which paths* enter the manifest. Two safety additions: an always-applied static exclude for the known runtime-cache shape (load-bearing only in the non-git fallback, harmless in the git path), and a deletion-output summary so the one-time cleanup of ~5147 stale cache files on existing consumers prints a count, not thousands of lines.

Order: (1) helper + work-tree detection + recursive-root rewrite; (2) glob-loop rewrite; (3) static cache exclude; (4) dirty-source advisory; (5) reconcile_deletions summary; (6) fixture + non-git tests; (7) doc update in `harness-sync.md` § Manifest scope; (8) run the full suite + a live `--check` against a consumer to confirm the drop from 6471→tracked-count.

## Files to touch

**Modify:**
- `.agent0/tools/sync-harness.sh`:
  - **New helper `list_tracked_under()`** (near `walk_copy_check`, ~L530): given a base dir, return git-tracked files under it. Uses `git -C "$AGENT0_ROOT" ls-files --cached -z -- "$base"` (NUL-delimited for path safety). Caller decides recursive vs maxdepth-1.
  - **New helper `agent0_is_git_worktree()`**: `git -C "$AGENT0_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1`. Computed once into a module-level flag at start of `walk_copy_check`.
  - **`COPY_CHECK_RECURSIVE` loop (~L534)**: when git work-tree → iterate `list_tracked_under "$base"`; else → keep `find "$base" -type f` (fallback) but rely on the static exclude (below) + emit the non-git advisory once.
  - **`COPY_CHECK_GLOBS` loop (~L548)**: same git/non-git branch; for the git path, list tracked files then filter to `dirname == dir` (maxdepth-1 equivalent) AND `basename` matching `$pattern` (use a `case`/`[[ ]]` glob, not a second `find`).
  - **`COPY_CHECK_EXCLUDE` (~L237)**: add `*/runtime/od-sync/extracted-*` (and keep it generic enough to catch the cache regardless of which recursive root it sits under). `matches_exclude` already `case`-globs the relpath, so the leading `*/` matches.
  - **Dirty-source advisory**: once per run, if `git -C "$AGENT0_ROOT" status --porcelain -- <roots>` is non-empty, print `harness-sync: advisory — Agent0 source work-tree is dirty; manifest reflects the index + working-tree content` to stderr. Non-blocking.
  - **Non-git advisory**: in the fallback branch, print `harness-sync: advisory — Agent0 source is not a git work-tree; degraded walk (static cache exclusion only)` once.
  - **`reconcile_deletions` (~L599)**: aggregate clean-orphan removals whose relpath matches the runtime-cache glob into a per-root counter; emit one `- removed N runtime-cache orphans under <root>` line instead of N per-file lines. Non-cache removals stay verbatim. `--force`/customized paths unchanged.

**Create:**
- `.agent0/tests/harness-sync/39-gitignore-aware-walk.sh` — fixture: build a temp Agent0 **git repo** SRC with a recursive root containing (a) a tracked file, (b) a gitignored cache file (`runtime/od-sync/extracted-x/foo`), (c) an untracked-nonignored file, (d) a tracked-then-`git rm --cached`/deleted path; assert `--check` manifest excludes b/c/d-deleted, includes a; assert `--apply` then `reconcile_deletions` removes a baseline-recorded cache orphan with the summarized line.
- `.agent0/tests/harness-sync/40-non-git-source-fallback.sh` — SRC is a plain dir (no `.git`) containing a cache-shaped path; assert the walk does NOT propagate `extracted-*` (static exclude) and emits the non-git advisory; assert a normal tracked-shaped file still copies.

**Modify (docs):**
- `.agent0/context/rules/harness-sync.md` § Manifest scope — document that the two `find`-based expansions are git-tracked-filtered (managed = tracked), the literal-file allowlist is not, and the non-git fallback behavior. Do NOT touch § Sync baseline's git-history-independence pillar.

## Alternatives considered

### `git check-ignore` (honor `.gitignore`) instead of `git ls-files`
Rejected: it would also propagate untracked-but-not-ignored files, and "managed = committed in Agent0" is the cleaner, stricter truth signal. `ls-files` also gave a provably-safe gap (tracked∩ignored = ∅).

### `git ls-tree -r HEAD` (committed file-set) instead of `git ls-files` (index)
Rejected during debate (R2/R3): the tool has *always* hashed working-tree content into the baseline (`agent0_commit` is a provenance breadcrumb, not a reproducibility contract). Switching the file-set to a committed ref while content stays working-tree would be a *new* contract; index-based file-set is consistent with existing semantics. Dirty-source nondeterminism is surfaced via the advisory instead.

### Fail closed on non-git sources
Rejected during debate (R3): `harness-sync.md:91` makes git-history-independence a deliberate pillar (works from tarball/shallow clone). Verified a `git archive` export is inherently cache-free (`grep -c extracted-` → 0), so the guarded `find` fallback is correct for the real export path; failing closed would break a documented workflow.

### Tracked harness-file catalog for non-git sources
Rejected: over-engineering against the `[[forks-ephemeral-dogfood]]` posture the rule itself cites; the static cache exclude covers the only measured leak.

## Risks and unknowns

- **`git ls-files` performance / arg handling** — large tracked sets are fine, but must use `-z` + read NUL-delimited to survive odd paths; the existing `find | sort` used plain newlines. Low risk (no newline-bearing paths in the harness today).
- **Static exclude breadth** — `*/runtime/od-sync/extracted-*` must not accidentally match a *tracked* path a consumer needs. Verified today: the only `extracted-*` content is the gitignored cache; no tracked path matches.
- **reconcile_deletions summary** — must preserve the existing `--force`/customized branches and exit codes; only the clean-orphan *output* is aggregated, not the deletion logic. Risk of mis-summarizing if a cache path is customized → that path must still print its own `!! customized` line.
- **Test fixture builds a git repo** — existing harness-sync tests use plain dirs; the new fixture must `git init` + `git add` + a `.gitignore`, a small but new pattern in the suite. The non-git test deliberately omits `.git`.
- **Dirty-source advisory noise** — Agent0's own work-tree is often dirty mid-session; the advisory fires on every dev `--check`. Keep it one line, stderr, non-blocking.

## Research / citations

- `.agent0/tools/sync-harness.sh` — `walk_copy_check` (L530-573), `record_manifest` (L522), `process_file`, `reconcile_deletions` (L599-662), `matches_exclude`, `COPY_CHECK_*` (L186-239).
- `.agent0/context/rules/harness-sync.md` — § Sync baseline (L84-93, git-history-independence), § Manifest scope (L216-227).
- `docs/specs/144-.../debate.md` — cross-model resolution of the three open questions.
- Reproduction commands (2026-06-03): per-root `find` vs `git ls-files` gap (5147 under `.claude/skills`); `git ls-files <roots> | git check-ignore --stdin` → empty; `git archive HEAD …/runtime | tar -t | grep -c extracted-` → 0.
- `.agent0/tests/harness-sync/` — existing suite + `run-all.sh` (next free numbers 39, 40).
