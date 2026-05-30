---
name: Agent0 base repo purpose
description: /home/goat/Agent0 is the user's base/template repository for all new
  software projects
metadata:
  type: project
  created_at: '2026-05-11T19:33:20-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---
`/home/goat/Agent0` is a **reusable base/template repository** for starting new software projects. "Agent0" is a generic placeholder name — it is not a specific product. Bootstrapped on 2026-05-10 with minimal Claude Code config: placeholder `CLAUDE.md` at the root, `.claude/settings.json` with `defaultMode: "bypassPermissions"`, empty `.claude/skills/` and `.claude/agents/` directories, `.gitignore` for `settings.local.json` / `CLAUDE.local.md` / `.claude/projects/`. Renamed from "atelier" to "Agent0" on the same day, all artifacts switched to English.

**Why:** The user wants a consistent starter they can duplicate/clone for each new project, instead of configuring Claude Code from scratch every time.

**Agent0 is *only* a template, forever.** It will never grow its own stack, app code, or production deploy target. Confirmed by user 2026-05-10: "nos somos e seremos apenas templates para outros projetos mesmo, nao temos stack". So when assessing readiness, treat empty `CLAUDE.md` placeholders, inert validator (no stack detected), and absent build/test commands as *intended features of being a template*, not pending work. The fork fills them. Do not list them as gaps when asked "is it ready?".

**How to apply:**
- Changes here must stay **generic** (no assumed language/framework). Before adding anything Python/Node/Go-specific, ask — it can break the template.
- Permission mode is `bypassPermissions` by explicit user choice — tools can execute without confirmation by default. Still keep caution around destructive actions (rm -rf, push --force, etc.) per system prompt rules.
- `CLAUDE.md` has a "Working agreement" section at the top with **template-stable rules** (research-before-proposing, English-only) — these travel with every clone and should not be removed in derived projects unless there's a specific reason. Below it are placeholder sections (Overview, Stack, Build & test, Conventions, Gotchas) to be filled in per project.
- `.claude/skills/` and `.claude/agents/` are empty with `.gitkeep` — that's where custom slash commands and subagents go when created.
- Statusline is **not** shipped by the harness — it lives in the operator's user-global Claude config (`~/.claude/settings.json`) and renders across every project uniformly. Extracted from the harness 2026-05-27; see `.agent0/context/rules/harness-sync.md` § *Gotchas* for the propagation lessons that informed the extraction.
- Remote: `git@github.com:cfpperche/Agent0.git` (public). Tracked branch: `main`.
