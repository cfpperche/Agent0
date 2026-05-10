# Agent0 — base repository

Starting point for new software projects. Replace the placeholder sections below as the project evolves.

## Working agreement

These rules apply in every project derived from Agent0. They are part of the template — keep them unless a project-specific reason demands otherwise.

### Research before proposing

For any task that requires planning (configuration, architecture, tool choice, non-trivial technical decisions), do not propose a solution from prior knowledge alone. Run web research first — `WebSearch` / `WebFetch`, or the `claude-code-guide` agent for Claude Code / SDK / API topics — until the subject is well understood, then present options or a plan. Cite sources. Mechanical, obvious tasks (rename a variable, read a file, run a test) do not require research.

### Language

All communication and repository artifacts default to English. The user may explicitly request another language for a specific message or artifact, but the default is English.

### Memory placement

When saving a learning, fact, or rule, route by audience:
- **Project-shared** (any agent or developer working on this repo benefits) → `./CLAUDE.md` or `./.claude/rules/<topic>.md` (git-tracked).
- **Personal / user-specific** (only this user, only this machine) → auto-memory at `~/.claude/projects/<path>/memory/` (not git-tracked).
- **Path-scoped project rules** (only relevant when working on specific files) → `./.claude/rules/<topic>.md` with `paths:` frontmatter.

Default to project-shared when in doubt. Personal stays personal only when it's clearly about preferences, style, or context that wouldn't help anyone else.

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
