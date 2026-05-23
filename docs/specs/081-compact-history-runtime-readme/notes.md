# 081 — compact-history-runtime-readme — notes

_Created 2026-05-23._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-23 — parent — `compactHistory.keepLast` defensive integer parsing

The plan said: `KEEP_LAST="$(jq -r '.compactHistory.keepLast // 20' settings.json)"`. That handles "key missing" but not "key present but non-numeric or zero/negative" (a malformed settings.json would otherwise break `tail -n +$((KEEP_LAST + 1))` with arithmetic error).

Added a defensive integer guard immediately after the jq lookup:

```bash
if ! [[ "$KEEP_LAST" =~ ^[0-9]+$ ]] || [[ "$KEEP_LAST" -lt 1 ]]; then
  KEEP_LAST=20
fi
```

Three bytes of paranoia, prevents one entire class of "fork misconfigured the cap and the hook now crashes". No test added — the surface is narrow enough that the guard is its own documentation.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-23 — parent — gitignore exception requires `dir/*` not `dir/`

The plan said: add `!.claude/.runtime-state/README.md` immediately after the existing `.claude/.runtime-state/` line.

What actually happened: that combination does NOT work. Git's documented gotcha — "It is not possible to re-include a file if a parent directory of that file is excluded" (`man gitignore`). When the parent dir is matched by `dir/` (wholesale-ignore), git skips even reading the contents, and the `!` exception never gets evaluated.

The working shape is `dir/*` (ignore the contents glob, not the directory itself) followed by `!dir/README.md`. Final state in `.gitignore`:

```
.claude/.runtime-state/*
!.claude/.runtime-state/README.md
```

Verification: `git add .claude/.runtime-state/README.md` produces an `A` status; sibling files like `last-run.json` and `in-flight/*` stay untracked. (`git check-ignore -v` reports exit 0 even on a matching `!` rule — its verbose output shows the negation rule but the exit code is unhelpful here; the real tests are `git add` and `git status`.)

The plan and the task list both encoded the wrong pattern. Plan and tasks left as-is for audit; rule-of-three demand-test for a `.claude/memory/<topic>.md` entry on gitignore-exception semantics (one incident is not enough — wait for two more before promoting).

### 2026-05-23 — parent — session-start.sh empty-dir branch needed scoped `|| true`

The plan's session-start.sh snippet read the lex-greatest snapshot with:

```bash
LATEST="$(ls -1 "$PROJECT_DIR/.claude/.compact-history"/*.md 2>/dev/null | tail -1)"
```

Under `set -euo pipefail` (which the hook declares), an unmatched glob makes `ls` return non-zero. With `pipefail`, the whole pipeline fails. With `-e`, bash exits 2 — the test caught this (scenario 5 branch B initially failed). Fix: scope `|| true` to the failing step:

```bash
LATEST_SNAPSHOT="$({ ls -1 "$COMPACT_HISTORY_DIR"/*.md 2>/dev/null || true; } | tail -1)"
```

Now graceful no-op works on both missing dir and present-but-empty dir.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
