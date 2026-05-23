# 076 — product-dogfood-fixes — plan

_Drafted from `spec.md` on 2026-05-22. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Six discrete fixes against the same dogfood triage. Five are local to the `/product` skill (a single line of stale prefix, a brief/schema section disagreement, a missing nav-discipline rule, two real false-parallelism claims, and a `file://` navigation that the Playwright MCP refuses); one is harness-core — the `# SKILL-DIRECTED:` marker mechanism resolved in OQ#8 that lets `delegation-gate.sh` recognize a deliberate skill-chosen model and suppress only the `escalation` advisory.

Execution order is **easiest → most cross-cutting**, one finding per commit so each `docs/specs/076-*/spec.md` acceptance scenario maps to a single revertible row in `git log`:

1. **#9** Step 08 NN-prefix typo — single-line edit in `delegation-briefs.md`.
2. **#3** Mood-screen single-nav rule — single CONSTRAINTS bullet added to the `§ Mood-screen-writer` brief.
3. **#2-sections** Step 11 brief vs schema alignment — reconcile the brief's section list to mirror `11-cost-estimate/schema.md` (the schema is the Layer 1 enforcer; brief must follow).
4. **#5** False-parallelism — serialize 03→04 and 15c→15b in `SKILL.md`, `delegation-briefs.md`, `state-machine.md`; 15a stays parallel with the (now serial) 15c→15b chain.
5. **#4** Phase 4 visual check over HTTP — replace the `file://` navigation with a tiny localhost server (Python's `http.server` if `python3` available, advisory-skip otherwise); inline a helper script `.claude/skills/product/scripts/serve-hifi.sh` so SKILL.md stays declarative.
6. **#8** SKILL-DIRECTED marker — gate-side reader (~5 lines around `delegation-gate.sh:213`), new audit field, rule documentation, and one marker line per Step 02-15 brief in `delegation-briefs.md`.

Each fix carries its own scenario in `spec.md`; verification per finding is the cheapest check that proves the contract:

- #9, #2-sections, #3 → `grep`/diff against the source line.
- #5 → re-read `SKILL.md § Phase 4` + § Worked example + `state-machine.md`; confirm no "ONE message" / "all inputs on disk" claim survives for the dependent pairs.
- #4 → invoke the helper script directly with a known fixture dir; confirm `lsof -i :<port>` shows it bound, then teardown.
- #8 → unit-test the gate by piping a stdin payload with + without the marker; observe `advisory_kind` flip from `"escalation"` to `null` (with marker) while a markerless equivalent still emits `"escalation"`. Tail one audit row of each case to confirm `skill_directed` field shape.

## Files to touch

**Create:**
- `.claude/skills/product/scripts/serve-hifi.sh` — best-effort HTTP server launcher for the Phase 4 visual check (Python `http.server` on a free port, prints `READY <port>` to stdout when bound; teardown caller's job via `kill $!`). Fail-fast with `not-available: <reason>` to stderr if `python3` missing — SKILL.md catches and falls back to advisory-skip.

**Modify:**
- `.claude/skills/product/references/delegation-briefs.md` — five edits:
  - **#9** § Step 08: `08-system-design.md + 08-security.md + 08-data-flow.json` → `system-design.md + security.md + data-flow.json` (one line; DELIVERABLE already correct)
  - **#2-sections** § Step 11: drop `SKIP unit economics + sensitivity + scenario analysis`; rewrite the required-H2 list to mirror `schema.md` (8 required + 3 conditional for revenue products: Overview / Pricing Model / Assumptions / Build Cost / Run Cost / Sensitivity / Risks / Recommendations + Unit Economics / Projections / Scenarios when revenue)
  - **#3** § Mood-screen-writer CONSTRAINTS: add one bullet — *"Exactly one nav renders at any viewport width. The desktop nav/sidebar is `display:none` below the mobile breakpoint (a wrapped nav is a hard violation, not just an overflow concern — the SKILL.md overflow probe cannot catch a wrap)."*
  - **#5** § Phase 4 (line ~392) + § Worked example (line ~188): "Step 15 dispatches three sub-agents — parallelizable in ONE message" → "Step 15 dispatches 15a + 15c **in one message** (no shared inputs); after 15c returns, dispatch 15b alone (reads `fixture-spec.md` from 15c)". Same correction for "Steps 03 + 04 — parallel fan-out" → "Step 03 alone (produces functional-spec.md); after 03 returns, Step 04 alone (reads functional-spec.md)".
  - **#8** add `# SKILL-DIRECTED: product` (mirrors `# OVERRIDE:` grammar) at the top of every brief body, Step 02 through Step 15c (count: 14 producer briefs + Mood-screen-writer + Quality judge = ~16 insertions).

- `.claude/skills/product/SKILL.md` — three edits:
  - **#4** § Phase 4 step 3: rewrite the visual check to launch the helper script, capture `READY <port>`, navigate to `http://127.0.0.1:<port>/<NN>-<name>.html` per screen, then teardown. Update the existing advisory shape to cover the new failure modes (`python3 missing`, `port bind failed`).
  - **#5** § Phase 4 step 1 + § Worked example: same serialization fixes (15a||15c, then 15b; 03 then 04) — keep wording aligned with delegation-briefs.md so the two files don't drift again.

- `.claude/skills/product/references/state-machine.md` — **#5** update the dispatch DAG diagram: `03+04 parallel` → `03 alone → 04 alone`; `step 15a + 15b + 15c parallel` → `15a + 15c parallel → 15b alone`.

- `.claude/hooks/delegation-gate.sh` — **#8** five-line addition around line 198-216:
  - `grep -qE '^# SKILL-DIRECTED: [A-Za-z0-9_-]{10,}' <<< "$PROMPT"` captures `skill_directed` slug (`""` when absent)
  - Suppress the `escalation` branch when `skill_directed != ""` (the `model-discipline` branch is unaffected — undeclared models still get nudged)
  - Add `--arg skill_directed "$SKILL_DIRECTED"` to the audit-row jq builder; new field after `advisory_kind`. Null when absent (use `--argjson` with `null` sentinel).

- `.claude/rules/delegation.md` — **#8** two edits:
  - § Advisories: add a paragraph documenting the marker (grammar, what it suppresses, what it does NOT excuse, audit-row field)
  - § Audit log → Dispatch row: bump field count from "Thirteen" to "Fourteen"; add `skill_directed` to the field enumeration with the same shape as `override` (string-or-null)

**Delete:**
- (none)

## Alternatives considered

### #4 — inline HTTP server in SKILL.md bash instead of a helper script

Rejected because the SKILL.md is already 25 KB of dense orchestration prose; inlining a multi-line `python3 -m http.server` + port-capture + PID-tracking + teardown scriptlet inflates the cognitive cost of reading Phase 4. The helper script is six lines, lives next to `build-report.ts`, is independently testable (`bash serve-hifi.sh ./fixture-dir` returns `READY 47281`), and keeps SKILL.md a declarative "launch helper → navigate → teardown" sequence.

### #8 — set the marker on the `description` field instead of the prompt body

Considered because `description` is a separate Agent-tool field (no prompt token cost). Rejected: the gate already reads the prompt body for the `# OVERRIDE:` marker, so adding a second extraction channel doubles surface area for no real win. The prompt body's marker grammar is established convention — generalizing it (override + skill-directed both end with `: <reason ≥10 chars>`) keeps the rule one short paragraph instead of two.

### #5 — keep 15a/15b/15c in one message and have 15b stub the fixture-spec read

Rejected because the producer's whole job is rendering on-brand, fixture-grounded copy (Mood-screen-writer hi-fi mode CONSTRAINTS, line ~482 of delegation-briefs.md). Stubbing the fixture read forces lorem-ipsum or invented data — exactly the antipattern the Step 15c fixture-spec exists to eliminate. Serialization is the only honest fix. The `notes.md` of spec 066 (2026-05-20) addressed 15a's atlas-vs-bytes case ("atlas forward-references hi-fi mood screens by path") but never reconciled 15b's hard read of 15c's bytes — this plan closes that gap.

### Spec 075 already shipped — also retire the "SKIP sensitivity" alongside the byte-window dissolution

Rejected: spec 075 explicitly retired only the **size-ceiling** instrument, not section-set discipline. The Step 11 brief's "SKIP sensitivity" line is independent — it was already wrong under v0.4.0 schema (which enforces `## Sensitivity` at Layer 1). Bundling the section-set fix into 075 would have conflated two distinct mechanisms; 076 is the correct home.

## Risks and unknowns

- **#4 — `python3` availability isn't guaranteed in every fork's environment.** The helper script falls back to a `not-available: python3 not found` advisory; SKILL.md treats that the same as today's `visual-gate-skipped` path. If real usage surfaces forks without Python, a `bun` HTTP one-liner is a cheap follow-up (bun is already a `/product` prerequisite via build-report.ts).
- **#5 — serializing 03→04 lengthens Phase 1 wall-clock.** Cost is ~1 sub-agent dispatch round; benefit is Step 04 actually reads non-empty functional-spec.md. The current "parallel" claim was producing silently incomplete validation audits — a worse failure mode than slower runs.
- **#5 — serializing 15c→15b also lengthens Phase 4.** Same tradeoff. 15a remains parallel with the (now-serial) 15c→15b chain, so the worst-case loss is one dispatch round across the whole phase.
- **#8 — `# SKILL-DIRECTED:` marker placement collides with `# OVERRIDE:` if both appear.** Both are independent — `# OVERRIDE:` skips the 5-field validation; `# SKILL-DIRECTED:` suppresses only `escalation`. A brief carrying both is legal (the audit row records both fields). Gate code should extract them with separate greps, not a single switch.
- **#8 — adding `# SKILL-DIRECTED: product` to ~16 briefs costs a small number of prompt tokens per dispatch.** Negligible (~12 tokens × 16 dispatches ≈ 200 tokens per `/product` run); call out in `notes.md` if a future run shows measurable cost so the decision is auditable.
- **Unknown: do any other skills currently dispatch `Agent` calls that would trip `escalation`?** Grep at implementation time. If yes, those skills opt in by adding the marker — not forced; no skill is excluded from the advisory by default. The marker is a self-certification, not a free pass.
- **Audit-row field count change is additive but readers may hard-code the field set.** No known reader hard-depends (audit is consumed by `jq` queries, all field-name-keyed). Documented in `.claude/rules/delegation.md § Audit log` field-count update so the schema-bump is explicit.

## Research / citations

- **Source verification (all 6 findings)** — re-read against current code 2026-05-22:
  - #9: `.claude/skills/product/references/delegation-briefs.md` line containing `Write 3 files DIRECTLY to {{out}}/docs/: 08-system-design.md + 08-security.md + 08-data-flow.json` (Step 08 CONSTRAINTS block)
  - #4: `.claude/skills/product/SKILL.md:146` (`browser_navigate to its file:// URL`); Playwright `file:` block independently confirmed during spec 073 work
  - #2-sections: brief at `delegation-briefs.md` Step 11 (line ~296: `SKIP unit economics + sensitivity + scenario analysis`; line ~297: 6 H2 list) vs schema at `.claude/skills/product/templates/pipeline/11-cost-estimate/schema.md:36-48` (8 required + 3 conditional)
  - #3: `delegation-briefs.md § Mood-screen-writer CONSTRAINTS` (line ~481+ — mobile-first + no horizontal overflow, no single-nav rule)
  - #5 03/04: Step 04 CONTEXT (line ~100) explicitly reads `functional-spec.md` (Step 03's deliverable, line ~88)
  - #5 15b/15c: Mood-screen-writer hi-fi mode CONTEXT (line ~474) explicitly reads `fixture-spec.md`
  - #8: `.claude/hooks/delegation-gate.sh:198-216` (escalation branch); all Step 02-15 briefs declare `model: sonnet` (verified via `grep 'model:' delegation-briefs.md`, 18 hits)
- **Spec 066 § notes 2026-05-20** — partial precedent for #5 (addressed 15a but not 15b←15c)
- **Spec 075** — retired the size-ceiling; this spec is the section-set-disagreement sibling
- **OQ#8 design decision** — `docs/specs/076-product-dogfood-fixes/notes.md § Design decisions` (2026-05-22)
- **`.claude/rules/delegation.md § Override marker`** — the existing `# OVERRIDE: <reason ≥10>` grammar that `# SKILL-DIRECTED:` mirrors
