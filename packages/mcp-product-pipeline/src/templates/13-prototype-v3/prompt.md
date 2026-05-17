---
mode: synthesis
delegable: true
delegation_hint: "synthesize step 13 screen-atlas.md + REPORT.md + screens/[0-9]+-*.html bundle from all prior 12 step outputs — PRD user-stories (step 8 US-NN IDs) drive the coverage matrix, design-system tokens (step 6 tokens.css) land verbatim in every screen, brand voice (step 5 brand-book) tunes every user-facing string, step-2 picked direction inherits as visual lineage, step 4 audit findings (fix_skill_hint:prototype-v3 or unresolved-from-v2) close inline; N is product-calibrated per § 4 (Micro 3-5 / Mobile 4-7 / Dev Tool 4-8 / SMB SaaS 6-10 / Venture 10-15); fully delegable — sub-agent reads ALL prior 12 step artifacts and produces the bundle with NO live parent interview (the 12 prior steps captured the inputs); output is the visual contract handed to /sdd"
---

# Step 13 — Prototype v3 (screen atlas — the visual contract)

**Goal:** the LAST step of the Specification phase AND the pipeline. Produce a comprehensive screen atlas — `screen-atlas.md` as the navigable index + `screens/[0-9]+-*.html` as the per-screen renderings + `REPORT.md` as the synthesis critique. This bundle IS the visual contract engineering builds against in `/sdd new <slug>`. Step 7 (prototype-v2) closed Identity with a brand+tokens-applied refinement of the killer flow; step 13 closes Specification by re-rendering every PRD user-story as a covered screen, with state coverage explicit, PRD coverage scored, design fidelity per-screen scored, and Open Decisions surfaced for engineering.

**Mode:** `synthesis` with `delegable: true`. Fully delegable — the sub-agent reads prior artifacts (PRD + system-design + cost-estimate + roadmap + legal + brand-book + design-system + prototype-v2 screens) and produces the bundle with no live parent interview. The 4 structural signals (PRD US-NN list + step-7 picked direction + step-6 tokens + step-4 unresolved findings) are mechanically extracted from prior artifacts; the synthesis is structural.

**Output bundle** (atomic via `extra_files` — all files written together or none):

| File | Role | Floor |
|---|---|---|
| `screen-atlas.md` | primary artifact — navigable index of every screen, PRD coverage matrix, design-fidelity score table, states coverage matrix, user-flow walkthrough, open decisions | ≥ 10 KB |
| `screens/<NN>-<name>.html` × N | one HTML file per PRD-derived surface; brand+tokens applied; states covered; `<html`+`<style` per file | ≥ 8 KB each |
| `REPORT.md` | run summary + PRD coverage X/Y + design fidelity scores per screen + states coverage matrix + recommendations to engineering | ≥ 6 KB |
| `flow.html` *(optional)* | single-page click-through that links every screen via anchored navigation — the founder's at-a-glance walkthrough | — |

`screen-atlas.md` is the **navigable visual contract** — the file engineering opens in `/sdd new <slug>` to discover what to build. It is NOT a re-render of any single screen; it is the **index + scorecards + walkthrough** that frames the `screens/` set as a whole. Without it, the `screens/` set is a pile of HTML files with no map; with it, the next reader (engineering, designer, founder) navigates the product in a single document with deep links into each screen.

---

## How to conduct this step

Read `references/screen-atlas-format.md` (the canonical structure of the atlas + per-screen-row shape), `references/states-coverage.md` (the loading / empty / error / disabled / success matrix every interactive screen must cover), `references/prd-coverage-rubric.md` (how to map step-8 user-story IDs to screens + how to score coverage), and `references/tokens-application-checklist.md` (how step 6 `tokens.css` lands in every screen + how step 5 brand voice tunes every user-facing string) BEFORE drafting.

### 1. Read everything prior

- **Step 8 PRD** — `docs/product/08-prd/prd.md` — § User Stories (each with stable `US-NN` ID per step-8 convention) is the surface-coverage spine; § P0/P1/P2 Requirements drive which screens are mandatory vs deferred; § Success Metrics + § Acceptance Criteria give per-screen verification anchors. **Every US-NN in the PRD must map to at least one screen in the atlas, OR carry an explicit "deferred to v2" note with reason.**
- **Step 7 prototype-v2** — `docs/product/07-prototype-v2/` — the picked direction, brand+tokens-applied screens, and `direction-final.html` showcase. Step 13's screens INHERIT step 7's visual lineage; they extend coverage from "killer flow + identity surfaces" to "every PRD user-story". Re-read step 7's `screens/` to identify which surfaces already exist (do NOT re-render — link from the atlas) vs which step-13 must net-new render.
- **Step 6 design-system** — `docs/product/06-design-system/` — `tokens.css` is the canonical value layer (verbatim copy into every screen's `:root`); `components.md` is the component-anatomy + states spec (every state in `components.md` must appear in the states-coverage matrix); `design-system.md` § Catalog Lineage declares the catalog/custom/mixed path inherited.
- **Step 5 brand-book** — `docs/product/05-brand/brand-book.md` — voice samples ON+OFF brand, motion principles, imagery posture. Every user-facing string on every screen is voice-checked against the brand-book. The brand name (when step 5 picked a final name distinct from step 1's placeholder) propagates to every screen.
- **Step 4 ux-testing** — `docs/product/04-ux-testing/validation-report.md` — frontmatter `findings[]` filtered by `fix_skill_hint: "prototype-v3"` OR `fix_skill_hint: "prototype-v2"` with `status: open` (i.e., step 7 deferred or only partially resolved). Step 13 closes these inline during render and documents in REPORT.md `## Audit Response`.
- **Step 9 system-design** — `docs/product/09-system-design/system-design.md` § Pages & Surfaces + § Integrations — confirms the surface inventory the PRD anchors against; § Non-Functional § Accessibility floor is the per-screen a11y contract.
- **Step 11 roadmap** — `docs/product/11-roadmap/roadmap.md` § Phases + § Open Decisions — phases that have NOT yet shipped are flagged in the atlas as "deferred from atlas — see roadmap Phase N"; open decisions that depend on UI surface (e.g., "free-tier cap UI" Q4) carry forward to atlas § Open Decisions.
- **Step 12 legal** — `docs/product/12-legal/legal-posture.md` § Privacy Posture + § Regulated Aspects — drives mandatory legal-surface screens (consent dialog, privacy notice, ToS acceptance, AI-disclosure badges when § AI-Specific fires). These screens are NOT inherited from the killer flow; they are net-new at step 13.
- **Step 1 concept brief + Step 3 spec** — for cross-referencing copy / persona / mechanic vocabulary. The brand-book provides voice; the brief + spec provide the strings (real product name, real persona handles, real mechanic vocabulary).

If any of step 6 tokens.css, step 7 picked direction, or step 8 PRD is missing, stop and report to the parent — don't fabricate the missing input. Step 4 frontmatter absence is acceptable (projected-mode audit per step-7 convention); handle per `references/screen-atlas-format.md` § Audit response.

### 2. Extract the 4 structural signals

The sub-agent reads the prior artifacts and extracts four signals that calibrate the bundle. NO live parent interview — these are mechanically extracted, NOT interview questions:

1. **PRD user-story inventory.** Enumerate every `US-NN` from step 8 `prd.md` § User Stories. Note the priority tier (P0 / P1 / P2 / Backlog from § Requirements). The PRD-coverage matrix in `screen-atlas.md` lists every US-NN with its screen mapping (or "deferred — reason"). This is the load-bearing signal — without complete US-NN extraction, the atlas silently under-covers the PRD.

2. **Picked visual lineage.** From step 7's REPORT.md § Run Summary, identify which step-2 direction was picked + the path to step 7's `direction-final.html` + step 7's `screens/*.html` set. Step 13's screens inherit this visual lineage; reusing tokens, brand voice, and component patterns. The `:root` token block from step 6 `tokens.css` copies verbatim into every screen.

3. **Step-4 unresolved findings.** Parse step 4 frontmatter `findings[]`. Filter by (a) `fix_skill_hint: "prototype-v3"` (findings explicitly routed here) OR (b) `fix_skill_hint: "prototype-v2"` with `status: "open"` or `status: "deferred"` (step 7 didn't close them). These are the inline fixes step 13 applies during render. Annotate each with `<!-- fix(F-NN): applied at step 13 — reason: ... -->`.

4. **Legal-mandatory surfaces.** From step 12 `legal-posture.md` § Privacy Posture + § Regulated Aspects + § AI-Specific (when fires): enumerate the legal-driven surfaces (consent dialog, privacy notice, ToS acceptance, AI-output disclosure badge, age-gate when COPPA triggered, sub-processor disclosure surface). These are net-new at step 13 — step 7 typically does NOT render them; the killer flow is product-feature-focused, not compliance-surface-focused.

These four signals drive screen-count derivation (§ 4 below), per-screen content composition (§ 5 below), and the PRD-coverage / states-coverage / design-fidelity matrices in `screen-atlas.md`.

### 3. Determine N (screen count) — product-class calibrated

**Schema floor:** `min_count: 3` (universal sanity — below 3 is "I didn't try"). Calibration above the floor is the sub-agent's job, anchored in the PRD's user-story inventory + product class, justified in `screen-atlas.md` § Overview and REPORT.md § Run Summary.

#### Calibration table — product class → typical screen count

Pull the **Scale** field from the concept brief's identity block (step 1). Map it:

| Product class (concept brief § Identity · Scale) | Typical N | Anchor surfaces |
|---|:---:|---|
| Micro-Product / single-purpose tool / CLI helper | **3-5** | Primary action surface · settings · empty-error. CLI: `--help` / primary command / error output. |
| Mobile App (focused, 1-persona) | **4-7** | Onboarding · main view · detail · settings · (1-2 mechanic surfaces) + (legal-consent surface when § Privacy fires) |
| Developer Tool / API-first | **4-8** | Landing · dashboard · integration / quickstart · key-state · error / empty + (auth-token UI when applicable) |
| SMB SaaS (the spec 026 default) | **6-10** | Landing · onboarding · dashboard · 2-3 core CRUD/workflow · settings · empty-error + (consent + privacy-notice when § Privacy fires) |
| Venture-Scale / Marketplace / multi-persona | **10-15** | Multi-persona surfaces (consumer-side + provider-side) increase the count linearly; legal surfaces typically 2-3 distinct (consent, privacy, AI-disclosure when AI-stack) |

Concept-brief field is missing or ambiguous → default to **SMB SaaS (6-10)**.

#### Procedure — how to pick N for THIS product

1. **Enumerate every PRD US-NN + every legal-mandatory surface.** From signal 1 (PRD inventory) + signal 4 (legal surfaces). This is the raw screen-need list. Cap at 25; if it exceeds 25, the PRD is over-scoped — flag back to the parent as a step-8 revision, do NOT silently truncate.
2. **Triage each surface into 3 buckets:**
   - **Killer-flow surfaces** — the demo screens; the persona's daily-use surfaces; the P0 stories from PRD § Requirements. Must all render at hi-fi.
   - **Supporting surfaces** — P1 stories; onboarding; auth; settings; dashboard. Render at hi-fi the ones load-bearing for the persona's first session.
   - **Edge-state surfaces** — empty-first-run, permission-denied, offline, generic 404, legal-consent dialogs, AI-disclosure badges. Can be **combined into 1-2 multi-state screens** for terse products, or rendered as separate screens for richer ones.
3. **Sum the buckets, cross-check against the calibration table.** A 12-US-NN SMB SaaS PRD triaged as 4 killer-flow + 5 supporting + 3 edge-state lands at 8 hi-fi screens (4 killer + 3 of the supporting + 1 combined edge-state) — inside the 6-10 SMB SaaS range.
4. **Decide N.** If your triage lands inside the calibration-table range for the product's Scale, use that N. If it lands outside, **justify the deviation in REPORT.md § Run Summary**: "12 screens — venture-scale marketplace with 4 distinct personas; the table's 10-15 range fits".
5. **Confirm the list with the parent BEFORE writing** if N or the surface choices are ambiguous. The sub-agent's parent-checkpoint dialogue is the right place for this confirmation — surface "I plan N = `<N>` screens covering `<list>` (rationale: `<one line>`). Confirm or adjust before I render."

#### Example default lists (NOT prescriptive)

**SMB SaaS, N=8 (the spec 026 default):**
1. `01-landing.html` — marketing landing (hero, value sections, pricing, FAQ)
2. `02-signup.html` — sign up flow (US-01)
3. `03-onboarding.html` — first-run wizard (US-03)
4. `04-dashboard.html` — primary in-product workspace (US-04)
5. `05-killer-flow.html` — the core mechanic surface (US-07, US-19)
6. `06-detail-view.html` — secondary mechanic / detail (US-12)
7. `07-settings.html` — account / preferences / billing (US-20)
8. `08-empty-error-consent.html` — combined empty + error + loading + consent-dialog surface

**Micro-Product / CLI helper, N=4:**
1. `01-landing.html` — short marketing one-pager OR `--help` rendering
2. `02-primary-action.html` — the single main surface (US-01)
3. `03-settings.html` — preferences / `config` command output (US-04)
4. `04-empty-error.html` — combined empty + error + loading states

The numbered file prefixes (`01-` through `NN-`) match the schema's glob pattern; the schema enforces only the floor (`min_count: 3`), so any N ≥ 3 with sequential `01-..NN-` prefixes passes.

### 4. Render the screens — per-screen render rhythm

Each screen in `docs/product/13-prototype-v3/screens/<NN>-<name>.html` extends step 7's visual lineage to a PRD-derived surface. Two delegation patterns by N:

**Sequential (N < 6)** — single agent walks screens in order. Lower coordination cost; suitable for micro-products / CLI tools.

**Parallel sub-agents (N ≥ 6)** — parent dispatches one sub-agent per screen (or batches of 2-3) in the same response. Each brief locks ONE screen filename, the PRD US-NN(s) it covers, the audit findings routed to it, and the path to step 6's tokens.css. Same fan-out pattern as step 7 § 5 — see `02-prototype/prompt.md` § 3.5 for the brief shape. Use `model: opus` per sub-agent.

**Per-screen render rhythm** (the discipline that separates a v3 atlas-screen from a step-7 re-render):

1. **Copy step 6's `tokens.css` content verbatim into `:root`**. NOT a `<link>` reference — inline, so the screen renders self-contained via `file://`. Step 7's token-mapping decisions (Path A direct-rename vs Path B alias) carry forward unchanged — do NOT re-decide.
2. **Compose the screen around its PRD US-NN(s).** Every interactive element traces to a user-story acceptance criterion. The screen's hero / primary CTA / main surface maps to the US-NN(s) the screen covers.
3. **Cover ALL states from step 6 `components.md`.** For every component on the screen, render its loading / empty / error / disabled / success state — visible in the HTML, NOT just declared in CSS. Use HTML comment sections or inline labels (e.g. `<section data-state="empty">...</section>`). See `references/states-coverage.md` for the matrix discipline.
4. **Apply routed audit fixes.** Per signal 3, the screen carries `fix(F-NN)` HTML comments at each inline fix locus. The mapping is the parent's job — do it BEFORE dispatching per-screen sub-agents so each sub-agent receives only the findings it must materialize.
5. **Voice-tune every user-facing string** against step 5 brand-book. Concrete strings, NOT placeholders. "Try again." or "Well, that didn't work. Want to try again?" — pick the one that matches voice. Never `[error message]`, never lorem ipsum. The brand name (when step 5 differed from step 1's placeholder) propagates here.
6. **Legal-surface screens carry the literal posture commitments.** Consent dialogs include the legal-basis text from step-12 § Privacy Posture; AI-disclosure badges include the disclosure copy from step-12 § AI-Specific; sub-processor surfaces list the actual vendors from step-12 § Data Handling § Sub-processor disclosure. NOT placeholders, NOT generic SaaS templates.
7. **Annotate Source citations in an HTML comment header** at the top of each screen: `<!-- screen: 05-killer-flow.html | covers: US-07, US-19 | extends: step 7 screens/05-triage-view.html | fix: F-12 (audit-deferred from v2) | legal: n/a -->`. This is the in-source audit trail; the atlas summarizes it; engineering reads both.

### 5. Write `screen-atlas.md` — the navigable visual contract

Required level-2 sections (see `schema.md` for the floor + `references/screen-atlas-format.md` for the per-section depth conventions):

- **`## Overview`** — short paragraph + 3 load-bearing one-liners (mirrors step 9 / 10 / 11 / 12 § Overview shape):
   - **Paragraph:** what's being indexed (the v1 screen atlas), product class + chosen N + rationale ("8 screens for an SMB SaaS, killer-flow + 3 supporting + 1 edge-state"), picked direction inherited from step 7.
   - **PRD coverage one-liner:** `X/Y user-stories covered (X out of Y from step-8 PRD); Z deferred to v2 with reason`. Numbers visible up front; the matrix in § PRD Coverage carries the per-row detail.
   - **Visual lineage one-liner:** step-7 picked direction name + step-6 tokens.css version + brand voice posture (`from step 5 § Voice`).
   - **Deciding signal for engineering handoff:** the one-line condition under which `/sdd new <slug>` should NOT fire — e.g., "Hold `/sdd new <slug>` if any P0 US-NN is uncovered in the matrix below; otherwise the contract is locked".

- **`## Screens Index`** — per-screen one-line row in a markdown table. Format:
   ```markdown
   | # | Screen | Covers (US-NN) | Extends | Concern |
   |---|---|---|---|---|
   | 01 | `screens/01-landing.html` | — (marketing) | step 7 — | [product] |
   | 02 | `screens/02-signup.html` | US-01 | step 7 screens/01-signup.html | [product+engineering] |
   | 03 | `screens/03-onboarding.html` | US-03 | step 7 screens/02-onboarding.html | [product+engineering] |
   | 04 | `screens/04-dashboard.html` | US-04, US-06 | step 7 screens/03-dashboard.html | [product+engineering] |
   | 05 | `screens/05-killer-flow.html` | US-07, US-19 | step 7 screens/05-triage-view.html | [product+engineering] |
   | 06 | `screens/06-detail-view.html` | US-12 | net-new at step 13 | [product+engineering] |
   | 07 | `screens/07-settings.html` | US-20 | step 7 screens/07-settings.html | [product+engineering] |
   | 08 | `screens/08-empty-error-consent.html` | US-22 + legal-consent | net-new at step 13 | [product] [counsel-review] |
   ```
   Concern tags inherit the step-11 allow-list (`[engineering]` / `[product+engineering]` / `[product]` / `[design]` / `[founder]`) extended with step-12's `[counsel-review]` for legal-surface rows.

- **`## PRD Coverage`** — the load-bearing scorecard. Per-US-NN markdown table:
   ```markdown
   | US-NN | Title (short) | Priority | Screen(s) | Acceptance Source | Status |
   |---|---|---|---|---|---|
   | US-01 | Sign up via email/Google | P0 | `screens/02-signup.html` | PRD § AC US-01 | covered |
   | US-03 | Import Jira in <2 min | P0 | `screens/03-onboarding.html` | PRD § AC US-03 | covered |
   | US-07 | Keyboard-first triage | P0 | `screens/05-killer-flow.html` | PRD § AC US-07; F-12 resolved at screen 05 | covered |
   ```
   **Every US-NN from step 8 PRD MUST appear here.** When a US-NN is deferred to v2, status is `deferred — <reason>` (e.g. "deferred — Phase 3 per roadmap; UI surface designed but not in atlas"). Silent omission is the regression mode the discipline catches.

   Coverage score: `## PRD coverage: X/Y` line at the END of the section. X is covered count; Y is total US-NN count. The score is what REPORT.md § PRD Coverage cites.

- **`## Design Fidelity`** — per-screen 5-dim scoring table inherited from step 7 (Token / Voice / Component / Audit-fix / Specificity / Min). Each row is one screen; the Min column is the gate indicator (✓ if ≥ 3 across all five dims). Any score < 3 names the deviation in REPORT.md § Recommendations.
   ```markdown
   | Screen | Token | Voice | Component | Audit-fix | Specificity | Min |
   |---|:---:|:---:|:---:|:---:|:---:|:---:|
   | 01-landing | 5 | 5 | 4 | n/a | 5 | 4 ✓ |
   | 02-signup | 5 | 5 | 5 | 5 | 4 | 4 ✓ |
   | 03-onboarding | 4 | 4 | 5 | 5 | 4 | 4 ✓ |
   ```

- **`## States Coverage`** — matrix table cross-cutting screens × states. Loading / Empty / Error / Disabled / Success. Cell content: ✓ when rendered in the screen; — when the state is N/A for that screen; `[gap]` when the screen needs the state but step 13 didn't render it (escalate to engineering or back-flag to step 6).
   ```markdown
   | Screen | [Loading] | [Empty] | [Error] | [Disabled] | [Success] |
   |---|:---:|:---:|:---:|:---:|:---:|
   | 02-signup | ✓ | — | ✓ | ✓ | ✓ |
   | 04-dashboard | ✓ | ✓ | ✓ | — | ✓ |
   | 05-killer-flow | ✓ | ✓ | ✓ | ✓ | ✓ |
   ```
   See `references/states-coverage.md` for the per-state rendering discipline + the cross-reference to step 6 `components.md`.

- **`## User Flow`** — written walkthrough of the killer flow across screens. NOT a re-summarization of every PRD acceptance criterion — a narrative anchored to a real persona that traces a single end-to-end session through `screens/02-...` → `screens/03-...` → ... → `screens/05-...`. The reader (engineering, designer, founder) follows the narrative and clicks each screen file:// URL to see the screen at that point in the flow. **Anchor to a real human role** for acceptance — "Closed-beta partner #1 navigates the atlas unassisted and reproduces the killer flow in <5 minutes" is the contract. CI-only / artifact-presence checks are necessary-but-not-sufficient.

- **`## Open Decisions`** — decisions the atlas surfaces for `/sdd new <slug>` to resolve. Inherits the step-11 + step-12 single-consolidated-table discipline. Each row carries a deciding signal. Format:
   ```markdown
   | # | Decision | Default if no decision by | Deciding signal | Concern |
   |---|---|---|---|---|
   | 1 | Confirm screen 08 combines empty+error+consent OR splits to 3 screens | first /sdd planning session | If engineering's component library has separate Empty / Error / Modal patterns, split; if shared shell, keep combined | [engineering] [product] |
   | 2 | Confirm legal-consent copy is the literal text shipped vs a placeholder for counsel review | before /sdd new <slug> fires | Counsel email approving the literal copy in screens/08; default placeholder until then | [counsel-review] [product] |
   | 3 | Confirm mobile-responsive variants of killer-flow screens (US-07) | end of Phase 2 per step-11 roadmap | If closed-beta partner #1 requests mobile in the first sprint, fold into Phase 2; otherwise defer to v2 | [design] [engineering] |
   ```
   2-5 rows is the target. NOT every decision — just the ones the atlas is parked on for engineering handoff.

- **`## v2-Vision`** — 3-5 bullets sketching the next 3-6 months of screen evolution post-v1. Mirrors step-11 § v2-Vision shape but at the screen level. Each bullet carries a "drives v1 atlas decision" clause that names what the v1 atlas should design FOR or AGAINST.
   ```markdown
   - **Public sharing surface (3 months post-launch).** v1 atlas does NOT include a share-issue surface; the killer flow is internal triage. Drives v1 atlas decision: every URL is workspace-scoped, no public share tokens designed.
   - **Mobile companion (6 months post-launch, deferred).** Atlas screens are desktop-first per concept brief § Identity. Drives v1 atlas decision: skip mobile-responsive polish in screen 05 (saves ~1 screen of variance).
   ```

### 6. Write `REPORT.md` — the synthesis critique

Required level-2 sections (see `schema.md` for the floor):

- **`## Run Summary`** — atlas product class + chosen N + rationale; picked-direction inherited from step 7; design-system version (step 6 tokens.css hash or version); brand-book version (step 5); audit findings inventory ("F-12, F-13 resolved inline at step 13; F-22 deferred to engineering / sub-agent reasoning in § Audit Response"); legal-driven surfaces ("consent dialog in screen 08; AI-disclosure badge in screen 05 per step-12 § AI-Specific"); output paths as `file://` URLs.
- **`## PRD Coverage`** — `X/Y` score visible at section open. Per-PRD-section breakdown when relevant (e.g., "P0: 5/5 covered; P1: 3/4 covered (US-18 deferred to Phase 3 per step-11); P2: 0/2 covered (Backlog)"). Lists deferred US-NNs with reasons. The REPORT's PRD Coverage section is the engineering-facing summary; the atlas's § PRD Coverage section is the per-US-NN audit trail.
- **`## Design Fidelity Scores`** — same per-screen table as atlas § Design Fidelity; here in REPORT it carries an additional **`Notes`** column when any dimension scored < 4. Single-line reason per row when below 4 — "Token: 3 — screen needed --shadow-modal, used --shadow-md as fallback; see § Token Gaps".
- **`## States Coverage Matrix`** — same matrix as atlas § States Coverage; here in REPORT it carries a summary count line ("All screens cover Loading + Error; 2 screens have `[Empty]` gaps — escalated to engineering"). The literal `[Loading]`, `[Empty]`, `[Error]` column headers are the load-bearing structural anchors the schema enforces.
- **`## Recommendations`** — actionable items for `/sdd new <slug>` to absorb into engineering execution. Mirrors step-7 § Deviations + step-9/10/11/12 § Open Decisions shape. Format: numbered list, each item carries a concern tag. Closes the loop between v1 atlas and engineering execution.

### 7. Surface for parent confirmation (Layer 3 checkpoint)

After `screen-atlas.md` + screens + REPORT drafts, do NOT call `product_step_submit` yet. Surface to parent:

```
✅ Step 13 complete — screen atlas synthesized

  file:///<absolute-path>/screen-atlas.md       — primary visual contract
  file:///<absolute-path>/REPORT.md             — synthesis critique
  file:///<absolute-path>/flow.html             — optional click-through walkthrough
  file:///<absolute-path>/screens/01-...html    — <screen 1 one-line summary>
  ...
  file:///<absolute-path>/screens/NN-...html    — <screen N one-line summary>

  ATLAS SUMMARY:
    · N screens cleared design-fidelity ≥ 3/5 across 5 dimensions
    · PRD coverage X/Y (Z deferred with reasons in screen-atlas.md § PRD Coverage)
    · States coverage matrix: M screens cover Loading + Error fully; K gaps escalated
    · L Open Decisions surfaced for /sdd new <slug>

  Surface the atlas to the parent as a navigable index + await walkthrough confirmation
  BEFORE product_advance. The reply pattern is: parent (or user) navigates screen-atlas.md
  + at least 3 sample screens via file:// URLs, then confirms "atlas locked" — that is the
  trigger to call product_advance.
```

Wait for confirmation. Do NOT call `product_advance` until parent confirms the atlas walkthrough succeeded.

### 8. Submit

Call `product_step_submit` with:
- `step: 13`
- `filename: "screen-atlas.md"`
- `content: <full atlas>`
- `extra_files`: `[{path: "REPORT.md", content: ...}, {path: "screens/01-<name>.html", content: ...}, ..., {path: "screens/NN-<name>.html", content: ...}, optionally {path: "flow.html", content: ...}]`

Schema enforces presence + min_size + contains for all listed files; missing/undersized produces `code: "schema-incomplete"` with the failure list. All files persist atomically — nothing is written unless every file passes Layer 1.

### 9. Advance (pipeline complete)

Call `product_advance`. Because step 13 is the LAST_STEP and is NOT in `GATE_AFTER` (the specification gate already fired after step 12), `product_advance` does NOT require another `product_gate_pass`. The response is:

```json
{
  "code": "pipeline-complete",
  "slug": "<slug>",
  "message": "Product planning complete. The comprehensive screen atlas at docs/product/13-prototype-v3/screen-atlas.md is the visual contract for engineering. Execution starts via /sdd new <slug> populating docs/specs/NNN-*/.",
  "next_action": "call product_done for the full handoff summary"
}
```

Then call `product_done` for the per-phase deliverable inventory + the literal `/sdd new <slug>` handoff command. **The screen-atlas.md is named explicitly in the `product_done` message as the visual contract** — engineering opens it first when starting `/sdd new <slug>` to discover what to build.

---

## Voice & rigor

- **The atlas IS the visual contract.** Treat `screen-atlas.md` like the file engineering opens in `/sdd new <slug>` — because that's exactly what happens. Every section is written for the next reader (engineering, designer, founder) navigating the product, NOT for an internal compliance check.
- **PRD coverage is binary per US-NN, not aspirational.** Every `US-NN` from step 8 PRD either has a screen (covered) or a documented deferral reason. Silent omission is the regression mode — a US-NN absent from the matrix is a covered-or-deferred decision the founder didn't get to make.
- **States coverage is per-component, not per-screen.** A screen with 5 interactive components has up to 25 state cells (5 components × 5 states). The matrix collapses to per-screen for readability, but the source-of-truth is per-component per step 6 `components.md`. Gaps in the matrix trace to gaps in `components.md` § Patterns OR to gaps in the screen render — both worth surfacing.
- **Design fidelity ≥ 3/5 across 5 dimensions per screen.** Any score < 3 requires either a fix pass (preferred) OR a deviation note in REPORT.md § Recommendations naming the trade-off accepted. Score inflation breaks the discipline.
- **Voice-check every user-facing string against step 5 brand-book.** Concrete strings, not placeholders. The brand name (when step 5 picked a final name different from step 1's placeholder) propagates to every screen — silent placeholder shipping is the failure mode this rule prevents.
- **Legal-mandatory surfaces carry the literal posture commitments.** Consent dialog uses the legal-basis text from step-12 § Privacy Posture verbatim; AI-disclosure badge uses the disclosure copy from step-12 § AI-Specific; sub-processor surfaces list the actual vendors from step-12 § Data Handling. NOT placeholders, NOT generic SaaS templates — the legal posture committed in step 12 lands on screens, observable by counsel review.
- **Inline audit-fix annotation per finding.** `<!-- fix(F-NN): applied at step 13 — reason: ... -->` is the in-source audit trail. A reader of the HTML diff between step 7 and step 13 sees WHY each change happened, mapped to a finding ID.
- **User-flow shaped section names where applicable** — inherits step-11 KEEP 1. The `## User Flow` H2 reads as a user-flow narrative ("A new manager signs up, imports a Jira workspace, triages 25 issues in 5 minutes") NOT as a label category ("Killer flow walkthrough"). The label form is valid fallback when the flow IS the named category (e.g., for atlas-of-edge-states-only).
- **Concern tags inherited from step 11 + 12.** `[engineering]` / `[product+engineering]` / `[product]` / `[design]` / `[founder]` / `[counsel-review]`. Optional — omit when single-discipline. Don't invent new tags.
- **Real-human acceptance in § User Flow** — inherits step-11 KEEP 3. "Closed-beta partner #1 navigates the atlas unassisted and reproduces the killer flow in <5 minutes" is stronger than "Atlas opens in browser without errors". CI-only checks are necessary-but-not-sufficient; a named human signoff is the contract.
- **Step-4 finding-ID lineage in Source citations** — inherits step-11 KEEP 5. The screen-atlas's `## PRD Coverage` Source column cites finding IDs when a step-4 finding resolves at a screen (e.g., "F-12 resolved at screen 05-killer-flow.html"). Adds the step-4 → step-13 lineage closing the trace from observed-user-pain → shipped-fix in the visual contract.
- **Exit / sub-criteria with ≥4 conditions format as sub-bulleted list, not single paragraph.** Inherits step-11 + step-12 CUT. When § User Flow carries 4+ step-by-step actions, format as sub-bulleted list under the bold persona-name introduction, NOT a single semicolon-separated paragraph.
- **Open Decisions carry deciding signals** — inherits step-9 / 10 / 11 / 12 § Open Decisions discipline. Every deferred screen-atlas decision either HOLDS or FLIPS on a measurable signal — a counsel-review email, a closed-beta partner request, an engineering component-library audit. Mirrors the discipline at the visual contract layer.
- **No meta-commentary section about the atlas's own visual-contract discipline** — inherits step-9 / 10 / 11 / 12 CUT-2. Do NOT write a `## Notes on this atlas's coverage discipline` or any equivalent. The matrices + scorecards + walkthroughs ARE the discipline; a section *about* them is noise.
- **No "locked decisions" sub-section** — inherits step-9 / 10 / 11 / 12 CUT-1. Picked direction, chosen N, product class are declared inline in § Overview opening. Re-tabling them as a separate Locked H2 duplicates the running commitment.
- **No metadata banner with pipe-separators at top of file** — inherits step-11 + 12 CUT-3. Do NOT emit a header line in the shape `**Pipeline step:** 13 (Prototype v3) | **Generated:** YYYY-MM-DD | **Class:** SMB SaaS`. Ceremony with no payoff — file path + § Overview opening sentence carry the same signal.
- **The atlas is a navigable index, NOT a re-summarization of every PRD section.** A founder hands the atlas to engineering for `/sdd new <slug>`; engineering reads the atlas, clicks a few screens, runs the killer-flow walkthrough, then dives into the PRD for acceptance-criteria depth when implementing. Atlas summarizes; PRD is the depth source. Sweet-spot file size is 11-16 KB for an SMB SaaS atlas (expand to ~18-20 KB for venture-scale multi-persona). A 30+ KB atlas is the regression mode where the agent re-summarized the entire PRD — pull the depth back to the PRD's own file.

## What this step does NOT do

- **Pixel-perfect production code.** The HTML is hi-fi mockup — interactivity remains CSS-only unless an interaction is core to the screen's contract. Step 13 is the visual contract; framework code emerges in `/sdd new <slug>` engineering execution.
- **Framework code (React / Vue / Svelte).** The atlas is HTML + the index document; framework synthesis happens AFTER `/sdd new <slug>` based on the engineering team's stack choice.
- **Brand voice deep-dive.** Step 5 owns voice; step 13 *applies* it to every screen string + the atlas narrative.
- **Design tokens.** Step 6 owns tokens; step 13 *consumes* them. A token referenced by a screen that doesn't resolve in step 6 `tokens.css` is a step-6 gap — flag in REPORT.md § Recommendations, do not invent the token inline.
- **PRD revision.** Step 8 owns the PRD. Step 13 reads it and flags coverage gaps; it does NOT modify PRD content. A US-NN deferral surfaces in atlas § PRD Coverage + REPORT.md § PRD Coverage; the PRD update happens in step 8 if the founder confirms the deferral is structural.
- **Roadmap revision.** Step 11 owns the roadmap. Step 13 reads it for phase context; deferral-to-Phase-3 decisions surface in atlas § Open Decisions but the roadmap document is not modified.
- **Engineering execution.** Step 13 closes the planning pipeline; `/sdd new <slug>` opens engineering execution. The atlas is the handoff document, NOT the implementation plan.
- **User testing.** Step 4 ran the planning-side audit; post-launch user testing is post-pipeline territory.

## What this step replaces

Step 13 is **NEW** — there is no anthill analog. It synthesizes from three anthill skills + the cumulative MCP-port discipline (steps 1-12):

1. **anthill-prototype** § Turn-2 hi-fi screens — provides the per-screen render rhythm (tokens copied verbatim, brand voice applied, components composed per the design system). Step 13 extends from "killer flow N screens" to "every PRD US-NN + every legal-mandatory surface".
2. **anthill-prd** US-NN stable ID convention — provides the coverage matrix anchor. Step 8's MCP port establishes the US-NN convention; step 13 cashes in on it for the PRD-coverage matrix that drives the atlas index.
3. **anthill-design-system** § Components.md states — provides the states-coverage matrix anchor. Step 6's MCP port establishes the loading / empty / error / disabled / success state vocabulary; step 13 cashes in on it for the per-screen states matrix.

The synthesis composition (atlas + screens + REPORT + flow) is Agent0-original. Anthill ships individual skills that produce single artifacts; step 13's discipline is to assemble the visual contract that `/sdd new <slug>` consumes — a different shape than anthill's per-skill artifacts. The MCP-port discipline inherits from step 7 (visual lineage + inline audit fixes), step 8 (US-NN coverage), step 11 (Open Decisions with deciding signals + concern tags + real-human acceptance + user-flow shaped names + sub-bulleted exit criteria), step 12 (synthesis mode + consolidated tables + escape-clause-equivalent legal-surface posture).

Anthill's `.anthill/`-namespaced runtime references are NOT applicable — there is no anthill source skill for step 13. The MCP-only conventions (`product_step_submit` validation errors → `code: "schema-incomplete"`, `product_advance` → `pipeline-complete` after step 13, `product_done` surfaces `/sdd new <slug>` as the handoff) are the canonical contract surface.
