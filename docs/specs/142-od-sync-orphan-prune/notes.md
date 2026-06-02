# 142 — od-sync-orphan-prune — notes

_Created 2026-06-02._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-02 — parent — Implementation followed the debate-resolved design exactly

All 4 OQs were pre-resolved in `debate.md` § Synthesis, so the build was mechanical: 4 pure exported cores (`computeOrphans`, `topLevelBundles`, `findReferencedOrphans`, `assertDisjointRoots`) TDD'd red→green (suite 36→46), plus FS wiring in `cmdApply` — compute-orphans + the two guards BEFORE Phase B (block before any mutation), move-to-`runtime/od-sync/pruned-<sha>/` trash after Phase B, `rm` the journal on full success.

### 2026-06-02 — parent — Empty-dir sweep via `find -mindepth 1 -type d -empty -delete`

Moving orphan FILES leaves empty bundle DIRs. Rather than track-and-rmdir each, swept each affected dst root with `find -mindepth 1 -type d -empty -delete` (bottom-up, never the root itself — staged files keep the root non-empty). `.gitkeep` keeps a legitimately-empty vendored dir non-empty, so it's preserved. Simpler than per-dir bookkeeping and idempotent.

## Deviations

_None — implementation matched plan.md._

## Tradeoffs

### 2026-06-02 — parent — Trash journal rm'd on success (not kept as a persistent record)

Per Codex's OQ-reversibility point, the journal exists to make a mid-write crash a local restore. On full success (manifest + indices + report written) the journal is `rm`'d — it's a crash-recovery aid, not an audit trail (the apply report's `## Pruned orphans` section is the durable record). Gitignored (`runtime/od-sync/pruned-*/`) as belt-and-suspenders for the crash case.

## Open questions

_None open. Live validation: `--apply` pruned 284 orphan files (the upstream creative `skills/` set the c128 advance wrote); `--verify` now passes all 7 paths; the 31 pipeline bundles (sourced from `design-templates/` by spec 143) survived; design-systems/frames/prompts untouched._

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
