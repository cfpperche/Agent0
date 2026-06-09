# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

- **`main` is five commits ahead of `origin/main`, all local/not pushed:** `7b9bf4c` spec 181 (`claude-exec-run-bounds`), `2ee4bb8` memory correction, `7979bee` spec 183 (`runtime-platform-audit`), `74e8b18` spec 184 (`codex-exec-run-bounds`), and `HEAD` spec 182 (`product-positioning-reset`).
- **Spec 181 (`claude-exec-run-bounds`) shipped and committed locally, not pushed.** Commit `7b9bf4c` (`feat(claude-exec): add bounded run controls`) implemented helper-owned bounds for `claude-exec`: `--timeout` default 600s (positive integer, timeout exits 124 + `timed_out` metadata), `--progress-interval` default 30s (0 disables heartbeat only), and `--max-budget-usd` forwarding/metadata as Claude's native budget guard. Added tests `06-timeout.sh` and `07-budget-and-progress.sh`; updated `SKILL.md` to v0.2; closed `docs/specs/181-claude-exec-run-bounds/` with `**Closure:**`.
- **Validation for spec 181 passed:** `spec-verify` 1/1; `sdd-close` clean; `bash .agent0/tests/claude-exec-skill/run-all.sh`; `bash -n .agent0/skills/claude-exec/scripts/claude-exec.sh`; `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/claude-exec`; `bash .agent0/skills/skill/scripts/check-rubric.sh .agent0/skills/claude-exec`. Live smoke `.agent0/.runtime-state/claude-exec/20260609T152815Z-live-smoke-181/metadata.json` returned Claude `error_max_budget_usd`; residual documented: native `--max-budget-usd` is a budget guard, not a hard billing ceiling.
- **Spec 184 (`codex-exec-run-bounds`) shipped and committed locally, not pushed.** Commit `74e8b18` (`feat(codex-exec): add bounded run controls`) adds helper-owned run bounds to `codex-exec`: `--timeout` default 600s (positive integer, timeout exits 124 + `timed_out` metadata) and `--progress-interval` default 30s (0 disables heartbeat only). No budget flag was added because local `codex exec --help` still has no native `--max-budget-usd` equivalent. Updated `.agent0/skills/codex-exec/SKILL.md` to v0.2, extended `.agent0/tests/codex-exec-skill/`, and closed `docs/specs/184-codex-exec-run-bounds/`.
- **Validation for spec 184 passed:** `bash .agent0/tests/codex-exec-skill/run-all.sh`; `bash -n .agent0/skills/codex-exec/scripts/codex-exec.sh`; `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/codex-exec`; `bash .agent0/skills/skill/scripts/check-rubric.sh .agent0/skills/codex-exec`; `bash .agent0/tools/spec-verify.sh docs/specs/184-codex-exec-run-bounds`; `bash .agent0/tools/sdd-close.sh docs/specs/184-codex-exec-run-bounds --json`; targeted `git diff --check`. Live smoke `.agent0/.runtime-state/codex-exec/20260609T154938Z-live-smoke-184/metadata.json` exited 0 and returned `CODEX_EXEC_RUN_BOUNDS_OK`.
- **Spec 182 (`product-positioning-reset`) shipped and committed locally at `HEAD`, not pushed.** Commit message `docs(product): reset agent0 positioning` implemented the pragmatic product-positioning reset the user approved: no consumer/adoption measurement in this pass. Changed `README.md`, added root `LICENSE`, updated landing copy in `site/src/i18n/strings.ts`, reopened the public site by default via `site/src/config.ts`, added `docs/product/positioning-proof.md`, and closed `docs/specs/182-product-positioning-reset/`.
- **Validation for spec 182 passed:** `bun run build` in `site/`; `agent-browser.sh verify-contract http://127.0.0.1:4321/Agent0/en/ docs/specs/182-product-positioning-reset/visual-contract.json .agent0/.runtime-state/visual-contract/spec-182` (en/pt/es hero flow, zero console errors); `bash .agent0/tools/sdd-close.sh docs/specs/182-product-positioning-reset`; targeted `git diff --check`.
- **Pre-existing / unrelated dirty state remains untouched:** `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/`.
- **Latest product-brand decision:** keep Agent0 independent/personal for now; do not add explicit CognixSE branding or a public "CognixSE product" link in this pass.

## Active Work

- Git — spec 182 product-positioning reset is committed locally at `HEAD` and ready to push — release: push `main` when requested; no consumer adoption measurement or consumer sync is included.
- Git — spec 184 local commit is ready to push — commit: `74e8b18` — release: push `main` when requested; no consumer sync is included in this spec.
- Git — spec 183 local commit is ready to push — commit: `7979bee` — release: push `main` when requested.
- Git — memory correction local commit is ready to push — commit: `2ee4bb8` — release: push `main` when requested.
- Git — spec 181 local commit is ready to push — commit: `7b9bf4c` — release: push `main` when requested; no consumer sync is included in this spec.
- Other/local — unrelated untracked state remains — path: `.agent0/meetings/terceiro-runtime-modelos-chineses-2026-06-08T14-18-05Z/` — release: unknown; do not stage unless explicitly requested.

## Next Actions

- If the user says to publish current committed work, push `main` to `origin/main` to publish all five local commits through current `HEAD`.
- If the user wants to change the spec 182 license holder from `cfpperche` to a legal name later, do that as a separate follow-up commit.
- No consumer sync is owed for this pass. The user explicitly deferred adoption/dogfood measurement across local projects.

## Decisions & Gotchas

- Agent0 is now positioned as a **portable governance/evidence harness for existing coding-agent runtimes**, not as another coding agent, SaaS, IDE, or app framework.
- The north star in README/proof is **new project -> first validated, reviewable commit in any supported runtime**.
- Keep Agent0 branded as independent/personal for now. A future CognixSE connection can be phrased as "used/developed through CognixSE's agentic software work", but do not put "A CognixSE product" in the hero/public positioning yet.
- Site maintenance now defaults to off; use `PUBLIC_UNDER_CONSTRUCTION=true bun run build` to publish the maintenance page again.
- `agent-browser` uses shared daemon state; do not inspect multiple locales in parallel. The visual contract fixture runs sequential en -> pt -> es and passed.
- `codex-exec` now has helper-owned timeout/progress bounds, but no spend guard. Treat scoped prompts plus `--timeout` as operational control only; do not imply cost control unless Codex CLI gains a native budget flag later.
