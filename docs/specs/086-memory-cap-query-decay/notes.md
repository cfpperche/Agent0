# 086 — memory-cap-query-decay — notes

_Created 2026-05-24._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-24 — parent — confirm does NOT generate journal event (spec drift corrected)

`spec.md` scenario "confirm bumps frontmatter audit fields" initially asserted that the memory-events-journal hook (spec 083) would capture confirm mutations as `update` events. Empirical verification (T16 mid-implementation) proved this WRONG: the spec 083 `PostToolUse` hook listens for `Edit` / `Write` / `MultiEdit` *tool* invocations. The Python helper writes via direct file syscalls (`open(p, 'w').write(...)`), which the hook never sees. Result: `confirm` mutations are invisible to the journal.

Acceptable as-is because:
1. `git log --follow <file>` already provides an audit trail for the mutation.
2. The journal's purpose is to track agent-invoked edits, not operator tooling.
3. Fixing it (helper appends JSONL itself) couples `memory-query-helper.py` to the journal's shape (which has its own schema in spec 083); decoupled is cleaner for v1.

Spec scenario was rewritten to reflect reality (`git log` is the audit, not the journal). If future demand surfaces a need for journal events on confirm (e.g. dashboard wants a confirmation timeline), the fix is to extend the helper to emit a JSONL line directly.

### 2026-05-24 — parent — memory-project.sh delegated to Python helper for YAML parsing

Plan said memory-project.sh would read `cap.max_line_chars` from config and add an advisory check, keeping its existing awk-based frontmatter parsing. Empirical reality: after T5 backfill, PyYAML's `safe_dump` folded long descriptions across multiple YAML lines (e.g. `agent0-purpose.md`'s description spans 2 lines). The awk parser only read the first line, producing truncated bullets in MEMORY.md.

Fix: added a `project-entries` subcommand to `memory-query-helper.py` that loads each entry via PyYAML (correctly handling folded scalars), collapses whitespace runs in `description`, and emits `<slug>\t<name>\t<description>` tab-separated lines. `memory-project.sh` consumes that and emits bullets. The old awk path remains as a degraded fallback when `python3+yaml` is absent, with an advisory.

Net change: ~30 LOC added to memory-project.sh, ~20 LOC added to memory-query-helper.py. Worth it — the projection is now correct on folded-YAML entries, and the fallback path means forks without PyYAML still get a usable (if degraded) MEMORY.md.

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
