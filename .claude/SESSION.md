# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 (6th) — Option B shipped + propagation-hygiene audit closed.**

Two commits, both synced to `~/mei-saas` + `~/codexeng`:

- `a59a024` — Option B. propagation-advisory triad excluded from sync manifest. `sync-harness.sh` gained `COPY_CHECK_EXCLUDE` + `matches_exclude()` (3 path patterns) plus a jq `is_excluded`/`strip_excluded` pair in `merge_settings_json` that filters PostToolUse entries whose any inner command contains `propagation-advise.sh` (filters both fork + agent0 sides — defends against forks that previously inherited the registration). CLAUDE.md propagation section removed; managed-block merge propagated removal. Memory updated (`.claude/memory/propagation-hygiene.md § The fork-bound file class` + `§ Mechanical enforcement`). Validated: 33/33 harness-sync tests + 11/11 propagation-advisory tests pass. Initial jq bug (`any(.hooks // []; ...)` indexed array with string) caught by tests 05 + 23, corrected to `.hooks[]?`.
- `60c16c6` — audit follow-up. Stripped 3 residual upstream-internal pointers from fork-bound surface: `pipeline.md:7` dropped spec-lineage parenthetical; `mcp-recipes-hint.sh` + `mcp-recipes.md` swapped "Agent0 base case" → "bare-repository case".

Fork commits: mei-saas `fbc37c8` + `e0cc7db`; codexeng `0c459ac` + `97cb58f`.

## WIP — resume point

**No active WIP.**

## Next steps

None queued. Open questions live in `.claude/reminders.yaml` (auto-injected) and on the kept-deferred residuals in `.claude/memory/propagation-hygiene.md § Not-yet-cleaned surfaces` (memory-basename examples in `routines.md` + `#`-style spec citations in shell-script comments — both decision is to defer, clean opportunistically when those files are next edited for another reason).

## Decisions & gotchas

- **Option (a) chosen for settings.json merge** over SESSION-5's (b). The (b) rationale ("fail-safe per test 09 opt-out") was wrong — test 09 is the env-var opt-out, not missing-file behavior. (a) cost ~3 LOC of jq for clean forks.
- **mei-saas + codexeng had been carrying stale upstream content** beyond Option B. Both forks pulled 273 stale-updated files in the first apply — propagation-hygiene cleanups (spec/memory citations) that landed upstream pre-Option-B but never reached the forks. Treat the volume as legitimate catch-up, not corruption.
- **`COPY_CHECK_EXCLUDE` is the canonical lever** if a future capacity needs the same upstream-maintainer-bound treatment. Mechanism is generic; only the 3 paths are currently in the list.

## Carryover (orthogonal — not touched this session)

- `docs/specs/087-skill-rubric-freedom-evals/` — untracked draft (`spec.md` + `plan.md` + `tasks.md` + `notes.md`). Pre-existing before this session; not picked up.
