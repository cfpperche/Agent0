# 072 — sync-harness-self-overwrite

_Created 2026-05-21._

**Status:** shipped

## Intent

`.claude/tools/sync-harness.sh` is itself in the propagation manifest — the tool that syncs a fork's harness also syncs *itself*. When a fork's copy of the script is stale relative to Agent0, an `--apply` run overwrites the running script's own file on disk. Bash does not slurp a script into memory; it reads and executes incrementally, tracking a byte offset into the file. Replacing the file mid-run means subsequent reads pull bytes from the *new* file at the *old* offset — the running process executes misaligned content and crashes, or, worse, silently executes the wrong code. This was observed empirically on 2026-05-21 while validating specs 069/070/071 against the mei-saas fork: run 1 of `sync-harness.sh --apply` died with `line 1234: src: unbound variable` after the script had overwritten its own file with Agent0's newer version. The failure is "self-healing" only in the narrow sense that run 1 leaves the script current so a re-run is clean — but the run aborts partway (leaving the fork partially synced), the crash looks like data corruption, the operator gets no signal that "just re-run" is the remedy, and the lucky crash is not guaranteed (silent mis-execution is the worse outcome). Every fork upgrading across any change to `sync-harness.sh` itself hits this. This spec makes the tool never execute from the file it is about to overwrite.

## Acceptance criteria

- [x] **Scenario: a self the run will overwrite does not crash the run**
  - **Given** a fork whose `.claude/tools/sync-harness.sh` the current run will overwrite (it is stale and baseline-matching, or customized under `--force`)
  - **When** the operator runs `sync-harness.sh --apply` once
  - **Then** the run completes in a single invocation with exit 0 — no `unbound variable` / syntax-error crash — and the fork's `sync-harness.sh` ends updated to Agent0's version

- [x] **Scenario: an up-to-date self adds no overhead**
  - **Given** a fork whose `sync-harness.sh` already matches Agent0's
  - **When** `sync-harness.sh --apply` or `--check` runs
  - **Then** no re-exec / rebootstrap step occurs and behavior is byte-identical to today

- [x] **Scenario: a customized-and-refused self is not rebootstrapped**
  - **Given** a fork that customized its `sync-harness.sh` and runs `--apply` without `--force`
  - **When** the sync runs
  - **Then** `sync-harness.sh` is reported customized-refused as today; because the run will not overwrite it, no rebootstrap occurs and no crash happens

- [x] The `harness-sync` test suite gains a scenario that stages a stale `sync-harness.sh` in a fixture fork, runs `--apply`, and asserts single-run completion with no crash; `run-all.sh` includes it and passes.

- [x] `.claude/rules/harness-sync.md` documents the self-rebootstrap behavior and the one-time transitional crash that pre-072 forks still hit on the upgrade that installs the fix, with the "re-run `--apply`, it is clean" remedy.

## Non-goals

- **Retroactively protecting the pre-072 → 072 upgrade itself.** A fork already deployed runs its *old* (pre-fix) `sync-harness.sh` on the upgrade that installs 072 — the old script has no rebootstrap guard, so it still self-overwrites once. 072 cannot fix the run that installs it; it prevents every run after. The transitional crash is documented (see the harness-sync.md criterion) and auto-heals on re-run, the same shape as 071's one-time `--force`.
- **The 2 residual spec-citation leaks from the same 2026-05-21 mei-saas validation** — the migration-candidate banner emitting `(spec 058)`, and the `.gitignore` comment carrying `Spec 007`. Those are 070-lineage propagation-hygiene follow-ups (de-leaking tool-generated text / scrubbing additive-merge files), a different problem from self-overwrite. They belong in a separate spec even though one of them happens to live in `sync-harness.sh` too — "same file" is not "same concern."
- **A general framework for self-modifying files.** `sync-harness.sh` is the unique manifest file that overwrites itself *while executing* — hooks and validators run outside the sync. The fix is scoped to this one script, not generalized.
- **Changing what the manifest syncs.** The manifest contents and the 3-way reconciliation are untouched; 072 changes only *how* the script protects its own process.

## Open questions

- [x] Q1 — Fix approach: **A** re-exec from a temp copy of Agent0's script at startup (single-run, invisible to the operator) vs **B** process `sync-harness.sh` last and exit with a "re-run to complete" message (simpler, but a deliberate permanent two-run cost). Leaning A. Owner: resolve in plan.md with the user.
- [x] Q2 — Detection point: a standalone pre-flight `diff` of the two `sync-harness.sh` files at startup, before the manifest loop (the loop writes the file too late to guard from inside it). Confirm pre-flight placement and that it correctly skips the customized-refused case (no overwrite → no rebootstrap). Resolve in plan.md.
- [x] Q3 — Re-exec safety (if approach A): the env-var marker that prevents an infinite re-exec loop (e.g. `AGENT0_SYNC_REBOOTSTRAPPED=1`), forwarding of the original args through `exec`, and temp-file cleanup via an `EXIT` trap. Resolve in plan.md.

## Context / references

- Empirical trigger — session 2026-05-21, validating specs 069/070/071 against the mei-saas fork; `sync-harness.sh --apply` run 1 crashed (`line 1234: src: unbound variable`) after self-overwrite. Run 2 was clean because the script was already current.
- `.claude/tools/sync-harness.sh` — the tool; the fix lives here.
- `.claude/rules/harness-sync.md` — the propagation manifest + the doc this spec updates.
- `docs/specs/071-claude-md-capacity-index/` — changed `sync-harness.sh`, which made every pre-071 fork's copy stale and surfaced this latent bug.
- `docs/specs/068-harness-sync-baseline-reconciliation/` — the 3-way reconciliation the self-check must stay consistent with.
- The classic Unix hazard: replacing a shell script while bash is executing it — bash reads scripts incrementally, so an in-place overwrite corrupts the running process.
