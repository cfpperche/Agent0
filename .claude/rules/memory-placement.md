# Memory placement

When saving a learning, fact, or rule, route by audience:

- **Project-shared** (any agent or developer working on this repo benefits) → `./CLAUDE.md` or `./.claude/rules/<topic>.md` (git-tracked).
- **Personal / user-specific** (only this user, only this machine) → auto-memory at `~/.claude/projects/<path>/memory/` (not git-tracked).
- **Path-scoped project rules** (only relevant when working on specific files) → `./.claude/rules/<topic>.md` with `paths:` frontmatter.

Default to project-shared when in doubt. Personal stays personal only when it's clearly about preferences, style, or context that wouldn't help anyone else.
