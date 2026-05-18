# 046 — sdd-in-flight-notes — notes

_Created 2026-05-18._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-18 — parent — Locked `.md` over `.html` for the notes file extension

`spec.md` § *Open questions* Q1 listed extension as an open question because Travis Fischer's original prompt used `implementation-notes.html`. Locked at `.md` in `plan.md` § *Approach* for three reasons grounded in this repo's tooling: (1) the other three artifacts are markdown — parity matters for `git diff` readability and for the agent's mental model of "what lives under `docs/specs/NNN-*/`"; (2) Travis's `.html` framing was for browser preview, but our workflow happens in CLI / IDE buffers where markdown renders better than raw HTML; (3) future tooling (potential `/sdd notes` subcommand, lint hooks) is cheaper to write against markdown than HTML. The decision is reversible — if a contributor surfaces a strong rendering need, switching extensions is a one-line template change.

### 2026-05-18 — parent — Author field uses `parent` / `<subagent_type>` rather than git user

Considered using `git config user.name` for the author field but rejected: most entries will be agent-authored (parent or delegated sub-agent), and the meaningful distinction at read-time is "who in the agent boundary made this call", not "which human's machine ran the agent". `parent` vs `subagent_type` (`general-purpose`, `Explore`, etc.) maps cleanly onto our delegation discipline. Git history already attributes the commit; the author field in `notes.md` answers a different question — was this an orchestrator decision or a delegated implementer's judgment call?

### 2026-05-18 — parent — Four fixed sections, not free-form journal

`plan.md` § *Alternatives* B walks through this in detail. The short version: free-form journals atrophy in practice (we have empirical evidence from internal scratch files and pre-spec `SESSION.md` shape). Four canonical sections cost the writer one routing decision and give the reader a known shape to scan. The sections are deliberately broad — `Design decisions` / `Deviations` / `Tradeoffs` / `Open questions` cover ~all the categories of in-flight content worth capturing without forcing further sub-categorization.

## Deviations

### 2026-05-18 — parent — Tightened the "mechanical lint" verification check

`tasks.md` § Verification "Mechanical lint pass" specified `grep -rn '{{NNN}}\|{{SLUG}}\|{{DATE}}' docs/specs/046-sdd-in-flight-notes/` returns zero hits. Running it produced 6 legitimate matches across `spec.md` / `plan.md` / `tasks.md` — but every match was **documentation prose describing the placeholder syntax** (e.g. "the template should contain `{{NNN}}` / `{{SLUG}}` / `{{DATE}}` placeholders"), not unsubstituted scaffold output that escaped substitution. The original lint shape was too coarse: the failure mode it should guard is "a populated file's H1 / subtitle / header still says `{{NNN}}`", not "the word `{{NNN}}` appears anywhere". Replaced the verification with a tighter check: confirm the H1 lines of all four files in `docs/specs/046-sdd-in-flight-notes/` are concrete (no `{{`), which is the real signal of broken substitution. Deviation logged here rather than re-editing `tasks.md` mid-flight; future scaffolds inherit the loosened framing via this note.

## Tradeoffs

### 2026-05-18 — parent — Spec root vs `artifacts/` subdir for notes.md placement

Recent specs (045 in particular) keep an `artifacts/` subdir for renders, screenshots, tombstones — material *adjacent to* the spec. Briefly considered placing `notes.md` under `artifacts/` for spatial separation from the three "primary" artifacts. Rejected because notes.md is not adjacent — it's canonical, the same status as spec/plan/tasks. Placing it at the spec root preserves the "four artifacts, one directory" mental model the rule now documents. The tradeoff accepted: a slightly more crowded spec root (4 files vs 3 + a subdir). The gain: a flat structure the `/sdd new` scaffold can reason about without case-splitting on artifact type.

### 2026-05-18 — parent — Rule-only v1 vs delegation-gate advisory v1

Could have shipped notes.md as both a rule AND a `delegation-gate.sh` advisory (warning, not block) when CONTEXT references a spec dir and DELIVERABLE omits the notes.md phrase. Chose rule-only per `.claude/memory/feedback_speculative_observability.md`'s rule-of-three demand test: build the observability/enforcement layer when drift has been observed at least three times, not pre-emptively. Spec 035 set the precedent for this pattern (rule-only, hook deferred). Accepting the cost: lower v1 compliance pressure on sub-agent briefs, balanced against the gain of measuring baseline before adding any nudge. The REMINDERS gate at 2026-07-01 will revisit with real data.

## Open questions

### 2026-05-18 — parent — How do we measure dogfood success quantitatively?

`spec.md` Q2 and `plan.md` § *Risks* both flag this. The current proposal is "≥3 of next 5 PRs cite notes.md AND ≥3 specs land with non-empty notes.md by 2026-07-01" — but it's a guess. Real signal might come from qualitative review feedback ("I read the notes file before reviewing the PR — saved me 20 minutes") rather than mechanical citation counts. Promotion criteria need a deciding owner (likely Carlos at REMINDERS gate time) once the window closes. No action needed before then; flagged so the gate-time review has a starting frame.

### 2026-05-18 — parent — Should sub-agent edits to `notes.md` trigger the post-edit validator?

`.claude/hooks/post-edit-validate.sh` runs the project validator after a delegated sub-agent edits any file. For `notes.md` specifically, this seems noisy — the file is prose with no validatable shape; running tsc / pytest / linters on a `notes.md` edit produces signal we don't act on. Provisional answer: let the existing validator-skip patterns handle this (markdown isn't compiled), and revisit only if a real false-positive surfaces. Flagged so the v2 follow-up (if there is one) has an explicit pointer.
