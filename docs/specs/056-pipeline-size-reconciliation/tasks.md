# 056 — Tasks

1. [x] Resolve open question #1 — **DECIDED: `schema.md` is canonical** (single source per step). `delegation-briefs.md` and `pipeline-coverage.md` reference it.
2. [x] Resolve open question #2 — **DECIDED: soft ceiling at `max_size × 1.2`** → sub-agent partial-result with `oversize_reason` field. Hard ceiling rejected to avoid validator-cascade risk (per spec 057).
3. [x] Resolve open question #3 — **DECIDED: backfill empirical** across dogfood-v3 (spec 045) + dogfood-erp (spec 048 #1) + dogfood-vet (Vetro). Calibration data in `notes.md`.
4. [x] Run calibration: measured standard-tier output of steps 02 / 03 / 08 / 09 / 10 / 15a across 3 dogfoods. See `notes.md § Calibration data`.
5. [x] Decide reconciled values per step. See `notes.md § Reconciled targets`.
6. [x] Edit `templates/pipeline/02-prototype/schema.md`: added `## Target` block (10-30 KB) + JSON `max_size: 30720` on direction-{a,b,c}.html.
7. [x] Edit `templates/pipeline/03-spec/schema.md`: added `## Target` block (12-30 KB); JSON `min_size` lowered 15→12 KB + `max_size: 30720`.
8. [x] Edit `templates/pipeline/08-system-design/schema.md`: added `## Target` block (15-42 KB); JSON `min_size` lowered 20→15 KB + `max_size: 43008`.
9. [x] Edit `templates/pipeline/09-legal/schema.md`: added `## Target` block with CONDITIONAL model (base + DPIA + AI + Regulated); JSON `min_size` lowered 9→5 KB + `max_size: 30720` (effective floor computed per profile).
10. [x] Edit `templates/pipeline/10-roadmap/schema.md`: added `## Target` block (6-18 KB); JSON `min_size` lowered 8→6 KB + `max_size: 18432`.
11. [x] Edit `templates/pipeline/15-screen-atlas/schema.md`: added `## Target` block (10-28 KB); JSON unchanged floor + `max_size: 28672` on atlas + `max_size: 18432` on REPORT.
12. [x] Edit `delegation-briefs.md`: 6 step briefs (Steps 02, 03, 08, 09, 10, 15a) now reference `schema.md § Target` instead of hardcoding sizes. DONE_WHEN lines updated to cite schema range.
13. [x] Edit `pipeline-coverage.md § Per-step size targets`: table promoted to derived-view; 6 calibrated steps marked ✓ 056 + reconciled sizes; 9 legacy steps labeled `(legacy — 056 phase 2)` for future calibration; uniform soft-ceiling discipline stated.
14. [ ] Run a verification dogfood (single fresh idea) and confirm ≥ 80% of outputs land in `[min_size, max_size]` for the 6 reconciled steps. **Deferred to next /product invocation** — 056 ships docs-only.
15. [ ] Commit: `feat(056): pipeline size reconciliation — schema canonical, 3-dogfood empirical backfill`.
