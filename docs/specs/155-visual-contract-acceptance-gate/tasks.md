# 155 — visual-contract-acceptance-gate — tasks

_Generated from `plan.md` on 2026-06-05. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

Each implementation task lands with its test in the same slice (TDD: red → green).

- [ ] 1. **Detection tool (D2).** Create `.agent0/tools/ui-impact-detect.sh`: read changed paths (stdin newline-list OR `--range <git-range>`), classify each as rendered-surface vs not per the D2 glob/exclusion set, output suggested `UI impact` level + a `mismatch` flag (surfaces changed but declared/effective level is `none`). Flags: `--declared <level>`, `--json`. Pure path matching, no content reads. Executable bit set. `UI impact: none` (this is a CLI/shell tool).
- [ ] 2. **Detection test.** Create `.agent0/tests/visual-contract/{run-all.sh,_lib.sh,01-detect.sh}` (runner globs `[0-9][0-9]-*.sh`). `01-detect.sh` asserts: `.tsx`/`.css`/`components/` → flagged; `docs/`,`*.md`,`.agent0/`,`migrations/`,`*.go` → not flagged; mismatch flag set when surface changed + `--declared none`; clear when `--declared render`.
- [ ] 3. **Validator advisory.** Modify `.agent0/validators/run.sh`: after the lint/typecheck advisory block, run `ui-impact-detect.sh` over the session diff; if mismatch, emit `visual-contract-advisory: <msg naming the surfaces + suggesting a UI impact declaration>` on **stderr only** (non-blocking; never changes exit code). Add `02-advisory.sh` asserting the advisory fires on a UI surface change with no declaration and is silent for `none`/non-UI changes.
- [ ] 4. **Contract-depth extension (D3).** Extend `verify_contract()` in `.agent0/tools/agent-browser.sh` to read optional top-level `interactions` and `flow` arrays and execute each step in order via the `run --` act-verb passthrough, appending a `check` per step to `report.json`; a `"flaky": true` step that fails records a `warn` check (does not flip `overall`). Render-only fixtures behave exactly as before (backward compatible). Tiers cumulative (`interaction` = render+interactions; `flow` = +flow).
- [ ] 5. **Contract-tier test.** Add `.agent0/tests/visual-contract/03-contract-tiers.sh` + `fixtures/{render-only,with-interactions,with-flow,malformed}.json`. Using the `AGENT0_BROWSER_BIN` fake-bin stub (offline, deterministic): assert correct act-verb sequence per tier, post-step assertions land in `report.json`, `flaky` step downgrades to `warn`, malformed fixture → usage error (exit 3), unavailable binary → exit 4 / `unavailable` (never pass). A `need_live`-guarded live check skips-with-pass when no browser.
- [ ] 6. **Delegation wiring (D4).** Modify `.agent0/hooks/delegation-verify.sh`: when the closing brief declared UI work, look for the named evidence bundle's `report.json` and surface a `visual-contract-advisory:` if absent or not `.overall=="pass"` (non-blocking). Document the UI-producing-brief field mapping in `.agent0/context/rules/delegation.md` (CONSTRAINTS/DELIVERABLE/DONE_WHEN, no 6th field). Add `04-delegation.sh` asserting both behaviors.
- [ ] 7. **Canonical rule doc.** Create `.agent0/context/rules/visual-contract.md`: the `UI impact` declaration + default, the 3 cumulative tiers, the extended contract schema (with a worked example per tier), SDD + delegation plug-in points, advisory-not-blocking posture, the `flow`-first future-hardening note (Codex minority report), reconcile-with-`/product`, fail-closed (`unavailable`≠pass).
- [ ] 8. **SDD + index wiring.** Add the optional `**UI impact:**` line to `.agent0/skills/sdd/templates/spec.md.tmpl`; note it in `.agent0/context/rules/spec-driven.md`; cross-reference the extended tiers in `.agent0/context/rules/browser-primitive.md`. Add the managed-block "Visual contract acceptance" index section to `CLAUDE.md` and `AGENTS.md` (mirror the sibling sections; don't break the AGENTS.md baseline). One-line reconcile note in `.claude/skills/product/` (design-time contract → SDD impl-evidence).
- [ ] 9. **Self-declare this spec's own UI impact.** Set `**UI impact:** none` in this `spec.md` (the capability ships as harness mechanism; Agent0 has no UI) — proves the declaration convention round-trips and the validator stays silent on this very spec's diff.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [ ] V1 (Scenario: declared UI + heuristic agrees) — `02-advisory.sh` green: declared `render`/`interaction`/`flow` + surface change ⇒ advisory expects evidence; absent ⇒ `visual-contract-advisory` on stderr, exit unchanged.
- [ ] V2 (Scenario: backend/CLI/docs not gated) — `01-detect.sh`/`02-advisory.sh` green: `none`-class change ⇒ no advisory, no requirement.
- [ ] V3 (Scenario: likely-omitted declaration flagged) — `01-detect.sh` green: surface change + `--declared none` ⇒ mismatch flag; tool only suggests, never sets.
- [ ] V4 (Scenario: delegated UI task proves it drove the UI) — `04-delegation.sh` green: declared-UI brief without a passing `report.json` ⇒ advisory; with one ⇒ clean. No 6th field added (`delegation-gate.sh` unchanged).
- [ ] V5 (Scenario: browser unavailable ≠ pass) — `03-contract-tiers.sh` green: unavailable binary ⇒ exit 4 / `unavailable`, never a green pass.
- [ ] V6 (static facts) — rule doc asserts semantic (not pixel) conditions; 3 cumulative tiers defined with examples; `/product` reconcile note present; capability lives entirely under `.agent0/`+`.claude/`+`CLAUDE.md`/`AGENTS.md` (no project-memory dependency).
- [ ] V7 (gate) — `bash .agent0/tests/visual-contract/run-all.sh` exits 0 (all `NN-*.sh` green) AND `.agent0/validators/run.sh` is green on the final tree AND `shellcheck` clean on new/changed shell.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
