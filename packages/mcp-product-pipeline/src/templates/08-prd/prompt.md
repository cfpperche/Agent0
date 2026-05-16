---
mode: draft-after-input
delegable: partial
delegation_hint: "draft the PRD synthesising step 1 + step 3 spec + step 4 audit + step 7 prototype-v2; parent must collect 2 inputs from user first (priority cut + success metric); user-story IDs follow US-NN convention (consumed by step 13 PRD-coverage scoring)"
---

# Step 8 — PRD (Product Requirements Document)

**Goal:** the canonical product spec — what's in v1, what's out, what success looks like, with **stable user-story IDs (`US-NN`)** that step 13 (prototype-v3) consumes for PRD-coverage scoring. The PRD is the contract engineering (step 9 system-design) and downstream execution (`/sdd new` post-handoff) consume. **First step of Specification phase.**

**Mode:** `draft-after-input` with `delegable: partial`. The parent must extract two pieces of input that no prior artifact captured — **feature priority cut** (must-have vs should-have vs nice-to-have for v1) and **success metric** (the single primary observable that says v1 worked). Once those are locked, the document writing delegates to a sub-agent. The priority and metric are founder calls; the synthesis is mechanical.

**Output file:** `prd.md` in `docs/product/08-prd/`. Single-artifact.

---

## How to conduct this step

Read `references/prd-format.md` for the US-NN ID convention + canonical section shapes (anti-patterns inline). Read `references/scope-cut-discipline.md` for the must/should/nice triage rules (when a P0 should be P1, when "should" is the cowardly version of "no").

### 1. Read everything prior

- **Concept brief** — `docs/product/01-ideation/04-concept-brief.md`. Product name, JTBD, persona, scale class, validation mode.
- **Functional spec** — `docs/product/03-spec/functional-spec.md`. Pages + components + interactions + states. The PRD's user stories should map 1:1 to spec surfaces.
- **UX audit** — `docs/product/04-ux-testing/validation-report.md`. Heuristic findings + WCAG findings + verdict + post-launch signal. **Read the YAML frontmatter if present.** Findings tagged `fix_skill_hint: "deferred"` flow into the PRD as Backlog items; findings already actioned at step 6/7 may surface as P0 acceptance criteria.
- **Prototype-v2** — `docs/product/07-prototype-v2/`. The screen list + REPORT.md § Screen-by-Screen is the surface inventory. Every PRD user story should be reachable from a step-7 screen filename (or flagged as a v1 gap that needs a new screen).
- **Brand book** (step 5) + **design system** (step 6) — voice + tokens are downstream constraints; the PRD references their existence and inherits their decisions, doesn't re-litigate.

If any prior artifact is missing/thin, stop and report to the parent — the PRD is synthesis, not invention.

### 2. Parent collects priority + metric (2 questions, ~3 min)

The parent MUST conduct this exchange directly with the user — not delegate. Two questions, sometimes a third:

1. **Priority cut.** Walk through the spec's feature list (or the prototype-v2 screen list — whichever is sharper for the founder). For each, ask: **must-have for v1 / should-have / nice-to-have / explicit non-goal?** Force the cut. If everything is must-have, the v1 is too big — push back until the founder makes a real cut.

2. **Primary success metric.** Ask: *"What's the single observable metric that says v1 worked? Pick ONE — not three."* Examples by product class:
   - **B2B SaaS:** week-1 activation rate, time-to-first-delegation, paid conversion, weekly active teams
   - **Marketplace:** matched transactions in month 1, GMV per active user, time-to-first-match
   - **Dev tool / CLI:** weekly downloads after launch, week-2 retention, in-product star/feedback ratio
   - **Consumer app:** day-7 retention, daily active sessions, organic install rate
   - **Custom:** founder-defined, must be observable + bounded in time + has a numerical target

3. **(Optional) Launch timeline** — soft target (this week / month / quarter)? Shapes what's actually in v1 vs deferred. Ask only when the founder seems uncertain; skip when the brief or spec already names a target.

**Why ONE metric, not "at least 2":** two equal-priority metrics produce optimization conflicts (one team optimizes activation, another optimizes retention, the trade-offs aren't surfaced honestly). A PRD with ONE primary metric + 0-N supporting observability metrics (read-only, no trade-off decisions tied to them) is the discipline that survives execution. Anti-pattern: "We're optimizing for retention AND activation AND revenue" — name your tier, then add the others as observability.

### 3. Drafting delegates to a sub-agent

Once priority + metric are locked, the parent calls `product_get_delegation_brief(8)` and dispatches an `Agent` sub-agent with the 5-field brief. CONTEXT includes:

- All 5 prior-artifact paths (steps 1, 3, 4, 5, 6, 7)
- The captured priority cut (verbatim from § 2 — list every feature with its assigned tier)
- The captured primary metric (verbatim, with target value + measurement window)
- The optional timeline if collected
- Confirmation that step 4's frontmatter (if present) was parsed and the `fix_skill_hint: "deferred"` findings are routed into the Backlog

The sub-agent's job is structural synthesis — fill the canonical PRD template using the captured inputs + the prior-artifact reads. No more user questions; the parent's interview was the last step needing the founder.

Use `model: opus` for the sub-agent — sonnet sometimes drops the US-NN ID discipline on a 30+ user-story PRD.

### 4. The canonical PRD template

The sub-agent writes `prd.md` against this section spine (full shape with depth conventions lives in `references/prd-format.md`):

1. **Problem statement** — concrete user pain with evidence from step 1 or step 4. Specific quote / metric / observed behavior, not "the experience could be better".
2. **Target users** — recap the persona from step 1 with any refinement step 4 audit suggested.
3. **Goals** — 3-5 outcome-oriented bullets (not output-oriented). "User triages a sprint in under 5 minutes" beats "Build a triage view".
4. **Non-goals** — explicit out-of-scope, one-line reason each. Prevents scope creep during execution.
5. **User stories** — every story carries a **stable `US-NN` ID** (zero-padded, sequential — `US-01`, `US-02`, ..., `US-29`). Format: `**US-NN.** As a <role>, I want <action> so that <benefit>.` IDs survive across PRD revisions — when adding a new story mid-life, append to the end (don't renumber existing IDs); when removing, leave the ID with a `~~`-strikethrough + removal note. **The US-NN IDs are consumed by step 13's PRD-coverage scoring — stability matters.**
6. **Requirements** — three priority tiers (P0 / P1 / P2) + Backlog, each as a markdown table with `# | Requirement | Acceptance Criteria | Source`. The `Source` column links to the originating user story (`US-NN`), spec section (`spec § <name>`), prototype screen (`prototype-v2 screens/<NN>-<name>.html`), or audit finding (`step 4 F-NN`).
7. **Success metrics** — ONE primary metric table row carrying baseline + target + measurement window. Optional supporting observability metrics (clearly labeled as "observability, not optimization target") in a separate sub-table.
8. **Acceptance criteria per user story** — BDD scenarios (Given/When/Then) for every P0-routed user story. 2-4 scenarios per story typically; reference the screen filename when behavior is screen-specific.
9. **Technical considerations** — feasibility flags, dependencies on external services, integration constraints. NOT implementation; that's step 9 system-design.
10. **Open questions** — what's not yet decided. Each has an owner OR a downstream step number where it'll resolve (`step 9 — Q1`, `step 10 — Q2`, etc).
11. **Backlog** — low-priority items, post-v1 candidates, step-4 audit findings tagged `fix_skill_hint: "deferred"`. Single table: `# | Title | Source | Why deferred`.

### 4.5. Spec-decision inline resolution (don't dump open questions forward)

If step 3's `functional-spec.md` carries a `## Decisions Pending` or `## Open Questions` section, the PRD's job is to RESOLVE those inline — not defer everything to step 8's own Open Questions. For each spec decision:

1. **Founder-locked in § 2 interview** — apply the founder's call; resolve inline with a one-line citation (`Source: founder · 2026-05-16`); the decision lands as a requirement in the appropriate priority tier OR as a non-goal.
2. **Default applies** — if the spec offers a `Default if unresolved` value AND the founder didn't override during the interview, apply the default; resolve inline with `Source: spec § Decisions Pending — default applied`.
3. **Genuinely open** — only items neither founder nor spec-default resolved survive into step 8's `## Open Questions` section. These carry an owner OR a downstream step number.

The MCP-port discipline restores anthill's Step 2c "resolve inline, don't defer" pattern that the step-7 blind judge surfaced as a real Agent0 weakness in the v1 port (judge dogfood 2026-05-16). Dumping all spec questions into the PRD's `## Open Questions` is the regression mode — it converts the PRD from "the v1 contract" into "a list of things we still need to decide", which reads as half-shipped.

### 5. Step-4 audit-findings consumption (mirror step 6/7 pattern)

The Identity-phase audit's `## Audit Response` pattern carries over here at the Specification-phase. Parse step 4's frontmatter (if present):

- **`fix_skill_hint: "design-system"` findings** — already actioned at step 6. The PRD acknowledges them in the Backlog with `Source: step 4 F-NN (resolved at step 6)` so the audit trail is visible end-to-end.
- **`fix_skill_hint: "prototype-v2"` findings** — already actioned at step 7. Same treatment in Backlog with `(resolved at step 7)`.
- **`fix_skill_hint: "deferred"` findings** — land in Backlog with `Source: step 4 F-NN` and a one-line "why deferred" (cosmetic / AAA-only / post-v1 / waiting on Q).
- **Frontmatter absent but `## Priority Recommendations` table present with explicit routing** (prose-routed audit — common when audit was hand-written or pre-dates the step-4 frontmatter port). Parse the table for rows tagged "Step-7 critical" / "Step-6 critical" / "Pre-gate" / "Defer" / explicit step-NN references. Treat the prose-routed routing as if `fix_skill_hint` had been set per the table's column; route findings into the PRD identically (P0 / Backlog-resolved-at-step-N / Backlog-deferred). Do NOT emit the projected-mode empty-state line — that would misrepresent a measurable audit and silently drop the prose-routed handoff. Mirror the prose-routed branch step 6's `audit-response.md` documents for design-system tokens; step 8 inherits the same discipline at the PRD layer.
- **No frontmatter AND no prose routing (truly projected mode)** — emit the explicit empty-state line in Backlog: *"Step 4 ran in projected mode — no structured findings to ingest, no prose routing in § Priority Recommendations. Backlog seeded from prototype-v2 deviations + open spec questions only."*

The PRD is the FIRST artifact that crosses the Identity → Specification boundary. The audit trail visibility is the load-bearing thing — a reader of the PRD should see what came from step 4 explicitly, not have to cross-reference manually.

### 6. Calibrate by product class (smart, not rigid)

The full template (§ 4) is the **v1 product PRD** default — what a SMB SaaS or marketplace deserves. Calibrate down for smaller scopes:

| Product class (concept brief § Identity · Scale) | PRD depth | Sections to keep / cut |
|---|---|---|
| **Micro-Product / CLI helper / single-purpose tool** | Compact | Keep 1, 4, 5 (1-3 stories), 6 (P0 only, no P1/P2 unless real), 7, 11. Cut 2 (persona inline in 1), 3 (1-2 goals), 8 (1-2 scenarios per story), 9 (optional, only if non-trivial deps), 10 (often empty) |
| **Mobile App (focused, 1 persona)** | Standard | Full structure; P2 tier likely small (3-5 items max) |
| **Developer Tool / API-first** | Standard | Full structure; technical-considerations § grows (rate-limit posture, SLA assumptions, versioning) |
| **SMB SaaS (the spec 026 default)** | Full | Full structure; expect 10-20 user stories, P0 5-10, P1 3-7, P2 3-5, Backlog 5-15 |
| **Venture-Scale / Marketplace / multi-persona** | Expanded | Full structure + per-persona § Target users sub-blocks; expect 20-40 user stories; success-metrics table may carry one primary + 2-3 observability per persona |

Brief field missing or ambiguous → default to **SMB SaaS (Full)**. Mark the chosen depth in `## Problem Statement` opening sentence ("v1 PRD for an SMB SaaS — full template depth applied.").

### 7. Submit + advance

Call `product_step_submit` with:
- `step: 8`
- `filename: "prd.md"`
- `content: <full PRD>`

No `extra_files` — single-artifact step.

Schema enforces section presence + the `US-NN` table substring (Layer 1 contains check on the literal pipe-delimited row that proves the user-story ID column shape exists). On success, `product_advance` moves to step 9 (system-design — pure synthesis, fully delegable; opens with the PRD as its primary input).

**No gate at step 8.** Step 7 closed the Identity gate; the next gate is at step 12 (closing Specification). Steps 8-11 advance fluidly through Specification phase.

---

## Voice & rigor

- **Cut hard.** PRDs that list 30 must-haves don't ship. 5-10 P0s with a thesis is shippable. The parent's interview at § 2 must produce a real cut — pushback on "everything is must-have" is part of the discipline.
- **US-NN IDs are stable.** They survive revisions; they cross-reference step 13. A PRD that renumbers user stories mid-life breaks coverage scoring downstream. Append, don't renumber.
- **Acceptance criteria are observable behaviors, not implementation details.** "User can mark task done" is implementation; "When user clicks `Done` on a task in dashboard, the task disappears from active list and appears in `Completed` with a timestamp" is acceptance.
- **ONE primary success metric.** Two = no metric (every team optimizes the easier one). Pick ONE; supporting observability metrics are read-only, not optimization targets.
- **Backlog is the audit trail.** Step 4 findings that didn't make v1 + step-7 deviations + spec open questions ALL land here with `Source` traceability. Without the Backlog, the v1 cut feels arbitrary; with it, every "no for v1" is documented.
- **Step 4 frontmatter routes findings INTO the PRD** the way step 6 routed them into tokens and step 7 routed them into renders. The PRD is where the Specification-phase first reads the audit and decides which findings became code, which are deferred, which are P0 for engineering.

## What this step does NOT do

- **Architecture / stack decisions.** Step 9 system-design owns these; step 8 only flags feasibility concerns as Technical Considerations + Open Questions.
- **Pricing / cost modeling.** Step 10 cost-estimate.
- **Release sequencing within v1.** Step 11 roadmap if v1 ships in stages; otherwise the PRD is monolithic.
- **Marketing positioning / launch strategy.** Step 17 GTM (future MCP).
- **Engineering specs / task decomposition.** That's the `/sdd new <feature>` post-pipeline phase.

## What this step replaces

Step 8 ports `anthill-prd` (222 LOC SKILL.md + 3 references = 291 LOC total in anthill). The MCP port keeps the structural template (Problem / Goals / Non-Goals / User Stories / Requirements P0-P2 / Success Metrics / Acceptance / Technical / Open Questions / Backlog) and inherits anthill's discipline (cut hard, evidence-based problem statements, acceptance-criteria-per-requirement). It diverges on three points worth naming:

1. **US-NN stable IDs** — anthill's user stories are unnumbered "As a / I want / So that" prose lines; the MCP port adds zero-padded sequential IDs that step 13's PRD-coverage scoring consumes. Stability discipline (append-don't-renumber) is the load-bearing new convention.
2. **Step-4 audit-findings consumption** — anthill had no concept of structured audit handoff; the MCP port mirrors steps 6/7 — parse step 4's frontmatter, route findings into the Backlog (or acknowledge resolved ones), document the audit trail in `Source` columns.
3. **ONE primary success metric (not "at least 2")** — anthill's checklist + anti-patterns mandate "At least 2 measurable outcomes". The MCP port reverses this: ONE primary metric is the gate; supporting observability metrics are optional and clearly labeled as non-optimization targets. The reversal is empirically grounded — two equal-priority metrics produce optimization conflicts that mask which one v1 is really betting on.

Anthill's `.anthill/issues/issue-*.md` ingestion + `## Decisions Pending` ingest from spec.md are not ported — those are runtime scaffolding specific to anthill's workspace conventions. The MCP analog is step 4's YAML frontmatter + step 3 spec's `## Open questions` section (when present); the consumption pattern is documented in § 5 above.
