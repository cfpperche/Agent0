# 151 — sync-harness-local-only — plan

_Drafted from `spec.md` on 2026-06-04. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add a **local-only mode** to `.agent0/tools/sync-harness.sh`, auto-detected from the consumer's `.gitignore` via git's own ignore engine, that suppresses every write to a **non-ignored (tracked)** path while still refreshing the gitignored harness content. Order: detection helper → per-write gate at every write site → reporting → docs → regression test (TDD: test first).

**1. Detection — `_is_local_only` (set a `LOCAL_ONLY` global once).**
```sh
_is_local_only() {  # $1 = consumer root
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1   # not a git repo → never local-only
  git -C "$1" check-ignore -q .agent0/skills .agent0/context .agent0/tools 2>/dev/null
}
```
`git check-ignore -q <paths>` exits 0 iff a path is ignored; probe representative `.agent0/` subdirs.

**2. The write gate.** Rule: in local-only, **write only what the consumer gitignores; skip anything that would be tracked.**
```sh
_consumer_tracks() { ! git -C "$CONSUMER_ROOT" check-ignore -q -- "$1" 2>/dev/null; }  # true → tracked → skip in local-only
```
At each write site, when `LOCAL_ONLY=1` and `_consumer_tracks "$rel"`, skip + increment `SKIPPED_TRACKED`: the COPY_CHECK per-file copy, `merge_settings_json` (`.claude/settings.json`), `merge_claude_md` (`CLAUDE.md`/`AGENTS.md`), and the `.gitignore` merge (all tracked → early-return). Gitignored targets (the `.agent0/` tree incl. `.agent0/harness-sync-baseline.json`) are written as usual → local harness stays current, re-syncs idempotent.

**3. Reporting.** On detection print once: `local-only: consumer ignores the .agent0/ harness tree — refreshing gitignored harness, skipping all tracked-file writes`; append `, N tracked-skipped (local-only)` to the final summary line.

**4. Docs.** Add a "Local-only consumers" subsection to `.agent0/context/rules/harness-sync.md`.

## Files to touch

**Create:**
- `.agent0/tests/harness-sync/42-local-only.sh` — regression: a consumer that gitignores `.agent0/` → `--apply` writes ignored harness, touches NO tracked file, reports local-only; a normal consumer is unchanged.

**Modify:**
- `.agent0/tools/sync-harness.sh` — add `_is_local_only` + `_consumer_tracks` + `LOCAL_ONLY`/`SKIPPED_TRACKED`; gate the 4 write sites; detection notice + summary suffix.
- `.agent0/context/rules/harness-sync.md` — document local-only mode (trigger, behavior, motivating case; link `.agent0/memory/tmux-sentinel-sync-no-commit.md`).

**Delete:** none.

## Alternatives considered

### `--local-only` CLI flag
Rejected: ephemeral; the caller must remember it every sync, recreating the exact failure this fixes (the tmux-sentinel accidental commit).

### Persistent tracked marker (`.agent0-sync.local-only`)
Rejected: contradicts the zero-footprint goal by adding a harness artifact to an otherwise-clean public repo.

_(Chosen: auto-detect from `.gitignore` — the consumer already encoded the durable "`.agent0/` is not part of this repo" decision; reuse git's ignore engine. Claude + Codex converged independently, de-biased consult 2026-06-04.)_

## Risks and unknowns

- **False positive** — a consumer ignores `.agent0/` but wants tracked files. Mitigated: that IS the local-only contract; notice + docs make it discoverable.
- **`git check-ignore` availability** — present in all supported git; not-a-git-repo falls back to normal mode.
- **Per-file `check-ignore` cost** — one cheap git call per skipped file, bounded by managed-file count. Acceptable.
- **Write-site coverage** — risk of missing a write path; the regression test asserts `git status --porcelain` shows NO tracked change, which catches any un-gated site.

## Research / citations

- `.agent0/tools/sync-harness.sh` (current write sites), `.agent0/tests/harness-sync/` (suite shape), `.agent0/memory/tmux-sentinel-sync-no-commit.md` (motivating case).
- Codex de-biased consult 2026-06-04 (independent convergence on mechanism (c) + the `git check-ignore` refinement).
