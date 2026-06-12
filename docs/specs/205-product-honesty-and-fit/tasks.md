# 205 — product-honesty-and-fit — tasks

_Generated from `plan.md` on 2026-06-12. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Verify:** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product && bun test ./.claude/skills/product/scripts/staleness-check.test.ts`

## Implementation

- [x] 1. `references/state-machine.md` — v6 contract: version-history entry, `product_form` field, `gate_concept` in progression + Gate UX + `gates_passed`/`iterations`, resume refuses v5
- [x] 2. `references/product-forms.md` (new) — 5-form taxonomy; per form: Step 07 category set, Step 02 mood variant, Step 14 scope, Phase 4 contract artifacts; `screen-app` default reproduces v0.5.0 behavior
- [x] 3. `templates/pipeline/01-ideation/{prompt,schema}.md` — add required `§ Product Form` (enum + rationale); reframe `§ Market Sizing` as hypothesis with cited sources + explicit uncertainty
- [x] 4. `templates/pipeline/03-spec/{prompt,schema}.md` — replace `§ Problem-Validation Interviews` with `§ Assumption Register` (4-risk classification, confidence + rationale, riskiest-assumption test recipe, abandon-signal; advice-only framing)
- [x] 5. `templates/pipeline/10-roadmap/{prompt,schema}.md` — projection disclaimer block (pre-validation, phase-1-only confidence, re-derive note)
- [x] 6. `templates/pipeline/11-cost-estimate/{prompt,schema}.md` — projection disclaimer + all monetary/effort figures as ranges
- [x] 7. `templates/pipeline/12-gtm-launch/{prompt,schema}.md` — projection disclaimer block
- [x] 8. `templates/pipeline/07-sitemap-ia/schema.md` + `references/sitemap-schema.md` — category set resolved per product form (enforcement mechanics unchanged)
- [x] 9. `references/quality-judge.md` — per-phase batch dispatch (one call, N per-unit verdict files), `cross-consistency` criterion, model-mix table (P1/P3 sonnet, P2/P4 opus, provisional), § Measurement protocol + revert path
- [x] 10. `references/quality-checklist.md` — new/updated criteria: 01 market-sizing-as-hypothesis + product-form-declared, 03 assumption-register, 10/11/12 projection-disclaimer (+ ranges for 11)
- [x] 11. `references/delegation-briefs.md` — update briefs: 01 (form + sizing framing), 03 (register), 10/11/12 (disclaimer/ranges), 02/07/14/15 (`{{product_form}}`), quality-judge (batch + mix); also Step 06 OST brief consumes the register with confidence tags
- [x] 12. `references/pipeline-coverage.md` — step table rows 01/03/10/11/12; form-awareness notes on 02/07/14/15
- [x] 13. `SKILL.md` — v0.6.0: frontmatter; Phase 0 state v6 init + v5 refusal; Phase 1 `gate_concept` after Step 01 + `product_form` capture; § Quality judge batching + mix; gates gain distilled review-agenda shape; Phase 4 form-variant dispatch; Phase 5 handoff mentions staleness checker; eval scenarios updated
- [x] 14. `scripts/staleness-check.ts` (new) — read `.state.json` + artifact mtimes + US-NN grep; print stale artifacts + `--from-step=NN` refresh hint; read-only
- [x] 15. `scripts/staleness-check.test.ts` (new) — stale detection, US-NN matching, no-mutation, clean-tree silence

## Verification

- [x] 16. `bun test ./.claude/skills/product/scripts/staleness-check.test.ts` green (11 pass / 0 fail)
- [x] 17. `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exit 0 (fixed a PRE-EXISTING frontmatter failure: `argument-hint` was never valid YAML — quoted now; description trimmed to ≤1024 chars; rule8 body-token warn is pre-existing and advisory)
- [x] 18. Cross-file consistency sweep — no surviving v5-init references; interview mentions survive only as historical "replaced X" notes; consumers (05-prd, 06-ost) now read the Assumption Register; `.agent0/tests/product-overwrite` 5/5 PASS; full harness battery 44/44 PASS
- [x] 19. Acceptance check against `spec.md` — all criteria ticked EXCEPT the Change-2 measurement-run scenario (requires a real ~3M-token dogfood run; mechanism + protocol shipped, run recorded as residual)

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
