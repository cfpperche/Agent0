# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-22 — spec 077 shipped & committed; spec 078 planned.** Branch `spec-077-product-validation-framing` (off `main`, not pushed, not merged).

- **077 — SHIPPED + COMMITTED.** Commit `89d81f2` (`feat`, 28 files): `/product` step 4 renamed "UX Testing" → "Validation" (`git mv 04-ux-testing` → `04-validation`, history preserved) + a new `contrast` quality-criterion on step 15b. Dogfooded in an ephemeral `/tmp` project (3 real `Agent` dispatches); `build-report.test.ts` 25/25. Spec `shipped`, 7/7 acceptance.
- **078 — PLANNED, not implemented.** `docs/specs/078-product-validation-findings-criterion/` — `spec.md` + `plan.md` filled, status `draft`. Fixes a pre-existing `/product` bug the 077 dogfood surfaced: `quality-checklist.md § 04`'s `findings` criterion demands YAML frontmatter unconditionally, but projected-mode audits are told to omit it → every standard-tier (projected) run false-fails the `04-validation` judge. `tasks.md` NOT generated yet.
- **075** — task 14 still partial (carryover, untouched this session).

## WIP — resume point

**078 is planned, not implemented.** Next: `/sdd tasks` on 078, then implement — a single-file reword of the `findings` criterion in `quality-checklist.md § 04` (grade the unconditional markdown `## Findings` table as the core; scope the YAML-frontmatter expectation to measurable-mode audits). Validate via a dogfood: dispatch the `04-validation` judge against a projected report (expect `findings: pass`) + a measurable report missing frontmatter (expect `concern`/`fail`).

## Next steps

1. **078** — `/sdd tasks`, then implement + dogfood-validate.
2. **Branch `spec-077-product-validation-framing`** carries 077 (committed) + the 078 spec scaffold — decide merge to `main` / open a PR when 078 lands too, or split.
3. **075 task 14** — full `/product` dogfood (carryover).
4. **076** — founder resolves OQ#8 before `/sdd plan`.
5. Dated reminders: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.

## Decisions & gotchas

- **078 is a single-file fix.** Reword the `findings` criterion in `quality-checklist.md § 04`; the YAML frontmatter stays `schema.md`-optional. Rejected alternative: making the frontmatter unconditional (contradicts the deliberate projected-mode design). See `078/plan.md`.
- **077 dogfood method** — representative slice: 3 real `Agent` dispatches in an ephemeral `/tmp` project, not a full 15-step run. Spec scenario 3 sanctions the representative-advance form. See `077/notes.md`.
- **Verification grep must use a broader pattern than the site-list grep** — the 077 sweep's lowercase-`ux-testing` site list missed `(UX testing)` capitalized; the case-insensitive verification grep caught it.
- **`secrets-scan` hook blocks compound `git add && git commit`** — run them as separate Bash calls. `git commit -F-` heredoc works fine.
- **`governance-gate` blocks `rm -rf`** (combined `-r`+`-f`) — use `rm -r` without `-f`.

## Carryover (orthogonal — not touched this session)

- **075 task 14** — full `/product` dogfood pending (scenarios 3-6); pairs with the "069 live validation" reminder.
- **076 product-dogfood-fixes** — scaffolded, OQ#8 blocks `/sdd plan`.
- `docs/specs/074-subagent-personas/` — untracked draft (persona/role-prompting killed on research grounds; another session's WIP — leave it).
- `.claude/REMINDERS.md` items per startup readout.
