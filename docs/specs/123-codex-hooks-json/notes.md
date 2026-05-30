# 123 — codex-hooks-json — notes

## Design Decisions

### 2026-05-30 — parent — ship Codex hooks as tracked project config

Agent0 should ship Codex hooks the way it ships Claude hooks: as a project-owned harness file, not as
commented setup snippets. `.codex/hooks.json` is the tracked Codex counterpart to
`.claude/settings.json`; `.codex/config.toml.example` remains an MCP recipes template only.

### 2026-05-30 — parent — consumer-safe first

The initial tracked `.codex/hooks.json` includes only hooks whose scripts are propagated to consumer
projects. `propagation-advise.sh` remains maintainer-only because `sync-harness` currently excludes
that script and its rule/test surface from consumers. Shipping a hook registration for an excluded
script would create a dangling consumer hook.

## Gotchas

- Codex merges `hooks.json` with inline TOML hooks and may run both. The local dogfood TOML must not
  retain duplicate Agent0 hook registrations.
- Moving hook definitions from TOML to JSON changes trust hashes. A fresh TUI run must accept the new
  hook review before live proof counts.

## Dogfood

### 2026-05-30 — founder-opened fresh Codex TUI passed

Founder-provided live output from a fresh Codex TUI session after the `.codex/hooks.json` migration:

```text
PASS
injected block present: yes
event value(s): SessionStart, UserPromptSubmit
mode value(s): index, prompt-selected
source_dir value(s): .agent0/context/rules
selected value if present: language user-prompt-framing spec-driven session-handoff runtime-capabilities harness-sync memory-placement
one short gotcha if any: context byte cap omitted some selected fragment bodies
```

This closes the live requirement: natural Codex hook delivery through tracked `.codex/hooks.json`
made `AGENT0_CONTEXT_INJECTION` visible to the model for both startup index hydration and
prompt-selected context.

### Fresh Codex prompt

Paste this in a fresh Codex TUI session opened at `/home/goat/Agent0` after accepting hook review if
Codex prompts for it:

```text
Live-confirm Agent0 spec 123 Codex hooks.json migration.

Do not run shell commands. Do not inspect files. Do not invoke hooks manually. Use only the context already visible to you at startup, this user prompt, and any hook-injected context that arrived naturally in this fresh Codex TUI session.

Report exactly:
PASS or FAIL
injected block present: yes/no
event value(s):
mode value(s):
source_dir value(s):
selected value if present:
one short gotcha if any:
```

Acceptance signal: `PASS`, `injected block present: yes`, event values including both
`SessionStart` and `UserPromptSubmit`, and `source_dir: .agent0/context/rules`. This proves the model
received the natural hook-injected `AGENT0_CONTEXT_INJECTION` context through tracked
`.codex/hooks.json`.

## Validation

### 2026-05-30 — local suites passed

- `jq -e . .codex/hooks.json`
- `bash .agent0/tests/context-injection/run-all.sh`
- `bash .agent0/tests/session-handoff-multi-runtime/run-all.sh`
- `bash .agent0/tests/codex-mcp-recipes/run-all.sh`
- `bash .agent0/tests/runtime-capabilities/run-all.sh`
- `bash .agent0/tests/harness-sync/run-all.sh`
- `bash .agent0/tests/multi-runtime-readouts/05-hooks-json-parse.sh`
- `git diff --check -- ...` on touched spec 123 / Codex hooks / docs / tests / handoff files
- `rg` check confirmed local `.codex/config.toml` and `.codex/config.toml.example` do not contain Agent0
  inline hook registrations; `.codex/hooks.json` is not gitignored, while `.codex/config.toml` remains
  gitignored.
