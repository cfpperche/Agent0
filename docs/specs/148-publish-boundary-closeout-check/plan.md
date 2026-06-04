# 148 — publish-boundary-closeout-check — plan

_Drafted from `spec.md` on 2026-06-04. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Extend the existing session-handoff mechanism instead of adding another opt-in ritual. `SessionStart` will persist the starting commit in `.agent0/.session-state/<session_id>/start-head`, alongside the existing porcelain snapshot. `SessionStop` will keep the dirty-work behavior unchanged, but replace the early clean-tree exit with a publish-boundary check: if the tree is clean, `HEAD` moved since `start-head`, the current branch has an upstream and is not ahead of it, and the latest commit in `start-head..HEAD` did not touch `.agent0/HANDOFF.md`, emit the existing nag-once corrective prompt.

This shape catches the exact failure mode from the meeting without trying to inspect the semantic content of handoff prose. A final handoff commit is the mechanical proof that the closeout ritual happened after all other session commits; pushed code with no final handoff commit gets one corrective continuation.

## Files to touch

_Concrete list of files to be created, modified, or deleted. Group by category if it helps._

**Create:**
- `.agent0/tests/session-handoff/11-publish-boundary-closeout.sh` — regression coverage for clean+pushed stale, clean+pushed fresh, and clean+ahead states
- `docs/specs/148-publish-boundary-closeout-check/` — SDD artifacts for this work

**Modify:**
- `.agent0/hooks/session-start.sh` — write `start-head` when the repo has a valid HEAD
- `.agent0/hooks/session-stop.sh` — add the clean-tree publish-boundary branch while preserving dirty-work behavior
- `.agent0/context/rules/session-handoff.md` — document the new Stop branch and `start-head` state file
- `.agent0/tests/session-handoff/run-all.sh` — include scenario 11
- `.agent0/HANDOFF.md` — current local closeout state

**Delete:**
- None.

## Alternatives considered

_At least one rejected approach with its reasoning. If there genuinely was no alternative, state that explicitly ("no real alternative — only viable approach is X because Y")._

### Rule-only checklist

Rejected because the existing rule already says to update handoff before ending a session. The repeated failure is that the model forgets at the publish boundary, so more prose alone does not change behavior.

### Handoff prose linter

Rejected because reliably determining whether `Active Work` and `Next Actions` are semantically current would require brittle NLP or project-specific heuristics. The hook should force a re-read/update moment, not pretend to verify prose truth.

### Pre-push hook

Rejected because it would fire for human and agent pushes alike, including trivial pushes where a session handoff is irrelevant. The session Stop hook already has session identity, nag-once behavior, runtime parity, and the escape hatch.

## Risks and unknowns

_What could go wrong, what we're not sure about, what assumptions we're making. Spell them out — surprises during implementation are usually pre-implementation risks that weren't named._

- Remote-tracking state after push must be represented locally for `@{upstream}..HEAD` ahead checks. This is already what `git status --short --branch` relies on in closeout and is acceptable for the hook's best-effort behavior.
- Strictly requiring the latest session commit to touch `HANDOFF.md` may nag after a harmless post-handoff transcript/doc commit. That is an intentional bias toward a final handoff commit at the actual end of section.
- Repositories without an upstream branch should be silent; they are not at a verified publish boundary.

## Research / citations

_Sources consulted (docs, blog posts, code references) that informed this plan. Satisfies `.agent0/context/rules/research-before-proposing.md`._

- `.agent0/meetings/handoff-closeout-discipline-20260604T163027Z/meeting.md`
- `.agent0/context/rules/session-handoff.md`
- `.agent0/hooks/session-start.sh`
- `.agent0/hooks/session-stop.sh`
- `.agent0/tests/session-handoff/10-stop-enforces-handoff-freshness.sh`
