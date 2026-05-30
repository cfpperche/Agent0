# 118 — move-validators-tests-to-agent0 — plan

_Drafted from `spec.md` on 2026-05-29. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

A pure path-relocation mirroring spec 105's playbook. The reference set is unusually wide (213 test files, ~10 rules, 3 `.agent0/hooks/`, the sync-harness manifest, 2 memories, README) but every reference is a literal `.claude/tests` or `.claude/validators` string that swaps to the `.agent0/` equivalent — so the bulk is a single scoped global substitution, with four genuinely delicate spots verified by hand afterward.

Order: (1) `git mv` both dirs so files live at the new home first (history preserved). (2) Global scoped sed of the two literal prefixes across **every tracked file except `docs/specs/` and `.git/`** — this catches the moved test scripts' internal refs, the validator's self-header, the manifest, the path-scoped rule frontmatter, the hooks, the rules' bodies, the memories, and the README in one pass. (3) Hand-verify the four delicate spots the sed touches but that carry correctness weight: the sync-harness manifest arrays, the two path-scoped rule `paths:` frontmatter triggers, the propagation-advise shipped-surface set, and the delegation-verify default validator path. (4) Run every suite from the new location + the assertion-sensitive harness-sync / instruction-drift / propagation-advisory suites.

**Live vs frozen (the scoping invariant, from spec 105):** rewrite every reference *outside* `docs/specs/`; leave every reference *inside* `docs/specs/NNN-*/` untouched (frozen design memory) — including this spec 118, whose `.claude/...` mentions correctly describe the *source* of the move and must read literally. ⚠️ **The file-list filter MUST anchor on the real path shape** — `grep -r` emits paths *without* a leading `./`, so a `grep -v '/docs/specs/'` exclusion silently fails (no leading slash to match) and the sed corrupts every frozen spec. Exclude with `grep -vE '(^|/)docs/specs/'` or prune the find before sed. (This bug fired once during implementation — see notes.md; recovered via `git checkout HEAD -- docs/specs/`.)

**Why sed is safe here:** the two target strings (`.claude/tests`, `.claude/validators`) are unambiguous — no other meaning exists in the tree, and the sibling `.claude/rules` / `.claude/hooks` / `.claude/skills` / `.claude/agents` / `.claude/worktrees` paths (which stay) do not share the prefix, so a prefix-anchored replace cannot touch them. CLAUDE.md/AGENTS.md/settings.json/codex-config carry zero refs (verified pre-flight), so no managed-block byte-equality risk.

## Files to touch

**git mv (the relocation itself):**
- `.claude/validators/run.sh` → `.agent0/validators/run.sh`
- `.claude/tests/` (23 dirs, 213 files) → `.agent0/tests/`
- Confirm `.claude/validators` and `.claude/tests` hold no tracked files afterward (dirs removed)

**Modify — sync-harness.sh manifest (delicate spot 1):**
- `COPY_CHECK_RECURSIVE`: `.claude/tests` → `.agent0/tests`
- `COPY_CHECK_GLOBS`: `.claude/validators|*.sh` → `.agent0/validators|*.sh`
- `COPY_CHECK_EXCLUDE`: `.claude/tests/propagation-advisory/*` → `.agent0/tests/propagation-advisory/*`

**Modify — path-scoped rule frontmatter (delicate spot 2 — functional triggers):**
- `.claude/rules/lint-validator.md` — `paths: .claude/validators/run.sh` → `.agent0/validators/run.sh`
- `.claude/rules/typecheck-advisory.md` — same

**Modify — propagation-advise.sh shipped-surface set (delicate spot 3):**
- line 62: `.claude/validators/*` → `.agent0/validators/*`
- line 64: `.claude/tests/*` → `.agent0/tests/*`
- line 72 (exclude): `.claude/tests/propagation-advisory/*` → `.agent0/tests/propagation-advisory/*`

**Modify — delegation-verify.sh default validator path (delicate spot 4):**
- lines 89-90 (functional) + line 36 (comment): `.claude/validators/run.sh` → `.agent0/validators/run.sh`

**Modify — governance-gate.sh:**
- line 52 (comment): `.claude/tests/governance-gate/` → `.agent0/tests/governance-gate/`

**Modify — rule bodies (live path refs):**
- `.claude/rules/`: `delegation.md`, `harness-sync.md`, `lint-validator.md`, `php-laravel-support.md`, `tdd.md`, `typecheck-advisory.md`, `memory-placement.md`, `propagation-advisory.md`, `runtime-capabilities.md`, `secrets-scan.md` — each carries `.claude/tests/<suite>` or `.claude/validators/run.sh` body pointers → swap to `.agent0/`

**Modify — current-mechanism memory:**
- `.agent0/memory/propagation-hygiene.md`, `.agent0/memory/propagation-advisory-maintenance.md` — shipped-surface set + test-location pointers → `.agent0/`

**Modify — moved test files (internal refs):**
- Every script under (now) `.agent0/tests/` that invokes the validator or self/sibling-references the test dir → all handled by the global sed

**Modify — README + validator self-header:**
- `README.md`, `.agent0/validators/run.sh` (line-2 self-path comment; its `.claude/rules/tdd.md` message stays — `.claude/rules` is not moving)

**Leave untouched:**
- All `docs/specs/NNN-*/` except 118 itself (frozen)
- `.claude/rules` / `.claude/hooks` / `.claude/skills` / `.claude/agents` / `.claude/worktrees` *paths* (only their body refs to tests/validators change)
- `CLAUDE_DELEGATION_VALIDATOR` env var name (non-goal)

## Alternatives considered

### Move only the validator (whose trigger is vested), defer tests

Rejected. The tests invoke the validator and live as a sibling capacity; moving `run.sh` to `.agent0/` while leaving `.claude/tests/lint-validator/*` calling it would re-create a cross-home reference (`.agent0/validators` ← `.claude/tests`) — the same split being eliminated. Bundling is one coherent relocation, one baseline bump; splitting doubles the churn on the shared manifest + rules. Same reasoning spec 105 used to bundle eight tools.

### Per-file hand-edit instead of global sed

Rejected. 213 test files with header + invocation refs makes hand-editing both error-prone and slow. The two target strings are unambiguous and prefix-isolated from the staying `.claude/*` siblings, so a scoped sed is *safer* (uniform, no missed file) than manual edits — provided the file-list filter is correctly anchored (see the ⚠️ in Approach). Delicate spots are hand-verified after the sed.

### Rename `CLAUDE_DELEGATION_VALIDATOR` → `AGENT0_DELEGATION_VALIDATOR` in this pass

Rejected (recorded as non-goal). Inconsistent to migrate one `CLAUDE_*` var while the family stays; a prefix migration is a separate, broader decision. Keeping the name has zero functional cost.

## Risks and unknowns

- **The sed file-list filter mis-anchors and corrupts frozen specs.** `grep -r` paths lack a leading `./`, so `grep -v '/docs/specs/'` fails to exclude them. Mitigation: anchor with `(^|/)docs/specs/`; recovery if it fires is `git checkout HEAD -- docs/specs/` (all frozen specs are committed). This is the realized risk this session.
- **A test fixture ASSERTS a literal `.claude/...` path** (harness-sync manifest, registration tests). The sed rewrites the assertion string too, so it asserts the new path against the new reality — consistent. Mitigation: run harness-sync + instruction-drift + propagation-advisory + delegation-verify suites explicitly.
- **Root-resolution depth.** `run-all.sh` computes root as `$(dirname "$0")/../../..`. `.claude/tests/X/` and `.agent0/tests/X/` are both 3 levels deep → identical resolution. Verified pre-flight.
- **Pre-existing unrelated failure** `typecheck-advisory/08-globs-nested-workspace.sh` (Node compile-cache pollution) will still fail post-move — NOT a regression of this spec.
- **propagation-advise `.agent0/` shipped assumption.** The manifest is per-path (explicitly lists which `.agent0/` paths ship), so adding tests/validators is consistent; the shipped-surface set is updated to match.

## Research / citations

- Exhaustive in-repo grep (2026-05-29) — full reference surface enumerated in `spec.md` + this file; 4 delicate spots located by line.
- `docs/specs/105-shared-tools-to-agent0/{spec,plan}.md` — the relocation playbook this mirrors.
- `.claude/rules/harness-sync.md` § Path relocations + § Self-rebootstrap — manifest + consumer-migration posture (self-rebootstrap hazard does NOT apply: sync-harness.sh isn't moving).
- `.agent0/memory/harness-home.md` — the classification principle + the `deferred`→resolved disposition.
