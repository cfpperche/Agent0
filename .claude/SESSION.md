# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

Spec 026 Phase B tasks 11/12/13 dogfooded end-to-end (commits up through `b8af3cf`); task 14 (step 5 brand port) shipped + dogfooded same-session (commits `e4f6361` + `d13263d`). Working tree clean. 109 tests pass, `bun tsc --noEmit` clean. 4 commits ahead of origin.

This session also produced a substantive **anthill-vs-MCP comparison** for steps 3 + 4 (artifact: `/tmp/bench/026-comparison-anthill/COMPARISON.md`, 8 KB). Verdict: volume parity (~130 KB vs ~130 KB step 3; ~46 vs ~41 KB step 4); MCP wins on tier-depth license + machine-readable architecture + format-enforced measurable a11y axis + validation_mode posture; loses on per-feature anti-goals + per-feature engineering decisions + YAML frontmatter source-of-truth + inline delegation routing (`fix_skill_hint` + `priority_fixes` agrupados). Honest credit: Gap B in step 4 is structural enforcement of rigor anthill's `evidence` field already invited, not a port-introduced improvement.

3 of the 4 port-improvements identified by the comparison shipped in `b8af3cf` (per-feature anti-goals + architecture-seed + Priority Recommendations named-batches discipline). 2 deferred: YAML frontmatter on step 4 + per-finding `fix_skill_hint`. Both fold into the step 6 PR (the consumer that defines what fields the structured layer needs).

Linear-clone-poc was promoted: pre-port artifacts archived to `.pre-port-archive/`; step 2/3/4 outputs now live at `linear-clone-poc/docs/product/{02-prototype,03-spec,04-ux-testing}/` with `/tmp/bench/...` paths rewritten to `../02-prototype/...`. 404 KB step 2 + 136 KB step 3 + 52 KB step 4. Steps 5-12 still placeholders.

Step 5 dogfood (sharp-vision founder branch, 6 exchanges, opus sub-agent synthesis) confirmed the calibrated-interview design works: "almost exactly the right shape, a 7th probe on sharp-vision would have produced thinner signal." Surfaced one real prompt-language ambiguity (posture-numbers vs scale-tokens) — fixed in `d13263d`.

## Next steps

1. **Spec 026 Phase B — step 6 design-system (task 15, HIGH priority).** Tokens feed steps 7 + 13. The two deferred port-improvements from the anthill comparison (YAML frontmatter on step 4 + per-finding `fix_skill_hint`) naturally fold here — design-system is the downstream consumer that defines the structured fields. Apply `feedback_anthill_port_smart_not_rigid` to the port (read source end-to-end → audit 4 smells → propose calibration → dogfood inline → fix same-session).
2. **Spec 026 Phase B — remaining tasks 16-22**: step 7 prototype-v2, 8 PRD, 9 system-design, 10 cost, 11 roadmap, 12 legal, 13 prototype-v3 NEW.
3. **Fair OD re-match + future OD `--bump`/`--apply`** — both still pending in `.claude/REMINDERS.md`, deferred-style not urgent.

## Carryover (orthogonal lanes, not active)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending (13 modified + 2 untracked there).
- Praxis-prototype lane (consultancy-site, separate repo): deployed at https://cfpperche.github.io/praxis-prototype/. Possible `section-line-grid` opacity bump 0.045 → 0.07.
- Bench artifacts (wipe-able): `/tmp/bench/026-dogfood-step2/` (~370 KB; promoted to linear-clone-poc but kept as bench reference) + `/tmp/bench/026-dogfood-step3-4/` (~157 KB) + `/tmp/bench/026-comparison-anthill/` (~140 KB) + `/tmp/bench/026-dogfood-step5/` (~14 KB).
