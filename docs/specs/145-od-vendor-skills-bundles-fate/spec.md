# 145 — od-vendor-skills-bundles-fate

_Created 2026-06-03._

**Status:** shipped (2026-06-03 — DROP decided by founder; `skills/` tree + `vendored_paths[]` entry removed; `--verify` green, 46/46 engine tests pass)

## Intent

Decide whether the `.claude/skills/product/vendor/open-design/skills/` subtree (**729** of the 747 files under `vendor/open-design/`) should keep being vendored + propagated to every consumer, given that **no live file in the `/product` pipeline reads it**. Surfaced 2026-06-03 during spec 144 review. A per-subdir audit (grep across all 98 non-vendor/non-engine skill files, **including `templates/pipeline/`**) found that most of `vendor/open-design/` IS consumed and must stay — only the `skills/` bundle tree is unreferenced:

| `vendor/open-design/` subdir | files | pipeline-consumed? | how |
|---|---|---|---|
| `prompts/` (directions/discovery/system.ts) | 6 | **yes** | Step 02 `Read`s — "source of truth" for the 5 design schools (`templates/pipeline/02-prototype/{prompt.md,references/od-bridge.md}`) |
| `frames/` (iphone/macbook/browser .html) | 6 | **yes** | Step 02 device-chrome wrappers |
| `templates/deck-framework.html` | 1 | **yes** | Step 02 pitch-deck template |
| `.cache/ds-index.json` | 1 | **yes** (intermediate) | catalogue-gen reads it → `references/od-catalog-index.json`; regenerable from `design-systems/` |
| `MANIFEST.json` + `LICENSE` + `NOTICE` | 3 | engine/attribution | sync engine bookkeeping + Apache-2.0 |
| **`skills/`** | **729** | **NO** | referenced only by the vendor tree itself, `sync-open-design.ts`, and `runtime/od-sync/` logs |

So the question is narrow and specific: **`vendor/open-design/skills/` (729 files) — keep or drop?** It is an active `vendored_paths[]` entry (remapped `src: skills/ → design-templates/` by spec 143) and is covered by the engine's `--verify`, so dropping it is a real change to the OD-engine's manifest + verify scope, not a plain `rm`. This is **investigate-then-decide**, founder-gated; nothing is removed without confirming intent and working out the `--verify` consequence. _(Note: the sibling `design-systems/` tree — 150 `DESIGN.md` — is the primary consumed OD content and is entirely out of scope here.)_

## Acceptance criteria

- [x] **Scenario: the "not read by pipeline" verdict for `skills/` is confirmed beyond a static grep**
  - **Given** the hypothesis that `vendor/open-design/skills/` (729 files) is never read at generation runtime
  - **When** the audit checks all pipeline step files (`templates/pipeline/**`), `SKILL.md`/`references/` prose for ad-hoc `Read` directions, and any dynamic path construction
  - **Then** it produces a definitive read / not-read verdict for `skills/` specifically, with evidence, distinguishing engine/log references from pipeline references

- [x] **Scenario: original intent for the `skills/` bundles is established from history**
  - **Given** specs 027 / 049 / 143 + the anthill ADR (`adr-vendor-open-design.md`)
  - **When** the audit reads them
  - **Then** it states whether the `skills/` bundle tree was vendored as (a) intended consumed material that was never wired, (b) attribution/provenance-only upstream mirror, or (c) future-use latent material — citing the text

- [x] **Scenario: the decision is made and, if "drop", scoped against the OD-engine**
  - **Given** the verdict + intent finding
  - **When** the decision is taken
  - **Then** it is KEEP (with `SKILL.md`/`harness-sync` documenting *why* a pipeline-unread tree is retained) OR DROP (remove the `skills/ ← design-templates/` entry from `MANIFEST.json` `vendored_paths[]` + the dst tree), with the `sync-open-design.ts --verify`/`--apply` consequence worked out and a passing engine test, and Apache-2.0 attribution preserved regardless

- [x] Quantify the carry cost: `729 files × N consumers` propagated for a pipeline-unread tree — the concrete motivator.

- [x] The rest of `vendor/open-design/` (`prompts/`, `frames/`, `templates/`, `.cache/`, manifest, license) is confirmed in-use and explicitly retained — the audit does not touch it.

## Non-goals

- Spec 144's git-aware walk — already shipped (`528c475`); separate concern.
- Touching `design-systems/` (150 `DESIGN.md`) — the primary consumed tree, out of scope.
- Touching the in-use `vendor/open-design/{prompts,frames,templates,.cache,MANIFEST.json}` — confirmed consumed; retained.
- Removing the OD sync engine or changing the vendoring mechanism — at most this edits one `vendored_paths[]` entry.
- Dropping Apache-2.0 `LICENSE`/`NOTICE`/attribution — preserved under every outcome.

## Open questions

- [x] **Is `vendor/open-design/skills/` truly unread, or is there a prose-directed ad-hoc `Read` I haven't found?** Static evidence (98-file grep incl. `templates/pipeline/`) says only the engine/logs reference it; confirm.
- [x] **Why was the `skills/` bundle tree vendored (027/049) — consumed-but-unwired, provenance, or latent?** If provenance/latent-by-design, KEEP + document; if consumed-but-unwired, decide wire-it-up vs drop.
- [x] **What exactly breaks on DROP?** Removing the `skills/ ← design-templates/` `vendored_paths[]` entry changes `--verify` scope and the 143 remap's target. Notably, spec 141's notes flag that `vendor/open-design/skills/` is the one path that *fails* `--verify` (orphan drift) — does dropping it actually *simplify* the engine? Work it out before cutting.
- [x] **Owner / resolution path:** founder decides KEEP vs DROP on the intent question (same author who shaped 027/049). The audit gathers evidence; the founder calls it.

## Context / references

- Trigger: spec 144 review (2026-06-03). Per-subdir audit: `/product` Step 02 (`templates/pipeline/02-prototype/{prompt.md,references/od-bridge.md}`) reads `prompts/`, `frames/`, `templates/`; catalogue-gen reads `.cache/ds-index.json`; nothing reads `skills/`.
- `docs/specs/049-od-vendor-port-to-skill/spec.md` § Intent — "`vendor/` = Apache-attributed upstream, `design-systems/` = consumed" sibling-split (KEEP counter-hypothesis).
- `docs/specs/027-od-vendor-port/`, `143-od-vendor-skills-remap/` — vendoring history; `skills/ ← design-templates/` src remap.
- `docs/specs/141-od-sync-apply-completeness/notes.md` — `vendor/open-design/skills/` is the path that fails `--verify` (orphan drift); relevant to the DROP-simplifies-engine question.
- `.claude/skills/product/vendor/open-design/MANIFEST.json` § `vendored_paths` — the `skills/ ← design-templates/` entry to be kept or removed.
- anthill ADR `.anthill/memory/architecture/adr-vendor-open-design.md` (if reachable) — origin of the sibling-split pattern.

## Resolution (2026-06-03)

**DROP — founder-decided.** `vendor/open-design/skills/` (729 files) was confirmed pipeline-unread (no `templates/pipeline/**`, `SKILL.md`, or `references/` reference; only the engine + runtime logs). Removed the `skills/ ← design-templates/` entry from `MANIFEST.json` `vendored_paths[]` and `git rm`'d the dst tree. Result: `--verify` green (7→6 paths; `skills/` was the path that *failed* verify per spec 141 notes, so the engine is now strictly cleaner), 46/46 engine unit tests pass. Retained: `design-systems/` (150), `vendor/open-design/{prompts,frames,templates,.cache,MANIFEST.json,LICENSE,NOTICE}`. Apache-2.0 attribution intact. `SKILL.md` § OD-vendor note updated. Each consumer drops the 729 files on next harness sync (clean orphans).
