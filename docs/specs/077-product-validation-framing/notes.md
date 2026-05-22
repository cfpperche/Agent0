# 077 — product-validation-framing — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-22 — parent — Generic "UX testing" activity-phrase uses deliberately kept

The plan flagged that `validation` collides with already-correct vocabulary, mandating targeted edits. While sweeping, four occurrences of "UX testing" turned out to be the *generic activity noun* (the discipline of UX testing), not the step name: `04-validation/prompt.md` lines 25 ("UX testing as conventionally defined doesn't fit"), 37 ("you ran a real UX test"), 109 ("Replace real UX testing"), and `04-validation/references/report-template.md:126` ("conventional UX testing doesn't fit"). These were kept verbatim — renaming them to "Validation" would produce nonsense. Spec acceptance criterion 7 reads "no stale `UX Testing` *display string*"; a common-noun use of the phrase is not a display string of the step, so the criterion is satisfied with these four in place.

### 2026-05-22 — parent — Dogfood scoped to a representative-slice, not a full 15-step run

Task 12 / acceptance scenario 3 allows either "a `/product` run through Phase 1" **or** "a representative resume/advance across step 4". Chose the representative slice: in the ephemeral `/tmp/077-dogfood` project, three real `Agent` dispatches against the actual renamed templates — (1) the step-04 Validation producer → a 32 KB `validation-report.md`; (2) the `04-validation` quality judge; (3) the `15b-hifi-mood` quality judge against three hand-built hi-fi fixtures (two AA-passing, one deliberately AA-failing). Rejected the full 15-step pipeline run: it is 35-55 min with 3 user gates (`pipeline-coverage.md`), disproportionate to a rename + one rubric line, and would not exercise any rename-load-bearing surface that the three targeted dispatches miss. What the slice does NOT exercise — the orchestrator's `validation_mode` regex-extraction into `.state.json` and the `gate_discovery` `AskUserQuestion` — is pure orchestrator logic that the rename does not touch (`SKILL.md` is grep-clean of `04-ux-testing`; it refers to step 4 by number). Both judges independently confirmed zero path/section-not-found errors resolving the renamed `04-validation/` directory and the `### 04 — Validation` rubric heading.

## Deviations

### 2026-05-22 — parent — Task-5 site list was under-enumerated; verification grep caught the miss

`plan.md` enumerated 8 inline-parenthetical sites for the `(ux-testing)` → `(validation)` sweep. That list was built from a grep for the lowercase-hyphenated token `ux-testing`. It missed `13-brand/prompt.md:53` — `step 4 (UX testing)` — a genuine step-name parenthetical written with a capital `U` and a space. Task 8's verification grep (case-insensitive, multi-pattern) caught it; fixed in the same pass. No plan correction needed — the plan's *method* (sweep, then verify-grep) worked exactly as designed; the verification step is what made the under-enumeration harmless. Lesson for similar renames: the verification grep must use a broader pattern than the one that built the site list.

### 2026-05-22 — parent — One out-of-scope memory-file path fixed (`consumer-contract-discipline.md`)

Spec acceptance criterion 7 scopes the no-residue check to `.claude/skills/product/`. The plan's risk note said to grep `.claude/` broadly and confirm outside hits were benign. The broad grep found `.claude/memory/consumer-contract-discipline.md:50` carrying a now-broken path `.../pipeline/04-ux-testing/schema.md`. Although strictly outside criterion 7's scope, a dangling path reference in project memory is a defect, not "benign" — fixed it (`04-ux-testing` → `04-validation`). This is in-spirit maintenance, not scope creep: the rename's job is to keep every cross-reference to step 4 valid.

### 2026-05-22 — parent — Stale `04-ux-testing` snapshot in gitignored session-state left untouched

The broad grep also found `04-ux-testing` in `.claude/.session-state/<id>/start-porcelain.txt`, referencing `packages/mcp-product-pipeline/src/templates/04-ux-testing/`. Left untouched: (a) it is gitignored per-session runtime cache, not source; (b) it points at the `packages/mcp-product-pipeline/` MCP package, discontinued 2026-05-19 (`pipeline-coverage.md` § Bundled-template provenance). Neither is in this spec's scope.

## Tradeoffs

_None surfaced in-flight beyond what `plan.md § Alternatives considered` already records._

## Open questions

### 2026-05-22 — parent — Dogfood surfaced a pre-existing `findings`-criterion ⇄ projected-mode inconsistency (OUT OF SCOPE for 077)

The `04-validation` quality-judge dispatch returned `outcome: fail` on the `findings` criterion: `quality-checklist.md § 04` requires `YAML findings[] ≥ 3, each carrying severity + fix_skill_hint`, but `04-validation/prompt.md` step 7 says the YAML frontmatter is "Recommended for measurable mode" and to "Skip the frontmatter when the audit ran in branch (ii) projected mode". A standard-tier run is projected-mode by default — so a correctly-behaving projected-mode step-4 producer will *always* draw a `findings: fail` from the judge. This is a genuine pre-existing `/product` defect (rubric demands unconditionally what the prompt makes conditional), surfaced by the 077 dogfood but **not caused by and not in scope for** spec 077 (rename + the 15b criterion). It predates 077. Owner: founder — decide whether to (a) make the `findings` checklist criterion conditional on `validation_mode` / audit branch, or (b) make the frontmatter unconditional in `04-validation/prompt.md`. Candidate follow-up spec or `/remind`.
