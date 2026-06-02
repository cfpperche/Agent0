# 137 — agent0-status — notes

_Created 2026-06-02._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-02 — parent — Library locates itself, not via the inspected project

`_brief-compose.sh` resolves its own directory (`_BRIEF_COMPOSE_DIR`) and uses it to find the sibling readout helpers (`reminders-readout.sh` etc.). Both tools also source the lib relative to their OWN path. This decouples "where the code lives" from "which project is inspected" (`AGENT0_PROJECT_DIR`/git root), so the tools run correctly from any CWD and from either runtime — and become testable against fixtures.

### 2026-06-02 — parent — Default-valued tunables make the lib serve both bounded and full views

The lib reads `HANDOFF_SECTION_LINES`/`REMINDER_LIMIT`/`REMINDER_TEXT_MAX` as `${VAR:-default}`. The SessionStart brief leaves the small defaults (bounded); `status.sh` sets them wide (200/999/2000) for the full untruncated view. One composition, two presentations, no fork.

## Deviations

### 2026-06-02 — parent — Promoted skill surface to spec-121 portable mid-spec

The first `spec.md` draft shipped only a Claude `/status` wrapper. Founder flagged this as under-specified for multi-runtime parity. Promoted to the portable model (canonical body + `.claude/` + `.agents/` symlinks + `runtime-capabilities.md` row + `CLAUDE.md`/`AGENTS.md` entries) so Codex gets `$status`. The lib's emit-neutrality is the enabling invariant — it keeps the brief's Claude-vs-Codex emit split out of the shared path.

## Tradeoffs

### 2026-06-02 — parent — Shared lib over independent status.sh (accepted: touching a live hook)

Chose the DRY refactor (extract from the live SessionStart hook) over an independent `status.sh` that re-implements composition. Cost: risk of regressing boot output. Bought down with a characterization test (capture → refactor → recapture → byte-identical, confirmed 1254 bytes). Worth it: eliminates a whole class of future handoff-format drift.

## Open questions

### 2026-06-02 — parent — Commit scoping vs concurrent-session contamination

At ship time the working tree also carried unrelated concurrent-session work (`/meeting` skill, `M CLAUDE.md`/`AGENTS.md`/`sync-harness.sh`). Spec 137's commit must be scoped to its own files only — must NOT bundle the meeting changes. Left for the founder to stage deliberately (see the delivery summary's commit-scope list). Two bugs were caught by the test suite during build and fixed before ship: a `PROJECT_DIR` shell-precedence bug (newline in the path → doctor false "all-missing"), and a reminders/next due-filter inconsistency.

### 2026-06-02 — parent — Cross-runtime dogfood + applied follow-ups

Ran a 6-way dogfood (claude-exec ×3 + codex-exec ×3, read-only) over `status`/`doctor`. Both runtimes independently converged on two HIGH findings → high confidence. Triaged into 3 buckets; **buckets 1 + 3 applied here, bucket 2 promoted to spec 138.**

Applied to spec-137 files this session:
- **Bucket 1 (bug):** `status.sh` `next_commands_block` no longer emits "handoff has queued Next Actions" when the handoff parks a "Nothing actionable in the queue" line there (it pointed at a section that contradicted it). Tests V8 added (suppressed-on-nothing + fires-on-real).
- **Bucket 3 (cosmetics):** `AGENT0_SKIP_GITHOOKS_HINT` alias in `_brief-compose.sh` (parity with reminders/routines); `doctor.sh` now checks `.agent0/context/rules` as a directory (`-d`) and requires exec core files to be non-empty (`-s`, presence≠function). Tests V9 added. Brief re-verified byte-identical after the lib edit.

Deferred to **spec 138** (the two HIGH judgment gaps): `status` handoff↔git reconciliation banner + in-flight-spec inference; `doctor` jq hook-contract validation with a real `broken` tier. D3 confirmed the multi-runtime core is sound — no parity work needed.

Run artifacts: `.agent0/.runtime-state/{claude,codex}-exec/*df-*/last-message.md`.
