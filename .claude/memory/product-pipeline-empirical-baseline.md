---
name: /product pipeline empirical baseline
description: First end-to-end full /product run with all 4 mature gates (2026-05-23)
  — ~3.1M tokens, ~83min, 44 dispatches, 17/17 judges. Use as cost+shape envelope
  for planning.
metadata:
  type: project
  created_at: '2026-05-23T17:28:53-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---
# /product pipeline empirical baseline (Expo, 2026-05-23)

First end-to-end full /product run with the 4 mature gates in place (spec 069 Phase 0 clear, spec 075 quality judge, spec 079 stack-aware handoff, spec 066 visual-contract structure). Captures the cost + shape envelope future planning needs.

**Run identity**
- idea: `habit tracker` · slug: `habit-tracker` (resolved to product name **Cadence** at Step 13)
- flags: `--stack=expo --out=/tmp/product-dogfood-2026-05-23-expo`
- target language: `en` (Phase 0.5)
- 15/15 steps complete · 0 blocked · 0 iterations at any of 3 gates (all `continue` on first pass)

**Cost envelope (Expo, single full run)**
- Wall-time: ~4h54m end-to-end (started 13:36 UTC, completed 18:30 UTC); includes orchestrator gate waits.
- Active sub-agent compute: ~83 min summed across producers + judges (significant parallelism savings vs serial).
- Tokens: ~3.1M total (~1.5M producers mostly-sonnet + opus on Step 01 + ~1.6M opus quality judges).
- Sub-agent dispatches: 44 total · 0 loop-budget-exceeded · 0 worktree isolation · 0 validator-cascade (no JS stack in /tmp so post-edit validator skipped).
- Quality judge fan: 4 (Phase 1) + 8 (Phase 2) + 2 (Phase 3) + 3 (Phase 4) = 17 opus judges. All cap-5 batched.

**Artifact shape**
- Total docs/ output: 2.7 MB across 58 files (25 md + 12 html + 1 css + 19 json + 1 yaml).
- Largest producer artifact: `functional-spec.md` 82 KB — well under the uniform 200 KB catastrophe cap.
- Mood screens (5 lo-fi + 5 hi-fi): ~45-68 KB each, ~590 KB combined — densest single category.
- REPORT.html (aggregator, NOT a producer artifact): ~1.3 MB; the cap doesn't apply.

**Quality verdict distribution**
- 17/17 judges fired · 8 pass · 9 concern · 0 fail.
- Concerns clustered on `right-sizing` (8 of 9). The criterion fires symmetrically — catches BOTH bloat (08-system-design 41 KB vs self-declared 20 KB; 09-legal 51 KB vs 11-14 KB sweet-spot; 14-design-system contrast values triple-documented; 15b hi-fi extension tokens) AND under-development (11-cost-estimate missing sensitivity/scenarios).
- One concern was internal-consistency (15c fixture-spec — Persona narrative streak=17 contradicts derivation streak=8); this surfaces semantic-not-just-structural drift, a desirable judge behavior.
- 0 fail = no gate forced to `iterate`; default `continue` recommended at every gate. Confirms verdict→gate routing per `references/quality-judge.md § Verdict → gate routing`.

**Mechanism validations (live, this run)**
- **Spec 069 Phase 0 clear-target.sh:** 5/5 sentinels — `.git/` + `.claude/` defense-in-depth preserved; `CLAUDE.md` allowlist preserved; non-harness file + dir removed. Blunt `rm -r <out>` foot-gun is truly gone.
- **Spec 075 quality judge:** anti-stub pre-filter never tripped (all producer outputs ≥ schema min_size); judges emit correctly-shaped JSON verdicts; verdict→state→gate routing works; rubric assembly per `quality-judge.md` produces actionable notes.
- **Spec 079 stack-aware handoff:** umbrella matrix is genuinely Expo-shaped (SDK 52, EAS Build/Submit, expo-sqlite, Apple StoreKit 2 + Google Play Billing, TestFlight, Hono+Postgres+Drizzle+Redis, Anthropic SSE, Whisper). 8 infra children (#3-#10) block-precede 3 per-phase visual children (#11-#13). Foundation child (`002-foundation`) is research-driven — explicitly cites `.claude/rules/research-before-proposing.md` and says "no Agent0-bundled template is consumed — none ships". A `--stack=next` run would yield a fundamentally different matrix (Next.js + Vercel + web routes) — the mechanism is real, not cosmetic.
- **Catastrophe cap:** 0 producer artifacts approached 200 KB; the cap is correctly loose (the largest legitimate producer is ~82 KB, ~2.5× headroom).
- **Phase 4 7-way parallel dispatch** (15a + 15c + 5× 15b): zero FS race (distinct write paths), all sub-agents completed in one wave, no validator-cascade.

**Operational gotchas**
- **Escalation advisory fires 100% on schema+security sub-agents declared `sonnet`** (steps 03, 04, 05, 07, 08, 09, 10, 11). Sonnet outputs all passed the quality judge in this run, suggesting the advisory may be over-eager. Worth measuring whether opus produces materially better artifacts on a follow-up run before tightening the signal trigger.
- **The `--stack=expo` flag is honored at Step 08 system-design as a binding contract** — § Stack section pins Expo SDK 52, then everything downstream (legal sub-processor list, cost vendor table, roadmap deliverables, atlas device targets, foundation child) inherits without re-prompting.
- **The 7-way parallel Phase 4 needs no worktree isolation** in this run because the target dir has no JS stack — the post-edit validator skipped. A `--stack=expo` run against a target dir that already has `package.json` (e.g. an iterating mei-saas-style fork) would trigger the validator-cascade unless the parent declares `isolation: "worktree"` on the parallel fan-out.
- **Quality judge tokens dominate** — ~1.6M of ~3.1M total = ~50%. Opus × 17 is the bulk of the spend; sonnet producers are cheaper than they look in aggregate. A budget-conscious run could mix-judge (sonnet for steps 01-07, opus for 08-15) but spec 075 currently mandates opus for all judges; tradeoff not yet measured.

**What this baseline is good for**
- Predicting cost + wall-time for a full /product run before invoking (especially "first real user" estimates per the reminder).
- Calibrating the next stack variant (Next.js) — the run shape (44 dispatches, 17 judges, ~3M tokens) should hold; the per-step content sizes may differ for web-shaped artifacts.
- Spotting regressions — if a future run produces fewer judges or different fail/pass distribution at the same gate, something shifted in the rubric or the producers.

**What it is NOT good for**
- A "should this run iterate?" decision — that's the quality judge's job per-run, not a baseline lookup.
- Stack-agnostic claims — these numbers reflect Expo specifically. A `--stack=next` run could move material weight (no IAP sub-processors, no EAS pipeline, different system-design surface, possibly fewer concerns since SaaS-shaped templates are better-calibrated upstream).

Future runs append a paragraph to this file (one per stack flavor or notable scope variant), keeping the comparison surface compact rather than spawning per-run memory files.
