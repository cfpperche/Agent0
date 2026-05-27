---
name: User-global hooks shadow project hooks
description: User-global hooks under ~/.claude/hooks/ fire BEFORE project hooks; can
  shadow Agent0 capacities. If dogfood gives unexpected interception, check there
  first.
metadata:
  type: reference
  created_at: '2026-05-13T13:19:18-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---

# User-global hooks shadow project hooks

Claude Code's hook resolution stacks **user-global hooks (from `~/.claude/settings.json` or `~/.claude/hooks/`) AHEAD of project hooks (from `<project>/.claude/settings.json` or `<project>/.claude/hooks/`)** for the same event. A user-global `PreToolUse(Bash)` hook fires first; if it exits non-zero with a block decision, the project-side gate never runs.

This is a normal CC platform behavior, not a bug — but it has a non-obvious blast radius for Agent0 dogfooding: a single user-global pre-commit hook can make the project's native `.githooks/pre-commit` gitleaks block completely unreachable from inside Claude Code, because the user-global layer blocks the `git commit` Bash invocation before it ever reaches git's own commit pipeline.

## Concrete case (2026-05-13)

Dogfood of secrets-scan in shrnk-mono surfaced this: a `~/.claude/hooks/pre-commit-secrets-scan.sh` (user-installed, not Agent0-managed) registered as `PreToolUse(Bash)` matched any `git commit` shape with a fake-AKIA fixture in the diff and blocked it with its own grep pattern + an unrelated bypass env-var convention. Two consequences:

1. **The project's preflight `.claude/hooks/secrets-scan.sh` still fired and audited correctly** (`passthrough` rows in `.claude/secrets-audit.jsonl`), because both PreToolUse handlers run in sequence in the order CC registers them — the first one to exit non-zero blocks. So the project's audit log was honest.
2. **The project's NATIVE `.githooks/pre-commit` gitleaks layer never ran**, because git's commit pipeline was never reached. The user-global block returned before git was invoked.

The user-global hook's bypass env-var cannot be set mid-session via a `Bash` tool call — same sibling-process gotcha as `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` (see `.agent0/memory/runtime-introspect-maintenance.md` § Deep gotchas and `.agent0/memory/cc-platform-hooks.md` for the canonical statement). Disabling the user-global shadow requires either (a) editing `~/.claude/settings.json` to remove the hook registration, or (b) launching `claude` with the user-global hook's bypass env var pre-set in the shell.

## When to consult this memory

- An Agent0 capacity gate appears to fire "from somewhere else" — different error text, different env-var conventions, blocking on shapes the project-side gate doesn't recognize.
- Dogfood of `git commit` / `bun add` / any `Bash`-gated capacity returns unexpected output that doesn't match the project's stderr template.
- A test you wrote against the project's PreToolUse hook works in isolation but fails in a live session.

First diagnostic: `ls ~/.claude/hooks/` and `jq '.hooks' ~/.claude/settings.json 2>/dev/null`. Anything registered there fires before the project equivalent.

## Why this isn't an Agent0 design flaw

Agent0's posture is "project owns the project's harness; don't reach into the user's setup." A user-global hook is the user's environmental choice — Agent0 cannot detect or work around it without overstepping. The capacities still audit correctly (their JSONL rows are honest about what they saw); they just may not be the final word on whether the underlying operation was blocked.

The fork dogfood lesson is operational, not architectural: when validating end-to-end behavior of an Agent0 capacity inside Claude Code, audit `~/.claude/` for user-global hooks that overlap the capacity's event. If there's overlap, either run the dogfood outside Claude Code (raw shell `git commit`, raw `bun add`) or document the shadow as a known confound for that specific test.

## Cross-references

- `.claude/rules/secrets-scan.md` — project's two-layer secrets-scan capacity.
- `.agent0/memory/runtime-introspect-maintenance.md` § Deep gotchas — canonical statement of the hook-is-harness-sibling-not-Bash-child rule (same mechanism that prevents mid-session env-var injection).
- `.agent0/memory/cc-platform-hooks.md` — canonical CC hook event surface.
