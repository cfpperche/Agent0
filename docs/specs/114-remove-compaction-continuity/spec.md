# 114 — Remove the compaction-continuity capacity (pre-compact hook)

**Status:** shipped
**Type:** (refinement — removes a capacity, ships no new behavior)

## Intent

Remove the **compaction-continuity** capacity in full: the `PreCompact` producer hook
(`.claude/hooks/pre-compact.sh`), its `SessionStart` consumer logic (the `source=compact`
snapshot-injection block in `.agent0/hooks/session-start.sh`), the on-disk snapshot store
(`.claude/.compact-history/`), the memory entry that documents it, the scenario test suite,
and every prose pointer to it across rules, `CLAUDE.md`, and the sync baseline.

## Why

A 2026-05-29 design discussion concluded native `/compact` summarization is sufficient for
this project's actual workflow, and the capacity is **dormant, redundant insurance**:

1. **Redundant.** The signal the snapshot preserves (paths, identifiers, decisions, the *why*)
   is already carried by four dedicated stores — `.agent0/HANDOFF.md` (WIP), `.agent0/memory/`
   (durable facts), `docs/specs/` (design memory), and `git log`. The native compaction summary
   is a fifth carrier; the snapshot is a sixth.
2. **Narrow and mis-targeted value.** Its only unique contribution over the native summary is
   *verbatim raw signal of the last 12 turns*. But "last 12 turns" protects the recent tail —
   exactly the window the summarizer handles best (recency bias) — and does **not** protect a
   mid-session decision the summary compresses away.
3. **Rarely fires for this workflow.** Zero snapshots exist in `.claude/.compact-history/`; the
   project's pattern is `/clear` + handoff between sessions, so the capacity almost never reaches
   a compaction boundary.

By the project's own anti-speculative-machinery doctrine (`feedback_speculative_observability`,
rule-of-three), a capacity that rarely fires and duplicates five existing carriers does not earn
its conceptual surface area. This spec removes it cleanly rather than leaving it dormant.

This decision is recorded as the resolution of the option-(a) branch in that discussion
("confirm rare auto-compaction → cut the pair + adjust § Compact Instructions").

## Scope

In scope: complete removal of every artifact and pointer belonging to the capacity, and an
adjustment of `CLAUDE.md` § Compact Instructions so it no longer assumes the snapshot exists
(the terse-summary guidance for the *native* summarizer stays, the snapshot dependency goes).

Out of scope: any change to native `/compact` behavior; any change to `.agent0/HANDOFF.md`,
memory, or specs as carriers (they remain the canonical continuity stores).

## Non-goals

- Not replacing the capacity with a different continuity mechanism — native compaction + the
  existing four stores are the deliberate replacement.
- Not touching the platform-fact documentation in `.agent0/memory/cc-platform-hooks.md` that
  PreCompact *exists as a Claude Code event* — that is true platform knowledge, independent of
  whether this project uses it. (Only references to *our* usage of it are removed.)

## Acceptance criteria

- [ ] `.claude/hooks/pre-compact.sh` no longer exists.
- [ ] `.claude/tests/compaction-continuity/` no longer exists.
- [ ] `.agent0/memory/compaction-continuity.md` no longer exists.
- [ ] `.claude/.compact-history/` runtime dir no longer exists in the working tree.
- [ ] `.claude/settings.json` has no `PreCompact` key, and parses as valid JSON.
- [ ] `.gitignore` has no `.claude/.compact-history/` line.
- [ ] `.claude/harness-sync-baseline.json` has no `pre-compact.sh` entry, and parses as valid JSON.
- [ ] `.agent0/memory/MEMORY.md` has no pointer line to `compaction-continuity`, regenerated via
      `memory-project.sh` (not raw-edited).

- [ ] **Scenario: SessionStart still injects the handoff after the removal**
  - **Given** `session-start.sh` with the `source=compact` snapshot block deleted
  - **When** the hook runs with `{"source":"compact"}` on stdin
  - **Then** it still emits the `=== HANDOFF.md (canonical handoff) ===` block and exits 0,
    with no reference to `.compact-history` and no shell error (`bash -n` clean).

- [ ] **Scenario: no dangling pointers remain**
  - **Given** the removal is complete
  - **When** the repo is grepped (case-insensitive) for `pre-compact`, `compact-history`,
    `compactHistory`, and `compaction-continuity`, excluding `.git/`, `*.jsonl` ephemeral logs,
    and the design-system / product-template false positives
  - **Then** the only surviving matches are: this spec dir (`docs/specs/114-*`), the generic
    word "compaction" in prose that refers to the native feature (not our hook), and any retained
    platform-fact mention of the `PreCompact` *event* in `cc-platform-hooks.md`.

- [ ] **Scenario: CLAUDE.md no longer promises the snapshot backstop**
  - **Given** § Compact Instructions previously said the summary "can stay terse" *because* the
    `.compact-history` snapshots preserve raw signal
  - **When** the section is read after the edit
  - **Then** the snapshot dependency sentence is gone and the remaining guidance stands on the
    native summarizer alone.

## Open questions

- None blocking. The cc-platform-hooks.md platform-fact retention is decided (keep the event
  mention, drop any "we use it" phrasing) and verified during implementation.

## Outcome (2026-05-29)

Removal complete and validated — `13/13` removal checks PASS (see `validation.txt`).

**Deleted:** `.claude/hooks/pre-compact.sh`, `.claude/tests/compaction-continuity/` (7 files),
`.agent0/memory/compaction-continuity.md` (+ `MEMORY.md` re-projected).

**Edited (deregistration + pointer cleanup):** `.claude/settings.json` (PreCompact removed),
`.agent0/hooks/session-start.sh` (compact branch + dead `SOURCE`/`COMPACT_HISTORY_DIR` removed;
`bash -n` clean; `source=compact` smoke run still emits HANDOFF), `.gitignore`, `CLAUDE.md` +
`AGENTS.md` (§ Compact Instructions snapshot sentence), `.claude/rules/session-handoff.md`,
`.claude/rules/artifact-budgets.md`, `.claude/rules/reminders.md` (dropped "compact-history
context" clause), `.agent0/memory/cc-platform-hooks.md` (8→7 used / 21→22 unused; removed usage
bullet + dead cross-ref; **kept** the `PreCompact` *platform-event* table row), `.agent0/memory/
harness-home.md`, `.agent0/.runtime-state/README.md` (subsystem row dropped), `.agent0/memory/
capacity-spec-index.md`, `site/src/i18n/capacities.ts` (capacity card removed).

**Deliberately KEPT (not dangling):**
- `.claude/rules/memory-placement.md:58,247` — accurate historical case-study of spec 096's
  rule→memory move; rewriting a teaching example to reflect a later removal would harm it.
- `PreCompact` / `PostCompact` / `/compact` / "compaction" mentions in `cc-platform-hooks.md`
  (event table), `runtime-capabilities.md`, `codex-cli-hooks.md`, `site/src/i18n/strings.ts`
  (FAQ), `harness-sync.md`, `rule-load-debug.md` (`--reason compact`) — these are platform-event
  / native-feature facts, independent of this project's now-removed usage.
- `docs/specs/*` historical specs (081/092/096/097/101/102/104/…) — design-memory record, never
  rewritten (SDD: git log is the audit trail).

**Follow-up (not done here):** `site/dist/*` is generated from `site/src/`; run the site build
to regenerate the static HTML so the public catalog drops the card. Generated HTML was not
hand-edited.
