# 060 — harness-gaps-2026

_Created 2026-05-19._

**Status:** shipped _(2026-05-31: every §A/§B row dispositioned — the tracker's defined acceptance. §A all `→ NNN`/`closed`; §B all `→ NNN`/`closed`/`deferred`. A4→131, A5/A7 closed this date. Next competitive audit is a fresh spec, scheduled 2026-08-19.)_
**Type:** umbrella

## Intent

Aggregator for the 2026 competitive harness audit. Web research surfaced gaps between Agent0 and contemporary harnesses (Codex CLI, Claude Code 2026, Hermes Agent, Goose, OpenCode, Spec-Kit, BMAD, OpenSpec) plus the cross-tool `AGENTS.md` standard. Each row in the gap matrix below either gets a follow-up spec (linked) or an explicit close-decision (with reason). This spec ships nothing on its own — it is a tracking artifact whose acceptance state is the closure of every row.

The audit ran 2026-05-19; sources cited in `plan.md` § Research. The frame is the same one that justified the existing discipline gates: Agent0 stays lightweight (bash-zero-dep capacities, discipline-first) and only adopts features whose ROI clears the rule-of-three demand-test from `.claude/memory/feedback_speculative_observability.md`.

## Acceptance criteria

- [ ] **Scenario: every §A row is resolved**
  - **Given** the gap matrix in this spec lists 8 "standard but missing" rows
  - **When** the umbrella is moved to `shipped`
  - **Then** each row has either a `→ NNN` follow-up spec link OR a `closed: <reason>` marker inline

- [ ] **Scenario: every §B row is resolved**
  - **Given** the gap matrix lists 9 "emerging" rows
  - **When** the umbrella is moved to `shipped`
  - **Then** each row has either a `→ NNN` link OR `closed: <reason>` OR `deferred: <re-evaluate condition>`

- [ ] **Scenario: §C is informational only**
  - **Given** the matrix lists "investigated and discarded" rows
  - **When** the umbrella is reviewed
  - **Then** §C requires no action — discards are documentation, not work items

- [x] `.claude/rules/spec-driven.md` documents the `**Type:** <value>` convention: omitted = default feature/refinement spec, `umbrella` = aggregator (no implementation; tracks closure of child rows)

- [x] Follow-up specs 061/062/063 are scaffolded (top-3 picks by ROI: small esforço + high priority)

## Non-goals

- Implementing any gap directly in this spec — child specs do that work
- Re-running the competitive research (sources frozen in `plan.md`; next audit gated by rule-of-three on user-reported drift)
- Forcing every gap to ship — explicit close-decision is a valid outcome
- Expanding `**Type:**` to other values (`bugfix` / `refactor` / `research`) — defer until 3+ specs demand the distinction
- Adopting `AGENTS.md` cross-tool standard from this umbrella (its own row deserves its own spec when prioritized)

## Open questions

- [ ] Should umbrella specs have their own lifecycle state (`shipped` when all child rows closed) or stay `in-progress` until manually marked? Proposed: auto-`shipped` when all rows have outcomes — but no enforcement, just convention.
- [ ] Does the `umbrella` type ever stack with `superseded`? E.g. a v2 umbrella for next-cycle audit — likely yes, treated like any other spec succession.

## Context / references

- Audit conversation 2026-05-19 (research delegated via general-purpose agent, opus model)
- Top-3 picks (alta prioridade + esforço S/M):
  - **061** → SubagentStop hook (closes delegation audit row) — _shipped 2026-05-21_
  - **062** → `/goal` skill — _closed 2026-05-19: superseded by CC native `/goal` (2.1.144+)_
  - **063** → worktree-isolated sub-agents — _shipped 2026-05-21 (Option B redesign — discipline on top of CC native worktrees)_
- `.claude/rules/spec-driven.md` § The four artifacts — convention being extended
- `.claude/memory/feedback_speculative_observability.md` — gates re-evaluation of §B deferrals

## Gap matrix

### §A — Standard but missing (8 rows)

| # | Gap | Canonized by | Priority | Esforço | Outcome |
|---|---|---|---|---|---|
| A1 | `/goal` primitive (done-state contract + auto-loop at user→main) | Codex CLI 0.128+; Claude Code v2.1.139+ | Alta | M | **closed**: superseded by CC native `/goal` (2.1.144+ binary confirms surface); see `docs/specs/062-goal-skill/spec.md` § Closure |
| A2 | Worktree-isolated sub-agents (6th handoff field `ISOLATION: worktree`) | Claude Code native | Alta | M | **→ 063** — shipped 2026-05-21 |
| A3 | `SubagentStop` hook closing delegation audit row | Claude Code 2026 (27+ events) | Alta | S | **→ 061** — shipped 2026-05-21 |
| A4 | `AGENTS.md` cross-tool standard (CLAUDE.md ↔ AGENTS.md sync) | Linux Foundation Agentic AI | Média | S | **→ 131** (shipped 2026-05-31): `harness-entrypoint-sync` closes both Gap A (shared index byte-identity enforced by `check-instruction-drift.sh`) and Gap B (always-on `AGENT0:PROJECT` mirror into both entrypoints via `sync-harness.sh`). Earlier groundwork in specs 095/123/128/129. |
| A5 | `PermissionRequest` hook (dynamic GREEN/YELLOW/RED policy) | Claude Code 2.0.45+ | Média | S | **closed** (2026-05-31): deferred until demand. No concrete pain in ~3 months — the existing `governance-gate` / `secrets-preflight` / `delegation-gate` PreToolUse floor covers the real cases, and rule-of-three (`feedback_speculative_observability.md`) is unmet for a dynamic-policy layer on top. Reopen via a fresh spec if a workflow surfaces a need the static gates can't express. |
| A6 | Cost/token observability per-delegação in audit JSONL | Hermes Agent; Claude Code `/cost` v2.1.92+ | Média | S | **closed** (2026-05-21): `SubagentStop` payload carries no cost/token field (spec 061 notes § payload matrix), so this is not the "S" effort estimated; CC `/cost` covers the user-facing need; rule-of-three unmet. Reopen via a fresh spec if real demand surfaces |
| A7 | Eval/golden-test harness for `/product`/`/sdd` regression | DeepEval, Promptfoo, Braintrust | Média | M | **closed** (2026-05-31): covered by work shipped after the 2026-05-21 re-eval — **075** (rubric-based per-step quality judge for `/product`, scope-aware right-sizing, `fail` → BLOCKED/iterate teeth) + **087** (`## Eval Scenarios` happy/minimal/adversarial as a DONE_WHEN rubric, re-read before declaring done, across `/sdd` `/product` `/skill`). The eval-discipline gap A7 named is filled in-run; a separate golden-output regression harness is unjustified for ephemeral-fork dogfood. Reopen if in-run judging proves insufficient. |
| A8 | Delta-spec tracking convention (ADDED/MODIFIED/REMOVED in `spec.md`) | OpenSpec | Baixa | S | **closed** (2026-05-21): delta-spec tracking already covered by the OpenSpec escalation path in `spec-driven.md` § Escalation path |

### §B — Emerging, worth watching (9 rows)

| # | Gap | Canonized by | Priority | Esforço | Outcome |
|---|---|---|---|---|---|
| B1 | `SubagentStart`/`SubagentStop` lifecycle hooks (related to A3 but broader) | Claude Code 2026 | Alta | S | folded into 061 — close as duplicate |
| B2 | InstructionsLoaded-driven rule analytics (histogram of rule load frequency) | (extension of own `rule-load-debug.sh`) | Baixa | S | deferred: re-evaluate when rule count > 30 |
| B3 | Agent-as-peer / pub-sub channels | Claude Code Channels Q1 2026 | Baixa | L | deferred: rule-of-three on orchestration demand |
| B4 | Persona/SOUL.md per sub-agent (`.claude/personas/<role>.md`) | Hermes Agent SOUL.md | Média | S | **closed** (2026-05-22): explored as spec 074 (`subagent-personas`, drafted then killed). Web research — persona/role-prompting does not improve performance and over-constrains capable models; the 2026 frame is context-engineering, which Agent0's 5-field handoff already is. The legitimate kernel (role-appropriate output) is served by per-dispatch `CONSTRAINTS`. Reasoning + sources in notes.md (2026-05-22). |
| B5 | Honcho-style dialectic memory (peer-modeling, background reasoning loop) | Honcho | Baixa | L | **closed**: heavy infra (FastAPI server) conflicts with bash-zero-dep frame |
| B6 | Cross-fork bidirectional memory sync | (no canonical) | Baixa | M | **closed**: one-way is conscious design (see `memory-placement.md`) |
| B7 | `UserPromptExpansion` hook (rewrites prompt with DONE-state inline) | Claude Code 2026 | Baixa-Média | S | folded into 062 — natural surface for `/goal` |
| B8 | `notes.md` sub-agent integration enforcement (validator checks append) | Spec 046 (parcial) | Média | S | **deferred** (2026-05-21): enforcement is contingent on spec 046's 2026-07-01 `notes.md` dogfood gate — re-evaluate after it resolves |
| B9 | Constitution / immutable principles as transversal gate | Spec-Kit | Baixa | S | **closed**: cerimônia risk; Agent0 prefers skip-categories + `# OVERRIDE` |

### §C — Investigated and discarded (8 rows, informational only)

| # | Discarded | Reason |
|---|---|---|
| C1 | BMAD 12-agent specialized cast (Analyst/PM/Architect/Dev/QA/Orchestrator) | Duplicates `/product` 15-step with weaker ergonomics; reinvents orchestration layer that delegation gate already covers |
| C2 | Goose recipes + sub-recipes composition | `.claude/skills/` already provides this; MCP-UI widgets are CLI-first antipattern |
| C3 | Pi RPC mode (subprocess embedding) | Agent0 IS the harness, not a meta-orchestrator over external harnesses |
| C4 | OpenCode 75+ LLM providers / multi-provider credentials | Runtime concern, not harness-discipline concern; inherited from Claude Code |
| C5 | MCP-UI visual widgets (Goose desktop) | Explicit antipattern: Agent0 is CLI-first, hooks are bash |
| C6 | Cursor Design Mode (mockup → impl) | Vertical-specific; `/product` already covers design system via discovery |
| C7 | Real-time agent dashboards (Braintrust/Langfuse) | Violates `feedback_speculative_observability.md` rule-of-three |
| C8 | Spec-Kit constitution as gate transversal | Cerimônia risk vs Agent0's skip-categories + override marker |

## Future audits

- Re-run competitive harness audit quarterly (next: 2026-08-19)
- Add reminder to `.claude/REMINDERS.md` after this spec's first child spec ships, so the audit cadence has an owner
