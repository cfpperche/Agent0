# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-18 — parent — vulture 2.16 + Go deadcode output/exit contracts (defensive-parse anchors)

**vulture 2.16.** Finding line: `path:line: unused <what> 'name' (NN% confidence)` where `<what>` ∈ import/function/class/method/variable/attribute/property/… plus `unreachable code …`. Exit: `3` when dead code found, `0` clean. **Exit code is NOT a reliable error signal** — a missing path prints `Error: <path> could not be found.` and STILL exits `0`. So: detect `Error:`/`could not be found` in output → `failed`; else parse finding lines (regex `:[0-9]+: unused .* \([0-9]+% confidence\)`); any → `findings` (carry confidence); none + no error → `clean`. Kind map: function/class/method → `unused export`; variable/attribute/property → `unreferenced member`; `unreachable code` → `unreachable code`; import → `other`. Resolve vulture no-fetch: `.venv/bin/vulture` → PATH `vulture` (no `uv run`/`poetry run` — those can sync/fetch). Pass `--exclude` for `.venv/venv/node_modules/build/dist/.git` so the venv isn't scanned.

**Go deadcode.** `deadcode -test -json ./...`: findings → JSON array `[{Path, Funcs:[{Name, Position:{File,Line,Col}, Generated, Marker}]}]`, **exit 0 even with findings** (parse the array, not the exit). Clean → stdout `null`, exit 0. **Library-only / no executable main → stderr `deadcode: no main packages`, exit 1** — this is the `unconfigured` case (no reachability root), NOT `clean`. Kind: unreachable func → `unreachable code`. Resolve no-fetch: PATH `deadcode` only (no `go install`); absent → `unavailable` + `go install golang.org/x/tools/cmd/deadcode@latest`.

### 2026-06-18 — parent — `unconfigured` generalized

`unconfigured` no longer means only "knip has no config". General meaning: **the engine lacks the boundary/entry model it needs to produce sound results**. knip → no entry config; Go deadcode → no executable `main`/test reachability root. Both would otherwise produce a misleading `clean`.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-06-18 — parent — vulture resolution simplified to .venv→PATH (deviation from plan)

Plan task 4 said "resolve vulture via uv/poetry/pdm/.venv mirroring the validator `py_prefix`". Shipped reality: `.venv/bin/vulture` then PATH `vulture` only — NO `uv run`/`poetry run`/`pdm run`. Reason: those wrappers can trigger a sync/fetch, which violates the load-bearing no-fetch contract; and vulture is pure-AST static analysis, so it does not need to import project code in the project interpreter. Simpler + safer. Spec OQ updated to match.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

## Verification log

### 2026-06-19T01:30:43Z — pass (1/1) — source: tasks.md
- `bash docs/specs/209-unused-code-python-go/verify.sh` — pass
