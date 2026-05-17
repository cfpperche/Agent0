# Phasing discipline — slice = end-to-end user value, per-phase exit criteria, risk + buffer calibration

How to phase v1 in `roadmap.md`. The load-bearing disciplines from anthill-roadmap + the calibration rules that make phasing smart, not rigid.

## Slice = end-to-end user value (Shape Up style)

Each phase delivers ONE end-to-end slice of user value — backend + frontend + tests for ONE complete user flow. NOT a horizontal layer.

### Anti-pattern: horizontal layering

```markdown
## Phase 1 — Backend (Weeks 1-6)
- All API endpoints
- All database tables
- All auth

## Phase 2 — Frontend (Weeks 7-12)
- All screens
- All state management
- All forms

## Phase 3 — Tests (Weeks 13-14)
- Test suite
- Manual QA
```

This is the regression mode. User value lands ONLY at end of Phase 2 (12 weeks in); Phase 3 finds bugs that backend-and-frontend integration would have surfaced 6 weeks earlier. The roadmap optimised for "feature complete" instead of "user value flowing".

### Canonical shape: vertical slicing

```markdown
## Phase 1 — Foundation (Weeks 1-4)
**Goal:** A user can sign up, create a workspace, see an empty dashboard on staging.
(Auth + data model + deploy pipeline + observability floor; no user-visible product features yet.)

## Phase 2 — Killer Flow (Weeks 5-8)
**Goal:** Keyboard-first triage (US-07) walks end-to-end: user creates an issue, triages with `j/k/x/y` keys, sees it land in the right swimlane.
(Issue CRUD + triage state machine + keyboard shortcuts + UI for triage view + tests for the flow.)

## Phase 3 — Surrounding (Weeks 9-12)
**Goal:** Bulk action (US-19) + Stripe checkout (US-05) shipped behind feature flag.
(Surrounding P0 features; each ships end-to-end before the next starts.)

## Phase 4 — Polish + Launch (Weeks 13-14)
**Goal:** Closed-beta launchable. Accessibility audit clean; error states wired; onboarding flow exists.
```

Each phase ships USER-OBSERVABLE BEHAVIOR. Phase 1's "empty dashboard" is observable (user can navigate to it); Phase 2's keyboard triage is observable (user can demo it to a non-engineer in <5 min).

### When horizontal layering is OK

Foundation phase is the one exception. Auth, data model, deploy pipeline, observability — these are infrastructure that has no user-visible flow by definition. But Foundation should ship A user-visible artifact (the empty dashboard above), even if the artifact is hollow. The artifact proves the infrastructure works.

## Per-phase exit criteria

Every phase has explicit exit criteria. Without them, the phase is "done when we say it's done" — discipline gap.

### Exit criteria are testable

```markdown
**Exit criteria:** A user can sign up via `/signup`, land on `/workspace/<id>`, see the empty issue list. Sentry captures errors; PostHog captures pageview events. Two engineers have run through the flow on staging without manual intervention.
```

The criteria are testable — a reviewer can verify each clause empirically. NOT testable:

- "Foundation phase complete" (circular)
- "Auth works" (works how? for what flow?)
- "Backend deployed" (deployed to where? doing what?)

### Exit criteria reference PRD stories

Where possible, exit criteria reference the PRD user-story IDs (US-NN) that the phase satisfies:

```markdown
**Exit criteria:** US-07 (keyboard triage) and US-19 (bulk action) both walk end-to-end on staging. Demo recording exists (<5 min, no narration). 3 design partners have walked through both flows without facilitator intervention.
```

This closes the trace — exit criteria → PRD story → audit trail.

### Exit criteria are observable, not procedural

Anti-pattern: "Sprint 3 done" / "75% of tasks complete" / "all tickets closed" / "feature flag flipped".

Canonical: "A user can <do thing>" / "<artifact> exists at <path>" / "<metric> measures <value> on <env>".

The criterion's job is to be a contract the team agrees on BEFORE the phase starts. Procedural criteria let scope creep; observable criteria force scope to lock.

## Dependency DAG (no circular deps)

Phase-to-phase dependencies are explicit AND acyclic. Draw the graph; verify it's a DAG.

### Canonical shape

```
Phase 1 (Foundation) → Phase 2 (Killer Flow) → Phase 3 (Surrounding) → Phase 4 (Polish + Launch)
                                  ↘ Phase 2.5 (Stripe integration, parallel weeks 6-8)
```

The diagram lives in `## Dependencies` as a code-fence block when ≥3 phases. Below the diagram, enumerate non-obvious edges:

```markdown
- Phase 2 depends on Phase 1 (auth + data model are prerequisites for issue CRUD)
- Phase 3 depends on Phase 2 (Stripe checkout depends on workspace creation which depends on auth)
- Phase 2.5 (Stripe Activate onboarding) runs in parallel weeks 6-8; can complete before Phase 2 ends
```

### Anti-pattern: circular dependencies

```
Phase 1 → Phase 2 → Phase 3 → Phase 1 (??)
```

Always a discipline gap — re-decompose. Usually means one of the phases is mis-scoped (Phase 3 should be split, or Phase 1 should expand to absorb the cycle source).

### Parallel work streams

Identify independent phases that CAN overlap (Phase 2.5 above). Some constraints:

- **Solo founder:** parallelism is impossible (one person, one phase at a time). Buffer the elapsed weeks accordingly.
- **2-engineer team:** can parallel 2 phases when dependencies allow. The DAG names which phases are truly independent.
- **Larger team:** more parallelism, but coordination overhead grows. A 4-engineer team doesn't ship 4x faster than a 1-engineer team — typically ~2.5x with full parallelism.

## Risk + buffer calibration (NOT flat 30%)

Per-phase: the single biggest unknown + mitigation. Buffer is calibrated per-phase by unknowns-count, NOT flat.

### Risks are SPECIFIC

Anti-pattern: "Schedule slip" / "scope creep" / "team coordination challenges". Useless — every project has these.

Canonical: "Auth0 onboarding may require custom-domain DNS coordination (typical 2-3 day delay)" / "Keyboard-triage UX needs 2-3 iterations against design-partner feedback (week 6-7 risk)" / "Stripe Activate review may take 1-2 weeks (week 6-9 risk window)".

Specific risk = nameable assumption + measurable impact-in-weeks + mitigation playbook.

### Buffer calibration table

```markdown
| Phase | Unknowns count | Buffer | Rationale |
|---|---|---|---|
| 1 Foundation | 1 (auth onboarding) | +10% | Well-understood; 1 vendor unknown |
| 2 Killer Flow | 3 (UX iteration, perf, design-partner feedback) | +25% | User-feedback-driven; highest unknown count |
| 3 Surrounding | 2 (Stripe Activate, bulk-action UX) | +20% | Medium; external dependency lag |
| 4 Polish | 1 (accessibility audit findings) | +10% | Well-understood checklist |
```

Net buffer = weighted average across phases. For a 14-week plan-of-record: 4 × 10% + 4 × 25% + 4 × 20% + 2 × 10% = 0.4 + 1.0 + 0.8 + 0.2 = **2.4 weeks honest buffer**. Plan-of-record = 14 weeks aggressive; realistic line = 16.4 weeks.

### Buffer calibration heuristics

- **Foundation phases:** +10-15% (well-understood; failure modes are known)
- **Killer-flow / UX-iteration phases:** +20-30% (user-feedback unknowns; iteration is the discipline)
- **External-dependency phases:** +15-25% (vendor onboarding lag; mitigate with frontloading)
- **Polish phases:** +5-15% (well-understood checklist; rarely slips except for late-discovery findings)

### Buffer is NOT 30% flat

The anthill-roadmap canonical skeleton said "add 30% to estimates" (flat). This is the magic-number audit-smell — hides which phases have the real risk. The MCP port calibrates per-phase.

### Buffer reporting shape

```markdown
**Buffer:** +10% on Phase 1, +25% on Phase 2, +20% on Phase 3, +10% on Phase 4. Net horizon: 14 weeks plan-of-record + 2.4 weeks buffer = 16.4 weeks honest. The 14-week line is the aggressive commitment; 16.4 weeks is the realistic line. Buffer activates phase-by-phase if the milestone slips by >50% of the phase's allotted weeks.
```

OR as a dedicated `## Buffer` H2 section (when buffer math is dominant — venture-scale projects).

## Owner discipline

Every deliverable in the phase table has exactly ONE owner. NOT "team" / "everyone" / "TBD".

### Single-owner rule

```markdown
| Deliverable | Owner | Status | Source |
|---|---|---|---|
| Postgres schema + migrations | Eng (founder) | not-started | step 9 § Data Model |
| Auth0 integration | Eng (hire) | not-started | step 9 § Integrations |
```

For a 2-engineer team, owner is `Eng (founder)` or `Eng (hire)` — names the human. For a larger team, owner is a role + name (`Eng (Alice)`, `Eng (Bob)`). "Team" / "Engineering" without specificity is the discipline gap — no one is responsible.

### When owner is TBD

If the founder genuinely hasn't decided who owns a deliverable, the roadmap surfaces it in § Open Decisions ("Decision N: Auth0 vs Supabase Auth owner") — NOT in the deliverable table as `TBD`. TBDs in the table are the procrastination mode the discipline catches.

## Product-class phase-count calibration (smart, not rigid)

Mirrors step-9 + step-10 calibration ladder. Phase count scales with product complexity:

| Product class | Phase count | Typical phase names |
|---|---|---|
| **Micro-Product / CLI helper** | 2-3 | Foundation + Build + Ship |
| **Mobile App (1 persona)** | 3-4 | Foundation + Killer Flow + Polish + App-Store-Review |
| **Developer Tool / API-first** | 3-4 | Foundation + API/Core + SDK/Dashboard + Docs/Launch |
| **SMB SaaS (the spec 026 default)** | 4-5 | Foundation + Killer Flow + Surrounding + Polish + Launch |
| **Venture-Scale / Marketplace** | 5-6+ | Foundation + Per-Persona-Onboarding (1-2) + Killer Flow + Marketplace-Bootstrap + Polish + Launch |

Brief field missing or ambiguous → default to **SMB SaaS (4-5 phases)**. Mark the chosen phase count in § Overview opening sentence.

## Anti-patterns the discipline catches

- **Phases without exit criteria** — covered above; observable, testable, traces to PRD stories.
- **Horizontal layering** — Phase 1 backend, Phase 2 frontend. Defeats Shape Up; user value lands at end of Phase 2 only.
- **No owners on deliverables** — covered above; single-owner rule.
- **Circular dependencies** — covered above; DAG validation.
- **Over-planning distant phases** — Phase 4 in week-1 doesn't need the same detail as Phase 1. Sketch later phases; detail current + next.
- **Mixing product and engineering without labels** — label each deliverable's `Source` column with PRD US-NN (product) vs system-design § X (engineering). Closes the trace.
- **Missing risk assessment** — one risk per phase MINIMUM. NOT "at least 2" (anthill anti-patterns.md magic-number); the constraint is "every phase has a named risk + mitigation".
- **Timeline without constraints** — § Horizon names team shape, velocity assumption, hard deadlines, external coordination triggers. Without these the timeline is decorative.
- **Ignoring parallel work streams** — identify the independent phases that can overlap. Solo founders skip this; 2+ engineers MUST identify parallelism opportunities.
