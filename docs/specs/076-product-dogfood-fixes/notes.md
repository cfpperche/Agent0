# 076 — product-dogfood-fixes — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-22 — parent — OQ#8 resolved as (b)+(c) synthesis — `# SKILL-DIRECTED:` marker

The spec's OQ#8 listed three candidates: (a) accept the advisory as noise, (b) skill emits an explicit signal, (c) gate skips `escalation` when a model is declared. Re-reading the gate (`.claude/hooks/delegation-gate.sh:198-216`) showed that (c) as worded is too blunt — `MODEL_SPECIFIED=true` is *already* the precondition for the current `escalation` branch, so inverting it would silence the legitimate ad-hoc case (parent picked sonnet for a multi-signal task and should reconsider opus). (a) was rejected because the founder explicitly listed #8 as a finding worth fixing, and 18+ false advisories per `/product` run train the agent to ignore advisories generally — the "advisory rot" failure mode.

Chosen: a hybrid where the skill adds `# SKILL-DIRECTED: <slug>` to each brief (mirrors the existing `# OVERRIDE:` grammar so the convention is familiar; ≥10-char slug rule reused), and the gate learns to suppress *only* `escalation` when the marker is present. `model-discipline` deliberately keeps firing — the marker certifies that a declared model was a conscious choice, not that forgetting to declare one is excused. Audit row records `skill_directed: "<slug>" | null` so adoption is greppable (`jq 'select(.skill_directed)'`).

Why this over (b) puro with some other mechanism: the `Agent` tool surface only exposes `prompt` + `model` + `subagent_type` + `description` + `isolation`. There is no metadata channel orthogonal to the prompt. The marker lives in the prompt body — the same surface `# OVERRIDE:` already uses — so the grammar generalizes rather than introducing a new field.

Implementation footprint: ~5 lines in `delegation-gate.sh` (grep for marker before the `score >= 2 && model != opus` branch), 1 line per brief in `.claude/skills/product/references/delegation-briefs.md` (Steps 02-15), one new field in the audit-row builder, and a § Advisories update in `.claude/rules/delegation.md` documenting the marker. Other skills opt in by adding the same marker line; no skill is forced to adopt.

### 2026-05-23 — parent — task 21 3-payload gate test (all 3 scenarios pass)

Ran the prescribed 3-payload local gate test against the live `.claude/hooks/delegation-gate.sh` after the task-19 + task-20 edits. Test script + outputs lived under `/tmp/` and were cleaned up post-verification (with `# OVERRIDE:` since the gov-gate flags `rm -rf` against any path).

Test pollution: because `CLAUDE_PROJECT_DIR` wasn't exported in the test shell, the gate's `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` fallback resolved to `/tmp` (where the test ran from), and the 3 audit rows landed at `/tmp/.claude/delegation-audit.jsonl` — *not* the real `/home/goat/Agent0/.claude/delegation-audit.jsonl`. Initially looked like a write-failure (grep against the real log returned nothing), but it was correct isolation behavior. Documenting because anyone re-running the test should expect the same and either `export CLAUDE_PROJECT_DIR=/home/goat/Agent0` to direct writes at the real log, or accept the `/tmp` sandbox.

Verbatim outcomes (per the 3 audit rows captured):

- (a) markerless multi-signal `sonnet` brief → `advisory_kind:"escalation"`, `skill_directed:null` ✓ (advisory text: "Delegation appears complex (signals: cross-domain, schema-data, security). Consider re-issuing with model: \"opus\" for stronger reasoning.")
- (b) same brief with `# SKILL-DIRECTED: product-dogfood` prepended → `advisory_kind:null`, `skill_directed:"product-dogfood"` ✓ (no `additionalContext` emitted — gate exits silently)
- (c) markerless brief WITHOUT a `model` field → `advisory_kind:"model-discipline"`, `skill_directed:null` ✓ (marker absent or not — `model-discipline` branch is independent of `SKILL_DIRECTED`)

Confirms the spec's two-branch invariant: marker suppresses *only* escalation; model-discipline keeps firing on undeclared models regardless. `bash -n` syntax-check passes on the edited gate.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-23 — parent — SKILL-DIRECTED slug min length lowered ≥10 → ≥3 (caught by task 25 live test)

The plan + tasks.md + initial implementation all said the slug rule mirrors `# OVERRIDE:`'s ≥10-char check verbatim. Task 25 (real-world dispatch through the Claude Code harness, not the synthetic 3-payload local test from task 21) caught the bug: the `/product` skill's actual slug is `product` — **7 chars** — which fails the ≥10-char check. The gate silently dropped the marker (`skill_directed: null` in the audit row) and `model-discipline` fired against an undeclared model, which was correct gate behavior given the dropped marker but the wrong outcome for the validation.

Root cause: copying `# OVERRIDE:`'s minimum without thinking about payload semantics. `# OVERRIDE:`'s payload is *human prose* explaining *why* — the ≥10 rejects lazy reasons like `skip` / `bypass` / `n/a`. `# SKILL-DIRECTED:`'s payload is a *machine slug* — and real Agent0 skill names are short by design: `product` (7), `sdd` (3), `run` (3), `verify` (6), `brainstorm` (10), `routine` (7), `remind` (6), `schedule` (8). The ≥10-char rule excluded most of them.

Resolution (chosen 2026-05-23 via AskUserQuestion, options 3/2/no-min): **min ≥3 chars** — distinguishes real skill names from typo-shaped junk (`# SKILL-DIRECTED: x`, `# SKILL-DIRECTED: ab`) while accepting every shipped skill slug. The slug-shape check (`^[A-Za-z0-9_-]+$`) still applies. Updated three places: gate code comment + length check; rule paragraph (explicitly says "mirrors `# OVERRIDE:` *anchoring*; slug is `[A-Za-z0-9_-]+` ≥3 chars — NOT the ≥10 of `# OVERRIDE:`"); tasks.md 19 + 22 carry the correction note pointing here.

Why the 3-payload local test (task 21) didn't catch this: the test payload used `product-dogfood` (15 chars), which passed the ≥10 trivially. A real `# SKILL-DIRECTED: product` test would've caught it. **Lesson:** synthetic test payloads should mirror real-world usage, not chase coverage of arbitrary edge cases. Logging here so the next harness-test author writes payloads that look like real briefs.

### 2026-05-23 — parent — #2-sections: schema has 4 conditional H2s (not 3) + dropped invented "Legal & Audit Budget" H2

`plan.md` + `tasks.md` task 5 both said "8 required + 3 conditional" with the conditional list as Unit Economics / Projections / Scenarios. The schema actually carries **4 conditional sections** — adds **Break-even** ("at what user count revenue covers run cost") to the three the plan named. Cross-checked against `templates/pipeline/11-cost-estimate/schema.md § Conditional sections` (lines 18-23): four bullets, not three. Followed schema as canonical truth — the spec's acceptance criterion is "brief mirrors schema", so the brief now lists all 4 conditional H2s (Unit Economics / Projections / Scenarios / Break-even) for revenue-generating products.

Separately: the pre-edit brief invented a `Legal & Audit Budget` H2 that the schema does not require. The legal-review + audit-cost rule it was tracking is content-level discipline (a Build Cost / Run Cost line item — already captured by the existing CONSTRAINTS rule "Legal review + audit costs in their own table row"), not its own H2. Dropped the H2 from the required list; kept the line-item rule. DONE_WHEN updated to check all 8 schema-required headers verbatim (was previously checking 5 stale ones including the invented Legal H2).

No `plan.md` rewrite needed — the spec's acceptance still holds and is more strictly met now ("schema enforces at Layer 1" → brief lists all 8 plus the 4 conditional). Plan's "3 conditional" was a stale count from earlier schema drafts; the production schema's 4-conditional shape is what's enforced.

### 2026-05-23 — parent — task 19 anchor mirrors `# OVERRIDE:` exactly (looser than tasks.md prescribed)

`tasks.md` task 19 prescribed `grep -m1 -oE '^# SKILL-DIRECTED: [A-Za-z0-9_-]{10,}'` — strict line-start (no leading whitespace) with the slug-length check fused into the regex. Implementation used `'^[[:space:]]*# SKILL-DIRECTED: '` instead (mirrors the existing `# OVERRIDE:` extraction on line 57 of the gate, including its optional leading whitespace), and moved the ≥10-char + slug-shape check into the shell (`[ ${#slug} -ge 10 ] && printf '%s' "$slug" | grep -qE '^[A-Za-z0-9_-]+$'`).

Reason: the rule paragraph (task 22) states the marker "mirrors `# OVERRIDE:` grammar" — if the gate anchors strictly while override anchors loosely, that one sentence is wrong. Mirroring exactly keeps the rule load-bearing and lets a maintainer use the override extraction as the canonical pattern. The shell-side length check is a small ergonomic gain too (the rule "≥10 chars" stays a single statement instead of split across regex + check, easier to update if the threshold changes).

No `plan.md` rewrite needed — outcome matches Move-1 intent ("suppress escalation only when marker present"); only the regex micro-shape differs from the literal task wording.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
