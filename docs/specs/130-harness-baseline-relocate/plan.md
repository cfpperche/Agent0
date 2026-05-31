# 130 — harness-baseline-relocate — plan

_Drafted from `spec.md` on 2026-05-31. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

A surgical, single-file behavior change in `sync-harness.sh` plus doc/test updates. Introduce a `LEGACY_BASELINE_FILE` constant alongside the repointed `BASELINE_FILE`; teach `load_baseline` to fall back to the legacy path when the new one is absent (read-side migration), and `write_baseline` to always write the new path and remove the legacy file after a successful write or on the idempotent path (write-side migration). Order is safety-first: never delete the legacy file before the new one is confirmed present, so a failed write can never lose the baseline. `--check`/`--dry-run` keep their existing no-write guard, so they read (with legacy fallback) but mutate nothing. Then update the rule + memory to the new path and migrate the test suite, adding one migration test.

## Files to touch

**Modify:**
- `.agent0/tools/sync-harness.sh`
  - `BASELINE_FILE` → `$CONSUMER_ROOT/.agent0/harness-sync-baseline.json` (line ~141); add `LEGACY_BASELINE_FILE="$CONSUMER_ROOT/.claude/harness-sync-baseline.json"`.
  - `load_baseline` (~290): read `$BASELINE_FILE`, else fall back to `$LEGACY_BASELINE_FILE` when present.
  - `write_baseline` (~612): write to `$BASELINE_FILE`; after a successful `mv` (and on the idempotent early-return), call a small `_remove_legacy_baseline` helper that `rm -f`s `$LEGACY_BASELINE_FILE` when present and logs `- baseline migrated (removed legacy .claude/...)`.
  - Update the header comment (~134) and the three log strings (632, 655, 658) to `.agent0/...`.
- `.agent0/context/rules/harness-sync.md` — § Sync baseline (path + "Git-tracked / non-dotted" rationale stays, dir changes), § Audit (`git log -- .agent0/harness-sync-baseline.json`), gotchas referencing the path; add a one-line § Path relocations note that the baseline moved (spec 130).
- `.agent0/memory/harness-home.md` — add the baseline to the `move (shipped)` disposition row with the spec-130 reference.
- `.agent0/tests/harness-sync/*baseline*.sh` (and any other hardcoding `.claude/harness-sync-baseline.json`) — repoint assertions to `.agent0/harness-sync-baseline.json`.

**Create:**
- `.agent0/tests/harness-sync/NN-baseline-legacy-migration.sh` — consumer with a legacy `.claude/` baseline → `--apply` reads it (no `!! customized` storm), writes `.agent0/` baseline, removes legacy; `--check` mutates nothing.

**Delete:** (none)

## Alternatives considered

### Leave the baseline in `.claude/` and just document why

Rejected — it violates Agent0's own `harness-home` "shared test" (the baseline is runtime-neutral, read by Codex-invoked `sync-harness.sh`), and the analogous `delegation-audit.jsonl` already moved (spec 119). Documenting an exception would entrench drift the umbrella 102 consolidation meant to eliminate.

### `git mv` the file during sync

Rejected — the tool never runs git operations on consumer trees (one-way, filesystem-only posture). It `rm`s the legacy + writes the new; the consumer's `git diff` captures both, same as every other relocation.

### Dual-write (keep both paths in sync indefinitely)

Rejected — that perpetuates the `.claude/` artifact forever and doubles the audit trail. A one-time migrate-and-remove is cleaner and matches spec-105.

## Risks and unknowns

- **Losing the baseline mid-migration** → mitigated by write-before-delete ordering; a failed `mv` leaves the legacy untouched.
- **A consumer `.gitignore` accidentally ignoring `.agent0/harness-sync-baseline.json`** → verify the new path is not matched by any glob (Agent0 ignores `.agent0/.runtime-state/` etc., dotted dirs — a non-dotted root file under `.agent0/` should be clear). Acceptance criterion checks this.
- **Tests hardcoding the old path** → grep the whole `.agent0/tests/` tree, not just `*baseline*` files, for `.claude/harness-sync-baseline.json`.
- **The mei-saas resync (goal step) will show the migration live** → new `.agent0/` baseline created, legacy `.claude/` one deleted; this is the acceptance validation, committed in the consumer.

## Research / citations

- `.agent0/tools/sync-harness.sh` lines 134–141 (def), 290–303 (load), 612–660 (write) — read in spec/plan drafting.
- `.agent0/memory/harness-home.md` — "shared test" + disposition matrix.
- spec 105 relocation of `sync-harness.sh` (`.claude/tools/`→`.agent0/tools/`) — the precedent migration pattern.
