# 087 — skill-rubric-freedom-evals — notes

_Created 2026-05-24._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-25 — parent — `/remind` / `/routine` / `/brainstorm` exempted via override marker, not annotated

**Discovery during T5 smoke test.** Spec.md NG-4 listed `/remind`, `/routine`, `/image`, `/brainstorm` as "mechanical skills exempt" by assuming each had <4 qualifying step headers. Empirical count via `check-rubric.sh` after T1-T4 shipped:

| Skill | Qualifying `^## ` headers | In scope by count-rule? |
|---|---|---|
| `/sdd` | 5 subcommands | ✓ in scope (annotated by T3) |
| `/product` | 8 phases | ✓ in scope (annotated by T4) |
| `/skill` | 5 subcommands | ✓ in scope (annotated by T2) |
| `/remind` | 6 subcommands | **above threshold** (NG-4 was wrong) |
| `/routine` | 5 subcommands | **above threshold** (NG-4 was wrong) |
| `/brainstorm` | 8 steps | **above threshold** (NG-4 was wrong) |
| `/image` | 0 (no qualifying headers — single-flow skill) | ✗ sub-threshold (NG-4 correct here) |

**Decision: apply `<!-- SKILL-RUBRIC-EXEMPT: -->` to the 3 misclassified skills with deferred-work reasons.** Two alternatives rejected:

- *Annotate them all (3 more skill rewrites)* — scope creep against NG-4's spirit ("apply to the three skills"); the 3 named targets carry the highest cost from drift (`/product` 15 steps; `/sdd` recursive — it scaffolds the very specs that drive this discipline; `/skill` self-applies the convention); the 3 misclassified are dispatchers with mostly-Low affordance per step and lower drift cost.
- *Raise threshold to e.g. ≥10 steps* — would exclude `/skill` (5 subcommands) too, defeating the purpose. No clean threshold cleaves the 3 named targets from the 3 misclassified.

The override marker is exactly the escape hatch documented in `skill-rubric.md` for "subcommand dispatcher with mechanical per-step structure". Reason text on each marker references this spec + this notes entry so future agents can re-evaluate.

**Follow-up:** If `/skill audit` surfaces these advisories repeatedly when dogfooding the rubric (≥3 separate sessions over the next month, per rule-of-three), file spec 088 to annotate them. Until then, exempt is the right posture.

### 2026-05-25 — parent — V4 verification corrected to use `/image` only

**Spec.md V4 originally said:** "Run `check-rubric.sh` against `.claude/skills/remind` and `.claude/skills/image` — both expected zero advisory lines."

`/remind` now carries an override marker, so still emits zero advisory lines — but the *reason* differs (override-silenced vs threshold-exempt). V4 corrected to test `/image` as canonical sub-threshold example AND adds the V5 scenario already in spec (override marker scenario) as the canonical test for the now-exempted skills.

### 2026-05-25 — parent — /product description over-cap discovered during V7 (pre-existing, out of scope)

V7 audit simulation surfaced `/product` as non-compliant in `validate.sh` — `rule4-description-length: 'description' is 1086 chars; must be 1-1024`. Verified pre-existing via `git show HEAD:.claude/skills/product/SKILL.md` (description was 1108 chars at HEAD; my edits never touched frontmatter). The `rule8-body-token-warn` (body ~10253 tokens vs 5000 cap) similarly pre-existed. Both belong to a follow-up `/skill port product` task, not this spec. Spec 087 V7 acceptance is on the RUBRIC layer only — `0 rubric advisories` — which the audit confirmed.

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
