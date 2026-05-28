# 105 — shared-tools-to-agent0 — notes

_Created 2026-05-28._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-28 — parent — live-vs-frozen extended into project memory (one historical exception)

The plan's live-vs-frozen rule was framed around `docs/specs/` (frozen) vs everything else (live). One borderline case surfaced inside `.agent0/memory/`: `cc-platform-hooks.md:138` references `.claude/tools/probe.sh` inside a *past-tense debugging narrative* ("First-pass observation framed this as…") about CC's per-rule hook-dedup behavior, citing probe.sh as the illustrative file that two rules' globs both match. Decision: **leave it** — it is frozen analysis, same spirit as a frozen spec, even though it lives in a memory file most of whose siblings *were* rewritten (those describe current invocation mechanics: how to run `bench-hooks.sh`, `probe.sh`, etc.). Rewriting a recorded historical observation to cite a path that didn't exist at observation time would falsify the narrative. The acceptance grep explicitly whitelists this one line so "live surface clean" still holds.

### 2026-05-28 — parent — site i18n strings rewritten despite not being shipped surface

`site/src/i18n/strings.ts` (the marketing site FAQ, 3 locales) names `.claude/tools/sync-harness.sh`. It is **not** part of the harness shipped surface (not in any `COPY_CHECK_*` array), so it falls outside the spec's "shipped code/rules/hooks/tests" acceptance phrasing. Decided to rewrite it anyway: it is live, public-facing documentation that would otherwise lie about the tool's path, and it is 3 trivial one-line edits. Cheap correctness; not scope creep.

### 2026-05-28 — parent — test-fixture `.claude/` dir is load-bearing for sync-harness's repo sanity check

sync-harness gates `--agent0-path` with a "looks like an Agent0 repo" check (`[ ! -d .claude ] || [ ! -f CLAUDE.md ]`, exit 2). Two fixtures (`harness-sync/33`, `instruction-drift/05`) used to satisfy the `.claude/` half *as a side effect* of `mkdir .claude/tools/lib`. Moving that mkdir to `.agent0/tools/lib` silently dropped `.claude/`, so the fixtures' synthetic Agent0 source stopped looking like a repo and sync-harness exited 2 mid-test. Decision: **keep the sanity check as-is and fix the fixtures** (add explicit `$SRC/.claude` / `$CONSUMER/.claude` mkdirs). The check is still correct — every real post-102 Agent0 repo and consumer still has `.claude/` (settings.json, Claude-only hooks, rules, skills, tests). Relaxing it to accept `.agent0/`-only trees would weaken a valid guard to accommodate an incomplete fixture.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-28 — parent — bulk sed pattern required a trailing slash, missing three `mkdir` fixture paths

The plan said "every reference is a literal `.claude/tools/<x>`" and the implementation used `sed 's|\.claude/tools/|.agent0/tools/|g'` (trailing slash). Three test fixtures referenced the directory *without* a trailing slash — `mkdir -p … "$X/.claude/tools"` — and were silently skipped by the first sed pass. The plan's own "hand-verify the assertion-sensitive suites" step caught the first (`harness-sync/33`); a follow-up `grep '.claude/tools'` (no trailing slash) surfaced the other two (`hook-chain-latency/03`, `codex-mcp-recipes/03`). All three fixed by hand. Lesson recorded for any future path-relocation: grep the no-trailing-slash form too, because `mkdir`/`-d` tests reference the bare directory.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-05-28 — parent — umbrella 102 left open after row 6 (crit 4/5 not bundled into 105)

Row 6 is the last `move`, but umbrella 102's acceptance also has criterion 4 (encode the § Classification principle durably) and criterion 5 (consumer-migration posture doc in `harness-sync.md`). 105 was scoped to the *relocation only*; crit 4/5 were left for a follow-up. Cost: the umbrella does not fully close on this spec. Worth it: the founder explicitly said other refactoring questions come *after* 105, and crit 4/5 are exactly that class of decision (where to put the principle — new `harness-home.md` vs extend `memory-placement.md`). Bundling them would have pre-empted a decision the founder reserved.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

_None — the one spec-level open question (self-rebootstrap transitional crash) was resolved in `spec.md` § Open questions (accept + documented gotcha)._
