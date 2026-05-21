# 071 — claude-md-capacity-index — plan

_Drafted from `spec.md` on 2026-05-21. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two work streams, sequenced compress-then-merge.

**1. Compress the managed block (CLAUDE.md).** Rewrite each capacity section inside `<!-- AGENT0:BEGIN -->`…`<!-- AGENT0:END -->` from a ~150-word paragraph to a one-line index entry: `**<Capacity>** — <one-sentence what>; see \`.claude/rules/<name>.md\`.` Before deleting each paragraph, verify the detail being dropped already exists in that capacity's rule (or skill `references/`) — the compression deletes a *duplicate*, it must not delete the only copy of a fact. If a paragraph carries a CLAUDE.md-only fact, that fact moves into the rule first. Parent-side mechanical editing, like spec 070's CLAUDE.md de-leak. `## Compact Instructions` and the fork-fill placeholders (`## Overview`/`## Stack`/`## Build & test`/`## Conventions`/`## Gotchas`) are left untouched.

**2. Reconcile the managed block as a unit (`sync-harness.sh`).** Today the CLAUDE.md merge *appends* missing `## ` sections before the `## Compact Instructions` anchor and never touches sections the fork already has — so a compressed-upstream block would never reach an already-synced fork. Change: treat the whole `AGENT0:BEGIN..END` block as a single baseline-tracked unit and 3-way reconcile it exactly like a plain file, reusing spec 068's machinery (`load_baseline` / `baseline_sha_for` / `record_manifest`). The block gets a baseline entry under a synthetic key `CLAUDE.md#managed-block`. Stale (fork block == baseline, Agent0 moved) → replace the block, no `--force`. Customized (fork block != baseline) → refuse without `--force`. Absent (fork CLAUDE.md has no markers) → insert (current first-time behavior, kept).

**Why managed-block-as-unit, not per-section.** The `AGENT0:BEGIN/END` markers (spec 058) declare the block 100% Agent0-owned — a fork's own content lives *outside* the markers. So any edit *inside* the block is, by definition, customization of Agent0-managed content. There is no "fork legitimately owns section X but not section Y" case. Unit-level reconciliation is therefore both correct and far simpler than N-section stale/customized tracking — it collapses the CLAUDE.md merge into the plain-file 3-way path that 068 already built and tested.

**Open-question resolutions** (from spec.md): (OQ1) the per-section append-when-present logic is retired; insertion-when-absent is kept as the no-markers-yet path. (OQ2) the managed block's baseline entry lives in the existing `.claude/harness-sync-baseline.json`, synthetic key `CLAUDE.md#managed-block` (`#` cannot appear in a real managed-file relpath, so no collision). (OQ3) one-line entries are `name + what + rule pointer`; the rule's frontmatter `paths:` already encodes "fires when", so no per-entry "fires when" clause — revisit only if the compressed file reads too thin in dogfood.

## Files to touch

**Create:**
- `docs/specs/071-claude-md-capacity-index/tasks.md` — drafted next.
- `.claude/tests/harness-sync/NN-*.sh` (×3) — regression tests for stale-block-auto-update, customized-block-refused, no-block-insertion.

**Modify:**
- `CLAUDE.md` — compress ~20 capacity sections in the managed block to one-line index entries; `## Compact Instructions` + fork-fill placeholders untouched.
- `.claude/tools/sync-harness.sh` — replace the append-only CLAUDE.md section merge with managed-block-as-unit 3-way reconciliation; add the `CLAUDE.md#managed-block` baseline entry; keep the no-markers insertion path.
- `.claude/tests/harness-sync/run-all.sh` — extend the test loop to include the new cases.
- `.claude/rules/harness-sync.md` — document the managed-block-as-unit reconciliation (replaces the append-only-merge description).

**Delete:**
- No files. Within `sync-harness.sh`, the per-section append-when-present code path is removed.

## Alternatives considered

### Per-section reconciliation of the managed block

Rejected. Tracking stale-vs-customized per `## ` section means N baseline entries, per-section diff, and a merge that can partially-apply — essentially re-deriving spec 068's complexity at section granularity. The `AGENT0:BEGIN/END` contract already declares the entire block Agent0-owned, so there is no ownership boundary *inside* the block for per-section logic to respect. Unit-level reconciliation is correct under that contract and an order of magnitude simpler.

### Keep the append-only merge, just compress CLAUDE.md upstream

Rejected. The append-only merge never replaces a section the fork already has. Every fork synced before 071 would keep the fat paragraphs permanently; the compression would benefit only brand-new forks. The merge change is what makes the compression actually propagate — it is not separable.

### Tiered presentation — full paragraph for hot capacities, one-liner for cold

Rejected during the 2026-05-21 discussion. The "which tier" judgment is a standing maintenance surface (every new capacity must be classified, and classifications drift). It is a partial fix — the hot-tier paragraphs still grow monotonically. A uniform one-line index is simpler and the full rule is always one on-demand read away regardless of tier.

### SessionStart hook emitting the active-capability list dynamically

Rejected. It adds a hook and a detection pass to solve what a static always-loaded index already solves. An index is exactly the kind of small, stable content that belongs in an always-loaded file; dynamic generation is machinery without payoff.

### Status quo

Rejected. ~3,600 tokens of always-loaded duplication today, growing ~150 words per capacity spec, with the rules already carrying the detail on demand.

## Risks and unknowns

- **Compression must not drop a CLAUDE.md-only fact.** The paragraphs are *mostly* duplicates of the rules, but a paragraph may carry a detail the rule lacks. Mitigation: per-section, diff the paragraph's claims against the rule before deleting; relocate any unique fact into the rule first. This is the task that needs the most care.
- **`sync-harness.sh` is the most load-bearing tool in the harness.** A merge regression breaks every fork's sync. Mitigation: the change reuses 068's already-tested baseline functions; three new regression tests gate it; the test suite must pass before the spec ships.
- **First sync after 071 on a pre-071 fork.** A fork whose baseline predates the `CLAUDE.md#managed-block` key sees the block as customized-no-baseline on its first post-071 `--apply` — the same one-time friction 068 documented for plain files. Resolve once with `--force`; acceptable and documented.
- **Sections without a 1:1 rule.** `## Product skill` maps to a skill, not a rule (pointer → `.claude/skills/product/`); `## Compact Instructions` is not a capacity (left full). The compress pass handles these by judgment, not a uniform template.
- **The `## Harness sync` entry describes the very mechanism being changed.** Its one-line index entry must point at the updated `harness-sync.md`; the detail of the new reconciliation lives in the rule, not the CLAUDE.md line.

## Research / citations

- Discussion 2026-05-21 — measured the managed block at 92 lines / 2,795 words / ~3,600 tokens; per-section word counts 78–220; Option B ratified.
- `docs/specs/068-harness-sync-baseline-reconciliation/` — the 3-way baseline functions (`load_baseline`, `baseline_sha_for`, `record_manifest`, `write_baseline`) reused here.
- `docs/specs/058-claude-md-managed-block/` — the `AGENT0:BEGIN/END` marker contract that licenses unit-level reconciliation.
- `docs/specs/070-propagation-hygiene/` — de-leaked CLAUDE.md content; this spec is its shape follow-up.
- No web research — internal harness refactor, no external tool/config decision.
