# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 065 (artifact-budget-discipline) shipped** (2026-05-19). Commits:
- Agent0 `ff35d17` — rule + harness edits + spec docs (10 files, +410/-9)
- mei-saas `559d215` — harness resync absorbing specs 060/061/064/065 (23 files, +1579/-74)

Behavioral fix to /product trim-loop antipattern (empirical case: mei-saas 2026-05-19 Step 02 produced 69→41.8 KB across 6+ iterations against 30 KB target). Canonical rule at `.claude/rules/artifact-budgets.md`: two-threshold overshoot cascade (≤1.2× → DONE, 1.2-1.8× → partial-result with agency, >1.8× → hard-abort, no agency); trim-loop AND re-emit-at-smaller-scope explicitly forbidden; `oversize_reason` field names bloat dimension (CSS / fixtures / prose / etc — actionable signal, not "too big"). Inlined uniformly into all 16 /product briefs.

## WIP (uncommitted)

- `M docs/specs/059-product-phase0-harness-aware/tasks.md` — orthogonal carryover (not this session)

## Recent commits (this multi-session day)

- `d0cf24d` — cc-platform-audit 2nd-run findings (payload-shape additions to memo + Open Q on routine prompt specificity)
- `e1443d9` — SESSION.md handoff (spec 065 shipped)
- `7012a22` — session handoff post-064 follow-ups
- `fa0d7d2` — first real routine (cc-platform-audit) + drift fix
- `ff35d17` — spec 065 ship (artifact-budget discipline)
- `265772a` — spec 064 ship (project-scoped routines)
- `850190c` — spec 064 scaffold

## Next steps

1. **Empirical Step 02 retry in mei-saas** — fresh session `/product --from-step=2 --out=...` to observe sub-agent abort at 54 KB (1.8× of 30 KB) with partial-result instead of trim-looping. End-to-end validation of the spec 065 mechanism; user-gated by design (spec.md Open Q4).
2. **Spec 064 cron natural fire** — Monday 2026-05-25 09:00 UTC. `cc-platform-audit` should queue without manual intervention. Validates cron+leader-flag path under real timing.
3. **3rd cc-platform-audit run** (after natural fire) — should report `no-drift-detected since 2026-05-19T22:41:22Z` IFF no new platform changes AND the 2 prior runs collectively caught all drift. If 3rd run still finds drift, that's empirical signal to tighten the routine prompt per `docs/specs/064-project-scoped-routines/notes.md` § Open questions.

## Decisions & gotchas

- **Bug caught in walkthrough (Task 11), fixed pre-ship**: initial rule table had `target_max × 1.0 < output ≤ target_max × 1.2` for soft zone, leaving 1.2×–1.8× as undefined gap. Corrected to DONE ≤1.2× / soft 1.2×–1.8× / hard >1.8× before V1-V9.
- **"re-emit at smaller scope" label collision**: phrase now appears 16× in delegation-briefs.md as forbidden-antipattern label (not as old Step 01 directive). V4 verification checks the OLD wording `≥50% means re-emit` is gone (returns 0), NOT the new label. Future readers may grep and find the label — that's correct.
- **mei-saas sync required `--force-except`** for 7 fork customs (open-design MANIFEST, prompt tunings, `.mcp.json.example`, `.gitleaks.toml`, fork's `sync-open-design.ts`). This is the normal sync flow when Agent0 evolves post-bootstrap, not "manual intervention".

## Carryover (orthogonal — not touched this session)

- Spec 046 dogfood gate due 2026-07-01
- Spec 029 adoption check due 2026-05-30
- Spec 026 Phase C/D pending
- Acme Yard substrate work at `/home/goat/acmeyard`
- mei-saas `/product` Phase 0 ready (founder owns next step — separate from the spec 065 retry above)
- `.claude/REMINDERS.md` items per startup readout
