# 211 — harness-cost-optimization

_Created 2026-06-19._

**Status:** draft
<!-- Bare enum only: draft | in-progress | shipped | shipped-partial | superseded | abandoned | deferred. Do NOT append dates/commits/test-counts/rationale here — that goes on the optional **Closure:** line below. -->

<!-- **Closure:** -->

**UI impact:** none

## Intent

Umbrella/program spec holding the 6 priority recommendations from the 2026-06-19 harness token/time/cost report (`.agent0/.runtime-state/reports/harness-token-time-cost-2026-06-19.md`). **The optimization target is the harness as shipped to consumer projects, not the Agent0 dev experience.** Agent0 is a stack-neutral template/governance harness that propagates via `sync-harness`; the shipped artifacts (the `AGENTS.md`/`CLAUDE.md` managed block, `context-inject.sh`, the `startup-brief.sh` mechanism) impose their token/time cost in **every session and every prompt of every consumer that syncs them**. The Agent0 local checkout was only the **measurement vehicle** — the report's Codex evidence comes from Agent0's own dev sessions, which the report itself flags as not consumer-representative (§ "Consumer distribution is not proven", rec #6). So value here is judged by **severity-if-omitted × breadth-across-consumers**, never by Agent0-local frequency.

Consequence for the portfolio: distinguish **shipped surface** (transfers to consumers verbatim — managed block, capability index, the two hooks → highest breadth) from **Agent0-specific content samples** (Agent0's own HANDOFF.md / full AGENTS.md — a measurement sample, not the consumer's cost; in a consumer their own handoff/core drives it). The fixes that matter most are the shipped *mechanisms*, applied so they help every consumer regardless of their content.

This umbrella owns the portfolio and the dispositions; it implements nothing itself. Each point gets exactly one disposition — **child spec opened** (next free NNN), **decided/recorded** (principle captured, no build), or **killed/deferred** (rationale recorded in `notes.md`). It exists now because the measurement is fresh and three of the six points directly bear on already-closed spec 185 (notably P5, killed for lack of measurement — this report supplies it).

This is the cost-optimization sibling of spec **185 (harness-evolution-program)** and follows the same "portfolio of dispositions, not a monolith" pattern (185 rejected being a single spec for the same reason).

## The portfolio

Triaged into **build** (becomes a child spec) and **record** (principle/no-op/watch — closes inside this umbrella).

### Build

Ranked by consumer breadth (R6 lens), highest first. All three are **shipped surface** — they propagate to every consumer via `sync-harness`.

- **R3 — `AGENTS.md`/`CLAUDE.md` capability index re-audit.** *Breadth: every consumer, every first turn — paid verbatim.* The managed capability index is ~2,587 tokens — the largest Agent0-controlled always-loaded block — and ships **identical** to every consumer, who pays the full token tax on the first turn whether or not they ever use image/video/sound/audio/transcribe/diagram/unused-code/… Spec 071/P4 already moved it to one-line discovery; this is a follow-up trim so rare/opt-in entries don't accrete operational detail. Rises to the top under the consumer lens precisely because it is verbatim-shipped surface with low per-consumer utility. (Report rec #4.)
- **R2 — `context-inject.sh` wall-time fast-path.** *Breadth: every consumer, every prompt.* ~0.76–0.85 s per `UserPromptSubmit` even when it emits 0 bytes; disabling retrieval only removes ~70–190 ms, so the floor is the shell/frontmatter/selection path itself, not retrieval. The hook ships, so the latency is paid on every prompt of every consumer session. Proposal: a cheaper fast path / precomputed index for frontmatter + retrieval candidates. **This is the measurement that 185's P5 (killed for lack of it) asked for** — 0.76–0.85 s is ~5× P5's ">~150 ms material" threshold. Largest dollar-neutral latency tax in the report. (Report rec #2.)
- **R1 — HANDOFF.md bullet discipline (shipped *mechanism*, Agent0-specific *sample*).** The 1,528-token brief measured is Agent0's own handoff content — a sample, not the consumer's cost. But the *mechanism* that ships is `summarize_handoff_section` printing whole non-empty lines, so one very long bullet can dominate the brief in **any** consumer. Proposal: a handoff style rule + non-blocking advisory/linter that ships and helps every consumer keep their own brief lean — first ~2 bullets per section stay compact, detail moves to follow-up bullets or referenced docs. Cheap, high-return, content-agnostic. (Report rec #1.)

### Record

- **R4 — Rules corpus stays lazy.** 38 files ≈ 97,959 tokens, but the model-visible path emits pointers + selected capsules, not the corpus. The report explicitly says compressing rules is **not** the right first lever. Disposition is "keep doing it" — a no-op confirmation, captured as a note; not a build. (Report rec #3.)
- **R5 — Delegation-verify perf budget.** `delegation-verify.sh` is the only measured hook above 1 s (median 1.87 s), acceptable because it runs only at subagent close — but it should not be expanded casually. Disposition: record a perf-budget guardrail note (likely in `delegation.md`), not buildable code. (Report rec #5.)
- **R6 — Frequency ≠ baseline importance (also the governing lens for this umbrella).** Agent0 repo frequency reflects harness development, not consumer value; shipped defaults should be decided by severity-if-omitted × breadth-of-applicability, not local frequency. This is not merely a portfolio item — it is the **ranking lens applied to R1/R2/R3 above** (the report measured Agent0's own sessions, which it flags as non-representative). Already adjacent to the `feedback_agent0_changes_ship_via_rules_not_memory` memory and the report's own rec #6. Disposition: record as principle (rule/memory), not a spec. (Report rec #6.)

## Acceptance criteria

- [ ] **Scenario: every point reaches a disposition**
  - **Given** the 6 portfolio points (R1–R6) above
  - **When** the program completes
  - **Then** each point has exactly one recorded disposition in `tasks.md`/`notes.md`: child spec opened (with NNN), decided/recorded (principle captured, location named), or killed/deferred (rationale in `notes.md`)

- [ ] **Scenario: build points produce verifiable child specs**
  - **Given** R1, R2, R3 are admitted as build work
  - **When** each is detailed
  - **Then** each opens its own `docs/specs/NNN-*` child with its own acceptance criteria, and this umbrella records the child NNN — the umbrella implements none of them directly

- [ ] **Scenario: R2 reconciles with killed P5**
  - **Given** 185's P5 ("measure and consolidate the hook chain") was killed for lack of measurement
  - **When** R2 is detailed
  - **Then** its child spec (or `notes.md`) cites the new measurement and states explicitly whether it reopens P5's concern or scopes narrower (context-inject only)

- [ ] Record points (R4, R5, R6) close inside this umbrella with their captured location named (rule path / memory entry), opening no child spec

## Non-goals

- Implementing any of R1–R6 here — children own implementation; this umbrella owns dispositions only.
- Compressing or deleting the rules corpus (R4 disposition is explicitly "keep lazy" per the report).
- Proving exact dollar cost — the report itself states billing is not provable from local token logs.
- Re-running the measurement; the 2026-06-19 report is the evidence base for this round.

## Open questions

- [ ] R2 scope: reopen 185's P5 (consolidate the whole hook chain into one dispatcher) or scope narrowly to a `context-inject` fast-path only? (Decide at R2 detailing — recommend narrow first, measure, expand only if justified.)
- [ ] R1 mechanism: non-blocking validator advisory vs a `/sdd`-style linter vs just a rule? (Decide at R1 detailing.)
- [ ] R3: now the top-breadth item — does the verbatim-shipped capability index warrant its own child spec (token budget per entry, advisory on accretion), or a one-pass direct trim? (Decide at R3 detailing — leaning child spec given it is shipped surface every consumer pays.)

## Context / references

- `.agent0/.runtime-state/reports/harness-token-time-cost-2026-06-19.md` — the source measurement report
- `docs/specs/185-harness-evolution-program/` — sibling umbrella; P4 (prose control plane, shipped), P5 (hook-chain measurement, killed — R2 supplies its missing evidence)
- `.agent0/hooks/startup-brief.sh`, `.agent0/hooks/context-inject.sh` — the measured hot paths (R1/R2)
- `AGENTS.md` / `CLAUDE.md` capability index (R3)
- `.agent0/context/rules/delegation.md` (R5), `feedback_agent0_changes_ship_via_rules_not_memory` memory (R6)
