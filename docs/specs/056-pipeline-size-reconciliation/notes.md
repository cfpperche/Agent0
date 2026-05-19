# 056 — In-flight notes

## Design decisions

### 2026-05-19 — parent — OQ-1 resolution: schema.md is canonical

**Decided:** each step's `templates/pipeline/<NN>/schema.md § Target` block is the single source of truth for size budgets. `delegation-briefs.md` and `pipeline-coverage.md` REFERENCE it; if a budget needs to change, the schema is the only edit site.

**Why:** schemas are self-contained per spec 033 portability (agentskills.io alignment) — they need to carry their full contract. Briefs are orchestration prose; pipeline-coverage is a derived overview. Single source per step + downstream references is the canonical "DRY for design memory" shape.

### 2026-05-19 — parent — OQ-2 resolution: soft ceiling at max × 1.2

**Decided:** exceeding `max_size × 1.2` triggers sub-agent partial-result with `oversize_reason` field naming what bloated. NOT a hard abort.

**Why:** hard ceilings cascade into the validator-cascade problem spec 057 is solving. Sub-agents auto-fixing oversize during the parent's fan-out wave creates ratchet failures across siblings. Partial-result with explicit reason lets the parent see + handle in a single decision point (typically by allowing the oversize OR re-dispatching with augmented brief).

The 20% number is empirical: dogfood-erp's Step 03 functional-spec at 64.8 KB sits at 2.16× the 30 KB ceiling, so 1.2× trigger fires correctly; dogfood-v3/vet at 21.9 KB sit well within band.

### 2026-05-19 — parent — OQ-3 resolution: backfill empirical (confirmed by user)

**Decided:** measure standard-tier output across 3 dogfoods (v3 / erp / vet) — see § Calibration data.

**Why:** intuition-only would reproduce the same mismatched ceilings that motivated this spec. Empirical numbers from real dogfoods give defensible ranges + named outlier cases.

## Calibration data

Measured 2026-05-19 from `/tmp/dogfood-{v3,erp,vet}/docs/`:

| Step | dogfood-v3 (KB) | dogfood-erp (KB) | dogfood-vet (KB) | Notes |
|---|---|---|---|---|
| 02 direction-a.html | 23.0 | 48.8 | 23.8 | dogfood-erp outlier (verbose sub-agent run) |
| 03 functional-spec.md | 21.9 | 64.8 | 21.9 | dogfood-erp severely over (would trigger partial-result) |
| 08 system-design.md | 15.2 | 40.0 | 32.8 | dogfood-v3 at the floor — old 20 KB floor would have BLOCKED it |
| 09 legal-posture.md | 6.9 | 6.8 | 18.8 | bimodal: base 7 / DPIA 19 (Vetro has PII → DPIA fires) |
| 10 roadmap.md | 7.9 | 14.6 | 14.6 | dogfood-v3 under old 8 KB floor — compact-product legit |
| 15a screen-atlas.md | 13.9 | 25.3 | 19.4 | within band; ceiling at 28 KB accommodates venture-scale |

**Product scale (for calibration interpretation):**
- dogfood-v3 = ClaudeOps (SMB SaaS → venture devtool, AI-native)
- dogfood-erp = SalãoOS (SMB SaaS BR vertical, no AI)
- dogfood-vet = VetUno (SMB SaaS BR vertical, PII-heavy → DPIA, no AI)

All 3 are SMB SaaS scale. dogfood-erp's consistent 2-3× larger output is sub-agent verbosity, not product complexity. Soft-overshoot trigger catches it correctly.

## Reconciled targets

| Step | Old (schema floor / brief ceiling) | Reconciled `min_size / max_size` | Calibration |
|---|---|---|---|
| 02 direction-a | 10 KB / 6-12 KB | **10 KB / 30 KB** | actuals 23-49; ceiling at median + reasonable spread; outlier hits soft-overshoot |
| 03 functional-spec | 15 KB / 8-12 KB | **12 KB / 30 KB** | floor lowered (dogfood-v3-class can land at 12-15 KB legit); ceiling accommodates 22-KB median |
| 08 system-design | 20 KB / 12-18 KB | **15 KB / 42 KB** | floor lowered (dogfood-v3 at 15.2 KB legit); ceiling accommodates venture-scale (40 KB) |
| 09 legal-posture | 9 KB / 4-7 KB | **CONDITIONAL: base 5-10 KB + DPIA +5/+12 + AI +2/+5 + Regulated +2/+8** | bimodal data demanded conditional model |
| 10 roadmap | 8 KB / 5-8 KB | **6 KB / 18 KB** | floor lowered; ceiling raised from 8 → 18 (medians 14-15) |
| 15a screen-atlas | 10 KB / ≥ 8 KB | **10 KB / 28 KB** | floor unchanged; ceiling added (currently no ceiling existed) |

## Deviations

### 2026-05-19 — parent — phased rollout: 6 of 15 steps calibrated

The spec problem statement listed 6 priority steps (02, 03, 08, 09, 10, 15a) with empirical drift. Spec 056 calibrates exactly those 6 + leaves the other 9 marked `(legacy — 056 phase 2)` in pipeline-coverage.md.

**Why phased:** calibration requires real dogfood data. The 6 priority steps had 3-dogfood evidence. Steps 01/04/05/06/07/11/12/13/14 either lack drift evidence OR their existing budgets matched empirical data (no reconciliation needed). Re-running calibration in phase 2 when fresh dogfood evidence accumulates is cheaper than premature reconciliation now.

### 2026-05-19 — parent — JSON `max_size` field added without parser update

The schemas' Layer 1 JSON blocks declare `required_files: [{path, min_size, contains, ...}]`. Spec 056 adds `max_size` to each entry for the 6 calibrated steps. The standalone `/product` skill does NOT enforce these JSON blocks at runtime (the MCP package validator does, but `/product` v0.3.0 is standalone per spec 048). The `max_size` field is therefore documentation for sub-agents reading the schema, NOT operationally enforced.

**Future:** if the standalone skill ever grows a Layer-1 enforcement (e.g. via the orchestrator post-Step-submit), the `max_size` field is already in place to read. If the MCP package re-syncs from the standalone skill, the parser will need a one-line update to honor `max_size`.

## Tradeoffs

- **Schema canonical vs brief canonical.** Schema wins on portability + self-containment; loses on locality (sub-agent reading the brief has to also read schema for size). Mitigation: brief explicitly cites `schema.md § Target` so the reference is one click away.
- **Soft 1.2× vs hard ceiling.** Soft preserves the fan-out's ability to recover without aborting; loses on tight budget discipline. Mitigation: `oversize_reason` field in partial-result forces explicit acknowledgement; founder/parent sees it in REPORT.
- **Phased rollout vs all-15-at-once.** Phased is honest (we don't have 3-dogfood evidence on the other 9); loses on "single sweep" simplicity. Mitigation: legacy steps clearly labeled in pipeline-coverage.md so the gap is visible.
- **Conditional model for Step 09 only.** Adding conditional sizing only where data demands it; loses on uniformity (Steps 08 + 15 also have conditional content but use a single range). Trade: Step 09's conditional sections are independent toggles (DPIA, AI, Regulated each fire on different signals); 08 + 15 have correlated content that doesn't decompose cleanly.

## Open questions

None remaining at ship — OQ-1/2/3 resolved + calibration empirical.

Forward-looking (for phase 2):

- **Are the 6 reconciled ranges right?** Verify on next dogfood by measuring outputs against new ranges. If ≥80% land in band, the calibration is good; if <80%, re-calibrate the off ones.
- **When to do phase 2?** Trigger condition: 2+ fresh dogfoods after 2026-05-19 surface drift on the 9 legacy steps OR a single dogfood produces wildly-off output on a legacy step. Until then, the (legacy) markers are correct.
- **Should `max_size` be enforced operationally?** Currently documentation-only. If sub-agents ignore it, promote to enforcement via a post-submit orchestrator check. Watch the next 2-3 dogfoods.
