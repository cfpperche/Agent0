# 167 - scope-admission-governance

_Created 2026-06-07._

**Status:** shipped

**UI impact:** none

## Intent

Turn spec 166's scope-admission doctrine into a first-class rule for deciding when Agent0 should build, defer, reject, or instrument a proposed first-party capacity. The goal is to make "do not build until the trigger fires" operationally clear without adding any new hook, validator, checker, or product surface in v1.

## Acceptance criteria

- [x] **Scenario: capacity proposal has an admission path**
  - **Given** a future proposal adds a first-party Agent0 capacity, governance lane, hook, tool, skill, sync surface, or hard gate
  - **When** the proposer reads the scope-admission rule
  - **Then** they can classify the proposal as admit, defer, reject, instrument-only, or harden-existing, with required evidence for each outcome

- [x] **Scenario: rule-of-three is concrete**
  - **Given** a proposal depends on repeated demand, dogfood pain, or drift
  - **When** the scope-admission rule is applied
  - **Then** the rule names what counts as evidence, how to record deferred signals, and when a single incident can justify a narrow safety fix

- [x] **Scenario: hard gates need a higher bar**
  - **Given** a future spec proposes turning an advisory/report into a blocking gate
  - **When** the scope-admission rule is applied
  - **Then** the spec must justify determinism, low false-positive risk, bypass/audit posture, consumer blast radius, and validation evidence before hardening

- [x] **Scenario: product drift remains bounded**
  - **Given** a proposal would make Agent0 own consumer release, operation, deployment, observability, or a dashboard
  - **When** the scope-admission rule is applied
  - **Then** the rule routes it to reject or defer unless a future spec explicitly moves the Agent0/product boundary

- [x] `.agent0/context/rules/scope-admission-governance.md` exists and is linked from `.agent0/context/rules/agent0-governance-doctrine.md`.
- [x] `.agent0/context/rules/spec-driven.md` points future Agent0 capacity specs at the scope-admission rule.
- [x] This spec adds no new runtime mechanism, hook, validator, script, or sync apply.

## Non-goals

- Enforce scope admission mechanically in a hook, validator, or SDD template checker.
- Add a new status field, schema, YAML registry, CLI command, or dashboard for capacity proposals.
- Decide or implement the candidate follow-ups `gate-algebra`, `security-governance-lane`, or `continuous-evolution-spine`.
- Rewrite historical specs to backfill an admission section.
- Change consumer projects or run harness sync.

## Open questions

- [ ] Should the admission brief become an optional section in a future SDD template after enough new capacity specs use it manually?
- [ ] Should deferred signals eventually get a structured file, or are reminders/routines/spec open questions enough until repeated friction appears?

## Context / references

- `docs/specs/166-agent0-governance-doctrine/` - parent doctrine and candidate follow-up.
- `.agent0/context/rules/agent0-governance-doctrine.md` - layered governance model and admission checklist.
- `.agent0/context/rules/visual-contract.md` - precedent for advisory-first hardening trajectory.
- `.agent0/context/rules/routines.md` - precedent for rule-of-three deferral of autonomous mode.
- `.agent0/context/rules/artifact-budgets.md` - precedent for retiring a bad mechanism and keeping a narrower circuit-breaker.
- `.agent0/context/rules/spec-driven.md` - SDD rule that should route capacity specs to this doctrine.
