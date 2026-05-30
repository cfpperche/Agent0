# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 121 multi-runtime-skills shipped this session (committing now).** Skills are now multi-runner via a
**canonical-source + per-runtime discovery-symlink** model (decided in a converged Claude↔Codex debate where
Codex empirically probed both live runtimes):
- Canonical body at `.agent0/skills/<slug>/SKILL.md`; discovery symlinks `.claude/skills/<slug>` (Claude) +
  `.agents/skills/<slug>` (Codex) → `../../.agent0/skills/<slug>`. One source, both runtimes follow the link.
- **3 skills migrated one-by-one** (each its own commit): `vuln-audit` (pilot, `1be1389`), `remind`
  (`38c1ef5`), `routine` (`215ad75`) → `.agent0/skills/<slug>/` + both symlinks (mode 120000), tier
  flipped to `agentskills-portable`. For remind/routine the internal script paths were neutralized to
  canonical `.agent0/skills/<slug>/scripts/` (readout hook, install-routines, new.sh TEMPLATE/VALIDATOR,
  rules) so they resolve under Codex without leaning on the Claude-named symlink.
- **sync-harness** propagates it: `.agent0/skills` in `COPY_CHECK_RECURSIVE` + `sync_skill_discovery_links`
  pass recreates the 2 symlinks, with copy-materialization fallback + `skills-advisory:` on symlink-hostile
  checkouts (Windows/`core.symlinks=false`) — the founder's elevated caveat.
- Docs: runtime-capabilities skills row, harness-sync § Skill discovery-link propagation, portability-tiers
  runbook, harness-home disposition. **Tests green:** multi-runtime-skills (8) + harness-sync (no regression)
  + vuln-audit (unbroken). `cc-native` skills (`AskUserQuestion`-bound) stay in `.claude/skills/`.

Prior: spec 120 vuln-audit shipped at `40bccdb`. Rules-first (`121-multi-runtime-rules`) was abandoned
(AGENTS.md has no `@import` + 32 KiB cap); skills was the cleaner path.

Pre-existing untracked `docs/specs/091-sdd-debate-runner/` is unrelated (out of scope).

## Active Work

- _None in flight._ (Spec 121 shipped; committing now.)

## Next Actions

1. **Live-Codex confirm spec 121** (reminder `r-2026-05-30-live-codex-confirm-spec-121`) — in a real Codex
   session, `codex debug prompt-input` should list `vuln-audit` from `.agents/skills`; `$vuln-audit` runs the
   tool. Offline tests prove the symlink/discovery structure; this confirms a live pickup.
2. **Next skills to migrate (one-by-one)** — `sdd` + `skill` need `${CLAUDE_SKILL_DIR}` neutralization
   (9 + 12 refs → resolve relative to SKILL.md), then portable. `product` is genuinely `cc-native`
   (`AskUserQuestion` ×7) → stays. `image` is MCP-bound (fal.ai); `brainstorm` renders HTML+state → assess.
   Runbook: `portability-tiers.md` § Per-skill multi-runtime migration runbook. (`vuln-audit`/`remind`/`routine` done.)
3. **vuln-audit post-merge smoke test** (reminder `r-2026-05-30-run-vuln-audit-once-against`) — real
   osv-scanner against `site/bun.lock`, confirm live V2 JSON parse. Still open from spec 120.
4. **Optional: rebuild `site/dist/`** — spec 118 changed `site/src/i18n/strings.ts`; only source changed.

## Decisions & Gotchas

- **Skill symlinks are relative + git-tracked (mode 120000).** `.claude/skills/<slug>` + `.agents/skills/<slug>`
  → `../../.agent0/skills/<slug>`. `find -type f` does NOT descend into them, so a migrated skill ships once
  (via `.agent0/skills`), never double via the `.claude/skills` symlink. Edit the canonical source only.
- **sync-harness symlink pass is apply-only + idempotent**, runs after `reconcile_deletions`; probes symlink
  capability and copy-materializes + `skills-advisory:` when unavailable. Relocated-skill orphan is deleted
  then re-linked in one `--apply`.
- **vuln-audit (spec 120, committed `40bccdb`):** osv-scanner V2 parse pinned to crafted fixtures; bun.lock
  covered, bun.lockb → skipped+migrate; live-binary smoke test still pending (reminder).
- **Pre-existing UNRELATED failure:** `typecheck-advisory/08-globs-nested-workspace.sh` (Node-24
  compile-cache). Fix = `NODE_DISABLE_COMPILE_CACHE=1` or gitignore.
- **Env:** gitleaks pre-commit active; governance gate blocks `rm -rf` + blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (commit standalone); `sleep`-chained Bash is
  blocked (use Monitor). Commits are user-gated.
