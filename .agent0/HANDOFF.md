# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Spec 092 (multi-runtime-handoff) shipped: `.agent0/HANDOFF.md` is now the canonical handoff; `.claude/SESSION.md` is a pointer-only compatibility file (first non-blank line `<!-- AGENT0_HANDOFF_POINTER -->`). Claude `SessionStart`/`Stop` hooks read and enforce this file on every source; Codex follows the same handoff by `AGENTS.md` convention. Adjacent rules (reminders, routines, memory-placement, spec-driven, artifact-budgets, runtime-introspect, compaction-continuity) and entrypoints (CLAUDE.md, AGENTS.md managed blocks, README.md) updated in the same commit. Five test suites green: session-handoff (10), compaction-continuity (6), session-state-isolation (7), session-edit-attribution (8), runtime-introspect (16); plus instruction-drift (6) and harness-sync (33). Spec 090 had shipped earlier.

Downstream forks **mei-saas** (`7c25afd`) and **codexeng** (`4a657ab`) sync'd + migrated (each got the 092 harness + their own `.agent0/HANDOFF.md` populated from prior SESSION.md content, SESSION.md collapsed to pointer). codexeng kept its known 1 customized-refused (`image/SKILL.md § Notes`) — section-blind sha-compare, no upstream content change so no merge needed. **administradora-ia-nativa** deferred (drift unrelated to 092: pending removals of `app-skeleton/` + `04-ux-testing/` from older specs — needs its own dedicated sync window).

## Active Work

_None._

## Next Actions

1. Spec 091 (`docs/specs/091-sdd-debate-runner/`) remains paused and **untracked** on the working tree. Do not commit or resume without explicit user direction.
2. Codex CLI port of `/sdd debate` is out-of-repo and unchanged in status.
3. Propagation-advisory regex gap (pattern set doesn't catalog fork names) remains unscoped — threshold for spec scaffolding not met.
4. **administradora-ia-nativa** harness sync — dedicated window: drift includes removals from older specs (`app-skeleton/`, `04-ux-testing/`, `project-memory/05-06` tests) plus a `.claude/settings.json` + `.gitignore` merge. Not coupled to 092.

## Decisions & Gotchas

- Pointer detection uses the literal first-non-blank-line marker `<!-- AGENT0_HANDOFF_POINTER -->`; size-threshold and frontmatter were rejected (false-positive / parser-cost).
- Cross-runtime edit attribution is out of v1: Codex has no lifecycle hook to attribute through, so the legacy porcelain-compare false-positive (Codex edits during a Claude bystander session, `edited-files.txt` missing) stays as documented legacy risk.
- Stale-claim TTL/advisory deferred per rule-of-three demand test — `Active Work` bullets ship with mandatory `release condition` field only; build the advisory if dogfood produces ≥3 stale-claim collisions the field cannot catch.
- `.agent0/HANDOFF.md` is git-tracked but **outside** `sync-harness.sh`'s manifest by design — per-project state, never fork-managed. Adopting forks rewrite their own `.claude/SESSION.md` to pointer-only and create their own HANDOFF.md; new hooks fall to layer-(b) advisory during the migration window.
- Block-once Stop semantics, edit-attribution tracker (`edited-files.txt`), and porcelain-compare fallback are preserved verbatim — only the freshness target changed (`.claude/SESSION.md` → `.agent0/HANDOFF.md`).
