# 090 — multi-runtime-entrypoints — plan

_Drafted from `spec.md` on 2026-05-26. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Six coordinated edits ship the asymmetric multi-runtime instruction contract that the debate (3 rounds, Claude Code initiating + Codex CLI reviewing) converged on. The shape: `CLAUDE.md` keeps its existing structured marker-aware merge (the `058`/`071` design); `AGENTS.md` is a new repo-root file registered as plain baseline-tracked in `sync-harness.sh`, gaining drift detection for free without any new merge primitive. Codex's native instruction-chain (`AGENTS.override.md` + nested `AGENTS.md`, root-to-cwd composition, 32 KiB `project_doc_max_bytes` cap per the OpenAI doc) handles fork-side customization — Agent0 does not duplicate that mechanism.

Order — six edits, all in one commit because they're contract-coupled:

1. **Extend CLAUDE.md's managed block** with a new "Runtime entrypoints" section explaining the asymmetric structure. This section is inside `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->`, so it propagates byte-identically to AGENTS.md.
2. **Create `AGENTS.md`** at repo root: top-section 3-tier capability classification preamble (Codex-safety contract, runtime-specific, OUTSIDE markers); middle byte-identical managed block (matches CLAUDE.md's region between markers); bottom-section pointer to `AGENTS.override.md` / nested `AGENTS.md` as the sanctioned customization surface (OUTSIDE markers).
3. **Register AGENTS.md in `sync-harness.sh`** by appending it to the `COPY_CHECK_FILES` array. The existing 3-way baseline machinery (stale auto-update / customized refusal / upstream-deletion propagation) handles it natively — no new logic.
4. **Update `.claude/rules/harness-sync.md`** § Manifest scope to list AGENTS.md, plus a § Gotchas bullet noting the asymmetric posture is intentional ("AGENTS.md is plain baseline-tracked; do not add structured merge for it without a follow-up spec — see 090").
5. **Author `.claude/tools/check-instruction-drift.sh`** — the 5-check static drift script. Checks (i)+(ii)+(iii)+(iv) are direct logic; check (v) shells out to `sync-harness.sh --check`. Reuses marker-detection logic by extracting the helpers to a sourced lib at `.claude/tools/lib/managed-block.sh` so both sync-harness and the new script share one source of truth (small extraction; minimal LOC).
6. **Update `README.md` quick start** to advertise "Open this repo with Claude Code or Codex."

Tests under `.claude/tests/instruction-drift/` mirror the five acceptance checks (one shell script per check, each `set -e` + assertion shape consistent with existing `.claude/tests/harness-sync/`).

## Files to touch

**Create:**
- `AGENTS.md` — Codex runtime entrypoint. Three regions: 3-tier preamble (outside markers, runtime-specific), byte-identical managed block (inside markers, matches `CLAUDE.md`'s region), customization-surface pointer (outside markers, points at `AGENTS.override.md` + nested `AGENTS.md`).
- `.claude/tools/check-instruction-drift.sh` — 5-check static drift script. Exit 0 = clean, 1 = drift. Reads `CLAUDE.md` + `AGENTS.md`, asserts existence + marker validity + managed-block byte equality + no Claude-only-claims-without-tier-caveat; shells out to `sync-harness.sh --check` for the baseline-drift signal.
- `.claude/tools/lib/managed-block.sh` — extracted helpers (`detect_marker_state`, `_extract_region`, `_region_sha`) sourced by both `sync-harness.sh` and `check-instruction-drift.sh`. Single source of truth for marker-region semantics.
- `.claude/tests/instruction-drift/01-both-entrypoints-exist.sh` — check (i).
- `.claude/tests/instruction-drift/02-markers-paired-and-ordered.sh` — check (ii).
- `.claude/tests/instruction-drift/03-managed-blocks-byte-equal.sh` — check (iii).
- `.claude/tests/instruction-drift/04-no-claude-only-claims-without-tier-caveat.sh` — check (iv).
- `.claude/tests/instruction-drift/05-sync-harness-detects-agents-md-drift.sh` — check (v).

**Modify:**
- `CLAUDE.md` — inside the existing `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->` markers, add `## Runtime entrypoints` section documenting the asymmetric structure (CLAUDE.md = structured merge / AGENTS.md = baseline-tracked + Codex's native override chain).
- `.claude/tools/sync-harness.sh` — append `AGENTS.md` to `COPY_CHECK_FILES`; replace inline `detect_marker_state` / `_extract_region` / `_region_sha` definitions with `source "$AGENT0_ROOT/.claude/tools/lib/managed-block.sh"` (or fork-relative-path resolution, mirroring the pattern of how the script already locates other resources).
- `.claude/rules/harness-sync.md` — § Manifest scope: list `AGENTS.md` under `COPY_CHECK_FILES`. § Gotchas: append bullet on the asymmetric posture. § CLAUDE.md managed-block merge strategy: append a sentence noting "this primitive does NOT apply to AGENTS.md by design — AGENTS.md is plain baseline-tracked; see spec 090".
- `README.md` — quick start gains one line mentioning both runtimes.

**Delete:** none.

## Alternatives considered

### Structured marker-aware merge for AGENTS.md (mirror CLAUDE.md)

Rejected per debate Rounds 2-3. Codex provides a native fork-customization primitive: at each scope level, `AGENTS.override.md` takes precedence over `AGENTS.md`, and nested `AGENTS.md` files in subdirectories layer on top of root files (root-to-cwd composition, blank-line joined, 32 KiB cap per `project_doc_max_bytes`). Mirroring CLAUDE.md's structured merge would duplicate ~150 LOC of dispatcher + extraction + 3-way reconciliation to solve a problem Codex already solves natively. CLAUDE.md needs the marker-aware merge precisely because Claude Code has no equivalent override chain — there's exactly one CLAUDE.md per project. Forcing symmetry between the two runtimes is the wrong shape; honest asymmetry matches each runtime's actual loader semantics. Promote to follow-up spec only on the rule-of-three demand test (≥3 forks customizing root AGENTS.md).

### Generator from provider-neutral source (e.g. `.agent0/instructions/managed-block.md`)

Rejected for v1. The shared block is 6.4 KiB / 94 lines of plain markdown index — duplication is cheap; the comparison test is a single shell line. A generator path is justified only when the block needs templating across runtimes (per-runtime variable substitution, runtime-specific section reordering). Today nothing in the block is runtime-conditional. Documented as a future-upgrade route in spec.md § Non-goals if the block ever grows templating needs.

### Single CLAUDE.md serves both runtimes (Codex configured to point at it)

Rejected. Codex's native discovery looks for `AGENTS.md` (and `AGENTS.override.md`) at known names. There is no documented alias mechanism that would let Codex treat `CLAUDE.md` as its instruction file. Going this route would require either a `~/.codex/config.toml` user setting (per-developer friction, breaks "drop the repo in any runtime and it works") or a symlink hack (filesystem-fragile, breaks Windows). The honest shape is two files at the contract level, with the shared substance comparing byte-equal under the markers.

### Place AGENTS.md at `.codex/AGENTS.md` or `.agent0/AGENTS.md` (away from repo root)

Rejected. Per the OpenAI doc, Codex's chain searches root-to-cwd, finding `AGENTS.md` (or `AGENTS.override.md`) at each level. A file inside `.codex/` would only load when cwd is inside that subdir — broken default discovery. Repo root is the only Codex-native location.

### Extend `sync-harness.sh` with a `--check-drift` subcommand instead of a standalone script

Rejected. Four of the five checks (existence, marker pair validity, region byte equality, sync-harness baseline drift) duplicate logic already in sync-harness, but the fifth (Claude-only-claims grep with tier-caveat allowlist) is orthogonal. Folding the orthogonal check into a 1400-LOC tool already at its complexity limit is the wrong cost/benefit. A small standalone (~80 LOC) at `.claude/tools/check-instruction-drift.sh` with five test fixtures keeps separation of concerns. The shared marker-region logic is extracted to a sourced lib so neither tool drifts from the other.

### Source `sync-harness.sh` directly from `check-instruction-drift.sh` instead of extracting helpers

Rejected. `sync-harness.sh` has executable side-effects when sourced (argument parsing at top level, environment variable setup, manifest array population). Sourcing it from a smaller tool would either trigger those side-effects or require defensive guards in both files. Extracting the ~30 LOC of marker-region helpers to `.claude/tools/lib/managed-block.sh` is the textbook "common code, two callers" refactor — incremental and well-contained.

## Risks and unknowns

- **Codex's 32 KiB project_doc_max_bytes is global across the chain.** A user with a 10 KiB global `AGENTS.md` plus our 7-8 KiB root file (~6.4 KiB managed block + ~1 KiB runtime preamble + customization-surface pointer) consumes ~17-18 KiB — well under cap, but downstream subdirectory `AGENTS.md` files in user projects could push past. Mitigation: the byte-envelope acceptance criterion + `wc -c` script in the drift checks keep the managed block from creeping unnoticed. The propagation-hygiene "index-shaped, not expanded rule copies" discipline already enforces the right shape.
- **First-sync `!! customized (no baseline)` friction for forks that pre-authored AGENTS.md.** Most consumers of Agent0's harness don't ship their own `AGENTS.md`. Any fork that DID create one before v1 ships will need a one-time `--apply --force --force-except='AGENTS.md'` (adopt Agent0's elsewhere, keep fork's AGENTS.md) or `--force` (adopt Agent0's wholesale). Mitigation: the PR body for this spec mentions the migration path in the body; downstream maintainers see it in the diff.
- **Asymmetry-fix temptation in maintenance.** Future maintainers seeing CLAUDE.md has structured merge but AGENTS.md doesn't may "correct" the asymmetry by adding marker-aware merge for AGENTS.md, undoing the v1 contract. Mitigation: documented in three places — both files' Runtime entrypoints section, the spec.md Acceptance criteria, and a harness-sync.md § Gotchas bullet. The audit trail prevents the regression by surfacing intent.
- **Helper-extraction refactor introduces a tiny regression window.** Moving `detect_marker_state` / `_extract_region` / `_region_sha` out of `sync-harness.sh` into a sourced lib changes the script's startup shape. Existing `.claude/tests/harness-sync/*.sh` tests pass through these helpers indirectly via the dispatcher. Mitigation: run the full `harness-sync/` test suite before the commit; the extraction is mechanical (no logic change), so test diffs should be zero.
- **Drift-script's "no Claude-only claims without tier caveat" check is heuristic.** A grep-based check for `/sdd`, `PreToolUse`, etc. without nearby tier-classification language can false-positive (legitimate mention IS qualified but the qualifier is N lines away) or false-negative (Claude-only claim phrased in unexpected wording). Mitigation: ship with a conservative allowlist + test fixtures covering common phrasings; iterate when real false positives surface. The check is a safety net, not a correctness oracle.
- **Codex doc accuracy.** The 32 KiB cap, root-to-cwd composition, `AGENTS.override.md` precedence are documented behaviors today; Codex is pre-1.0. Mitigation: the drift checks key on Agent0-internal contracts (marker validity, byte equality, claim discipline), not on Codex's exact loader behavior. If Codex's loader evolves, the drift checks still hold their meaning. The `r-2026-05-25-...` reminders pattern (already canonical for keeping external docs in sync) absorbs the cadence.

## Research / citations

- **OpenAI Codex AGENTS.md guide** — WebFetched 2026-05-26 (https://developers.openai.com/codex/guides/agents-md). Confirmed: root-to-cwd chain composition with blank-line joining; `AGENTS.override.md` precedence at each scope level (global + project); `project_doc_max_bytes = 32 KiB` default, configurable via `~/.codex/config.toml`; missing-file behavior is graceful skip, not error.
- **`docs/specs/090-multi-runtime-entrypoints/debate.md`** — 3-round cross-model debate (Claude Code initiating, Codex CLI reviewing) that converged on the asymmetric architecture documented here. Key resolutions: byte-identical for v1; sync-harness propagates AGENTS.md in this same spec; 3-tier capability classification preamble; 5 concrete drift checks; asymmetric file structure between CLAUDE.md and AGENTS.md.
- **`CLAUDE.md`** — current managed block measures 6.4 KiB / 94 lines (verified via `wc -c` + region-extraction script on 2026-05-26). Used as the empirical envelope for the byte-size acceptance criterion.
- **`.claude/tools/sync-harness.sh`** — manifest arrays (`COPY_CHECK_FILES`), 3-way reconciliation logic, marker-region helpers (`detect_marker_state` lines 767+, `_extract_region` lines 805-812, `_region_sha` lines 816-818) that this plan extracts to a shared lib.
- **`.claude/rules/harness-sync.md`** — § Customization detection (3-way table), § CLAUDE.md managed-block merge strategy (the design lineage we deliberately do NOT replicate for AGENTS.md), § Manifest scope.
- **`docs/specs/058-claude-md-managed-block/`** — original managed-block markers design.
- **`docs/specs/071-claude-md-capacity-index/`** — index-shape discipline that bounds the shared block's growth (canonical example for the "index-shaped, not expanded rule copies" criterion in this spec).
