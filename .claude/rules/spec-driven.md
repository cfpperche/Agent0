# Spec-driven development

Non-trivial work in this repo is **spec-driven**: write the intent before the code. The discipline catches half-baked thinking on cheap markdown instead of expensive diffs, and gives the next session (human or AI) a contract to verify against.

## When SDD applies

Apply for any change that meets at least one of:

- Touches 3+ files, or introduces a new module/package/service
- Changes a public API, schema, or contract another component depends on
- Has user-visible behavior change worth describing in a PR body
- Has reversibility cost (migrations, infra, destructive ops)
- Was prompted by a vague request ("add auth", "make it faster") that needs decomposition

## When to skip

Mechanical or local-only work — go straight to the edit:

- Typos, renames, formatting, lint fixes
- One-file bug fixes with obvious cause
- Dependency bumps without behavior change
- Editing existing specs / docs / configs
- Throwaway exploration in a scratch branch

When in doubt, write a spec — 5 minutes of markdown is cheap insurance.

## The three artifacts

Specs live under `docs/specs/NNN-<slug>/` where `NNN` is zero-padded sequential (001, 002, …). Each spec has three files:

- **`spec.md`** — the *what* and *why*. Intent, acceptance criteria as a checklist, non-goals, open questions. This is the contract — hand it to a stakeholder or paste it into the PR body.
- **`plan.md`** — the *how*. Approach, files to touch, alternatives considered and rejected (with reasoning), risks and unknowns. This is the engineering judgment.
- **`tasks.md`** — the *do*. Numbered checklist of concrete execution steps. This is what Claude (or you) works through one at a time, checking off as it goes.

Specs are **git-tracked** — they are the project's design memory. Don't gitignore them. Update them when the plan shifts; the file history *is* the audit trail.

## Workflow

1. **Spec** — `/sdd new <slug>` scaffolds the three files. Fill `spec.md` first, alone. Don't plan how until you've nailed what.
2. **Plan** — `/sdd plan` drafts `plan.md` from `spec.md`. Review and edit. Stop here if assumptions need user confirmation.
3. **Tasks** — `/sdd tasks` drafts `tasks.md` from `plan.md`. Each task should be small enough that completing it is unambiguous.
4. **Implement** — work `tasks.md` top-to-bottom. Check off as you go. If a task reveals the plan is wrong, update `plan.md` *before* continuing.
5. **Close** — when the spec is delivered, the spec dir stays — it's the historical record. Reference it from the commit / PR.

## Relationship to other rules

- **`research-before-proposing.md`** — research happens *during* spec phase, before `plan.md` is locked. Cite sources in the spec or plan.
- **`session-handoff.md`** — if a spec is mid-flight at end of session, mention the active spec dir in `SESSION.md` so the next session resumes from `tasks.md`.

## Escalation path

For larger projects (multi-week features, multiple contributors), this convention-light approach has limits. Lightest opt-in upgrade: [OpenSpec](https://openspec.dev/) — `npm i -g @fission-ai/openspec && openspec init` adds delta-spec tracking (`ADDED` / `MODIFIED` / `REMOVED`) and proposal review on top of plain markdown. Doesn't conflict with `docs/specs/`; just adds an `openspec/` tree alongside.

Heavier tools (spec-kit, BMAD) are an option but bring Python/multi-agent overhead. Reach for them only if the project actually needs them.
