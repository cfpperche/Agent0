# 146 — product-craft-floor — tasks

_Generated from `plan.md` on 2026-06-03 (OQs resolved with Codex). Work top-to-bottom._

## Implementation

- [x] 1. Write `.claude/skills/product/references/craft-floor.md` — Agent0-authored P0 rule list (5 deterministic + 2 judge-only guidance), OD attribution.
- [x] 2. Write `scripts/craft-floor-check.ts` — pure exported matchers (`default-indigo-accent`, `trust-gradient`, `emoji-feature-icon`, `filler-copy`, `sans-display-when-serif-bound`), `parseDesignTokens(designMd)`, `buildReport(files, tokens)`, + CLI (`--design <path> <html...> [--json]`). No deps (regex/string over raw HTML; hex→HSL for gradient hue bins).
- [x] 3. Write `scripts/craft-floor-check.test.ts` — fixtures inline (temp dir): `slop` (5 active P0), `purple-brand` (declared `--accent:#4f46e5` → indigo suppressed), `noisy` (left-border card + "99.9% uptime" → 0 deterministic findings).
- [x] 4. Add `craft-floor` criterion to `quality-checklist.md` under `### 02` + the `15b-hifi-mood` rubric; note exclusion from 15a/15c/01-14.
- [x] 5. Document the orchestration in `quality-judge.md` (run check before judge for the 2 units; judge sets `craft-floor` from `summary.active_p0`).
- [x] 6. Wire `SKILL.md` judge-dispatch orchestration to run the check on the 2 visual units' HTML and attach the JSON to the judge brief.
- [x] 7. Add a short anti-slop reminder (pointing at `references/craft-floor.md`) to the Step 02 brief + the Step 15b hi-fi brief only.

## Verification

- [x] `bun test scripts/craft-floor-check.test.ts` — all pass (slop=5 active, purple-brand suppresses indigo, noisy=0).
- [x] CLI smoke: run `bun scripts/craft-floor-check.ts --design <a DESIGN.md> <a slop fixture> --json` → well-formed JSON with the expected findings.
- [x] `bun test scripts/sync-open-design.test.ts` still 46/46 (no regression).
- [x] Acceptance criteria in `spec.md` re-read and checked; spec Status → shipped.

## Notes

- Bias gradient + emoji matchers toward UNDER-flagging (advisory; false positives erode trust).
- Rule list authored under Agent0 ownership, attribution to OD `craft/anti-ai-slop.md`. Lives in the `/product` package only (not Agent0 shared dirs).
