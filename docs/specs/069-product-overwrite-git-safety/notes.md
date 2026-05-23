# 069 — product-overwrite-git-safety — notes

_Created 2026-05-21._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-21 — parent — run-all.sh uses a glob, not a hardcoded test list

`.claude/tests/harness-sync/run-all.sh` enumerates its tests via a hardcoded `for n in 01 02 … 31` list, which has to be hand-extended for every new test (it was extended twice during spec 068). The new `.claude/tests/product-overwrite/run-all.sh` globs `[0-9][0-9]-*.sh` instead — new scenario scripts are auto-discovered, no orchestrator edit needed. `plan.md` specified only "a `run-all.sh` orchestrator"; the glob shape was the implementation-time choice as the lower-maintenance option. Not retrofitted to harness-sync's run-all — out of scope for this spec.

### 2026-05-23 — parent — live preservation validated end-to-end against fresh ephemeral target

The static test suite (`.claude/tests/product-overwrite/`) covered the script-level promise; the Híbrido 2026-05-21 validation strategy still wanted a "live" arm — observe `clear-target.sh` running inside a real `/product` invocation against a pre-seeded target. Done 2026-05-23 as part of the spec-075 task-14 dogfood (`/product "habit tracker" --stack=expo --out=/tmp/product-dogfood-2026-05-23-expo`): the target was pre-seeded with 5 sentinels covering all 3 preservation categories — `.git/` (defense-in-depth never-remove), `.claude/rules/sentinel-survives.md` (defense-in-depth via `.claude/`), `CLAUDE.md` (allowlist), `sentinel-should-be-cleared.md` (non-harness file), `docs-old-stale/legacy.md` (non-harness dir). Phase 0 fired the overwrite prompt as designed → `y` → `bash .claude/skills/product/scripts/clear-target.sh /tmp/product-dogfood-2026-05-23-expo` ran inside the skill execution → result: **5/5 sentinels passed**. The 2 non-harness entries surfaced verbatim as `removed docs-old-stale` + `removed sentinel-should-be-cleared.md` in the script's stderr (the audit trail this spec's Gap F replacement promised). The blunt `rm -r <out>` foot-gun is empirically dead. The reminder list item "069 live validation" can be dismissed.

## Deviations

_None — implementation followed `plan.md`._

## Tradeoffs

_None surfaced in-flight beyond the run-all glob choice above._

## Open questions

_None — Q1 (git-status-after-overwrite: intended, no handling) and Q2 (script vs prose: script) were both resolved in `plan.md` before implementation, and nothing new surfaced during the build._
