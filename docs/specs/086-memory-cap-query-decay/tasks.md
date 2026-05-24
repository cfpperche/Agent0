# 086 — memory-cap-query-decay — tasks

_Generated from `plan.md` on 2026-05-24. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Author `.claude/memory.config.json` starter template** — top-level keys `cap` and `decay`, plus `_comment` keys. Concrete values: `cap.max_line_chars: 250`, `decay.threshold_days: 60`, `decay.confirm_boost_days: 14`. Add `_comment_<key>` siblings explaining each value. Valid JSON parseable by `python3 -c "import json; json.load(...)"`. ~25 lines.

- [x] 2. **Author `.claude/tools/memory-query-helper.py`** — Python helper with 5 subcommands invoked from the bash dispatcher and the backfill helper:
   - `backfill-metadata <file>` — read entry, set `metadata.created_at` from `git log --follow --format=%aI -- <file> | tail -1` (subprocess), `metadata.last_accessed: today_iso`, `metadata.confirmed_count: 0`. Idempotent — if all 3 fields already set, no-op silently.
   - `search <pattern>` — case-insensitive grep across all entries; print `<file>: <first matching line>` per hit.
   - `list [--type=T] [--stale=Nd|Nw|Nm]` — load all entries, filter, print `<name> — <description>`. Staleness threshold uses same duration grammar as `/remind snooze`.
   - `confirm <name1> [<name2> ...]` — variadic; for each, load entry, set `metadata.last_accessed: today_iso`, increment `metadata.confirmed_count` (default 0 → 1), write back via `yaml.safe_dump(sort_keys=False)`. Refuse on non-existent name with exit 2. Report `confirmed: <name> (last_accessed=YYYY-MM-DD, count=N)`.
   - `decay [--readout]` — compute staleness score `(today - last_accessed_or_created_at).days - confirmed_count * confirm_boost_days` for each entry; filter `score > threshold_days`; emit list. `--readout` flag wraps output in `=== MEMORY DECAY ===` frame with `(no stale entries)` empty case; bare invocation emits one-per-line CLI list. Reads `cap`/`decay` config from `.claude/memory.config.json` (defaults to 250/60/14 if absent/malformed; emits `memory-config-advisory:` on malformed JSON).
   ~200-250 LOC. `chmod +x`. Mirror error-handling shape of `reminders-helper.py` (exit 2 user error, exit 3 IO/dep error).

- [x] 3. **Author `.claude/tools/memory-query.sh` bash dispatcher** — thin bash that parses subcommand + forwards to the Python helper with the right args. ~80 LOC. Verifies `python3 -c "import yaml"` works before invoking; if not, emits `memory-query-advisory: PyYAML missing` and exits 3 (no degraded path — query/decay/confirm all need YAML mutation). `chmod +x`.

- [x] 4. **Author `.claude/tools/memory-backfill-metadata.sh`** — one-shot wrapper that iterates `.claude/memory/*.md` (excluding `MEMORY.md`) and invokes `python3 .claude/tools/memory-query-helper.py backfill-metadata <file>` for each. Report `backfilled: <name>` per entry; emit `(N entries already populated; skipped)` at end. Idempotent (the helper no-ops when fields already present).

- [x] 5. **Run backfill on the 13 existing entries** — `bash .claude/tools/memory-backfill-metadata.sh`. Verify all 13 entries now carry `metadata.created_at` + `metadata.last_accessed` + `metadata.confirmed_count` via `grep -L "confirmed_count:" .claude/memory/*.md | grep -v MEMORY.md` (should return empty). Commits the 13 entry mutations as part of the ship.

- [x] 6. **Refactor `.claude/tools/memory-project.sh`** — read `cap.max_line_chars` from `memory.config.json` (default 250). For each projected line, check length; if > cap, emit `memory-cap-advisory: <file> projects to <N> chars (cap <M>) — shorten description` to stderr. Always emit the bullet (no truncation). Exit 0. Backward-compat preserved: config absent → uses default 250 → behavior unchanged for entries under 250 chars.

- [x] 7. **Author `.claude/hooks/memory-decay-readout.sh`** — POSIX bash, ~25 LOC. Resolves `$CLAUDE_PROJECT_DIR`, invokes `bash .claude/tools/memory-query.sh decay --readout` (or directly the Python helper if you prefer), exits 0. Mirrors `reminders-readout.sh` shape. Never blocks SessionStart.

- [x] 8. **Register hook in `.claude/settings.json`** — add `memory-decay-readout.sh` under `hooks.SessionStart` matcher (likely under a `*` matcher, matching existing entries). Verify JSON still parses. (Reminder per `.claude/rules/compaction-continuity.md`: hook only fires on the NEXT session — won't fire mid-session.)

- [x] 9. **Update `.claude/rules/memory-placement.md`** — append a new § *Cap / query / decay* subsection after § *Event journal*. Document: (a) cap mechanism + advisory; (b) `memory-query.sh` subcommands; (c) decay formula + threshold + override; (d) `memory.config.json` schema; (e) cross-references to spec 086. Update § *Files* to include `.claude/memory.config.json` + `memory-query.sh` + `memory-query-helper.py` + `memory-decay-readout.sh`.

- [x] 10. **Update umbrella 080** — in `docs/specs/080-memory-system-scale-ready/spec.md`: flip the MS-5 and MS-7 rows' `Status` from `pending` to `✓ shipped`; flip `Scenario: 086 closure` checkbox from `[ ]` to `[x]`.

## Verification

- [x] 11. **Mechanical: backfill idempotent** — re-run `bash .claude/tools/memory-backfill-metadata.sh` after task 5; verify all 13 entries are skipped (no mutations), output shows `(13 entries already populated)`. **Maps to spec scenario "schema migration step", task 5 acceptance.**

- [x] 12. **Mechanical: search subcommand** — run `bash .claude/tools/memory-query.sh search hooks` and verify ≥2 entries match (`cc-platform-hooks`, `user-global-hooks-shadow` known to contain "hooks" in the title). **Maps to spec scenario "query by pattern surfaces full-body matches".**

- [x] 13. **Mechanical: list --type filter** — count entries with `type: project` vs `type: reference` via direct grep; then run `bash .claude/tools/memory-query.sh list --type=reference` and verify counts match. **Maps to spec scenario "list filters by type".**

- [x] 14. **Mechanical: list --stale filter** — set one test entry's `last_accessed` to 90 days ago via direct edit; run `bash .claude/tools/memory-query.sh list --stale=60d`; verify only the test entry surfaces. Restore the original `last_accessed`. **Maps to spec scenario "list filters by staleness".**

- [x] 15. **Mechanical: confirm mutates frontmatter** — pick `agent0-purpose.md`, note its `last_accessed` + `confirmed_count`; run `bash .claude/tools/memory-query.sh confirm agent0-purpose`; verify `last_accessed` = today, `confirmed_count` incremented by 1. **Maps to spec scenario "confirm bumps frontmatter audit fields".**

- [x] 16. **Mechanical: confirm variadic** — run `bash .claude/tools/memory-query.sh confirm visibility-intent skill-eval-pattern`; verify both entries' `last_accessed` and `confirmed_count` bumped in one invocation. **Maps to OQ-5 resolution.**

- [x] 17. **Mechanical: decay formula correctness** — set 3 test entries' `last_accessed` to `today - 80d` with `confirmed_count` 0, 1, and 2 respectively. Run `bash .claude/tools/memory-query.sh decay`; verify which surface as stale per the formula (`80 - 0*14 = 80 > 60` stale; `80 - 1*14 = 66 > 60` stale; `80 - 2*14 = 52 < 60` not stale). Restore. **Maps to spec scenario "decay readout surfaces stale entries" + OQ-1 formula resolution.**

- [x] 18. **Mechanical: decay readout frame** — set 1 test entry to stale; run `bash .claude/hooks/memory-decay-readout.sh`; verify output starts with `=== MEMORY DECAY ===`, contains the test entry, ends with `=== end MEMORY DECAY ===`. Restore + re-run; verify `(no stale entries)` empty-case line.

- [x] 19. **Mechanical: decay never mutates entries** — capture sha256 of all 13 entry files, run `bash .claude/tools/memory-query.sh decay`, re-capture sha256; verify zero changes. **Maps to spec scenario "decay never auto-archives".**

- [x] 20. **Mechanical: cap advisory on the 2 known offenders** — run `bash .claude/tools/memory-project.sh` and capture stderr; verify `memory-cap-advisory:` line for `consumer-contract-discipline.md` (~353 chars) and `anthill-port-workflow.md` (~345 chars); verify MEMORY.md still emits both lines (no truncation). **Maps to spec scenario "cap advisory on overflow".**

- [x] 21. **Mechanical: config override** — temporarily edit `.claude/memory.config.json` to set `decay.threshold_days: 30`; verify `bash .claude/tools/memory-query.sh decay` surfaces different entries (more stale at 30d than 60d). Restore. **Maps to spec scenario "config overrides default formula".**

- [x] 22. **Mechanical: malformed config advisory** — temporarily inject invalid JSON into `.claude/memory.config.json`; run `bash .claude/tools/memory-query.sh decay`; verify `memory-config-advisory:` appears and decay still runs with defaults; exit code 0. Restore.

- [x] 23. **Mechanical: cross-references in updated rule** — grep `.claude/rules/memory-placement.md` for the new § headers (`Cap / query / decay`) and verify the 4 file paths are documented under § *Files*.

- [x] 24. **Sanity: settings.json parse + git diff size check** — `python3 -c "import json; json.load(open('.claude/settings.json'))"` succeeds; `git diff --stat` shows reasonable totals (estimated ~600-800 LOC across ~20 files including 13 backfilled entries).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
