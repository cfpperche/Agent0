# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 065 (artifact-budget-discipline) shipped + dogfooded; harness-sync settings-merge bug fixed across 3 repos.**

Spec 065: behavioral fix to /product trim-loop antipattern (empirical case: mei-saas 2026-05-19 Step 02 produced 69→41.8 KB across 6+ iterations against 30 KB target). Canonical rule at `.claude/rules/artifact-budgets.md`: two-threshold overshoot cascade (≤1.2× → DONE, 1.2-1.8× → partial-result with agency, >1.8× → hard-abort, no agency); trim-loop AND re-emit-at-smaller-scope explicitly forbidden; `oversize_reason` field names bloat dimension. Inlined uniformly into all 16 /product briefs. Empirical Step 02 retry in mei-saas: done.

Harness-sync fix: `merge_settings_json` was dropping non-hooks top-level keys (`$schema`, `statusLine`, `permissions`, `env`, `model`) on every `--apply`. Rewrote jq to use fork's settings as base + explicit Agent0-owned-key whitelist override. Regression test `23-settings-merge-toplevel-keys.sh` added (5 assertions). All 23 harness-sync tests pass.

## WIP (uncommitted)

- `M docs/specs/059-product-phase0-harness-aware/tasks.md` — orthogonal carryover, not touched
- mei-saas has `?? docs/` — `/product` Step 02 dogfood output from 2026-05-19, not committed by founder yet

## Recent commits (anchors for the day)

- Agent0 `0702c6a` — settings.json non-hooks key preservation fix
- mei-saas `b128f76` / acmeyard `1dd71a2` — fix landed across forks
- Agent0 `ff35d17` — spec 065 ship (artifact-budget discipline)
- Agent0 `265772a` / `850190c` — spec 064 (project-scoped routines)

Older context in `git log --oneline -20`.

## Next steps

1. **Statusline runtime check (deferred to next interactive session in either fork)** — open a fresh CC session in `/home/goat/mei-saas` or `/home/goat/acmeyard`; the terminal should render the statusline from `.claude/presence/statusline.mjs`. If it does, the settings.json fix is validated end-to-end. If it doesn't, residual bug somewhere — diagnose then.
2. **Spec 064 cron natural fire** — Monday 2026-05-25 09:00 UTC. `cc-platform-audit` should queue without manual intervention.
3. **3rd cc-platform-audit run** (after natural fire) — should report `no-drift-detected` IFF no new platform changes since 2026-05-19. If still finds drift, signal to tighten the routine prompt per `docs/specs/064-project-scoped-routines/notes.md` § Open questions.

## Decisions & gotchas

- **Statusline bug had two sub-bugs** (A: presence/ not in manifest, fixed 2026-05-12; B: `merge_settings_json` dropped non-hooks keys, fixed today). A masked B for 7 days. Both documented in `.claude/rules/harness-sync.md` § Gotchas.
- **3-repo sync via `--force-except`** preserves fork-specific files (open-design MANIFEST, prompt tunings, `.mcp.json.example`, `.gitleaks.toml`). Normal flow when Agent0 evolves post-bootstrap.
- Spec 065 details — see `docs/specs/065-artifact-budget-discipline/notes.md` (rule table bug caught in walkthrough; "re-emit at smaller scope" appears 16× as antipattern label not directive).

## Carryover (orthogonal — not touched this session)

- Spec 046 dogfood gate due 2026-07-01
- Spec 029 adoption check due 2026-05-30
- Spec 026 Phase C/D pending
- mei-saas `/product` Phase 0 (founder owns next step)
- `.claude/REMINDERS.md` items per startup readout
