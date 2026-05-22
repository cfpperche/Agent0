# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-22 — spec 075 Moves 1-2 complete; task 14 dogfood partial.** Active spec `docs/specs/075-product-quality-audit/` — replaced the `/product` size-budget instrument with a rubric quality judge.

- **075 — Moves 1+2 DONE + committed.** `22aae4b`+`6c31e8c` (Move 1, tasks 1-4 — retire the size ceiling); `d8e8671` (Move 2 tasks 5-7 — the judge spec: verdict shape, `quality-judge.md`, repositioned `quality-checklist.md`); `0496a3b` (Move 2 tasks 8-13 — the § Quality judge brief + `SKILL.md`/`state-machine.md`/`report.md.tmpl` wiring + a 3-schema prose-ceiling fix task 12 caught); `54a6342` (task 14 partial).
- **075 task 14 — PARTIAL.** Representative slice done — the judge was dispatched against 2 real mei-saas artifacts (functional-spec 66 KB, cost-estimate 30 KB); scenarios 1-2 validated (verdict shape ✓; correctly-scoped large artifact → `right-sizing: pass` ✓✓ — the core false-positive regression is killed). Scenarios 3-6 + the full end-to-end run deferred.
- **073 — FULLY CLOSED.** Four post-ship commits this session: `675c3da` (Step 15 reorder — hi-fi screens lead), `43f9d9f` (per-step sub-tabs — multi-part step no longer one giant scroll), `7aa8553` (`docs` — tick acceptance + log fixes), `42b11f0` (HTML artifacts inlined via `<iframe srcdoc>` — REPORT.html survives a filesystem move). Spec `shipped`, acceptance 15/15 `[x]`, tasks 18/18, no open questions, `plan.md` § Alternatives amended. Suite `build-report.test.ts` 25/25. mei-saas REPORT.html regenerated (769 KB). Done — no follow-up.
- **076 product-dogfood-fixes — scaffolded (`e8ff256`).** spec.md filled; plan/tasks NOT drafted; OQ#8 blocks `/sdd plan`.

## WIP — resume point

**075 is implementation-complete. One task left: 14's full dogfood.**

- Run a full `/product` invocation (35-55 min, needs an `--out` dir) to validate scenarios 3-6 — bloat flagged by dimension, verdict→gate `iterate` pre-population, Phase 4 handoff surfacing, anti-stub pre-filter short-circuit, catastrophe cap. Then tick `075/spec.md § Acceptance` scenarios 3-6 and bump status `in-progress` → `shipped`. Pairs with the pending "069 live validation" reminder (`/product` vs `/home/goat/mei-saas`).

## Next steps

1. **075 task 14** — the full `/product` dogfood. Last task before `shipped`.
2. **076** — founder must resolve OQ#8 (`076/spec.md § Open questions`) before `/sdd plan`.
3. Dated reminders: spec 029 05-30 · spec 035 06-07 · spec 046 07-01 · spec 060 07-19.

## Decisions & gotchas

- **075 quality judge:** independent `opus` sub-agent per step; rubric = `quality-checklist.md` semantic criteria + `schema.md` structural context + a scope-aware right-sizing criterion; verdict = per-criterion pass/concern/fail + `scope_assessment` + `outcome` rollup; `fail` pre-sets the phase gate's `iterate` (Phase 4 → handoff). `quality_verdicts` is **v5-additive** (no v6 bump). Never autonomous hard-BLOCK.
- **`SKILL.md` body-token warning** (~8414 vs 5000 recommended) — non-blocking, pre-existing, worsened by the 075 wiring. A `SKILL.md` trim is a candidate follow-up (not 075 scope).
- **Bash cwd drifts** after Skill invocations — `cd /home/goat/Agent0` or use absolute paths.
- **`secrets-scan` hook blocks compound `git add && git commit`** — run them as separate Bash calls.
- **`governance-gate` blocks `rm -rf`** (combined `-r`+`-f`) — use `mktemp -d`, `rm -r` without `-f`.

## Carryover (orthogonal — not touched this session)

- `.claude/REMINDERS.md` items per startup readout.
- `docs/specs/074-subagent-personas/` — untracked draft (spec 074 — persona/role-prompting killed on research grounds; another session's WIP — leave it).
