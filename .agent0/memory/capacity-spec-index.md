---
name: Capacity → spec index
description: Which Agent0 spec(s) designed each capacity — Agent0-internal index relocated
  by spec 070 to keep fork-bound files free of docs/specs/ pointers.
metadata:
  type: reference
  created_at: '2026-05-21T12:01:55-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---
# Capacity → spec index

The design-memory linkage between each Agent0 capacity and the spec(s) that designed it.

**Why this file exists.** CLAUDE.md capacity sections and `.claude/rules/*.md` propagate to forks via sync-harness; `docs/specs/` never does. A `Spec NNN:` citation or a `docs/specs/NNN-*/` pointer inside a propagated file is therefore a dangling reference in every fork. Spec 070 (propagation-hygiene) stripped those pointers from the fork-bound files and relocated the linkage here — `.agent0/memory/` is git-tracked but not in the sync-harness manifest, so this index stays Agent0-internal. An Agent0 maintainer who needs the rationale behind a capacity looks it up here, then reads `docs/specs/NNN-<slug>/`.

This index is Agent0-internal. Do not cite it from CLAUDE.md or `.claude/rules/*.md` — that would recreate the dangling-pointer flaw (the index does not propagate either). See `.agent0/memory/propagation-hygiene.md` for the discipline.

## Governance & delegation

| Capacity / rule | Origin spec | Extending specs |
|---|---|---|
| Governance gate | `001-governance-gate` | — |
| Delegation (`delegation.md`) | `002-delegation` | `030-session-edit-attribution` (audit actor), `061-subagent-stop-hook` (close rows), `063-worktree-isolated-subagents`, `067-parallel-edit-validation` (validator-cascade) |
| User prompt framing (`user-prompt-framing.md`) | `035-user-prompt-framing` | — |

## Verification & validation

| Capacity / rule | Origin spec | Extending specs |
|---|---|---|
| TDD (`tdd.md`) | `005-tdd` | — |
| BDD / acceptance-scenario shape | `004-bdd` | — |
| Lint validator (`lint-validator.md`) | `013-lint-validator-extension` | — |
| Typecheck advisory (`typecheck-advisory.md`) | no dedicated spec — shipped as a validator fix (shrnk-mono dogfood 2026-05-12); lineage in `013` / `015` | — |
| Runtime introspect (`runtime-introspect.md`) | `011-runtime-introspect` | `020-runtime-capture-on-failure`, `022-runtime-introspect-cargo` |
| Goal skill | `062-goal-skill` | — |

## Secrets

| Capacity / rule | Origin spec | Extending specs |
|---|---|---|
| Secrets scan (`secrets-scan.md`) | `006-secrets-scan`, `007-secrets-scan-timing` | `018-githooks-activation-hint`, `112-prune-supply-chain-and-secrets-advise` (removed the soft Edit-time advise hook) |

_Supply chain (`008`/`009`/`109`) was removed by `112-prune-supply-chain-and-secrets-advise` — the install-time block was the wrong shape; vuln-audit is the replacement direction._

## Harness propagation & session state

| Capacity / rule | Origin spec | Extending specs |
|---|---|---|
| Harness sync (`harness-sync.md`) | `016-harness-sync` | `058-claude-md-managed-block`, `068-harness-sync-baseline-reconciliation` |
| Propagation hygiene (`.agent0/memory/propagation-hygiene.md`) | `070-propagation-hygiene` | — |
| Session state isolation | `017-session-state-isolation` | — |
| Session handoff / stop (`session-handoff.md`) | `023-session-stop-noop-aware` | `030-session-edit-attribution`, `061-subagent-stop-hook` |
| Project memory (`memory-placement.md`) | `019-project-memory` | — |
| Compaction continuity (`.agent0/memory/compaction-continuity.md`) | no dedicated spec dir | — |
| Rule load debug (`.agent0/memory/rule-load-debug.md`) | no dedicated spec dir | — |

## MCP & browser

| Capacity / rule | Origin spec | Extending specs |
|---|---|---|
| MCP recipes (templates only — `.mcp.json.example`, `.codex/config.toml.example`) | `012-mcp-recipes` | `014-mcp-recipes-extras`, `015-monorepo-stack-detect`; curation + hint decommissioned 2026-05-27 (no spec) |
| Browser auth (`browser-auth.md`) | `021-browser-auth-workflow` | renamed from `mcp-recipes.md` § Authenticated workflow when curation was decommissioned 2026-05-27 |

## Skills, SDD & product

| Capacity / rule | Origin spec | Extending specs |
|---|---|---|
| Skill compliance toolkit | `033-skill-compliance-toolkit` | — |
| SDD workflow (`spec-driven.md`) | `004-bdd` (acceptance-scenario shape) | `028-sdd-refine-interview`, `029-sdd-list-in-flight`, `046-sdd-in-flight-notes` |
| Brainstorm | `031-brainstorm` | — |
| Reminders (`reminders.md`) | `003-reminders` | — |
| Routines (`routines.md`) | `064-project-scoped-routines` | — |
| Artifact budgets (`artifact-budgets.md`) | `065-artifact-budget-discipline` | — |
| Product skill | `048-product-skill-foundation` (current) | lineage `045` ← `036` ← `034`; parent design `032-pipeline-industry-alignment`; OD vendor `027` / `049`; fixes `051`–`057`, `059`, `066`, `069`; discontinued MCP `025` / `026` |

## Stack support

| Capacity / rule | Origin spec | Extending specs |
|---|---|---|
| PHP / Laravel (`php-laravel-support.md`) | `047-php-laravel-support` | — |

## Other specs (no fork-propagated rule)

| Spec | Note |
|---|---|
| `024-public-landing` | public landing page; not a harness capacity |
| `060-harness-gaps-2026` | umbrella spec — tracks closure of harness-gap follow-ups |

## Base conventions with no originating spec

`language.md` and `research-before-proposing.md` are base behavioral conventions — they predate or sit outside the numbered-spec workflow and have no `docs/specs/` dir.
