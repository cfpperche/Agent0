# 165 — cross-dir-capacity-sourcing

_Created 2026-06-07._

**Status:** shipped

<!-- Optional — declare when this spec produces UI; drives the visual-contract acceptance gate (spec 155). Omit or keep `none` for non-UI work. See .agent0/context/rules/visual-contract.md -->
**UI impact:** none

## Intent

The named reopen-trigger from spec 164, opened by founder directive. Spec 164 migrated the two **tools-dir** paid tools (`sound`, `audio --remote`) onto `lib/paid-media.sh` but left the two **skill-dir** paid tools (`video`, `image`) out, because a skill-dir script sourcing `tools/lib` was an unvalidated cross-dir dependency. This pass validates that pattern with a dedicated smoke test, then migrates `video` (its `*-tiers.yaml` reader → `pm_yaml_*`, FAL_KEY check → `pm_has_fal_key`) and `image` (FAL_KEY check → `pm_has_fal_key`). Measurement collapsed the perceived risk: both skill-dir scripts **already** anchor on `$PROJECT_DIR` and **already** cross into `tools/` (they invoke `$PROJECT_DIR/.agent0/tools/fal-rest.sh`); the only new bit is *sourcing* a lib (functions into the shell) vs *invoking* a tool. Same behavior-preserving discipline as 164, plus one cross-dir-specific rule: the lib is **lazy-loaded inside paid subcommands only**, so the non-paid lanes (`--help`/`noargs`/`record`) keep working when the lib is absent. Decision-grade `/meeting` (claude+codex, blind openings converged independently — `.agent0/meetings/cross-dir-capacity-sourcing-2026-06-07T13-27-06Z/`).

## Acceptance criteria

- [x] **Scenario: skill-dir tool sources the shared lib via the `$PROJECT_DIR` anchor**
  - **Given** `video`/`image` already resolve `$PROJECT_DIR` and use it for `fal-rest.sh`
  - **When** they need the paid helpers
  - **Then** they source `. "$PROJECT_DIR/.agent0/tools/lib/paid-media.sh"` (no `../../../` relative path)

- [x] **Scenario: lazy-load preserves the non-paid lanes**
  - **Given** `video`/`image` `--help`/`noargs`/`record` work today with no lib loaded
  - **When** the lib is sourced via a `load_paid_media` guard called INSIDE paid subcommands only (video `prepare`/`submit`/`poll`; image `prepare`/`exec`)
  - **Then** `--help`/`noargs` still succeed even when the lib is absent; only a paid subcommand fails on absence

- [x] **Scenario: absent lib fails clean on the paid path**
  - **Given** the lib is missing
  - **When** a paid subcommand runs
  - **Then** it exits `70` with `missing kit library lib/paid-media.sh` (kernel precedent), while `--help` still exits 0

- [x] **Scenario: `video` reader migration is behavior-preserving**
  - **Given** `video`'s `resolve_tier_field`/`yaml_top` read `model`/`price_usd_per_second`/`max_duration_seconds` + `snapshot_date`/`stale_after_days`
  - **When** they become 1-line binders over `pm_yaml_tier_field`/`pm_yaml_top`
  - **Then** the values are byte-identical (proven empirically over `video-tiers.yaml`) and every `tests/video/` scenario passes unchanged

- [x] **Scenario: FAL_KEY checks adopt the shared predicate**
  - **Given** `video` and `image` check `[ -z "${FAL_KEY:-}" ] && die_no_fal_key`
  - **When** migrated
  - **Then** the check is `pm_has_fal_key || die_no_fal_key` — each tool keeps its own multi-line `die_no_fal_key` message (pure-helper contract); FAL_KEY value never leaked

- [x] **Scenario: cross-dir smoke test pins the new surface**
  - **Given** a new `tests/capacity-kit/cross-dir-source.sh`
  - **When** it runs
  - **Then** it proves: repo-root resolution, `CLAUDE_PROJECT_DIR`/consumer-root resolution (sentinel consumer lib), and absent-lib `exit 70` on a paid subcommand while `--help` works

- [x] `image`'s pipe-table `TIER_TABLE` is untouched — image gets only `pm_has_fal_key` (it is not YAML; converting it is out of scope)
- [x] `bash -n` clean on `video/gen.sh`, `image/gen.sh`, the new test; `doctor` stays green; existing golden/paid-golden/sync-propagation/missing-kit-guard still pass

## Non-goals

- **No `image` pipe-table → YAML conversion.** Image's tiers are a deliberate pipe-delimited `TIER_TABLE` + a separate aspect table — a different data model. Converting would CREATE a new oracle file + docs + tests, not RETIRE any duplication this pass introduces. Image gets only the FAL_KEY predicate; the table stays. (Its own spec if ever wanted — ~zero dedup value today, one tool/one table.)
- **No file-top sourcing in skill-dir tools.** That would break `--help`/`noargs` when the lib is absent. Lazy-load inside paid subcommands only.
- **No cost-print / cost-gate / async-ledger / body-shape extraction.** Same as 164 — genuine per-tool variants, stay local.
- **No new helpers in `lib/paid-media.sh`.** This pass is consumers of the existing four helpers, not new ones.

## Open questions

- [x] `$PROJECT_DIR` anchor vs `$BASH_SOURCE`-relative? → **`$PROJECT_DIR`** (already used for fal-rest; robust in repo + consumer). Resolved in meeting.
- [x] Source at file-top or lazy? → **Lazy** (`load_paid_media` inside paid subcommands) to preserve non-paid lanes. Resolved.
- [x] Is leaving image's pipe-table a punt? → **No** — converting creates net-new surface, doesn't retire this pass's duplication; zero loose ends left for image. Resolved.

## Context / references

- `.agent0/meetings/cross-dir-capacity-sourcing-2026-06-07T13-27-06Z/meeting.md` — decision-grade meeting (blind openings, 8-claim ledger all anchored, anti-punt minority report); the seed
- `docs/specs/164-paid-media-kit/` — the prior pass; `lib/paid-media.sh` + the behavior-preserving discipline + the named reopen-trigger this resolves
- `.agent0/skills/video/scripts/gen.sh` (readers ~61-85; FAL_KEY ~118/172/238; dispatch ~277-295), `.agent0/skills/image/scripts/gen.sh` (TIER_TABLE ~40-42; FAL_KEY ~189/272; dispatch ~436-468) — migration targets
- `.agent0/tools/lib/paid-media.sh` — the four helpers being consumed
- `.agent0/tests/capacity-kit/{sync-propagation,missing-kit-guard,golden,paid-golden}.sh` — the gate to extend with `cross-dir-source.sh`
