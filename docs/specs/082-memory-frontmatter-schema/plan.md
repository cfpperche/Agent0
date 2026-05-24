# 082 — memory-frontmatter-schema — plan

_Drafted from `spec.md` on 2026-05-24. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two artifacts, one rule edit, one settings edit, one migration pass — landed in that order.

**(1) Schema lives in the rule.** Extend `.claude/rules/memory-placement.md` with a new `## Frontmatter schema` section that documents the 3 required fields (`name`, `description`, `metadata.type`) and the 3 optional fields (`metadata.created_at`, `metadata.last_accessed`, `metadata.confirmed_count`) with semantics, value shapes, and a worked example. Add an HTML comment `<!-- DO NOT RENAME — hook .claude/hooks/memory-frontmatter-validate.sh cites this section by name -->` above the heading so the validator's advisory pointer stays stable across future edits of the rule.

**(2) Standalone hook, in-hook path scoping.** Create `.claude/hooks/memory-frontmatter-validate.sh` as a new `PostToolUse(Edit|Write|MultiEdit)` hook — a **4th** entry alongside the existing three (`post-edit-validate.sh`, `secrets-advise.sh`, `supply-chain-advise.sh`, `session-track-edits.sh` — actually 4 existing, so this is the 5th). Path matching for `.claude/memory/*.md` happens **inside** the hook by reading `tool_input.file_path` from the JSON payload — CC's `matcher` field gates on tool name, not path (verified by reading existing `Edit|Write|MultiEdit` registrations in `.claude/settings.json`). The hook exits 0 silently on non-memory files; this is the same pattern `secrets-advise.sh` uses for its file-class filtering.

**(3) Hook fires on parent + sub-agent edits.** Unlike `post-edit-validate.sh` which gates on `.agent_id` presence (sub-agent only), this hook ignores `agent_id` and runs for both. Per spec OQ-4 rationale: memory edits happen mostly from the parent, the check is cheap (one regex on a small YAML block), and the typo-guard benefit is symmetric across actors.

**(4) Pure bash + tolerant frontmatter extractor.** Implementation reads the file, extracts lines between the first `---` (must be line 1) and the next `---`, then walks the block with line-shape checks: `^name:` / `^description:` / `^metadata:` for top-level keys, and `^  type:` / `^  created_at:` / `^  last_accessed:` / `^  confirmed_count:` for `metadata.*` nested keys (2-space indent assumed — matches all 8 conforming existing entries). Unknown keys at either level trigger the typo-guard advisory. No `yq` dependency. Per spec OQ-2: the advisory's goal is signal, not validation rigor; bash misses some edge YAML cases (anchors, multi-line strings) but catches every failure mode the 8 existing entries' shape exercises.

**(5) Migration of the 5 non-conforming entries.** Empirical survey 2026-05-24: 8/13 entries conform; 5/13 are header-style markdown with no frontmatter at all — `capacity-spec-index.md`, `forks-ephemeral-dogfood.md`, `od-grounding-dogfood.md`, `product-pipeline-empirical-baseline.md`, `propagation-hygiene.md`. For each, derive `name` from the H1 (kebab-cased or kept prose-style per existing convention drift — both shapes pass the validator), `description` from the lede paragraph (~1 sentence, ≤200 chars), `metadata.type` from content (`project` for the 4 Agent0-internal observations; `reference` for `capacity-spec-index.md` since it indexes external pointers). Land migration in the same commit as the validator; this is the spec's acceptance criterion #9 ("all 13 existing entries pass") — without migration the validator would emit 5 standing advisories every session.

## Files to touch

**Create:**
- `.claude/hooks/memory-frontmatter-validate.sh` — the validator hook. Bash 3.2-compatible (matches sibling hook discipline). ~80 lines: stdin JSON parse → path filter → frontmatter extract → required-field check → unknown-field check → stderr advisory lines → exit 0.

**Modify:**
- `.claude/rules/memory-placement.md` — add `## Frontmatter schema` section with worked example, the DO-NOT-RENAME comment, and a back-pointer cross-reference (link to `.claude/hooks/memory-frontmatter-validate.sh` so a reader of the rule sees what enforces it).
- `.claude/settings.json` — register the new hook as a 5th entry under `hooks.PostToolUse[]` with `matcher: "Edit|Write|MultiEdit"` and `command: bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/memory-frontmatter-validate.sh`.
- `.claude/memory/capacity-spec-index.md` — add frontmatter (`name: capacity-spec-index`, `description: Which Agent0 spec(s) designed each capacity — Agent0-internal index relocated by spec 070 to keep fork-bound files free of \`docs/specs/\` pointers.`, `metadata.type: reference`).
- `.claude/memory/forks-ephemeral-dogfood.md` — add frontmatter (`name: forks-ephemeral-dogfood`, `description: Capacity docs' "forks" framing is forward-looking; current reality is all forks are spun-up-then-archived dogfood projects. Hard-cutover is the default back-compat posture.`, `metadata.type: project`).
- `.claude/memory/od-grounding-dogfood.md` — add frontmatter (`name: od-grounding-dogfood`, `description: Spec 027 step-2 dogfood (2026-05-14) — citation-by-path real, but grounding alone doesn't buy visual quality. Blind judge result was confounded (1-pass OD vs 4×-refined baseline).`, `metadata.type: project`).
- `.claude/memory/product-pipeline-empirical-baseline.md` — add frontmatter (`name: product-pipeline-empirical-baseline`, `description: First end-to-end full /product run with all 4 mature gates (2026-05-23) — ~3.1M tokens, ~83min, 44 dispatches, 17/17 judges. Use as cost+shape envelope for planning.`, `metadata.type: project`).
- `.claude/memory/propagation-hygiene.md` — add frontmatter (`name: propagation-hygiene`, `description: Maintainer discipline — fork-bound files (CLAUDE.md, .claude/rules/, sync manifest) must carry no Agent0-internal pointers. Read before editing CLAUDE.md or a rule.`, `metadata.type: project`).

**Delete:** none.

## Alternatives considered

### Reuse `post-edit-validate.sh` instead of adding a new hook

Rejected. That hook gates on `.agent_id` (sub-agent only — per `.claude/rules/delegation.md`) and would therefore skip parent edits, which are the dominant memory-edit actor per spec OQ-4. Removing the gate to accommodate memory validation would change the contract for the project validator (typecheck/lint) too, which is intentionally sub-agent-scoped because it's expensive. Mixing capacities in one hook also makes the JSON validator output shape ambiguous — `post-edit-validate.sh` currently expects the validator's stdout to be a `{ok, command, exit, …}` object, not a free-form advisory stream. Cleaner to be a separate hook with its own narrow contract.

### `yq` or Python for "real" YAML parsing

Rejected. The validation surface is small — 6 known keys, 2 levels of nesting, no anchors or multi-line strings in any of the 13 existing entries. Bash + `awk`/`grep` catches every failure mode the spec scenarios target. Adding a `yq` or Python dependency would break the `cc-native` portability tier (hooks must work with zero install steps post-`git clone`). The cost of a false negative (bash passes a malformed entry that `yq` would catch) has low blast radius for an advisory — MEMORY.md regeneration or event-journal projection in 083/085 will fail loudly downstream on shape it can't parse.

### Block (`exit 2`) on missing required field instead of advisory

Rejected. Inconsistent with the established advisory-only pattern (`tdd-advisory:`, `lint-advisory:`, `typecheck-advisory:` — all exit 0). A blocking gate on memory edits would interrupt the author mid-thought when they're saving a learning; the advisory surfaces on the next turn and lets the author choose when to fix. Promoting to blocking is reserved for after rule-of-three demand evidence (per `.claude/memory/feedback_speculative_observability.md`).

### Path-based matcher in `settings.json` instead of in-hook filtering

Rejected — not actually an option. CC's `matcher` field gates on tool name (e.g., `Edit|Write|MultiEdit`), not on file path. Verified by inspecting `.claude/settings.json` — no existing hook uses a path matcher. Path filtering must happen inside the hook by reading `.tool_input.file_path` from the JSON payload. This is the same pattern `secrets-advise.sh` uses.

### Hand-rewrite the 5 missing-frontmatter entries' bodies to fit the H1-prefix convention

Rejected. Two bucket-internal styles exist today (frontmatter-bearing vs H1-prefix prose) and both are valid Markdown. Forcing all 13 into one style is policy, not mechanism — and it'd churn 5 files just to satisfy a stylistic preference unrelated to the schema. Migration only adds the missing frontmatter block (top of file, before the H1); the H1 prose stays.

## Risks and unknowns

- **Risk: bash frontmatter parser false-positives on edge YAML.** Mitigated by the spec's `OQ-2` decision (advisory only; downstream consumers catch real parse failures). If false-positive rate is high in dogfood, swap to `yq` in a follow-up — the hook's surface is small enough that the rewrite is hours, not days.

- **Risk: 4th `Edit|Write|MultiEdit` PostToolUse hook may interact with the existing 4.** Empirically the existing 4 (`post-edit-validate.sh`, `secrets-advise.sh`, `supply-chain-advise.sh`, `session-track-edits.sh`) all exit 0 on success and emit only stderr; none mutate shared state for this file class (`.claude/memory/*.md` is outside their concerns). Adding a 5th independent hook is safe. Verify in dogfood that all advisories surface cleanly (no stderr interleave issues).

- **Risk: the validator's pointer to `§ Frontmatter schema` can break if the section is later renamed.** Mitigated by the `<!-- DO NOT RENAME -->` comment above the heading. Belt + suspenders: the validator's grep target is the literal heading string, so renaming would silently break the pointer — comment is the only signal. Worth a follow-up that asserts the heading exists at hook-install time, but out of scope here.

- **Unknown: sync-harness manifest coverage for the new hook + the modified rule.** `harness-sync-baseline.json` doesn't have an explicit "memory" entry per grep. Standard glob coverage for `.claude/hooks/*.sh` and `.claude/rules/*.md` should pick up the new + modified files automatically. Verify by running `bash .claude/tools/sync-harness.sh --dry-run` (in a fork or a probe directory) after implementation; if the new hook isn't enumerated, add an explicit manifest entry.

- **Unknown: do the 5 migrated entries currently have any value in being non-frontmatter'd?** Inspection shows no — all 5 are conventional memory entries, the absence of frontmatter is historical accident (they predate the convention being formalized). Adding frontmatter is a strict improvement. The H1 in each file becomes redundant with `name:` once frontmatter lands, but Markdown readability doesn't suffer from having both (the H1 is what humans see in editors; `name:` is what tools see).

- **Risk: `description:` values can exceed any future MEMORY.md index line cap (MS-5, spec 085).** 085's cap is 250 chars per spec 080. All 5 proposed descriptions above are under 250 chars; the 8 existing conforming descriptions vary (some are ~400 chars — `anthill-port-workflow` is the longest at ~360). This is 085's problem to validate; flagging here so 085 has a known "needs trim" inventory at its ship time.

## Research / citations

- `.claude/hooks/post-edit-validate.sh` — read top-to-bottom for sibling validator shape (stdin JSON parse, stderr advisories, fail-open posture, lock semantics, bash 3.2 compat).
- `.claude/rules/delegation.md` § *Advisories* — canonical advisory grammar that `memory-frontmatter-advisory:` mirrors (non-blocking, stderr-only, prefix-tagged).
- `.claude/rules/memory-placement.md` — current 3-bucket rule that the schema section will extend.
- `.claude/memory/cc-platform-hooks.md` — `PostToolUse` matcher semantics; confirms matcher gates on tool name, not path.
- `.claude/settings.json` § `hooks.PostToolUse[]` — registration pattern for the 5th hook entry; existing 4 entries provide the canonical shape (`matcher: "Edit|Write|MultiEdit"`, `type: "command"`, `command: bash "$CLAUDE_PROJECT_DIR"/...`).
- Direct inspection of all 13 `.claude/memory/*.md` files (2026-05-24) — established the 8 conforming / 5 missing baseline that drives the migration sub-task.
- `docs/specs/080-memory-system-scale-ready/spec.md` § *The 7 mechanisms (gap matrix)* — confirms MS-1 deliverable scope and downstream consumers (083, 085).
