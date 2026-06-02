# 139 — status-doctor-reconciliation — notes

_Created 2026-06-02._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-02 — parent — Contradiction banner keys on Active Work's first bullet only

`reconcile_block` fires the RESUME WARNING only when the **first non-empty bullet** of the handoff's `## Active Work` matches a clean/idle pattern (`working tree clean` / `nothing in flight` / `no active work` / a leading `none`/`nothing`). Chose Active-Work-only (not Current State) and first-bullet-only to minimize false positives — Current State is a history narrative likely to contain "none" incidentally. Contradiction-only by construction: a handoff that already describes the work raises no banner (acceptance criterion 2).

### 2026-06-02 — parent — doctor validates the contract without eval'ing the command

The hook command embeds `$CLAUDE_PROJECT_DIR` / `$(git rev-parse …)`, so the literal path can't be safely resolved. `wired_check` instead (a) jq-extracts `.hooks.SessionStart[].hooks[].command`, (b) matches `startup-brief` in that scoped string, and (c) independently asserts the canonical `$PROJECT_DIR/.agent0/hooks/startup-brief.sh` is present+executable. Contract proven without running untrusted strings. jq-absent degrades to the old substring as `advisory` (never crash); a present-but-unwired config is `broken`.

## Known limitations (accepted — dogfood 139, LOW severity)

A second cross-runtime dogfood (claude-exec + codex-exec, reconcile + wiring) confirmed the live behavior is sound on both runtimes and drove the fixes above (anchored idle detection, rename dedup, jq-absent messaging). The residual LOWs are accepted, not fixed — fixing them would be over-engineering past demonstrated need (rule-of-three):

- **`status` idle detection checks only the first Active Work bullet.** A metadata-only lead bullet (e.g. "Owner: X") could hide a later idle claim. Scanning all bullets was rejected — it over-fires on a mixed "Shipped X / still doing Y" section. First-bullet matches the real HANDOFF format.
- **`status` slug inference truncates on out-of-kebab chars.** `docs/specs/139-status_doctor` → infers `139-status`. The repo convention is lowercase-hyphen NNN-slug, so low-risk; no validation/flag added.
- **`status.sh | head` / `| grep -q` emits a SIGPIPE "broken pipe" on stderr** when the consumer closes the pipe early. Standard Unix behavior; the tool exits cleanly otherwise. Lesson applied to the test suite: capture status output to a variable, then grep (a direct `| grep -q` + `pipefail` yields a false-negative as status.sh dies with 141).
- **`doctor` within-SessionStart match is still substring** (`test("startup-brief")`). A command that merely names the string but doesn't invoke the canonical script (e.g. `echo startup-brief`) passes, because the `-x` arm validates the canonical `.agent0/hooks/startup-brief.sh`, not the matched command's actual target. Vastly narrower than the old file-wide grep (now scoped to a real SessionStart command); airtight resolution deferred.
- **`doctor` reports invalid JSON as "no SessionStart hook binds startup-brief."** An unparseable config yields empty `cmd` → `broken` (correct severity) but a mislabeled cause. A `jq -e .` parse pre-check would give a truer message; deferred (severity is already correct).

## Deviations

### 2026-06-02 — parent — reconcile uses `--porcelain -uall`, not plain `--porcelain`

V12 caught it: git **collapses untracked directories** to their top-level parent (`?? docs/`) when nothing under them is tracked, so plain `--porcelain` hid the `docs/specs/NNN-<slug>/` path the in-flight inference needs. In the real repo it worked by luck (sibling spec dirs are already tracked, so the parent isn't collapsed). Switched `reconcile_block` to `--porcelain -uall` for full untracked paths. The `=== git ===` display block keeps plain `--porcelain` (collapsing is fine for display).

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

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
