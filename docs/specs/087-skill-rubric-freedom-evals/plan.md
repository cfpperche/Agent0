# 087 — skill-rubric-freedom-evals — plan

_Drafted from `spec.md` on 2026-05-24. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two parallel workstreams that converge at the end. **(A) Documentation + skill-rewrites first** — write `.claude/skills/skill/references/skill-rubric.md` (canonical grammar), then hand-annotate the three target SKILL.md files (`/sdd`, `/product`, `/skill`) with freedom markers + `## Eval Scenarios` sections. **(B) Validator advisory second** — implement the body-shape check as a separate `scripts/check-rubric.sh` invoked from the `/skill audit` flow (NOT bolted into `validate.sh`). Doc + rewrites ship first so the validator's first run is clean across the 3 targets; running it earlier would emit `skill-rubric-advisory:` lines on every audit during a non-compliance window with no value.

**Deviation from spec — validator placement.** Spec acceptance bullet says "`.claude/skills/skill/scripts/validate.sh` extended to emit `skill-rubric-advisory:`". Reading `validate.sh` and `/skill` SKILL.md § Notes reveals this is the wrong host. `validate.sh` `exec`s `skills-ref validate` when canonical is on PATH — any rubric check appended there is dead code in canonical-present sessions. The `/skill` SKILL.md § Notes explicitly anticipates body-shape checks living in `audit`, not `validate`:

> "Body not validated. This toolkit checks frontmatter compliance only. Body portability […] is operator-asserted; a future enhancement could grep for tier-inconsistent signals during `/skill audit`."

The plan therefore places the check in a new `scripts/check-rubric.sh` wired into `/skill audit`. The acceptance scenarios in `spec.md` still hold — they reference "the validator", and `/skill audit` IS the validator subcommand for body-shape concerns. Spec text will be updated at ship time to point at `audit` (one-line edit).

## Files to touch

**Create:**
- `.claude/skills/skill/references/skill-rubric.md` — canonical doc of: freedom-annotation marker grammar (emoji + text fallback), `## Eval Scenarios` shape (header + ≥2 `### Eval ` sub-headers), step-counting rule (≥4 non-frame `^##` headers, with `Notes` / `Gotchas` / `Cross-references` / `Reference Files` excluded), override marker grammar (`<!-- SKILL-RUBRIC-EXEMPT: <reason ≥10> -->`).
- `.claude/skills/skill/scripts/check-rubric.sh` — body-shape advisory check. Inputs: a SKILL.md path. Behavior: count qualifying step headers; if ≥4, check for freedom annotations on every step header AND `## Eval Scenarios` block with ≥2 sub-headers. Emit `skill-rubric-advisory:` stderr line(s) per gap. Always exit 0. Honor `<!-- SKILL-RUBRIC-EXEMPT: -->` to skip entirely.

**Modify:**
- `.claude/skills/sdd/SKILL.md` — add `🔒` / `🔓` markers on subcommand section headers (`new`, `refine` already partially has them, `plan`, `tasks`, `list`); add `## Eval Scenarios` with 2-3 scenarios (new from scratch / refine an existing spec / list with --in-flight).
- `.claude/skills/product/SKILL.md` — add markers across the 15-step pipeline (gates + judge = Low; content-generation steps = Medium); add `## Eval Scenarios` (full multi-phase product / MVP / scope-narrowed).
- `.claude/skills/skill/SKILL.md` — add markers on the 5 subcommand sections (all Low — they're mechanical dispatchers, the action is in the scripts); add `## Eval Scenarios` (new scaffold / audit --all / port a non-compliant skill); add a new bullet in the `audit` subcommand instructing it to invoke `check-rubric.sh` for each target and surface findings in the audit report.
- `.claude/rules/spec-driven.md` § *Acceptance scenarios* — one-line cross-reference at the bottom of the section: "Skill-level sibling: `.claude/skills/skill/references/skill-rubric.md` § *Eval scenarios* — same Input/Expected/Failure-indicator discipline applied to `SKILL.md` files."

**Delete:**
- (none)

## Alternatives considered

### A1: Extend `validate.sh` directly (the spec's original direction)

Rejected after reading the script. `validate.sh` uses `exec skills-ref validate "$skill_dir"` when canonical is on PATH — a process replacement, so any code after that line never runs. Adding rubric checks before the `exec` would either run them eagerly even when canonical is present (mixing repo-local concerns with upstream spec checks) or require restructuring the defer-to-canonical pattern. The `/skill` SKILL.md § Notes explicitly steers body-shape checks toward `audit`. The spec was drafted before this detail was visible; the plan corrects the host.

### A2: Add a fifth `/skill rubric` subcommand

Rejected because users would always pair it with `audit` (`/skill audit && /skill rubric`). Better composability is `audit` running both passes. A new subcommand also costs argument-parsing surface + SKILL.md section + documentation for negligible gain. The `check-rubric.sh` script invoked from `audit` is the smallest viable surface.

### A3: Run rubric check eagerly on every `PostToolUse(Edit|Write)` on SKILL.md files

Rejected (spec NG-2). A hook firing during authoring would emit advisories on every keystroke that touches a SKILL.md mid-draft — noise during the only window where the gaps are intentional (the author is in the middle of adding them). User-invoked `/skill audit` is the right cadence.

### A4: Auto-rewrite the three target SKILLs with stub annotations

Rejected per spec NG-4 and `.claude/rules/artifact-budgets.md` § *Anti-stub floor*. Generating `🔒 Low freedom: <empty>` markers across 15 steps of `/product` would produce technically-compliant prose that bypasses the writing discipline the convention exists to enforce. Author writes each annotation manually; the validator surfaces gaps, doesn't paper them over.

### A5: Enforce a strict eval-scenario body shape (parse Input / Expected / Failure indicators)

Rejected per spec OQ-4 tentative resolution. Validator checks only for the section header `## Eval Scenarios` AND ≥2 `### Eval ` sub-headers. Body shape (Input/Expected/Failure-indicators) is convention documented in `skill-rubric.md`, not regex-enforced. Same posture as `## Acceptance criteria` in spec.md — the rule documents shape, the validator doesn't parse Given/When/Then.

## Risks and unknowns

- **R1: Step-counting heuristic false positives.** Excluding `Notes` / `Gotchas` / `Cross-references` / `Reference Files` is a static list; skills with custom frame-section taxonomy (e.g. `## Discipline`, `## Files`) may still count those as steps and trigger the threshold spuriously. Mitigation: the exempt marker handles the rare case; the heuristic stays simple (avoid building a content-aware parser).

- **R2: Emoji-render variation in non-mono terminals.** `🔒` / `🔓` render width inconsistently. Mitigated by accepting text fallback (`Low freedom:` / `Medium freedom:`) per OQ-2; the validator's regex matches both forms. Authors in emoji-hostile environments use text.

- **R3: `/skill audit` output growth.** Adding rubric findings inline per-skill could blow past comfortable terminal width. Mitigation: rubric findings emit as a separate footer block under the per-skill compliance table, not as additional columns. The audit's existing summary line gains one count: `summary: N compliant, M non-compliant, K rubric advisories`.

- **R4: `/product` annotation tedium.** 15-step pipeline takes 30-45 min of careful per-step calibration (most Medium freedom; gates + quality-judge invocation Low). Not blocking — just sized. Plan accommodates by sequencing `/skill` first (smallest, validates the convention on the meta-skill itself), `/sdd` second, `/product` last.

- **U1: Subcommand sections vs pipeline steps in counting.** `/sdd` and `/skill` are subcommand-shaped (5 sections each); `/product` is pipeline-shaped (15 steps). The plan treats both as "steps" for counting purposes — per OQ-1 tentative resolution. Validate during dogfood: if subcommand-sections feel awkward to annotate with freedom markers, revisit the heuristic.

- **U2: When `audit` runs `check-rubric.sh`, does it fire on every target or only on those that exceeded the step threshold?** Plan: fire on every target unconditionally; `check-rubric.sh` itself short-circuits when the count is below threshold (cleaner separation of concerns). The audit invoker doesn't pre-filter.

- **U3: Cross-reference direction.** Spec calls for one-line cross-ref from `.claude/rules/spec-driven.md` → `skill-rubric.md`. The reverse direction (`skill-rubric.md` → `spec-driven.md`) is also worth including for symmetry but isn't in the spec's acceptance. Plan: add both as a single hop in `skill-rubric.md` body (the doc that names the parallel will naturally point at the source convention).

## Research / citations

- `/home/goat/anthill/.claude/skills/anthill-codebase-review/SKILL.md` — primary reference; 10 freedom annotations distributed across 9 steps; 3 eval scenarios with explicit `Input` / `Expected` / `Failure indicators` triples
- `/home/goat/anthill/.claude/skills/anthill-agent-creator/SKILL.md` — second corroborating reference; 8 freedom annotations across 8 steps; minimal "Happy path / Edge case" eval format (proves the eval shape is convention-loose, not rigid)
- Density audit (2026-05-24): `grep -l "🔒\|🔓" /home/goat/anthill/.claude/skills/*/SKILL.md` returns 118/144 (82%); `grep -l "## Eval" ...` returns 123/144 (85%). Confirms convention, not one-off.
- `.claude/skills/skill/scripts/validate.sh` — current frontmatter validator; the `exec skills-ref validate` defer-to-canonical pattern motivates Alt A1 rejection
- `.claude/skills/skill/SKILL.md` § Notes (lines 162-166) — explicit guidance that body-level signal checks belong in `audit`, not `validate`: "a future enhancement could grep for tier-inconsistent signals during `/skill audit`"
- `.claude/rules/delegation.md` § *Advisories* — `skill-rubric-advisory:` adopts the established `<kind>-advisory:` grammar; stderr only, exit 0, no JSONL audit
- `.claude/rules/spec-driven.md` § *Acceptance scenarios* — the spec-level sibling of the eval-scenarios layer; cross-reference is bidirectional
- `.claude/memory/feedback_speculative_observability.md` — motivates advisory-only posture; promotion to blocking deferred until rule-of-three demand test passes
- `.claude/memory/feedback_no_persona_role_prompting.md` — motivates NG-5 (no IC-persona sub-agents adopted from anthill)
- `.claude/rules/artifact-budgets.md` § *Anti-stub floor* — same disciplina that motivates NG-4 and Alt A4 rejection (no auto-stub generation)
