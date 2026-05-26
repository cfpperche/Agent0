# 090 — multi-runtime-entrypoints — notes

_Created 2026-05-26._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-26 — Codex CLI — Keep shared block compact and globally caveated

The spec required `AGENTS.md` to avoid presenting Claude-only hooks/skills as native Codex capabilities while also requiring the managed block to remain byte-identical with `CLAUDE.md` and inside the existing size envelope. Instead of expanding every capacity entry with per-line caveats, implementation added a compact shared `## Runtime entrypoints` section that applies the tier interpretation to the entire managed block. This keeps the block index-shaped and under the 10% headroom threshold while making the Codex safety contract explicit.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-26 — Codex CLI — Ship managed-block lib through the sync manifest

The plan created `.claude/tools/lib/managed-block.sh` but only explicitly asked to add `AGENTS.md` to `COPY_CHECK_FILES`. Running the existing harness-sync suite exposed the missing dependency in the self-rebootstrap scenario: the temp re-exec copy can fall back to `--agent0-path`, but that source fixture also needs the lib to exist. Implementation therefore added `.claude/tools/lib/managed-block.sh` to `COPY_CHECK_FILES` and updated the self-rebootstrap fixture to copy the lib as part of the current harness shape.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-05-26 — Codex CLI — Drift checker supports fixture flags

The plan described a live-root drift checker, but the requested five test fixtures need to run the same checker against temporary roots and, for checks 1-4, avoid depending on a full `sync-harness.sh` fixture. Implementation added `--root`, `--agent0-path`, and `--skip-sync-check`. This slightly expands the script surface, but keeps tests black-box against the real checker instead of duplicating its logic in each fixture.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

No open implementation questions remain for v1.
