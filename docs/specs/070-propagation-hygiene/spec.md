# 070 — propagation-hygiene

_Created 2026-05-21._

**Status:** shipped

## Intent

The `sync-harness.sh` tool propagates a defined set of files from Agent0 to its forks — every `.claude/rules/*.md` verbatim, and CLAUDE.md's `## ` capacity sections via structured merge. Those fork-bound files currently carry **Agent0-design-internal content** that is meaningless or actively misleading inside a fork: 15 of 21 rule files and 11 CLAUDE.md capacity sections cite specific specs (`Spec 047:`, `See docs/specs/047-php-laravel-support/`), but `docs/` is explicitly never propagated — so every such citation is a dangling pointer in a fork, and an agent that tries to follow one wastes a turn or concludes the harness is broken. A second instance of the same root cause is the CLAUDE.md `## PHP / Laravel` section: it is organised on the *stack* axis (unbounded — Ruby, Java, .NET, … each would demand a chapter) instead of the *capacity* axis every other section uses, and it sits in always-loaded context for every fork regardless of stack. Both flaws share one cause: **fork-bound files intermix two registers — fork-facing operational documentation and Agent0-internal design memory — with no discipline separating them.** This spec de-leaks the fork-bound surface, relocates the Agent0-internal design-memory linkage to a non-propagated bucket, and records the discipline itself as non-propagating maintainer memory so the fix does not reproduce the flaw it corrects.

## Acceptance criteria

- [x] `grep -rE 'docs/specs/0[0-9][0-9]|[Ss]pecs? [0-9]|[Ss]pec-0[0-9][0-9]|[Pp]re-0[0-9][0-9]|[Pp]ost-0[0-9][0-9]' .claude/rules/*.md CLAUDE.md .mcp.json.example .gitleaks.toml .githooks/pre-commit .gitignore` returns zero matches — no concrete-numbered spec pointer (path, prose, or hyphenated `spec-NNN` / `pre-NNN` / `post-NNN` form) survives in any fork-bound file. The generic naming-convention scheme `docs/specs/NNN-<slug>/` (literal `NNN`, no concrete digits) is permitted and expected to remain in `.claude/rules/spec-driven.md`, which documents the convention itself. (Original AC1 grepped only `docs/specs/0NN` over rules + CLAUDE.md; the pattern was widened during implementation — see notes.md § Deviations — because the narrow form missed the prose and hyphenated cases.)

- [x] No CLAUDE.md capacity section begins with a `Spec NNN:` / `Specs NNN+NNN:` prefix; capacity sections describe the capacity operationally with no design-memory pointer.

- [x] The `## PHP / Laravel` section no longer exists in CLAUDE.md. PHP/Laravel detection is mentioned inline in the capacity sections that already enumerate detected stacks (validator, supply-chain, runtime-introspect, lint, etc.), the same way `## Lint validator` already names "Biome for JS/TS, Ruff for Python".

- [x] `.claude/rules/php-laravel-support.md` is retained unchanged in scope — it is correctly `paths:`-scoped (loads only when `composer.json` / `artisan` is present) and does not propagate cost to non-PHP forks.

- [x] **Scenario: capacity↔spec linkage stays discoverable for Agent0 maintainers**
  - **Given** the design-memory pointers have been stripped from CLAUDE.md and the rule files
  - **When** an Agent0 maintainer needs the spec that designed a given capacity
  - **Then** `.claude/memory/capacity-spec-index.md` maps every capacity to its originating spec(s), and `.claude/memory/MEMORY.md` carries a one-line index pointer to it

- [x] **Scenario: a fresh fork inherits clean fork-bound content**
  - **Given** a new fork that runs `sync-harness.sh --apply` against Agent0 at or after spec 070
  - **When** the fork's agent loads CLAUDE.md and `.claude/rules/*.md`
  - **Then** no dangling `docs/specs/0NN-*` pointer and no `## PHP / Laravel` per-stack chapter appears in the fork's loaded context

- [x] **Scenario: the discipline file does not itself propagate**
  - **Given** `.claude/memory/propagation-hygiene.md` documenting the fork-bound-content discipline
  - **When** the `sync-harness.sh` manifest is checked for that path
  - **Then** the file is absent from the manifest — `.claude/memory/` content is never propagated, so the discipline (a maintainer-scoped mandate, inert in a leaf fork) does not reproduce the leak it forbids

- [x] `.claude/memory/propagation-hygiene.md` exists, names the fork-bound file class (everything in the sync-harness manifest + CLAUDE.md capacity sections), states the no-Agent0-internal-pointer mandate, and points maintainers at the non-propagated buckets (`.claude/memory/`, `docs/specs/`) for design memory.

## Non-goals

- **General CLAUDE.md bloat.** CLAUDE.md carries ~25 always-loaded capacity sections; whether a fork should inherit all of them in this annotated form is a larger, separate question. 070 only de-leaks and de-stacks — it does not prune or restructure the section set.
- **Retroactively cleaning already-synced forks.** The CLAUDE.md sync merge is append-only — deleting `## PHP / Laravel` from Agent0 does not remove it from forks that already synced it. Fixing the merge to support section removal is a separate spec; 070 leaves the orphan in pre-070 forks.
- **De-citationing `.claude/hooks/*.sh` / `.claude/tools/*.sh` / `.claude/skills/` comments.** Spec citations in those shell-script comments and `SKILL.md` bodies are out of scope for v1 — they are code comments, not instruction context loaded the way CLAUDE.md and rules are. Candidate follow-up if the inventory shows material noise. (The four root config/hook files — `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore` — *were* de-citationed in-session 2026-05-21 at user request; see notes.md § Deviations.)
- **Transform-on-propagate.** Stripping citations during the sync copy is explicitly rejected (see plan) — it would break spec 068's SHA-baseline reconciliation. The fix is source-clean content, not a content-transforming sync.
- **No enforcement hook.** v1 ships the discipline as memory only; a `PostToolUse(Write)` / validator check that detects new leaks is deferred per the rule-of-three demand test (`.claude/memory/feedback_speculative_observability.md`).

## Open questions

- [x] After de-leaking, should each rule's stripped design-memory pointer be replaced by nothing, or by a neutral phrase? It must NOT point at `.claude/memory/capacity-spec-index.md` either — that path also does not propagate, recreating the dangling-pointer flaw. Leaning: replace with nothing; the rule describes the capacity and stops. Owner: resolved at plan time.
- [x] `.claude/rules/memory-placement.md` states project memory is "factual reference, NOT behavioral mandate", yet `.claude/memory/propagation-hygiene.md` is a maintainer discipline. Precedent exists (`agent0-purpose.md` holds a quasi-discipline). Decide during implementation whether to add a one-line carve-out to `memory-placement.md` or rely on precedent. Non-blocking.
- [x] Does the inventory surface concrete-spec pointers in fork-bound files beyond CLAUDE.md + `.claude/rules/` (e.g. `.mcp.json.example`, `.gitleaks.toml`)? Resolve by running the inventory in task 1; expand scope only if found.

## Context / references

- The two canonical flaws were surfaced in conversation 2026-05-21: the `## PHP / Laravel` per-stack section, then the systemic spec-citation leak.
- `.claude/rules/harness-sync.md` — the propagation manifest and the append-only CLAUDE.md merge semantics this spec works within.
- `docs/specs/068-harness-sync-baseline-reconciliation/` — the SHA-baseline 3-way reconciliation that forbids transform-on-propagate and makes source-clean content the only viable fix.
- `.claude/rules/memory-placement.md` — the 3-bucket model; 070 exposes its gap (no explicit slot for a non-propagating maintainer discipline).
- `.claude/memory/feedback_agent0_changes_ship_via_rules_not_memory.md` — the propagation-boundary principle this spec generalises.
- `docs/specs/047-php-laravel-support/` — origin of the `## PHP / Laravel` section being collapsed (this spec, being under `docs/specs/`, cites freely — only CLAUDE.md and rules are constrained).
