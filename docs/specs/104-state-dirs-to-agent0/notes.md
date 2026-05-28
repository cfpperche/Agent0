# 104 — state-dirs-to-agent0 — notes

_Created 2026-05-28._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-28 — parent — harness-sync fixture fidelity (updated despite being mechanism-only)

The three `harness-sync/{13,14,15}-gitignore-merge-*.sh` tests build *synthetic* Agent0 `.gitignore` fixtures and assert the additive-merge mechanism (overlap dedup, marker, preservation) — they'd pass green regardless of whether the fixture entries read `.claude/.*-state/` or `.agent0/.*-state/`. Decision: update them anyway. These tests ship to consumers via the `.claude/tests/` manifest, so a consumer reading test 14's `# Agent0: harness entries` block would see `.claude/.session-state/` presented as a *current* Agent0 gitignore entry — now stale. Fidelity of shipped fixtures > minimal-diff. The sed touched SRC fixture + consumer fixture + assertion strings together, preserving internal consistency, so the suite stayed 36/36.

### 2026-05-28 — parent — local browser-state credentials physically migrated

`.claude/.browser-state/{linkedin,x}.com.json` are this machine's real saved Playwright auth state (gitignored, credential-class). The capacity-only posture says "forks migrate their own data", but since this is the founder's own machine executing the relocation, I `mv`'d the JSONs to `.agent0/.browser-state/` so the saved logins aren't silently orphaned (the browser-auth flow now looks under `.agent0/`). Outside the commit (gitignored); a local convenience, fully reversible.

### 2026-05-28 — parent — live-session mid-migration window accepted

This Claude session's `session-start.sh` had already written state to `.claude/.session-state/<id>/` before the code edit re-pointed the hooks to `.agent0/.session-state/`. The Stop hook for *this* session reads the new path, finds no `started-at`, and falls to its porcelain/mtime fallback. Harmless (ephemeral, one session) and the HANDOFF update + commit satisfy the nag anyway. No mitigation taken; documented as the expected transitional cost.

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
