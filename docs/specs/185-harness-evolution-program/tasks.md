# 185 — harness-evolution-program — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom by default, but the maintainer may pick any point for the next detailing round. Check a box only when the point's disposition is recorded; write the disposition inline after the checkbox (e.g. `→ admitted as 186-<slug>`, `→ killed, see notes.md`, `→ decided: <decision>`)._

## Detailing rounds (recommended order)

- [x] 1. **P7 — CI for harness tests** (fix, mechanical, no gates) → **deferred 2026-06-09** — maintainer: project not in production yet; revisit when production/adoption raises the cost of a missed regression. See notes.md.
- [x] 2. **P1 — Evidence bundle as product** (evolve, the strategic bet) → **deferred 2026-06-09** — maintainer: no users yet; revisit with adoption. Full detailing analysis preserved in notes.md (incl. the verified ephemerality finding).
- [x] 3. **P2 — Lab vs adoptable asset** (decision, gates P3/P4/P6) → **decided 2026-06-09: lab + public showcase** — personal lab optimized for one operator; site/README stay as consultancy showcase; no adoption machinery. Reopen on first genuine external interest. See notes.md.
- [x] 4. **P3 — Multi-runtime posture: portable core + reference runtime** (decision, contradicts doctrine) → **deferred 2026-06-09** — maintainer: "leave as is"; symmetric-parity doctrine stands. Scope had been narrowed to Codex re-tier only (third runtime discarded, meeting deleted). Full impact analysis (files-to-touch, kept lanes, freeze-not-teardown, rot risk) preserved in notes.md.
- [x] 5. **P4 — Shrink the prose control plane** (optimize) → **adopted as discipline 2026-06-09** (B+C, no child spec) — numeric-target diet withdrawn as over-engineering under lab posture; register-split-on-touch + mechanism-or-demand admission + prose→gate promotion recorded in `.agent0/memory/rule-corpus-discipline.md`, with seed backlog (move-whole: governance pair; split: harness-sync/delegation/memory-placement/secrets-scan).
- [x] 6. **P5 — Hook-chain latency** (optimize, measure-first) → **killed 2026-06-09 by measurement** — per-Bash chain ~7ms, per-Edit chain ~46ms sequential (28ms of it = project-core-sync alone, all others 3-5ms); the 150ms consolidation threshold is not remotely approached. Benchmark method + numbers in notes.md.
- [ ] 7. **P8 — Hook supply-chain integrity** (fix) — checksum manifest + doctor verification; check whether P1's bundle format subsumes it.
- [ ] 8. **P6 — Kernel out of bash** (optimize, XL, gated by P2) — only detail after P2 decided; expected: admit-deferred or kill if P2 = lab.

## Verification

- [ ] Every P1–P8 box above carries an inline disposition (spec.md scenario 1).
- [ ] P2 has an explicit maintainer decision and P3 has a decision-grade debate record (or explicit recorded override) before any related child spec exists (spec.md scenario 2).
- [ ] Each round's analysis exists in a child spec or in `notes.md` — spot-check: no disposition whose only trace is chat history (spec.md scenario 3).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
