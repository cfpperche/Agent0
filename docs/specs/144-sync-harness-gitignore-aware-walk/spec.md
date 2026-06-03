# 144 — sync-harness-gitignore-aware-walk

_Created 2026-06-03._

**Status:** shipped (2026-06-03 — on origin/main, 528c475)

## Intent

`sync-harness.sh`'s recursive-root walk (`walk_copy_check`, iterating `COPY_CHECK_RECURSIVE` via bare `find -type f`) **does not respect `.gitignore`**, so it sweeps and propagates ephemeral, gitignored runtime caches to consumer projects as if they were managed harness files. Measured 2026-06-03 — the authoritative figure is the per-root **`find` vs `git ls-files` gap**:

```bash
for b in .claude/skills .agent0/context .agent0/skills .agent0/tests .claude/agents; do
  echo "$b: find=$(find "$b" -type f | wc -l) ls-files=$(git ls-files "$b" | wc -l)"
done
```

→ `.claude/skills`: find=6471 vs ls-files=**1324** = **5147 untracked/ignored files**; the other four roots: gap=0. That 5147 is almost entirely the OD-engine's tarball-extraction cache (`.claude/skills/product/runtime/od-sync/extracted-<sha>/`, gitignored via `runtime/od-sync/.gitignore` → `extracted-*/`; 5163 on disk, only 4 tracked). The prior session mis-attributed this to `reconcile_deletions` "not mirroring recursive roots": the deletion pass IS baseline-gated and works, but it operates over a baseline poisoned with thousands of cache entries, and the pin SHA is embedded in the extracted dir *name* (`extracted-c128ffd5…/`) so every OD-pin advance creates a fresh orphan tree on every consumer.

The fix: make the two **`find`-based** manifest expansions (`COPY_CHECK_RECURSIVE` and `COPY_CHECK_GLOBS`) **git-aware** — "managed = tracked in Agent0", via `git ls-files`. Mechanism: `git ls-files` (the **index**) supplies the file-SET; content still comes from the **working tree** — consistent with the existing baseline semantics, where `sha_of` already hashes working-tree content and `agent0_commit` is a provenance breadcrumb, not a reproducibility contract (`harness-sync.md` § Sync baseline). The tracked-set vs find-set difference is provably *only* gitignored/untracked files (gap=0 on every root except `.claude/skills`; **no tracked file is gitignored**), so `git ls-files` never drops a file that must travel. This is a harness-layer correctness fix in the same bug-class as specs 141/142 (which fixed the analogous gaps inside the OD-engine), one layer up. _Cross-model debate (Claude Code ↔ Codex CLI, 2026-06-03 — see `debate.md`) resolved the propagation model, the dirty-source semantics, and the non-git fallback._

## Acceptance criteria

- [x] **Scenario: the git-aware walk ignores gitignored runtime cache**
  - **Given** Agent0 has a populated `runtime/od-sync/extracted-<sha>/` tree (gitignored, ~5000 files) under the `.claude/skills` recursive root
  - **When** `sync-harness.sh --check <consumer>` runs from a git work-tree Agent0 source
  - **Then** no `runtime/od-sync/extracted-*` path appears in the walk output or the manifest, and the walked file-set under each recursive root equals that root's `git ls-files` set (e.g. `.claude/skills` → 1324, not 6471)

- [x] **Scenario: tracked content still propagates**
  - **Given** the git-aware walk is in effect
  - **When** `--check`/`--apply` runs against a consumer
  - **Then** every git-tracked file under each `COPY_CHECK_RECURSIVE` root (including the 747 tracked `vendor/open-design/` files and all `.gitkeep` sentinels) is still walked, recorded in the manifest, and reconciled exactly as before

- [x] **Scenario: git-awareness covers both find-based expansions; named files stay an allowlist**
  - **Given** an untracked file under a `COPY_CHECK_RECURSIVE` root AND an untracked file matching a `COPY_CHECK_GLOBS` pattern AND a locally-untracked-but-present file that is a literal `COPY_CHECK_FILES` entry
  - **When** the walk runs
  - **Then** the untracked recursive file and the untracked glob match are both **excluded** (tracked-filtering applies to both `find` expansions), while the named `COPY_CHECK_FILES` entry **still propagates** (explicit allowlist — literal paths cannot sweep a cache, so they are not tracked-filtered)

- [x] **Scenario: source-state matrix is honored (behavioral contract)**
  - **Given** under a recursive root: a staged-new tracked file, an unstaged edit to a tracked file, an unstaged deletion of a tracked file, an untracked-nonignored file, and an untracked-ignored file
  - **When** the walk runs from a dirty git work-tree
  - **Then** staged-new → included; unstaged-edit → included with working-tree (dirty) content; unstaged-deletion → **excluded** (both `record_manifest` and `process_file` guard on `[ -f "$src" ]`) and therefore **drives consumer-side deletion** via `reconcile_deletions`; untracked-nonignored → excluded; untracked-ignored → excluded
  - **And** when `git status --porcelain -- <root>` is non-empty the run emits a one-line **dirty-source advisory** to stderr (the advisory is load-bearing — an unstaged deletion silently propagating a removal must be visible)

- [x] **Scenario: non-git source falls back safely, never blind**
  - **Given** an Agent0 source where `git -C "$AGENT0_ROOT" rev-parse --is-inside-work-tree` fails (a tarball/archive export with no `.git`)
  - **When** the walk runs
  - **Then** it falls back to `find` **guarded by an always-applied static runtime-cache exclusion** (`*/runtime/od-sync/extracted-*`) and emits a degraded-mode (non-git) advisory; it does NOT fail closed (preserving the documented tarball/shallow-source support per `harness-sync.md`) and does NOT propagate the known cache blind
  - **And** a standard `git archive` export is already tracked-only (verified: `git archive HEAD …/runtime | tar -t | grep -c extracted-` → 0), so the fallback is correct for the standard export path and the static exclusion is defense-in-depth for non-standard raw-copy exports

- [x] **Scenario: previously over-propagated cache is cleaned from consumers on next apply**
  - **Given** a consumer whose baseline + working tree carry the ~5147 over-propagated `extracted-<sha>/` cache files from a pre-fix sync, untouched since
  - **When** `sync-harness.sh --apply <consumer>` runs with the git-aware walk
  - **Then** those paths are absent from the new manifest, `reconcile_deletions` removes the clean orphans, the new baseline no longer records them, and the deletion is **summarized** (e.g. `- removed N runtime-cache orphans under <root>`, not ~5000 individual lines)

- [x] **Scenario: a consumer-customized stale cache file is not silently destroyed**
  - **Given** a consumer that edited a file inside `extracted-*` before the fix
  - **When** `--apply` runs
  - **Then** that file hits the existing `!! customized <path> (upstream-removed — resolve manually)` refusal (consumer work is never silently deleted), and `--force` is the documented bulk-cleanup path

- [x] **Scenario: a pin advance no longer leaks a new extracted tree**
  - **Given** Agent0 advances the OD pin (`extracted-<oldsha>/` replaced by `extracted-<newsha>/`, both gitignored)
  - **When** the consumer is re-synced
  - **Then** neither tree is propagated, and no orphan extracted directory accumulates on the consumer

- [x] **Scenario: fresh-consumer bootstrap stays single-command (Model A)**
  - **Given** a fresh consumer with no prior OD vendoring
  - **When** `sync-harness.sh --apply <consumer>` completes
  - **Then** the tracked `vendor/open-design/` design-template corpus is present and usable with **no second / network-dependent command** — the harness transports the committed snapshot

- [x] Tests land in `.agent0/tests/harness-sync/`: (a) a fixture test that builds a temp Agent0 git repo with a recursive root containing a tracked file, a gitignored cache file, an untracked-nonignored file, and a tracked-but-deleted path, then asserts manifest + `--check` + `--apply` behavior matches the source-state matrix; (b) a non-git-source test asserting the guarded fallback (known cache excluded + degraded-mode advisory).

- [x] No git-tracked file in any current `COPY_CHECK_RECURSIVE` root is also gitignored — proven by `git ls-files <roots> | git check-ignore --stdin` returning empty (run 2026-06-03: empty), so the change provably never drops a file that must travel.

## Non-goals

- Changing `reconcile_deletions`' baseline-gated deletion logic — it is correct; this spec removes the cache pollution that made it look broken.
- Touching the OD-engine (`sync-open-design.ts`) — specs 141/142/143 own vendoring, prune, idempotence, and the `skills/`→`design-templates/` remap. This spec is purely the harness walk.
- Replacing the explicit `COPY_CHECK_FILES` / `COPY_CHECK_GLOBS` / `COPY_CHECK_EXCLUDE` lists with a fully git-derived manifest — the change is scoped to the two `find`-based expansions; the literal-file allowlist stays.
- Shipping a tracked harness-file catalog/manifest for non-git sources — rejected as over-engineering against the `[[forks-ephemeral-dogfood]]` posture `harness-sync.md` itself cites; the guarded `find` fallback covers the real export paths.
- Changing `harness-sync.md`'s git-history-independence pillar (`agent0_commit` is a breadcrumb; reconciliation works from a tarball/shallow clone) — preserved; the non-git fallback is designed around it.
- Switching content sourcing to a committed ref (`git ls-tree HEAD`) — rejected; the tool has always hashed working-tree content, and a content-pinned model would change existing behavior.

## Open questions

_All resolved during `/sdd debate` (2026-06-03, Claude Code ↔ Codex CLI — see `debate.md` § Synthesis)._

- [x] **Propagation model (was A vs B) → resolved: Model A, ownership-clarified.** The harness transports the already-tracked `vendor/open-design/` snapshot (fork-and-go, no network at bootstrap); the OD-engine is the sole generator/updater of that snapshot **in Agent0**; a consumer-side OD refresh is an explicit opt-in maintainer workflow that thereafter takes the `!! customized` / `--force` sync path. (Lean-B withdrawn — it broke the harness-sync bootstrap contract.)
- [x] **Mechanism → resolved: `git ls-files` (index) for the file-set + working-tree content + dirty-source advisory.** Rejected `git ls-tree HEAD` (would change existing content semantics) and a `.gitignore`-parsing approach (reimplements git).
- [x] **One-time cleanup of stale cache on existing consumers → resolved: summarize + `--force`, do not gate.** Normal `reconcile_deletions` removes clean orphans (output summarized); customized cache files refuse and are cleaned via `--force`.

## Context / references

- `.agent0/tools/sync-harness.sh` — `walk_copy_check` (~L530), `COPY_CHECK_RECURSIVE` (~L186), `COPY_CHECK_GLOBS` (~L195), `COPY_CHECK_EXCLUDE` (~L237), `record_manifest` (~L522), `reconcile_deletions` (~L599), `process_file`.
- `.agent0/context/rules/harness-sync.md` — the 3-way baseline reconciliation contract; § Sync baseline line 91 (git-history-independence pillar); § Manifest scope.
- `docs/specs/144-sync-harness-gitignore-aware-walk/debate.md` — the cross-model debate that resolved the open questions.
- `docs/specs/142-od-sync-orphan-prune/spec.md`, `143-od-vendor-skills-remap/spec.md`, `141-od-sync-apply-completeness/spec.md` — the OD-engine layer of the same bug-class.
- `.agent0/tests/harness-sync/` — existing sync-harness test suite (fixture home for the new tests).
- Reproduction (2026-06-03): per-root `find` vs `git ls-files` gap = 5147 under `.claude/skills`, 0 elsewhere; `git ls-files <roots> | git check-ignore --stdin` → empty; `git archive HEAD …/runtime | tar -t | grep -c extracted-` → 0.
