# 046 — sdd-in-flight-notes — tasks

_Generated from `plan.md` on 2026-05-18. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Create the template** — write `.claude/skills/sdd/templates/notes.md.tmpl` with: H1 `# {{NNN}} — {{SLUG}} — notes`; short intro paragraph explaining the file's purpose (in-flight design memory; append-only; entries shaped `### YYYY-MM-DD — <author> — <one-line title>` + free-prose body); four `##` sections (`Design decisions`, `Deviations`, `Tradeoffs`, `Open questions`); one placeholder entry under each section showing the entry shape. Mirror style of existing `.tmpl` files (subtitle line `_Created {{DATE}}._`).

- [x] 2. **Extend the `/sdd new` scaffold** — edit `.claude/skills/sdd/SKILL.md`:
  - Add `cp ${CLAUDE_SKILL_DIR}/templates/notes.md.tmpl docs/specs/NNN-<slug>/notes.md` to the Step 3 `cp` block (Subcommand `new <slug>`).
  - Update Step 5 report wording so it mentions four output files instead of three.
  - Change the description-line file list `{spec,plan,tasks}.md` → `{spec,plan,tasks,notes}.md` in the frontmatter `description:` and any prose body references in this file. Do NOT change the frontmatter `argument-hint` (still `<new <slug> | refine | plan | tasks | list>`); the `notes` capacity is rule + scaffold, not a new subcommand.
  - Bump `metadata.version` `"0.1"` → `"0.2"`.

- [x] 3. **Document the fourth artifact in `spec-driven.md`** — edit `.claude/rules/spec-driven.md`:
  - Rename heading `## The three artifacts` → `## The four artifacts`.
  - After the existing `tasks.md` bullet, add a fourth bullet describing `notes.md`: purpose (in-flight design memory), four-section structure, append-only convention, entry shape (`### YYYY-MM-DD — <author> — <title>` + free body), optional in v1, distinguished from `spec.md`'s pre-flight Open Questions and `SESSION.md`'s cross-session WIP.
  - Add a one-sentence cross-reference pointing at `.claude/rules/delegation.md` § *The 5-field handoff*.

- [x] 4. **Document the delegation integration** — edit `.claude/rules/delegation.md`:
  - In or directly after § *The 5-field handoff*, add one paragraph: when `CONTEXT` references a spec dir (`docs/specs/NNN-*`), `DELIVERABLE` SHOULD include the phrase "append any in-flight decisions/deviations/tradeoffs/open-questions to `docs/specs/NNN-*/notes.md`" (verbatim or equivalent). No gate logic change; no `delegation-gate.sh` edit.

- [x] 5. **Update CLAUDE.md** — in § *Spec-driven development*, change `{spec,plan,tasks}.md` to `{spec,plan,tasks,notes}.md`. Single literal-string replacement.

- [x] 6. **Create spec 046's own `notes.md`** (meta-dogfood) — write `docs/specs/046-sdd-in-flight-notes/notes.md` populated from `notes.md.tmpl` (NNN=046, SLUG=sdd-in-flight-notes, DATE=2026-05-18) AND seed at least three real entries surfaced during this spec's design: one Design decision (e.g. `.md` over `.html` extension), one Tradeoff (e.g. four canonical sections vs free-form journal), one Open question (e.g. promotion criteria for v1→v2). Author for these initial entries: `parent`. Entries should reference `plan.md` § *Approach* and § *Alternatives considered* where applicable.

- [x] 7. **Add the REMINDERS gate** — append one line to `.claude/REMINDERS.md` using `/remind add`: "Spec 046 dogfood gate — review next 3-5 specs scaffolded after 046; if `notes.md` is non-empty AND cited in ≥3 PRs by 2026-07-01, promote to mandatory + consider delegation-gate advisory; if empty in all, revert template + rule edits. See `docs/specs/046-sdd-in-flight-notes/spec.md` Open Q2." `--due 2026-07-01`.

## Verification

_Acceptance checks tied to `spec.md` § Acceptance criteria. Each maps directly to a checklist item there._

- [x] **Verify scenario "scaffold creates notes.md"** — read `.claude/skills/sdd/SKILL.md` § Subcommand `new <slug>` Step 3 and confirm the `cp` block lists four template copies; confirm placeholder substitution (Step 4) applies to all four files. Optional sanity: scaffold a throwaway spec dir under `/tmp/sdd-test-046/` using the documented commands, confirm `notes.md` lands populated.

- [x] **Verify scenario "in-flight append by implementer"** — read `docs/specs/046-sdd-in-flight-notes/notes.md` and confirm at least three dated entries exist with the documented shape `### YYYY-MM-DD — <author> — <title>` + body, distributed across at least two of the four sections.

- [x] **Verify scenario "delegation brief references notes"** — read `.claude/rules/delegation.md` and confirm the paragraph about spec-dir CONTEXT → notes.md in DELIVERABLE is present, near or in § *The 5-field handoff*.

- [x] **Verify scenario "rule documents the artifact"** — read `.claude/rules/spec-driven.md` and confirm: heading renamed to `## The four artifacts`; fourth bullet describes `notes.md` with the documented attributes; cross-reference to `delegation.md` is present.

- [x] **Verify scenario "dogfood window opens"** — read `.claude/REMINDERS.md` and confirm a single line about spec 046's dogfood gate with `--due 2026-07-01` is present.

- [x] **Verify static facts (6 of them)**:
  - `.claude/skills/sdd/templates/notes.md.tmpl` exists, has four `## ` sections, contains `{{NNN}}`/`{{SLUG}}`/`{{DATE}}` placeholders
  - `.claude/skills/sdd/SKILL.md` mentions `notes.md.tmpl` in the cp list
  - `.claude/skills/sdd/SKILL.md` frontmatter `metadata.version` bumped to `"0.2"`
  - `CLAUDE.md` file list in § *Spec-driven development* reads `{spec,plan,tasks,notes}.md`
  - `docs/specs/046-sdd-in-flight-notes/notes.md` is non-empty (≥3 entries)
  - `spec.md` § *Acceptance criteria* boxes for the five scenarios above can be checked

- [x] **Mechanical lint pass** — `grep -rn '{{NNN}}\|{{SLUG}}\|{{DATE}}' docs/specs/046-sdd-in-flight-notes/` returns no hits (no unsubstituted placeholders escaped into populated files; the template file `notes.md.tmpl` is allowed to contain them and is excluded from this check by being outside `docs/specs/`).

- [x] **Check task ↔ spec mapping** — every scenario or static fact in `spec.md` § *Acceptance criteria* has at least one verification task above pointing at it. Re-read both files side-by-side; no orphaned scenarios.

## Notes

- The implementation order (template → SKILL → rule → delegation → CLAUDE → meta-dogfood → REMINDERS) is by dependency: the template anchors all downstream cross-references; SKILL.md links to it; the rule docs cite the SKILL; CLAUDE.md syncs the rule; the meta-dogfood demonstrates the rule once it's stable; REMINDERS gates the dogfood window.
- Task 6 (meta-dogfood) is the load-bearing test: if writing spec 046's own `notes.md` feels forced or empty, the template needs revision before declaring done. Treat it as part of the design loop, not a checkbox.
- Per `.claude/rules/research-before-proposing.md`, no further research is needed at the tasks stage — sources cited in `plan.md` § *Research / citations* cover the scope.
- The post-edit validator will not fire on any of these edits (parent agent, not sub-agent) — verification is mechanical inspection plus the throwaway scaffold sanity check in the first verification task.
