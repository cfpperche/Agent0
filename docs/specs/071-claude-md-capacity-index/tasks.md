# 071 — claude-md-capacity-index — tasks

_Generated from `plan.md` on 2026-05-21. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Audit each managed-block section against its rule.** For every `## ` capacity section inside `AGENT0:BEGIN..END`, confirm the corresponding `.claude/rules/<name>.md` (or skill `references/`) already holds every fact in the paragraph. Record the per-section worklist + any CLAUDE.md-only facts in `notes.md`. Flip `spec.md` Status `draft` → `in-progress`.
- [x] 2. **Relocate any CLAUDE.md-only fact** surfaced by task 1 into the owning rule, so compression deletes only duplicated content.
- [x] 3. **Compress the managed block.** Rewrite each capacity section in `CLAUDE.md` to a one-line index entry (`**<Capacity>** — <one-sentence what>; see \`.claude/rules/<name>.md\``, ≤ ~25 words). Leave `## Compact Instructions` and the fork-fill placeholders (`## Overview`/`## Stack`/`## Build & test`/`## Conventions`/`## Gotchas`) untouched.
- [x] 4. **Add the managed-block baseline entry to `sync-harness.sh`.** Extend the baseline read/record path so the `AGENT0:BEGIN..END` block is tracked under the synthetic key `CLAUDE.md#managed-block` in `.claude/harness-sync-baseline.json`.
- [x] 5. **Replace the CLAUDE.md merge in `sync-harness.sh`.** Swap the append-only per-section merge for managed-block-as-unit 3-way reconciliation, reusing `load_baseline` / `baseline_sha_for` / `record_manifest`: stale → replace block (no `--force`); customized → refuse without `--force`; absent (no markers) → insert. Retire the per-section append-when-present path; keep insertion-when-absent.
- [x] 6. **Add regression tests** under `.claude/tests/harness-sync/` (×3): stale managed block auto-updates; fork-customized managed block is refused; CLAUDE.md with no markers gets the block inserted. Extend `run-all.sh` to include them.
- [x] 7. **Update `.claude/rules/harness-sync.md`** — replace the append-only-merge description with the managed-block-as-unit reconciliation; ensure the doc carries no concrete-spec pointer (per spec 070 propagation-hygiene).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 8. **AC1–AC4** — managed block is all one-line index entries; `awk` word-count of the block ≤ ~900 (down from ~2,800); the count of indexed capacities is unchanged; `## Compact Instructions` + fork-fill placeholders byte-identical to pre-071; spot-check 3 sections that no dropped fact is missing from the rule.
- [x] 9. **AC5–AC8** — run the 3 new harness-sync tests + full `run-all.sh`; all pass. Confirms stale-block-auto-update, customized-block-refuse, no-marker-insertion.
- [x] 10. **AC9** — `.claude/rules/harness-sync.md` and CLAUDE.md's `## Harness sync` entry describe the new reconciliation. Then tick `spec.md` acceptance boxes, flip Status `in-progress` → `shipped`, append deviations/decisions to `notes.md`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
