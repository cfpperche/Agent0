# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-26 (later) — Spec 092 plan drafted.**

`/sdd plan 092` drafted `docs/specs/092-multi-runtime-handoff/plan.md` (uncommitted). 5-layer mechanical migration: new `.agent0/HANDOFF.md` → pointer-only `.claude/SESSION.md` → hooks rewired (both `source=startup` AND `source=compact` inject HANDOFF.md) → rules in lockstep (`session-handoff.md` rewritten, `compaction-continuity.md` one-paragraph update) → AGENTS.md + CLAUDE.md parity inside `<!-- AGENT0:BEGIN -->` managed block. 4 rejected alternatives documented (mirror, no-fallback hot-swap, size-threshold detection, frontmatter detection). 5 risks named.

Two plan-level decisions surfaced for user review:

- **Pointer detection = content-marker** (`<!-- AGENT0_HANDOFF_POINTER -->` as the legacy `.claude/SESSION.md`'s first non-blank line). Size-threshold and frontmatter rejected.
- **Open Q2 disposition = defer the stale-claim advisory.** v1 ships with the explicit `release condition` field only, per rule-of-three demand test. Build the advisory if ≥3 dogfood sessions surface drift the field couldn't catch.

Spec 092 stays `**Status:** draft` — plan written, awaiting user confirmation before `/sdd tasks`.

## WIP

`plan.md` is the only uncommitted change. No mid-stream edits elsewhere.

## Next steps

1. **User reviews `plan.md`** — confirm content-marker choice + Open Q2 deferral, or override. Then `/sdd tasks` for spec 092.
2. **Push** — `main` is still 7 commits ahead of `origin/main` from the prior session. Operator's call.
3. **Spec 091 — paused.** `docs/specs/091-sdd-debate-runner/` untracked; do not commit or resume without explicit "resume 091".
4. **Propagation-advisory regex gap** — side-discovery from prior session; pattern set doesn't catalog fork names. Threshold not yet met; no spec scaffolded.
5. **Codex side port of `/sdd debate`** — out-of-repo; unchanged.

## Decisions & gotchas

- **codexeng will keep showing `1 customized-refused` on every sync** by design — § Notes fork bullet trips sha-compare. Expected until smart-merge ships; rule-of-three threshold not met.
- **`.claude/rules/spec-driven.md` § *When SDD applies*** is the canonical "non-trivial" definition for AGENTS.md / session-handoff.md cross-references (Codex audit of 092 synthesis).
- **Spec 092's new 4-section template** (`Current State` / `Active Work` / `Next Actions` / `Decisions & Gotchas`) is **declared in `spec.md` but NOT yet implemented** — this SESSION.md keeps its current shape until 092 ships. Applying the template before the rule rewrite would dogfood a not-yet-implemented contract.
- **Plan's pointer-detection choice (content-marker)** is grep-trivial for bash hooks and has zero false-positive surface; the alternatives (size-threshold, frontmatter) had real false-positive or dep-cost risks documented in `plan.md` § Alternatives considered.
