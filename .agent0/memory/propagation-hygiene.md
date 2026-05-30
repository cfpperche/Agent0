---
name: Propagation hygiene
description: Maintainer discipline — shipped files (CLAUDE.md, .agent0/context/rules/,
  sync manifest) must carry no Agent0-internal pointers. Read before editing CLAUDE.md
  or a rule.
metadata:
  type: project
  created_at: '2026-05-21T12:01:55-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---
# Propagation hygiene

A maintainer discipline: **shipped files must carry no Agent0-internal pointers.** When you edit CLAUDE.md or a `.agent0/context/rules/*.md` file, the content you write will be copied verbatim into every consumer project by `sync-harness.sh`. Anything in it that only makes sense inside the Agent0 repo becomes dead weight — or a dangling pointer — in every consumer project.

This file is Agent0-internal (memory does not propagate). It records the discipline; it is not a rule. See `docs/specs/070-propagation-hygiene/` for the design.

## The shipped file class

A file is **shipped** if `sync-harness.sh` propagates it to consumer projects. That is everything in the sync manifest:

- `.claude/hooks/*.sh`, `.agent0/context/rules/*.md`, `.agent0/tools/*.sh`, `.agent0/validators/*.sh`, `.claude/skills/`, `.agent0/tests/`, `.claude/agents/`
- `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`
- CLAUDE.md's `## ` capacity sections (structured-merge-appended into a consumer project's CLAUDE.md)

**Not** shipped, by design: `docs/specs/`, `.agent0/memory/` (ships only `.gitkeep`), `src/`, the consumer project's own `tests/`, package manifests. These never travel.

**Explicit exclusions inside the sync manifest** — `COPY_CHECK_EXCLUDE` in `sync-harness.sh` drops three paths from propagation despite their location in otherwise-shipped surface: `.agent0/hooks/propagation-advise.sh`, `.agent0/context/rules/propagation-advisory.md`, `.agent0/tests/propagation-advisory/*`. A companion filter in `merge_settings_json` strips the PostToolUse registration whose command points at `propagation-advise.sh`. This is the self-consistency resolution of the propagation-advisory mechanism: the discipline binds the upstream maintainer (this file's whole point), so shipping its enforcement to leaf consumer projects would emit false-positive advisories on a consumer project's legitimate own-spec / own-path content — the exact dangling-pointer flaw this discipline forbids. Same posture as `.agent0/memory/` shipping only `.gitkeep`: the capacity lives in Agent0, the *opt-in* for downstream re-propagators is manual copy of the 4 paths + the settings entry.

## The mandate

Content in a shipped file must be **consumer-facing operational documentation** — what the capacity does, how it behaves, how a consumer developer uses it. It must NOT contain **Agent0-internal design memory**:

- No concrete-spec pointers: `Spec 047:`, `(spec 013)`, `see docs/specs/047-php-laravel-support/`. In a consumer project `docs/specs/` does not exist, so the pointer is dangling — an agent that follows it wastes a turn; a reader is misled.
- No per-stack or per-spec chapters in always-loaded files. CLAUDE.md is loaded in full every session; a section organised on an unbounded axis (one chapter per stack, one per spec lineage) is permanent context cost for every consumer project. Organise by *capacity* (the bounded axis), and name stacks inline — the way `## Lint validator` names "Biome for JS/TS, Ruff for Python, Pint for PHP" in one section.
- No frontmatter `paths:` globs pointing at `docs/specs/0NN-*/**`. In a consumer project those dirs never exist, so the glob is inert cruft. Frontmatter file-path triggers must point only at files a consumer project actually has.

The two registers — consumer-facing operational doc, and Agent0-internal design memory — must stay physically separate. The first ships; the second does not.

## Where the design-memory linkage lives instead

The capacity↔spec linkage (which spec designed which capacity, the rationale, the lineage) is real and worth keeping — for the Agent0 maintainer. It lives in **`.agent0/memory/capacity-spec-index.md`**, which is git-tracked but not in the sync manifest. A maintainer who needs a capacity's design rationale looks it up there, then reads `docs/specs/NNN-<slug>/`.

Do NOT cite `capacity-spec-index.md` from a shipped file either — `.agent0/memory/` does not propagate, so a rule pointing at it recreates the dangling-pointer flaw. The linkage is one-directional: the index references the rules; the rules reference nothing.

## The one allowed `docs/specs/` reference

`.agent0/context/rules/spec-driven.md` and CLAUDE.md's `## Spec-driven development` section document the **naming convention** `docs/specs/NNN-<slug>/` — literal capital `NNN`, no digits. That is not a pointer to a specific spec; it is the scheme itself, and a consumer project uses the same scheme for its own specs. Keep it. The distinguishing test: a concrete number (`docs/specs/047-…`) is a leak; the literal `NNN` is the convention.

## Known limitation — already-synced consumer projects

The CLAUDE.md sync merge is **append-only**: it adds missing `## ` sections, it never removes them. Deleting a section from Agent0's CLAUDE.md (as spec 070 did with `## PHP / Laravel`) does NOT remove it from a consumer project that already synced it. Fresh consumer projects get the clean CLAUDE.md; pre-existing consumer projects keep the stale section until a future spec teaches the merge to remove sections. Rule files, by contrast, are whole-file synced — a de-leaked rule does propagate cleanly to existing consumer projects via the 3-way reconciliation (a consumer project that never customised the rule auto-updates).

## Mechanical enforcement — the advisory hook

The discipline is documented here; the **mechanical enforcement** lives in `.agent0/context/rules/propagation-advisory.md` + `.agent0/hooks/propagation-advise.sh`. The hook fires on Claude `PostToolUse(Edit|Write|MultiEdit)` and Codex `PostToolUse(apply_patch)` (spec 113) against any file in the shipped surface and emits `propagation-advisory:` stderr lines per leak finding. Patterns covered: `spec-NNN`, `docs/specs/NNN`, `anthill`, `personal-path` (`/home/<user>/`), `memory-pointer` (`.agent0/memory/<file>.md`). Always non-blocking — same `<kind>-advisory:` shape as TDD / lint / typecheck advisories.

The hook + rule + tests are **Agent0-only** by construction — see § The shipped file class § *Explicit exclusions inside the sync manifest*. Tests still run against Agent0's copy (the 11 scenarios in `.agent0/tests/propagation-advisory/` are exercised here); the exclusion stops only the sync.

This is the rule-of-three promotion candidate: if the advisory empirically fires more than ~3 times per week on legitimate new leaks (not false positives), promote to a pre-commit gate OR a periodic `/routine`. Until then, the soft signal at edit-time is enough — drift is caught mid-flight, the maintainer fixes in the same edit cycle, no separate cleanup pass needed.

## Not-yet-cleaned surfaces (follow-up)

Spec 070 cleaned CLAUDE.md, `.agent0/context/rules/*.md`, and the four root config/hook files (`.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`) of `docs/specs/` spec-citation leaks. Follow-up status:

- **Memory `.agent0/memory/<file>.md` path-pointers — cleaned 2026-05-21 (070 follow-up #1).** 9 citation pointers across 6 rule files (`spec-driven`, `runtime-introspect`, `rule-load-debug`, `routines`, `user-prompt-framing`, `artifact-budgets`) named a specific Agent0 memory file (`feedback_speculative_observability.md`, `cc-platform-hooks.md`). `.agent0/memory/` ships only `.gitkeep`, so each was a dangling pointer in a consumer project — same shape as the spec-citation leak, distinct cause. Stripped per spec 070's resolved OQ1: drop the pointer, keep the operational concept (the rule still describes "rule-of-three demand test" / the 29-event behavior, it just no longer cites where Agent0 records it). The two `.agent0/memory/MEMORY.md` mentions in CLAUDE.md § Memory and `memory-placement.md` were deliberately KEPT — `MEMORY.md` is the index-file *name* (the scheme a consumer project reuses for its own memory bucket), not an Agent0-specific file; same carve-out as the literal `NNN` in `docs/specs/NNN-<slug>/`. A consequential-staleness fix rode along: `memory-placement.md` § Project memory claimed memory discovery happens "via cross-references from specific rule docs" — the exact cross-references this cleanup removed — so that clause was dropped.
- **Memory basenames-as-examples — residual, not yet cleaned.** A softer adjacent form surfaced during the 2026-05-21 path-pointer sweep: bare memory-file *basenames* used as illustrative examples — `routines.md` (`cc-platform-hooks.md` in two routine examples), `memory-placement.md` § buckets (`agent0-purpose.md`, `visibility-intent.md`, `cc-platform-hooks.md`, `propagation-hygiene.md` listed as "concrete examples currently in this bucket"). These are pedagogical, not navigable pointers; cleaning them means rewriting examples to generic ones — an editorial change, deferred rather than silently folded into the mechanical path-pointer sweep.
- **Code comments in `.claude/hooks/*.sh` / `.agent0/tools/*.sh` / `.claude/skills/`** — `#`-style spec citations in shell-script comments and `SKILL.md` bodies. Lower harm: code comments, not instruction context loaded the way CLAUDE.md and rules are. (The *generated-output* citations in `sync-harness.sh` — `printf` text emitting `(spec 058)` into a consumer project's migration-candidate banner and diverged-sections report — were a genuine leak, not mere comments, since the generated content lands in consumer-loaded context; cleaned 2026-05-21 alongside spec 072. Only inert code comments now remain.)

When a shipped file is next touched, clean the remaining surfaces in passing if cheap.

## Why this is memory, not a rule

The discipline binds whoever maintains content that propagates — in Agent0, the maintainer. A leaf consumer project consumes the harness and propagates to nothing, so the discipline has no actor to bind there. A `propagation-hygiene.md` *rule* would itself be Agent0-internal content shipped to consumer projects where it is inert — the exact flaw it forbids. So it lives in memory. The principle correctly flags its own would-be violation; that self-consistency check is the point. See `memory-placement.md` § Project memory for the "maintainer-only discipline → memory" carve-out.
