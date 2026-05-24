# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-23 (cont.) — 076 #8 harness-core slice landed (uncommitted); dogfood unblocked the brief-side.** Tasks 19-23 done: `# SKILL-DIRECTED: <slug>` marker extraction + `skill_directed` audit field in `.claude/hooks/delegation-gate.sh`; `escalation` branch suppression (`model-discipline` untouched); § Advisories paragraph + § Audit log field count bump (13→14) in `.claude/rules/delegation.md`. 3-payload local test passed. The parallel dogfood session shipped 075 (commit `88a2134`) and ended, leaving my 5 modified files untouched per the Parallel WIP convention — `.claude/skills/product/` is free again. Tree: 5 modified files (gate, rule, SESSION.md, 076 notes.md, 076 tasks.md), 3 commits ahead of origin/main (079, 081, 075).

## WIP — resume point

**Resume 076 #8 tasks 24-26 now.** Per option (b): insert `# SKILL-DIRECTED: product` into ~16 briefs in `.claude/skills/product/references/delegation-briefs.md` (task 24), real-world dispatch test (task 25), then ONE combined commit `feat(076): SKILL-DIRECTED marker suppresses escalation on skill-chosen models (#8)` (task 26) — covers all of 19-26.

## Next steps

1. **076 #8 tasks 24-26** (in progress) → combined commit closes #8.
2. After #8 ships → sweep the remaining 5 findings of 076 (#9, #3, #2-sections, #5, #4 — easiest→hardest; see `docs/specs/076-product-dogfood-fixes/plan.md`).
3. `/sdd new memory-frontmatter-schema` → scaffold umbrella-080 child **082** (MS-1 frontmatter schema + PostToolUse advisory validator). Foundation for 083 (MS-2 event-sourcing) and 085 (MS-5+MS-7 cap+query+decay). All three unscaffolded.
4. Dated reminders due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.
5. Push pending commits when ready (`git push origin main`).

## Decisions & gotchas

- **076 — anchor for `# SKILL-DIRECTED:` mirrors `# OVERRIDE:` exactly** (loose `^[[:space:]]*# SKILL-DIRECTED: ` + shell-side ≥10-char/slug check), not the strict regex tasks.md prescribed. Reason: rule paragraph claims grammar parity with `# OVERRIDE:`; strict regex would falsify that. Logged in `docs/specs/076-product-dogfood-fixes/notes.md` § Deviations.
- **`CLAUDE_PROJECT_DIR` fallback ≠ project dir for ad-hoc gate runs.** Gate uses `${CLAUDE_PROJECT_DIR:-$PWD}`; piping a payload from `/tmp` writes audit rows to `/tmp/.claude/delegation-audit.jsonl`, NOT the real log — looks like a write-failure on casual grep. `export CLAUDE_PROJECT_DIR=/home/goat/Agent0` or accept the sandbox. Logged in 076 notes.md.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
