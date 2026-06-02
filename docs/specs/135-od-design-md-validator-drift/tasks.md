# 135 — od-design-md-validator-drift — tasks

_Generated from `plan.md` on 2026-06-01. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Red — rewrite `validateDesignMd` tests** in `sync-open-design.test.ts`: accept abbreviated headings (`## 2. Color`), accept wechat-style vocabulary (no literal "layout"/"visual theme"), reject degenerate (no palette / too few sections). Confirmed 3 fail under old validator.
- [x] 2. **Green — reimplement `validateDesignMd`** as the substance gate (unique `#RRGGBB` hex ≥ `MIN_PALETTE_HEX`, `^## ` count ≥ `MIN_H2_SECTIONS`; named problem strings). Consts commented to `generateDsIndex` + step 02. Signature unchanged.
- [x] 3. **Updated the stale doc-comment** + the `cmdApply` failure message (`missing H2: …` → the generic problem list).
- [~] 4. **Phase-A atomic-invariant: verified empirically, not as a unit fixture.** A network-decoupled apply harness would require refactoring the two-phase mechanism — a declared Non-goal. The invariant is structural (the schemaFailures `throw` precedes the Phase B rename loop) and is verified empirically in Verification below (degenerate-perturbation apply), exactly as the original dogfood verified it. See `notes.md` § Deviations.
- [x] 5. Full suite green — 19 pass.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] Tests cover all accepted heading aliases (abbreviated + wechat-style + monochrome) AND rejected malformed shapes (no-palette / truncated / 1-hex) — 20/20 pass.
- [x] `validateDesignMd` no longer references a hand-maintained heading list; required surface is the consumer-derived substance contract (`MIN_PALETTE_HEX`/`MIN_H2_SECTIONS`, commented).
- [x] Real `--apply` of upstream HEAD `bfcac4e0` reached Phase B — 731 files passed Phase A, 648 added / 83 updated / 0 removed, `--verify` OK. Content reverted (founder-gated); pin stays `d25a7aaf`.
- [x] Phase-A failure (spacex/figma at the pre-recalibration floor) preserved the atomic invariant (manifest not updated, staging preserved, live untouched).

## Notes

- Validation surfaced a real calibration bug: `MIN_PALETTE_HEX` 3 → 2 (mono systems spacex/figma). See `notes.md` § Tradeoffs.
- Two-phase atomic invariant empirically confirmed twice this session (wechat under old validator; spacex/figma under new validator pre-recalibration).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
