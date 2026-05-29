# 115 — remove-rule-load-debug

_Created 2026-05-29._

**Status:** shipped

## Outcome

Shipped 2026-05-29. The `rule-load-debug` capacity is removed in full: hook script + memory doc `git rm`'d, runtime log + lock + their `.gitignore` lines deleted, `InstructionsLoaded` registration dropped from `settings.json` (parses clean, key absent), `rule-loads` subcommand + usage + env-hint stripped from `probe.sh` (`bash -n` clean; `last-run` still exits 0; `rule-loads` now hits unknown-subcommand exit 2), `MEMORY.md` regenerated (22 entries, no `rule-load-debug` line), and the runtime-state README / capacity-spec-index / `capacities.ts` rows removed. `cc-platform-hooks.md` corrected (`6 of these 29`, attribution + dead pointers severed) while preserving the platform-fact event row and the empirical dedup finding. Site rebuilt — `dist/` clean of the card (and of spec 114's compaction card, resolving that pending action too; `site/dist` is gitignored). Three historical-narrative mentions kept by design (see `notes.md` § Design decisions). All acceptance scenarios verified PASS.

## Intent

Remove the `rule-load-debug` capacity entirely — the opt-in `InstructionsLoaded` observability hook, its memory doc, its probe subcommand, its settings registration, its runtime log, and every live cross-reference. The capacity (shipped 2026-05-13, commit `fd17b0b`) was exercised exactly once on its creation day — the `.claude/.rule-load-debug.jsonl` log holds 18 rows, all within a ~30-second window across 2 sessions, and zero events in the 16 days since. It is the canonical shape of the `feedback_speculative_observability` anti-pattern the project flagged: observability built ahead of demonstrated demand, where the demand never materialised. The legitimate use case (verifying `paths:` glob correctness on the 10 path-scoped rules) is real but recurs rarely enough that the off-by-default tool was never reached for when it would have helped. Removing it deletes dead weight from the harness — and, notably, a Claude-only hook (`InstructionsLoaded` has no Codex analogue) that was a standing exception to the `.claude/` → `.agent0/` multi-runtime migration arc.

## Acceptance criteria

- [x] **Scenario: hook script and memory doc are gone**
  - **Given** the repo after this spec ships
  - **When** `ls .claude/hooks/rule-load-debug.sh .agent0/memory/rule-load-debug.md` runs
  - **Then** both paths report "No such file or directory"

- [x] **Scenario: InstructionsLoaded registration removed and settings.json still valid**
  - **Given** `.claude/settings.json`
  - **When** parsed with `jq .` after the edit
  - **Then** it parses cleanly AND `.hooks.InstructionsLoaded` is absent (`jq -e '.hooks | has("InstructionsLoaded")'` exits non-zero)

- [x] **Scenario: probe.sh no longer exposes rule-loads**
  - **Given** the edited `.agent0/tools/probe.sh`
  - **When** `bash .agent0/tools/probe.sh rule-loads` runs
  - **Then** it falls through to the unknown-subcommand branch (exit 2, usage printed) AND `bash .agent0/tools/probe.sh last-run` still works (exit 0), AND `bash -n .agent0/tools/probe.sh` is clean

- [x] **Scenario: runtime log files deleted and de-gitignored**
  - **Given** the repo after this spec ships
  - **When** `ls .claude/.rule-load-debug.jsonl*` runs AND `grep rule-load-debug .gitignore` runs
  - **Then** the log + lock files are gone AND `.gitignore` has no `rule-load-debug` line

- [x] **Scenario: MEMORY.md index regenerated without the entry**
  - **Given** the deleted memory entry
  - **When** `bash .agent0/tools/memory-project.sh` regenerates the index
  - **Then** `.agent0/memory/MEMORY.md` has no `rule-load-debug` line AND the projection runs clean

- [x] No live (non-`docs/specs/`) reference to the deleted capacity survives: `grep -rn "rule-load-debug\|CLAUDE_RULE_LOAD_DEBUG" . --include=*.sh --include=*.md --include=*.json --include=*.ts` outside `docs/specs/` returns only KEEP-listed platform-knowledge lines (see § Decisions).
- [x] `.agent0/.runtime-state/README.md` has no `.rule-load-debug.jsonl` row and its intro no longer names `rule-load-debug` as a Claude-exclusive state owner.
- [x] `.agent0/memory/capacity-spec-index.md` has no `Rule load debug` row.
- [x] `site/src/i18n/capacities.ts` has no `rule-load-debug` capacity object; `cd site && npm run build` (or the project build) succeeds.
- [x] `.agent0/memory/cc-platform-hooks.md` no longer attributes `InstructionsLoaded` to the removed capacity (the "7 of these 29" count is corrected and the `rule-load-debug` cross-references are severed), while the platform-fact event-table row and the empirical dedup finding are preserved.

## Non-goals

- **Not removing platform knowledge.** The `InstructionsLoaded` row in the `cc-platform-hooks.md` event table and the empirical intra-session dedup finding are genuine CC-platform facts independent of our hook. They stay (with dead pointers to the deleted doc severed). See § Decisions.
- **Not rewriting `docs/specs/*` history.** Every historical mention of `rule-load-debug` across specs 060/062/081/095/096/097/100/102/105/108/109/112/114 is the audit trail — left untouched per `.claude/rules/spec-driven.md` (git is the record).
- **Not touching the frozen `propagation-hygiene.md:66` narrative** — it documents spec 070's cleanup history and naming the file there is historically accurate.
- **Not re-implementing a replacement.** If `paths:` glob verification is ever needed again, `/memory` + a manual fresh-session read covers the rare case; rebuilding the audit hook is out of scope (and would re-trip the rule-of-three demand test).

## Open questions

- [x] None. Surface is fully mapped (exhaustive grep run 2026-05-29); edge decisions resolved in § Decisions.

## Context / references

- `.agent0/memory/rule-load-debug.md` — the doc being deleted (full capacity description)
- `feedback_speculative_observability` (user auto-memory) — rule-of-three demand test; this removal is its application
- `docs/specs/096-maintainer-rules-to-memory/` — moved the rule → memory (the capacity this spec now removes wholesale)
- `docs/specs/114-remove-compaction-continuity/` — immediate precedent: same shape (remove a dormant, redundant capacity), same KEEP-platform-knowledge discipline
- `docs/specs/102-harness-consolidate-agent0/` — the `.claude/` → `.agent0/` migration arc this hook was a Claude-only exception to
