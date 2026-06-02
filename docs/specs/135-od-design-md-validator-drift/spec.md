# 135 — od-design-md-validator-drift

_Created 2026-06-01._

**Status:** shipped (implemented + validated 2026-06-01, commit `884724c`. Residual pin-advance content ingestion is founder-gated, out of scope.)

## Intent

The `/product` OD vendor-sync engine (`.claude/skills/product/scripts/sync-open-design.ts`) validates every `DESIGN.md` it stages during `--apply` against `REQUIRED_H2_SUBSTRINGS = ['color palette', 'typography', 'component', 'layout', 'visual theme']` (Phase A, `validateDesignMd`). The first real `--apply` dogfood against upstream HEAD `bfcac4e0` (2026-06-01) found that ~60 of the upstream design-systems now fail this gate: newer systems (`flat`, plus the bulk of the catalogue) ship `## 2. Color` instead of the older `## 2. Color Palette & Roles`, so the literal `'color palette'` substring no longer matches — and `wechat` additionally lacks `layout` and `visual theme` headings. The net effect: **a real `--apply` of current upstream is hard-blocked** by the validator, even though the heading rename is a legitimate upstream convention change. This was masked until now because the idempotence short-circuit (content unchanged → no-op) and the `--check` truncation false-negative (Bug A, fixed in the same dogfood session) both prevented `--apply` from ever reaching Phase A. We need to decide whether the validator should track upstream's looser heading convention, while still catching genuinely malformed DESIGN.md files (like `wechat`'s missing sections), so the OD sync can actually advance its pin again.

**Effort: M.** This is not a one-line substring loosen — it requires a consumer audit (preflight), a policy decision, `wechat` disposition, an alias/source-of-truth mechanism, and real `--apply` verification. The work splits into a **preflight decision task** (resolve Q1/Q2 from the audit) and a **code-change task**.

### Preflight (must complete before any code change) — ✅ DONE 2026-06-01 (see `notes.md` § Design decisions)

- [x] **Consumer inventory recorded** — catalogued in `notes.md`. **Machine-parsed:** `generateDsIndex` reads only `mood` (first non-`category` blockquote / `#` title fallback) + `palette_summary` (first 6 `#RRGGBB` hex); reads no H2 text. **LLM-read:** step 02-prototype `Read`s the whole file as prose (robust to heading renames), takes palette tokens verbatim (= hex). **No consumer depends on the literal `'color palette'` substring.**
- [x] **Q1 policy decided + recorded** — **substance gate** (refined (a)): replace the exact-phrase `REQUIRED_H2_SUBSTRINGS` with a consumer-derived check (≥ `MIN_PALETTE_HEX` hex + ≥ `MIN_H2_SECTIONS` headings, any name). Rationale + rejected alternatives in `notes.md`. _(Founder may veto — nothing committed.)_
- [x] **Q2 `wechat` disposition** — **pass.** `wechat` @ HEAD has `## Color Palette`/`## Typography`/`## Components`, 15 hex, 8 sections; it only lacks the literal words "layout"/"visual theme" (uses `## Spacing System`/`## Brand Identity`). Valid vocabulary, not a defect.

### Behavior

- [x] **Scenario: validation reflects the decided policy, not a smuggled default** — policy = substance gate (the consumer-grounded decision, not a one-substring edit). Abbreviated-heading systems now pass; the gate's required surface is the consumed surface. ✅
  - **Given** an upstream `DESIGN.md` using the abbreviated headings (`## 2. Color`, `## 5. Layout & Composition`, `## 1. Visual Theme & Atmosphere`)
  - **When** `--apply` stages it in Phase A
  - **Then** it passes (substance present); verified — the real `--apply` passed all such systems.

- [x] **Scenario: genuinely malformed DESIGN.md is still rejected** — verified empirically: the validation `--apply` rejected `spacex`/`figma` at the 3-hex floor and the Phase-A failure preserved the atomic invariant (manifest not updated, staging preserved, live untouched) before the floor was recalibrated. Degenerate (no-palette / too-few-sections) shapes covered by unit tests. ✅
  - **Then** validation fails AND the two-phase atomic invariant holds (live vendor untouched, manifest not updated, staging preserved)

- [x] **Section contract has a named source of truth** — `MIN_PALETTE_HEX` / `MIN_H2_SECTIONS` constants in `sync-open-design.ts`, commented to trace to `generateDsIndex` (mood+hex) + step 02-prototype (prose). No hand-maintained heading list, no per-system allowlist. _(Resolves Q3.)_ ✅

- [x] **Tests** — `validateDesignMd` unit-tested across abbreviated + wechat-style + monochrome accepted shapes and degenerate (no-palette / truncated / 1-hex) rejected shapes. 20/20 pass. Phase-A atomic invariant verified empirically (see `notes.md` § Deviations — a unit fixture would require refactoring the Non-goal two-phase mechanism). ✅

- [x] **Real `--apply` of upstream HEAD reaches the decided outcome** — verified 2026-06-01: a forced real `--apply` of HEAD `bfcac4e0` passed Phase A for all 731 staged files and reached/completed Phase B ("Validation passed (731 files) … Done: 648 added, 83 updated, 0 removed"); `--verify` OK. Closes the residual of `r-2026-05-18`. The wholesale content ingestion was then reverted (founder-gated per Non-goals); the pin remains `d25a7aaf`. ✅

## Non-goals

- The `--check` 300-file compare truncation false-negative (Bug A) — fixed separately in the same dogfood session (`resolveChangedVendoredScope`); not re-litigated here.
- Reworking the two-phase atomic apply mechanism — the dogfood confirmed it holds correctly under a Phase-A failure; no change needed.
- Changing which upstream design-systems are vendored (the `vendored_paths` set) or adding new ones.
- **Committing the wholesale vendored-content update** that advancing the pin from `d25a7aaf` → HEAD produces (a month of upstream visual changes across ~72 design-systems). This spec delivers the validator fix and *demonstrates* a clean apply; whether to actually ingest+commit that large content diff — which changes `/product` visual output — is a separate founder-reviewed decision, not bundled here.

## Open questions

- [x] **Q1 (RESOLVED 2026-06-01):** Nothing in the pipeline consumes the exact H2 heading text — `generateDsIndex` reads mood+hex, step 02-prototype reads prose. **Decision: substance gate** (≥ `MIN_PALETTE_HEX` hex + ≥ `MIN_H2_SECTIONS` headings of any name), replacing `REQUIRED_H2_SUBSTRINGS`. The contract is the consumed surface (Q3). Full rationale + rejected (b)/(c)/naive-(a) in `notes.md`.
- [x] **Q2 (RESOLVED 2026-06-01):** `wechat` is a different-but-valid vocabulary, not a defect → **passes** the substance gate. No upstream filing. The end-to-end criterion expects `wechat` (and the abbreviated-heading systems) to pass.
- [x] **Q3 (RESOLVED 2026-06-01):** Source of truth = the consumer-derived substance contract, documented inline at the validator (`MIN_PALETTE_HEX` / `MIN_H2_SECTIONS` constants with a comment tracing them to `generateDsIndex` + step 02). No hand-maintained heading list, no per-system allowlist.
- [ ] **Residual (founder, post-merge):** whether to actually commit the wholesale pin advance (the ~72-system content ingestion) — out of scope here (see Non-goals).

## Context / references

- `.claude/skills/product/scripts/sync-open-design.ts` § `REQUIRED_H2_SUBSTRINGS` / `validateDesignMd` / `cmdApply` Phase A
- `docs/specs/049-od-vendor-port-to-skill/` — the OD vendor port this validator lives in
- Reminder `r-2026-05-18` (now closed) — the dogfood that surfaced this; write-paths exercised end-to-end 2026-06-01
- Dogfood evidence: upstream `d25a7aaf` → `bfcac4e0`; `flat/DESIGN.md` uses `## 2. Color`; live `claude/DESIGN.md` (vintage) uses `## 2. Color Palette & Roles` and passes
