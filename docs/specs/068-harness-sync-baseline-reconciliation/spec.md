# 068 — harness-sync-baseline-reconciliation

_Created 2026-05-20._

**Status:** draft

## Intent

`sync-harness.sh` propagates the Agent0 harness to forks, but its merge sophistication is inconsistent across surfaces. `CLAUDE.md` got a managed-block marker merge (spec 058) and `settings.json` got a structured `jq` merge (spec 016) — both can tell *Agent0-owned* content apart from *fork-owned* content, and both propagate additions **and** removals. The plain-file path — the ~500 files under `.claude/hooks|rules|tools|validators|skills|tests`, i.e. the bulk of the harness — never got that upgrade. It still uses the spec-016-original whole-file `sha256` compare, which has only two states: `up-to-date` or `customized`.

That two-state model conflates two unrelated things: a file the fork *deliberately edited* and a file the fork simply *hasn't caught up on*. A fork that falls behind several specs sees **every** upstream change as `!! customized` and `sync-harness` refuses to touch it without `--force` — and `--force` is all-or-nothing, clobbering genuine fork customizations alongside stale files. There is no clean catch-up path, which undermines Agent0's core premise that the harness propagates to forks. The same gap also means the plain-file path cannot *delete*: a file Agent0 renamed or removed (live case: `templates/monorepo-skeleton/` → `templates/app-skeleton/`) orphans forever in the fork, because the sync walk only iterates Agent0's current files and never visits a fork-only orphan.

This spec adds the missing primitive — a **recorded sync baseline** (the Agent0 managed-file state as of the fork's last sync) — and uses it for **3-way reconciliation** on the plain-file path: `fork` vs `baseline` vs `agent0-current`. With three reference points, `sync-harness` can distinguish *stale* (auto-update, no `--force` needed) from *customized* (refuse, as today), and can propagate upstream *deletions* safely. The baseline record doubles as the sync audit log that `.claude/rules/harness-sync.md` § Audit currently defers to "a v2 spec".

## Acceptance criteria

- [ ] **Scenario: a stale plain file auto-updates without `--force`**
  - **Given** a fork with a recorded baseline, and a plain file whose fork copy still matches that baseline (the fork never edited it)
  - **When** Agent0's version of that file has since changed and `sync-harness --apply` runs **without** `--force`
  - **Then** the file is updated in the fork and reported as `stale` (updated), not `customized`, and the run is not refused on its account

- [ ] **Scenario: a genuinely customized file is still refused**
  - **Given** a fork with a recorded baseline, and a plain file whose fork copy differs from **both** the baseline and Agent0's current version
  - **When** `sync-harness --apply` runs without `--force`
  - **Then** the file is reported `!! customized`, counted in `customized-refused`, left untouched, and the run exits non-zero — identical to today's behavior for real customizations

- [ ] **Scenario: an upstream-removed file is deleted from the fork**
  - **Given** a file present in the recorded baseline that no longer exists in Agent0's manifest, and whose fork copy still matches the baseline
  - **When** `sync-harness --apply` runs
  - **Then** the file is removed from the fork and reported as `removed` (canonical case: `templates/monorepo-skeleton/` after the `app-skeleton` rename)

- [ ] **Scenario: an upstream-removed file the fork customized is NOT deleted**
  - **Given** a baseline file absent from Agent0's current manifest, but whose fork copy differs from the baseline (the fork customized it)
  - **When** `sync-harness --apply` runs
  - **Then** the file is preserved, reported as customized-and-upstream-removed, and the operator is told to resolve it manually — no silent deletion of fork work

- [ ] **Scenario: `--check` distinguishes stale from customized**
  - **Given** a drifted fork with a recorded baseline
  - **When** `sync-harness --check` runs
  - **Then** each plain file is labeled `up to date` / `stale` (would update) / `customized` (would refuse) / `removed` (would delete), so the operator sees the real catch-up picture before applying, and the exit code reflects drift

- [ ] **Scenario: the baseline is recorded on every `--apply`**
  - **Given** any `sync-harness --apply` run that completes (clean or with refusals)
  - **When** the run finishes
  - **Then** a baseline file exists in the fork capturing Agent0's managed-file sha-set as of this sync, so the next sync reconciles 3-way

- [ ] **Scenario: a fully-synced fork is idempotent**
  - **Given** a fork whose baseline is current and whose files all match Agent0
  - **When** `sync-harness --apply` runs again with no Agent0 changes
  - **Then** zero files are mutated, every plain file reports `up to date`, and the baseline file is unchanged

- [ ] An existing fork with **no baseline file** does not error: the first `--apply` degrades gracefully (per the bootstrap behavior resolved in Open Q1) and writes a baseline so subsequent syncs are 3-way.
- [ ] The `settings.json`, `CLAUDE.md`, and `.gitignore` merge paths are unchanged — this spec touches only the plain-file path (`process_file` and the walk).
- [ ] `.claude/tests/harness-sync/` gains regression tests covering each new state (`stale`, `removed`, customized-upstream-removed, bootstrap, idempotency).
- [ ] `.claude/rules/harness-sync.md` § Customization detection, § Manifest scope, § Audit, and § Gotchas are updated; the `## Harness sync` section of `CLAUDE.md` reflects the baseline mechanism.

## Non-goals

- **Gap C/D — `settings.json` issues.** Hook-rename orphans and non-propagating new harness-owned top-level keys are real but live in a different merge path (`merge_settings_json`). Out of scope here; candidate for a follow-up spec.
- **Gap F — `/product` `rm -r <out>` foot-gun.** The product skill's overwrite path destroys `.git` when `--out` is an existing repo. A genuine bug, but it is a skill issue, not a propagation issue — separate fix.
- **Whitespace-only false positives.** A fork that ran a formatter over a hook still shows `fork != baseline` → still flagged customized. 3-way does not fix this; the tool deliberately does not normalize whitespace. Unchanged.
- **Bidirectional sync.** Agent0 remains one-way upstream. Fork improvements still flow back via PR review, not this tool.
- **Auto-commit in the fork.** The post-sync `git diff` remains the review surface; `sync-harness` never commits.

## Open questions

- [ ] **Q1 — Bootstrap behavior for a fork with no baseline.** On the first sync under the new mechanism, files that *match* Agent0 trivially seed `baseline = agent0_sha`. Files that *differ* are the pre-baseline ambiguity — we cannot tell stale from customized. Options: (a) treat all differing files as `customized` on the first run (current behavior), record the baseline, let the *second* sync be fully 3-way; (b) add an `--adopt` flag where the operator declares "the fork is clean, take Agent0 wholesale and seed the baseline"; (c) if `--agent0-path` is a git repo, infer the baseline commit by best-match against Agent0 history. Resolve in `plan.md` after the copier/cruft research — copier's `copier update --vcs-ref` is direct prior art. _Owner: decided in plan._
- [ ] **Q2 — Baseline format.** Per-file sha manifest (`{path: agent0_sha_at_last_sync}`, self-contained, no git dependency — cruft-style) vs a single Agent0 git commit ref (lighter, but needs Agent0 history reachable to do `git show <ref>:<path>` — copier-style). Lean toward the per-file manifest for robustness; confirm against prior art in `plan.md`. _Owner: decided in plan._
- [ ] **Q3 — Baseline file location and git-tracking.** Likely `.claude/.harness-sync-baseline.json`. Git-tracked (travels on clone, like `.copier-answers.yml`) vs gitignored (per-machine sync bookkeeping)? Tracked seems right — a fresh clone of the fork should know its baseline — but it then appears in fork PR diffs. _Owner: decided in plan._
- [ ] **Q4 — Exit-code and counter semantics for the new states.** Does `stale`/`removed` count as drift in `--check` (yes, presumably)? New counters (`UPDATED`, `REMOVED`) vs folding into `COPIED`/`MERGED`? _Owner: decided in plan._

## Context / references

- `docs/specs/016-harness-sync/` — original sync tool; the plain-file `sha256` compare originates here
- `docs/specs/058-*` — `CLAUDE.md` managed-block marker merge; the in-repo prior art that solved stale-vs-customized for `CLAUDE.md` (and propagates removals — the orphan-removal fix this spec mirrors for the file tree)
- `docs/specs/060-harness-gaps-2026/` — harness-gaps umbrella; this spec closes a gap of that class
- `.claude/tools/sync-harness.sh` — `process_file()` (lines ~196-252) and `walk_copy_check()` (~254) are the locus; the manifest arrays (~128-151) define scope
- `.claude/rules/harness-sync.md` — § Customization detection (the 2-state model), § Manifest scope, § Audit ("None"; defers an audit log to "a v2 spec"), § Gotchas (the long-stale-fork large-diff note)
- **External prior art (to research in `plan.md`):** `copier` (records template version in `.copier-answers.yml`; `copier update` does 3-way reconciliation) and `cruft` (records the cookiecutter commit; `cruft update`) — both solve "update a project from an upstream template" with the recorded-baseline → 3-way model
- Session investigation 2026-05-20 — surfaced via the mei-saas `/product` dogfood prep: `sync-harness --check` reported the mei-saas fork's stale `/product` skill tree as `!! customized` and would have refused it without `--force`
