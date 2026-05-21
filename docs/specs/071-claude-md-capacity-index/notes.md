# 071 — claude-md-capacity-index — notes

_Created 2026-05-21._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-21 — parent — The CLAUDE.md merge was never "append-only" — spec framing corrected

`spec.md` § Intent and `plan.md` framed the problem as "the CLAUDE.md merge is append-only and won't replace sections." Reading `sync-harness.sh` showed the real picture: `merge_claude_md` dispatches by the *fork's* marker state. A fork with paired `AGENT0:BEGIN/END` markers already runs `_merge_claude_md_managed_block`, which **replaces the region wholesale** — append-only is only the `_merge_claude_md_legacy` fallback for un-migrated (no-marker) forks. The real bug was narrower and sharper: the managed-block merge had **no baseline**, so it refused on *any* body divergence of a shared section (`_check_region_divergence`) — unable to tell "Agent0 changed the body" (stale) from "the fork changed it" (customized). After 071's compression every section body differs, so every already-migrated fork would have been refused. The fix (baseline 3-way) is exactly what the plan said; only the framing of *why* was imprecise.

### 2026-05-21 — parent — AC7 scenario wording ("managed block inserted") was imprecise

`spec.md` AC7 said a fork with no markers gets "the managed block inserted (current behavior)." The actual current behavior: a no-marker fork routes to the legacy heading-set append + a migration-candidate file for the operator to `mv`-ratify — there is no automatic block insertion. 071 leaves that path untouched; the no-marker path is covered (unchanged) by the existing test 17. AC7 is satisfied in substance — the no-marker fork is handled, and handled the same as before 071 — but the "inserted" word overstated it.

## Deviations

### 2026-05-21 — parent — `set -e` landmine in record_managed_block_manifest

First full test run after the sync-harness.sh change: 22 of 31 scenarios failed — far beyond the 3 CLAUDE.md tests expected to need updating. Root cause: `record_managed_block_manifest` used `[ cond ] || return` on its skip paths. A bare `return` propagates the failed test's exit code; under the script's `set -euo pipefail`, the function returning non-zero as a bare statement in `main` aborted the whole script right after `walk_copy_check` — so `write_baseline` and every merge never ran. Fix: `|| return 0` on both skip paths (the `if/then/fi`-with-no-else pattern that `record_manifest` uses is the other safe shape). After the one-character-class fix, 28/31 passed — the remaining 3 were the genuine behavior-change failures.

### 2026-05-21 — parent — Test plan revised: update 16/19/22 in place + 1 new test, not 3 brand-new

`tasks.md` task 6 said "3 new tests (stale / customized / no-marker)." Implementation revised this. Tests 16 / 19 / 22 were spec-058 tests asserting the *old* managed-block behavior (wholesale replace gated by body-divergence); 071 changes that behavior, so those 3 tests genuinely had to be rewritten regardless. Rewriting them to the post-071 baseline-aware shape (each now a 2-phase test: sync once to seed the baseline, then mutate, then sync again) makes them cover stale-auto-update (16, added section), customized-refuse + `--force` (19), and stale-orphan-removal (22). Only the genuinely-uncovered case — paired markers + region differs + **no baseline** (the first-sync friction) — needed a brand-new file: `32-claude-md-managed-block-no-baseline-refuse.sh`. Net: 3 rewritten + 1 new, `run-all.sh` extended to `32`. Cleaner than 3-new-plus-3-broken-old, same coverage.

## Tradeoffs

### 2026-05-21 — parent — 2-phase tests (sync-to-seed) over hand-seeded baseline JSON

Tests 16/19/22 need a baseline whose `CLAUDE.md#managed-block` entry matches the fork's region. Test 24 (plain file) hand-writes `harness-sync-baseline.json` with a `sha256sum` of the file — simple. The managed-block region sha is NOT a plain file sha: `_region_sha` is `printf '%s\n' "$(_extract_region …)" | sha256sum`, with command-substitution trailing-newline stripping. Hand-seeding would couple each test to that exact newline handling — fragile. Chosen instead: a first `--apply` with fork-region == Agent0-region lets the tool record the baseline itself, then phase 2 mutates and re-syncs. Costs one extra sync per test; buys robustness — the test never reproduces an internal hashing formula.

## Open questions

_None open — OQ1/OQ2/OQ3 were resolved in plan.md § Approach (the per-section-append retire, the synthetic baseline key, the one-line entry shape)._
