# Agent0 — base repository

Starting point for new software projects. Replace the placeholder sections below as the project evolves. Behavior rules for any agent working on this repo live in `./.claude/rules/`.

## Overview

_Brief description of the project and its purpose._

## Stack

_Language, framework, main dependencies._

## Build & test

```bash
# build:
# test:
# lint:
```

## Conventions

_Style, patterns, architectural decisions — what's not obvious from the code._

## Gotchas

_Non-obvious behaviors, known pitfalls, context not captured in code._

<!-- AGENT0:BEGIN -->

## Spec-driven development

Non-trivial work is spec-first — intent before code under `docs/specs/NNN-<slug>/{spec,plan,tasks,notes}.md`, scaffolded and progressed by the `/sdd` skill. See `.claude/rules/spec-driven.md`.

## Runtime entrypoints

`CLAUDE.md` is the Claude Code entrypoint; `AGENTS.md` is the Codex entrypoint. This managed block is the shared Agent0 index; runtime support details live in `.claude/rules/runtime-capabilities.md`. `AGENTS.md` is baseline-tracked; Codex consumer project customization belongs in `AGENTS.override.md` or nested `AGENTS.md`.

## Runtime capabilities

`.claude/rules/runtime-capabilities.md` is the canonical provider-neutral matrix for Agent0 capability support across Claude Code, Codex CLI, and future runtimes. Consult it before assuming a `.claude/*` capability is native in a runtime.

## Session handoff

`.agent0/HANDOFF.md` is the canonical runtime-neutral handoff with four sections: Current State, Active Work, Next Actions, Decisions & Gotchas. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks, with `AGENTS.md` as the convention fallback. See `.claude/rules/session-handoff.md`.

## Delegation

`Agent` dispatches are gated: `.claude/hooks/delegation-gate.sh` enforces a 5-field handoff (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN), and `.claude/hooks/post-edit-validate.sh` re-validates sub-agent edits. See `.claude/rules/delegation.md`.

## User prompt framing

On a non-trivial prompt the main agent runs a 3-question mental check (TASK / CONTEXT / DONE clear?) and clarifies via `AskUserQuestion` before acting when ≥2 are unclear. Rule-only — no hook. See `.claude/rules/user-prompt-framing.md`.

## Test-driven development

Production code follows red → green → refactor with tests in the same diff; the validator emits a non-blocking `tdd-advisory:` when prod files move without a test. Cultural discipline, not a blocking gate. See `.claude/rules/tdd.md`.

## Secrets scan

Two layers — the native `.githooks/pre-commit` runs gitleaks over the staged diff at commit time; a `PreToolUse(Bash)` preflight (`.claude/hooks/secrets-scan.sh`) gates dangerous commit shapes. Activate per-consumer with `git config core.hooksPath .githooks`. See `.claude/rules/secrets-scan.md`.

## Supply chain

A `PreToolUse(Bash)` preflight (`.claude/hooks/supply-chain-scan.sh`) blocks dependency-install commands across 11 managers with an exit-2 corrective template + override marker; a `PostToolUse` hook advises on manifest/lockfile edits. See `.claude/rules/supply-chain.md`.

## Runtime introspect

`PreToolUse` / `PostToolUse(Bash)` hooks snapshot the last verifier run (test / build / typecheck / lint, allowlisted) to `.claude/.runtime-state/last-run.json`; read it back with `bash .claude/tools/probe.sh last-run`. See `.claude/rules/runtime-introspect.md`.

## MCP recipes

MCP server blocks for common external MCPs (Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, fal.ai) ship as copy-paste templates only: `.mcp.json.example` for Claude Code, `.codex/config.toml.example` for Codex CLI. Each block is `enabled = false` / commented by default and uses env-var indirection for any secret (`bearer_token_env_var`, `env_vars`). Consult the upstream README of each MCP for activation specifics, runtime requirements, and security stance — Agent0 ships the templates, not curated reference docs.

## Image generation

Opt-in capacity for AI image generation via fal.ai MCP — the `/image` skill produces draft mockups (FLUX schnell, ~$0.003/img, gitignored) and brand assets (gpt-image-2 or Imagen 4 Ultra, $0.04-$0.20/img, tracked) with mandatory `--tier` flag, pre-call cost printing, and a JSONL manifest of every call. Activation is a `.mcp.json` edit + `FAL_KEY` env. See `.claude/rules/image-gen.md`.

## Harness sync

`.claude/tools/sync-harness.sh` brings a consumer project's harness up to date with Agent0 via 3-way baseline reconciliation against `.claude/harness-sync-baseline.json` — stale files auto-update, consumer-customized files refuse without `--force`, never touches product code. See `.claude/rules/harness-sync.md`.

## Lint validator

The post-edit validator runs the consumer project's idiomatic linter — Biome (JS/TS), Ruff (Python), Pint + PHPStan/Larastan (PHP) — when the manifest declares it; missing-but-declared emits a non-blocking `lint-advisory:`. See `.claude/rules/lint-validator.md`.

## Typecheck advisory

The validator runs a typecheck step only when the consumer project declares the primitive (a `tsconfig.json`, or a `typecheck` script in `package.json`); otherwise it emits `typecheck-advisory:` and skips. See `.claude/rules/typecheck-advisory.md`.

## Memory

Factual project knowledge lives in `.agent0/memory/<topic>.md`; the trigger-read index is `.agent0/memory/MEMORY.md`. Content is git-tracked for this project, but not shipped to consumers.
Read the index when work touches project architecture, first-party capacities, `.claude/rules/`, `.claude/hooks/`, `.claude/skills/`, `.claude/tools/sync-harness.sh`, `.claude/rules/runtime-capabilities.md`, or `.agent0/memory/`.
Follow only relevant entries; ordinary reads do not mutate memory.
Claude uses `.claude/settings.json` hooks. Codex users opt in by copying `.codex/config.toml.example` to `.codex/config.toml` and uncommenting the Agent0 hook blocks.
Do not raw-edit `.agent0/memory/MEMORY.md`; edit entries and let projection regenerate it.
Hook-disabled memory edits must end with `bash .agent0/tools/memory-maintain.sh finalize <entry-path>`.
Without hooks, stale-memory readout is `bash .agent0/tools/memory-query.sh decay --readout`.
See `.claude/rules/memory-placement.md` § Multi-runtime usage.

## Browser auth

On an auth-gated URL with no saved state the agent emits `BROWSER_AUTH_REQUIRED: <host>`; the human logs in via a headed Playwright MCP session and the state (`.claude/.browser-state/<host>.json`) is reused for headless reads. See `.claude/rules/browser-auth.md`.

## Skill compliance

Every first-party `.claude/skills/*/SKILL.md` must pass the agentskills.io frontmatter spec; the `/skill` meta-skill scaffolds, audits, ports, and validates them, with three declared portability tiers. See `.claude/skills/skill/`.

## Product skill

`/product` is the foundation generator + design partner for the product lifecycle (idea → v1 → vN) — a multi-step industry-aligned pipeline producing the planning artifacts + a visual contract that hands off to SDD. See `.claude/skills/product/`.

## Routines

`.agent0/routines/<slug>.md` git-tracks recurring project work; an opt-in leader machine's cron enqueues each run for the next interactive session to dispatch via `/routine run <slug>`. See `.claude/rules/routines.md`.

## Artifact size cap

Artifact size is not a scope/quality signal — scope and quality are judged by the `/product` quality judge. The only size mechanism is a uniform 200 KB catastrophe cap (a dumb token-runaway circuit-breaker) plus the retained per-step `min_size` anti-stub floors; trim-loop and re-emit-at-smaller-scope stay forbidden. See `.claude/rules/artifact-budgets.md`.

## Compact Instructions

When summarizing this conversation for context compaction, prioritize keeping:

- The user's most recent intent and the *why* behind in-flight work (not just the *what*)
- Decisions made and rejected alternatives, with reasoning
- Open questions, blockers, and known gotchas hit during the session
- File paths and identifiers that anchor the work (so subsequent searches stay grounded)

Safe to compress:

- Verbatim tool output (file contents, command output) — re-read on demand
- Resolved sub-tasks where the outcome is already in `git log` or the code
- Exploratory tangents that didn't influence the final direction

`.claude/.compact-history/` snapshots are regenerated by the PreCompact hook with the last 12 turns verbatim — those files are the source of truth for raw signal across the compaction boundary, so the summary itself can stay terse.

<!-- AGENT0:END -->
