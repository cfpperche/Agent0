---
description: Spec-driven development scaffolding. Use when starting non-trivial work (3+ files, new module, API/schema change, vague request needing decomposition). Creates and progresses specs/NNN-slug/{spec,plan,tasks}.md per the spec-driven workflow. Subcommands - new <slug>, plan, tasks, list. See .claude/rules/spec-driven.md for when SDD applies and when to skip.
argument-hint: <new <slug> | plan | tasks | list>
---

# /sdd — spec-driven development

Scaffolds and progresses spec folders for non-trivial work. Each feature gets `specs/NNN-<slug>/` with three files: `spec.md` (what + why), `plan.md` (how), `tasks.md` (do).

See `.claude/rules/spec-driven.md` for the workflow rationale and when to apply / skip SDD.

## Argument parsing

User invokes as `/sdd <subcommand> [args]`. The raw argument string is `$ARGUMENTS`. Parse it yourself: split on whitespace, first token is the subcommand (`new` / `plan` / `tasks` / `list`), the rest are subcommand args. Do not rely on `$1` / `$2` — harness substitution for those is inconsistent across invocation paths (slash vs Skill tool); always parse `$ARGUMENTS` instead.

Raw invocation: `$ARGUMENTS`

## Subcommand: `new <slug>`

Scaffold a new spec dir. Parse `$ARGUMENTS`: first token must be `new`, second token is the slug (kebab-case, e.g. `auth-rewrite`).

1. **Validate** — refuse with a clear message if:
   - slug is empty
   - slug doesn't match `^[a-z][a-z0-9-]*$` (kebab-case starting with a letter)
   - `specs/NNN-<slug>/` with that slug already exists (suggest a different slug or `/sdd list`)

2. **Find next NNN** — scan `specs/` for existing `NNN-*` dirs (ignore hidden files like `.gitkeep`), take the highest NNN, increment. Start at `001` if none exist. Zero-pad to 3 digits.

3. **Create the dir and copy templates** — use the templates in `${CLAUDE_SKILL_DIR}/templates/`:
   ```
   mkdir -p specs/NNN-<slug>
   cp ${CLAUDE_SKILL_DIR}/templates/spec.md.tmpl  specs/NNN-<slug>/spec.md
   cp ${CLAUDE_SKILL_DIR}/templates/plan.md.tmpl  specs/NNN-<slug>/plan.md
   cp ${CLAUDE_SKILL_DIR}/templates/tasks.md.tmpl specs/NNN-<slug>/tasks.md
   ```

4. **Substitute placeholders** in each created file — replace literally:
   - `{{SLUG}}` → `<slug>`
   - `{{NNN}}` → the zero-padded number
   - `{{DATE}}` → current date in `YYYY-MM-DD` (UTC)

5. **Report** — output the three paths and tell the user the next step is to fill `spec.md`. Do NOT auto-fill it; the user owns intent. Suggest they describe the change conversationally and you can draft `spec.md` from that, but only after they say so.

## Subcommand: `plan`

Draft `plan.md` from an existing `spec.md`. No positional argument — operate on the most recent spec dir (highest NNN) unless the user has already named a specific one in conversation.

1. **Locate target** — find the latest `specs/NNN-*/` dir. If multiple are in flight and ambiguous, ask which one.
2. **Read `spec.md`** — refuse if it still has unfilled template placeholders (`{{` substrings) or is essentially empty. Tell the user to fill spec first.
3. **Draft `plan.md`** — preserve the existing template section headers; fill them from `spec.md` + your understanding of the codebase. For "Alternatives considered" you MUST list at least one rejected option with reasoning — if there genuinely was no alternative, say so explicitly ("no real alternatives; only viable approach is X because Y").
4. **Cite research** — if the spec or plan involved web research or codebase exploration, link the sources in the plan. This satisfies `research-before-proposing.md`.
5. **Report** — output `plan.md` path. Tell the user to review and confirm before `/sdd tasks`.

## Subcommand: `tasks`

Generate `tasks.md` from `plan.md`. Same target-selection rule as `plan`.

1. **Locate target** — find the latest spec dir (or the one in conversation).
2. **Read `plan.md`** — refuse if it has unfilled template placeholders.
3. **Decompose into tasks** — each task should be:
   - Small enough that completion is unambiguous (passes/fails clearly)
   - Independently checkable (testable, observable, or produces a concrete artifact)
   - Ordered by dependency — earlier tasks unblock later ones
   - Numbered (`1.`, `2.`, …) with checkbox prefix (`- [ ]`)
4. **Include verification** — the last 1-2 tasks should be acceptance checks against the criteria in `spec.md` (run tests, verify behavior, sanity checks).
5. **Report** — output `tasks.md` path. Tell the user implementation is now mechanical: work the tasks top-to-bottom, check off as completed, update `plan.md` if any task reveals plan is wrong.

## Subcommand: `list`

List all specs in the repo with a one-line status each.

1. Scan `specs/` for `NNN-*/` dirs (sorted by NNN ascending).
2. For each, emit one line: `NNN-<slug>  [status]  — <h1 of spec.md, or "(no spec)" if empty>`.
3. Status heuristic:
   - `spec` — `spec.md` has content but `plan.md` still has placeholders
   - `plan` — `plan.md` filled but `tasks.md` still has placeholders
   - `tasks` — `tasks.md` filled, some unchecked boxes remain
   - `done` — all checkboxes in `tasks.md` are checked (`- [x]`)
   - `empty` — `spec.md` still has `{{` placeholders

## Unknown subcommand

If the first token of `$ARGUMENTS` is missing or not one of `new`, `plan`, `tasks`, `list`, refuse with a one-line usage hint:

```
/sdd <new <slug> | plan | tasks | list>
```

## Notes

- Specs are **git-tracked** — they are project memory, not scratch. Don't gitignore them.
- The skill provides *structure*; you (Claude) provide *content*. Don't auto-fill `spec.md` — the user owns intent.
- If the user describes a change conversationally and SDD applies (per `.claude/rules/spec-driven.md`), offer to run `/sdd new <slug>` rather than diving into code.
