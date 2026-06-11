# Agent0

Agent0 is a portable governance and evidence harness for coding agents.

It is not another coding agent, IDE, hosted control plane, or application framework. It is a reusable base repository that gives existing agent runtimes - currently Claude Code and Codex - a disciplined project loop: intent before code, bounded delegation, validation evidence, session handoff, safety checks, and syncable harness state.

**North star:** clone a new project, open it in an agent runtime, and reach the first validated commit without losing context or bypassing the project's discipline.

-> **Landing page:** [cfpperche.github.io/Agent0](https://cfpperche.github.io/Agent0/) (en / pt / es)

## Why This Exists

Coding agents already write, edit, and run code. That part is becoming commodity. The harder problem is making their work repeatable and reviewable inside real projects.

Agent0 focuses on the layer vendors are least likely to standardize across competitors:

- **Portability:** shared rules, tools, skills, and hooks across Claude Code and Codex where the runtimes allow it.
- **Evidence:** specs, acceptance criteria, validators, visual contracts, audit logs, and proof commands instead of "looks done" claims.
- **Continuity:** a runtime-neutral handoff, memory, reminders, routines, and status surfaces so the next session can resume from facts.
- **Safety:** preflight checks for dangerous command shapes, secrets scanning, dependency audit hooks, and explicit override trails.
- **Replication:** `sync-harness.sh` updates consumer projects conservatively without touching product code.

Agent0 has no application stack. The project using it chooses the language, framework, deployment model, and product conventions.

## Quick Start

```bash
# Clone Agent0 as the seed of a new project
git clone git@github.com:cfpperche/Agent0.git my-new-project
cd my-new-project
rm -rf .git && git init

# Optional: point at your own remote
git remote add origin git@github.com:you/my-new-project.git

# Optional but recommended: activate the native git hooks
git config core.hooksPath .githooks
```

Then open the directory in Claude Code or Codex.

- Claude Code reads `CLAUDE.md` and project hooks from `.claude/settings.json`.
- Codex reads `AGENTS.md` and, after project hook trust, tracked hooks from `.codex/hooks.json`.
- Both runtimes share the Agent0-owned source under `.agent0/`.

For an existing project that already consumes Agent0, update the harness with:

```bash
bash .agent0/tools/sync-harness.sh --agent0-path=/path/to/Agent0 --check .
bash .agent0/tools/sync-harness.sh --agent0-path=/path/to/Agent0 --apply .
```

`--check` is read-only. `--apply` updates harness files through 3-way baseline reconciliation and never touches product code such as `src/`, package manifests, or app tests.

## The Work Loop

Agent0 is useful when the change needs a durable trail.

1. **Frame the work.** Non-trivial changes start in `docs/specs/NNN-<slug>/spec.md`: what changes, why, acceptance criteria, non-goals, open questions.
2. **Plan before editing.** `plan.md` records the approach, files to touch, rejected alternatives, and risks.
3. **Execute as a checklist.** `tasks.md` turns the plan into ordered work and verification steps.
4. **Prove the result.** The repo's validator, declared proof commands, visual-contract evidence, and audit logs are kept with the work.
5. **Hand off honestly.** `.agent0/HANDOFF.md` records current state, active work, next actions, and decisions for the next session.

Tiny edits skip the spec. Skipping the spec does not skip proof: a UI change still needs browser evidence, a code change still needs the repo's normal validation, and a risky command still needs an explicit reason.

## What Ships

The harness is a set of plain repo files:

- `AGENTS.md` and `CLAUDE.md` - runtime entrypoints.
- `.agent0/context/rules/` - behavior rules and capability docs.
- `.agent0/hooks/` - runtime-neutral lifecycle hooks.
- `.agent0/tools/` - shell tools for sync, status, validation helpers, media utilities, browser verification, and related harness tasks.
- `.agent0/skills/` plus runtime discovery links - portable skill bodies where the runtimes support them.
- `.agent0/validators/run.sh` - stack-aware validation.
- `.githooks/pre-commit` and `.gitleaks.toml` - optional native git-side protection.
- `docs/specs/` - historical design and delivery records.
- `site/` - the public landing/documentation site.

The detailed inventory lives in `.agent0/context/rules/runtime-capabilities.md` and the landing page. The README intentionally does not lead with a capacity count; the product is the disciplined loop, not a catalog.

## Proof And Limits

Current evidence is local and repository-backed:

- Agent0 is developed using its own spec-first workflow.
- Claude Code and Codex have distinct entrypoints and shared Agent0-owned rules/tools.
- Several capacities have regression suites under `.agent0/tests/`.
- `sync-harness.sh` has been used to propagate the harness into local consumer projects.

This is not yet evidence of external adoption or commercial traction. See `docs/product/positioning-proof.md` for the current proof level and non-claims.

## Extending Agent0

New first-party harness capacity must pass scope admission before it is built. The default is to keep Agent0 a stack-neutral template/governance harness, not a product platform.

Read these before expanding the surface:

- `.agent0/context/rules/agent0-governance-doctrine.md`
- `.agent0/context/rules/scope-admission-governance.md`
- `.agent0/context/rules/spec-driven.md`
- `.agent0/context/rules/runtime-capabilities.md`

If the change is admitted, create a spec:

```bash
/sdd new my-capacity
/sdd plan
/sdd tasks
```

Then implement top-to-bottom, update the spec artifacts, run validation, and close the handoff.

## Graduated projects

⚡ **Tachyon** — a VSCode extension for multi-agent terminal orchestration — was incubated here
(specs 186–204) and graduated to its own repository on 2026-06-10:
[github.com/cfpperche/tachyon](https://github.com/cfpperche/tachyon). Its full history travelled
with it; the work remains in this repo's git log.

## License

MIT. See [LICENSE](LICENSE).
