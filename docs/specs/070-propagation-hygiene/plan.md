# 070 — propagation-hygiene — plan

_Drafted from `spec.md` on 2026-05-21. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The fix is a **two-register separation done at the source** — fork-bound files carry only fork-facing operational content; Agent0-internal design memory moves to non-propagated buckets. Four work streams, ordered so no linkage is lost:

1. **Inventory** — produce the exact list of concrete-spec pointers (`docs/specs/0NN-…`, `Spec NNN`, `specs NNN+NNN`) across CLAUDE.md and the 15 affected rule files. This list is both the de-leak worklist and the raw data for the index.
2. **Relocate (build the index first)** — create `.claude/memory/capacity-spec-index.md` mapping each capacity → its originating spec(s), BEFORE stripping the pointers, so the capacity↔spec linkage is captured in a durable place first. Memory is git-tracked but never propagated (sync-harness ships only `.claude/memory/.gitkeep`), so the index stays Agent0-internal by construction.
3. **De-leak + de-stack** — strip concrete-spec pointers from CLAUDE.md capacity sections and the 15 rule files; delete the `## PHP / Laravel` CLAUDE.md section and fold its PHP detection facts inline into the capacity sections that already enumerate stacks. Stripped pointers are replaced by *nothing* (resolves spec.md OQ1) — pointing at the index would itself be a dangling pointer in a fork, since the index does not propagate either. The rule/section just describes the capacity and stops.
4. **Record the discipline** — `.claude/memory/propagation-hygiene.md` documents the fork-bound file class and the no-Agent0-internal-pointer mandate. It lives in memory, not rules, because the discipline binds the *maintainer of propagating content* — which a leaf fork is not — so a rule would leak it to forks where it is inert, reproducing the exact flaw.

**Two deliberate special cases.** `.claude/rules/spec-driven.md` and the CLAUDE.md `## Spec-driven development` section *document the `docs/specs/NNN-<slug>/` naming convention itself*. They keep the literal-`NNN` scheme (no concrete digits) and lose only concrete pointers like `docs/specs/060-harness-gaps-2026/`. The verification grep targets `docs/specs/0[0-9][0-9]` (concrete digits) precisely so the convention scheme survives it.

The whole change is markdown-only — no hook, no validator, no tool code. It is done parent-side (no sub-agent fan-out): the edits are prose pointer-removals across 17 files, each minimal and individually reviewable, and a parallel fan-out would gain nothing while risking the validator-cascade.

## Files to touch

**Create:**
- `.claude/memory/capacity-spec-index.md` — capacity → originating-spec(s) map; the relocated design-memory linkage. Non-propagated.
- `.claude/memory/propagation-hygiene.md` — the fork-bound-content discipline (file class + no-leak mandate + pointer to non-propagated buckets). Non-propagated.
- `docs/specs/070-propagation-hygiene/tasks.md` — generated next via `/sdd tasks`.

**Modify:**
- `CLAUDE.md` — strip `Spec NNN` lead-ins and `docs/specs/0NN` pointers from ~11 capacity sections; **delete the `## PHP / Laravel` section**; fold PHP/Laravel detection inline into the capacity sections that enumerate stacks (validator/lint reference, supply-chain managers list, runtime-introspect allowlist, TDD patterns); `## Spec-driven development` keeps the `NNN-<slug>` convention, loses concrete pointers.
- 15 `.claude/rules/*.md` — strip concrete-spec pointers: `harness-sync.md`, `session-handoff.md`, `routines.md`, `lint-validator.md`, `memory-placement.md`, `php-laravel-support.md`, `user-prompt-framing.md`, `spec-driven.md` *(special — keep the convention scheme)*, `runtime-introspect.md`, `artifact-budgets.md`, `supply-chain.md`, `delegation.md`, `mcp-recipes.md`, `secrets-scan.md`, `tdd.md`.
- `.claude/memory/MEMORY.md` — add two index lines (capacity-spec-index, propagation-hygiene).
- `.claude/rules/memory-placement.md` — *conditional* (resolves spec.md OQ2): a one-line carve-out acknowledging memory may hold a maintainer discipline. Decide during task execution; `agent0-purpose.md` precedent may make it unnecessary. This file is already in the de-leak list regardless.

**Delete:**
- No files deleted. The `## PHP / Laravel` removal is a section deletion within `CLAUDE.md`, not a file delete.

## Alternatives considered

### Transform-on-propagate (sync-harness strips Agent0-internal markers when copying to a fork)

Rejected because it breaks spec 068's SHA-baseline reconciliation. 068 records a per-file sha manifest and treats a fork file that differs from Agent0's recorded sha as "customized". A sync that transforms content on copy means the propagated file *never* matches Agent0's sha — every managed file would read as permanently customized, defeating the stale-vs-customized distinction 068 just shipped. It also converts sync-harness from a pure copier into a content-transformer, adding a new failure surface. Source-clean content is the only approach compatible with 068.

### Keep the spec pointers, treat dangling links as harmless breadcrumbs

Rejected because the cost is paid every session by every fork — the citations sit in always-loaded CLAUDE.md context, and an agent that follows `See docs/specs/047-*/` in a fork burns a turn discovering the directory is absent. The countervailing value (a curious fork developer navigates upstream to read rationale) is hypothetical and rare. Permanent context noise for occasional speculative benefit is a bad trade.

### Discipline as a `.claude/rules/` file

Rejected mid-design (this conversation, 2026-05-21). `.claude/rules/*` propagates to forks. The propagation-hygiene discipline binds whoever maintains propagating content — in Agent0 that is the maintainer; a leaf fork consumes the harness and propagates to nothing. A `propagation-hygiene.md` rule would therefore be Agent0-internal content shipped to forks where it is inert — the precise flaw this spec exists to remove. The principle flags its own would-be violation; the discipline goes to memory.

### Ship `docs/specs/` to forks so the pointers resolve

Rejected because a fork creates its own `docs/specs/NNN-…` for its own product features; shipping Agent0's specs (`002-delegation`, `047-php-laravel-support`, …) would collide with the fork's numbering and clutter its design memory with template-internals. sync-harness correctly never touches `docs/`. The fix belongs at the citing end (fork-bound files), not the cited end.

## Risks and unknowns

- **Over-strip / under-strip.** The de-leak is prose editing across 17 files. Risk: removing a clause's meaning along with its pointer, or missing a mid-paragraph "spec 013" reference. Mitigation: each edit is a minimal pointer-removal, not a rewrite; the verification grep (`docs/specs/0[0-9][0-9]` + `[Ss]pecs? [0-9]`) is the mechanical backstop.
- **The two convention special-cases.** An over-eager strip could remove the `docs/specs/NNN-<slug>/` convention from `spec-driven.md` / `## Spec-driven development`. Mitigation: tasks call this out explicitly; the grep is digit-targeted so it will not flag the literal `NNN`.
- **PHP fold-in has no uniform home.** Not every capacity section enumerates stacks in a list ready to append "php" to. Mitigation: the inventory identifies which sections have a stack list; where none exists, a short clause is acceptable rather than forcing a list.
- **Already-synced forks keep the orphan `## PHP / Laravel`.** The CLAUDE.md merge is append-only — deleting the section from Agent0 does not retroactively clean forks that synced it. Accepted non-goal; the discipline memory should note it so a future maintainer is not surprised.
- **No enforcement.** Nothing mechanically stops the next capacity-adding spec from re-leaking a pointer into CLAUDE.md or a rule. v1 accepts this per the rule-of-three demand-test; the discipline memory is the only guard until drift is observed ≥3×.
- **memory-placement.md carve-out (OQ2).** Minor and non-blocking — resolved in-flight during task execution.

## Research / citations

- Codebase exploration this session: `grep` inventory across `.claude/rules/*.md` + `CLAUDE.md` — 15 of 21 rule files carry concrete `docs/specs/0NN` pointers, all 15 use concrete numbers (zero use convention-only form); 11 CLAUDE.md capacity sections carry `Spec NNN` references.
- `.claude/tools/sync-harness.sh` — manifest confirmed: `.claude/memory/` ships only `.gitkeep` (line 173), content is project-local per spec 019. Confirms the index + discipline files will not propagate.
- `.claude/rules/harness-sync.md` — propagation manifest scope and the append-only CLAUDE.md structured-merge semantics.
- `docs/specs/068-harness-sync-baseline-reconciliation/` — the SHA-baseline 3-way reconciliation that rules out transform-on-propagate.
- No web research — this is an internal-repo documentation refactor with no external tool/config/architecture decision; mechanical-internal work is exempt per `.claude/rules/research-before-proposing.md`.
