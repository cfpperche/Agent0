# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 097 shipped + synced to both consumer projects.** Agent0 `main` is 3 commits ahead of `origin/main`, all local:

- `ca88370` docs(097): ship borderline-rules-disposition — 3 rules split into CF slice + maintenance memory
- `e2ab331` docs(memory): add agent0-core-thesis
- `56edfd7` docs: add spec 098 codex mcp parity *(parallel session, not this session)*

Downstream syncs committed:

- mei-saas `2a05f11` — chore(harness): sync 093/094/095/096/097 (12 stale-updated, 3 removed, 0 customized-refused)
- codexeng `072bb20` — chore(harness): sync 093/094/095/096/097 (21 copied, 81 stale-updated, 5 removed, 1 customized-refused — `.claude/skills/image/SKILL.md` preserved)

Repo clean except `docs/specs/091-sdd-debate-runner/` (paused, untracked).

## Active Work

_None._

## Next Actions

1. **Push to `origin/main`** when ready — 3 commits queued locally.
2. **Spec 091** stays paused unless explicitly resumed.
3. **Spec 098** belongs to a parallel session — leave alone.

## Decisions & Gotchas

- **Codexeng's `image/SKILL.md` customization is stable.** 1 customized-refused on every sync since adoption; consumer-side image-gen tuning is intentional. Future syncs should keep refusing without `--force`.
- **Spec 097's split discipline is canonical** — codified in `memory-placement.md § Why three buckets` (3rd trigger). Consult before the next borderline-rules audit. Precedent file pair: `.claude/rules/runtime-introspect.md` ↔ `.claude/memory/runtime-introspect-maintenance.md`.
- **`propagation-advisory.md` is excluded from sync** by `COPY_CHECK_EXCLUDE` in `sync-harness.sh` — its 097 thinning ships nowhere. Only `runtime-capabilities.md` + `runtime-introspect.md` reach consumers.
