# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (now includes a 4 KB size discipline section, added 2026-05-15 after this very file ballooned to 12 KB and tripped the SessionStart hook's preview cap).

---

## Current state

Spec 026 Phase B tasks 12 (`4050de9`) and 13 + dogfood-driven Gap fixes A/B/C/D (`4522eb3`) shipped + committed. SessionStart-bloat fix (this session, see Next steps) also committed. Working tree clean. 109 tests pass, `bun tsc --noEmit` clean.

Cool Brutalist HTML bundle for Linear-Clone produced as the empirical input for the next-session re-dogfood — `/tmp/bench/026-dogfood-step2/` (3 mood-boards + compare + REPORT + 8 hi-fi screens, ~370 KB, all Layer 1 gates pass). HTTP server: `127.0.0.1:8765` may still be up (kill: `pkill -f "http.server 8765"`).

Durable lessons from this session live in memory, not here:

- `~/.claude/projects/-home-goat-Agent0/memory/feedback_anthill_port_smart_not_rigid.md` — the 4-smell port-audit pattern (magic numbers, single-orchestrator, undynamic defaults, one-mode-templates) with the canonical Gap C/D examples + Phase B audit targets
- `~/.claude/projects/-home-goat-Agent0/memory/feedback_hook_truncation_read_source.md` — when an injected block shows truncation markers, Read the source file before answering
- `.claude/memory/mcp-pipeline-quirks.md` — `required_glob` "one of" pattern, `extractRequiredSections` greedy bullet trap, opus-required for step-2 Producer

## Next steps

1. **Re-dogfood step 3 + step 4 against the Cool Brutalist HTML bundle** — sequential (step 4 gains from step 3's fresh decomposition). Validates Gap A (tiered-depth license under 8 real screens + 4 spec-projected) + Gap B (measurable WCAG audit branch under HTML).
2. **Spec 026 Phase B — tasks 14-22**: step 5 brand, **step 6 design-system (HIGH priority — tokens feed 7 + 13)**, 7 prototype-v2, 8 PRD, 9 system-design, 10 cost, 11 roadmap, 12 legal, 13 prototype-v3 NEW. Apply `feedback_anthill_port_smart_not_rigid` to each port (read source end-to-end → list every magic number / default / always-X → propose calibration → dogfood inline → fix same-session).
3. **Fair OD re-match + future OD `--bump`/`--apply`** — see `.claude/REMINDERS.md` (both still pending, both deferred-style not urgent).

## Carryover (orthogonal lanes, not active)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending (13 modified + 2 untracked there).
- Praxis-prototype lane (consultancy-site, separate repo): deployed at https://cfpperche.github.io/praxis-prototype/. Possible `section-line-grid` opacity bump 0.045 → 0.07.
- Step 2 bench artifacts under `/tmp/bench/step2-*` — wipe-able.
