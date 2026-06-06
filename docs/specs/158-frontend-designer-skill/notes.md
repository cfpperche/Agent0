# 158 — frontend-designer-skill — notes

_In-flight design memory. Append-only by convention._

## Design decisions

### 2026-06-05 — parent — Deterministic mechanics vs prompt-driven craft
Split the skill: `scripts/frontend-designer.sh` owns the testable, repeatable parts (caps/detect/artifacts-dir/scaffold-docs/verify); the craft (taste, code, design judgment) is prompt-driven in SKILL.md + references. Keeps the agent free to be the "artist" while detection/paths/verify stay drift-free and unit-tested (20/20).

### 2026-06-05 — parent — verify is a fail-closed thin wrapper, not a new gate
`verify` shells `agent-browser.sh verify-contract` (spec 155) and fail-closes (rc 4, BLOCKER) when `agent-browser route` ≠ primary. No new acceptance machinery — done-proof is spec 155 verbatim. `FD_AGENT_BROWSER` env override makes fail-closed testable with a stub.

## Deviations

_(none — built as planned.)_

## Tradeoffs

### 2026-06-05 — parent — design docs into the target repo (git-tracked)
Chose to write `reference-research.md` + `design-direction.md` into the target project (SDD spec dir or `docs/design/<surface>/`), git-tracked, over a gitignored scratch area. They are decision records, not throwaway. Screenshots/reports stay gitignored evidence. Codex's pressure-test confirmed this for refine mode too (value is grounded judgment, not just CSS edits).

## Open questions

### 2026-06-05 — parent — does `explore` mode earn its place?
`explore` (research + direction, no code) was spec'd narrow and **not** exercised in the dogfood (the matrix covered create ×2 + refine ×1). Re-evaluate after its first real use; risk is it collapses into create's research phase or drifts toward `/product`-lite. Tracked as the one remaining spec open question.

## Dogfood outcome (2026-06-05)

Three `/tmp` demos, all proven (summary: `/tmp/FD-DOGFOOD-SUMMARY.md`):
- **A** `fd-demo-a` — create, web, **reused** existing design system → green `verify-contract` 6/6. Output visibly uses the project's `tokens.json` (zero new colors).
- **B** `fd-demo-b` — refine, web → before **FAIL** 3 / after **PASS** 7/7 (interaction tier); bounded diff (only `checkout.html`, all field ids + submit behavior preserved). The drive-and-see loop caught a real accessible-name bug (trailing space from an `aria-hidden` asterisk span) on iteration 1, fixed iteration 2 — concrete evidence the see-and-critique loop works.
- **C** `fd-demo-c` — create, **native** Expo/RN, no DS → proposed tokens; **native-honesty path**: `node --test` 7/7 over pure logic + token invariants (44pt tap target, 8px spacing), **no visual-contract claimed**, no new native tooling added.

All acceptance scenarios in `spec.md` satisfied; `/skill validate` exit 0; doctor 18 ok.
