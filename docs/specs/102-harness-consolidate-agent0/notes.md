# 102 — harness-consolidate-agent0 — notes

_Created 2026-05-28._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-28 — parent — Resolved all four `undecided` rows (3-6) to `move`

The umbrella left rows 3-6 `undecided`. Resolved each against the § Classification principle ("shared test"):

- **Row 3 (session-state) → move**, reversing 101 OQ-E. OQ-E kept it in `.claude/` for pragmatic regression reasons + a "099/100 precedent" that hooks move while state stays. But that precedent was a pause, not a principle — 102 exists to reopen it. The 4-file contract is written by *both* runtimes' session hooks (already in `.agent0/hooks/`), so the shared test is unambiguous.
- **Row 5 (browser-state) → move.** Cleanest case: written by a human headed Playwright session, read by either runtime headless. Smallest blast radius (~8 refs), no runtime-exclusive producer.
- **Row 6 (tools) → move.** Strong by principle *and* by existing precedent — the memory tools already live in `.agent0/tools/`, so the remaining `.claude/tools/*.sh` (incl. the Codex-facing `codex-local-env.sh`) are the residual inconsistency. Largest blast (~85 refs) → own child spec.
- **Row 4 (runtime-state) → move (the one genuinely debatable disposition).** Its *producer* (`runtime-capture.sh`/`runtime-pre-mark.sh`) is Claude-only with no Codex port, so the "shared" claim rests only on the neutral reader `probe.sh`. Founder chose `move` (over `defer`) on 2026-05-28: probe.sh moves in row 6, and leaving the state in `.claude/` while its reader sits in `.agent0/tools/` would re-create the exact split the umbrella kills. The producer hooks stay Claude-only — only the state-dir *path* moves.

**Child-spec grouping** (deviates from the handoff's "decide row 3 first, then 4-6" sequencing): rows 3+4+5 are the same mechanical `.claude/.*-state/` → `.agent0/.*-state/` move and share the gitignore, `probe.sh`, sync-harness manifest, and test-fixture sed — bundling them into one child (`104-state-dirs-to-agent0`) is *less* churn than three separate specs and still not a mega-diff. Row 6 (tools) is large enough to warrant its own child (`105-shared-tools-to-agent0`). Scope this session was decision-only (founder choice) — no child scaffolded, no files moved yet.

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
