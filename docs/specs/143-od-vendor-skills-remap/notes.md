# 143 — od-vendor-skills-remap — notes

_Created 2026-06-02._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-02 — parent — All 4 OQs resolved at plan-time; no surprises in implementation

OQ1 whole-tree (per spec 027 no-partial-vendor), OQ2 keep dst stable, OQ3 keep `kind` (verified display-only), OQ4 accept provenance path change. The implementation was a single manifest `src` field edit + `--apply`; the (spec-141) content-true apply did the rest. No deviation from plan.

### 2026-06-02 — parent — Baseline confirmed the bundles were stale across MULTIPLE pins, not just c128ffd5

The pre-apply `web-prototype/assets/template.html` provenance read `open-design@454e8373…:skills/web-prototype/…` — an even OLDER pin than the prior `d25a7aaf`. So the pipeline's skill bundles had been frozen at `454e8373` and never re-vendored through the `d25a7aaf` or `c128ffd5` advances (they were always orphans the no-prune bug preserved). The remap doesn't just fix c128ffd5 — it re-sources the bundles to the CURRENT pin for the first time in several advances. After apply, provenance correctly reads `@c128ffd5:design-templates/…`.

## Deviations

_None — implementation matched plan.md exactly (one manifest field + re-apply)._

## Tradeoffs

### 2026-06-02 — parent — Accepted a large vendor diff (≈729 design-templates files / 80 new bundle dirs) for whole-tree fidelity

The whole-tree mirror writes all 111 `design-templates/` bundles (incl. ~80 the pipeline never references — html-ppt-*, orbit-*, taste variants). Chose this over 31 explicit entries to honor spec 027's ratified no-partial-vendor stance and avoid manifest verbosity + a silent-failure maintenance burden. Cost: a big commit + eventual consumer re-sync churn. Accepted; 142's prune keeps the tree honest going forward.

## Open questions

### 2026-06-02 — parent — `--verify` stays red until 142 (expected, not a 143 defect)

After remap, the now-orphaned upstream creative `skills/` set (the 154 bundles the c128 advance wrote) remains on disk and fails `--verify` for `vendor/open-design/skills/` (6/7 other paths green). This is the documented hand-off to spec 142 (orphan-prune), not a 143 failure. Owner: sequenced — 142 next.

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
