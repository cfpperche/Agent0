# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Clean tree (only the unrelated untracked `docs/specs/091-sdd-debate-runner/`). The multi-runtime arc is
landed: **rules** ship via a context hydrator, **portable skills** via a canonical source + discovery
symlinks. Recent shipped+committed work (detail lives in the specs + commit messages, not here):

- **Spec 122 — context-injection rules cutover (`2060f61`).** Rule bodies moved `.claude/rules/` →
  `.agent0/context/rules/`; new `.agent0/hooks/context-inject.sh` hydrates them (`SessionStart` = bounded
  index, `UserPromptSubmit` = prompt-selected fragments with `AGENT0_CONTEXT_INJECTION` provenance).
  `.claude/rules/` now empty. Live-confirmed in Claude + Codex TUI.
- **Spec 123 — Codex hooks.json (`2038c4f`, `5eafd5a`).** `.codex/hooks.json` is the tracked,
  consumer-safe Codex hook source; inline TOML hook blocks removed; `.codex/config.toml.example` is now
  "MCP recipes only".
- **Spec 121 — multi-runtime skills.** 5 portable skills migrated to `.agent0/skills/<slug>/` + dual
  discovery symlinks (`.claude/skills/<slug>` + `.agents/skills/<slug>`), tier `agentskills-portable`:
  `vuln-audit` `1be1389`, `remind` `38c1ef5`, `routine` `215ad75`, `sdd` `3a5688a`, `skill` `4f53c5c`.
  `/skill new` now scaffolds portable skills at the canonical home + symlinks (`33769e9`).

## Active Work

- _None in flight._

## Next Actions

1. **Refactor the cc-only skills toward multi-runner** (the planned next arc). Candidates: `image`
   (real blocker = fal.ai MCP — needs the Codex-MCP-parity question answered first, not just relocation)
   and `brainstorm` (HTML render + `.agent0/.brainstorm-state/`; assess whether porting earns its keep —
   it has no `AskUserQuestion` block, so it's not hard-blocked). `product` stays **cc-native** by design
   (`AskUserQuestion` ×7 — no Codex equivalent). Follow `portability-tiers.md` § Per-skill migration
   runbook; create new portable skills via the now-fixed `/skill new --tier agentskills-portable`.
2. **Live-Codex confirm spec 121** (reminder `r-2026-05-30-live-codex-confirm-spec-121`) — fresh Codex
   session: `codex debug prompt-input` lists a migrated skill from `.agents/skills`; `$<slug>` runs it.
3. **vuln-audit smoke test** (reminder `r-2026-05-30-run-vuln-audit-once-against`) — real osv-scanner vs
   `site/bun.lock`, confirm live V2 JSON parse. Open from spec 120.
4. **Optional:** rebuild `site/dist/` (source strings changed by 122/123; dist not rebuilt).

## Decisions & Gotchas

- **Skill symlinks are relative + git-tracked (mode 120000):** `.claude/skills/<slug>` + `.agents/skills/<slug>`
  → `../../.agent0/skills/<slug>`. `find -type f` does NOT descend into them, so a migrated skill ships once
  (via `.agent0/skills`). **Edit the canonical `.agent0/skills/<slug>/` source only.**
- **Rules are now context fragments.** Do not reintroduce `.claude/rules/*.md`; add/update
  `.agent0/context/rules/*.md` and let `context-inject.sh` hydrate. Keep portable skill bodies free of
  `${CLAUDE_SKILL_DIR}`; reference bundled resources by repo-relative `.agent0/skills/<slug>/...`.
- **`${CLAUDE_SKILL_DIR}` is also a detection token** in `skill/scripts/port-frontmatter.sh` +
  `references/portability-tiers.md` — do NOT neutralize it there (it flags cc-native skills).
- **Codex `.codex/hooks.json`:** if both it and inline TOML hooks exist, Codex runs matching hooks twice;
  moving the source resets trust hashes (fresh TUI must re-trust). `codex exec` did NOT expose hook
  context in testing — interactive TUI is the live-proof path.
- **sync-harness skill symlink pass** is apply-only + idempotent (after `reconcile_deletions`); probes
  symlink capability and copy-materializes + `skills-advisory:` on symlink-hostile checkouts (Windows).
- **cc-only skill reasons:** `product` genuine (`AskUserQuestion` ×7); `image` MCP-bound; `brainstorm`
  HTML+state. Only `product` is blocked by a CC-exclusive primitive; the other two are just unported.
- **vuln-audit (spec 120, `40bccdb`):** osv-scanner V2 parse pinned to crafted fixtures; live-binary smoke
  test still pending (reminder).
- **Pre-existing UNRELATED failure:** `typecheck-advisory/08-globs-nested-workspace.sh` (Node-24
  compile-cache). Fix = `NODE_DISABLE_COMPILE_CACHE=1` or gitignore.
- **Env:** gitleaks pre-commit active; governance gate blocks `rm -rf` + blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (commit standalone); `sleep`-chained Bash
  blocked (use Monitor). Commits are user-gated.
