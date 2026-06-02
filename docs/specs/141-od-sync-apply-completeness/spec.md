# 141 — od-sync-apply-completeness

_Created 2026-06-02._

**Status:** in-progress (implemented + validated 2026-06-02; uncommitted — pending founder commit)

## Intent

The 2026-06-02 OD pin advance (`d25a7aaf → c128ffd5`, 73 → 150 systems, shipped in `5233ab3`) surfaced **two correctness gaps** in `.claude/skills/product/scripts/sync-open-design.ts` that made the advance impossible via the normal `--bump` + `--apply` path and required a manual workaround + a hand-run catalogue regen. Both are real bugs in the engine whose ONE job is "advance the vendored Open Design catalogue." This spec fixes them so a future pin advance is a clean two-command operation with no workarounds. It deliberately does NOT restructure the OD vendor (that is the separate, founder-gated OD-vendor-extraction work, `r-2026-06-01`); it makes the existing engine correct.

## Acceptance criteria

- [x] **Scenario: a `--bump` followed by `--apply` reconciles content without a workaround**
  - **Given** the vendored content on disk matches the OLD pin, and `--bump <new-sha>` has updated `pinned_sha` (but not the vendored-path checksums)
  - **When** `--apply` runs
  - **Then** it detects that on-disk content differs from the NEW pin's tarball and performs the full reconcile — without needing a perturbed vendored file to defeat the idempotence gate

- [x] **Scenario: idempotence compares on-disk against the pinned tarball, not the stale manifest**
  - **Given** any pin state
  - **When** the idempotence check runs
  - **Then** "already in sync" means on-disk content == the content at `pinned_sha` (computed from the tarball, including recursive trees via tree-checksum), NOT on-disk == the manifest's last-recorded checksums. A genuine no-op (on-disk already == pinned content) still short-circuits before re-staging

- [x] **Scenario: recursive vendored trees are content-compared in the idempotence check**
  - **Given** a recursive vendored path (`design-systems/`, `skills/`, `frames/`) whose on-disk tree differs from the pinned tarball's
  - **When** the idempotence check runs
  - **Then** it computes the on-disk tree-checksum (`computeTreeChecksum` over per-file hashes) and detects the difference — the current `if (vp.recursive) continue` blind-skip is removed

- [x] **Scenario: `--apply` regenerates the pipeline-facing catalogue**
  - **Given** an `--apply` that adds/updates/removes systems
  - **When** it completes
  - **Then** `references/od-catalog-index.json` (the index steps 02-prototype and 14-design-system actually `Read`) is regenerated to match the new system set — preserving existing curated entries (category / mood / palette_primary) verbatim and adding new entries mechanically (`category` from each `DESIGN.md` `> Category:` line, `mood` + first palette hex from the DESIGN.md / ds-index). Today `--apply` only writes `vendor/open-design/.cache/ds-index.json`, leaving the pipeline-facing catalogue stale → new systems invisible to `/product`

- [x] **Scenario: hardcoded system counts don't silently rot**
  - **Given** the catalogue size changes
  - **When** `--apply` completes
  - **Then** EITHER the doc references stop hard-coding a count (preferred — "the vendored systems catalogued at …") OR the apply report flags the stale-count doc lines. (The 73→150 advance left ~6 doc strings to hand-fix.)

## Non-goals

- Restructuring or extracting the OD vendor out of `/product` — that is the separate founder-gated `r-2026-06-01` OD-vendor-extraction; this spec only makes the in-place engine correct.
- Re-curating the 78 mechanically-generated catalogue entries to the fidelity of the 72 hand-curated ones (e.g. named `palette_primary` like "Rausch (#ff385c)" instead of a bare hex). A later quality pass can enrich them; mechanical is the functional floor.
- Changing the substance-gate validation (spec 135 owns that and it worked correctly here).
- Auto-advancing the pin on a schedule — pin advance stays a deliberate founder action.

## Open questions

- [ ] Should the catalogue regen live in the engine (`--apply` calls it) or be a separate `--gen-catalog` subcommand the apply invokes? Resolve at `/sdd plan`.
- [ ] Should the pipeline read `.cache/ds-index.json` directly (one index) instead of maintaining the separate curated `od-catalog-index.json`? That would delete the whole second-index problem but lose the curated `category`/`palette_primary` fields. Plan-time decision.
- [ ] Idempotence after-download cost: the corrected check must download the tarball to compare. Acceptable (a pin advance is rare + deliberate), but confirm the no-op case (re-running `--apply` at an already-applied pin) stays cheap — cache the tarball, or compare a cheap upstream tree-sha first.

## Context / references

- `5233ab3` — the OD pin advance that surfaced both bugs; its commit message documents the workaround used.
- `.claude/skills/product/scripts/sync-open-design.ts` §§ idempotence check (lines ~429-446, the `if (vp.recursive) continue` + manifest-compare), `--apply` Phase A/B (full reconcile, correct), `computeTreeChecksum` (line ~100, sorted → order-independent — reuse for the on-disk tree compare).
- `references/od-catalog-index.json` (pipeline-facing, curated) vs `vendor/open-design/.cache/ds-index.json` (engine cache) — the two-index split; steps `templates/pipeline/{02-prototype,14-design-system}/` `Read` the former.
- `docs/specs/135-od-design-md-validator-drift/` — prior engine spec; its notes already flagged "idempotence guard short-circuits otherwise" as the reason the 135 dogfood perturbed a file. This spec fixes the root cause 135 worked around.
- One-off regen used this session: `/tmp/gen-catalog.py` (preserve-curated + mechanical-new logic) — the reference implementation for the in-engine regen.
