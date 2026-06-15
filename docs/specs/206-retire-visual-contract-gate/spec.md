# 206 — retire-visual-contract-gate

_Created 2026-06-14._

**Status:** shipped

**Closure:** 2026-06-14 — visual-contract acceptance gate retired. Created `.agent0/context/rules/ui-acceptance.md` + `.agent0/tools/ui-runner-detect.sh`; validator now emits `ui-runner-advisory:` (UI surface changed + no declared runner); removed `verify_contract` from `agent-browser.sh`, the `report.json` check from `delegation-verify.sh`, `visual-contract.md`, and the old test suite; repointed browser-primitive/delegation/spec-driven/frontend-designer/product/post-launch + CLAUDE.md/AGENTS.md; `UI impact` tiers collapsed to `none|ui`; superseded spec 155; memory updated. Verify: `bash .agent0/tests/ui-acceptance/run-all.sh` 42/42 pass (logged in notes.md). Residual: none in scope; the one harness test failure (`13-dogfood-adopt.sh`) is a pre-existing live test needing interactive CDP login, unrelated to this spec.

**UI impact:** none

## Intent

Spec 155 made the *visual contract* a first-class acceptance artifact: every UI-producing
spec authors a `visual-contract.json` (a 3-tier fixture), runs `agent-browser verify-contract`,
and commits a frozen evidence bundle (`agent-browser/{report,a11y,console,vitals}.json` +
`screen.png`). Field evidence from the consumer `cognixse` (~28 specs of the "project" era)
shows this bundle is **dead weight in any project mature enough to matter**: cognixse runs a
full Playwright suite in CI (`.github/workflows/e2e.yml`), almost every spec with a
`visual-contract.json` has a sibling `.spec.ts` covering the same feature, and the head-to-head
(spec 087 `notifications`) proves the contract is a **strict subset** of the e2e test — fewer
assertions, no negative/RBAC cases, no state-mutation, not in CI, no regression protection,
runs once and freezes. We pay ~80% of e2e authoring cost for ~20% of the value, and **Agent0
itself maintains the entire machine** (fixture format, `verify_contract`, the detector, the
validator advisory, the delegation-verify hook, the offline stub suite, the `/product`
design-time reconciliation) that sustains a weaker duplicate. This spec retires the visual
contract as an *acceptance mechanism* and its per-spec load. UI acceptance becomes **a green
UI test** (the stack's idiomatic e2e/runner) covering the changed surface; a project that
produces UI without a test runner gets an **advisory to provision one** (the harness requires
the runner instead of shipping a substitute). `agent-browser` survives intact as the
runtime-neutral dev/inspection primitive — eyes+hands for driving, auth/adopt, and debugging
until the test is green — it simply stops being an acceptance-artifact generator. This aligns
with the project's own doctrines: *speculative observability is harness-drift* (the bundle
never re-runs, never gates) and *match rigor to reversibility* (the advisory is non-blocking,
so a throwaway prototype ignores it and proceeds without formal proof, which is acceptable).

**This is a deliberate tradeoff, not equivalent coverage.** Agent0 moves from *weak proof
everywhere* to *strong proof where a UI test runner exists, and an explicit, named gap where
it does not* — a no-runner UI change can close with **no machine UI proof at all** until the
runner is provisioned. We accept that gap rather than paper over it with a frozen bundle,
because the bundle's "proof" was a strict subset of a real test that rots on the day it is
written. The honest cost is that the strongest case for the old gate — greenfield projects and
delegated one-off UI work with zero test infra, where "use the project's runner" is undefined —
loses its automatic, uniform, stack-neutral proof. The mitigation is the runner-advisory
nudging that infra into existence, not a substitute we must maintain.

## Acceptance criteria

- [x] **Scenario: UI change with a test runner — acceptance is a green test**
  - **Given** a consumer project that declares a UI test runner (e.g. an `e2e` script / `playwright.config` / equivalent)
  - **When** a spec or delegated task changes a rendered UI surface
  - **Then** the owed proof is a green run of the project's UI test covering that surface (recorded in the PR/CI), and no `visual-contract.json` fixture or `agent-browser/` evidence bundle is authored or expected

- [x] **Scenario: "covering the surface" is real coverage, not a gameable smoke**
  - **Given** a UI change whose acceptance is a green UI test
  - **When** the proof is judged
  - **Then** the test must name the changed route/surface, perform at least one **semantic assertion after render** (not a bare page load), exercise the changed interaction/state when applicable, and contain no `skip`/`only` on that test — a test that only loads `/`, is skipped, or asserts nothing does **not** satisfy acceptance (the exact detection/command/CI contract is resolved at `plan` time — see Open questions)

- [x] **Scenario: UI change with no runner — advisory to provision**
  - **Given** a consumer project with no declarable UI test runner
  - **When** a changed-path set includes a rendered UI surface
  - **Then** the post-edit validator emits a non-blocking `ui-runner-advisory:` telling the author to provision the stack's idiomatic UI test runner — it does **not** fall back to an `agent-browser verify-contract` acceptance bundle

- [x] **Scenario: agent-browser remains a usable dev primitive**
  - **Given** the visual-contract acceptance gate is retired
  - **When** an agent needs to drive/inspect a web UI during development (navigate, click, snapshot, auth/adopt)
  - **Then** `agent-browser.sh caps/route/run/audit/adopt` work exactly as before, and `browser-primitive.md` no longer frames `verify-contract` as a visual-contract acceptance verifier

- [x] **Scenario: delegation gate proves UI by test, not bundle**
  - **Given** a delegated brief that produces UI
  - **When** the brief is authored and verified at `SubagentStop`
  - **Then** `DONE_WHEN` names a green UI-test command (not `verify-contract … jq .overall==pass`), and `delegation-verify.sh` no longer checks a `report.json` `.overall=="pass"`

- [x] **Scenario: frontend-designer keeps a fail-closed completion contract**
  - **Given** `frontend-designer`'s current done-proof IS `verify-contract` (its only acceptance ladder)
  - **When** the gate is retired
  - **Then** its done-proof becomes the project's green UI test when a runner exists; for no-runner or native-only surfaces it falls back to **clearly-labeled build/runtime evidence** (preserving the skill's existing honesty path) **plus** a `ui-runner-advisory` — the skill never silently loses a completion contract or claims visual proof it didn't produce

- [x] **Scenario: stale visual-contract evidence never counts as acceptance**
  - **Given** a consumer repo with legacy `visual-contract.json` / `agent-browser/` bundles from before this spec
  - **When** validators run
  - **Then** that frozen evidence is ignored — it is historical record, never treated as satisfying UI acceptance, and legacy already-closed specs are not retroactively nagged

- [x] **Decision (was Open Question): `agent-browser.sh verify-contract` cannot survive as an acceptance-shaped artifact** — it is either removed, or renamed (e.g. `smoke-contract`) with its output stripped of acceptance semantics (no `report.json` with `overall: pass`), so it cannot be reused as a green gate. The exact disposition is chosen at `plan` time; "keep it looking like a gate" is not an option.

- [x] The canonical rule `visual-contract.md` is replaced by `ui-acceptance.md` (acceptance = green UI test; agent-browser = dev primitive; runner-advisory model), and every harness reference is repointed: `browser-primitive.md`, `delegation.md`, `spec-driven.md`, `frontend-designer` (SKILL + `done-proof.md` + `verify` script + `fixture-spec` template), `/product` references, `post-launch-maintenance-loop.md` (+ its review-checklist template), `spec.md.tmpl`, the `CLAUDE.md`/`AGENTS.md` managed index block.
- [x] The `**UI impact:**` declaration is kept as a forcing-function but its tiers collapse to `none | ui` (the render/interaction/flow granularity existed only for the retired fixture format); `spec-driven.md` and `spec.md.tmpl` updated accordingly.
- [x] `ui-impact-detect.sh` is repurposed to feed the runner-advisory; the validator's two `visual-contract-advisory:` emissions are replaced by `ui-runner-advisory:`.
- [x] The offline test suite is updated: `.agent0/tests/visual-contract/` (esp. `03-contract-tiers.sh`, `04-delegation.sh`) and `.agent0/tests/agent-browser/10-dogfood-visual.sh` are retired or rewritten for the new advisory; tests cover the `ui-runner-advisory` fire/no-fire cases **and the gaming cases**: runner present but no UI command run, a `skip`/`only` test, a stale legacy bundle, a UI surface with no runner, and a backend-only change with a runner present (advisory must not fire).
- [x] Spec 155 is marked `superseded by 206-retire-visual-contract-gate`; spec 157 visual-contract-telemetry is confirmed already `abandoned` (no resurrection) — the supersession is noted in this spec.
- [x] Agent0 project memory entries asserting the visual-contract doctrine are updated via `memory-maintain.sh finalize`.

## Non-goals

- Retroactively deleting existing consumer evidence bundles (e.g. cognixse's `docs/specs/*/agent-browser/` + `visual-contract.json`) — they remain as historical record; `sync-harness.sh` never touches product code.
- Removing the `agent-browser` primitive or its wrapper subcommands (`caps/route/run/audit/adopt`) — only the *acceptance* role of `verify-contract` is in scope.
- Mandating a specific test framework (Playwright, Cypress, …) — the runner-advisory must be stack-aware, in the spirit of `typecheck-advisory`.
- Making any UI proof a **blocking** gate — v1 stays advisory; a hard gate ("green UI test required") is deferred behind the rule-of-three demand test, as spec 155's flow-tier hard-gate was.
- Removing `/product`'s **design-time** contract (screen-atlas, fixture-spec, moods) — that survives as design input/reference for writing tests; only the design-time→implementation-bundle reconciliation is cut.

## Open questions

_All resolved in `plan.md` § Decisions (2026-06-14)._

- [x] **The "runner contract"** → RESOLVED: deterministic declarable signals in a new `ui-runner-detect.sh` (a `test:e2e`/`e2e`/`test:ui` script in any `package.json`; known e2e config files; or a stack-neutral `.agent0/ui-test.json` override). CI not required; a local green run with recorded evidence suffices.
- [x] **a11y/console/vitals/overflow disposition** → RESOLVED: kept as an opt-in `agent-browser audit` sweep (not required acceptance), documented in `ui-acceptance.md`.
- [x] **Native/mobile no runner** → RESOLVED: the advisory points native surfaces at `frontend-designer`'s existing "honest build/runtime evidence, NOT visual-contract proof" path; no new native tooling.
- [x] **No-runner posture** → RESOLVED (confirmed): advisory only, no bundle fallback; named tradeoff in § Intent.

## Context / references

- `docs/specs/155-visual-contract-acceptance-gate/` — the spec this partially supersedes.
- `docs/specs/157-visual-contract-telemetry/` — adjacent; review for supersession.
- `.agent0/context/rules/visual-contract.md` — the rule being replaced by `ui-acceptance.md`.
- `.agent0/context/rules/browser-primitive.md` — agent-browser primitive (kept, re-framed).
- Field evidence: `~/cognixse` Playwright suite (`apps/web/e2e/*.spec.ts`, `.github/workflows/e2e.yml`) vs `docs/specs/*/agent-browser/` bundles; head-to-head `notifications.spec.ts` ⟷ `087/visual-contract.json`.
- Draft proposal: `/tmp/visual-contract-retire-draft.md` (this session, 2026-06-14).
- Adversarial review by a Codex agent (gpt-5.5, via Tachyon, 2026-06-14): verdict `ship-with-changes`; its accepted points are folded into this spec (named-tradeoff Intent, anti-gaming coverage scenario, frontend-designer/native fail-closed scenario, stale-evidence scenario, verify-contract decision, a11y/vitals + native open questions, gaming-case tests). Raw output: `/tmp/codex-spec-review-out.txt`.
- Project doctrines: memory `feedback_speculative_observability`, `feedback_match_rigor_to_reversibility`, `feedback_agent0_changes_ship_via_rules_not_memory`.
