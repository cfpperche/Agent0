# 130 — harness-baseline-relocate

_Created 2026-05-31._

**Status:** shipped

## Intent

Relocate the harness-sync baseline from `<consumer>/.claude/harness-sync-baseline.json` to `<consumer>/.agent0/harness-sync-baseline.json`, closing the last unmigrated harness surface from umbrella spec 102's `.claude/`→`.agent0/` consolidation. The baseline is a runtime-neutral harness artifact: it is read and written by `sync-harness.sh`, which Codex invokes directly (`bash .agent0/tools/sync-harness.sh`), and it is not a Claude-native on-disk format. Applying the `harness-home.md` "shared test" — _in a Codex-only consumer that never opens Claude Code, would this file still be read/written?_ — the answer is **yes**, so by Agent0's own classification principle the baseline belongs under `.agent0/`. Its sibling artifact `delegation-audit.jsonl` was already moved to `.agent0/` (spec 119); the baseline was simply overlooked — it never appears in umbrella 102's disposition matrix. The current `.claude/` location is hardcoded inertia (`sync-harness.sh:141`, predating the consolidation), not a deliberate design choice. This drift was surfaced during the spec-129 mei-saas resync (2026-05-31).

The relocation must be a one-time, self-migrating move that never loses the baseline mid-flight (a lost baseline would make the next `--apply` refuse every differing file as `!! customized`). The mechanism mirrors the spec-105 relocation of `sync-harness.sh` itself (`.claude/tools/`→`.agent0/tools/`): the tool reads from the legacy path when the new one is absent, writes to the new path, and removes the legacy file — the consumer sees the new file created and the old one deleted in its post-sync `git diff`, exactly the audit posture every other relocation took.

## Acceptance criteria

- [x] **Scenario: new consumer writes baseline at the new location**
  - **Given** a consumer with no baseline at either path
  - **When** `sync-harness.sh --apply` runs
  - **Then** it writes `<consumer>/.agent0/harness-sync-baseline.json` (non-dotted name preserved) and writes nothing at `.claude/harness-sync-baseline.json`

- [x] **Scenario: legacy baseline auto-migrates on next apply**
  - **Given** a consumer whose baseline lives only at `.claude/harness-sync-baseline.json` (pre-130 state)
  - **When** `sync-harness.sh --apply` runs
  - **Then** the tool reads the legacy baseline for 3-way reconciliation (no spurious `!! customized` storm), writes the fresh baseline to `.agent0/harness-sync-baseline.json`, and removes the legacy `.claude/` file — both changes visible in the consumer's `git diff`

- [x] **Scenario: new location is authoritative when both exist**
  - **Given** a consumer that somehow has baselines at both paths
  - **When** the tool loads the baseline
  - **Then** it reads `.agent0/harness-sync-baseline.json` (the new location wins) and removes the legacy `.claude/` file on the next `--apply`

- [x] **Scenario: `--check` and `--dry-run` never mutate either path**
  - **Given** any consumer state (legacy, new, or both)
  - **When** `sync-harness.sh --check` or `--apply --dry-run` runs
  - **Then** the tool reads whichever baseline exists (legacy fallback included) but creates, moves, or deletes nothing

- [x] **Scenario: idempotent re-sync after migration**
  - **Given** a consumer already migrated to `.agent0/harness-sync-baseline.json`
  - **When** `--apply` runs again with no managed-file changes
  - **Then** the baseline files-map is byte-identical so the file is left untouched (no `synced_at` churn), and no legacy file is recreated

- [x] `sync-harness.sh` defines the baseline at `.agent0/harness-sync-baseline.json` and a `LEGACY_BASELINE_FILE` at `.claude/harness-sync-baseline.json`; all read/write/log strings reference the new path.

- [x] The new path is NOT covered by any `.gitignore` glob (the baseline must stay git-tracked for fresh clones); verified against Agent0's and a consumer's `.gitignore`.

- [x] The baseline remains absent from every `COPY_CHECK_*` array (still a consumer-side artifact, never shipped).

- [x] `.agent0/context/rules/harness-sync.md` (§ Sync baseline, § Audit, gotchas) and `.agent0/memory/harness-home.md` (disposition matrix: add baseline to `move`) are updated to the new path.

- [x] Existing `.agent0/tests/harness-sync/*baseline*.sh` pass against the new path, and a new test covers the legacy→new migration + removal.

## Non-goals

- Backfilling the stale `agent0_commit` breadcrumb from the spec-129 mei-saas sync. That is a cosmetic field that self-corrects on the next content-changing sync; this spec is about file location, not breadcrumb accuracy.
- Changing the baseline's JSON shape, the 3-way reconciliation algorithm, or the non-dotted filename. Only the directory moves.
- Auto-migrating via `git mv`. The tool mutates the filesystem (rm legacy + write new); the consumer reviews and commits the diff, same one-way posture as every harness mutation.
- Shipping the baseline through the manifest. It stays consumer-side and unsynced.
- A flag to opt out of the relocation. The move is unconditional, like the spec-105 `sync-harness.sh` relocation.

## Open questions

_All resolved during investigation (2026-05-31); recorded with rationale._

- [x] **Remove the legacy file, or leave it for the consumer? — RESOLVED: the tool removes it.** Mirrors spec-105, where the consumer's old `.claude/tools/sync-harness.sh` was removed as part of the relocation `--apply`. The baseline is tool-owned (gotcha: "let `--apply` maintain it"), so there is no consumer customization to preserve. Removal happens on `--apply` only (after the new file is written), never on `--check`/`--dry-run`.
- [x] **Read precedence when both exist — RESOLVED: new wins.** If `.agent0/` baseline exists, use it and treat `.claude/` as a stale leftover to delete. Only fall back to the legacy path when the new one is absent.
- [x] **One-time crash like spec-105's self-rebootstrap? — RESOLVED: no.** The self-rebootstrap hazard is specific to `sync-harness.sh` overwriting itself mid-read. The baseline is data the script reads/writes, not the script being executed, so relocating it carries no re-exec hazard.

## Context / references

- `.agent0/memory/harness-home.md` — the `.claude/` vs `.agent0/` classification principle (umbrella 102); the baseline passes the "shared test" → `.agent0/`. Its disposition matrix omits the baseline; this spec adds it.
- `.agent0/context/rules/harness-sync.md` § Sync baseline / § Audit / § Path relocations — current contract documenting the `.claude/` path; updated here.
- `.agent0/tools/sync-harness.sh` — `BASELINE_FILE` at line 141; read sites (291, 296, 627–629), write sites (653–658). Mirror the spec-105 relocation pattern.
- spec 102 (`102-harness-consolidate-agent0`) — the umbrella this closes; spec 119 already moved the analogous `delegation-audit.jsonl` to `.agent0/`.
- spec 129 mei-saas resync (2026-05-31) — the dogfood that surfaced the drift; this spec's resync of mei-saas is the live validation.
