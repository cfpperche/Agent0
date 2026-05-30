# Agent0

→ **Landing page:** [cfpperche.github.io/Agent0](https://cfpperche.github.io/Agent0/) (en · pt · es)

A reusable base/template repository for starting new software projects with [Claude Code](https://docs.claude.com/en/docs/claude-code) or Codex. Ships a working harness — hooks, rules, skills, and spec-driven workflow — so each new project starts with the discipline already wired up, not from a blank `.claude/`.

Agent0 itself has no application code and no stack. It is *only* a template. The fork chooses the language, fills in the placeholders, and inherits the harness.

## Quick start

```bash
# Clone as the seed of a new project
git clone git@github.com:cfpperche/Agent0.git my-new-project
cd my-new-project
rm -rf .git && git init

# Optional: point at your own remote
git remote add origin git@github.com:you/my-new-project.git
```

Then open the directory in Claude Code or Codex. Claude Code's `SessionStart` hook will surface `.agent0/HANDOFF.md` and any pending reminders automatically; Codex reads `AGENTS.md` as its native entrypoint and, after project hook trust, uses tracked `.codex/hooks.json` for the same handoff/context readouts.

## What you get

Eight capacities are live on `main`. Each one is documented in its own rule file (`.agent0/context/rules/<topic>.md`) and, where it was non-trivial, has a spec under `docs/specs/`.

| Capacity | Mechanism | Rule | Spec |
| --- | --- | --- | --- |
| Spec-driven development | `/sdd` skill scaffolds `docs/specs/NNN-<slug>/{spec,plan,tasks}.md` | `spec-driven.md` | — |
| Governance gate | `PreToolUse(Bash)` blocks destructive ops, hook bypass, blanket staging | — | `001-governance-gate/` |
| Delegation gate + stop-time verifier | 5-field handoff required for every `Agent` call (`delegation-gate.sh`); a runtime-neutral `SubagentStop` hook (`delegation-verify.sh`, Claude + Codex) runs the project validator once when a delegated sub-agent closes — block-then-one-continuation-then-partial-result, keyed by `agent_id` | `delegation.md` | `002-delegation/` + `111-delegation-verify-subagent-stop/` |
| Reminders | `/remind` skill writes `.claude/REMINDERS.md`, auto-read at session start | `reminders.md` | `003-reminders/` |
| BDD acceptance scenarios | `/sdd` template scaffolds Given/When/Then scenarios in `spec.md` | `spec-driven.md` § *Acceptance scenarios* | `004-bdd/` |
| TDD working agreement | Cultural red→green→refactor + non-blocking validator advisory when prod files move without tests | `tdd.md` | `005-tdd/` |
| Secrets scan | Layered: native `.githooks/pre-commit` runs gitleaks over the staged diff (primary block); `PreToolUse(Bash)` preflight gates command shape + parses override marker + bridges the override via env var to the native layer | `secrets-scan.md` | `006-secrets-scan/`, `007-secrets-scan-timing/` |

The override marker `# OVERRIDE: <reason ≥10 chars>` is honored by the governance, delegation, TDD, and secrets-scan gates. The reason is recorded in the audit log — `"skip"` / `"bypass"` are rejected.

## Per-fork checklist

1. **Fill in `CLAUDE.md` placeholders.** The Overview, Stack, Build & test, Conventions, and Gotchas sections are intentionally empty in the template. Replace them with your project's specifics. The `## Compact Instructions`, `## Spec-driven development`, `## Delegation`, and `## Test-driven development` sections are template-stable — leave them unless you have a reason.

2. **Activate the validator.** `.agent0/validators/run.sh` auto-detects bun / pnpm / npm / python / go / rust by lockfile/marker. The bun branch recognises `bun.lockb` (binary, Bun ≤1.2), `bun.lock` (text, Bun 1.3+ default), or `bunfig.toml`. The python branch is venv-aware: if `uv.lock`/`poetry.lock`/`pdm.lock` is present (and the matching tool is on `PATH`), the validator prepends `uv run` / `poetry run` / `pdm run` so deps inside `.venv/` are visible. Pytest is a real gate; mypy stays non-blocking (`|| true` only on the mypy step). When your stack lands, the typecheck+test commands wire up automatically. If your stack isn't covered, either edit the per-stack branch in `run.sh` or set `CLAUDE_DELEGATION_VALIDATOR=/abs/path/to/script` pointing at a script that emits the JSON `{ ok, command, exit, duration_ms, stdout, stderr, warnings? }` contract.

3. **Customize test patterns if needed.** The TDD advisory recognizes `*.test.*`, `*.spec.*`, `__tests__/`, `tests/`, `*_test.py`, `*_test.go`, etc. out of the box. Override with `CLAUDE_TDD_TEST_PATTERNS="<space-separated globs>"` if your project uses different naming. The override fully replaces the defaults, so include every pattern you want recognized.

4. **Install gitleaks (optional but recommended).** The secrets-scan hook degrades open when `gitleaks` is missing from `PATH` — commits proceed with a one-line warning. To activate the protection, install gitleaks v8.x (single static Go binary, MIT, no runtime deps: see https://github.com/gitleaks/gitleaks#installing). Customize detector exemptions in `.gitleaks.toml` at repo root, or use inline `# gitleaks:allow` on a single line. `CLAUDE_SKIP_SECRETS_SCAN=1` disables the hook entirely for throwaway sessions.

5. **Activate the native pre-commit hook.** Run once, after `git init`:

   ```bash
   git config core.hooksPath .githooks
   ```

   This points git at the versioned `.githooks/` directory and activates `.githooks/pre-commit`, which is the primary layer of the secrets-scan capacity (spec 007). The step is manual on purpose — automating it via a post-checkout hook would replicate the 2025 Lazarus Group "Contagious Interview" attack pattern, where a poisoned repo's hook runs on clone. Verify with `git config --get core.hooksPath` returning `.githooks`.

6. **Reset `.agent0/HANDOFF.md`.** Replace the handoff content with a short "fresh project, nothing in flight" state or your own starting context. Keep the four sections (`Current State`, `Active Work`, `Next Actions`, `Decisions & Gotchas`). The Stop hook will nag you to update it on commit-day Claude Code sessions.

7. **(Optional) Drop the harness self-verification suite.** `.agent0/tests/secrets-scan/` ships 8 scenario scripts (~780 LOC) that verify spec 007's two-layer scan against gitleaks — useful when modifying `.githooks/pre-commit` or `.agent0/hooks/secrets-preflight.sh`, otherwise unused. The suite lives under `.claude/` (not the project's `tests/`) because it tests *the harness*, not the fork's code; forks that won't touch the secrets-scan internals can delete the dir to drop ~780 LOC from their initial commit. The harness keeps working without it.

## Workflow

Non-trivial work flows through the `/sdd` skill:

```
/sdd new <slug>     # scaffolds docs/specs/NNN-<slug>/{spec,plan,tasks}.md
/sdd plan           # drafts plan.md from spec.md
/sdd tasks          # drafts tasks.md from plan.md
/sdd list           # show all specs
```

Mechanical edits (rename, typo, one-file fix) skip `/sdd` and go straight to the change. See `.agent0/context/rules/spec-driven.md` for the full when-to-apply / when-to-skip rules.

Future to-dos that don't belong in `.agent0/HANDOFF.md` (in-flight) or memory (knowledge) go to `/remind`:

```
/remind add "circle back on caching when first user complains"
/remind add "review pricing in Q3" --due 2026-09-01
/remind list
/remind dismiss 2
```

## Layout

```
.
├── AGENTS.md                          # Codex instructions (runtime preamble + shared Agent0 block)
├── CLAUDE.md                          # project instructions (placeholders + template-stable rules)
├── README.md                          # this file
├── .agent0/
│   ├── HANDOFF.md                     # runtime-neutral session handoff (git-tracked)
│   ├── hooks/secrets-preflight.sh     # runtime-neutral commit-shape preflight (spec 108; Claude + Codex)
│   ├── hooks/delegation-verify.sh     # runtime-neutral SubagentStop verifier (spec 111; Claude + Codex)
│   └── secrets-audit.jsonl            # secrets-scan audit log (gitignored)
├── .gitleaks.toml                     # starter secrets-scan config (allowlists + builtin detectors)
├── .githooks/                         # versioned native git hooks (activate per-fork via core.hooksPath)
│   └── pre-commit                     # primary secrets-scan layer (gitleaks over staged diff)
├── .claude/
│   ├── settings.json                  # hooks + permissions
│   ├── SESSION.md                     # pointer to .agent0/HANDOFF.md
│   ├── REMINDERS.md                   # deferred-intent list (git-tracked)
│   ├── hooks/                         # 8 lifecycle hooks (delegation-verify moved to .agent0/ in spec 111)
│   ├── rules/                         # behavior rules (loaded into context)
│   ├── skills/                        # /sdd, /remind
│   ├── validators/run.sh              # auto-detect typecheck+test
│   ├── agents/                        # custom subagent definitions (empty)
│   ├── tests/secrets-scan/            # harness self-verification suite for spec 007 (run-all.sh + V1-V7; optional, see step 7)
│   └── delegation-audit.jsonl         # (moved to .agent0/ in spec 106 — see .agent0/ above)
└── docs/
    └── specs/NNN-<slug>/              # design memory, one dir per feature
        ├── spec.md                    # what + why
        ├── plan.md                    # how + alternatives rejected
        └── tasks.md                   # numbered checklist
```

## Pointers

- **All behavior rules** live in `.agent0/context/rules/`. Read them in order if you want the full picture; each one is short and self-contained.
- **The harness is configurable** through `.claude/settings.json` (hooks, env vars, permissions). The `/update-config` skill is the sanctioned way to mutate it.
- **Memory routing** (project-shared vs personal vs path-scoped) is documented in `.agent0/context/rules/memory-placement.md`.

## License

No license file shipped — add one in your fork.
