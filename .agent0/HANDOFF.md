# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 114 (remove compaction-continuity) implemented + validated — NOT committed.** The whole
compaction-continuity capacity is gone: the PreCompact `pre-compact.sh` producer + the
`SessionStart` `source=compact` snapshot-injection consumer, the test suite, the memory entry, the
runtime-state dir row, and every live pointer. Decision: native `/compact` summarization suffices;
the capacity was dormant (0 snapshots ever), redundant with HANDOFF/memory/specs/git, and its
"last 12 turns" window mis-targeted. Full rationale + audit trail in
`docs/specs/114-remove-compaction-continuity/` (`spec.md` § Outcome, `validation.txt`, `*-log.txt`).

Validation: all removal checks PASS. `session-start.sh` is `bash -n` clean and its `source=compact`
smoke run still emits the HANDOFF block (no compact-history banner). `settings.json` valid JSON.
Only surviving "compact-history"/"compaction-continuity" strings are the **deliberate** historical
case-study lines in `memory-placement.md:58,247` (spec-096 narrative) + platform-event/native-feature
mentions (`PreCompact` event table, `--reason compact`, FAQ) — all correct to keep.

Pre-existing untracked `docs/specs/091-sdd-debate-runner/` is unrelated (out of scope).
Specs 112 + 113 from the prior session are committed but still **unpushed**.

## Active Work

- _None in flight._

## Next Actions

1. **Review `git status` / `git diff` and commit spec 114.** Deletions are `git rm`-staged; edits
   unstaged. Suggested: "feat(114): remove compaction-continuity capacity". Commits are user-gated.
2. **Rebuild the site** (`site/`) so `site/dist/*` drops the removed capacity card —
   `site/src/i18n/capacities.ts` was updated but generated HTML was not hand-edited.
3. `git push` the 112 + 113 + 114 commits when ready.
4. Continue the hook-migration arc — the runtime-introspect pair (`.claude/hooks/runtime-capture.sh`
   + `runtime-pre-mark.sh`) → `.agent0/`. (`pre-compact.sh` is now gone; remaining `.claude/hooks/*`
   are the runtime-introspect pair + `delegation-gate.sh` + `rule-load-debug.sh`.)
5. vuln-audit spec when prioritized (reminder `r-2026-05-29-spec-the-vuln-audit-capacity`).

## Decisions & Gotchas

- **PreCompact is Claude-only by nature** — Codex has no compaction-hook surface, so the capacity
  was correctly `.claude/`-homed (not migration debt). Removal was a scope/value call, not a port.
- **Intentional KEEPs** (not dangling): `memory-placement.md:58,247` (accurate spec-096 history);
  all `PreCompact`/`PostCompact`/`/compact`/"compaction" platform-event + native-feature mentions
  in `cc-platform-hooks.md` event table, `runtime-capabilities.md`, `codex-cli-hooks.md`,
  `strings.ts` FAQ, `harness-sync.md`, `rule-load-debug.md` (`--reason compact`); all `docs/specs/*`.
- **No `harness-sync-baseline.json` exists** here — nothing to scrub there.
- **Tool-output channel dropped results intermittently this session** — all mutations used
  assertion-guarded Python scripts (fail-fast + git-reversible) with logs persisted under the 114
  spec dir, so the on-disk record is authoritative where live output didn't render.
- **Env:** gitleaks pre-commit active (`core.hooksPath=.githooks`); governance gate blocks `rm -rf`
  + blanket `git add` — use explicit paths + `git rm`; commits are user-gated.
