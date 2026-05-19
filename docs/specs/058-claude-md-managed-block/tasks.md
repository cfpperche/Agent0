# 058 — claude-md-managed-block — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Day 1 morning — Foundation: detect + paired-state replace

- [ ] 1. Re-read `.claude/tools/sync-harness.sh` end-to-end; identify current `merge_claude_md()` body (lines ~377-465) + the main dispatch loop (~lines 467-473); confirm no external script calls `merge_claude_md` by name
- [ ] 2. Implement `detect_marker_state()` helper: scans target file for line-anchored `^<!-- AGENT0:BEGIN -->$` and `^<!-- AGENT0:END -->$`; returns one of `absent` / `paired` / `mismatched` / `nested-invalid` via stdout. Pure function, no side effects.
- [ ] 3. Add unit-test-style smoke check inline (commented after function): four `printf | grep` invocations covering each state, exits 0 if all match expected. (Removed after task 14 lands real tests.)
- [ ] 4. Implement `_extract_region()` helper: takes file path; outputs the lines between (exclusive) the BEGIN and END markers. Used by both managed-block replace and region-divergence check.
- [ ] 5. Implement `_merge_claude_md_managed_block()` function (paired-state handler):
  - Compute `src_region` from Agent0's CLAUDE.md via `_extract_region`
  - Compute `dst_region` from fork's CLAUDE.md via `_extract_region`
  - If `dst_region` differs from `src_region` AND `--force` is NOT set → call `_write_region_divergence_report()` (task 19) and refuse with `customized-refused` increment
  - Else: build new fork content = (lines above BEGIN marker, verbatim) + BEGIN marker + src_region + END marker + (lines below END marker, verbatim); atomic `mv` from `mktemp`
  - Respect MODE=check (drift report only) and DRY_RUN=1 (decisions only)
- [ ] 6. Rename current `merge_claude_md()` body to `_merge_claude_md_legacy()` (just rename — no logic changes); the new `merge_claude_md()` becomes a dispatcher of ~12 lines
- [ ] 7. New `merge_claude_md()` body:
  ```
  state="$(detect_marker_state "$dst")"
  case "$state" in
    paired)         _merge_claude_md_managed_block ;;
    mismatched|nested-invalid) emit refuse + return ;;
    absent)         _merge_claude_md_legacy; _generate_migration_candidate ;;
  esac
  ```
- [ ] 8. Run the existing 15 harness-sync tests — all must PASS (regression check that legacy path is unchanged). Fix immediately if any breaks.

### Day 1 afternoon — Agent0 self-host + scratch dogfood

- [ ] 9. Read current `/home/goat/Agent0/CLAUDE.md`; confirm section order: 5 project-narrative on top (Overview, Stack, Build & test, Conventions, Gotchas), 18 capacities below (Spec-driven development through Compact Instructions)
- [ ] 10. Edit Agent0's `CLAUDE.md`: insert `<!-- AGENT0:BEGIN -->\n` immediately before the `## Spec-driven development` line; insert `\n<!-- AGENT0:END -->` after the last line of `## Compact Instructions` section. Verify with `grep -nE '^(<!-- AGENT0|## )' CLAUDE.md` that markers bracket the capacity sections cleanly.
- [ ] 11. Scratch-fork dogfood: `cp -r /home/goat/Agent0 /tmp/scratch-agent0` + `mkdir /tmp/scratch-fork && touch /tmp/scratch-fork/CLAUDE.md` (empty fork CLAUDE.md to exercise the "absent → copy + candidate" path); `bash sync-harness.sh --apply --agent0-path=/tmp/scratch-agent0 /tmp/scratch-fork`; inspect `diff /tmp/scratch-agent0/CLAUDE.md /tmp/scratch-fork/CLAUDE.md` — should be empty (full copy via process_file).
- [ ] 12. Scratch-fork dogfood part 2: copy Agent0's wrapped CLAUDE.md to scratch fork; modify ONE Agent0 capacity title in Agent0 source (e.g., rename `## Skill compliance` → `## Skill validation` temporarily); re-sync; verify scratch fork's region replaced (new title appears, old title removed). Then revert the temporary rename.
- [ ] 13. Commit checkpoint: `feat(058): foundation — detect_marker_state + managed-block replace + Agent0 CLAUDE.md wrapped` (working tree includes sync-harness.sh + CLAUDE.md edits)

### Day 2 morning — Candidate generation + divergence detection

- [ ] 14. Implement `_check_section_divergence()` helper: for each `## ` heading common to both Agent0 source and fork's current CLAUDE.md, compare the body bytes. Outputs a list of diverged section titles to stdout (one per line). Empty output = no divergence.
- [ ] 15. Implement `_generate_migration_candidate()` function:
  - Call `_check_section_divergence`; if non-empty → write `.claude/CLAUDE.md.diverged-sections.md` (each entry: title + diff stat) + emit `claude-md-migration-blocked: <N> sections diverged — see <path>` to stderr; return (no candidate written; legacy fallback already ran via dispatcher)
  - Else: build candidate content = (fork's project-only sections, verbatim) + BEGIN marker + (Agent0's region content, sourced from `_extract_region` on Agent0 CLAUDE.md) + END marker; prepend a leading HTML comment block explaining the file's purpose + generation timestamp + source SHA; write to `.claude/CLAUDE.md.migration-candidate.md`; emit `claude-md-migration-advisory: candidate written to <path>` to stderr
- [ ] 16. Define what "project-only sections" means in code: any `## ` heading in fork CLAUDE.md that does NOT appear in Agent0's CLAUDE.md heading set. Pure heading-set diff.
- [ ] 17. Add deduplication safeguard: if the fork's project sections include any heading that ALSO appears in Agent0's source, log a warning (this is the divergence path — should have been caught by `_check_section_divergence`, but the safeguard prevents accidental double-wrap)
- [ ] 18. Wire `_generate_migration_candidate()` invocation into the `absent` branch of the dispatcher (already sketched in task 7). Confirm: when markers absent, both legacy fallback AND candidate generation run; both write to fork; advisory is non-blocking.

### Day 2 — Region-level divergence + force override

- [ ] 19. Implement `_write_region_divergence_report()` helper (referenced by task 5): writes `.claude/CLAUDE.md.diverged-region.md` showing the diff between fork's region content and Agent0's region content; called from `_merge_claude_md_managed_block` when divergence detected
- [ ] 20. Verify `--force` propagation: when `FORCE=1`, the managed-block handler skips the region-divergence refuse path and overwrites; increments `OVERWRITTEN` counter; emits `! overwritten CLAUDE.md (region replaced under --force)`
- [ ] 21. Verify `--force-except` interaction: `--force-except='CLAUDE.md'` should refuse merge entirely (emit `!! force-except CLAUDE.md (merge skipped)` + increment `CUSTOMIZED_REFUSED`). Mirror the pattern from `merge_gitignore` § force-except check.

### Day 2 — Tests

- [ ] 22. Create `.claude/tests/harness-sync/_helpers.sh` (new shared library): export `make_wrapped_claude_md(project_sections, agent0_sections)` that produces a CLAUDE.md string with markers; export `make_legacy_claude_md(headings)` for absent-marker fixtures. Bash-3.2-portable.
- [ ] 23. Write `16-claude-md-paired-markers-replace.sh`: fork has paired markers, Agent0 has new section in region → after sync, fork's region replaced; lines above BEGIN preserved; lines below END preserved
- [ ] 24. Write `17-claude-md-absent-markers-fallback.sh`: fork has NO markers, no section divergence → legacy append runs (verifiable via existing test 06 shape) AND candidate file written; advisory line on stderr
- [ ] 25. Write `18-claude-md-mismatched-markers-refuse.sh`: case (a) only BEGIN present → refuse + CUSTOMIZED_REFUSED increment; case (b) only END present → refuse; both cases assert stderr contains `markers mismatched`
- [ ] 26. Write `19-claude-md-region-divergence-refuse.sh`: paired markers, fork edited body INSIDE region → refuse + diverged-region.md written; same fixture with `--force` → region replaced, OVERWRITTEN increment
- [ ] 27. Write `20-claude-md-section-divergence-blocks-migration.sh`: no markers, fork rewrote `## Test-driven development` body → diverged-sections.md written (NOT candidate); legacy fallback merge still runs
- [ ] 28. Write `21-claude-md-idempotent-managed-block.sh`: paired markers, region matches source → first sync = up to date; second sync = up to date; sha256sum unchanged across runs
- [ ] 29. Write `22-claude-md-removes-orphan-section.sh`: simulate the acmeyard scenario — Agent0 source has 3 capacity sections (A, B, C); fork's region has 4 sections (A, B, ORPHAN, C); after managed-block sync, fork's region = (A, B, C), ORPHAN gone
- [ ] 30. Update `.claude/tests/harness-sync/run-all.sh`: extend the `for n in 01 02 ... 15` to include `16 17 18 19 20 21 22`
- [ ] 31. Run full suite: `bash .claude/tests/harness-sync/run-all.sh`; all 22 PASS

### Day 2 — Doc + acmeyard dogfood

- [ ] 32. Update `.claude/rules/harness-sync.md`: add new section `## CLAUDE.md managed-block merge strategy` between `## .gitignore merge strategy` and the existing `## CLAUDE.md merge strategy`; in the existing section, retitle to `## CLAUDE.md heading-set merge strategy (legacy fallback)` and add a leading paragraph clarifying its role as fallback for unmigrated forks; cross-reference both directions
- [ ] 33. Document marker line-anchored convention in the new section ("markers must be on their own lines, exact match `<!-- AGENT0:BEGIN -->` and `<!-- AGENT0:END -->`"); document the 4-state detection table; document the candidate-file ratification flow with `mv` step
- [ ] 34. Run sync against acmeyard: `bash sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/acmeyard`; expect `claude-md-migration-advisory: candidate written` (legacy fallback still runs; candidate file appears in acmeyard's `.claude/`)
- [ ] 35. Inspect `/home/goat/acmeyard/.claude/CLAUDE.md.migration-candidate.md` manually: verify project sections (Overview, Stack, Build & test, Conventions, Gotchas, plus the orphan `## Prototype skill` which counts as project-titled since Agent0 doesn't have it) are above BEGIN; Agent0 capacities are between markers; nothing below END
- [ ] 36. **Manual decision point:** if the candidate looks right, `mv .claude/CLAUDE.md.migration-candidate.md CLAUDE.md` in acmeyard. If the candidate has the orphan `## Prototype skill` outside the Agent0 region (correct per heading-set diff — Agent0 dropped that title), decide whether to delete the section or keep it as a project-narrative note. Recommended: delete (orphan was unintentional).
- [ ] 37. Re-run sync against acmeyard post-ratification: `bash sync-harness.sh --apply`; expect managed-block merge path runs; verify acmeyard's CLAUDE.md now matches Agent0's region content exactly (orphan removed if it was deleted in task 36)
- [ ] 38. Commit Agent0: `feat(058): claude-md managed-block merge — primary strategy with fallback`. Commit acmeyard: `chore(harness): migrate to managed-block — orphan ## Prototype skill removed`. Push both.

## Verification

Each verification maps to one acceptance scenario in `spec.md`:

- [ ] **paired markers — apply managed-block merge** — test 16 (task 23) covers; manual verify on acmeyard task 37
- [ ] **absent markers — fallback to spec 016 legacy + write candidate advisory** — test 17 (task 24)
- [ ] **mismatched markers — refuse with explicit error** — test 18 (task 25)
- [ ] **nested-invalid markers — refuse with explicit error** — test 18 extended OR new fixture in same file
- [ ] **candidate file shape — project sections preserved + Agent0 region wrapped** — test 17 + manual review acmeyard task 35
- [ ] **candidate generation refuses on per-section divergence** — test 20 (task 27)
- [ ] **ratification — operator moves candidate to CLAUDE.md** — manual on acmeyard tasks 36-37
- [ ] **region body diverged after ratification — refuse** — test 19 (task 26)
- [ ] **`--force` overrides region divergence** — test 19 second half (task 26)
- [ ] **idempotent re-sync — no Agent0 changes, no fork changes** — test 21 (task 28)
- [ ] **Agent0's own CLAUDE.md wraps its capacity sections in markers** — task 10 (manual edit + grep verification)
- [ ] **orphan `## Prototype skill` removed from acmeyard on first managed-block sync** — test 22 (task 29) + manual on acmeyard task 37

## Notes

- **Day 1 must end at task 13** (commit checkpoint). The Agent0 CLAUDE.md wrapping is the highest-risk single change; checkpoint isolates it for revert if needed.
- **Task 12's temporary rename is destructive** — if interrupted between rename and revert, Agent0 source could be in inconsistent state. Use `git stash` as a safety net: stash → rename → sync → revert → stash pop.
- **Task 19's diff report shape** is left to implementation discretion (no spec requirement on diff format). Minimum: filenames + line numbers of divergence. Diff utility recommended: `diff -u` for context.
- **Task 22's helper library** is the first shared bash library in `.claude/tests/`. If it grows, consider promoting to `.claude/tests/_lib/` as a directory; until then, single file is fine.
- **Task 36 is a human decision point** — script does NOT auto-delete the orphan; operator decides. The whole point of the candidate-with-refuse design is that this decision is exposed, not hidden.
- **Tests under `_helpers.sh` naming** — bash sourcing convention; `run-all.sh` glob `[0-9]*-*.sh` won't match `_helpers.sh` so it's not auto-run as a test (correct behavior).
- **No new audit log added** by this spec. `git diff` post-sync IS the audit trail, consistent with spec 016's posture. `feedback_speculative_observability.md` rule-of-three: not yet a need.
- **`--migrate-claude-md` flag is intentionally absent** per spec.md non-goals. If real-world use surfaces "I want to bypass the candidate ratification step", revisit then; until then, the `mv` is the ratification.
