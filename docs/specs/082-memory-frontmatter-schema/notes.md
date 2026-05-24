# 082 — memory-frontmatter-schema — notes

_Created 2026-05-24._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-24 — parent — verify.sh lives in spec dir, not tests/

`plan.md` mentioned a TDD test artifact but didn't pin location. Chose `docs/specs/082-memory-frontmatter-schema/verify.sh` over `tests/hooks/memory-frontmatter-validate.test.sh`. Reasons: (a) there is no existing `tests/` tree for hooks in this repo — sibling hooks (`post-edit-validate.sh`, `secrets-advise.sh`, etc.) ship with no formal test harness, only dogfood; (b) the script is acceptance-scenario-aligned (one PASS line per spec scenario), making it more useful as a spec-companion artifact than as a generic test; (c) re-running against future hook changes is one command (`docs/specs/082-*/verify.sh`) without needing a test-runner convention. The script doubles as the executable form of the spec's § Acceptance criteria.

### 2026-05-24 — parent — advisory message format uses em-dash, not nested parens

Iterated on the message format during hook implementation. Initial draft: `memory-frontmatter-advisory: <rel>: missing required field 'description' (typo guard; ...) (see schema)`. Nested parens were ugly. Settled on: `memory-frontmatter-advisory: <rel>: <reason> — see .claude/rules/memory-placement.md § Frontmatter schema`. Em-dash separates the failure reason from the citation, keeps citation literal so `grep`-based meta-assertion (verify.sh S12) works on a stable substring.

## Deviations

_No intentional departures from `plan.md`._

## Tradeoffs

### 2026-05-24 — parent — bash regex parser tolerates a class of malformed YAML

`spec.md` OQ-2 already named this tradeoff, but the implementation made it concrete: the line-shape parser accepts `Description:` (capital D) by treating it as "other line, tolerated" — HAS_DESC stays 0, advisory fires correctly ("missing required field 'description'"). The author reading the advisory sees their typo. So the practical effect is correct, just routed through a different failure mode than a "real" YAML parser would emit. Acceptable for an advisory.

Edge cases the bash parser misses but a YAML parser would catch: anchors (`&id001`), multi-line strings (`description: |`, `description: >`), quoted values containing `:`. None of the 13 existing entries use any of these. If they appear in future entries, the validator silently passes the file — downstream consumers (083 event journal, 085 index regen) would catch it. v1 cost accepted; promotable to `yq` in a follow-up if dogfood shows the gap matters.

## Open questions

### 2026-05-24 — parent — within-session settings.json activation

Confirmed empirically: edited `.claude/memory/_e2e-test-082.md` with intentionally malformed frontmatter (missing `description`, `metdata` typo, missing `metadata.type`) AFTER registering the new hook in `settings.json`. The Write completed without any visible advisory output. Manual invocation (piping the same payload to the hook directly) produced the 3 expected advisories. Conclusion: the new hook does not fire in the session where it was added — matches the documented gotcha in `.claude/rules/compaction-continuity.md` § Gotchas ("Hooks only register on the next session — settings.json changes mid-session don't retro-activate.").

This is NOT a defect, just a session-boundary constraint. The next session that boots in this repo will pick up the registration and the hook will fire on memory edits. The script-level testing (verify.sh + the standalone dogfood loop) is the same code path the harness invokes, so logical correctness is verified without depending on session reload.
