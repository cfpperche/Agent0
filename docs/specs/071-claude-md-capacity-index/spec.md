# 071 — claude-md-capacity-index

_Created 2026-05-21._

**Status:** shipped

## Intent

CLAUDE.md's Agent0-managed block (`<!-- AGENT0:BEGIN -->` … `<!-- AGENT0:END -->`) carries ~20 capacity sections as full ~150-word paragraphs — ~2,800 words / ~3,600 tokens — loaded **in full, every session, in every fork**. Each paragraph is a near-duplicate of the capacity's `.claude/rules/<name>.md`, which is itself path-scoped and loads on demand. The duplication is permanent always-loaded weight, and it grows **monotonically**: every new capacity spec appends another paragraph and the append-only CLAUDE.md sync merge never removes or shrinks one. Spec 070 de-leaked the *content* (spec citations) but left the *shape*. This spec fixes the shape: each capacity section becomes a one-line index entry — capacity name, a one-sentence "what", and a pointer to its rule — so CLAUDE.md is an *index* of the harness, not a second copy of the rules. Because the current CLAUDE.md merge only *appends* missing sections, compressing the sections upstream would leave every already-synced fork stuck with the fat paragraphs; so this spec also changes the merge to treat the managed block as a baseline-reconciled unit (reusing spec 068's 3-way machinery), so the compression actually propagates.

## Acceptance criteria

- [x] Every capacity section inside CLAUDE.md's managed block is a one-line index entry — capacity name in bold, one sentence stating what it does, and a `see .claude/rules/<name>.md` pointer (or the skill/reference path where there is no rule file). Target ≤ ~25 words per entry.

- [x] The managed block's word count drops from ~2,800 to ≤ ~900 words. No capacity is dropped from the index — the count of indexed capacities is unchanged, only each entry's length.

- [x] No information is lost: every detail removed from a CLAUDE.md paragraph already exists in that capacity's `.claude/rules/<name>.md` (or its skill `references/`). The compression relocates nothing — it deletes a duplicate.

- [x] Non-capacity sections are left intact: `## Compact Instructions` keeps its full text (it is steering instructions, not a capacity index entry); the fork-fill placeholders (`## Overview`, `## Stack`, `## Build & test`, `## Conventions`, `## Gotchas`) are untouched.

- [x] **Scenario: a stale managed block auto-updates on sync**
  - **Given** a fork whose CLAUDE.md managed block matches the recorded baseline (fork never edited it) and Agent0's managed block has since changed
  - **When** `sync-harness.sh --apply` runs
  - **Then** the fork's entire managed block is replaced with Agent0's current one — no `--force` needed, no per-section append — and the baseline is re-recorded

- [x] **Scenario: a fork-customized managed block is refused, not clobbered**
  - **Given** a fork that has edited content inside its `<!-- AGENT0:BEGIN -->`…`<!-- AGENT0:END -->` block
  - **When** `sync-harness.sh --apply` runs
  - **Then** the managed block is reported as customized and refused without `--force`, consistent with the plain-file 3-way reconciliation

- [x] **Scenario: a fork with no managed block at all**
  - **Given** a fork whose CLAUDE.md predates the `AGENT0:BEGIN/END` markers (no managed block)
  - **When** `sync-harness.sh --apply` runs
  - **Then** the managed block is inserted (current behavior — first-time insertion still works)

- [x] The `harness-sync` test suite (`.claude/tests/harness-sync/`) gains regression coverage for the three scenarios above; `run-all.sh` includes the new tests and passes.

- [x] `.claude/rules/harness-sync.md` and CLAUDE.md's own `## Harness sync` index entry describe the managed-block-as-unit reconciliation.

## Non-goals

- **Re-litigating which capacities exist.** 071 compresses the presentation of the capacity inventory; it does not add, remove, merge, or rename capacities. The set of indexed capacities is exactly today's set.
- **Touching the rules themselves.** `.claude/rules/*.md` already hold the detail and are already on-demand-loaded. 071 does not edit them (beyond `harness-sync.md`, which documents the changed merge).
- **A SessionStart "active capacities" hook.** Dynamically emitting the capability list from detected `.claude/rules/` presence was considered (see plan.md) and rejected for v1 — a static one-line index is simpler and sufficient.
- **Per-section reconciliation.** The merge treats the managed block as ONE baseline-tracked unit, not N independently-reconciled sections. Per-section stale-vs-customized was considered and rejected (see plan.md) — the block is 100% Agent0-owned by the `AGENT0:BEGIN/END` contract, so unit-level reconciliation is correct and far simpler.
- **Retroactively fixing the spec-070 orphan in already-synced forks beyond the managed block.** 071's merge change does make the managed block self-healing going forward; it does not chase down other pre-070 drift.

## Open questions

- [x] The merge currently *appends missing `## ` sections before the `## Compact Instructions` anchor*. If the block is reconciled as a unit, does the append-path logic get retired entirely, or kept as the no-managed-block-yet insertion path? Leaning: keep insertion-when-absent, retire per-section append-when-present. Resolve in plan.md.
- [x] Does the managed block's baseline entry live in the same `.claude/harness-sync-baseline.json` as the plain files (keyed by a synthetic path like `CLAUDE.md#managed-block`), or a separate field? Leaning: same baseline file, synthetic key. Resolve in plan.md.
- [x] One-line entries still need to convey enough for an agent to know *when* a capacity is relevant. Is "name + what + rule pointer" enough, or does each entry need a one-clause "fires when…"? Leaning: name + what + pointer; the rule's own frontmatter `paths:` already encodes "when". Revisit if the compressed CLAUDE.md reads as too thin.

## Context / references

- `docs/specs/070-propagation-hygiene/` — de-leaked CLAUDE.md content; this spec is the shape follow-up flagged in 070's "General CLAUDE.md bloat" non-goal.
- `docs/specs/068-harness-sync-baseline-reconciliation/` — the 3-way baseline machinery this spec reuses for the managed block.
- `docs/specs/058-claude-md-managed-block/` — introduced the `AGENT0:BEGIN/END` markers that make unit-level reconciliation possible.
- `.claude/rules/harness-sync.md` — the sync tool and its current append-only CLAUDE.md merge.
- `.claude/memory/capacity-spec-index.md` — the maintainer-side capacity↔spec map (created by 070); unaffected, but the natural companion to a compressed CLAUDE.md index.
- Discussion 2026-05-21: measured the managed block at ~3,600 tokens; Option B (one-line index) ratified over status-quo and tiered alternatives.
