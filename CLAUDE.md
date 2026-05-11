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

## Spec-driven development

Non-trivial work is spec-first: write intent before code under `docs/specs/NNN-<slug>/{spec,plan,tasks}.md`. Specs are dual-consumer design memory — humans read them for review/audit/validation, agents read them to guide execution (acceptance criteria, approach, task order). `.claude/` is reserved for harness configuration (rules, skills, hooks) that the Claude Code runtime consumes to shape its own behavior. The `/sdd` skill scaffolds and progresses these (`/sdd new <slug>`, `/sdd plan`, `/sdd tasks`, `/sdd list`). See `.claude/rules/spec-driven.md` for when to apply and when to skip.

## Delegation

Sub-agent dispatches via the `Agent` tool are gated by `.claude/hooks/delegation-gate.sh`: every call must use the 5-field handoff (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN) so the delegated agent has scope, constraints, and a verifiable outcome instead of inventing its own framing. Edits made by delegated sub-agents are then re-validated by `.claude/hooks/post-edit-validate.sh`, which runs the project validator (`.claude/validators/run.sh`, auto-detects bun/pnpm/npm/python/go/rust) and blocks the sub-agent into a fix-then-retry loop on failure (capped by `CLAUDE_DELEGATION_LOOP_BUDGET`, default 5). Parent edits are exempt; the audit log lives at `.claude/delegation-audit.jsonl`. Same `# OVERRIDE: <reason ≥10 chars>` escape as the governance gate. See `.claude/rules/delegation.md`.

## Test-driven development

TDD is a *cultural* discipline reinforced by the validator — not a blocking gate. Production code follows red → green → refactor; tests land in the same diff that introduces the behavior they cover. When a delegated sub-agent edits production files in a project with a detected test stack, the validator appends a non-blocking `warnings` entry that the post-edit hook surfaces to stderr with a `tdd-advisory:` prefix; the agent should add the missing test before declaring done unless the change is genuinely test-exempt (rename, comment, doc, dependency bump). The `# OVERRIDE: tdd-exempt: <reason ≥10 chars>` shape on a brief documents deliberate skips. BDD scenarios from `spec.md` map naturally to test names. See `.claude/rules/tdd.md`.

## Secrets scan

Two layers (spec 007): the native `.githooks/pre-commit` runs gitleaks over the staged diff at git's actual commit moment and is the primary block; the Claude Code preflight `.claude/hooks/secrets-scan.sh` (PreToolUse Bash) gates dangerous command shapes (compound `git add && git commit`, `git commit -a`, `--no-verify`), parses the override marker, and bridges it across via `CLAUDE_SECRETS_OVERRIDE_REASON`. Activation per-fork: `git config core.hooksPath .githooks` after `git init` (manual on purpose — Lazarus vector). Same `# OVERRIDE: <reason ≥10 chars>` escape as the other gates (multi-line form: marker on its own line); `CLAUDE_SKIP_SECRETS_SCAN=1` disables both layers for throwaway sessions; `CLAUDE_SECRETS_ADVISE_ON_EDIT=1` opts into the soft `secrets-advisory:` on sub-agent edits. Both layers fail open when gitleaks is absent. See `.claude/rules/secrets-scan.md`.

## Supply chain

Two-layer capacity (specs 008+009): a `PreToolUse(Bash)` preflight (`.claude/hooks/supply-chain-scan.sh`) **blocks** dep-mutating commands across 10 managers (npm/pnpm/yarn/bun/pip/uv/poetry/pdm/cargo/go) by default with an exit-2 corrective stderr template, and a `PostToolUse(Edit|Write|MultiEdit)` hook (`.claude/hooks/supply-chain-advise.sh`) flags sub-agent edits to manifest/lockfile basenames (`package.json`, `Cargo.toml`, etc.) as advisory-only (basename match has too high an FP rate to block on). Each Bash match writes a JSONL row to `.claude/supply-chain-audit.jsonl` with `decision` in `{block, block-override, advisory, advisory-override, skip-not-install}`. Same `# OVERRIDE: <reason ≥10 chars>` escape (multi-line form); a valid override records `decision: "block-override"` and suppresses both the block and the stderr template. `CLAUDE_SUPPLY_CHAIN_BLOCK=0` falls back to spec-008 advisory-only mode; `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` disables both layers for throwaway sessions. See `.claude/rules/supply-chain.md`.

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

`.claude/COMPACT_NOTES.md` is regenerated by the PreCompact hook with the last 12 turns verbatim — that file is the source of truth for raw signal across the compaction boundary, so the summary itself can stay terse.
