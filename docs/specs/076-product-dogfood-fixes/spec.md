# 076 — product-dogfood-fixes

_Created 2026-05-22._

**Status:** draft

## Intent

The 2026-05-22 triage of the mei-saas `/product` dogfood produced 10 findings, each verified against current Agent0 source. The budget-instrument subset (#1, #2-byte-window, #6, #7, #10) is spec 075. This spec batches the **remaining six** — five `/product`-skill bugs and one harness-core observation — none of which depend on the budget-instrument work, so they can ship independently:

- **#9 — Step 08 NN-prefix typo.** `delegation-briefs.md § Step 08` line 220 says "Write 3 files: `08-system-design.md` + `08-security.md` + `08-data-flow.json`" — stale `NN-` prefixes; v0.4.0/spec 048 uses semantic names. The DELIVERABLE line (222) is already correct.
- **#4 — Playwright blocks `file://`.** `SKILL.md § Phase 4` step 3 instructs the best-effort visual check to `browser_navigate` to each hi-fi screen's `file://` URL. The Playwright MCP blocks the `file:` protocol (independently confirmed twice during spec 073 work) — the visual check is silently skipped.
- **#2-sections — Step 11 brief vs schema section disagreement.** `delegation-briefs.md § Step 11` says "SKIP unit economics + sensitivity + scenario analysis" and lists 6 H2 sections; `11-cost-estimate/schema.md` enforces `## Sensitivity` and gates `## Unit Economics` for revenue products. (The byte-window half of #2 — brief's 5-8 KB ceiling below the schema's 10 KB floor — dissolves with spec 075's ceiling retirement; only the section-set contradiction is in scope here.)
- **#3 — mood-screen brief lacks a responsive-nav rule.** The § Mood-screen-writer brief mandates mobile-first + no horizontal overflow, but has no rule that exactly one nav renders at any width. A desktop nav that *wraps* (rather than overflows) passes the mobile-first check while being visually broken — and the SKILL.md overflow probe (`scrollWidth > clientWidth`) cannot catch a wrap.
- **#5 — false-parallelism claims in the orchestration docs.** `SKILL.md`, `delegation-briefs.md` (line 392), and `state-machine.md` claim Step 15a+15b+15c are parallelizable with "all inputs on disk from Phases 1-3". False: Step 15b (hi-fi mood) reads `fixture-spec.md` — Step 15c's output (mood-screen-writer brief, hi-fi CONTEXT); and Step 03+04 are claimed parallel but Step 04 reads `functional-spec.md` — Step 03's output. The orchestration contract actively misleads.
- **#8 — model-escalation advisory noise (harness-core, the lone non-`/product` item).** The `delegation-gate.sh` **escalation** advisory ("consider re-issuing with `model: opus`") fires on every skill-directed `sonnet` dispatch (Steps 02-15) that trips ≥2 complexity signals — which dense `/product` briefs always do. The gate cannot distinguish a deliberate skill-chosen model from an under-committed ad-hoc one. Resolution approach is an open question (below).

## Acceptance criteria

- [ ] **#9** — `delegation-briefs.md § Step 08` uses semantic filenames consistently (`system-design.md` / `security.md` / `data-flow.json`); no `08-` NN-prefix remains in the "Write 3 files" line

- [ ] **Scenario: #4 — visual check runs over HTTP, not `file://`**
  - **Given** the Phase 4 best-effort visual check on the hi-fi screens
  - **When** `SKILL.md` runs it
  - **Then** it serves `<out>/docs/screens/hifi/` over a local HTTP server and `browser_navigate`s to `http://127.0.0.1:<port>/...` — never a `file://` URL — so the check actually executes

- [ ] **#2-sections** — `delegation-briefs.md § Step 11` and `templates/pipeline/11-cost-estimate/schema.md` declare the **same** required-section set: no "SKIP X" in the brief for a section the schema's Layer 1 enforces

- [ ] **#3** — the § Mood-screen-writer brief carries an explicit single-nav rule: exactly one nav renders at any viewport width; the desktop nav/sidebar is `display:none` below the mobile breakpoint (a wrapped nav is a hard violation, not just an overflow concern)

- [ ] **Scenario: #5 — dependent steps are not dispatched in parallel**
  - **Given** Step 15b consumes `fixture-spec.md` (Step 15c's output) and Step 04 consumes `functional-spec.md` (Step 03's output)
  - **When** `/product` dispatches those steps
  - **Then** Step 15c completes before Step 15b is dispatched, and Step 03 before Step 04 — they are not in the same parallel message; and `SKILL.md` / `delegation-briefs.md` / `state-machine.md` no longer assert "all inputs on disk from Phases 1-3" for those pairs

- [ ] **#8** — the model-escalation advisory no longer fires spuriously on skill-directed dispatches (exact mechanism per the resolved open question below)

## Non-goals

- **Does not touch the budget instrument.** Findings #1, #2-byte-window, #6, #7, #10 are spec 075 (`product-quality-audit`) — the size-ceiling retirement + rubric judge. This spec does not modify `artifact-budgets.md` or the `schema.md` size floors/ceilings.
- **Not a `/product` redesign.** These are six discrete bug/contradiction fixes against the current v0.4.0 skill, not a pipeline restructure.

## Open questions

- [ ] **#8 resolution approach** — three candidates: (a) accept the advisory as informational noise (it never blocks — advisories are always allowed); (b) the skill sets an explicit signal at dispatch so the gate recognizes a deliberate skill-chosen model and suppresses `escalation`; (c) `delegation-gate.sh` learns to skip `escalation` when the dispatch carries a brief-declared model. Note this is harness-core (`delegation-gate.sh` + `.claude/rules/delegation.md`), the only finding in this spec that ships beyond the `/product` skill. _Owner: founder, before `plan.md` locks._

## Context / references

- Conversation 2026-05-22 — the 10-finding triage table (each finding verified against source)
- `.claude/skills/product/references/delegation-briefs.md` — §§ Step 08 (#9), Step 11 (#2), Phase 4 line 392 + § Mood-screen-writer (#3, #5)
- `.claude/skills/product/SKILL.md` — § Phase 4 visual check (#4) + the 15a/b/c and 03/04 dispatch claims (#5)
- `.claude/skills/product/references/state-machine.md` — the parallel-dispatch claims (#5)
- `.claude/skills/product/templates/pipeline/11-cost-estimate/schema.md` — the enforced section set (#2-sections)
- `.claude/hooks/delegation-gate.sh` + `.claude/rules/delegation.md` § Advisories — the `escalation` advisory (#8)
- `docs/specs/066-product-ui-quality/` — fix F9 reportedly addresses the 15-trio dependency; cross-check when implementing #5
- `docs/specs/075-product-quality-audit/` — the sibling spec; the budget-instrument half of the same dogfood
