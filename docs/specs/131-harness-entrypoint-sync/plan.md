# 131 — harness-entrypoint-sync — plan

_Drafted from `spec.md` on 2026-05-31. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The debate's two gaps have very different costs to close, so the plan splits them.

**Gap A (duplicated index) is already guarded** — `.agent0/tools/check-instruction-drift.sh` (lines 99–104) already asserts that Agent0's `CLAUDE.md` and `AGENTS.md` managed blocks (`AGENT0:BEGIN…END`) are **byte-identical**, failing otherwise. That is the "single source of truth, enforced" invariant for the index in the Agent0 repo; in consumers both blocks descend from Agent0 via sync, so they cannot independently drift. So Gap A needs **no new code** — only a spec-criterion wording fix ("kept identical, enforced by the drift checker", not "rendered from one source") and a doc note. Full physical single-sourcing (one file rendered into both) is deferred as a non-goal — it is a larger refactor with no current pain.

**Gap B (project core invisible to the non-authoring runtime) is the real build.** Implement the converged **consumer-source mirror**: a consumer authors `.agent0/project-core.md` once (consumer-owned, *outside* the sync manifest so Agent0 never overwrites it); on `--apply`, `sync-harness.sh` renders it verbatim into an always-on `<!-- AGENT0:PROJECT:BEGIN -->…END` region in BOTH `CLAUDE.md` and `AGENTS.md`. The merge is a new direction (consumer-source → the consumer's own two entrypoints) reusing the existing 3-way machinery: per-region rendered hash recorded in `harness-sync-baseline.json` under synthetic keys `CLAUDE.md#PROJECT` / `AGENTS.md#PROJECT` (same trick as `CLAUDE.md#managed-block`). Region absent → create (inserted just above `AGENT0:BEGIN`); region == source → up-to-date; region == last recorded hash but source changed → stale re-render (no `--force`); region edited away from both source and recorded hash → refuse (`--force` re-renders). The source is never written by sync. When `.agent0/project-core.md` is absent the whole pass is a no-op, so the feature is opt-in and backward-compatible (existing consumers like cognixse are untouched until they adopt it). Long-tail reference stays in `docs/` + the existing context-injection hook — explicitly not mirrored.

Build order: (1) generalize the marker lib to accept a marker name; (2) add `sync_project_core` + wire it into main + record synthetic keys; (3) tests; (4) rule + spec doc updates.

## Files to touch

**Create:**
- `.agent0/tests/harness-sync/NN-project-core-mirror.sh` — fixture test: create / up-to-date / stale / customized-refuse / `--force` / sentinel-in-both-entrypoints / source-never-overwritten / absent-source-no-op.

**Modify:**
- `.agent0/tools/lib/managed-block.sh` — add an optional marker-name arg to `detect_marker_state` and `_extract_region` (default `AGENT0`, so all existing callers are unchanged; `AGENT0:PROJECT` selects the new markers).
- `.agent0/tools/sync-harness.sh` — add `PROJECT_SOURCE_REL`/`PROJECT_MARKER` constants, `sync_project_core()` + `_mirror_project_region()`, call it in main between `merge_gitignore` and `write_baseline`, and append the `<rel>#PROJECT` synthetic keys to the manifest so `write_baseline` persists them. Add a usage/escape-hatch note.
- `.agent0/context/rules/harness-sync.md` — new § "Project core (consumer-source mirror)" documenting the source, markers, merge rule, synthetic keys, opt-in/migration posture; note Gap A is guarded by `check-instruction-drift.sh`.
- `.agent0/tools/check-instruction-drift.sh` — (optional, if low-risk) add an invariant: when `.agent0/project-core.md` exists, both entrypoints' `PROJECT` regions equal the source.
- `docs/specs/131-harness-entrypoint-sync/spec.md` — reword the "single-sourced index" scenario to "kept byte-identical, enforced by `check-instruction-drift.sh`"; mark physical single-sourcing a non-goal.

**Delete:** none.

## Alternatives considered

### Render the index from one physical source into both entrypoints (true Gap-A single-sourcing)
Rejected for v1 — Agent0 has no build step, the two blocks are already byte-identical and CI-guarded by `check-instruction-drift.sh`, and the index is not the pain anyone hit. Adds a render pipeline for zero current benefit. Revisit only if the drift guard proves insufficient.

### Author the project core in CLAUDE.md and mirror into AGENTS.md (debate Design 2)
Rejected — makes CLAUDE.md the privileged source and AGENTS.md a derived artifact, which breaks Codex's expectation that AGENTS.md is its primary entrypoint (raised by Codex in round 3). The neutral-source design keeps neither entrypoint privileged.

### Deliver the project core through the context-injection hook (debate Option A / A+)
Rejected for the always-on core — the hook rail is relevance-gated (keyword selection), byte-bounded (6000 B / 5 fragments), and advisory-ordered; it can silently drop always-needed framing. Reserved for the long tail, where relevance-gating is a feature.

## Risks and unknowns

- **Region insertion anchor** — `_mirror_project_region` inserts a new region just above `<!-- AGENT0:BEGIN -->`. If an entrypoint lacks that marker (malformed), fall back to EOF-append with a warning (mirror the managed-block merge's missing-anchor handling).
- **Baseline key persistence on refuse** — must append the `#PROJECT` synthetic key to the manifest on all non-error paths (incl. customized-refuse), else `write_baseline` (which rebuilds the files-map from the manifest) drops the recorded hash. Mirror `record_managed_block_manifest`'s unconditional-on-paired recording.
- **Marker collision** — `^<!-- AGENT0:BEGIN -->$` must not match `<!-- AGENT0:PROJECT:BEGIN -->`. It does not (exact-line grep), but the generalized lib must build the pattern from the marker name correctly. Covered by a test asserting the index block is untouched when only the PROJECT region changes.
- **Bash 3.2 / macOS portability** — keep to the repo's `mapfile`-free, `declare -A`-free style (same as the rest of `sync-harness.sh`).
- **Self-rebootstrap** — `sync_project_core` runs after `_self_rebootstrap`, so editing `sync-harness.sh` itself is already covered; no new interaction.

## Research / citations

- `.agent0/tools/sync-harness.sh` — `_merge_claude_md_managed_block` (1012–1118), `record_managed_block_manifest` (811), baseline machinery (294–325, 634–684), main orchestration (1424–1432).
- `.agent0/tools/lib/managed-block.sh` — `detect_marker_state`, `_extract_region`, `_region_sha` (the helpers to generalize).
- `.agent0/tools/check-instruction-drift.sh` (99–104) — existing Gap-A byte-identical guard.
- `.agent0/context/rules/harness-sync.md` — § Sync baseline (synthetic-key precedent), § CLAUDE.md managed-block merge, § Manifest scope (allowlist → out-of-scope is consumer-owned).
- `debate.md` (this spec) — round-3 consumer-source-mirror merge rule + authority order.
