# 185 — harness-evolution-program — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom by default, but the maintainer may pick any point for the next detailing round. Check a box only when the point's disposition is recorded; write the disposition inline after the checkbox (e.g. `→ admitted as 186-<slug>`, `→ killed, see notes.md`, `→ decided: <decision>`)._

## Detailing rounds (recommended order)

- [x] 1. **P7 — CI for harness tests** (fix, mechanical, no gates) → ~~deferred 2026-06-09~~ **REOPENED + executed 2026-06-09** — maintainer's operator-quality principle ("personal doesn't mean not working perfectly") overturned the deferral: CI is quality insurance for the operator, not adoption machinery. Shipped: `.agent0/tests/run-all-suites.sh` + `.github/workflows/harness-tests.yml`. See notes.md.
- [x] 2. **P1 — Evidence bundle as product** (evolve, the strategic bet) → **deferred 2026-06-09** — maintainer: no users yet; revisit with adoption. Full detailing analysis preserved in notes.md (incl. the verified ephemerality finding).
- [x] 3. **P2 — Lab vs adoptable asset** (decision, gates P3/P4/P6) → **decided 2026-06-09: lab + public showcase** — personal lab optimized for one operator; site/README stay as consultancy showcase; no adoption machinery. Reopen on first genuine external interest. See notes.md.
- [x] 4. **P3 — Multi-runtime posture: portable core + reference runtime** (decision, contradicts doctrine) → **deferred 2026-06-09** — maintainer: "leave as is"; symmetric-parity doctrine stands. Scope had been narrowed to Codex re-tier only (third runtime discarded, meeting deleted). Full impact analysis (files-to-touch, kept lanes, freeze-not-teardown, rot risk) preserved in notes.md.
- [x] 5. **P4 — Shrink the prose control plane** (optimize) → **adopted as discipline 2026-06-09** (B+C, no child spec) — numeric-target diet withdrawn as over-engineering under lab posture; register-split-on-touch + mechanism-or-demand admission + prose→gate promotion recorded in `.agent0/memory/rule-corpus-discipline.md`, with seed backlog (move-whole: governance pair; split: harness-sync/delegation/memory-placement/secrets-scan).
- [x] 6. **P5 — Hook-chain latency** (optimize, measure-first) → **killed 2026-06-09 by measurement** — per-Bash chain ~7ms, per-Edit chain ~46ms sequential (28ms of it = project-core-sync alone, all others 3-5ms); the 150ms consolidation threshold is not remotely approached. Benchmark method + numbers in notes.md.
- [x] 7. **P8 — Hook supply-chain integrity** (fix) → **admitted minimal + executed 2026-06-10** — doctor gained a `shipped integrity` section verifying the executable shipped surface against the existing sync baseline sha-set (zero new state; advisory-only; n/a without baseline). P1-overlap OQ answered: standalone, baseline-backed — no bundle format needed. Suite shipped-integrity 5/5; CI green.
- [x] 8. **P6 — Kernel out of bash** (optimize, XL, gated by P2) → **killed 2026-06-09** — a rewrite buys installability/portability for strangers, not quality for the operator (bash kernel is tested, fast per P5, and working); maintainer's quality bar is served by tests+CI instead. No separate reopen trigger: a P2 posture flip re-tables it naturally. See notes.md (incl. the operator-quality principle that reopened P7).

## Verification

- [x] Every P1–P8 box above carries an inline disposition (spec.md scenario 1).
- [x] P2 has an explicit maintainer decision and P3 has a decision-grade debate record (or explicit recorded override) before any related child spec exists (spec.md scenario 2). — P2 decided (lab+showcase); P3 deferred, no child spec opened, so the debate precondition was never triggered.
- [x] Each round's analysis exists in a child spec or in `notes.md` — spot-check passed: P1/P3/P5 full analyses, P2/P4/P6/P7/P8 decision+execution records all in notes.md.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
