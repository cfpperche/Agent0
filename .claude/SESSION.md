# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 030 session-edit-attribution: SHIPPED.** All 21 tasks checked off, status flipped from `draft` → `shipped`. The Stop hook now uses per-session edit attribution via `edited-files.txt` as primary signal; spec 023 demoted to fallback for legacy sessions. 20/20 tests green (8 spec 030 + 5 spec 023 regression + 7 spec 017 regression). Hand-verified the canonical bystander case end-to-end and inspected real edited-files.txt populated during dogfooding of this very session.

Files this session ready to commit:
- New: `.claude/hooks/session-track-edits.sh`, `.claude/tests/session-edit-attribution/{run-all,01..08}.sh` (9 files)
- Modified: `.claude/hooks/{session-start,session-stop}.sh`, `.claude/settings.json`, `.claude/rules/session-handoff.md`, 3 regression tests under `.claude/tests/session-{handoff,state-isolation}/`, `docs/specs/030-session-edit-attribution/{spec,plan,tasks}.md`

**Sibling-session work NOT touched** (do NOT stage):
- `.claude/skills/brainstorm/`, `docs/specs/031-brainstorm/`, `site/src/{pages/cheatsheet,components/Header.astro,i18n/strings.ts}`, `cheatsheet-*.png` — parallel session is shipping the brainstorm skill + cheatsheet page.
- `.gitignore` — likely sibling-modified; verify intent before staging.

## Next steps

1. **Push the spec 030 ship commit** once the user approves.
2. **Coordinate with sibling session** on the brainstorm/cheatsheet PR — that work is unrelated to spec 030.
3. **Spec 026 Phase B remaining tasks 19-22** (step 10/11/12/13) still pending from earlier in the day.
4. **REMINDERS.md** unchanged — fair OD re-match, OD `--bump/--apply` upstream test, spec 029 adoption check (due 2026-05-30).

## Decisions & gotchas

- **Spec 023 stays `shipped`, not superseded.** Its porcelain-compare is load-bearing on the legacy-session branch of spec 030's primary path. Don't archive or remove it.
- **Bash-driven edits in tracker-enabled sessions become a silent miss.** Documented in spec 030 § Non-goals. Users who edit via `sed -i`, `cat >`, IDE saves, etc must remember to update SESSION.md manually — the nag won't fire. Trade taken because bystander quiet was the primary goal and Bash-arg parsing for path attribution is too fragile.
- **Spec 030 path normalization gotcha**: `realpath --relative-to=$PROJECT_DIR` resolves relative paths against `$PWD`, not `$PROJECT_DIR`. Fix in the tracker: only call realpath on absolute paths; treat relative paths as already project-relative. Surfaced in test debug, fixed before ship.
- **Spec.md scenario 5 was rewritten mid-implementation.** Original wording said Bash-edit falls back to spec 023 (fires nag), but that contradicted scenario 1 (bystander → silent) — both have identical hook signals. Corrected to "Bash-edit becomes silent miss in tracker-enabled session". Noted in tasks.md task 10.

## Carryover (orthogonal lanes, not active)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending.
- Praxis-prototype (separate repo): deployed at https://cfpperche.github.io/praxis-prototype/.
- Bench artifacts (wipe-able, ~1.5 MB combined): `/tmp/bench/026-dogfood-step{2,3-4,5,6,7,8}/` + `/tmp/bench/026-comparison-anthill/`.
- 10 `step7-*.png` screenshots at repo root from prior dogfood visualizations — wipe-able, not source.
