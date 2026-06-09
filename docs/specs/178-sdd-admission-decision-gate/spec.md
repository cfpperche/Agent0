# 178 — sdd-admission-decision-gate

_Created 2026-06-08._

**Status:** shipped
**Closure:** 2026-06-08 — rule prose only (`spec-driven.md` §§ When SDD applies/When to skip + `visual-contract.md` framing); doctor 24 ok/0 broken; spec-verify pass 1/1; read-through green on all 4 acceptance scenarios; residual: none — consumer sync is a separate call

**UI impact:** none

## Intent

The SDD admission gate (`spec-driven.md` § *When SDD applies*) lists **"Touches 3+ files, or introduces a new module"** as a standalone trigger. That criterion uses **mechanical breadth** — file count — as a proxy for spec-worthiness, and it misfires: an obvious-cause bugfix that renames a field across 5 files, or a UI tweak that moves two components across 4 files, drags the work into full spec/plan/tasks ceremony despite having *no decision to make before coding*. Breadth is not the signal; **the presence of a pre-code decision** is.

This spec replaces the file-count trigger with a **decision-based admission gate**, operationalized as a small fixed set of questions a contributor answers before editing (the "5-question test"): if every question has a trivial / already-determined / not-applicable answer, skip SDD and go straight to the edit; if even one requires explanatory writing, SDD is owed. Mechanical breadth is demoted from a trigger to mere evidence — and only when breadth reflects **crossing independent semantic/ownership boundaries** (API + client + persistence + docs), never raw file count (component + hook + test + style).

A second, independent axis is decoupled in the same change: **proof-worthiness** (does this need to be proven by driving the UI?) is separated from **spec-worthiness** (does this need pre-code intent?). A UI tweak is typically *spec-worthiness = no, proof-worthiness = yes* — so it skips SDD but still owes a visual-contract check. Because today's `visual-contract.md` is triggered *by a spec or delegated task*, decoupling leaves UI proof without a recipient; this spec gives that proof a home **outside** the spec (PR body / report path / handoff) so skipping SDD never silently waives verification.

This is a consumer-facing flow change (ships via `sync-harness`): it must serve a product repo full of fixes and UI tweaks, **not** Agent0's atypical governance cadence (Agent0 alone has ~166 specs vs ~48 across all 7 consumers combined — the volume signal is an Agent0 artifact, so the gate is calibrated for consumers). The change is rule-doc prose only: no new tool, hook, validator, or gate.

## Acceptance criteria

- [x] **Scenario: file-count no longer admits a wide-but-trivial change**
  - **Given** the revised `spec-driven.md` § *When SDD applies*
  - **When** a contributor evaluates an obvious-cause change that touches many files but crosses no contract/ownership boundary (e.g. a mechanical rename across 5 files)
  - **Then** the gate says **skip** — no criterion is satisfied by file count alone, and the rule text states breadth is evidence only when it reflects boundary-crossing

- [x] **Scenario: a costly-but-obvious change is still admitted**
  - **Given** the revised gate
  - **When** the change has no approach-debate but touches a public API / schema / permission / persisted-data / migration / rollback-sensitive surface
  - **Then** the gate admits it via the reversibility/contract criterion — *not* via file count — so "obvious but expensive to get wrong" still gets a spec

- [x] **Scenario: the 5-question test is the operational gate**
  - **Given** § *When SDD applies* / § *When to skip* rewritten around the question set
  - **When** a contributor cannot give a short, already-determined answer to at least one of: (1) what observable behavior/contract changes, (2) who outside the local file depends on it, (3) how it will be proven, (4) how it is reverted/migrated if wrong, (5) which alternative was chosen among plausible options
  - **Then** SDD is owed; if all five are trivial / not-applicable, SDD is skipped

- [x] **Scenario: UI tweak skips SDD but still owes proof**
  - **Given** a small UI layout/copy/style tweak that changes no flow, state semantics, permission, persisted data, or contract
  - **When** the contributor applies the revised gate
  - **Then** SDD is skipped **and** the rule directs them to satisfy the visual-contract obligation outside a spec (declare/record effective `UI impact` + browser-driving evidence in PR body / report path / handoff)

- [x] `spec-driven.md` § *When SDD applies* contains no file-count trigger; breadth appears only as boundary-crossing evidence
- [x] `spec-driven.md` § *When to skip* explicitly lists mechanical multi-file renames and obvious-cause bugfixes (even with test/fixture/doc churn) as skip cases
- [x] `visual-contract.md` states the UI-proof obligation holds whether or not a spec exists, and names the non-spec recipient for the evidence
- [x] The revised gate stays **tight** — the 5-question test is the primary mechanism; no exhaustive enumerated catalog of contract surfaces that would rot or re-introduce over-triggering by literal match

## Non-goals

- Tightening *overall* SDD volume / adding an admission quota — consumer evidence shows their cadence is healthy; this is about the *small-change boundary*, not throughput.
- Any Agent0-local "apply SDD less to meta-governance" discipline — that is a separate, optional `CLAUDE.md`/`project-core.md` concern, not a shared-rule change.
- New tooling: no admission-checking script, hook, or validator advisory. Prose-only rule change.
- Changing the `**Verify:**` / spec-verify mechanism (spec 177) or the closure-cluster convention (commit `d6da13c`).
- Rewriting `visual-contract.md`'s verification mechanics — only adding the "owed with or without a spec + non-spec recipient" clause.

## Open questions

- [x] Final wording of the 5-question test — Claude favors leading with the questions and ≤3 illustrative examples; Codex's draft enumerates contract surfaces (API/schema/permission/billing/telemetry/flag/persisted-data). Resolve at `/sdd plan`: questions-primary with short examples, OR questions + a compact surface list. (Owner: founder; Claude's recommendation = questions-primary to avoid enumeration rot.)
- [x] Does "boundary-crossing" need a one-line definition in the rule, or is it self-evident from the API-vs-component example? (Lean: one example sentence, no formal definition.)
- [x] Where exactly does the non-spec UI-proof evidence live by default — PR body, a `report.json` path, or handoff — and should the rule pick one or list all three as acceptable? (Lean: list all three as acceptable; do not mandate one.)

## Context / references

- `.agent0/context/rules/spec-driven.md` §§ *When SDD applies* / *When to skip* — the gate being revised.
- `.agent0/context/rules/visual-contract.md` — the proof axis; needs the "owed with or without a spec" clause.
- Closure-cluster commit `d6da13c` (this session) — `**Status:**` enum + `**Closure:**` split + slim notes template; the sibling SDD-flow fix from the same Claude×Codex debate.
- Adversarial debate transcripts (Claude×Codex via `codex-exec.sh`): `.agent0/.runtime-state/codex-exec/sdd-debate-out.md` (broad SDD-flow critique) and `.agent0/.runtime-state/codex-exec/sdd-threshold-out.md` (focused admission-trigger debate; source of the 5-question test and the boundary-crossing reframe).
- Consumer spec-count evidence (2026-06-08): Agent0 166 vs cognixse 34 / codexeng 7 / mei-saas 2 / ag-antecipa 2 / acmeyard 1 / tmux-sentinel 1 / tese 1 — establishes the gate must be calibrated for consumers, not Agent0.
- `.agent0/context/rules/agent0-governance-doctrine.md` — this change touches a consumer-facing harness surface (the SDD rule), so classify scope at `/sdd plan`.
