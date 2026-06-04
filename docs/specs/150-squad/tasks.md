# 150 — squad — tasks

_Generated from `plan.md` on 2026-06-04 (v1 cut resolved via the dogfooded debate). Work top-to-bottom._

## Implementation

- [x] 1. `references/squad-contract.md` + `references/squad.yaml.example` — the gate-contract schema (acceptance/validator/build/lint/typecheck/smoke commands; max_rounds; max_repair_attempts; budget ceilings; checkpoint cadence; forbidden/human-gated path patterns) + terminal-state semantics.
- [x] 2. `scripts/squad.sh` — `init` (read squad.yaml, create run dir under `.agent0/.runtime-state/squads/<slug>-<ts>/` + `state.json`, record `start_head`). bash 3.2, `set -uo pipefail`, jq.
- [x] 3. `squad.sh` `turn-start`/`turn-end` — turn-lock assertion (`turn_holder`), per-turn `git diff --stat` + changed-paths snapshot, round++/flip holder.
- [x] 4. `squad.sh` budget + `propose-done` + terminal states — round/token ceilings → `aborted_budget`; `propose-done` records an agent proposal (agreement only proposes).
- [x] 5. `squad.sh` `gate` — run squad.yaml gate commands; all-green + both proposed-done → `ready_for_human_prod`; fail → `repair_attempts++`, `>max` → `aborted_repairs`.
- [x] 6. `squad.sh` `guard` + `rollback` — out-of-turn change detection → `aborted_conflict`; forbidden/human-gated path touched → `aborted_policy`; `rollback` to last clean turn boundary.
- [x] 7. `squad.sh` `status`/`abort` + dispatch.
- [x] 8. `SKILL.md` — `/squad` skill: `init`/`run`/`status`/`abort`; the pump loop; symmetric initiation; `--mode assisted` debug path; human-checkpoint + human-triggers-prod discipline; agentskills.io frontmatter.
- [x] 9. `.agent0/context/rules/squad.md` + `CLAUDE.md` `## Squad` managed-block index + mark spec 138 autonomous-loop concern superseded-by-150.
- [x] 10. `.agent0/tests/squad/` — shell suite over a temp git repo (init/state; turn-lock; diff-snapshot; budget→aborted_budget; gate green→ready_for_human_prod + gate-fail→repair→aborted_repairs; guard out-of-turn→aborted_conflict + forbidden-path→aborted_policy; rollback; agreement-without-green-gate does NOT close; shellcheck).

## Verification

- [x] `bash .agent0/tests/squad/run-all.sh` — all pass.
- [x] Dry-run pump: a stub peer + stub squad.yaml (trivial gate green after N turns) drives `squad.sh` through init→turns→gate-green→ready_for_human_prod, and separate runs hit `aborted_budget` and `aborted_repairs`. (State machine end-to-end without a live LLM run.)
- [x] Mechanical proof **agreement ≠ done**: both agents `propose-done` but gate red → `status` is NOT `ready_for_human_prod`.
- [x] No regression: `meeting` 15/15, `deliberation-bias` 11/11, `harness-sync` 40/40; `bash -n` + shellcheck on `squad.sh`; `/skill validate .agent0/skills/squad`.
- [x] Acceptance criteria in `spec.md` re-read; Status → shipped.

## Notes

- v1 discipline: deterministic core + thin pump + dry-run only. NO worktree-per-agent, NO 3rd runtime, NO autonomous-to-prod (explicit non-goals / v2).
- Run-dir under `.agent0/.runtime-state/squads/` to inherit the existing gitignore (zero new entry); durable record = the spec + git history of the turns.
- The live 2-agent dogfood (real code-writing run) is a separate cost-gated activity after this lands — start with a tiny low-risk pre-planned spec.
