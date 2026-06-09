# 185 — harness-evolution-program

_Created 2026-06-09._

**Status:** in-progress

**UI impact:** none

## Intent

Umbrella/program spec holding the 8 findings of the 2026-06-09 external-perspective harness review (conducted by Claude Fable 5 at the maintainer's request: "evolve where? optimize where? fix where?" — explicitly independent opinion, not a synthesis of the project's own backlog). Each point gets detailed one-by-one in a dedicated working round; the outcome of each round is a **disposition**: admit as a child spec (next free NNN), kill with recorded rationale, or route to a decision-grade debate first. This umbrella owns the portfolio and the decisions; it implements nothing itself.

## The portfolio

### Evolve

- **P1 — Evidence bundle as the product.** The harness self-describes as a "governance/evidence harness" but evidence is a scattered by-product (validator output, spec-verify records, delegation-audit.jsonl, visual-contract reports, secrets-audit). Proposal: every change/spec emits one consolidated machine-readable *evidence bundle* (what was validated, by which command, what failed and was fixed, which agent/model touched what, cost/time). Rationale: provenance of agent-written code is becoming a compliance/market requirement; "the harness that makes agent-built software auditable" is a differentiated thesis, and most infrastructure already exists — only the aggregator and format are missing.
- **P2 — Decide: personal lab vs adoptable asset.** The harness has multi-team-platform architecture serving one user. If "adoptable asset": gap #1 is the adoption path (no installer, no 10-minute value-proving quickstart; current complexity is a moat against adoption). If "personal lab": stop paying generality costs and optimize for one operator's throughput. Funding both paths without deciding is the expensive option. **Gates P3, P4, P6.**
- **P3 — Exit symmetric multi-runtime parity.** A large fraction of the spec corpus is porting/parity/matrix upkeep. Proposal: declare the portable core = files + git + conventions (handoff, specs, memory, rules work in any runtime for free); Claude Code = reference runtime with full enforcement; other runtimes = best-effort consumers, no cell-by-cell parity commitment. **Deliberately contradicts the current multi-runtime posture → decision-grade debate required.** Related: the in-flight `terceiro-runtime` meeting (provider-adapter vs runtime admission).

### Optimize

- **P4 — Shrink the prose control plane.** 39 rules / ~416 KB is past the point where each marginal rule degrades compliance with the others (agents read pointers, not corpora); coupled prose drifts (the delegation↔artifact-budgets contradiction lived ~3 weeks). Proposal: discipline that matters becomes *mechanism* (gate/validator/template — fails loudly); explanation moves out of the control plane; numeric target on the order of ≤20 rules / ≤8 KB each. Migration, not bonfire.
- **P5 — Measure and consolidate the hook chain.** 5 PostToolUse hooks fire on every edit, 4 PreToolUse on every Bash/Agent call — each a bash process spawn; latency never measured. Measure p50/p95; if chain cost is material (>~150 ms), consolidate into a single dispatcher process that routes internally.
- **P6 — Kernel out of bash.** The harness kernel (3-way sync, memory, validation) is typeless bash; symptoms: a 62 KB rule explaining sync-harness.sh, ~360 shell tests compensating for no compiler. Proposal: small single binary (Go/Rust), bash hooks become thin shims. Precedent already accepted: agent-browser is a pinned Rust binary. **Gated by P2.**

### Fix

- **P7 — CI for the harness tests.** Verified fact: `.github/workflows/` contains only the site deploy; the ~360 tests across 44 suites run only when someone remembers, and there is no global runner (44 `run-all.sh`, no umbrella script). Cheapest highest-return correction in the repo: one workflow running all suites on push + a `run-all-suites.sh`.
- **P8 — Hook supply-chain integrity.** sync-harness installs executable shell into consumer projects, trusted-on-sync, running with full user permissions on every tool call. Minimum viable: a checksum manifest for shipped hooks, verified by doctor on the consumer side.

## Acceptance criteria

- [ ] **Scenario: every point reaches a disposition**
  - **Given** the 8 portfolio points above
  - **When** the program completes
  - **Then** each point has exactly one recorded disposition in `tasks.md`/`notes.md`: child spec opened (with NNN), killed (with rationale in `notes.md`), or decision recorded (for decision-type points)

- [ ] **Scenario: decision-type points are not silently admitted**
  - **Given** P2 (lab vs asset) and P3 (multi-runtime posture) are maintainer decisions, and P3 contradicts standing doctrine
  - **When** their detailing rounds run
  - **Then** P2 closes with an explicit maintainer decision recorded in `notes.md`, and P3 goes through a decision-grade debate (or an explicit maintainer override recorded as such) before any child spec is opened

- [ ] **Scenario: a detailing round produces a verifiable artifact**
  - **Given** any point's detailing round
  - **When** the round closes
  - **Then** the round's analysis (problem, evidence, options, recommendation, effort) exists either in the child spec's `spec.md` or in this umbrella's `notes.md` — never only in chat history

- [ ] Child specs are numbered at admission time (next free NNN), one per admitted point; this umbrella never contains their implementation.

## Non-goals

- Implementing any point inside this spec — the umbrella holds portfolio, dispositions, and cross-point sequencing only.
- Re-auditing the harness (the 2026-06-09 audit findings already shipped: commits `b999412`…`573a07a`).
- Committing to all 8 points — killing a point with recorded rationale is a first-class outcome.
- Deciding spec 171's fate here (tracked separately in HANDOFF.md Next Actions; it predates this program).

## Open questions

- [ ] P2 ordering: should the lab-vs-asset decision run before P3/P4/P6 detailing (it gates their worth), or after P7/P1 build momentum? Owner: maintainer.
- [ ] Does P1's evidence bundle subsume parts of P8 (signed manifest as part of the bundle format)? Resolve when P1 is detailed.

## Context / references

- 2026-06-09 audit session: doctor 24/24, drift green, 0 orphans, 164/173 specs shipped, ~360 tests/44 suites; fixes shipped as commits `b999412`, `7d571d9`, `28186fb`, `573a07a`.
- Verified facts grounding P5/P7: `.claude/settings.json` hook counts (PostToolUse: 5, PreToolUse: 4); `.github/workflows/` = `deploy-pages.yml` only.
- In-flight meeting `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/` — adjacent to P3 (synthesis pending, human's turn).
- Doctrine touchpoints: `.agent0/context/rules/agent0-governance-doctrine.md` (admission checklist applies to each child), `scope-admission-governance.md`, `artifact-budgets.md` (P4 precedent: prose mandate retired in favor of mechanism).
