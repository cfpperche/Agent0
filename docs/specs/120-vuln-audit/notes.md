# 120 — vuln-audit — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-30 — parent — Live osv-scanner smoke-test: V2 JSON parse matches real output

Closes reminder `r-2026-05-30-run-vuln-audit-once-against`. The CI suite mocks osv-scanner with an offline fake-osv stub; this is the first run of the wrapper against the **real binary** (`osv-scanner 2.3.8` / `osv-scalibr 0.4.5`, installed to `~/.local/bin` from the GitHub release — Go 1.22 here is too old to `go install` the v2 module).

Scanned `site/bun.lock` (npm/bun) — it carries **4 real findings**, which exercised all three parse paths the reminder named, cross-checked field-by-field against raw `osv-scanner --format json`:

- **severity** — wrapper emits `moderate/low/high/moderate`; raw `database_specific.severity` = `MODERATE/LOW/HIGH/MODERATE` (wrapper lowercases). ✅ **Caveat:** the `groups.maxSeverity` *fallback* branch was **not** exercised — all 4 vulns carried `database_specific.severity`, so the primary path won. The raw CVSS `groups.max_severity` (6.1 / 7.5 / 4.3) were present but unused, as designed (categorical db_sev preferred). Fallback path remains stub-only-verified.
- **fixed_version** — `affected.ranges.events.fixed`: astro→`6.1.6`/`6.1.10`, devalue→`5.8.1`, yaml→picked `2.8.3` from the multi-event array `[2.8.3, 1.10.3]` (correct fix line for installed 2.7.1). ✅
- **source.path basename** — raw `source.path` = `/home/goat/Agent0/site/bun.lock`; wrapper's `coverage.{found,covered}` report the basename `bun.lock` (there is no per-finding `source` field — basename lives in the coverage block). ✅

Flag behaviors also confirmed against the live finding set (CI only had the stub): `--exit-code` → `1` with findings; `--severity high` → filters to the single devalue HIGH; `--severity critical` → `status=clean` (no criticals). Wrapper exits `0` without `--exit-code` even when findings exist (advisory-only contract, per `vuln-audit.md`).

No false alarm to act on for Agent0 itself — these are `site/` (the Astro marketing site) deps; recording the parse-correctness result, not opening a remediation task.

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
