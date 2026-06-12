# 205 — product-honesty-and-fit — notes

_Created 2026-06-12._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-12 — parent — spec number 205, not 186

The dir scan suggested 186, but 186-204 were the Tachyon specs (removed at e8aa5d7 when Tachyon graduated to its own repo) and the git log still cites them ("close spec 204"). Reusing the range would collide with history; numbering continues at 205.

### 2026-06-12 — parent — concept gate is judge-free by design

`gate_concept` fires immediately after Step 01, BEFORE any quality-judge run — the founder's own read of the concept brief is the input. Wiring a judge in front of it would delay the cheapest redirect point behind an opus/sonnet call, defeating its purpose.

### 2026-06-12 — parent — Step 06 OST consumes the register with traveling confidence tags

The spec only said value rows "seed OST"; implementation pins the provenance tag shape to `[register: A<N>, confidence: <level>]` (replacing `[interview: <subject>]`) plus an explicit "never launder a low-confidence bet into an evidenced opportunity" constraint — the laundering risk was the whole motivation for Change 1.

### 2026-06-12 — parent — non-screen per-category minimum defaults to 1

`product-forms.md` ships first-cut category sets for the four non-screen forms with min 1 route per category (vs the screen-app's calibrated 3-auth/2-admin minimums). Deliberately loose: no dogfood data exists for those forms; a weak ruler degrades to a weaker completeness check, never a broken pipeline. Calibrate when the first non-screen run lands.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-06-12 — parent — pre-existing skill-validator failure fixed in passing

`validate.sh .claude/skills/product` failed at HEAD (before this spec): `argument-hint: "<idea>" --out=...` was never valid YAML (rule1), masking everything downstream. Fixed by single-quoting the value; the expanded v0.6.0 description then tripped rule4 (>1024 chars) and was trimmed. Not in plan.md's file list as a change, but required to reach the spec's verify gate. rule8 (body ~12k tokens > 5k recommended) is pre-existing and advisory — body size predates this spec.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-06-12 — parent — batched judge writes per-unit files, summary only in-message

One judge call returning N verdicts raises the malformed-output risk; mitigated exactly as plan.md proposed — the brief mandates one verdict FILE per unit (paths unchanged from v0.5.0) so the orchestrator merge path is identical, and the in-message array is only a human-readable trace. Gave up: a single combined verdict file (simpler to read); kept: the unchanged `quality_verdicts` merge + re-judge-overwrites-key semantics.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### 2026-06-12 — parent — Change-2 measurement run is residual

The judge model mix (P1/P3 sonnet, P2/P4 opus) ships as PROVISIONAL per `quality-judge.md § Measurement protocol`; adoption confirms only after the next real `/product` dogfood run records that sonnet batches still catch the "streak 17 vs 8" inconsistency class. Owner: maintainer, at the next dogfood. A reminder was filed via /remind.

## Verification log

### 2026-06-12T15:44:47Z — pass (1/1) — source: tasks.md
- `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product && bun test ./.claude/skills/product/scripts/staleness-check.test.ts` — pass
