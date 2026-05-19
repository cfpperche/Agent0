# 058 — claude-md-managed-block

_Created 2026-05-19._

**Status:** shipped

## Intent

Spec 016's CLAUDE.md merge handler is heading-set comparison with append-only insertion before the `## Compact Instructions` anchor — by design and explicit documentation, the merge "never prunes". When Agent0 REMOVES or RENAMES a capacity section in CLAUDE.md (canonical example: spec 048 renamed `/prototype` skill to `/product`, dropping the `## Prototype skill` section in the process), the old section orphans in every fork that synced before the rename. The audit on 2026-05-19 detected this empirically: acmeyard carries `## Prototype skill` zombie that Agent0 already dropped. Frequency of the bug = (Agent0 capacity rename or removal) × (fork count) = N orphans linearly, indefinitely. Cost of inaction: capacity index pollution, agent context noise on every session start (the orphan section gets read), fork developer confusion ("does this project have `/prototype`?"). This spec adds a `merge_managed_block()` function to `.claude/tools/sync-harness.sh` that delimits Agent0-owned capacity sections in CLAUDE.md with HTML comment markers (`<!-- AGENT0:BEGIN -->` ... `<!-- AGENT0:END -->`), replacing the region wholesale on each sync — propagating ADDs and REMOVALs symmetrically. Migration is opt-in via candidate-file ratification (no auto-wrap, no silent edits to fork CLAUDE.md). Spec 016's heading-set merge stays as the fallback path for unmigrated forks, keeping disruption at zero.

## Acceptance criteria

### Marker detection (4 states)

- [x] **Scenario: paired markers — apply managed-block merge**
  - **Given** fork's `CLAUDE.md` contains exactly one `<!-- AGENT0:BEGIN -->` and exactly one matching `<!-- AGENT0:END -->`, with BEGIN appearing before END
  - **When** `sync-harness.sh --apply` runs
  - **Then** the region between markers is replaced with Agent0's current capacity sections (project sections above BEGIN preserved verbatim, anything below END preserved verbatim); the marker lines themselves are preserved exactly; counter `MERGED` increments by 1

- [x] **Scenario: absent markers — fallback to spec 016 legacy + write candidate advisory**
  - **Given** fork's `CLAUDE.md` contains NEITHER `<!-- AGENT0:BEGIN -->` nor `<!-- AGENT0:END -->`
  - **When** `sync-harness.sh --apply` runs
  - **Then** spec 016's existing heading-set append merge runs (preserving current behavior), AND a `.claude/CLAUDE.md.migration-candidate.md` file is written showing what the wrapped version would look like, AND stderr emits `claude-md-migration-advisory: candidate written to <path> — review and \`mv\` to ratify`; the merge itself succeeds (advisory, not blocking)

- [x] **Scenario: mismatched markers — refuse with explicit error**
  - **Given** fork's `CLAUDE.md` contains exactly one of `<!-- AGENT0:BEGIN -->` or `<!-- AGENT0:END -->` but not both
  - **When** `sync-harness.sh --apply` runs
  - **Then** the merge is refused for CLAUDE.md (exit-code path matches `customized-refused`), and stderr emits `!! claude-md: markers mismatched — both BEGIN and END must be paired, or both absent`; other files in the sync run continue normally

- [x] **Scenario: nested-invalid markers — refuse with explicit error**
  - **Given** fork's `CLAUDE.md` contains more than one BEGIN or more than one END marker, OR END appears before BEGIN
  - **When** `sync-harness.sh --apply` runs
  - **Then** the merge is refused for CLAUDE.md, and stderr emits `!! claude-md: nested or out-of-order markers — exactly one BEGIN before exactly one END required`

### Migration candidate file

- [x] **Scenario: candidate file shape — project sections preserved + Agent0 region wrapped**
  - **Given** an unmigrated fork with mixed-order headings (some matching Agent0's set, some fork-specific)
  - **When** migration candidate is generated
  - **Then** `.claude/CLAUDE.md.migration-candidate.md` contains: (1) fork-specific headings + bodies at the top (preserved verbatim from current fork CLAUDE.md), (2) `<!-- AGENT0:BEGIN -->` marker, (3) Agent0-owned headings + bodies in Agent0's current order, (4) `<!-- AGENT0:END -->` marker; nothing below END

- [x] **Scenario: candidate generation refuses on per-section divergence**
  - **Given** fork rewrote the body of an Agent0-titled section (e.g., fork's `## Test-driven development` body differs from Agent0's)
  - **When** migration candidate generation runs
  - **Then** `.claude/CLAUDE.md.migration-candidate.md` is NOT written; `.claude/CLAUDE.md.diverged-sections.md` IS written listing each section name + diff line count; stderr emits `claude-md-migration-blocked: <N> sections diverged — see <path>`; legacy merge still runs (zero disruption to existing flow)

- [x] **Scenario: ratification — operator moves candidate to CLAUDE.md**
  - **Given** a candidate file exists and operator runs `mv .claude/CLAUDE.md.migration-candidate.md CLAUDE.md`
  - **When** the next `sync-harness.sh --apply` runs
  - **Then** marker detection returns `paired` and managed-block merge applies; subsequent syncs are idempotent (no changes when Agent0 source unchanged)

### Region-level divergence (post-ratification)

- [x] **Scenario: region body diverged after ratification — refuse**
  - **Given** fork has paired markers (post-migration), but the content between markers differs from Agent0's current region content
  - **When** `sync-harness.sh --apply` runs
  - **Then** sync writes `.claude/CLAUDE.md.diverged-region.md` showing the diff; emits `!! claude-md: managed region diverged — move project customizations OUTSIDE markers, or accept Agent0 replacement via --force`; refuses with `customized-refused` increment

- [x] **Scenario: `--force` overrides region divergence**
  - **Given** fork has paired markers and divergent region content
  - **When** `sync-harness.sh --apply --force` runs
  - **Then** the region is replaced wholesale (fork's region edits are overwritten); stderr emits `! overwritten CLAUDE.md (region replaced under --force)`; counter `OVERWRITTEN` increments by 1

### Idempotency

- [x] **Scenario: idempotent re-sync — no Agent0 changes, no fork changes**
  - **Given** fork has paired markers and region content byte-identical to Agent0's current region
  - **When** `sync-harness.sh --apply` runs twice in a row
  - **Then** first run reports `= up to date CLAUDE.md`; second run reports identical; no file mutations; counter `UP_TO_DATE` increments by 1 each run

### Agent0 self-host

- [x] **Scenario: Agent0's own CLAUDE.md wraps its capacity sections in markers**
  - **Given** `/home/goat/Agent0/CLAUDE.md` after this spec ships
  - **When** any reader scans the file
  - **Then** exactly one `<!-- AGENT0:BEGIN -->` precedes `## Spec-driven development` (or whichever capacity is first) and exactly one `<!-- AGENT0:END -->` follows the last capacity section (typically `## Compact Instructions`); project-narrative sections (Overview, Stack, Build & test, Conventions, Gotchas) remain above BEGIN

- [x] **Scenario: orphan `## Prototype skill` removed from acmeyard on first managed-block sync**
  - **Given** acmeyard ratified migration (markers paired) and `## Prototype skill` exists inside its Agent0 region (legacy orphan from pre-spec-048 sync)
  - **When** managed-block merge runs against Agent0 source (which lacks `## Prototype skill`)
  - **Then** the resulting CLAUDE.md has no `## Prototype skill` section (region replaced wholesale = orphan dropped); `git diff` shows the section removed

### Static facts

- [x] `merge_managed_block()` function defined in `.claude/tools/sync-harness.sh` and called from main after `merge_claude_md()` (or replaces it conditionally) — implemented as `_merge_claude_md_managed_block()` dispatched from refactored `merge_claude_md()`
- [x] `.claude/rules/harness-sync.md` has a new `## CLAUDE.md managed-block merge strategy` section documenting markers, the 4 detection states, migration flow, and the relationship to spec 016's legacy heading-set merge (fallback role)
- [x] At least 5 new test files under `.claude/tests/harness-sync/` covering the marker-detection states, candidate generation, per-section divergence refusal, region-level divergence refusal, and idempotent re-sync — 7 new tests (16-22)
- [x] `.claude/tests/harness-sync/run-all.sh` updated to iterate new test numbers
- [x] All existing spec-016 tests (01-15) continue to PASS post-implementation (no regression in legacy path)

## Non-goals

- **Generalization to `.mcp.json.example`, `.githooks/pre-commit`, `.gitleaks.toml`, etc.** CLAUDE.md only in v1. Refactor `merge_managed_block()` into a generic primitive only when a second file pulls demand. Other harness files have different customization profiles (JSON-with-comments, bash scripts, TOML) and don't fit managed-block idiomatically.
- **Three-way merge for region edits.** The managed region is intentionally Agent0-owned; fork customizations belong OUTSIDE markers as project sections. Three-way merge would create ambiguity about who owns what.
- **Auto-recovery for mismatched markers.** Heuristic recovery is fragile and risks silent data loss. Refuse with explicit error; fork developer fixes the broken state manually.
- **Multiple discrete Agent0 regions.** Single contiguous region only. If a future use case demands multiple regions (e.g., capacity section region + appendix region), revisit then.
- **Persisted breadcrumb tracking whether a fork ever had markers.** Stateless detection per sync — markers absent = use fallback, markers present = use managed-block. No `.claude/.migration-history.json` etc.
- **Removal of spec 016's heading-set merge.** Spec 016 stays shipped; its `merge_claude_md()` function is the fallback path for unmigrated forks. Removal can be considered after all known forks have migrated (revisit in 6 months).
- **`--migrate-claude-md` flag to force migration.** Advisory-only posture; migration is opt-in via the operator's manual `mv` of the candidate file. No flag to bypass the advisory.
- **Compact Instructions as a special anchor.** Deprecated by this spec — Compact Instructions becomes a regular capacity section inside the Agent0 region; its position is "wherever Agent0's source places it" (typically last in the region).
- **Cross-fork migration enforcement.** Each fork migrates on its own schedule. Agent0 emits the advisory each sync against an unmigrated fork; if multiple forks remain unmigrated for an extended period, consider deprecation in a follow-up spec.
- **Marker visibility in rendered Markdown.** HTML comment markers are intentionally invisible in GitHub-rendered Markdown. Operators inspecting the rendered docs won't see the structural delimiters; raw file inspection (`cat`, editor) is the surface for marker management.

## Open questions

- [ ] **Migration candidate file timestamp staleness threshold.** Should the candidate file embed a timestamp + emit a "stale" warning when Agent0 source changed materially since candidate was last generated (e.g., > 7 days old)? Lean yes — implementation simple (`stat -c %Y` compare); fork dev may have forgotten about a candidate and Agent0 has moved since. Resolve during implementation.
- [ ] **Should `merge_managed_block()` REPLACE `merge_claude_md()` or BE CALLED FROM it?** Two patterns: (a) `merge_claude_md()` detects markers state and dispatches to either managed-block or legacy heading-set; (b) two top-level functions called sequentially with state-aware branching. Lean (a) — single dispatch point cleaner. Confirm during plan.md drafting.
- [ ] **Region-replacement semantics when Agent0 source has zero capacity sections.** Edge case: hypothetical future where Agent0 ships a CLAUDE.md with only project-template sections (no capacities). What does the region between markers contain? Empty? `<!-- AGENT0:BEGIN -->\n<!-- AGENT0:END -->`? Lean toward empty region (just markers, no content) — preserves the placeholder for future capacity additions. Confirm in implementation.
- [ ] **Should migration candidate include a leading comment block explaining itself?** E.g., `<!-- This file was generated by sync-harness.sh on YYYY-MM-DD as a managed-block migration candidate. Review the wrapped layout below; if it matches your intent, mv this file to CLAUDE.md. -->`. Helpful for first-time operators; clutter for repeat. Lean yes for v1.
- [ ] **Test coverage for fork that NEVER migrates.** Should there be an explicit test asserting "5 syncs against unmigrated fork yields 5 candidate files (no errors, no infinite loop)"? Lean yes — exercises the long-tail fallback path. Add to test set.

## Context / references

- **`/home/goat/Agent0/.claude/tools/sync-harness.sh`** — the file being patched; currently has `merge_settings_json` and `merge_claude_md` (with append-only heading-set logic) and `merge_gitignore` (added by `fix(016)` 2026-05-19 — same shape this spec mirrors for the managed-block pattern).
- **`/home/goat/Agent0/.claude/rules/harness-sync.md`** — capacity doc to be extended with new `## CLAUDE.md managed-block merge strategy` section. Already documents spec 016 heading-set logic; the relationship between the two strategies is fallback (legacy) vs primary (managed-block).
- **Spec 016 (`/home/goat/Agent0/docs/specs/016-harness-sync/`)** — original sync-harness design. Stays shipped; not superseded. This spec is additive: introduces a new merge path that takes precedence when markers are present, falls back to spec 016 logic when absent.
- **Agent0 commit `7ecb2c9` `fix(016): sync-harness gitignore additive merge handler`** — just-shipped 2026-05-19; introduces `merge_gitignore()` with marker line + idempotent comm-based merge. This spec's `merge_managed_block()` mirrors that pattern's overall shape (marker + idempotent + advisory on first-time state).
- **Spec 048 (`/home/goat/Agent0/docs/specs/048-product-skill-foundation/`)** — the capacity rename that empirically created the orphan `## Prototype skill` in acmeyard's CLAUDE.md. Concrete motivating case for this spec.
- **Auditoria 2026-05-19** (this discovery session, prior turn) — empirical detection of the orphan section in acmeyard. Audit logic: `diff <(grep '^## ' Agent0/CLAUDE.md | sort) <(grep '^## ' acmeyard/CLAUDE.md | sort)` showed `## Prototype skill` present in acmeyard, absent in Agent0.
- **`.claude/rules/memory-placement.md`** — distinguishes rules (behavioral, shipped to forks) from project memory (factual reference, NOT shipped). This spec's behavior changes ship via `sync-harness.sh` + `harness-sync.md` rule — both propagate to forks correctly.
- **`.claude/memory/feedback_speculative_observability.md`** — rule-of-three demand test for audit/forensics. NOT applicable here: the gap was empirically observed in auditoria (N=1 manifestation in acmeyard); the fix is structural (a different merge algorithm), not observability. No new audit log is added.
- **Pattern precedent — managed-block in config files:** asdf/conda init blocks in `.bashrc`/`.zshrc` (`# >>> conda initialize >>>` ... `# <<< conda initialize <<<`), Ansible `blockinfile` module (`# BEGIN ANSIBLE MANAGED BLOCK` ... `# END ANSIBLE MANAGED BLOCK`), `.gitattributes` BEGIN/END for git-LFS, GitHub README badges (HTML comment delimiters). HTML comment shape chosen for Markdown idiomaticity + render-invisibility.
- **Discovery session 2026-05-19** (this `/sdd refine` session) — 4 rounds of decisions feeding this spec. Locked: HTML comment markers, bottom contiguous region, candidate-file-with-refuse migration, per-section + region-level divergence detection, CLAUDE.md-only scope, drop Compact Instructions anchor concept, fallback-with-advisory backward compat, 4-state marker detection with refuse for corrupted states.
