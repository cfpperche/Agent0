# 087 — skill-rubric-freedom-evals — tasks

_Generated from `plan.md` on 2026-05-24. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — Documentation foundation

- [x] 1. **Write `.claude/skills/skill/references/skill-rubric.md`.** Sections: *Freedom annotations* (marker grammar: `🔒 Low freedom: <claim>` / `🔓 Medium freedom: <claim>`; text fallback `Low freedom:` / `Medium freedom:` per OQ-2; no `High freedom` tier — skills are imperative); *Eval scenarios* (`## Eval Scenarios` header + ≥2 `### Eval N: <title>` sub-headers; body convention: **Input** / **Expected** / **Failure indicators** as bold inline labels, but body shape is convention-only — validator checks header presence + sub-header count, nothing more); *Step-counting rule* (≥4 `^##` headers excluding the static frame-section set `Notes` / `Gotchas` / `Cross-references` / `Reference Files`); *Override marker* (`<!-- SKILL-RUBRIC-EXEMPT: <reason ≥10> -->` anywhere in the body skips the check entirely; mirrors `# OVERRIDE:` grammar from `.claude/rules/delegation.md`); *Why this is repo-local and not in agentskills.io spec* (frontmatter-vs-body split, Agent0 ships convention upstream-canonical-tool can't enforce); *Cross-reference back* to `.claude/rules/spec-driven.md` § *Acceptance scenarios* (the spec-level sibling).

### Phase B — Annotate the three target skills

- [x] 2. **Annotate `.claude/skills/skill/SKILL.md`.** Add freedom marker to each subcommand section header (`## Subcommand: new`, `audit`, `port`, `validate`, `list`) — all expected to be `🔒 Low freedom` (mechanical dispatchers; the action lives in the scripts). Append `## Eval Scenarios` section with 2-3 scenarios: (a) happy — `new <slug>` scaffolds + validates + reports; (b) audit-all — runs validator across every `.claude/skills/*/SKILL.md`, returns per-skill compliance + rubric advisories; (c) port non-compliant — recognizes deficiencies, applies porter, re-validates.

- [x] 3. **Annotate `.claude/skills/sdd/SKILL.md`.** Add freedom markers to subcommand section headers (`new`, `refine`, `plan`, `tasks`, `list`) — `new` and `list` likely `🔒`, `refine` already has internal step-level annotations (preserve), `plan` and `tasks` likely `🔒` (deterministic from inputs). The `refine` body already uses the convention internally; ensure the top-level subcommand header has its own marker. Append `## Eval Scenarios`: (a) `new <slug>` from scratch; (b) `refine` on an existing spec; (c) `list --in-flight` filter behavior.

- [x] 4. **Annotate `.claude/skills/product/SKILL.md`.** 15-step pipeline. Calibrate per step: most content-generation steps (concept brief, functional spec, UX audit, PRD, OST, sitemap, system design, legal, roadmap, cost, GTM, brand, design system) are `🔓 Medium freedom` (content adapts to scope); the three `AskUserQuestion` gates (after steps 4 / 12 / 14) are `🔒 Low freedom: canonical question shape`; quality-judge invocation (step 14) is `🔒 Low freedom: judge runs deterministically`; SDD-handoff scaffolding (step 15) is `🔒 Low freedom: umbrella matrix template`. Append `## Eval Scenarios`: (a) full multi-phase product, all 15 steps; (b) MVP — `--skip-prd --skip-brand` flags; (c) resume mid-pipeline via `--from-step=NN`.

### Phase C — Validator advisory

- [x] 5. **Implement `.claude/skills/skill/scripts/check-rubric.sh`.** Zero-dep bash, ~80-100 LOC. Inputs: one positional arg = SKILL.md path or skill directory. Behavior:
  1. Honor `<!-- SKILL-RUBRIC-EXEMPT: <reason ≥10> -->` anywhere in the body — exit 0 silently if matched.
  2. Count qualifying `^## ` headers (exclude `## Notes`, `## Gotchas`, `## Cross-references`, `## Reference Files`, `## Eval Scenarios`).
  3. If count < 4 → exit 0 silently (sub-threshold exempt).
  4. Otherwise check (a) every qualifying step header line OR its immediate next non-blank line carries a freedom marker (`🔒` / `🔓` / `Low freedom:` / `Medium freedom:`); (b) `## Eval Scenarios` section exists AND contains ≥2 `^### Eval ` sub-headers.
  5. Emit one `skill-rubric-advisory: <slug> — <gap description>` stderr line per gap. Always exit 0.

- [x] 6. **Wire `/skill audit` to invoke `check-rubric.sh`.** Edit `.claude/skills/skill/SKILL.md` § `Subcommand: audit`: add a sub-step that runs `bash ${CLAUDE_SKILL_DIR}/scripts/check-rubric.sh <skill_dir>` per target after the existing `validate.sh` invocation. Capture stderr; surface findings as a footer block under the per-skill compliance table. Update the audit summary line to gain a rubric count: `summary: N compliant, M non-compliant, K rubric advisories`.

### Phase D — Cross-references + spec correction

- [x] 7. **Add cross-reference in `.claude/rules/spec-driven.md`.** Insert at the bottom of the `## Acceptance scenarios` section a single line: `Skill-level sibling: \`.claude/skills/skill/references/skill-rubric.md\` § *Eval scenarios* — same Input/Expected/Failure-indicator discipline applied to SKILL.md files.`

- [x] 8. **Correct spec.md acceptance bullet.** Edit `docs/specs/087-skill-rubric-freedom-evals/spec.md` acceptance bullet that reads "`.claude/skills/skill/scripts/validate.sh` extended to emit `skill-rubric-advisory:`" — replace `scripts/validate.sh` with `scripts/check-rubric.sh (invoked from /skill audit)` and add a one-line note that the original placement was corrected during planning (the plan deviation is documented in `plan.md` § *Approach*).

- [x] 9. **Flip spec status to `in-progress`.** Edit the `**Status:** draft` line to `**Status:** in-progress` in `spec.md`. (At ship time, flip again to `shipped`.)

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one maps to a checklist item there._

- [x] **V1 — Scenario: compliant skill passes validator.** `bash .claude/skills/skill/scripts/check-rubric.sh .claude/skills/sdd` emits zero stderr lines, exits 0. Same for `/skill` and `/product`.

- [x] **V2 — Scenario: missing freedom annotations triggers advisory.** Create a temp copy of a target SKILL.md, strip its freedom markers, run `check-rubric.sh` on the copy — expect one `skill-rubric-advisory: ... no freedom annotations ...` line on stderr; exit 0; remove the temp copy. (Alternative: mutate the meta-skill in a worktree per `.claude/rules/delegation.md` § *Worktree isolation*.)

- [x] **V3 — Scenario: missing eval scenarios triggers advisory.** Same shape as V2 but stripping the `## Eval Scenarios` section instead. Expect `skill-rubric-advisory: ... no ## Eval Scenarios ...` stderr line.

- [x] **V4 — Scenario: sub-threshold skill is exempt.** Run `check-rubric.sh` against `.claude/skills/remind` and `.claude/skills/image` — both expected zero stderr lines, exit 0, regardless of their annotation/eval state. Confirms the step-threshold gate works.

- [x] **V5 — Scenario: rubric override marker silences a deliberate exemption.** Create a temp copy of a target SKILL.md, strip eval scenarios, AND insert `<!-- SKILL-RUBRIC-EXEMPT: testing override grammar reason -->` on line 2 — run `check-rubric.sh` on the copy, expect zero stderr lines despite the missing eval scenarios.

- [x] **V6 — Static facts: 3 target skills compliant.** Final pass: `bash .claude/skills/skill/scripts/check-rubric.sh` on each of `/sdd`, `/product`, `/skill` — all three emit zero advisory lines.

- [x] **V7 — `/skill audit --all` integration.** Run the audit flow per the wiring in Task 6 — verify the audit output now includes a rubric-findings footer block; with the 3 targets compliant, the footer reads `0 rubric advisories` (or equivalent).

- [x] **V8 — Cross-reference present.** `grep -F "skill-rubric.md" .claude/rules/spec-driven.md` returns the inserted line.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- **Validator host correction.** Spec originally targeted `validate.sh`; plan re-hosted in `audit` after reading `validate.sh` (defer-to-canonical `exec skills-ref`) and `/skill` SKILL.md § Notes (explicit guidance that body-shape checks belong in `audit`). Spec acceptance bullet corrected at Task 8.
- **`/product` annotation is the largest single edit** (15 steps); recommend running it as its own dispatched Agent call with the brief explicitly carrying the calibration heuristic from Task 4. Other two skills can be in-session edits.
- **No commit cadence prescribed.** Author decides commit grain. Suggested split: (1) docs + script + audit wiring; (2) the 3 SKILL.md annotations; (3) cross-references + spec status flip. Three commits is cleaner for review than one mega-diff.
