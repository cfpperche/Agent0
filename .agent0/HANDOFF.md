# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol. **Scope: this file records Agent0 work only — work on any other project (e.g. the graduated `~/tachyon` repo) belongs in THAT project's handoff, never here (§ Project scope).**

---

## Current State

- **Spec 208 — `/unused-code` (JS/TS via knip) SHIPPED + committed + pushed** — `d803257` on `main`. On-demand dead-code audit, the `/vuln-audit` twin: engine `.agent0/tools/unused-code.sh` + skill `.agent0/skills/unused-code/` (Claude/Codex symlinks) + rule `.agent0/context/rules/unused-code-audit.md` + CLAUDE.md/AGENTS.md index. Statuses `no-stack|clean|findings|unconfigured|unavailable|failed`; default exit 0 / 64 usage; never installs/deletes. `verify.sh` 22/22; codex-reviewed twice (engine BLOCK→folded, final SHIP-WITH-CHANGES→folded).
- **Spec 209 — `/unused-code` extended to Python (vulture) + Go (deadcode) — SHIPPED + committed + pushed** on `main`. Per-stack dispatch, `--stack <js|python|go>`, structured `unaudited_stacks` (computed for forced runs too), per-finding `confidence` (vulture), generalized `unconfigured` (knip no-config | Go no-main), new kind `unreachable code`. `verify.sh` 20/20, spec-208 parity 22/22, doctor 25/0/0. **Rust/PHP deliberately deferred** (codex+maintainer ruling: their tools find unused *dependencies* not dead *code* → would make `status=clean` lie; likely a future `/unused-deps`). Codex-reviewed twice (engine BLOCK→all folded incl. a dotted-name findings-drop BLOCKER; final diff SHIP-WITH-CHANGES→all folded).
- Earlier shipped on `main` (unchanged): Spec 205 `/product` v0.6.0 (`ae6bd8f`/`5b89c3c`, shipped-partial), Spec 206 UI-acceptance (`4a24cfc`), Spec 207 declarative validator (`2823e0d`/`b351787`/`2198af1`), public-surface-hygiene (`64274cc`/`93d01fa`).
- **Agent0 hosts no product code — pure governance/harness template.** Tachyon graduated to `~/tachyon` (own repo/handoff).

## Active Work

- **Next up: discuss "code health"** (the complexity / code-smell axis — long functions, large classes, cyclomatic/cognitive complexity) — maintainer asked to discuss it after spec 209 landed. This is the axis BOTH 208 and 209 explicitly deferred as "threshold-politics" → likely a separate `/code-health` capability or a consumer-declared analyzer command, NOT bolted onto `/unused-code`. No spec yet; design discussion pending.
- Throwaway engine fixtures live under `/tmp/uc-pygo` and `/tmp/unused-code-209-fixtures` (gitignored by location; verify.sh rebuilds them).

## Next Actions

- **Discuss code-health** (see Active Work) — scope/shape conversation before any spec; remember the deferral rationale (taste/threshold-bound, would poison the high-signal unused-code part if merged).
- **Possible follow-up (deferred, not requested):** `/unused-deps` capability for Rust (`cargo-machete`) + PHP (`composer-unused`) + npm/composer deps — the honest home for "unused dependency" detection that 209 kept out of `/unused-code`. Only if demand lands (rule-of-three).

- **Next `/product` dogfood:** run the judge-mix measurement protocol (`.claude/skills/product/references/quality-judge.md § Measurement protocol`) — confirm the provisional `sonnet`(P1/P3)/`opus`(P2/P4) judge mix still catches semantic inconsistencies (the fixture-spec "streak 17 vs 8" class); adopt or revert. Reminder `r-2026-06-12-run-the-spec-205-judge`; append the run to `.agent0/memory/product-pipeline-empirical-baseline.md`.
- **CI:** every push touching harness paths runs all 44 suites (`harness-tests` workflow) — keep it green.

## Decisions & Gotchas

- **Handoff is project-scoped.** This file = Agent0 only; a sibling/graduated repo (`~/tachyon`) keeps its own handoff. Cross-project running-logs are the top source of bloat + contradiction. See `session-handoff.md § Project scope`.
- **Agent0 is PUBLIC and must not know its consumers.** Shipped surface (rules/skills/tools/validators/hooks/CLAUDE.md/AGENTS.md) never names cognixse/mei-saas/acmeyard, private `/home/<user>/` paths, or commercial strategy. Audit: `git grep -nI -iE 'cognixse|mei-saas|acmeyard' -- <shipped paths>` (exclude `runtime/`).
- **UI acceptance (spec 206):** built-UI "done" = a GREEN PROJECT UI TEST covering the surface, never a frozen `agent-browser` bundle (`verify-contract` is GONE). No runner declared → validator emits `ui-runner-advisory:` (harness requires the runner, ships no substitute). `UI impact: none|ui`. `/product`'s design-time visual contract survives as test-writing INPUT. Rule: `.agent0/context/rules/ui-acceptance.md`.
- **Declarative validator (spec 207):** `.agent0/validator.json` (object of common commands OR ordered `{name,run}` array) is the contract; if present, stack detection is bypassed; invalid/empty → `ok:false`, no guessing. Consumer-owned, not in the sync manifest.
- **`founder` is overloaded — never blind-sed.** `.agent0/context/rules/*` → operator (`maintainer`); `/product` → product-builder persona (leave); legal/roadmap templates → domain (leave).
- **Agent0 is a harness, not a product host.** A future product is incubated in `packages/<name>/` (never touching `.agent0/`/`.claude/`), then split out with `git filter-repo` when it earns its own repo.
- **`/unused-code` engine invariants (specs 208/209) — load-bearing, do not regress:** (1) NO-FETCH — resolve a local engine binary, never `go install`/`pip install`/`pnpm exec`/bare `bunx`/`uv run`/`poetry run`; same resolved invocation for probe AND run. (2) Engine exit codes are UNRELIABLE (knip 0/1 only-normal; vulture exits 0 even on error; deadcode exits 0 with findings) → parse OUTPUT, and a parse/jq failure must become `failed`, never a false `clean` (two codex BLOCKERs were exactly this class). (3) Rust/PHP stay OUT (deps≠code). Defensive-parse contracts per engine in each spec's `notes.md`.
- **Git gotchas:** secrets-preflight blocks compound `git add … && git commit …` (stage + commit in SEPARATE Bash calls); governance-gate blocks blanket staging (`git add -A`/`.`/`*`) and `rm -rf` (use explicit paths or append `# OVERRIDE: <≥10-char reason>`). Committing a separate repo from this session: `git -C <path> commit -F <msgfile>` (NOT `cd <path> && git commit` — matches the `&& git commit` block).
