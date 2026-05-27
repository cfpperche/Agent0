# 096 — maintainer-rules-to-memory — notes

_Created 2026-05-27._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-27 — parent — pre-move cross-ref inventory

Phase 1 grep results. Two queries, scoped to live surfaces (`hooks/`, `tools/`, `memory/`, `routines/`, `rules/`, `tests/`, `settings.json`, `CLAUDE.md`, `AGENTS.md`); session-state, audit JSONL, and runtime-state README excluded as ephemeral.

**Runtime file-read probe (task 2 — blocker check):** `grep -rn -E '(cat|head|tail|<) [^|]*\.claude/rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .claude/` → **empty**. No hook or tool runtime-reads the rule files. Move is safe at the path-string level; no redirect machinery needed.

**Path-pointer rewrites needed (Phase 3):**

| File | Line(s) | Reference |
|---|---|---|
| `.claude/hooks/governance-gate.sh` | 23 | comment: `see .claude/rules/hook-chain-latency.md` |
| `.claude/hooks/runtime-pre-mark.sh` | 30 | comment: `see .claude/rules/hook-chain-latency.md` |
| `.claude/hooks/rule-load-debug.sh` | 9 | header pointer: `.claude/rules/rule-load-debug.md` |
| `.claude/tools/bench-hooks.sh` | 23 | comment: `see .claude/rules/hook-chain-latency.md` |
| `.claude/routines/hook-chain-bench.md` | 22 | body: `Read .claude/rules/hook-chain-latency.md § Optimization techniques` |
| `.claude/memory/hook-chain-maintenance.md` | 12, 83 | body + cross-references: `.claude/rules/hook-chain-latency.md` (companion) |
| `.claude/memory/cc-platform-hooks.md` | 145, 150, 154 | body + cross-references: refs to `.claude/rules/rule-load-debug.md` (×2) + `.claude/rules/compaction-continuity.md` (×1) |
| `.claude/memory/capacity-spec-index.md` | 54, 55 | table cells: bare filenames `compaction-continuity.md` / `rule-load-debug.md` — still valid post-move, updated for clarity |
| `.claude/tests/hook-chain-latency/03-regression-fires.sh` | 11 | comment: `see .claude/rules/hook-chain-latency.md § Regression check` |

**False matches (no rewrite needed):**

- `.claude/memory/propagation-hygiene.md:66` — historical "stripped 2026-05-21" prose referencing the rule paths as past leak sites. Documentary; no live pointer.
- `.claude/tools/probe.sh:181` — `LOG="$PROJECT_DIR/.claude/.rule-load-debug.jsonl"` — JSONL audit-log filename, not a rule pointer. Leave alone.
- `.claude/settings.json:212` — registered hook command path `.claude/hooks/rule-load-debug.sh`. The hook script itself. Leave alone.
- Test scripts matching on filenames in their `#` header comment — self-pointers, not cross-refs. Leave alone.

**Entrypoint sections to delete (Phase 4):**

- `CLAUDE.md:99` — `## Rule load debug` (header + body)
- `CLAUDE.md:115` — `## Hook chain latency` (header + body)
- `AGENTS.md:79` — `## Rule load debug` (header + body)
- `AGENTS.md` — `## Hook chain latency` is absent (pre-existing drift; spec incidentally closes by not propagating it)

**Net surface:** 9 files to rewrite + 3 rule files to delete + 2 entrypoint files to prune + 1 routing-tree clarification in `memory-placement.md`. No skill files affected. No `docs/specs/**` updates (per spec § Open Q3 — historical mentions stay intact).

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
