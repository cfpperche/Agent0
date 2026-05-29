# Plan — 114 remove compaction-continuity

## Approach

Pure removal + pointer cleanup. No new behavior. Order edits so the repo never enters a state
where a registered hook points at a deleted file *and* a session could start mid-removal — i.e.
deregister in `settings.json` before/with deleting the script. Since this is a single working
session, the practical ordering risk is low; we still deregister and delete together.

## Files to touch

### Delete
- `.claude/hooks/pre-compact.sh` — the `PreCompact` producer.
- `.claude/tests/compaction-continuity/` — whole dir (6 scenario tests + `run-all.sh`).
- `.agent0/memory/compaction-continuity.md` — the capacity's memory entry. Then re-project
  `MEMORY.md` via `.agent0/tools/memory-project.sh` (the sanctioned, gate-compliant path — raw
  edits to `MEMORY.md` are blocked by `memory-index-gate.sh`).
- `.claude/.compact-history/` — runtime snapshot dir (gitignored, ephemeral). Remove if present.

### Edit
- `.claude/settings.json` — remove the entire `"PreCompact": [ … ]` array property (the block
  registering `pre-compact.sh`). No `compactHistory` key exists in this file (verified by full
  read), so nothing else to strip here. Must remain valid JSON (no trailing comma left behind).
- `.agent0/hooks/session-start.sh` — remove three regions:
  1. header comment lines describing the `compact` source injection (the `# - compact → …` lines),
  2. the `COMPACT_HISTORY_DIR=…` variable assignment,
  3. the `if [[ "$SOURCE" == "compact" ]]; then … fi` snapshot-injection block.
  Keep everything else (HANDOFF injection, source parsing, runtime-introspect/githooks banners,
  state-file logic). `SOURCE` is still parsed and still used by other logic, so the variable
  stays; only the compact-branch is deleted.
- `.gitignore` — remove the `.claude/.compact-history/` line.
- `CLAUDE.md` — § Compact Instructions: delete the sentence coupling the terse summary to the
  `.compact-history` snapshots; keep the prioritize/compress guidance.
- `.claude/rules/session-handoff.md` — § SessionStart fallback: drop the "also injects the latest
  `.claude/.compact-history/*.md` snapshot" clause (keep that SessionStart fires on `source=compact`
  and still injects the handoff). § Reader-side defense: drop `.compact-history` from the example
  source list (HANDOFF.md remains the example).
- `.claude/rules/artifact-budgets.md` — § Where this applies: remove the "compact-history snapshots
  keep the last 12 turns," clause from the state-file-limits sentence.
- `.claude/harness-sync-baseline.json` — remove the `pre-compact.sh` hash entry so sync-harness
  does not flag a missing baseline file. Keep valid JSON.

### Verify-then-edit (uncertain until grepped at implement time)
- `.claude/rules/runtime-capabilities.md` — if it carries a compaction-continuity capability row,
  remove it; if no match, no change.
- `.agent0/memory/harness-home.md` — if it inventories `pre-compact.sh`, remove that line.
- `.agent0/.runtime-state/README.md` — if it references compact-history, adjust.
- `.agent0/memory/cc-platform-hooks.md` — retain the `PreCompact` *platform event* fact; remove
  only any "we use it / our pre-compact.sh" phrasing.
- `.codex/config.toml.example` — Codex has no compaction hook, so expected no match; confirm.

## Alternatives considered

- **Keep dormant.** Rejected by the design discussion — dormant + redundant + mis-targeted fails
  the rule-of-three demand test; conceptual surface area is the cost being removed.
- **Mark the memory entry "superseded" instead of deleting.** Rejected — the entry documents a
  now-nonexistent mechanism; `git log` is the historical record, and a superseded reference entry
  would just be decay-bait. Delete is cleaner.
- **Rewrite the snapshot to capture mid-session decisions (fix the window mis-targeting).**
  Rejected — that is building *more* machinery to justify a capacity we concluded isn't needed;
  out of scope and against the decision.

## Risks

- **Leaving a dangling pointer.** Mitigated by the no-dangling-pointers grep scenario as a hard
  acceptance gate.
- **Breaking `session-start.sh`.** Mitigated by `bash -n` syntax check + a stdin-driven
  `source=compact` smoke run asserting the HANDOFF block still emits.
- **Invalid JSON after the settings/baseline edits.** Mitigated by `python3 -m json.tool` parse
  checks on both files.
- **Memory index drift.** Mitigated by regenerating `MEMORY.md` via `memory-project.sh` rather
  than hand-editing (also respects `memory-index-gate.sh`).
