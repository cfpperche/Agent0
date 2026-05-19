# 058 — claude-md-managed-block — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

**Single dispatch, single file, single new function — patch spec 016 in place.** All implementation concentrates in `.claude/tools/sync-harness.sh`. The existing entry point `merge_claude_md()` becomes a dispatcher: it calls `detect_marker_state()` and routes to one of three paths: (a) `paired` → managed-block replace via new helper `_merge_claude_md_managed_block()`; (b) `absent` → spec 016 legacy logic (extracted into `_merge_claude_md_legacy()` helper for clarity) PLUS candidate generation via `_generate_migration_candidate()`; (c) `mismatched`/`nested-invalid` → refuse with explicit error. The public function name `merge_claude_md` stays stable — no external call site changes.

Implementation order pivots on Agent0's own CLAUDE.md being the **first test vehicle**: Day 1 wraps Agent0's CLAUDE.md with markers and validates by syncing into a scratch fork, before any other fork sees the change. This dogfood-by-design is what spec 058 demonstrates is the right shape for spec 016 going forward (the orphan section finding from the 2026-05-19 audit would have surfaced if Agent0 itself had been wrapped during spec 048's rename). Once Agent0 source is wrapped, the new code paths can be exercised against real content, not just synthetic test fixtures.

Day 1 (~6 hours): detect_marker_state + paired-state replace + Agent0's CLAUDE.md wrapping + scratch-fork validation. Day 2 (~6 hours): candidate generation + per-section divergence + region-level divergence + 7 tests + doc update + acmeyard dogfood migration → ship.

## Files to touch

### Modify

**`/home/goat/Agent0/.claude/tools/sync-harness.sh`** — central change. Replace the body of `merge_claude_md()` with dispatch logic (~10 lines). Add 5 helper functions (~60-80 lines total):
- `detect_marker_state()` — scans target file for `<!-- AGENT0:BEGIN -->` and `<!-- AGENT0:END -->`; returns one of `absent` / `paired` / `mismatched` / `nested-invalid` via stdout
- `_merge_claude_md_managed_block()` — handles paired state: extract Agent0 region (between markers) from source; check region-level divergence vs fork (refuse-or-force-overwrite); replace region in fork while preserving everything outside markers
- `_merge_claude_md_legacy()` — extracts the existing spec 016 heading-set body verbatim (this is just a rename of the current `merge_claude_md` body)
- `_generate_migration_candidate()` — checks per-section divergence first (refuse-and-write-diverged-sections.md if found); otherwise builds wrapped layout (project headings on top, Agent0 region with current source content, markers wrapping it); writes to `.claude/CLAUDE.md.migration-candidate.md`; emits advisory line
- `_extract_section_body()` — already exists as `extract_section` in spec 016 logic; reuse without modification

**`/home/goat/Agent0/CLAUDE.md`** — one-time wrapping. Insert `<!-- AGENT0:BEGIN -->` between the last project-narrative section (`## Gotchas`) and the first capacity section (`## Spec-driven development`). Insert `<!-- AGENT0:END -->` after the last line of `## Compact Instructions`. No reordering needed; current section order already has project sections on top and capacities below. Validate by reading the diff: ~2 line additions, zero deletions.

**`/home/goat/Agent0/.claude/rules/harness-sync.md`** — add a new `## CLAUDE.md managed-block merge strategy` section between `## .gitignore merge strategy` and `## CLAUDE.md merge strategy` (the existing spec 016 section, retitled to `## CLAUDE.md heading-set merge strategy (legacy fallback)`). Cross-reference: the new section is primary, the renamed section is the fallback. ~50 lines added net.

**`/home/goat/Agent0/.claude/tests/harness-sync/run-all.sh`** — extend the iteration array from `01 02 ... 15` to `01 02 ... 22`.

### Create

Seven new test scenarios under `/home/goat/Agent0/.claude/tests/harness-sync/`:

- `16-claude-md-paired-markers-replace.sh` — paired markers + Agent0 source has new section → fork's region replaced; project sections above BEGIN preserved verbatim; everything below END (if any) preserved verbatim
- `17-claude-md-absent-markers-fallback.sh` — no markers in fork → legacy heading-set append still runs (back-compat verified) AND `.claude/CLAUDE.md.migration-candidate.md` written; advisory line on stderr
- `18-claude-md-mismatched-markers-refuse.sh` — only BEGIN present (no END) → refuse; same test with only END present (no BEGIN) → refuse; CUSTOMIZED_REFUSED counter increments
- `19-claude-md-region-divergence-refuse.sh` — paired markers, fork edited body INSIDE region → refuse + `.claude/CLAUDE.md.diverged-region.md` written; same scenario with `--force` → region replaced, `OVERWRITTEN` counter increments
- `20-claude-md-section-divergence-blocks-migration.sh` — no markers + fork rewrote an Agent0-titled section body → candidate generation BLOCKED + `.claude/CLAUDE.md.diverged-sections.md` written; legacy fallback merge still runs
- `21-claude-md-idempotent-managed-block.sh` — paired markers, region matches Agent0 → first sync = `up to date`, second sync = `up to date` (no mutations)
- `22-claude-md-removes-orphan-section.sh` — the canonical motivating case: fork's region contains `## Prototype skill` (Agent0 dropped it); after sync, fork's CLAUDE.md no longer contains that section (region replaced wholesale)

### Delete

None. Spec 016's logic is preserved (renamed to a helper) rather than removed. Backward compatibility is the whole point of the fallback path.

## Alternatives considered

### Two top-level functions called sequentially (`merge_claude_md` + `merge_managed_block`)

Rejected. The main loop in `sync-harness.sh` would need to coordinate which one runs and when; adding state to the main loop is more error-prone than centralizing dispatch in `merge_claude_md` itself. With the chosen approach, the main loop is unchanged (still calls `merge_claude_md` once), and all branching lives in one function — easier to audit and test.

### Auto-wrap migration on first sync (the path Round 2 explicitly rejected)

Rejected. If a fork rewrote the body of an Agent0-titled section, auto-wrap would silently put the rewritten content inside the managed region, and the next sync would replace it — silent data loss. The chosen candidate-file-with-refuse approach exposes the divergence to the operator and lets them resolve per-section.

### Generalize `merge_managed_block` as a reusable primitive in this spec

Rejected. YAGNI. Only CLAUDE.md has empirical demand (the audit found the orphan). Refactoring the function into a generic primitive when a second file pulls the same shape is cheaper than designing the abstraction up-front against unknown future use cases. The signature `_merge_claude_md_managed_block()` is intentionally CLAUDE.md-scoped; if `.mcp.json.example` or another file later needs the same logic, the rename to `_merge_managed_block(file, marker_begin, marker_end)` is mechanical.

### H2 sentinel headings (`## ⛔ Agent0-managed`) instead of HTML comments

Rejected during Round 1. Visible in rendered Markdown; risks collision with fork-authored headings; clutters the table of contents in GitHub renders. HTML comments are invisible, idiomatic in Markdown (GitHub README badge sections use the same shape), and trivially grep-able.

### Hard-refuse unmigrated forks (no fallback to legacy spec 016 logic)

Rejected during Round 3. Disruption higher than fix value: every fork would be forced to migrate on its next sync, even if the fork dev isn't ready. Advisory-with-fallback matches Agent0's general posture (`lint-advisory:`, `typecheck-advisory:`, `tdd-advisory:`) and keeps spec 058 zero-disruption to existing forks.

### Persisted breadcrumb tracking marker history (e.g., `.claude/.harness-state/claude-md-migration.json`)

Rejected. Adds state to the harness; stateless detection per-sync is simpler and equally correct. If markers go away (operator accidentally deleted them), fallback path runs again — that's the right behavior, not a bug to detect via persistence.

## Risks and unknowns

1. **Agent0's own CLAUDE.md wrapping is the single riskiest change.** Markers in the wrong place mean every fork's sync writes a wrong region. Mitigation: Day 1 Step 3 explicitly validates by `cp /home/goat/Agent0/CLAUDE.md /tmp/scratch-source/CLAUDE.md && bash sync-harness.sh --apply --agent0-path=/tmp/scratch-source /tmp/scratch-fork` and inspects the diff manually before committing the Agent0 CLAUDE.md change.

2. **Marker collision in fork content.** Fork CLAUDE.md could legitimately contain the string `<!-- AGENT0:BEGIN -->` (e.g., quoted inside a documentation section about this very mechanism). Mitigation: `detect_marker_state()` uses line-anchored grep (`^<!-- AGENT0:BEGIN -->$`), so the marker must be on its own line to count. Document the convention. Probability low (markers in docs are usually fenced inside ``` blocks where they're still grep-matched but easy to see in `diff`).

3. **Bash 3.2 / macOS portability.** Per `.claude/rules/harness-sync.md` § Gotchas: no `mapfile`, no `declare -A`. New helpers must follow. Mitigation: pattern-copy from existing `merge_settings_json` / `merge_gitignore` functions which already comply.

4. **Test infrastructure for marker-state matrices.** Each test sets up SRC + FORK with specific marker states. Risk: copy-paste drift between tests. Mitigation: a shared bash helper `make_wrapped_claude_md()` in `.claude/tests/harness-sync/_helpers.sh` (new file) accepting `(project_sections, agent0_sections)` and producing the wrapped output. Saves ~30% boilerplate per test.

5. **Fork dev workflow ambiguity for in-region customization.** Some operators may try to add notes inside the managed region (e.g., "for this fork, X behaves differently") and get the divergence-refuse error on next sync. Risk of friction. Mitigation: the `harness-sync.md` § Migration section explicitly documents the convention "customize outside markers"; the refuse message names the file (`.claude/CLAUDE.md.diverged-region.md`) so the diff is visible.

6. **Candidate file staleness.** A fork dev who generates a migration candidate, then waits a week before reviewing, may get a candidate that doesn't reflect Agent0's current state (Agent0 changed in the interim). Open question in `spec.md` (Q1). Provisional resolution: write a leading comment in the candidate file with the source SHA at generation time + a Markdown note advising re-run if stale.

7. **acmeyard dogfood reveals unforeseen interaction.** Real-world fork has 24 intermixed sections, including `## Prototype skill` orphan, plus project-narrative sections (Overview, Stack, etc. — likely currently above the would-be BEGIN marker). Mitigation: Day 2 includes manual review of the generated candidate before `mv` — if anything looks wrong, iterate on the candidate generator before declaring v1 done.

8. **Spec 016 documentation rewrite scope creep.** Renaming `## CLAUDE.md merge strategy` to `## CLAUDE.md heading-set merge strategy (legacy fallback)` is fine, but the body text may need adjustments to make the fallback role clear. Mitigation: time-box doc edits to 30 min; if it bloats, defer body rewrites to a follow-up doc-only commit.

## Research / citations

- **`/home/goat/Agent0/docs/specs/058-claude-md-managed-block/spec.md`** — this fork's spec, 4-round discovery synthesis. Every decision in this plan traces back.
- **`/home/goat/Agent0/.claude/tools/sync-harness.sh`** — the file being patched. Current functions: `process_file`, `merge_settings_json`, `merge_claude_md` (the one being expanded), `merge_gitignore` (just shipped in commit `7ecb2c9`). Same shell style and shape throughout.
- **`/home/goat/Agent0/.claude/rules/harness-sync.md`** — capacity doc. Already documents spec 016 (heading-set merge) and the just-shipped `.gitignore` merge. New section slots in between, before the `## Manifest scope` section.
- **`/home/goat/Agent0/.claude/tests/harness-sync/`** — existing 15 tests (after `fix(016)` added 13/14/15). Same pattern: SRC + FORK in mktemp dir, run TOOL, assert output/exit/state. Tests 5-7 are the closest in shape (settings.json + CLAUDE.md merge tests).
- **`/home/goat/Agent0/CLAUDE.md`** — current state has 23 `## ` headings: 5 project-narrative (Overview, Stack, Build & test, Conventions, Gotchas) on top, 18 capacities below (Spec-driven development through Compact Instructions). Wrapping is a 2-line insertion.
- **Commit `7ecb2c9` `fix(016): sync-harness gitignore additive merge handler`** (2026-05-19) — the just-shipped pattern this spec mirrors structurally. Marker line + idempotent re-run + advisory-on-anomaly are all repeated patterns.
- **Spec 048 (`/home/goat/Agent0/docs/specs/048-product-skill-foundation/`)** — the rename that empirically created the orphan. The motivating case for spec 058 is concrete and reproducible.
- **2026-05-19 audit conversation** (this session, prior turn) — diff `<(grep '^## ' Agent0/CLAUDE.md | sort) <(grep '^## ' acmeyard/CLAUDE.md | sort)` empirically detected `## Prototype skill` present in acmeyard, absent in Agent0. The fix this spec ships removes the orphan automatically once acmeyard ratifies migration.
- **Pattern precedents — managed-block in config files:**
  - asdf init blocks in `~/.bashrc`: `# >>> asdf initialize >>>` ... `# <<< asdf initialize <<<`
  - Ansible `blockinfile` module: `# BEGIN ANSIBLE MANAGED BLOCK` ... `# END ANSIBLE MANAGED BLOCK`
  - `.gitattributes` BEGIN/END for git-LFS-managed entries
  - GitHub README badge generators (shields.io, badgen) use HTML comment delimiters: `<!-- bage-start -->` ... `<!-- badge-end -->`
  - The HTML comment shape was chosen for Markdown idiomaticity + render-invisibility, NOT because there's a single canonical precedent; the convention is established practice across multiple tools.
