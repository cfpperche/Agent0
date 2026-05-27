# 097 — borderline-rules-disposition — notes

_Created 2026-05-27._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-27 — parent — pre-move cross-ref inventory

Phase 1 task 1 repo-wide grep matches the plan's 24-file inventory exactly:

```
.claude/.runtime-state/README.md
.claude/hooks/propagation-advise.sh
.claude/hooks/runtime-capture.sh
.claude/hooks/runtime-pre-mark.sh
.claude/memory/cc-platform-hooks.md
.claude/memory/hook-chain-latency.md
.claude/memory/propagation-hygiene.md
.claude/memory/user-global-hooks-shadow.md
.claude/rules/delegation.md
.claude/rules/php-laravel-support.md
.claude/rules/propagation-advisory.md
.claude/rules/runtime-capabilities.md
.claude/tests/runtime-capabilities/02-registry-missing.sh
.claude/tests/runtime-capabilities/05-vocab-term-missing.sh
.claude/tests/runtime-capabilities/06-required-row-missing.sh
.claude/tests/runtime-capabilities/07-required-row-duplicated.sh
.claude/tests/runtime-capabilities/08-extra-row-allowed.sh
.claude/tests/runtime-capabilities/fixtures.sh
.claude/tools/check-instruction-drift.sh
.claude/tools/probe.sh
.claude/tools/sync-harness.sh
AGENTS.md
CLAUDE.md
site/src/i18n/capacities.ts
```

No deltas vs plan. One incidental observation: `.claude/rules/runtime-introspect.md` self-reference does NOT appear in the grep because the regex matches `rules/<slug>` literals, and a file referring to itself by section anchor rather than path won't surface; this is fine — self-refs don't need rewire.

### 2026-05-27 — parent — drift-check anchors safe across split

`check-instruction-drift.sh` anchors on `runtime-capabilities.md` in five ways (lines 130–211): (1) registry path existence, (2) CLAUDE.md/AGENTS.md managed-block contains the registry path string, (3) six vocabulary terms (`native`, `native-opt-in`, `convention`, `read-only`, `planned`, `unsupported`) appear in the registry, (4) twelve minimum-set capability labels (`instruction entrypoints`, `session handoff`, `SDD`, …) appear as table rows, (5) AGENTS.md lacks the legacy `## Codex Capability Tiers` table. All five anchors live on content that the plan keeps in the consumer-facing slice (`## Status vocabulary` + `## Capability matrix` + paths/managed-blocks). The MB sections being moved (`## Update rule`, `## Drift enforcement`, `## Skill portability relationship`) are NOT anchors. **No drift-check edit needed.** Plan stands.

### 2026-05-27 — parent — synthetic propagation-advisory readability test

Verifying the thinned `.claude/rules/propagation-advisory.md` still lets a consumer act on the advisory line alone (per plan.md § Risks and unknowns + task 9 requirement). Synthetic case: agent writes content that triggers the hook and sees this on stderr:

```
propagation-advisory: spec-NNN in .claude/rules/foo.md:42 — see spec 074 for prior art
```

Reading the thinned rule cold (no memory entry consulted):

1. `§ What fires, what stays silent` names the 5 pattern kinds inline including `spec-NNN` — consumer recognises `spec-NNN` as "concrete spec number" without needing the regex.
2. The advisory line format is named in the same section: `propagation-advisory: <pattern-kind> in <relpath>:<line> — <truncated text>` — matches the synthetic line shape.
3. `§ Override marker` gives the override grammar: `# OVERRIDE: propagation-exempt: <reason ≥10 chars>`.
4. `§ Escape hatch` gives the per-session opt-out: `CLAUDE_SKIP_PROPAGATION_ADVISE=1`.

A consumer reading the advisory line can identify the leak class, decide whether the reference is genuinely upstream-internal (remove it) or legitimate-but-internal-looking historical prose (override marker), and apply the fix — all without ever opening the memory companion. The maintenance memory entry is reserved for the maintainer who needs the exact regex (extending the pattern), the shipped-surface set (deciding whether a NEW file path should be scanned), or the audit-log promotion criterion.

Verdict: thinned rule is consumer-readable on its own. Split disposition succeeds.

### 2026-05-27 — parent — CF/MB boundaries confirmed cold-read

Re-read all three source rules cold (`runtime-capabilities.md`, `propagation-advisory.md`, `runtime-introspect.md`). The plan's `§ Per-file disposition` CF/MB boundaries match the actual file heading structure with zero deviation. Specifically:

- **runtime-capabilities.md**: H1 + opening + `## Status vocabulary` + `## Capability matrix` + `## Future runtimes` are CF; `## Update rule` + `## Drift enforcement` + `## Skill portability relationship` are MB. Headings match the plan verbatim.
- **propagation-advisory.md**: opening + `## What fires, what stays silent` + `## Override marker` + `## Escape hatch` are CF; `## The 5 patterns` + `### Pattern exclusions` + `## Shipped surface` + `### Within-surface exclusions` + `## Audit log` are MB. `## Gotchas` is mixed (per plan, thin to consumer-relevant items only). Headings match.
- **runtime-introspect.md**: opening + `## What fires, what captures` (condensed) + `## Detector pair list (v1)` table + `## last-run.json schema` (field semantics) + `## Probe output shape` + `## Escape hatches` are CF; `### Extension via env var (HUMAN-ONLY, pre-launch)` paragraph + per-detector `### Inference heuristics` tables + `## State file (no audit log)` design rationale + maintainer-deep gotchas are MB. `## Gotchas` is mixed. Headings match.

Phase 2 cleared to proceed.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-27 — parent — none material

Implementation followed `plan.md § Per-file disposition` and § Files to touch verbatim. Phase 4 cross-ref audit identified exactly 4 pointer rewrites (`runtime-capture.sh:14`, `cc-platform-hooks.md:106`, `user-global-hooks-shadow.md:26+45`) where the citation named a moved section by anchor; all other ~20 cross-refs were either bare rule pointers (no rewrite) or already pointed at surviving consumer-facing sections. No deviations from disposition or file lists.

Minor naming consistency observation (NOT a deviation): the moved `## Inference heuristics` and `## Gotchas` subsections in the source `runtime-introspect.md` rule landed under `## Inference heuristics` / `## Deep gotchas` in the maintenance memory. The "Deep" prefix is implicit in the location (memory not rule) and explicit in the heading, mirroring the spec's framing of "deep gotchas a maintainer extending detectors needs". One downstream cross-ref still cites `§ Inference heuristics` (cc-platform-hooks.md:106) — anchor matches the memory's section heading, so the pointer resolves.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
