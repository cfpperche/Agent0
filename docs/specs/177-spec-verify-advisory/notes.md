# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-08 — parent — built in /squad mode (Claude ↔ Codex)

Implemented as a 2-round squad run (`177-spec-verify-advisory-20260608T205457Z`). Round 0 (claude): tool + validator advisory + rule doc + index + 6-scenario suite + squad.json. Round 1 (codex, dispatched workspace-write via codex-exec): genuine adversarial-hardening turn. Closed at `ready_for_human_prod` — external gate green (9/9) + both agents propose-done + guard clean.

### 2026-06-08 — codex — three real defects found and fixed in the peer turn

Codex's review was not a rubber-stamp; it found and fixed three genuine defects:
1. `spec-verify.sh --json` fell back to human output when `jq` was absent (violating the JSON contract) and depended on external `basename` (broke under a PATH-minimal run). Fixed with shell-native `${ABS_SPEC##*/}` + a `json_escape` helper emitting JSON without jq. New coverage in `04-json-shape.sh` (no-jq PATH sandbox).
2. Validator advertised a `spec.md` fallback but my opt-in probe did `[ -f tasks.md ] || continue` *before* checking `spec.md`, so a single-file spec was never evaluated. Removed the premature continue. Covered by `911-spec-fallback` in `07-advisory-latest.sh`.
3. Validator "latest record" grep was too loose — a hand-written `### … — pass …` design heading in notes.md could fake a passing record. Tightened to the exact tool-shaped header regex. Covered by `910-noise` in `07-advisory-latest.sh`.

Suite grew 6 → 8 scenarios; all green. The squad gate (fail-closed per 151) caught nothing red because the work was sound, but the peer review is what actually hardened it — exactly the "green gate is necessary, not sufficient" posture.

### 2026-06-08 — parent — declaration home + persistence

`**Verify:**` lives in `tasks.md` (executable "do" file), keeping `spec.md` intent-pure per Agent0 doctrine; `spec.md` is a fallback scan. Result persisted as a markdown `## Verification log` in `notes.md` (git-tracked, human-readable) rather than the studied project's SQLite `last_verified_result` row — the deliberate substrate rejection.

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


## Verification log

### 2026-06-08T21:04:59Z — pass (1/1) — source: tasks.md
- `bash .agent0/tests/spec-verify/run-all.sh` — pass

### 2026-06-08T21:05:44Z — pass (1/1) — source: tasks.md
- `bash .agent0/tests/spec-verify/run-all.sh` — pass
