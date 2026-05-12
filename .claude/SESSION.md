# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 020 (runtime-capture-on-failure) delivered.** Agent0 `462fb15` + propagated to all 3 forks (`pyshrnk 0a16fa0`, `shrnk ebae994`, `rshrnk c8d6dba`). All 4 repos: 12/12 tests GREEN, zero drift.

**Plan-phase assumption broke + got fixed in-session.** Phase 3 dump-probe surfaced that `PostToolUseFailure(Bash)` payload DIVERGES from `PostToolUse(Bash)`. Spec/plan/tasks all updated to reflect the empirical truth; hook gained a ~15-line branch keyed on `hook_event_name`. End-to-end verification works (failing `bun test` → `status: FAIL` with failure body in `--- stderr ---`).

Agent0 recentes:
- `462fb15` spec 020 runtime-capture-on-failure
- `94a9726` spec 020 scaffold (prior session)
- `e1a7182` spec 019 amendment (memory scaffold ships)
- `1eb3803` spec 019 project-memory
- `3677807` spec 013 lint-validator

Forks (all drift-free against Agent0 `462fb15`):
- pyshrnk `0a16fa0` (spec 020), `0751c6a` (spec 019 amendment), `d19212b` (Starlette dogfood)
- shrnk `ebae994` (spec 020), `8a2de8c`
- rshrnk `c8d6dba` (spec 020), `c0feba2`

## WIP

None — spec 020 is closed loop in Agent0.

## Next steps

1. **Pyshrnk dogfood pass 2** — failure-path verification per `~/pyshrnk/docs/dogfood-plan.md § checkpoint 7`. Write a deliberately failing pytest, run `uv run pytest`, probe in a separate Bash call, assert `status: FAIL` with body. Should be the first 0-finding candidate for pyshrnk (post spec 011+020 fix).
2. **Pyshrnk pass 3** if pass 2 is clean — second consecutive 0-finding triggers yield-decay graduation.
3. **Dogfood B2 (shrnk)** and **B3 (rshrnk gap-finding pass)** — same shape, different forks.
4. **Specs 014 + 015** can enter at any point.
5. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption documented with spec-009 OVERRIDE marker but the "no frameworks" rule still says otherwise. Decide: amend rule to allow framework or revert Starlette.

Untracked carryovers:
- `docs/specs/010-audit-forensics/` (sessão prévia, sem review)

## Decisions & gotchas

- **PostToolUseFailure payload shape DIVERGES from PostToolUse.** Verified empirically by dump-probe on a failing `bun test`: no `tool_response` field; failure body at top-level `.error` (single string, harness-merged); `is_interrupt` replaces `tool_response.interrupted`; `hook_event_name: "PostToolUseFailure"` IS present and usable for dispatch. Full payload shape documented in `.claude/memory/cc-platform-hooks.md`.
- **Lesson from spec 020:** when integrating with an unfamiliar hook event, write a dump-probe first (~5 min). Cheaper than shipping on an assumed-parity shape and finding out via downstream dogfood. Recorded as second-order meta-lesson in `cc-platform-hooks.md`.
- **Mid-session settings.json reload works.** Edits to `.claude/settings.json` are picked up by the harness within the same conversation — no need to wait for a fresh session to verify a newly-registered hook. Confirmed by spec 020 Phase 3.
- **PostToolUse fires only on exit-zero** (spec 011 silent-drop gap). Spec 020 fixed via dual registration AND payload-shape branch. `runtime-capture.sh` now keys on `hook_event_name`.
- **`status: FAIL` default for PostToolUseFailure UNKNOWN cases.** Even when the per-detector inference table misses the failure pattern, the event itself signals failure — hook overrides `inferred_status` to FAIL with basis `"PostToolUseFailure event (pattern table missed)"`.
- **Memory bucket model (3 buckets) remains stable.** Spec 020 added content to `.claude/memory/cc-platform-hooks.md` (Agent0-only — doesn't ship to forks via sync-harness). Forks gained the `runtime-capture.sh` payload-shape branch (capacity, ships) but NOT the documented payload-shape memory content.
- **`--force-except=GLOB`** preserved its canonical use (`.gitignore` per-fork stack patterns) during spec 020 sync.
- **`core.hooksPath` activation continues MANUAL by design** (Lazarus). Spec 018 hint silences once activated.
- **SESSION.md auto-injection ~2KB preview budget** — replace stale; `git log` is audit trail.
