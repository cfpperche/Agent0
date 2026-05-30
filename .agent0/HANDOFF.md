# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Clean tree (only the unrelated untracked `docs/specs/091-sdd-debate-runner/`). Multi-runtime arc landed:
**rules** via context hydrator, **portable skills** via canonical source + discovery symlinks. Shipped
(detail in the specs + commits, not here):

- **Spec 122 — rules cutover (`2060f61`).** Rule bodies `.claude/rules/` → `.agent0/context/rules/`;
  `.agent0/hooks/context-inject.sh` hydrates them (`SessionStart` index + `UserPromptSubmit` prompt-selected,
  `AGENT0_CONTEXT_INJECTION` provenance). `.claude/rules/` empty. Live-confirmed Claude + Codex TUI.
- **Spec 123 — Codex hooks.json (`2038c4f`).** `.codex/hooks.json` = tracked consumer-safe hook source;
  inline TOML hook blocks removed; `.codex/config.toml.example` = "MCP recipes only".
- **Spec 121 — multi-runtime skills.** 5 portable skills → `.agent0/skills/<slug>/` + dual symlinks, tier
  `agentskills-portable`: `vuln-audit` `1be1389`, `remind` `38c1ef5`, `routine` `215ad75`, `sdd` `3a5688a`,
  `skill` `4f53c5c`. `/skill new` scaffolds portable at canonical home + symlinks (`33769e9`).

## Active Work

- _None in flight._

## Next Actions

1. **Refactor the cc-only skills toward multi-runner** (next arc). `image` blocker = fal.ai MCP
   (answer Codex-MCP-parity first, not just relocate); `brainstorm` = HTML + `.agent0/.brainstorm-state/`
   (assess if porting earns its keep; not hard-blocked). `product` stays **cc-native** (`AskUserQuestion` ×7).
   Use `portability-tiers.md` § Per-skill migration runbook + `/skill new --tier agentskills-portable`.
2. **Live-Codex confirm spec 121** (reminder `r-2026-05-30-live-codex-confirm-spec-121`) — fresh Codex:
   `codex debug prompt-input` lists a migrated skill from `.agents/skills`; `$<slug>` runs it.
3. **vuln-audit smoke test** (reminder `r-2026-05-30-run-vuln-audit-once-against`) — real osv-scanner vs
   `site/bun.lock`, confirm live V2 JSON parse. Open from spec 120.
4. **Optional:** rebuild `site/dist/` (122/123 changed source strings; dist not rebuilt).

## Decisions & Gotchas

- **Skill symlinks are relative + git-tracked (mode 120000):** `.claude/skills/<slug>` + `.agents/skills/<slug>`
  → `../../.agent0/skills/<slug>`. `find -type f` doesn't descend into them (ships once). **Edit the
  canonical `.agent0/skills/<slug>/` source only.**
- **Rules are now context fragments.** Don't reintroduce `.claude/rules/*.md`; add to
  `.agent0/context/rules/*.md` (hydrated by `context-inject.sh`). Keep portable skill bodies free of
  `${CLAUDE_SKILL_DIR}` — reference bundled resources by repo-relative `.agent0/skills/<slug>/...`.
- **`${CLAUDE_SKILL_DIR}` is also a detection token** in `skill/scripts/port-frontmatter.sh` +
  `references/portability-tiers.md` — do NOT neutralize it there (it flags cc-native skills).
- **Codex `.codex/hooks.json`:** both it + inline TOML hooks → hooks run twice; moving source resets trust.
  `codex exec` did NOT expose hook context — TUI is the live-proof.
- **sync-harness skill symlink pass** is apply-only + idempotent (after `reconcile_deletions`); copy-
  materializes + `skills-advisory:` on symlink-hostile checkouts (Windows).
- **cc-only skill reasons:** only `product` is blocked by a CC-exclusive primitive (`AskUserQuestion` ×7);
  `image` (MCP) + `brainstorm` (HTML+state) are just unported, not hard-blocked.
- **Pre-existing UNRELATED failure:** `typecheck-advisory/08-globs-nested-workspace.sh` (Node-24
  compile-cache). Fix = `NODE_DISABLE_COMPILE_CACHE=1` or gitignore.
- **Env:** gitleaks pre-commit active; governance blocks `rm -rf` + blanket `git add`; secrets-preflight
  blocks compound `git add && git commit` (commit standalone); `sleep`-chained Bash blocked. Commits user-gated.
