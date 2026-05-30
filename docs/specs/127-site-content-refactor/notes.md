# 127 — site-content-refactor — notes

_Created 2026-05-30._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-30 — parent — runtime-status vocabulary aligned to the matrix (not the spec's draft terms)

The spec's draft Scenario 4 said "enforcement / advisory / read-only / convention / planned". The canonical source — `.agent0/context/rules/runtime-capabilities.md` § Status vocabulary — actually uses `native` / `native-opt-in` / `convention` / `read-only` / `planned` / `unsupported`. Since the acceptance criterion is "sourced from runtime-capabilities.md", the implementation uses the matrix's real vocabulary (rendered as `STATUS_LABELS` in `docs.ts`), and the spec scenario was corrected to match. The "enforcement/advisory" distinction the draft wanted is carried in each capacity's `note` instead.

### 2026-05-30 — parent — count drifted 23 → 24 (added `cross-model-debate` as a capacity)

The audit treated debate as a notable first-class capability (it has its own runtime-status nuance: human-brokered works now, automated runner is planned/091), so it became its own manifest entry. The displayed count derives from `CAPACITIES.length`, so "24 capacities" is automatic and self-correcting — no hardcoded number to re-stale.

### 2026-05-30 — parent — process note: `git checkout` of an uncommitted file wiped the manifest

Mid-verification I broke a `sourcePath` with `sed` to prove the currency check fails (it did, exit 1), then `git checkout src/i18n/capacities.ts` to restore — which reverted to the **last commit** (the pre-127 model), destroying the uncommitted new manifest. Recovered by re-authoring it from context, then committed immediately. Lesson carried forward: never `git checkout` an uncommitted file to "undo" a temp edit — copy/restore in-place, or commit first.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
