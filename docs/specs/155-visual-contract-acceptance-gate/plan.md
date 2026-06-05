# 155 — visual-contract-acceptance-gate — plan

_Drafted from `spec.md` on 2026-06-05. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The verification *mechanism* already exists: `agent-browser.sh verify-contract <url> <fixture.json> <outdir>` opens a URL, snapshots a11y + console + vitals + screenshot, asserts a fixture-spec (`{ required:[{role,name}], max_console_errors }`), and writes `report.json` (`{ overall:"pass"|"fail", checks:[…] }`) — fail-closed (`unavailable` ≠ pass) per spec 152/153. So 155 is NOT "build a browser verifier." It is three things layered on top: **(1) a declaration + detection trigger** that decides *when* a visual contract is owed, **(2) a depth extension** to the contract format so it covers navigation/interaction/flow (the user's explicit requirement) and not just static render, and **(3) acceptance wiring** into SDD and the delegation gate so the contract is an acceptance artifact rather than an optional nicety. All of it ships as runtime-neutral `.agent0/` rules/tools/hooks (sync-harness-propagated), because Agent0 itself has no UI — it ships the *mechanism* that activates in consumer projects that do.

Order of build (each slice independently gate-checkable): D1 declaration convention + rule doc → D2 detection tool → validator advisory → D3 contract-depth extension to `verify-contract` → D4 delegation wiring → D5 docs/reconcile → tests throughout (TDD: each tool/extension lands with its `NN-*.sh` test in the same slice). The advisory posture (non-blocking) is deliberate and load-bearing: it mirrors the established `tdd/lint/typecheck` advisories so a new discipline earns trust before it can block (rule-of-three), and it means interactive-verification flakiness can never break a build in v1.

## Decisions (resolves every spec § Open question — no deferred follow-ups)

- **D1 — Declaration field.** Adopt Codex's single 4-valued field `UI impact: none | render | interaction | flow` (folds trigger + depth into one token). Canonical home: a `**UI impact:**` line in `spec.md` (adjacent to `**Status:**`), default `none` when absent. Optional per-task override as a `UI impact:` token in a `tasks.md` task line. `none` ⇒ no contract owed; `render`/`interaction`/`flow` ⇒ a contract at that (cumulative) depth is owed.
- **D2 — Detection heuristic.** New `.agent0/tools/ui-impact-detect.sh` classifies a changed-path set (from `git diff --name-only <range>` or stdin). A path is a **rendered browser surface** if it matches any of: extension `\.(tsx|jsx|vue|svelte|astro|mdx)$` or `\.(css|scss|sass|less|styl)$` or a web template `\.(html|hbs|ejs|pug|blade\.php|erb|twig)$`; OR a path segment in `{components,pages,app,views,layouts,routes,screens,ui,styles,theme,design-system}/`. **Excluded (never UI):** anything under `docs/`, `*.md`, `.agent0/`, `test`/`tests`/`__tests__`, `migrations/`, `*.sql`, `*.go`/`*.rs`/`*.py` server files, CLI dirs, `package.json`/lockfiles. Output: a suggested `UI impact` level + a `mismatch` flag when surfaces changed but the declared level is `none`/absent. The tool **never sets** the declaration — it only suggests (declaration-first, spec § Acceptance scenario 3).
- **D3 — Contract format = extend, don't fork.** Keep the existing `verify-contract` fixture-spec as the `render` tier verbatim (backward compatible). Add two optional top-level arrays: `interactions` (each `{ action: click|type|press|select, target:{role,name}, value?, expect:{role,name,state?} , flaky?:bool }`) and `flow` (each step `{ goto?:url, action?, target?, value?, expect_url?:regex, expect:{role,name}?, flaky?:bool }`). `verify-contract` executes them in order via the wrapper's policy-gated `run -- <agent-browser act verbs>` passthrough (click/type/navigate already exist in the underlying binary), asserting post-action a11y/URL/state; each step appends a `check` to `report.json`. A `"flaky": true` step that fails is recorded as a `warn` check, not `fail` (does not flip `overall`). Tiers are cumulative: `interaction` runs render+interactions; `flow` runs render+interactions+flow.
- **D4 — Delegation wiring (no 6th field).** `delegation.md` documents that a UI-producing brief carries the proof in the existing fields: `CONSTRAINTS` = "no done from static review alone"; `DELIVERABLE` = evidence-bundle path; `DONE_WHEN` = the exact `agent-browser.sh verify-contract … && jq -e '.overall==\"pass\"' <outdir>/report.json` command. `delegation-verify.sh` already surfaces validator stderr, so the new `visual-contract-advisory:` auto-propagates; add a small check that, when the brief declared UI, looks for the named evidence bundle's `report.json` and surfaces an advisory if it's absent or not `pass` (non-blocking).
- **D5 — Flakiness.** v1 is non-blocking, so flakiness cannot fail a build. The `"flaky": true` per-step downgrade (D3) plus documented timeout/retry guidance in the rule doc is the whole story for v1.

## Files to touch

**Create:**
- `.agent0/context/rules/visual-contract.md` — canonical rule: `UI impact` declaration, the 3 cumulative tiers, the extended contract schema, SDD + delegation plug-in points, advisory-not-blocking posture, the `flow`-first future-hardening note, reconcile-with-`/product`.
- `.agent0/tools/ui-impact-detect.sh` — the D2 detection heuristic (deterministic, stdin or git-range input, JSON/text output).
- `.agent0/tests/visual-contract/run-all.sh` — glob runner (`[0-9][0-9]-*.sh`), mirrors `.agent0/tests/agent-browser/run-all.sh`.
- `.agent0/tests/visual-contract/_lib.sh` — shared assert helpers (or source the agent-browser `_lib.sh` if reusable).
- `.agent0/tests/visual-contract/01-detect.sh` — ui-impact-detect classification (surface→level, exclusions, mismatch flag).
- `.agent0/tests/visual-contract/02-advisory.sh` — validator emits `visual-contract-advisory:` on a UI surface change with no declaration; silent on `none`/non-UI.
- `.agent0/tests/visual-contract/03-contract-tiers.sh` — extended fixture-spec parsing + tier orchestration via `AGENT0_BROWSER_BIN` fake-bin (render/interaction/flow; `flaky` downgrade; unavailable≠pass).
- `.agent0/tests/visual-contract/04-delegation.sh` — `delegation-verify.sh` surfaces the advisory + evidence-bundle check for a declared-UI brief.
- `.agent0/tests/visual-contract/fixtures/*.json` — example contracts (render-only, with-interactions, with-flow, malformed).

**Modify:**
- `.agent0/validators/run.sh` — add the `visual-contract-advisory` step (after the lint/typecheck advisories, before the JSON/tail capture); call `ui-impact-detect.sh` over the session diff; emit on stderr only (non-blocking).
- `.agent0/tools/agent-browser.sh` — extend `verify_contract()` to read optional `interactions`/`flow` arrays and execute them (D3), backward-compatible with render-only fixtures.
- `.agent0/hooks/delegation-verify.sh` — add the declared-UI evidence-bundle check (D4); the advisory itself already auto-surfaces.
- `.agent0/context/rules/delegation.md` — document the UI-producing-brief field mapping (D4).
- `.agent0/context/rules/spec-driven.md` — note the `**UI impact:**` line + that UI specs carry visual acceptance.
- `.agent0/context/rules/browser-primitive.md` — cross-reference the extended `verify-contract` tiers.
- `CLAUDE.md` + `AGENTS.md` — add the managed-block index section "Visual contract acceptance" (one paragraph, like the siblings).
- `.claude/skills/product/SKILL.md` (or its references) — one-line reconcile note: design-time visual contract → SDD impl-evidence (D5/reconcile). Smallest possible touch.
- `.agent0/skills/sdd/templates/spec.md.tmpl` — add the optional `**UI impact:**` line to the scaffold so new specs declare it.

**Delete:** none.

## Alternatives considered

### Invent a new standalone visual-contract file format + a new verifier tool

Rejected because `agent-browser.sh verify-contract` already defines a fixture-spec format, already writes `report.json`, is already fail-closed, and is already tested under `.agent0/tests/agent-browser/`. A parallel format would duplicate the mechanism, fragment the contract surface, and violate the meeting's anchored decision to *reconcile* with existing surfaces (and the repo rule against shipping redundant mechanisms). Extending the existing format is strictly less code and less drift.

### Make v1 a hard blocking gate (Codex's minority-report alternative)

Rejected for v1 because a mandatory browser-verification gate that over-fires gets rubber-stamped or disabled — worse than no gate — and Agent0's consistent pattern (anchored in the meeting ledger to `tdd.md`/`lint-validator.md`/`typecheck-advisory.md`) is advisory-first, hard-gate-by-rule-of-three. The minority report is preserved: the rule doc names `UI impact: flow` as the first hard-gate candidate for the future dogfood-gated spec. (This is a deliberate scope line, not an unresolved question — see spec § Open questions, all resolved.)

### Add a 6th delegation field (`VISUAL_PROOF:`)

Rejected because the existing 5 fields already carry it cleanly (DONE_WHEN names the command, DELIVERABLE names the bundle), and `delegation-gate.sh`'s validation is a fixed 5-field contract that other specs depend on. A 6th field is a breaking change to the gate for zero expressive gain.

## Risks and unknowns

- **R1 — Extending `verify_contract()` to drive act verbs is the meatiest slice.** The underlying `agent-browser` binary's act-verb syntax (click/type/navigate by role+name) must be confirmed against its actual CLI; the wrapper reaches it via the policy-gated `run --` passthrough. Mitigation: tests use the `AGENT0_BROWSER_BIN` fake-bin stub to verify the *orchestration* (correct verb sequence, correct assertion, `flaky` downgrade, unavailable handling) offline/deterministically — exactly how the existing agent-browser logic tests work — so the slice is gate-checkable without a live browser. A live dogfood is a separate, skip-with-pass test (`need_live`).
- **R2 — Detection false-positive/negative balance.** The glob set will mis-flag some non-UI paths and miss some non-obvious UI. Mitigation: it only *suggests* (advisory), declaration is the source of truth, and the exclusion list is conservative; tune via tests, not by widening blast radius.
- **R3 — Validator step cost/latency.** `ui-impact-detect.sh` over the session diff runs on every validator pass. Mitigation: pure path-pattern matching over an already-computed name-only diff; no file content reads; bounded.
- **R4 — `AGENTS.md` is baseline-tracked.** The managed-block edit must go in the shared index region, not break the Codex baseline. Mitigation: mirror the exact managed-block pattern the sibling sections use.

## Research / citations

- Spec-155 recon map (this session) — `agent-browser.sh:264-322` (`verify_contract` signature + fixture-spec), `:508-517` (dispatch incl. `run` passthrough), `validators/run.sh:235-240` (advisory emission), `delegation-verify.sh:103-105` (stderr surfacing), `delegation-gate.sh:98-111` (5-field parse), `.agent0/tests/agent-browser/` (glob runner + fake-bin pattern).
- `.agent0/meetings/visual-contracts-sdd-delegation-gate-2026-06-05T21-29-24Z/meeting.md` — the decision-grade deliberation (anchored ledger) this plan implements.
- `.agent0/context/rules/{tdd,lint-validator,typecheck-advisory}.md` — the advisory-emission precedent the new advisory mirrors.
- `.agent0/skills/squad/references/squad-contract.md` — fail-closed gate authoring (the squad.json for this spec must prove the spec's own tests run, not vacuously green).
