# 028 — sdd-refine-interview — plan

_Drafted from `spec.md` on 2026-05-14. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add `refine` as a fourth-and-a-half subcommand to the existing `/sdd` skill — method ported from anthill's archived `anthill-feature-refiner`, adapted to Agent0's artifacts. The work is documentation-only: no hooks, no validators, no code. Three edits and two new reference files.

The `refine` subcommand conducts a five-step discovery interview: (0) silent context load, (1) brief grounded opening, (2) 3-6 adaptive discovery rounds drawing on a ported question bank, (3) user-ratified synthesis, (4) write the synthesis into the existing `spec.md.tmpl` structure, (5) close with a self-assessed quality score and a handoff pointer to `/sdd plan`. It accepts three entry shapes — `/sdd refine "<idea>"` (fresh), `/sdd refine NNN` (refine existing), `/sdd refine` (latest spec dir) — and at the synthesis step the user can decline to write a spec dir, getting the synthesis inline only ("just the summary" exit).

The five open questions from `spec.md` are resolved as follows: **(Q1)** port *both* anthill's `checklist.md` (trimmed to Agent0 artifacts) and the weighted quality-score table (the table lives inline in `SKILL.md` Step 5, the checklist as a reference file); **(Q2)** adopt the 🔒/🔓/🟢 freedom annotations per step, matching the anthill source; **(Q3)** `refine` *proposes* a kebab-case slug derived from the idea, user confirms or overrides at the synthesis step — unlike `new`, which requires the slug up front, because `refine` from-scratch hasn't scoped the feature yet when invoked; **(Q4)** the silent context-load reads CLAUDE.md, `.claude/rules/*.md`, `.claude/memory/MEMORY.md` (lazy index, then specific files as relevant), the `docs/specs/` directory listing (titles only, not full bodies), and recent `git log` — web research per `research-before-proposing.md` is permitted *during* the discovery rounds (grep/read repo first, web second, ask last), not in the silent step; **(Q5)** when the target spec dir already has a filled `plan.md`/`tasks.md`, `refine` warns ("refining intent after planning started — re-run `/sdd plan` afterward to resync") but does not block.

Order: write the two reference files first (they are self-contained), then the `SKILL.md` subcommand section (references them), then the `spec-driven.md` workflow update (smallest, names the new step).

## Files to touch

**Create:**
- `.claude/skills/sdd/references/question-bank.md` — the 56-question / 6-category discovery bank ported from anthill, stripped of anthill-specific product references (ConsultaHub, Stripe Connect examples, etc.). Categories kept verbatim: problem validation, scope & boundaries, architecture & data, external integrations, UX, tradeoffs & risks. (Anthill's bank has a 6th "business impact" category — keep it; forks building products will use it, and it is harmless for harness work.)
- `.claude/skills/sdd/references/checklist.md` — self-review checklist ported from anthill's `checklist.md`, trimmed: drop rows referencing anthill-only artifacts (PRD, ADR-as-separate-file), keep Context / Discovery quality / Synthesis / Output quality / Integrity groupings, re-point "output follows the template" at our `spec.md.tmpl`.

**Modify:**
- `.claude/skills/sdd/SKILL.md` — (a) add `## Subcommand: refine` between `new` and `plan` with the five-step process, freedom annotations, the resumability check, the three entry shapes, the inline quality-score table in Step 5, and references to the two new files; (b) add `refine` to the argument-parser subcommand enumeration; (c) add `refine` to the unknown-subcommand usage hint (`/sdd <new <slug> | refine [...] | plan | tasks | list>`); (d) update the `argument-hint` frontmatter line.
- `.claude/rules/spec-driven.md` — in § Workflow, insert `refine` as an optional Step 0 ("discovery") that precedes filling `spec.md`; note it is opt-in and especially suited to the "vague request" trigger already named in § When SDD applies.

**Delete:**
- _None._

## Alternatives considered

### Standalone `/refine` skill

Rejected. Agent0 has a small skill surface and all spec work lives under `/sdd`. A separate `/refine` would be orphaned — the user would have to independently know it exists *and* that it feeds SDD — and it would not chain naturally into `/sdd plan`. The subcommand keeps the mental model "spec work = `/sdd`" intact. The one property a standalone skill has — "invocable at any point" — is preserved by the three entry shapes (especially the "just the summary" inline exit), so nothing is lost.

### Fold discovery into `/sdd new`

Rejected. It breaks the single-responsibility of `new` (scaffold), makes `new` do two unrelated things, and structurally cannot refine an *existing* spec — the resumability case from `spec.md` scenario 3. It also kills standalone discovery (interview without committing to a dir).

### Port anthill's 12-section feature-spec-template

Rejected. Our `spec.md.tmpl` (5 sections) is the contract `/sdd plan` consumes — replacing it is out of scope and would ripple into `plan`/`tasks`. The architecture, data-model, and implementation-plan detail anthill crams into its spec template is exactly what *our* `plan.md` is for. `refine` fills the existing template; the Gherkin scenarios anthill surfaces map cleanly onto our `Scenario: … Given/When/Then` sub-bullet shape.

## Risks and unknowns

- **SKILL.md bloat.** `refine` will be the largest subcommand section. Mitigation: the question bank and checklist live in `references/` (loaded on demand), so `SKILL.md` carries only the process steps + the compact quality-score table.
- **Anthill product references leak through the port.** The question bank and checklist contain ConsultaHub / Stripe Connect / PRD / ADR-file examples. Mitigation: explicit strip-and-re-point pass during the create step; the spec's acceptance criterion already calls this out.
- **Interview length vs Agent0's "cheap markdown" ethos.** 3-6 rounds could feel heavy for a convention-light repo. Mitigation: `refine` is opt-in; convergence detection plus the 6-round cap (deep mode opt-in only) bounds it; the "just the summary" exit keeps it lightweight when that is all the user wants.
- **Fork propagation.** `.claude/skills/` and `.claude/rules/` are both in the sync-harness manifest, so `refine` (skill + references + rule update) ships to forks automatically — desired, and consistent with how the rest of `/sdd` propagates. No manifest change needed; confirm `.claude/skills/sdd/references/` is covered by the existing `.claude/skills/` glob (it is — sync-harness scopes the whole `.claude/skills/` tree).
- **Unknown:** whether `refine`'s silent context-load should also read fork `.claude/memory/<topic>.md` files beyond `MEMORY.md`. Deferred — v1 reads the `MEMORY.md` index and pulls specific files only when a round needs them, matching the lazy-read discipline in CLAUDE.md § Memory.

## Research / citations

- Source skill (archived, read-only): `/home/goat/anthill/.claude/skills/anthill-feature-refiner/SKILL.md` + `references/{question-bank,feature-spec-template,checklist,anti-patterns}.md` — studied in full this session.
- `.claude/skills/sdd/SKILL.md` — the skill being extended; current subcommand structure and argument-parsing convention.
- `.claude/skills/sdd/templates/spec.md.tmpl` — the 5-section target structure `refine` fills.
- `.claude/rules/spec-driven.md` — § Workflow and § When SDD applies; the rule `refine` slots into.
- `.claude/rules/research-before-proposing.md` — governs the grep-then-web-then-ask ordering inside discovery rounds.
