# 185 — harness-evolution-program — plan

_Drafted from `spec.md` on 2026-06-09. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Run one **detailing round per point**, one point at a time (maintainer picks the next point; recommended default order in `tasks.md`). A round = (1) expand the point into a full analysis — problem, evidence (verified live, not assumed), options, recommendation, effort (S/M/L/XL), blast radius; (2) maintainer disposition — **admit** (scaffold child spec at next free NNN via `/sdd new`, move the analysis into its `spec.md`), **kill** (record rationale in this umbrella's `notes.md`), or **debate** (decision-type points: run the decision-grade flow before admission); (3) check the point's box in `tasks.md` with the disposition inline. Each admitted child then lives its own normal SDD life (refine/plan/tasks) independent of this umbrella.

Sequencing constraints honored during rounds: P2 (lab vs asset) gates the *worth* of P3/P4/P6 — if those are detailed before P2 is decided, their recommendation must be expressed conditionally on P2's outcome. P3 must pass a decision-grade debate (it contradicts standing multi-runtime doctrine). Every admitted child answers the governance admission checklist in its own spec (layer, own/instrument/ignore, evidence, why existing mechanism is insufficient, runtime assumptions, sync surface, advisory-vs-blocking posture).

## Files to touch

**Create:**
- `docs/specs/<NNN>-<child-slug>/` — one per admitted point, at admission time (next free NNN; slugs proposed per round).

**Modify:**
- `docs/specs/185-harness-evolution-program/tasks.md` — disposition checklist, updated per round.
- `docs/specs/185-harness-evolution-program/notes.md` — kill rationales, decisions, cross-point findings.
- `.agent0/HANDOFF.md` — program state across sessions.

**Delete:**
- Nothing.

## Alternatives considered

### One mega-spec implementing all 8 points

Rejected: the points have different natures (mechanical fix vs strategic decision vs doctrine reversal), different gates, and at least two are likely kills-or-defers after analysis. A single spec would force a single status onto a portfolio and bury decisions inside implementation noise.

### Eight specs opened immediately, no umbrella

Rejected: opens 8 in-flight specs before any analysis — exactly the zombie-spec pattern the corpus audit flagged (specs 091/171). Lazy admission keeps `/sdd list --in-flight` honest: only points that survive detailing become specs.

### Track in HANDOFF.md only, no spec

Rejected: HANDOFF.md is session-scoped working state, rewritten constantly; an 8-point program with decisions and rationale needs a durable, addressable artifact. `docs/specs/` is git-tracked project memory and does not ship to consumers — the right register for internal strategy.
