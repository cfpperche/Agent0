# 181 — claude-exec-run-bounds — notes

_Created 2026-06-09._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` of the delegated worker.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-09 — parent — Default bounds and no unbounded escape hatch

Adopted the spec's recommended defaults: `--timeout 600` and `--progress-interval 30`. `--timeout 0` is refused in v1 instead of becoming an unbounded escape hatch, because the defect this spec fixes is the helper claiming a bounded subprocess while allowing silent indefinite work. Callers can still choose a larger positive timeout explicitly.

The implementation uses the platform `timeout` command around the exact Claude argv and a separate wait loop for heartbeat output. This keeps the child termination behavior conventional (`124` on helper-owned timeout) while preserving the existing JSON/JQ extraction and metadata path.

### 2026-06-09 — parent — Budget guard, not hard billing ceiling

The live smoke used `--max-budget-usd 0.01` and returned Claude's native `error_max_budget_usd`, proving the helper forwards the guard and preserves the non-success result. The same stdout reported `total_cost_usd: 0.056673600000000005`, so the implementation and docs must not claim a hard cost cap. V1 treats the flag as a native Claude budget guard plus metadata/evidence, not as Agent0-owned billing enforcement.

## Deviations

## Tradeoffs

## Open questions

## Verification log

### 2026-06-09T15:32:19Z — pass (1/1) — source: tasks.md
- `bash .agent0/tests/claude-exec-skill/run-all.sh && bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/claude-exec` — pass
