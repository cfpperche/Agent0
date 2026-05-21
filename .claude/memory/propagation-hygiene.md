# Propagation hygiene

A maintainer discipline: **fork-bound files must carry no Agent0-internal pointers.** When you edit CLAUDE.md or a `.claude/rules/*.md` file, the content you write will be copied verbatim into every fork by `sync-harness.sh`. Anything in it that only makes sense inside the Agent0 repo becomes dead weight — or a dangling pointer — in every fork.

This file is Agent0-internal (memory does not propagate). It records the discipline; it is not a rule. See `docs/specs/070-propagation-hygiene/` for the design.

## The fork-bound file class

A file is **fork-bound** if `sync-harness.sh` propagates it to forks. That is everything in the sync manifest:

- `.claude/hooks/*.sh`, `.claude/rules/*.md`, `.claude/tools/*.sh`, `.claude/validators/*.sh`, `.claude/skills/`, `.claude/tests/`, `.claude/agents/`
- `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`
- CLAUDE.md's `## ` capacity sections (structured-merge-appended into a fork's CLAUDE.md)

**Not** fork-bound, by design: `docs/specs/`, `.claude/memory/` (ships only `.gitkeep`), `src/`, the fork's own `tests/`, package manifests. These never travel.

## The mandate

Content in a fork-bound file must be **fork-facing operational documentation** — what the capacity does, how it behaves, how a fork developer uses it. It must NOT contain **Agent0-internal design memory**:

- No concrete-spec pointers: `Spec 047:`, `(spec 013)`, `see docs/specs/047-php-laravel-support/`. In a fork `docs/specs/` does not exist, so the pointer is dangling — an agent that follows it wastes a turn; a reader is misled.
- No per-stack or per-spec chapters in always-loaded files. CLAUDE.md is loaded in full every session; a section organised on an unbounded axis (one chapter per stack, one per spec lineage) is permanent context cost for every fork. Organise by *capacity* (the bounded axis), and name stacks inline — the way `## Lint validator` names "Biome for JS/TS, Ruff for Python, Pint for PHP" in one section.
- No frontmatter `paths:` globs pointing at `docs/specs/0NN-*/**`. In a fork those dirs never exist, so the glob is inert cruft. Frontmatter file-path triggers must point only at files a fork actually has.

The two registers — fork-facing operational doc, and Agent0-internal design memory — must stay physically separate. The first ships; the second does not.

## Where the design-memory linkage lives instead

The capacity↔spec linkage (which spec designed which capacity, the rationale, the lineage) is real and worth keeping — for the Agent0 maintainer. It lives in **`.claude/memory/capacity-spec-index.md`**, which is git-tracked but not in the sync manifest. A maintainer who needs a capacity's design rationale looks it up there, then reads `docs/specs/NNN-<slug>/`.

Do NOT cite `capacity-spec-index.md` from a fork-bound file either — `.claude/memory/` does not propagate, so a rule pointing at it recreates the dangling-pointer flaw. The linkage is one-directional: the index references the rules; the rules reference nothing.

## The one allowed `docs/specs/` reference

`.claude/rules/spec-driven.md` and CLAUDE.md's `## Spec-driven development` section document the **naming convention** `docs/specs/NNN-<slug>/` — literal capital `NNN`, no digits. That is not a pointer to a specific spec; it is the scheme itself, and a fork uses the same scheme for its own specs. Keep it. The distinguishing test: a concrete number (`docs/specs/047-…`) is a leak; the literal `NNN` is the convention.

## Known limitation — already-synced forks

The CLAUDE.md sync merge is **append-only**: it adds missing `## ` sections, it never removes them. Deleting a section from Agent0's CLAUDE.md (as spec 070 did with `## PHP / Laravel`) does NOT remove it from a fork that already synced it. Fresh forks get the clean CLAUDE.md; pre-existing forks keep the stale section until a future spec teaches the merge to remove sections. Rule files, by contrast, are whole-file synced — a de-leaked rule does propagate cleanly to existing forks via the 3-way reconciliation (a fork that never customised the rule auto-updates).

## Not-yet-cleaned surfaces (follow-up)

Spec 070 cleaned CLAUDE.md, `.claude/rules/*.md`, and the four root config/hook files (`.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`) of `docs/specs/` spec-citation leaks. Follow-up status:

- **Memory `.claude/memory/<file>.md` path-pointers — cleaned 2026-05-21 (070 follow-up #1).** 9 citation pointers across 6 rule files (`spec-driven`, `runtime-introspect`, `rule-load-debug`, `routines`, `user-prompt-framing`, `artifact-budgets`) named a specific Agent0 memory file (`feedback_speculative_observability.md`, `cc-platform-hooks.md`). `.claude/memory/` ships only `.gitkeep`, so each was a dangling pointer in a fork — same shape as the spec-citation leak, distinct cause. Stripped per spec 070's resolved OQ1: drop the pointer, keep the operational concept (the rule still describes "rule-of-three demand test" / the 29-event behavior, it just no longer cites where Agent0 records it). The two `.claude/memory/MEMORY.md` mentions in CLAUDE.md § Memory and `memory-placement.md` were deliberately KEPT — `MEMORY.md` is the index-file *name* (the scheme a fork reuses for its own memory bucket), not an Agent0-specific file; same carve-out as the literal `NNN` in `docs/specs/NNN-<slug>/`. A consequential-staleness fix rode along: `memory-placement.md` § Project memory claimed memory discovery happens "via cross-references from specific rule docs" — the exact cross-references this cleanup removed — so that clause was dropped.
- **Memory basenames-as-examples — residual, not yet cleaned.** A softer adjacent form surfaced during the 2026-05-21 path-pointer sweep: bare memory-file *basenames* used as illustrative examples — `routines.md` (`cc-platform-hooks.md` in two routine examples), `memory-placement.md` § buckets (`agent0-purpose.md`, `visibility-intent.md`, `cc-platform-hooks.md`, `propagation-hygiene.md` listed as "concrete examples currently in this bucket"). These are pedagogical, not navigable pointers; cleaning them means rewriting examples to generic ones — an editorial change, deferred rather than silently folded into the mechanical path-pointer sweep.
- **Code comments in `.claude/hooks/*.sh` / `.claude/tools/*.sh` / `.claude/skills/`** — `#`-style spec citations in shell-script comments and `SKILL.md` bodies. Lower harm: code comments, not instruction context loaded the way CLAUDE.md and rules are. (The *generated-output* citations in `sync-harness.sh` — `printf` text emitting `(spec 058)` into a fork's migration-candidate banner and diverged-sections report — were a genuine leak, not mere comments, since the generated content lands in fork-loaded context; cleaned 2026-05-21 alongside spec 072. Only inert code comments now remain.)

When a fork-bound file is next touched, clean the remaining surfaces in passing if cheap.

## Why this is memory, not a rule

The discipline binds whoever maintains content that propagates — in Agent0, the maintainer. A leaf fork consumes the harness and propagates to nothing, so the discipline has no actor to bind there. A `propagation-hygiene.md` *rule* would itself be Agent0-internal content shipped to forks where it is inert — the exact flaw it forbids. So it lives in memory. The principle correctly flags its own would-be violation; that self-consistency check is the point. See `memory-placement.md` § Project memory for the "maintainer-only discipline → memory" carve-out.
