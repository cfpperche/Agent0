# 059 — In-flight notes

## Design decisions

### 2026-05-19 — parent — Allowlist inlined, not externalized

The 7-path Agent0 harness allowlist is inlined verbatim in `SKILL.md` § Phase 0 step 1 rather than referenced from a separate config file. Trade: maintenance debt (allowlist must stay in sync with `sync-harness.sh` manifest). Why: a separate config file would mean Phase 0 has to load/parse another resource at run time. The skill is model-orchestrated — adding I/O surface there is friction. Spec 016's sync-harness already enumerates the manifest in its own source; the spec 059 allowlist mirrors that, and the audit task (task 1) catches drift before each /product release.

### 2026-05-19 — parent — `.gitignore` append-marker is verbose

Marker chosen: `# --- /product (Next.js) ---`. Alternative considered: `# /product` (terse). Verbose wins because it survives `grep` searches and signals intent to a fork developer scanning the file cold. The same marker shape exists already in other parts of Agent0 (e.g. `compaction-continuity.md` references `# CC` markers in CLAUDE.md). Consistency.

### 2026-05-19 — parent — Surgical `rm -r` deferred

Spec 048's existing semantics for "dir has /product artifacts" remain: prompt overwrite → full `rm -r <out>` on `y`. Surgical rm (preserve harness during rm) was considered but rejected for v1. The re-run scenario (re-running /product on a dir with both harness AND prior /product output) is recoverable via `sync-harness.sh` post-rm, just annoying. If it becomes common (≥3 dogfoods), follow-up spec with surgical rm + tested rm-path-list.

### 2026-05-19 — parent — Synthetic smoke test outcomes (task 4)

Manual verification per `plan.md` § *Acceptance verification* executed as synthetic smoke test in `/tmp/test-{empty,harness,artifacts}/` instead of waiting for empirical `/product` invocation. Cenário-a-cenário:

- **Scenario 1 (empty `<out>`)** — PASS. `/tmp/test-empty` created via `mkdir -p`; `<remaining>` = ∅; matches SKILL.md § Phase 0 step 1 "If `<remaining>` is empty: proceed to step 2 (Init) — no prompt, no rm, harness preserved".
- **Scenario 2 (harness-only `<out>`)** — PASS. `sync-harness.sh --apply /tmp/test-harness` produced exactly 7 top-level entries: `.claude/`, `.git/`, `.githooks/`, `.gitignore`, `.gitleaks.toml`, `.mcp.json.example`, `CLAUDE.md`. All 7 in the inline allowlist; `<remaining>` = ∅ after filter; SKILL.md prose path = proceed-to-init. **Allowlist confirmed without drift vs sync-harness manifest output as of 2026-05-19.**
- **Scenario 3 (`/product` artifacts present)** — PASS. Copied test-harness to test-artifacts and added `docs/` (with `.state.json`, `concept-brief.md`, `screens/`); top-level = 7 harness + 1 `docs/`; `<remaining>` = `{docs/}` ≠ ∅; with no `--from-step` triggers the overwrite prompt path. Existing spec 048 semantics preserved.
- **Scenario 4 (`--from-step` resume with harness present)** — VERIFIED BY INSPECTION (not exercised). The harness allowlist is filtered out in step 1 BEFORE the `--from-step` validation in the else-branch evaluates `<remaining>`. By construction, the validation logic only sees non-harness paths (i.e. real `/product` artifacts). End-to-end empirical proof gated on real `/product` orchestration with valid `.state.json` v4 + matching slug/idea/stack — pending mei-saas founder run.
- **Scenario 5 (`.gitignore` append-with-marker)** — PASS. Simulated the three sub-cases against `/tmp/test-harness/.gitignore` (64-line harness-shipped file):
  - **5a — fresh append (no marker)**: marker `# --- /product (Next.js) ---` + rules added at EOF; harness rules 1-64 preserved verbatim; 1-line blank separator inserted (intentional readability spacing).
  - **5b — re-run with marker present**: region below marker REPLACED with fresh rules; harness section 1-64 unchanged (verified by `diff` vs pre-run snapshot — only diff is the deliberate blank separator at line 65).
  - **5c — marker absent (founder edited it out)**: collapses to fresh-append path; marker recreated.

Verification mechanism: an `awk`-based mirror of the SKILL.md prose (`/tmp/simulate-gitignore-append.sh`) was run against fixtures; the SKILL.md prose is unambiguous enough that a faithful translation behaved as specified. Fixtures cleaned up post-verification.

**Residual gap (intentional):** Scenario 4 lacks end-to-end empirical evidence. Spec scope closure-decision: accept inspection-level verification for scenario 4 since the logic is mechanical (filter-then-evaluate) and the empirical run will happen organically when the mei-saas founder invokes `/product` in their next session. If scenario 4 fails in real use, follow-up patch is local to SKILL.md § Phase 0 step 1 else-branch.

## Deviations

(None — implementation matches plan.md exactly.)

## Tradeoffs

- **Tiny scope vs comprehensive.** Could have shipped surgical rm + harness-aware writes for CLAUDE.md + harness-aware writes for `.gitignore` + harness-aware writes for any future conflict. Picked tiny — only fix the immediate blocker (Phase 0 prompt) + minimal `.gitignore` collateral. Reduces shipping risk; surgical rm can land later when empirically needed.
- **Allowlist drift risk.** Hardcoding the 7 paths in SKILL.md means a sync-harness manifest expansion creates drift. Trade: cheap to audit (one file each side), zero runtime config-loading.
- **No automated test.** /product has no test harness today. Manual verification is the contract. Acceptable for v1; if /product gains a test framework someday, add scenarios 1-5 there.

## Open questions

1. **What if founder has manually-edited files at `<out>/` root that are NOT harness AND NOT /product output?** Current spec triggers the overwrite prompt for them (treats as /product artifacts). Founder can abort. Surgical rm would be more lenient but is out of scope. Watch for complaints in real use.
2. **Marker idempotency edge case.** If a founder edits the auto-generated `.gitignore` section (under the marker) and then re-runs /product, the replace-region-under-marker logic loses their edits. Acceptable? Probably — /product's `.gitignore` rules are deterministic from `--stack`. If founder wants custom rules, they go ABOVE the marker.
