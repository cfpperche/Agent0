# 068 — harness-sync-baseline-reconciliation — plan

_Drafted from `spec.md` on 2026-05-20. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add one primitive — a **recorded sync baseline** in the fork — and rewrite the plain-file decision in `sync-harness.sh` from a 2-way `sha256` compare into a 3-way reconciliation (`fork` vs `baseline` vs `agent0-current`). The structured-merge paths (`settings.json`, `CLAUDE.md`, `.gitignore`) are untouched; only `process_file()`, `walk_copy_check()`, and the summary/exit logic change, plus one new deletion pass and baseline read/write.

The plan resolves the four Open Questions from `spec.md` up front, because the implementation shape depends on all four:

**Q2 — baseline format → per-file sha manifest, with a git-commit audit field.** The baseline file is JSON: `{ "agent0_commit": "<sha|null>", "synced_at": "<iso>", "tool_version": "<n>", "files": { "<relpath>": "<agent0_sha_at_last_sync>", … } }`. This *deliberately diverges* from copier/cruft, which record only a git ref and regenerate the template at that ref. That machinery exists because cookiecutter/copier templates have **variables** — they must re-render Jinja at the old ref to know what the project started from. Agent0's harness has **no variables**: hooks, rules, tools are copied verbatim. So "what did this file look like at last sync" is answered directly by a stored sha — no `git show <ref>:<path>` per file, no dependency on Agent0's history being intact or reachable (works from a tarball or shallow clone). `agent0_commit` is still recorded as a human-readable audit breadcrumb (and is the audit log § Audit of the rule defers to "v2").

**Q3 — location → `.claude/harness-sync-baseline.json`, git-tracked.** No leading dot in the filename: every `.claude/.<name>` path in this repo is gitignored per-machine state (`.runtime-state/`, `.delegation-state/`, `.routines-state/`, …), and the baseline must NOT be — it is meaningful state that should travel on `git clone` of the fork (a fresh clone must know its baseline). copier and cruft both git-track their answer files (`.copier-answers.yml`, `.cruft.json`); we follow that. It appears in the fork's post-sync `git diff` — intended: the diff *is* the "harness baseline bumped" record.

**Q1 — bootstrap → first sync seeds what it can, refuses the rest; `--force`/`--force-except` is the one-time reconciliation lever; no new flag.** On a sync with no baseline file present, for each plain file: `fork == agent0` → seed `files[path] = agent0_sha`; `fork != agent0` → cannot tell stale from customized (the genuine pre-baseline ambiguity), so report `!! customized (no baseline — first sync)` and refuse, exactly as today. The operator does a **one-time** reconciliation: review the diffs, then `--apply --force` (adopt Agent0 wholesale) or `--apply --force --force-except='<globs of real customizations>'`. After that first run, the baseline is fully seeded and **every subsequent sync is clean 3-way**. copier has no first-class adopt (`copier adopt`, issue #2486, still open — you hand-craft the answers file); cruft has `cruft link`. We need neither: `--force` already *is* the adopt path. The one-time first-sync friction is unavoidable — there is genuinely no recorded history to consult — but it is paid exactly once per fork, ever.

**Q4 — exit/counters.** Two new counters: `STALE_UPDATED` (stale files auto-updated) and `REMOVED` (upstream-removed files deleted). `--check`: `stale` and `removed` both count as drift → exit 1, alongside `would copy` and `customized`. `--apply`: exit 1 iff customizations were refused (unchanged) — stale auto-updates and removals are successful actions, not refusals, so they do not flip the exit code. The summary line gains `N stale-updated, N removed`.

**Decision flow per plain file** (`process_file()`), when `fork_sha != agent0_sha` and both files exist:

| `baseline_sha` | relation | verdict |
|---|---|---|
| present, `== fork_sha` | fork untouched since sync, Agent0 moved | **stale** → update (no `--force` needed) |
| present, `!= fork_sha` | fork edited the file | **customized** → refuse (today's behavior; `--force` overrides) |
| absent (no entry) | first sync / file added to manifest after fork's last sync | **customized (no baseline)** → refuse; `--force` overrides |

**Deletion pass** (new, runs after `walk_copy_check`): the walk collects Agent0's current managed-file set; for each path in `baseline.files` NOT in that set — `fork_sha == baseline_sha` → **remove** from fork (+ `rmdir` now-empty parents); `fork_sha != baseline_sha` → **customized-upstream-removed** → keep, refuse, advise manual resolution; fork no longer has it → no-op. Canonical case: `templates/monorepo-skeleton/*` after the `app-skeleton` rename.

**Baseline write**: only on `--apply` without `--dry-run`, after all passes. Recompute Agent0's current manifest sha-set and write the JSON atomically (`mktemp` + `mv`, same pattern as `merge_settings_json`).

## Files to touch

**Create:**
- `<fork>/.claude/harness-sync-baseline.json` — written into the fork by `--apply` (runtime artifact, not committed to Agent0 itself).
- `.claude/tests/harness-sync/NN-baseline-*.sh` — regression tests, one per new state (stale-auto-update, customized-still-refused, removed, customized-upstream-removed, bootstrap-no-baseline, idempotency, `--check` labelling). Numbered after the current highest in that dir.

**Modify:**
- `.claude/tools/sync-harness.sh` — (1) baseline load near startup: parse `<fork>/.claude/harness-sync-baseline.json` if present; (2) `process_file()` — insert the 3-way decision table; (3) `walk_copy_check()` — accumulate Agent0's current manifest into a set (sorted temp file); (4) new `reconcile_deletions()` pass; (5) new `write_baseline()` called at end of `--apply`; (6) two new counters + summary line + `--check`/exit wiring.
- `.claude/rules/harness-sync.md` — rewrite § Customization detection (2-state → 3-way table), add a § Sync baseline section, update § Audit (no longer "None" — the baseline file is the record), § Manifest scope (deletion propagation), § Gotchas (Bash-3.2 lookup note, one-time first-sync reconciliation note).
- `CLAUDE.md` § Harness sync — add the baseline mechanism + the new file path to the capacity summary.
- `.gitignore` — confirm no pattern catches `.claude/harness-sync-baseline.json` (the non-dotted name already dodges the `.claude/.*` ignores; add an explicit `!`-negation only if a broad pattern is found).

**Delete:** none.

## Alternatives considered

### Pure git-ref baseline (verbatim copier/cruft model)

Record only `agent0_commit`; recover each file's last-synced content via `git -C $AGENT0_ROOT show <commit>:<relpath>` at reconcile time. Rejected: it makes a hard dependency on Agent0's git history being present and reachable at every sync (fails on a tarball, a shallow clone, or after a history rewrite), and it buys nothing Agent0 needs — copier regenerates at the old ref because its templates have Jinja variables; Agent0's harness is verbatim-copied, so a stored per-file sha captures the identical information with zero git calls. We keep `agent0_commit` as an *audit* field but do not depend on it for reconciliation.

### In-file markers for plain files (extend the spec-058 CLAUDE.md approach)

Wrap each hook/rule/tool in `# AGENT0:BEGIN`/`# AGENT0:END` so the Agent0-owned region is self-describing, as `CLAUDE.md` does. Rejected: markers fit `CLAUDE.md` because it genuinely *interleaves* fork-authored prose (Overview, Stack) with Agent0 capacity sections — there is a real fork region to delimit. A hook script or a rule `.md` is ~100% Agent0-owned; there is nothing to interleave, so a whole-file `BEGIN/END` wrapper is pure noise, and it gives no answer for a file the fork legitimately customizes end-to-end. Whole-file ownership is exactly what an external baseline records cleanly.

### Do nothing — rely on `--force` + `--force-except`

Rejected: that is the status quo and precisely the bug. `--force-except` requires the operator to enumerate the customized files *in advance* — which is the unknowable thing the 2-state compare cannot tell them. The baseline exists to compute that set instead of demanding it as input.

## Risks and unknowns

- **Bash 3.2 portability — no `declare -A`.** The baseline lookup cannot use an associative array (repo-wide constraint, `harness-sync.md` § Gotchas). Mitigation: one `jq` call dumps `path\tsha` lines into a sorted temp file; per-file lookup is `grep`/`look` against it — no per-file `jq` fork (500 forks would be slow). Decide the exact lookup in implementation; the temp-file approach is the default.
- **One-time first-sync friction for every existing fork.** Until a fork runs its first post-068 `--apply`, it has no baseline; that first run degrades to 2-state and needs manual `--force`/`--force-except` reconciliation. Unavoidable (no history to consult) — must be documented as a migration note in `harness-sync.md`, not hidden.
- **Baseline staleness if the fork hand-edits the JSON.** Same footgun copier warns about ("never edit `.copier-answers.yml` manually"). Lower severity here — a wrong sha just mislabels one file stale-vs-customized, recoverable on the next sync. Document, do not guard.
- **Directory orphan cleanup.** `monorepo-skeleton/` is a tree; the deletion pass removes files then must `rmdir` emptied parents without touching dirs that still hold fork content. Walk parents bottom-up, `rmdir` only on empty.
- **`agent0_commit` when `--agent0-path` is not a git repo.** `git rev-parse` fails → record `null`, fail-open. Reconciliation never depends on this field, so `null` is harmless.
- **Effort: M.** One tool file (contained changes to ~3 functions + 2 new functions), ~7 regression tests, 3 doc files.

## Research / citations

- [copier — Updating a project](https://copier.readthedocs.io/en/stable/updating/) — `.copier-answers.yml` stores `_commit` (a VCS ref); `copier update` is a 3-way merge: regenerate the project from the *old* ref with the same answers, diff against the user-modified project, apply that diff onto the *new* generation. Conflicts → `.rej` files or inline markers. The regeneration step is what Agent0 can skip (no template variables).
- [copier issue #2486 — `copier adopt`](https://github.com/copier-org/copier/issues/2486) — adopting a template into a pre-existing project is *not* first-class in copier; the bootstrap is a manual answers-file craft. Informs Q1: Agent0's `--force` first-sync is the equivalent, and is enough.
- [cruft](https://cruft.github.io/cruft/) & [cruft GitHub](https://github.com/cruft/cruft) — `.cruft.json` records the template's git source + the exact commit hash + context vars (git-tracked). `cruft update` diffs `recorded_commit..latest`; `cruft check` is the CI drift gate; `cruft link` retro-links an existing project to a template. Confirms: git-track the baseline file; a commit ref is the audit anchor.
- [Cruft vs copier — Blenddata](https://www.blenddata.nl/en/blogs/cruft-vs-copier-automating-template-updates-at-scale) — both tools converge on "record where you synced from, 3-way reconcile on update"; the difference is delivery (cruft = diff/patch, copier = regenerate/merge). Agent0's verbatim-copy harness is simpler than either.
- `.claude/tools/sync-harness.sh` — `process_file()` (~196-252, the 2-state compare), `walk_copy_check()` (~254), `merge_settings_json()` (~284, the atomic-write + jq pattern to mirror), manifest arrays (~128-151).
- `.claude/rules/harness-sync.md` — § Customization detection, § Audit ("None" → defers a log to "a v2 spec"), § Gotchas (Bash 3.2 / `declare -A` constraint, long-stale-fork large-diff note).
- `docs/specs/058-*` — `CLAUDE.md` managed-block merge: the in-repo precedent for propagating upstream removals (the orphan-removal fix this spec mirrors for the file tree).
