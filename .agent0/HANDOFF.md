# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 114 (remove compaction-continuity) shipped + committed (`cd4c45c`), NOT pushed.** The whole
compaction-continuity capacity is gone: the PreCompact `pre-compact.sh` producer, the `SessionStart`
`source=compact` consumer branch, the test suite, the memory entry, and every live pointer. Decision:
native `/compact` summarization suffices; the capacity was dormant (0 snapshots ever), redundant with
HANDOFF/memory/specs/git, and its "last 12 turns" window mis-targeted. Rationale + audit trail in
`docs/specs/114-remove-compaction-continuity/` (`spec.md` § Outcome, `validation.txt`, `*-log.txt`).
Validation all PASS; `session-start.sh` `bash -n` clean and `source=compact` smoke run still emits
the HANDOFF block.

`main` now has **5 unpushed commits**: 112 + 113 (prior session) + 114 (this one).
Pre-existing untracked `docs/specs/091-sdd-debate-runner/` is unrelated (out of scope).

## Active Work

- _None in flight._

## Next Actions

1. **Rebuild the site** (`site/`) so `site/dist/*` drops the removed capacity card —
   `site/src/i18n/capacities.ts` was updated but generated HTML was not hand-edited.
2. `git push` the 112 + 113 + 114 commits when ready.
3. Continue the hook-migration arc — the runtime-introspect pair (`.claude/hooks/runtime-capture.sh`
   + `runtime-pre-mark.sh`) → `.agent0/`. (`pre-compact.sh` is now gone; remaining `.claude/hooks/*`
   are the runtime-introspect pair + `delegation-gate.sh` + `rule-load-debug.sh`.)
4. vuln-audit spec when prioritized (reminder `r-2026-05-29-spec-the-vuln-audit-capacity`).

## Decisions & Gotchas

- **PreCompact is Claude-only by nature** — Codex has no compaction-hook surface, so the capacity
  was correctly `.claude/`-homed (not migration debt). Removal was a scope/value call, not a port.
- **Intentional KEEPs** (not dangling): `memory-placement.md:58,247` (accurate spec-096 history);
  all `PreCompact`/`PostCompact`/`/compact`/"compaction" platform-event + native-feature mentions
  in `cc-platform-hooks.md` event table, `runtime-capabilities.md`, `codex-cli-hooks.md`,
  `strings.ts` FAQ, `harness-sync.md`, `rule-load-debug.md` (`--reason compact`); all `docs/specs/*`.
- **No `harness-sync-baseline.json` exists** here — nothing to scrub there.
- **Env:** gitleaks pre-commit active (`core.hooksPath=.githooks`); governance gate blocks `rm -rf`
  + blanket `git add` — use explicit paths + `git rm`; commits are user-gated.
