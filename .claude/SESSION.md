# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 — closed. Umbrella 080 fully shipped.** Two specs landed end-to-end in one session:

- **feat(084)** `e4bd714` — reminders.yaml refactor + check_command + snooze (15 files, +890/-94).
- **feat(086)** `028628e` — memory cap + query + decay (26 files, +1048/-60).

Plus prior-session push at session start (`19218f9..c8104a1` to origin — 083 + 2 handoffs).

Umbrella 080 status: **shipped**. All 7 mechanisms ✓ (MS-1 frontmatter schema, MS-2 event journal, MS-3 + MS-6 compact-history + runtime-state README, MS-4 reminders YAML, MS-5 cap + query, MS-7 decay engine). One polish scenario remains unchecked in umbrella acceptance — documenting the 4 umbrella NGs explicitly in `.claude/rules/memory-placement.md`. Non-blocking; do during next memory-placement edit.

## WIP — resume point

**No active WIP.**

**Boot-time consequences (next session):**

1. `.claude/hooks/memory-decay-readout.sh` fires at SessionStart, surfaces `=== MEMORY DECAY ===` framed block. Currently empty (all 13 entries backfilled with `last_accessed=2026-05-24`; no entry will be stale until ~2026-07-23 at the 60d default threshold).
2. `bash .claude/tools/memory-project.sh` now emits cap advisories — 3 entries currently overflow the 250-char projected-line cap (`anthill-port-workflow` 363, `consumer-contract-discipline` 357, `product-pipeline-empirical-baseline` 252). Worth shortening descriptions when next touching those entries.
3. Local `main` is **2 commits ahead of origin** (`e4bd714` + `028628e`) — push pending user decision.

## Next steps

1. **Push** — `git push origin main` to publish 084 + 086.
2. **Polish: umbrella 080 NG-doc scenario** — add explicit documentation of the 4 umbrella NGs (NG-1..NG-4) to `.claude/rules/memory-placement.md` so the last umbrella closure scenario can tick. Small edit, can fold into the next memory-placement touch.
3. **Tighten 3 cap-overflow entries** — rewrite descriptions for `anthill-port-workflow`, `consumer-contract-discipline`, `product-pipeline-empirical-baseline` to fit under 250 chars projected (the cap discipline ships hot — wear it).
4. **Dated reminders due (now in `.claude/reminders.yaml`):** 029 (05-30) · 035 (06-07) · 046 (07-01) · 060 (07-19). Run `bash .claude/tools/memory-query.sh list` analog isn't applicable — use `bash .claude/hooks/reminders-readout.sh` or just `cat .claude/reminders.yaml`.

## Decisions & gotchas

- **086 `confirm` bypasses the memory-events-journal hook** — Python helper writes via syscall, hook only sees `Edit`/`Write`/`MultiEdit` tool calls. Audit lives in `git log`. Spec scenario rewritten mid-flight; see `086/notes.md`.
- **086 `memory-project.sh` now delegates YAML to Python helper** — PyYAML folds long descriptions, breaking awk. New `project-entries` subcommand emits tab-separated triples; degraded awk fallback retained.
- **086 NNN renumbered 085 → 086** — slot 085 occupied by external empty scaffold. Umbrella 080 row refs updated.
- **086 OQ-1 formula:** `(today − last_accessed_or_created_at).days − confirmed_count × 14`, threshold 60d. Forks override in `.claude/memory.config.json`.
- **Settings.json hooks activate next-session only** — `memory-decay-readout.sh` registered, fires from next boot.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
- `docs/specs/085-image-gen-opt-in/` — empty scaffold from another session; leave alone (user confirmed it's external to this work).
