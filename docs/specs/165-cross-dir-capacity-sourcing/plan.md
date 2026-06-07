# 165 — cross-dir-capacity-sourcing — plan

_Drafted from `spec.md` on 2026-06-07. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

164 discipline + one cross-dir rule (lazy-load). Order: **(1) golden capture BEFORE** → **(2) write the smoke test** `tests/capacity-kit/cross-dir-source.sh` (the load-bearing prerequisite — the whole reason video/image were deferred) → **(3) migrate `video`** → **(4) migrate `image`** → **(5) prove green** → **(6) docs**.

The smoke test is written FIRST (before the migrations consume the pattern) so the pattern is pinned the moment it exists. It uses the sync-propagation temp-consumer harness: a sentinel `$CONSUMER/.agent0/tools/lib/paid-media.sh` and a copy of `video/gen.sh` (or `image/gen.sh`), run with `CLAUDE_PROJECT_DIR=$CONSUMER`, proving the skill script sources the lib from the consumer root; a no-lib lane proving a paid subcommand exits 70 while `--help` exits 0.

The `load_paid_media` guard (one per skill script, near the top but NOT executed at load) sources `$PROJECT_DIR/.agent0/tools/lib/paid-media.sh` once and fails `exit 70` + `missing kit library lib/paid-media.sh` when absent. It is **called inside** each paid subcommand function (video `sub_prepare`/`sub_submit`/`sub_poll`; image `sub_prepare`/`sub_exec`) — never in the `--help`/`noargs`/`record` path. video's `resolve_tier_field`/`yaml_top` become 1-line binders over `pm_yaml_*` (proven byte-identical); their FAL_KEY checks become `pm_has_fal_key || die_no_fal_key`. image's two FAL_KEY checks become `pm_has_fal_key || die_no_fal_key`; its pipe-table is untouched.

## Files to touch

**Create:**
- `.agent0/tests/capacity-kit/cross-dir-source.sh` — the cross-dir smoke gate (repo-root + consumer-root resolution + absent-lib exit-70-on-paid-while-help-works).

**Modify:**
- `.agent0/skills/video/scripts/gen.sh` — add `load_paid_media`; call it atop `sub_prepare`/`sub_submit`/`sub_poll`; `resolve_tier_field`/`yaml_top` → binders over `pm_yaml_tier_field`/`pm_yaml_top`; FAL_KEY checks (`118`/`172`/`238`) → `pm_has_fal_key || die_no_fal_key`.
- `.agent0/skills/image/scripts/gen.sh` — add `load_paid_media`; call it atop `sub_prepare`/`sub_exec`; FAL_KEY checks (`189`/`272`) → `pm_has_fal_key || die_no_fal_key`. TIER_TABLE untouched.
- `.agent0/context/rules/capacity-kit.md` — note skill-dir tools (video/image) now consume the paid kit via the `$PROJECT_DIR` anchor + lazy-load; cross-dir smoke gate added; the 164 video/image reopen-trigger is CLOSED.
- `CLAUDE.md` — Capacity kit section: video/image now on the paid kit (cross-dir, lazy-loaded); spec 165.
- `docs/specs/165-*/notes.md` — in-flight memory.

**No change (verify, don't edit):**
- `.agent0/tools/lib/paid-media.sh` — consumed as-is; no new helpers.
- `golden.sh`/`paid-golden.sh`/`sync-propagation.sh`/`missing-kit-guard.sh` — must still pass (sound/audio unaffected; libs still ship).

## Alternatives considered

### `$BASH_SOURCE`-relative source (`../../../tools/lib/...`)

Rejected: brittle (breaks if the script moves) and NOT the anchor the files already trust. `$PROJECT_DIR` is what both already use for `fal-rest.sh` — robust in repo and consumer (= consumer root). Both meeting runtimes converged on `$PROJECT_DIR` independently.

### Source the lib at file-top (like sound/audio)

Rejected: a behavior change. video/image have non-paid lanes (`--help`/`noargs`/`record`) that work today with no lib; a top-level source would make `--help` fail (exit 70) when the lib is absent. Lazy-load inside paid subcommands preserves them. (sound/audio can source at top because they are paid from the first line.)

### Convert image's pipe-table to YAML so it can use `pm_yaml_*`

Rejected: it CREATES net-new surface (a new oracle file + docs + tests), does not RETIRE duplication this pass introduces, and has ~zero dedup value (one tool, one table). Leaving the pipe-table leaves zero loose ends from this work. Its own spec if ever justified.

## Risks and unknowns

- **video reader byte-identical** — retired: proven for every field video reads over `video-tiers.yaml` before planning. Golden + `tests/video/` are the standing proof.
- **`load_paid_media` placement** — must be inside the paid subcommand FUNCTIONS, after arg parse but before the first `pm_*` call. Confirm `staleness_advisory` (uses `yaml_top`) is only reached from a paid path; if it can run pre-load, its `yaml_top` binder would call an unloaded `pm_yaml_top` → must load before it. (Mitigation: the binder can lazy-load, or the advisory is gated behind load. Resolve in build.)
- **Consumer-layout resolution** — the smoke test's whole job; `$PROJECT_DIR=CLAUDE_PROJECT_DIR` makes it deterministic.

## Research / citations

- `.agent0/meetings/cross-dir-capacity-sourcing-2026-06-07T13-27-06Z/meeting.md` — 8-claim ledger, all anchored; lazy-load + image-scope decisions
- Empirical byte-identical check (this session) — video `resolve_tier_field`/`yaml_top` vs `pm_yaml_*` over `video-tiers.yaml`: model/price/max_duration + snapshot/stale all matched
- `docs/specs/164-paid-media-kit/notes.md` — binder pattern, source-below-help gotcha, pure-helper contract
