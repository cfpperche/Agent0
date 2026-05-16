# 029 — sdd-list-in-flight — tasks

_Generated from `plan.md` on 2026-05-16. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Modify `.claude/skills/sdd/templates/spec.md.tmpl` — promote line 3 italic `_Created {{DATE}}. Status: draft._` into two lines: `_Created {{DATE}}._` followed by a blank line and `**Status:** draft`. Verify line count delta is +1 (italic became one bold line + one blank separator).

- [x] 2. Modify `.claude/skills/sdd/SKILL.md` § Subcommand: list — extend the section to cover the seven sub-additions named in `plan.md` § Files to touch:
  - (a) Status-recognition rule: a `**Status:** <value>` line in `spec.md` overrides the derived checkbox-state heuristic; applies to bare `/sdd list` output as well as `--in-flight`.
  - (b) Status semantics sub-section: enumerate the 5 status states — 4 declared (`draft`, `in-progress`, `shipped`, `superseded`) + 1 derived fallback (`derived` — the existing heuristic when no `**Status:**` line is present, reported using the current 5 sub-states `spec`/`plan`/`tasks`/`done`/`empty`).
  - (c) `--in-flight` flag: filter rule = `Status ∈ {draft, in-progress}` OR (Status absent AND derived ∈ {spec, plan, tasks} AND last git activity within the recency window).
  - (d) `--in-flight` row shape: `NNN-<slug>  [status]  N/M acceptance unchecked  last activity Yd ago  — <h1>`. Where `N` is unchecked `- [ ]` count under `## Acceptance criteria` (all bullets, all nesting depths) and `M` is the total count under that section.
  - (e) `--json` flag: emit a JSON array of objects with keys `nnn` (string, zero-padded), `slug` (string), `status` (string — one of the 5 declared or 5 derived states), `acceptance_unchecked` (integer or `null` if the `## Acceptance criteria` section is missing/malformed), `acceptance_total` (integer or `null` likewise), `last_activity_iso` (string, ISO-8601 from `git log -1 --format=%aI -- <dir>`), `h1` (string — the spec.md `# ` heading). Document the shape inline with a worked example block.
  - (f) Recency window: default 14 days; tunable via `CLAUDE_SDD_IN_FLIGHT_RECENCY_DAYS` env var (integer, days).
  - (g) Explicit inline note: `--json` is a shape-only convenience for ad-hoc agent reads — NOT a versioned wire contract; consumers that hard-depend on this shape do so at their own risk.

- [x] 3. Modify `.claude/rules/spec-driven.md` § The three artifacts — append one sentence under the `spec.md` bullet: "The `**Status:**` line near the top declares lifecycle: `draft` (not started), `in-progress` (work begun), `shipped` (acceptance criteria satisfied), `superseded` (replaced by a later spec, slug named inline)."

- [x] 4. Add a 2-week revert-check reminder to `.claude/REMINDERS.md` via `/remind add` (per Open question 1 of `spec.md` — rule-of-three caveat). Text: "Spec 029 sdd-list-in-flight — 2 weeks post-ship, check `/sdd list --in-flight` adoption; if unused, revert the template change (one line, cheap)." Due date 14 days from ship commit.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] **AC #1 (declared overrides derived):** `SKILL.md` § Subcommand: list reads, near the start, that a `**Status:**` line in `spec.md` overrides the derived checkbox heuristic for the bare `/sdd list` output too — not only under `--in-flight`. Confirm by reading.
- [x] **AC #2 (--in-flight filters out shipped and superseded):** `SKILL.md` documents the filter rule explicitly — `Status ∈ {draft, in-progress}` OR (Status absent AND derived ∈ {spec, plan, tasks} AND recent). Confirm by reading.
- [x] **AC #3 (row shape with unchecked count + last activity):** `SKILL.md` documents the row shape with `N/M acceptance unchecked` and `last activity Yd ago`. Confirm by reading.
- [x] **AC #4 (--json shape):** `SKILL.md` documents the JSON object schema with all 7 keys, the `null`-for-missing-section convention, and the "not a versioned wire contract" disclaimer. Confirm by reading.
- [x] **AC #5 (no bulk-edit of existing specs):** `git diff --stat` against the ship commit shows changes ONLY to `.claude/skills/sdd/templates/spec.md.tmpl`, `.claude/skills/sdd/SKILL.md`, `.claude/rules/spec-driven.md`, `.claude/REMINDERS.md`, and `docs/specs/029-sdd-list-in-flight/{spec,plan,tasks}.md` — NO modifications to any other `docs/specs/[0-9]*/` file.
- [x] **AC #6 (template Status line):** `grep -n '^\*\*Status:\*\*' .claude/skills/sdd/templates/spec.md.tmpl` returns one match; `grep -n 'Status: draft' .claude/skills/sdd/templates/spec.md.tmpl` (italic form) returns nothing.
- [x] **AC #7 (SKILL.md documents --in-flight + --json + Status rule):** `grep -n '\-\-in-flight\|\-\-json\|\*\*Status:\*\*' .claude/skills/sdd/SKILL.md` returns ≥3 matches covering all three terms.
- [x] **AC #8 (spec-driven.md mentions Status):** `grep -n 'draft.*in-progress.*shipped.*superseded' .claude/rules/spec-driven.md` returns one match in § The three artifacts.
- [x] **Smoke test (manual):** Author a Status line in `docs/specs/029-sdd-list-in-flight/spec.md` itself (`**Status:** in-progress` at ship time, then flip to `shipped` after commit) and run `/sdd list` mentally against the new instructions — confirm the row would render as expected and bare output picks up `[in-progress]` from declared truth.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- The italic `Status: draft` on line 3 of `spec.md.tmpl` already existed — this spec promotes it to bold-parseable rather than adding a new field. Line count delta is +1 (italic line becomes one bold line + one blank separator).
- No new files; no scripts. The skill remains instruction-driven, matching spec 028's pattern. If `--json` ever becomes load-bearing for an external hook or tool, revisit the script-vs-skill tradeoff then (see `plan.md` § Alternatives considered).
- `--in-flight` and `--json` are independent: any combination of (flag present / absent) is legal; `--json` without `--in-flight` emits the full repo state as JSON.
- The reminder added in task 4 is what makes Open question 1 of `spec.md` actually load-bearing — without it, the rule-of-three caveat is just words.
