# 070 — propagation-hygiene — notes

_Created 2026-05-21._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-21 — parent — Inventory worklist + scope confirmation

Task 1 grep sweep. De-leak worklist is **CLAUDE.md + 16 rule files** (plan said 15; `typecheck-advisory.md` was missed — it carries 6 prose `spec NNN` mentions but zero `docs/specs/0NN` path pointers, so it did not appear in the path-based grep that produced the plan's 15-file list). Adding it is not scope creep — it is a `.claude/rules/*.md` file, already inside AC1's declared grep target.

Per-file `docs/specs/0NN` path-pointer counts: CLAUDE.md 2, artifact-budgets 4, delegation 4, harness-sync 3, lint-validator 3, mcp-recipes 4, memory-placement 1, php-laravel-support 3, routines 2, runtime-introspect 4, secrets-scan 4, session-handoff 4, spec-driven 1, supply-chain 4, tdd 3, user-prompt-framing 2. Prose `spec NNN` mentions are heavier: CLAUDE.md 27 (concentrated in § Product skill's lineage paragraph and § Harness sync), harness-sync 16, session-handoff 18, runtime-introspect 9, others lighter.

### 2026-05-21 — parent — OQ3 resolved: config-file comments deferred, not expanded into v1

spec.md OQ3 asked whether the leak extends beyond CLAUDE.md + `.claude/rules/`. It does: `.mcp.json.example` (`// Agent0 — MCP recipes (spec 012)`), `.gitleaks.toml` (`# harness-sync-baseline.json (spec 068)`), `.githooks/pre-commit` (6 hits incl. literal `docs/specs/007-*` paths), `.gitignore` (`# Spec 058 —`, `# Spec 007 scenario tests`). All are **comments in code/config files**, not instruction context loaded the way CLAUDE.md and `.claude/rules/` are. spec.md § Non-goals already excludes "code comments" by stated principle; expanding v1 to cover these would override a declared non-goal mid-flight. Resolution: v1 scope stays CLAUDE.md + 16 rule files; the 4 config files are a documented follow-up (cheap — ~10 comment lines). The follow-up belongs with the deferred hooks/tools/skills de-citationing.

### 2026-05-21 — parent — Memory cross-references found as an adjacent leak, deferred

While de-leaking, a second class of leak surfaced: rule files and CLAUDE.md point at specific `.claude/memory/<file>.md` (canonical example `feedback_speculative_observability.md`, referenced from several capacity sections). `.claude/memory/` ships only `.gitkeep` to forks, so a named memory file is a dangling pointer in a fork too — same shape as the spec-citation leak, distinct cause. This is outside spec 070's declared scope (the ACs target `docs/specs/` paths + `Spec NNN` prose). Deferred, not silently expanded; recorded in `.claude/memory/propagation-hygiene.md` § Not-yet-cleaned surfaces alongside the config-file-comments follow-up. Clean opportunistically when a fork-bound file is next touched.

## Deviations

### 2026-05-21 — parent — Rule-file de-leak delegated, not parent-side

plan.md § Approach said the 17-file de-leak runs "parent-side (no sub-agent fan-out)", reasoning that parallelising "would gain nothing while risking the validator-cascade". Implementation revised this: the rule-file de-leak surfaced ~150 distinct pointers across 16 files — voluminous enough that parallel fan-out gives a real wall-clock win. The validator-cascade risk does not apply here — Agent0 has no detected language stack, so `.claude/validators/run.sh` is inert and post-edit validation cannot produce sibling-induced failures. Three `general-purpose` sub-agents (`sonnet`) each took a **disjoint** set of 5 rule files (no overlapping targets → no collision, no worktree isolation needed per `.claude/rules/delegation.md` § When parents SHOULD declare isolation). CLAUDE.md (parent-side, done) and `spec-driven.md` (the keep-the-convention special case) stayed parent-side.

### 2026-05-21 — parent — Frontmatter `paths:` spec-dir globs also stripped

Not pre-empted by spec/plan: 8 rule files carried `docs/specs/0NN-*/**` globs in their YAML frontmatter `paths:` blocks (a path-scope trigger that auto-loads the rule when the agent works in that spec's dir). The sub-agents were told to leave frontmatter untouched (conservative — `paths:` also holds the legitimate fork-relevant globs). But AC1's grep target is `.claude/rules/*.md` with no prose/frontmatter distinction, so a literal reading requires these gone — and they ARE the leak in config form (in a fork they point at spec dirs that will never exist; inert, but cruft). Parent stripped only the `docs/specs/` glob lines from each frontmatter, leaving every functional file-path trigger intact (each rule still auto-loads on the hooks/tools/manifests it governs). The only lost behavior is the Agent0-dev convenience of auto-loading a rule when editing its spec's markdown — negligible, and the rule still loads via CLAUDE.md and its file triggers. Files: `runtime-introspect`, `harness-sync`, `secrets-scan`, `session-handoff`, `mcp-recipes`, `php-laravel-support`, `lint-validator`, `supply-chain`.

### 2026-05-21 — general-purpose — Minor over-step in typecheck-advisory.md, accepted

The batch-B sub-agent removed the bare date `2026-05-12` from `typecheck-advisory.md` (`Surfaced via shrnk-mono dogfood 2026-05-12` → `Surfaced via the shrnk-mono dogfood`). A date is not a spec pointer and the brief said change-nothing-else, so this is a small over-step. The sub-agent flagged it transparently in its report and the sentence reads cleaner without the orphan date. Accepted rather than reverted — reverting is pure churn for no benefit.

### 2026-05-21 — parent — Config files de-citationed + AC1 grep widened (post-ship scope extension)

After the spec shipped, the user authorised pulling in the OQ3 config-file follow-up. The four root fork-bound config/hook files were de-citationed: `.mcp.json.example` (1 pointer), `.gitleaks.toml` (1), `.githooks/pre-commit` (7), `.gitignore` (2). Doing so exposed a verification gap: AC1/AC2's original grep patterns (`docs/specs/0[0-9][0-9]` and `[Ss]pecs? [0-9]`) do not match the **hyphenated** forms `spec-NNN` / `pre-NNN` / `post-NNN` — and 12 such residuals had survived the rule-file de-leak (`pre-063`, `Pre-013`/`Post-013`, `spec-006`, `spec-068`/`post-068`/`pre-068`, `spec-008`×3, `spec-002`, `Spec-007`). All 12 fixed parent-side; AC1 in `spec.md` widened to the exhaustive pattern so the recorded contract actually proves the intent. One consequential staleness also fixed: `php-laravel-support.md` § 7 still claimed CLAUDE.md has a `## PHP / Laravel` section (removed by task 4) — rewritten to describe the inline-fold + path-scoped auto-load reality. Lesson for a future similar spec: grep the hyphenated forms from the start.

## Tradeoffs

_None — no alternatives were weighed mid-flight beyond those already in plan.md._

## Open questions

_None open — OQ1/OQ2/OQ3 resolved (OQ1 in plan.md § Approach, OQ2 at task 9, OQ3 above)._
