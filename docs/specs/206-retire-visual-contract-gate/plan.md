# 206 — retire-visual-contract-gate — plan

_Drafted from `spec.md` on 2026-06-14._

## Decisions (resolving the spec's open questions)

These were the spec's open questions; locked here so implementation is mechanical.

1. **`verify-contract` disposition → REMOVE.** The `verify_contract()` function and the
   `verify-contract` subcommand are deleted from `agent-browser.sh`. Rationale: removal kills
   the "acceptance-shaped `report.json .overall==pass`" footgun outright and shrinks the
   maintenance surface the most. Ad-hoc UI driving stays available via `run`; the
   a11y/console/vitals/overflow sweep stays available via `audit`. (Chosen over rename-to-
   `smoke-contract`, which keeps the footgun one rename away.)
2. **Runner detection contract.** A project "has a UI test runner" when a deterministic,
   content-free signal is present — implemented in a new `ui-runner-detect.sh`:
   - a `test:e2e`, `e2e`, `test:ui`, or `e2e:*` script key in any `package.json` (root or
     workspace), OR
   - a known e2e config file outside `node_modules`: `playwright.config.{ts,js,mjs,cjs}`,
     `cypress.config.{ts,js,mjs,cjs}`, `wdio.conf.{ts,js}`, `nightwatch.conf.{js,ts}`, OR
   - a **stack-neutral declarable override**: a `.agent0/ui-test.json` manifest naming the
     command (escape hatch for Python/Playwright-python, Rust, etc.), mirroring how
     `typecheck-advisory` only fires when the primitive is declarable.
   **CI is not required** by the harness; a local green run with recorded evidence suffices
   (the gate is advisory/non-blocking, so mandating CI would over-reach).
3. **a11y/console/vitals/overflow disposition → opt-in `agent-browser audit`.** They are not
   required acceptance conditions; `ui-acceptance.md` documents `agent-browser audit` as the
   surviving home for an opt-in sweep. (Chosen over requiring them in every e2e — that would
   re-import the over-prescription we are removing.)
4. **Native/mobile no-runner → frontend-designer's existing honest-evidence path.** The
   runner-advisory points native surfaces at the already-shipped "build/runtime evidence,
   clearly labeled NOT visual-contract proof" path; we add no native visual tooling.
5. **No-runner posture → confirmed.** Advisory only, no bundle fallback; a no-runner UI change
   can close with no machine UI proof (named tradeoff in `spec.md` § Intent).
6. **Spec 157 → confirmed already `abandoned`** (verified during review); only 155 needs a
   `superseded` marker.

## Approach

Land the **behavioral core first** (it is what actually changes agent behavior), then the
**doc/reference repoints**, then **tests + validation**. The core is a three-link chain:
detector (`ui-impact-detect.sh`, kept) → new `ui-runner-detect.sh` → validator advisory
(`ui-runner-advisory:` replaces the two `visual-contract-advisory:` emissions) and the
delegation close hook (`delegation-verify.sh`, strip the `report.json` check). The canonical
rule `visual-contract.md` is replaced by `ui-acceptance.md`; `verify_contract` is excised from
`agent-browser.sh`. Everything else is repointing prose to the new rule and collapsing the
`UI impact` tiers to `none | ui`. Do the core + rule + agent-browser edits as one coherent
pass (they interlock), then the prose repoints (independent), then rewrite the offline tests
to assert the new advisory + the gaming cases, then run the suites and validator to prove green.

## Files to touch

**Create:**
- `.agent0/context/rules/ui-acceptance.md` — canonical rule: acceptance = green UI test; agent-browser = dev primitive; runner-advisory model; a11y/vitals via `audit`; native honesty path.
- `.agent0/tools/ui-runner-detect.sh` — deterministic "does this project declare a UI test runner?" (exit 0 present / 1 absent; `--json`).
- `.agent0/tests/ui-acceptance/` — rewritten offline suite (detect, advisory fire/no-fire, gaming cases).

**Modify:**
- `.agent0/validators/run.sh` — replace the visual-contract advisory block with the ui-runner advisory (fires when UI surfaces changed AND no runner detected; never for backend/docs/tests).
- `.agent0/hooks/delegation-verify.sh` — remove `visual_contract_*` functions + the report.json check; UI briefs prove via the validator advisory only.
- `.agent0/tools/agent-browser.sh` — delete `verify_contract()` + the `verify-contract` dispatch + its usage/help line.
- `.agent0/context/rules/browser-primitive.md` — drop `verify-contract` from the wrapper surface + any visual-contract framing.
- `.agent0/tools/ui-impact-detect.sh` — reword header comments (drop spec-155/visual-contract framing; it now feeds the runner advisory). Logic unchanged (surface detection is still correct).
- `.agent0/context/rules/delegation.md` — § UI-producing briefs: `DONE_WHEN` = green UI-test command, not `verify-contract`.
- `.agent0/context/rules/spec-driven.md` — `UI impact` semantics → `none | ui`; "visual-contract obligation" → "UI-test proof obligation".
- `.agent0/skills/sdd/templates/spec.md.tmpl` — `**UI impact:** none` comment repointed to `ui-acceptance.md`; tiers → `none | ui`.
- `.agent0/skills/frontend-designer/{SKILL.md,references/done-proof.md,scripts/frontend-designer.sh,templates/fixture-spec.json.tmpl,templates/design-direction.md.tmpl,references/imagery.md}` — done-proof = green project UI test; native/motion honesty paths preserved, re-anchored off spec 155.
- `.claude/skills/product/**` — references that imply the design-time contract is verified by an implementation bundle → design-time artifact is input for writing tests, never implementation proof.
- `.agent0/context/rules/post-launch-maintenance-loop.md` + `.agent0/context/templates/post-launch-maintenance-loop/review-checklist.md` — bundle reference → green UI test.
- `CLAUDE.md` + `AGENTS.md` — managed index block "Visual contract acceptance" → "UI acceptance".
- `docs/specs/155-visual-contract-acceptance-gate/spec.md` — `**Status:** superseded by 206-retire-visual-contract-gate`.
- `.agent0/memory/*` — entries asserting the visual-contract doctrine; finalize via `memory-maintain.sh finalize`.

**Delete:**
- `.agent0/context/rules/visual-contract.md` — replaced by `ui-acceptance.md`.
- `.agent0/tests/visual-contract/` — replaced by `.agent0/tests/ui-acceptance/`.
- `.agent0/tests/agent-browser/10-dogfood-visual.sh` — exercised the retired verify-contract.

## Alternatives considered

### Rename `verify-contract` → `smoke-contract` instead of removing it
Rejected: it keeps an acceptance-shaped output (`report.json` with `overall`) one rename away
from being reused as a gate — the exact footgun the spec calls out. Removal is cleaner and the
ad-hoc need is already served by `run`/`audit`.

### Keep `visual-contract.md`, just flip the advisory to non-owed
Rejected: leaves the entire fixture format, the 3-tier vocabulary, and the design-time→bundle
reconciliation alive as dead prose that drifts. A clean rule replacement is less to maintain
and unambiguous about what acceptance now is.

### Make the runner-advisory blocking from day one
Rejected per the spec's non-goal and the rule-of-three demand test: a mandatory gate that
over-fires gets rubber-stamped or disabled. v1 is advisory; hardening is a future demand-gated spec.

## Risks and unknowns

- **Stack-neutral runner detection over/under-fires.** Mitigation: the `.agent0/ui-test.json`
  override + a conservative known-signal list; tests cover backend-only-change-no-fire.
- **Blast radius in frontend-designer.** Its done-proof IS verify-contract; the rewrite must
  preserve the fail-closed honesty posture (native/motion) while swapping the acceptance source.
- **Sync churn for consumers** (e.g. cognixse) — handled by non-goals: legacy bundles stay as
  history; `sync-harness.sh` flags customized rule files for manual reconciliation.
- **Memory edits need the finalize step** (`memory-maintain.sh finalize`) or the projection goes stale.

## Research / citations

- Field evidence: `~/cognixse` (`apps/web/e2e/*.spec.ts`, `.github/workflows/e2e.yml`) vs `docs/specs/*/agent-browser/` bundles; head-to-head `notifications.spec.ts` ⟷ `087/visual-contract.json`.
- Adversarial review: Codex (gpt-5.5) `ship-with-changes`, `/tmp/codex-spec-review-out.txt`.
- Precedent: `.agent0/context/rules/typecheck-advisory.md` (declare-the-primitive advisory shape), `tdd.md`, `lint-validator.md`.
- Spec 155 (`visual-contract-acceptance-gate`), spec 157 (`visual-contract-telemetry`, abandoned).
