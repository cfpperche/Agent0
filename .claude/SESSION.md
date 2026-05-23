# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-23 — 076 AND 079 both spec'd + planned + tasked, ready to implement (orthogonal — no file overlap).** 076 work shipped to `origin/main` in prior commits (`a64b319`, `90c1453`, `afd2f28`, `9274545`). 079 (new this session) responds to the mei-saas2 diagnose (2026-05-22 transcript `~/.claude/projects/-home-goat-mei-saas/ea991098-*.jsonl`): `/product` Phase 5 scaffolds visual-only templates that ignore `system-design.md` D-03 architecture lock; mei-saas was first real motivator. Fix: Agent0 stops shipping stack code — deletes `templates/app-skeleton/{next,expo}/` + `references/stack-defaults.md`; Phase 5 reads system-design.md + roadmap.md Fase 1 and emits infra children when arch demands; foundation child becomes research-driven via `research-before-proposing.md` at `/sdd plan` time.

## WIP — resume point

Two specs ready to implement, orthogonal — pick either order. 076 has 33 tasks, 079 has 36 tasks. **Founder directive 2026-05-22: 079 first, then sync mei-saas, then re-run /product there to validate the fix.** 076 can be parallel/interleaved (no file overlap with 079 — confirmed in 079 plan § Risks).

## Next steps

1. Implement 079 top-to-bottom — 6 commit-blocks (sdd-handoff rewrite → SKILL.md Phase 5 → Step 08 brief hint → deletes → REMINDERS dismiss → /sdd plan advisory) + 10 verifications.
2. Sync mei-saas fork — `bash .claude/tools/sync-harness.sh --apply --agent0-path=/home/goat/Agent0 /home/goat/mei-saas`. Templates auto-removed via spec 068 deletion pass.
3. Re-run `/product` in mei-saas to validate the fix (umbrella should now carry monorepo + backend infra children).
4. 076 — work the 33-task list either before or after 079 (orthogonal).
5. Carryover: 075 task 14 (dogfood scenarios 3-6), pairs with 069 live-validation reminder.
6. Dated reminders coming due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.

## Decisions & gotchas

- **`secrets-scan` hook blocks compound `git add && git commit`** — run them as two separate Bash calls; `git commit -F-` heredoc works fine.
- **`governance-gate` blocks `rm -rf`** — use `rm -r` without `-f` (079 task 16-19 deletes need this).
- **OQ#8 (c)-puro is a foot-gun.** Inverting the gate on `MODEL_SPECIFIED=true` alone silences the legitimate ad-hoc case. The marker is the discriminator.
- **079 principle (saved as feedback memory `no-shipped-stack-opinions`):** Agent0 ships mechanisms, not frozen stack opinions. Anytime a future spec proposes shipping a template/snapshot/defaults file, reject — pipeline output + human at contract-time decide.

## Carryover (orthogonal — not touched this session)

- **075 task 14** — `/product` dogfood scenarios 3-6 pending.
- `docs/specs/074-subagent-personas/` — untracked draft (persona/role-prompting killed on research grounds; leave it for the originating session).
- `.claude/REMINDERS.md` items per startup readout.
