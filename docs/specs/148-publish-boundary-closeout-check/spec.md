# 148 — publish-boundary-closeout-check

_Created 2026-06-04._

**Status:** implemented

## Intent

Agent0's session Stop hook currently catches dirty work without a handoff update, but it does not catch the recurring end-of-section failure where an agent commits and pushes successfully while `.agent0/HANDOFF.md` still describes pre-push next actions. Add a publish-boundary closeout check: when a session advanced HEAD and the branch is already pushed, the hook should require a final handoff re-read/update if the session's latest commit does not include `.agent0/HANDOFF.md`. This serves the founder's closeout workflow and every consumer project that relies on Agent0's handoff as ship state.

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan. See `.agent0/context/rules/spec-driven.md` § Acceptance scenarios for shape guidance._

- [x] **Scenario: clean and pushed session with stale handoff nags**
  - **Given** a session starts from a pushed commit and records its start HEAD
  - **When** the session creates and pushes a later commit that does not touch `.agent0/HANDOFF.md`
  - **Then** `session-stop.sh` emits the existing one-shot `decision:"block"` corrective prompt and names the publish-boundary handoff check

- [x] **Scenario: handoff updated before a later pushed commit still nags**
  - **Given** a session starts from a pushed commit and records its start HEAD
  - **When** the session commits a handoff update, then commits later work, and pushes both
  - **Then** `session-stop.sh` emits the publish-boundary corrective prompt because the latest session commit is not a handoff closeout commit

- [x] **Scenario: clean and pushed session with final handoff commit stays quiet**
  - **Given** a session starts from a pushed commit and records its start HEAD
  - **When** the session creates and pushes a later commit whose latest session commit includes `.agent0/HANDOFF.md`
  - **Then** `session-stop.sh` exits silently

- [x] **Scenario: clean but unpushed session stays quiet**
  - **Given** a session starts from a pushed commit and records its start HEAD
  - **When** the session creates a later local commit but the branch remains ahead of upstream
  - **Then** `session-stop.sh` exits silently so mid-work commit flow is not interrupted

- [x] Existing dirty-work handoff checks still behave as before.
- [x] The session-handoff rule documents the publish-boundary branch and the new `start-head` session-state file.

## Non-goals

_What this change explicitly does NOT do. Future scope or adjacent problems that look similar but aren't in this spec._

- Parsing or judging whether `HANDOFF.md` prose is semantically correct. The hook forces the closeout ritual at the right boundary; the agent still reads and updates the text.
- Adding a new `/closeout` skill or pre-push git hook. Opt-in tools can be forgotten, and push hooks would be too noisy for trivial pushes.
- Blocking sessions that are clean but still ahead of upstream. Those are not publish boundaries yet.

## Open questions

_Unknowns to resolve before `plan.md` can be locked. Each should have an owner (who decides) or a path to resolution. Empty if there are none._

None.

## Context / references

_Links to related specs, prior art, issues, docs, conversations. Optional but useful._

- `.agent0/meetings/handoff-closeout-discipline-20260604T163027Z/meeting.md`
- `.agent0/context/rules/session-handoff.md`
- `.agent0/hooks/session-start.sh`
- `.agent0/hooks/session-stop.sh`
- `.agent0/tests/session-handoff/`
