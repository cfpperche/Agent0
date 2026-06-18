# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol. **Scope: this file records Agent0 work only — work on any other project (e.g. the graduated `~/tachyon` repo) belongs in THAT project's handoff, never here (§ Project scope).**

---

## Current State

- **Agent0 working tree is clean** (only this handoff dirty). All recent Agent0 work is committed on `main`:
  - **Spec 205 — `/product` v0.6.0 (honesty + fit)** — `ae6bd8f`/`5b89c3c`. Status `shipped-partial`; residual = the judge-mix measurement on the next real `/product` dogfood.
  - **Spec 206 — retire visual contract → UI acceptance via green UI test** — `4a24cfc` (synced to consumers).
  - **Spec 207 — declarative validator contract (`.agent0/validator.json`)** — `2823e0d`/`b351787`/`2198af1`.
  - **Public-surface-hygiene rule** (Agent0 never names its consumers) — `64274cc`/`93d01fa`.
  - **Rule-corpus cleanup synced to all 3 consumers** (2026-06-10): mei-saas `4e81afd`, acmeyard `d903c91`, cognixse `19c8447`.
- **Agent0 hosts no product code — it is a pure governance/harness template.** Tachyon was incubated in `packages/` and graduated to its own repo (`e8aa5d7`, 2026-06-10, github.com/cfpperche/tachyon). All Tachyon session-state lives in `~/tachyon`, not here.
- **Untracked `docs/specs/208-unused-code-audit/`** is present (started outside this session) — not yet classified.

## Active Work

- None in flight for Agent0.

## Next Actions

- **Next `/product` dogfood:** run the judge-mix measurement protocol (`.claude/skills/product/references/quality-judge.md § Measurement protocol`) — confirm the provisional `sonnet`(P1/P3)/`opus`(P2/P4) judge mix still catches semantic inconsistencies (the fixture-spec "streak 17 vs 8" class); adopt or revert. Reminder `r-2026-06-12-run-the-spec-205-judge`; append the run to `.agent0/memory/product-pipeline-empirical-baseline.md`.
- **CI:** every push touching harness paths runs all 44 suites (`harness-tests` workflow) — keep it green.

## Decisions & Gotchas

- **Handoff is project-scoped.** This file = Agent0 only; a sibling/graduated repo (`~/tachyon`) keeps its own handoff. Cross-project running-logs are the top source of bloat + contradiction. See `session-handoff.md § Project scope`.
- **Agent0 is PUBLIC and must not know its consumers.** Shipped surface (rules/skills/tools/validators/hooks/CLAUDE.md/AGENTS.md) never names cognixse/mei-saas/acmeyard, private `/home/<user>/` paths, or commercial strategy. Audit: `git grep -nI -iE 'cognixse|mei-saas|acmeyard' -- <shipped paths>` (exclude `runtime/`).
- **UI acceptance (spec 206):** built-UI "done" = a GREEN PROJECT UI TEST covering the surface, never a frozen `agent-browser` bundle (`verify-contract` is GONE). No runner declared → validator emits `ui-runner-advisory:` (harness requires the runner, ships no substitute). `UI impact: none|ui`. `/product`'s design-time visual contract survives as test-writing INPUT. Rule: `.agent0/context/rules/ui-acceptance.md`.
- **Declarative validator (spec 207):** `.agent0/validator.json` (object of common commands OR ordered `{name,run}` array) is the contract; if present, stack detection is bypassed; invalid/empty → `ok:false`, no guessing. Consumer-owned, not in the sync manifest.
- **`founder` is overloaded — never blind-sed.** `.agent0/context/rules/*` → operator (`maintainer`); `/product` → product-builder persona (leave); legal/roadmap templates → domain (leave).
- **Agent0 is a harness, not a product host.** A future product is incubated in `packages/<name>/` (never touching `.agent0/`/`.claude/`), then split out with `git filter-repo` when it earns its own repo.
- **Git gotchas:** secrets-preflight blocks compound `git add … && git commit …` (stage + commit in SEPARATE Bash calls); governance-gate blocks blanket staging (`git add -A`/`.`/`*`) and `rm -rf` (use explicit paths or append `# OVERRIDE: <≥10-char reason>`). Committing a separate repo from this session: `git -C <path> commit -F <msgfile>` (NOT `cd <path> && git commit` — matches the `&& git commit` block).
