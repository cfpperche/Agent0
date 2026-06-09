# 185 — harness-evolution-program — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom by default, but the maintainer may pick any point for the next detailing round. Check a box only when the point's disposition is recorded; write the disposition inline after the checkbox (e.g. `→ admitted as 186-<slug>`, `→ killed, see notes.md`, `→ decided: <decision>`)._

## Detailing rounds (recommended order)

- [ ] 1. **P7 — CI for harness tests** (fix, mechanical, no gates) — detail → expected disposition: admit small child spec (workflow + `run-all-suites.sh`).
- [ ] 2. **P1 — Evidence bundle as product** (evolve, the strategic bet) — detail format, aggregation points, consumers of the bundle; check overlap with P8.
- [ ] 3. **P2 — Lab vs adoptable asset** (decision, gates P3/P4/P6) — maintainer decision round; record decision + implications in notes.md.
- [ ] 4. **P3 — Multi-runtime posture: portable core + reference runtime** (decision, contradicts doctrine) — decision-grade debate (`/sdd debate` on a position child spec, or meeting), then disposition.
- [ ] 5. **P4 — Shrink the prose control plane** (optimize) — inventory rules by prose-vs-mechanism; propose migration list + numeric target; conditional on P2.
- [ ] 6. **P5 — Hook-chain latency** (optimize, measure-first) — measure p50/p95 of Pre/PostToolUse chains; disposition depends on numbers.
- [ ] 7. **P8 — Hook supply-chain integrity** (fix) — checksum manifest + doctor verification; check whether P1's bundle format subsumes it.
- [ ] 8. **P6 — Kernel out of bash** (optimize, XL, gated by P2) — only detail after P2 decided; expected: admit-deferred or kill if P2 = lab.

## Verification

- [ ] Every P1–P8 box above carries an inline disposition (spec.md scenario 1).
- [ ] P2 has an explicit maintainer decision and P3 has a decision-grade debate record (or explicit recorded override) before any related child spec exists (spec.md scenario 2).
- [ ] Each round's analysis exists in a child spec or in `notes.md` — spot-check: no disposition whose only trace is chat history (spec.md scenario 3).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
