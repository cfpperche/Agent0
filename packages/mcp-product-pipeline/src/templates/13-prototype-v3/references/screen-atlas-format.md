# Screen atlas format — the visual-contract document shape

The `screen-atlas.md` file produced by step 13 is the navigable index that engineering opens when starting `/sdd new <slug>`. This page documents the canonical section shape, per-section depth conventions, and the discipline that separates a real visual-contract atlas from a re-summarized PRD.

## Why the atlas is a distinct artifact (not a PRD re-summary)

The PRD (step 8) is the depth source — every user-story, every acceptance criterion, every priority decision lives there. The atlas is the **navigation layer** over the PRD: it indexes which screens cover which user-stories, scores design fidelity per screen, surfaces state-coverage gaps, walks the killer flow as a narrative. A reader holding the PRD + the atlas + the screens has the full visual contract; a reader holding only the atlas should be able to navigate to the screens AND verify PRD coverage without re-reading the PRD's depth.

The atlas's job is **handoff to engineering, not handoff to design**. Step 7 (prototype-v2) handed off to engineering for Identity-phase signoff; step 13 hands off for the full execution. Engineering reads the atlas to discover what to build; the atlas's matrices + walkthroughs replace the typical "engineering reads the PRD and infers what to build" failure mode.

## The 8 required sections — per-section depth conventions

### `## Overview`

Short paragraph + 3 load-bearing one-liners. Mirrors step-9 / 10 / 11 / 12 § Overview shape. Format:

```markdown
## Overview

**v1 screen atlas for an SMB SaaS — N=8 screens covering 12 PRD user-stories (10 covered, 2 deferred to Phase 3 per step-11 § Phases).** This atlas is the visual contract handed to `/sdd new octant` for engineering execution. Picked visual direction: "Operador Silencioso" (step 7 § Run Summary; step 2 § Direction A). Design system: step 6 `tokens.css` v1 (catalog path — Linear-anchored hairline restraint with cobalt accent). Brand voice: step 5 § Voice samples — direct, no hand-holding, slight smirk.

**PRD coverage:** 10/12 user-stories rendered as screens; 2 deferred (US-18 multi-project view, US-22 admin role) with reasons in § PRD Coverage.

**Visual lineage:** step 7 picked direction "Operador Silencioso" + step 6 tokens.css inline-copied verbatim per screen + step 5 § Voice § Direct posture applied to every user-facing string.

**Deciding signal for engineering handoff:** Hold `/sdd new <slug>` if any P0 US-NN is uncovered in the matrix below; otherwise the contract is locked. Open the atlas + 3 sample screens; if the killer-flow walkthrough (§ User Flow) reproduces in <5 minutes, the contract is engineering-ready.
```

The 3 one-liners are NOT decorative — they answer the three questions every engineering reader asks at the atlas's first sentence: "is the PRD covered?" / "what does it look like?" / "is it ready for me to build?".

### `## Screens Index`

The visual-contract's table-of-contents. Markdown table:

```markdown
## Screens Index

| # | Screen | Covers (US-NN) | Extends | Concern |
|---|---|---|---|---|
| 01 | `screens/01-landing.html` | — (marketing) | step 7 — | [product] [design] |
| 02 | `screens/02-signup.html` | US-01 | step 7 screens/01-signup.html | [product+engineering] |
| 03 | `screens/03-onboarding.html` | US-03 | step 7 screens/02-onboarding.html | [product+engineering] |
| 04 | `screens/04-dashboard.html` | US-04, US-06 | step 7 screens/03-dashboard.html | [product+engineering] |
| 05 | `screens/05-killer-flow.html` | US-07, US-19 | step 7 screens/05-triage-view.html (F-12 + F-13 resolved at v2; F-22 closed inline at v3) | [product+engineering] |
| 06 | `screens/06-detail-view.html` | US-12 | net-new at step 13 | [product+engineering] |
| 07 | `screens/07-settings.html` | US-20 | step 7 screens/07-settings.html | [product+engineering] |
| 08 | `screens/08-empty-error-consent.html` | US-22 (deferred) + legal-consent surface | net-new at step 13 | [product] [counsel-review] |
```

**Concern tags** inherit the step-11 + step-12 allow-list: `[engineering]` / `[product+engineering]` / `[product]` / `[design]` / `[founder]` / `[counsel-review]`. Optional — omit when single-discipline.

**The Extends column** is the lineage anchor. Three valid values:
- `step 7 screens/<NN>-<name>.html` — screen re-rendered from step 7 with v3 extensions (audit-fix application, state coverage completion, US-NN re-mapping).
- `step 7 — (no source)` — when the step-7 screen has no direct lineage but the atlas extends from step-7's visual conventions (typical for `01-landing` which is often marketing-pass).
- `net-new at step 13` — screens that step 7 did NOT render (typical for legal-consent surfaces, edge-state combinations, P1 supporting surfaces step 7 deferred).

### `## PRD Coverage`

The load-bearing scorecard. Markdown table with one row per US-NN from step 8 PRD:

```markdown
## PRD Coverage

| US-NN | Title (short) | Priority | Screen(s) | Acceptance Source | Status |
|---|---|---|---|---|---|
| US-01 | Sign up via email/Google | P0 | `screens/02-signup.html` | PRD § AC US-01 | covered |
| US-03 | Import Jira in <2 min | P0 | `screens/03-onboarding.html` | PRD § AC US-03 | covered |
| US-04 | Land in workspace dashboard | P0 | `screens/04-dashboard.html` | PRD § AC US-04 | covered |
| US-07 | Keyboard-first triage | P0 | `screens/05-killer-flow.html` | PRD § AC US-07; F-12 resolved at screen 05 | covered |
| US-12 | Detail view with sidebar | P1 | `screens/06-detail-view.html` | PRD § AC US-12 | covered |
| US-18 | Multi-project view | P2 | — | — | deferred — Phase 3 per step-11 roadmap |
| US-19 | Bulk-action confirmation | P0 | `screens/05-killer-flow.html` | PRD § AC US-19; F-13 resolved at screen 05 | covered |
| US-20 | Account settings + billing | P1 | `screens/07-settings.html` | PRD § AC US-20 | covered |
| US-22 | Admin role management | P2 | `screens/08-...` (partial; admin-toggle visible but full surface deferred) | PRD § AC US-22 | deferred — admin-flow needs design partner #2's feedback |

**## PRD coverage: 10/12** (10 covered, 2 deferred — US-18 to Phase 3, US-22 pending design-partner feedback)
```

**Discipline:** every `US-NN` from step 8 PRD appears here, OR carries an explicit "deferred — reason" status. Silent omission is the regression mode the schema's `| US-NN |` literal-anchor catches at structure level, but the per-row discipline catches at content level.

The **Status column** values: `covered` / `deferred — <reason>` / `partial — <screen carries part>`. NOT `n/a` or `tbd` (those leak the founder's indecision to engineering).

The section closes with the `## PRD coverage: X/Y` summary line. The exact phrasing — H3-style with the score — IS the substring REPORT.md § PRD Coverage cross-references.

### `## Design Fidelity`

Per-screen 5-dim scoring table. Same dimensions as step 7 (Token / Voice / Component / Audit-fix / Specificity / Min). Format:

```markdown
## Design Fidelity

| Screen | Token | Voice | Component | Audit-fix | Specificity | Min |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 01-landing | 5 | 5 | 4 | n/a | 5 | 4 ✓ |
| 02-signup | 5 | 5 | 5 | 5 | 4 | 4 ✓ |
| 03-onboarding | 4 | 4 | 5 | 5 | 4 | 4 ✓ |
| 04-dashboard | 5 | 5 | 5 | 4 | 5 | 4 ✓ |
| 05-killer-flow | 5 | 5 | 5 | 5 | 5 | 5 ✓ |
| 06-detail-view | 4 | 4 | 4 | n/a | 4 | 4 ✓ |
| 07-settings | 5 | 5 | 4 | n/a | 4 | 4 ✓ |
| 08-empty-error-consent | 4 | 5 | 4 | 4 | 5 | 4 ✓ |
```

The Min column carries the gate indicator (✓ if ≥ 3 across all five dims). Any score < 3 should have been fixed in a pre-emit pass — if it lands in the final atlas, the deviation gets a one-liner in REPORT.md § Recommendations.

`n/a` is valid for the Audit-fix column when no step-4 finding routes to that screen.

### `## States Coverage`

Matrix table cross-cutting screens × states. Format:

```markdown
## States Coverage

| Screen | [Loading] | [Empty] | [Error] | [Disabled] | [Success] |
|---|:---:|:---:|:---:|:---:|:---:|
| 01-landing | — | — | — | — | — |
| 02-signup | ✓ | — | ✓ | ✓ | ✓ |
| 03-onboarding | ✓ | ✓ | ✓ | — | ✓ |
| 04-dashboard | ✓ | ✓ | ✓ | — | ✓ |
| 05-killer-flow | ✓ | ✓ | ✓ | ✓ | ✓ |
| 06-detail-view | ✓ | [gap] | ✓ | — | ✓ |
| 07-settings | ✓ | — | ✓ | ✓ | ✓ |
| 08-empty-error-consent | ✓ | ✓ | ✓ | ✓ | ✓ |
```

Cell content semantics:
- **✓** — state is rendered in the screen (HTML comment section or inline label visible)
- **—** — state is N/A for that screen (e.g., a landing page has no Empty state)
- **`[gap]`** — screen needs the state but step 13 didn't render it; escalated to engineering OR back-flagged to step 6 `components.md`

`[gap]` cells generate a one-line row in REPORT.md § Recommendations (e.g., "Recommendation 3: screen `06-detail-view.html` is missing the Empty state; engineering or step-6 step-back to fill the gap").

The literal column headers (`[Loading]`, `[Empty]`, `[Error]`, `[Disabled]`, `[Success]`) — note the bracket form — are the load-bearing substrings the schema enforces (the bracket anchors prevent silent dropping into prose). Cosmetic variants (`Empty State`, `Error states`, etc.) do NOT satisfy the schema check — the canonical bracketed form is required.

### `## User Flow`

Narrative walkthrough anchored to a real persona. NOT a re-summary of every PRD acceptance criterion — a single end-to-end session traced through the screens. Format:

```markdown
## User Flow — the killer flow

**Persona:** Engineering Manager at a 5-30 person squad. Coming from Jira; needs to triage a 25-issue sprint in under 5 minutes.

A new manager opens `screens/02-signup.html`, signs up via Google OAuth in <30 seconds, lands at `screens/03-onboarding.html`. The onboarding wizard offers Jira import; she pastes her Jira workspace URL, authorizes the OAuth, watches the import progress bar complete in 90 seconds (US-03 acceptance). She lands at `screens/04-dashboard.html` — 25 imported issues visible, sorted by stale-cycle-time, color-coded by priority (US-04, US-06 acceptance).

She presses `t` to enter triage mode → `screens/05-killer-flow.html`. The first untriaged issue presents full-screen with keyboard hints visible at the bottom (US-07 acceptance). She presses `1` for priority-high → `a` to assign to herself → next issue auto-loads within 100ms. After 12 issues, she bulk-selects the remaining 13 (US-19 acceptance), presses `b` to confirm bulk-action — the confirmation modal appears (F-13 resolved inline at screen 05; was the audit's bulk-action-without-confirmation finding from step 4), she confirms, all 13 issues triaged. The triage-mode-complete summary surfaces: 25 issues, 4 minutes 12 seconds, cycle-time-stat 4.5 days.

**Closed-beta partner #1 navigates the atlas unassisted and reproduces this killer flow in <5 minutes.** This is the v1 acceptance — if the walkthrough fails for the first design partner, the atlas is not engineering-ready. The contract is the named-human signoff, not CI passing.
```

**Real-human acceptance** is mandatory — the literal `Closed-beta partner` substring is the schema-enforced anchor. The canonical phrasing is `Closed-beta partner #N navigates the atlas unassisted and reproduces the killer flow in <5 minutes`; cosmetic variants (`closed-beta partner #2`, `Closed-beta partner #1 walks the atlas`) all carry the literal substring.

When the killer flow spans ≥4 distinct actions, format as sub-bulleted list under the bold persona-name introduction (inherits step-11 + step-12 sub-bullet discipline). When 1-3 actions, prose-paragraph is fine.

### `## Open Decisions`

Decisions the atlas surfaces for `/sdd new <slug>` to resolve. Inherits step-9 / 10 / 11 / 12 § Open Decisions discipline. Format:

```markdown
## Open Decisions

| # | Decision | Default if no decision by | Deciding signal | Concern |
|---|---|---|---|---|
| 1 | Screen 08 — combine empty+error+consent OR split into 3 screens | first /sdd planning session | If engineering's component library has separate Empty / Error / Modal patterns, split; if shared shell, keep combined | [engineering] [product] |
| 2 | Legal-consent copy is the literal text shipped vs a placeholder for counsel review | before /sdd new <slug> fires | Counsel email approving the literal copy in screens/08; default placeholder until then | [counsel-review] [product] |
| 3 | Mobile-responsive variants of killer-flow screens (US-07) | end of Phase 2 per step-11 roadmap | If closed-beta partner #1 requests mobile in the first sprint, fold into Phase 2; otherwise defer to v2 | [design] [engineering] |
```

2-5 rows is the target. **NOT every decision** — just the ones the atlas is parked on for engineering handoff. Each row has a deciding signal that closes the deferral.

### `## v2-Vision`

3-5 bullets sketching post-v1 screen evolution. Mirrors step-11 § v2-Vision shape at the atlas layer. Format:

```markdown
## v2-Vision

- **Public sharing surface (3 months post-launch).** v1 atlas does NOT include a share-issue surface; the killer flow is internal triage. Drives v1 atlas decision: every URL is workspace-scoped, no public share tokens designed.
- **Mobile companion (6 months post-launch, deferred).** Atlas screens are desktop-first per concept brief § Identity. Drives v1 atlas decision: skip mobile-responsive polish in screen 05 (saves ~1 screen of variance).
- **AI-assisted triage suggestion (4-5 months post-launch).** v1 keyboard-first triage produces the training corpus. Drives v1 atlas decision: log triage actions with intent (not just side-effect) in PostHog — atlas does NOT render the suggestion UI but the data-collection contract is shipped.
```

3-5 bullets, NOT a v2 plan. Each bullet has a "drives v1 atlas decision" clause that names what v1 should design FOR or AGAINST.

## Audit response handling (when step 4 findings landed at step 13)

When step-4 frontmatter `findings[]` carries `fix_skill_hint: "prototype-v3"` OR `fix_skill_hint: "prototype-v2"` with `status: open` (i.e., step 7 deferred), step 13 closes them inline + documents in either:
- atlas `## Audit Response` (optional H2, fires when ≥3 findings land at step 13)
- REPORT.md `## Run Summary` (inline when ≤2 findings)

Per-finding documentation per `07-prototype-v2/references/audit-response.md` shape. The `<!-- fix(F-NN): applied at step 13 — reason: ... -->` HTML comment is the in-source audit trail at the screen.

## Token-gap handling

When a screen needs a token step 6 didn't define, atlas § Open Decisions row OR REPORT.md § Recommendations row carries a back-flag to step 6 (e.g., "Recommendation 5: step 6 to add `--shadow-modal` token; screen `06-detail-view.html` needed hard-edge dialog elevation"). Do NOT invent tokens inline; the inline-invent failure mode breaks the cross-step traceability discipline. See `07-prototype-v2/references/token-mapping.md` § When a screen needs a token step 6 didn't define.
