# 081 — compact-history-runtime-readme — plan

_Drafted from `spec.md` on 2026-05-23. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two orthogonal mechanisms ship in one diff. Neither shares code with the other; both correct already-felt friction with zero new primitives.

**MS-3 — Per-compaction history.** Replace the single overwritten `.claude/COMPACT_NOTES.md` with a directory of timestamped snapshots at `.claude/.compact-history/<ISO>-<pid>-<rand>.md`. `pre-compact.sh` writes a new file per invocation (creating the dir on demand) and applies a retention cap read from `.claude/settings.json` key `compactHistory.keepLast` (default 20 when unset). `session-start.sh` on `source=compact` swaps its `cat $NOTES_FILE` for `cat "$(ls -1 .claude/.compact-history/*.md | tail -1)"` — the lex-greatest filename equals the chronologically-latest snapshot because the timestamp prefix is fixed-width ISO seconds. Filename suffix `-<pid>-<rand>` is a 12-byte tie-breaker for the (rare but real) case where two `/compact` events fire within the same UTC second; lex order is then within-second arbitrary but cross-second still chronological. Cleanup runs once at write time via `ls -1t … | tail -n +$((KEEP_LAST+1)) | xargs -r rm -f` — bounded work per compaction, no separate cron.

**MS-6 — Runtime-state README.** Ship `.claude/.runtime-state/README.md` as a 6-row table enumerating every state subsystem currently present in Agent0 (`.runtime-state/`, `.browser-state/`, `.delegation-state/`, `.routines-state/`, `.rule-load-debug.jsonl`, `.compact-history/`) with Owner column pointing at the rule file. The README is git-tracked via a `.gitignore` exception (`!.claude/.runtime-state/README.md` after the existing `.claude/.runtime-state/` ignore line); siblings in the dir stay gitignored. Add the path to `COPY_CHECK_FILES` in `sync-harness.sh` so forks receive it on `--apply`. Pattern borrowed from `/home/goat/anthill/.anthill/runtime/README.md` (shape only — Agent0's table is shorter and the "never write to /tmp" framing is Anthill-specific).

Implementation order: MS-3 hooks first (smaller blast radius — hook changes are observable on next `/compact`), then MS-6 (pure additive doc + manifest entry). Each could land in its own commit; recommended single commit since the two share NG-F (project-state, never user-state) and ship as one umbrella row pair.

## Files to touch

**Create:**

- `.claude/.runtime-state/README.md` — 6-row enumeration of state subsystems (`Path | Owner | Purpose` table); footer paragraph declares the discipline that future state additions update this README in the same commit.

**Modify:**

- `.claude/hooks/pre-compact.sh` — replace the `NOTES_FILE` constant with a per-call path under `.claude/.compact-history/`; `mkdir -p` the dir before write; add retention pass at end (read `compactHistory.keepLast` from settings.json via `jq // 20`, prune older files by mtime).
- `.claude/hooks/session-start.sh` — on `source=compact`, change the `cat "$NOTES_FILE"` block to read the lex-greatest `.claude/.compact-history/*.md` (graceful no-op when dir missing or empty); keep the `=== COMPACT_NOTES.md ===` banner text unchanged for prompt-cache stability or update it to `=== compact-history ===` (lean: update — the banner is informational, no consumer parses it).
- `.claude/rules/compaction-continuity.md` — § *Flow* references new per-event path; § *Files* updates the snapshot location and adds `.claude/.compact-history/<ISO>.md`; § *Gotchas* removes the "single file gets overwritten" entry and adds a one-line note that the single-file model was retired by 081; document the `compactHistory.keepLast` setting and its default 20.
- `.gitignore` — add `.claude/.compact-history/` to the ephemeral-state block; add `!.claude/.runtime-state/README.md` immediately under the existing `.claude/.runtime-state/` line (gitignore exception must follow the dir-ignore line); remove the `.claude/COMPACT_NOTES.md` entry (file no longer written by any hook).
- `.claude/tools/sync-harness.sh` — add `.claude/.runtime-state/README.md` to the `COPY_CHECK_FILES` array so forks receive it on `--apply`.

**Delete:**

- `.claude/COMPACT_NOTES.md` — local-only orphan (file was gitignored, never tracked). One-time `rm -f` in the working tree as the final task in `tasks.md`; the hook does NOT do it (a hook should not carry one-shot side-effects).

## Alternatives considered

### Single growing file (`COMPACT_NOTES.md`) with append-only sections

Keep the single-file model and append new snapshots inside it under `## YYYY-MM-DD` headings. Rejected because: (a) violates spec NG-C (no semantic compression / cross-event aggregation — the file would be a de-facto journal); (b) `session-start.sh` would need to parse the latest section out of an unbounded file (current behavior is `cat` of the whole file — substituting "extract last section" is more brittle than "cat lex-greatest filename"); (c) retention would require in-file editing rather than `rm` of old files, which is harder to keep correct in bash.

### Pre-create `.compact-history/` via `.gitkeep`

Add `.claude/.compact-history/.gitkeep` so the directory exists post-clone before the first compaction. Rejected because: (a) the hook already does `mkdir -p` before writing, so a missing directory is a non-issue; (b) `.gitkeep` would itself need a `.gitignore` exception (twin of the README treatment), doubling the gitignore-exception surface for no functional benefit; (c) discovery of the dir is via the runtime-state README (which lists `.compact-history/`), not by the dir's existence on a fresh clone.

### Nanosecond-resolution ISO filename (`date -u +%N`)

Use `date -u +%Y-%m-%dT%H-%M-%S-%N` for sub-second ordering. Rejected because `%N` is GNU-specific — BSD `date` (macOS forks) outputs the literal `%N` and the filename becomes garbage. The chosen `-<pid>-<rand>` suffix is portable across bash 3.2 + BSD, gives ~5 bytes of collision resistance per second, and the only loss is sub-second arrival ordering which no consumer cares about (session-start picks one snapshot; same-second twins have near-identical content).

### Top-level `.claude/STATE-LAYOUT.md` instead of nested README

Promote the enumeration to a top-level doc. Already rejected in spec NG-D — discovery angle is "what is `.claude/.*-state/`?" so the README lives inside `.claude/.runtime-state/` per the Anthill pattern. Reaffirmed here without revisiting.

### Dedicated config file (`.claude/compact-history.config.json`) instead of settings.json key

Read retention from a separate file rather than `.claude/settings.json`. Rejected because the spec locked `compactHistory.keepLast` in `settings.json` (OQ-3) and the merge model already preserves fork-only top-level keys (sync-harness's `merge_settings_json` only reconciles `$schema`, `statusLine`, `hooks` — anything else fork-side passes through untouched). Adding a separate config file would create a new gitignore/sync question for one integer.

## Risks and unknowns

- **`date -u +%Y-%m-%dT%H-%M-%SZ-$$-$RANDOM` produces variable-width random suffix.** `$RANDOM` is 0..32767 → 1-5 digits. Filenames sort correctly across seconds (timestamp prefix is fixed-width) but within a second the variable-width random suffix breaks strict lex order. Mitigation: `printf -v RAND_PAD '%05d' $RANDOM` to pad to 5 digits. Cost: one extra line in the hook; net: filenames are always exactly the same width.
- **`compactHistory.keepLast` reads from settings.json on every compaction.** `jq` invocation on the file each time is cheap (~10ms) but adds a hard dep on `jq` being installed. `pre-compact.sh` already requires `jq` to parse the transcript, so no new dep. Fallback chain: `jq … // 20` → if jq fails entirely, `KEEP_LAST=20`. Verified by reading the existing `pre-compact.sh` (jq usage on lines 20-22, 34-60).
- **Sync-harness propagation of the README on first sync.** Fork's first `--apply` after this lands will see `.claude/.runtime-state/README.md` as a new file, copy it cleanly. Existing forks that have a `.runtime-state/` dir with no README receive the README without conflict (no fork file at that path). Risk-free.
- **`!.claude/.runtime-state/README.md` exception requires the directory to not itself be ignored.** `.gitignore` ignores dir CONTENTS via `.claude/.runtime-state/` (trailing slash) — the dir itself is implicitly excluded from the ignore set, so the file exception works. Verified by inspection (git's gitignore docs are explicit: `dir/` ignores contents, not the directory record). One sanity check during implementation: after the gitignore edit, `git check-ignore -v .claude/.runtime-state/README.md` should return non-zero (file is NOT ignored).
- **Old `COMPACT_NOTES.md` left on disk in long-lived working trees.** After this ships, the file becomes orphan litter in every machine that had used the old hook. Cleanup is a one-time `rm -f .claude/COMPACT_NOTES.md` in the task list, NOT a side-effect of the hook (would be confusing — hook running cleanup that has nothing to do with the current compaction).
- **Retention cap fires only when a new snapshot is written.** A fork that compacts heavily then goes idle for weeks keeps an oversized history until the next `/compact`. Acceptable — the cap is "trim on write", not "trim continuously". Same pattern as `.claude/.routines-state/<slug>/completed/` FIFO cap.

## Research / citations

- `.claude/rules/compaction-continuity.md` — current single-file model; explicitly documents the overwrite gotcha this spec resolves.
- `.claude/hooks/pre-compact.sh` lines 11-13, 62-93 — the `NOTES_FILE` constant and the `> "$NOTES_FILE"` writer block being replaced.
- `.claude/hooks/session-start.sh` lines 17-18, 57-65 — the `NOTES_FILE` read and the `=== COMPACT_NOTES.md ===` banner block being swapped to dir-read.
- `.claude/tools/sync-harness.sh` lines 161-184 (manifest arrays) and lines 235-300 (3-way reconciliation) — confirms a new entry in `COPY_CHECK_FILES` propagates cleanly under the 3-way model.
- `.claude/rules/harness-sync.md` § *Manifest scope*, § *settings.json merge strategy* — confirms `compactHistory.keepLast` (a non-whitelisted top-level key) stays as a fork-only override under the merge.
- `/home/goat/anthill/.anthill/runtime/README.md` lines 1-30 — pattern reference for the README's shape (title + framing + Path/Owner/Purpose table). Shape only; Anthill-specific framing (storage substrate, NFS warnings) is NOT ported.
- `.claude/rules/memory-placement.md` § *The 3 buckets* — confirms a rule update for `compaction-continuity.md` is correct routing (this is operational documentation of a capacity, not project memory or per-user preference).
- Parent umbrella `docs/specs/080-memory-system-scale-ready/spec.md` rows MS-3 + MS-6 — closure criterion for the umbrella's gap matrix.
