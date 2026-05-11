# 009 — supply-chain-block — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. **Preserve regression-guard semantics on existing advisory-mode tests.** Prepend `export CLAUDE_SUPPLY_CHAIN_BLOCK=0` (after `set -euo pipefail` and the `AGENT0_ROOT` / `HOOK` / `TMPDIR` setup, before `run_case`/test invocations) to:
  - `.claude/tests/supply-chain/01-bash-install-advisory.sh` (asserts `decision: "advisory"`)
  - `.claude/tests/supply-chain/02-skip-not-install.sh` (mode-agnostic but `skip-not-install` is preserved by both modes; the explicit export documents intent and matches the suite's convention)
  - `.claude/tests/supply-chain/05-override-marker.sh` (asserts `advisory-override`)
  - `.claude/tests/supply-chain/07-tokenizer-shape.sh` (asserts `advisory`)
  - Tests 03, 04, 06 don't depend on Bash-mode (Edit-side or env-disable paths) and are skipped.
  - Run `bash .claude/tests/supply-chain/run-all.sh` after; expect all 7 still PASS (no behavior change yet — the hook still treats unset as advisory).

- [ ] 2. **Write `.claude/tests/supply-chain/08-block-default.sh`** — asserts block-mode-no-override behaviour. Setup: empty env (no `CLAUDE_SUPPLY_CHAIN_BLOCK` set; under the new default this means block mode). Input: `tool_input.command = "npm install axios"`. Assertions:
  - Hook exits 2 (not 0).
  - Stderr contains the verbatim string `supply-chain-block: npm install detected — packages: axios`.
  - Stderr ends with the two-line corrected form: original command on one line, `# OVERRIDE: <reason ≥10 chars — why this dep is being added>` on the next.
  - Audit log has one row with `decision: "block"`, `manager: "npm"`, `action: "install"`, `packages: ["axios"]`, `override_reason: null`.

- [ ] 3. **Write `.claude/tests/supply-chain/09-block-override-valid.sh`** — block-mode + valid override. Setup: empty env. Input: `tool_input.command = "npm install axios\n# OVERRIDE: documented chart-library upgrade per spec-009 verification"`. Assertions:
  - Hook exits 0.
  - Stderr is empty (no advisory line, no block template).
  - Audit row: `decision: "block-override"`, packages captured, `override_reason: "documented chart-library upgrade per spec-009 verification"`.

- [ ] 4. **Write `.claude/tests/supply-chain/10-block-override-too-short.sh`** — block-mode + too-short override. Setup: empty env. Input: `tool_input.command = "npm install axios\n# OVERRIDE: skip"` (reason `skip` is 4 chars, below the 10-char floor). Assertions:
  - Hook exits 2.
  - Stderr contains `supply-chain-block: override reason must be ≥10 characters, got "skip"`.
  - Stderr ends with the two-line corrected form (same shape as test 08).
  - Audit row: `decision: "block"`, `override_reason: "skip"` (populated — forensic preservation of the rejected string).

- [ ] 5. **Write `.claude/tests/supply-chain/11-advisory-opt-out.sh`** — `CLAUDE_SUPPLY_CHAIN_BLOCK=0` falls back to spec-008 advisory mode. Two sub-cases via `run_case` helper:
  - (a) `CLAUDE_SUPPLY_CHAIN_BLOCK=0` + `npm install axios` → exits 0, stderr contains `supply-chain-advisory: npm install — axios`, audit `decision: "advisory"`.
  - (b) `CLAUDE_SUPPLY_CHAIN_BLOCK=0` + `npm install axios\n# OVERRIDE: documented advisory-mode opt-out for spec 009 test` → exits 0, no stderr, audit `decision: "advisory-override"`, `override_reason` populated.
  - This is the regression guard that the entire spec-008 contract still works when explicitly opted into.

- [ ] 6. **Extend `.claude/tests/supply-chain/run-all.sh`** — change the iteration list from `01 02 03 04 05 06 07` to `01 02 03 04 05 06 07 08 09 10 11`. Mirror the previous extension pattern (single-character substitution in the `for n in` loop).

- [ ] 7. **Run the test suite RED** — `bash .claude/tests/supply-chain/run-all.sh`. Expected: tests 01-07 PASS (regression-preserved by task 1), tests 08-11 FAIL (hook hasn't been patched yet). The exact failure shape on 08-10 will be that the hook returns exit 0 instead of 2 (current advisory behaviour). On 11 the hook will already pass because `CLAUDE_SUPPLY_CHAIN_BLOCK=0` doesn't change anything in the current hook. **This is the TDD red phase — confirms the new tests actually catch the new requirements.**

- [ ] 8. **Patch `.claude/hooks/supply-chain-scan.sh` with mode resolution and block branches.** Edits:
  - **Add mode resolver near top** (after the `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` check, before stdin capture): resolve `CLAUDE_SUPPLY_CHAIN_BLOCK` per plan.md § *Approach* (default OR `=1` OR any non-`0` value → block mode; `=0` → advisory mode). Set a `MODE` variable to `"block"` or `"advisory"`.
  - **Update override-marker phase** to NOT silently drop too-short reasons in block mode. Track `override_too_short` separately from `override_valid`: marker present but reason <10 chars → `override_valid=0` AND `override_too_short=1` AND `override_reason` populated with the rejected string. Advisory mode behaviour stays the original silent-drop.
  - **Replace Phase 5 decision section** with mode-aware branches:
    - `skip-not-install` (unchanged for both modes)
    - block mode + valid override → audit `decision: "block-override"`, silent, exit 0
    - block mode + no marker → emit no-override block template, audit `decision: "block"` with `override_reason: null`, exit 2
    - block mode + too-short marker → emit short-reason block template, audit `decision: "block"` with `override_reason` populated, exit 2
    - advisory mode + valid override → audit `decision: "advisory-override"` (unchanged from 008), exit 0
    - advisory mode + no/too-short marker → emit advisory stderr line, audit `decision: "advisory"` (unchanged from 008), exit 0
  - **Add two stderr template heredocs**: the no-override template and the too-short template (verbatim text per plan.md § *Approach*). The closing two lines of both are the corrected form: original command line + `# OVERRIDE: <reason ≥10 chars — why this dep is being added>` literal.
  - Update the file's docstring header to describe the new mode resolver and the two new decision values.

- [ ] 9. **Run the test suite GREEN** — `bash .claude/tests/supply-chain/run-all.sh`. Expected: all 11 PASS. If 08-11 still fail, fix the hook (likely template-string mismatch or audit-field shape) and re-run. If 01-07 fail, the regression-guard export in task 1 is missing somewhere; fix it. Update plan.md if a fix reveals the plan was wrong.

- [ ] 10. **Update `.claude/rules/supply-chain.md`** with the new mode discipline. Edits:
  - § *What fires, what advises* — first sentence after "**Bash preflight**" paragraph now describes block-by-default semantics; preserve the existing "**This is an advisory-only capacity**" text but reframe as "Bash preflight blocks by default; advisory mode is opt-in via env var" near the top of the section.
  - **New § *Block vs advisory mode* section** between § *Manager detection table* and § *Manifest+lockfile basename allowlist*: mode-resolver table (env-var values → mode), decision-value matrix (mode × override-state → decision), notes on the override-too-short forensic preservation.
  - § *Override grammar* — note that the ≥10-char rule is now hard-enforced in block mode (rejects with corrective template); soft-degrade behaviour ONLY applies when explicitly in advisory mode.
  - § *Audit log* — add `block` and `block-override` rows to the decision table; note that `override_reason` may be populated on `block` rows (too-short case) and how forensic queries discriminate (`(.override_reason | length // 0)`).
  - § *Escape hatch* — add `CLAUDE_SUPPLY_CHAIN_BLOCK=0` as the per-session advisory opt-out, alongside the existing `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1`. Distinguish the two: opt-out vs full disable.
  - § *Gotchas* — add: (a) first-fork friction note, (b) the override-too-short audit-row discriminator, (c) cross-reference to the issue-#24327 stderr-contract precedent in secrets-scan.

- [ ] 11. **Update CLAUDE.md `## Supply chain` section** — change the lead sentence from "Two-layer advisory capacity (spec 008)" to "Two-layer capacity (specs 008+009): Bash preflight blocks dep-mutating commands by default; Edit/Write advises on manifest edits". Append one sentence after the existing override-marker mention: "`CLAUDE_SUPPLY_CHAIN_BLOCK=0` falls back to spec-008 advisory-only mode." ≤2 sentences of marginal text per spec.

- [ ] 12. **Update README.md per-fork checklist** — find the existing checklist (the one that already documents `core.hooksPath` and other per-fork install steps), add one bullet near the supply-chain block: "For advisory-only supply-chain mode (the spec-008 behaviour), `export CLAUDE_SUPPLY_CHAIN_BLOCK=0` in the session env or shell rc. Default is block; `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` fully disables both layers for throwaway sessions."

- [ ] 13. **Final regression run + audit-log sanity check** — `bash .claude/tests/supply-chain/run-all.sh` → 11/11 PASS. Then inspect the test-run audit log shapes by hand: confirm one block row has `decision: "block"`, `override_reason: null`; one has `decision: "block"`, `override_reason: "skip"`; one has `decision: "block-override"`, `override_reason` populated; advisory-opt-out rows look exactly like the spec-008 audit rows. `jq -c '{decision, override_reason}'` per case.

## Verification

_Each line maps 1:1 to a `spec.md` acceptance criterion._

- [ ] Scenario "Bash dep-install in default block mode without override" — covered by `08-block-default.sh` (T2).
- [ ] Scenario "Bash dep-install in default block mode WITH valid override marker" — covered by `09-block-override-valid.sh` (T3).
- [ ] Scenario "Bash dep-install in advisory opt-out mode" — covered by `11-advisory-opt-out.sh` (T5).
- [ ] Scenario "Short override reason in block mode still blocks" — covered by `10-block-override-too-short.sh` (T4).
- [ ] Scenario "Edit/Write on manifest stays advisory under block mode" — covered by existing `03-edit-manifest-advisory.sh` (no changes needed; Edit hook untouched by this spec, runs under any Bash mode).
- [ ] Scenario "`CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` still silences both layers" — covered by existing `06-env-var-disable.sh` (mode resolver runs AFTER the skip check; preserved by patch in T8).
- [ ] Scenario "`skip-not-install` audit shape unchanged" — covered by existing `02-skip-not-install.sh` under advisory mode (T1 export) AND by the absence of regression in 08-11 (the new block-mode tests use real dep-install shapes, not skip shapes).
- [ ] Scenario "Stderr template ends with verbatim corrected form" — asserted explicitly in T2 (08-block-default) and T4 (10-block-override-too-short) via stderr-tail regex.
- [ ] `.claude/hooks/supply-chain-scan.sh` patched with mode resolver + block branches (T8).
- [ ] `.claude/rules/supply-chain.md` updated with `block` / `block-override` decision rows, mode section, gotchas (T10).
- [ ] 4 new tests added (08-11), `run-all.sh` extended, suite green at 11/11 (T2-T5, T6, T9, T13).
- [ ] CLAUDE.md § *Supply chain* updated to ≤2 sentences of marginal text (T11).
- [ ] README per-fork checklist gains the opt-out bullet (T12).

## Notes

- Implementation is parent-driven, same as 008 — single hook file modified, four new test scripts, three doc files touched. No `Agent` delegation needed (no model-discipline signals fire: small scope, single integration, no schema/security signals beyond what 008 already declared).
- TDD discipline is explicit in the task order: T1 preserves existing-test semantics under the new default, T2-T5 write new RED tests, T7 confirms RED, T8 makes them GREEN, T9 confirms. No production-then-test path.
- Hook patch (T8) is a single-file edit; the four template heredocs and the mode resolver fit comfortably in <60 LOC added. Audit primitive (`flock`-atomic append) reused verbatim from existing 008 code — no new abstraction needed.
- The "first-fork friction" risk from plan.md § *Risks* is mitigated by documentation density (CLAUDE.md + README + stderr template all name the env-var opt-out). Real-world signal will come from the next dogfood pass against a fresh fork; defer until that happens.
- Consider follow-up live-dogfood pass against pyshrnk or shrnk AFTER this spec lands — first-fork friction is best surfaced live, not in unit tests. Out of scope for this spec.
