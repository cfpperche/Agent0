# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 122 context-injection-rules-cutover shipped and committed (`2060f61`).** Founder decision:
remove Claude Code native `.claude/rules/` as an Agent0 harness surface and use one Agent0-owned context
hydrator in both runtimes.
- Former `.claude/rules/*.md` bodies moved to `.agent0/context/rules/*.md`; `.claude/rules/` now has no
  harness markdown files for Claude to auto-load.
- New `.agent0/hooks/context-inject.sh`: `SessionStart` emits a bounded fragment index; `UserPromptSubmit`
  emits trusted prompt-selected fragments with `AGENT0_CONTEXT_INJECTION` provenance labels.
- `.claude/settings.json` registers the hydrator for `SessionStart` + `UserPromptSubmit`; Codex uses
  tracked `.codex/hooks.json` instead of TOML hook snippets.
- **Claude live confirmed:** fresh Claude session saw `AGENT0_CONTEXT_INJECTION` at `SessionStart`
  (index mode) and `UserPromptSubmit` (prompt-selected mode), both sourced from `.agent0/context/rules`;
  `.claude/rules/` is absent and the context-injection suite passed 8/8.
- **Codex live confirmed in TUI:** after adding the local opt-in blocks to `.codex/config.toml`, a fresh
  Codex TUI session saw `AGENT0_CONTEXT_INJECTION` at `SessionStart` (index mode) and
  `UserPromptSubmit` (prompt-selected mode), both sourced from `.agent0/context/rules`. Dogfood reply:
  `PASS; injected block present yes; event value(s): SessionStart, UserPromptSubmit; mode value(s):
  index, prompt-selected; source_dir value(s): .agent0/context/rules; selected: language
  user-prompt-framing spec-driven session-handoff runtime-capabilities harness-sync memory-placement`.
  A follow-up normal TUI launch prompted hook review, accepted `Trust all and continue`, and replied
  `TRUSTED_CONTEXT_SEEN`.
- `sync-harness` ships `.agent0/context/` and no longer manifests `.claude/rules|*.md`; existing consumers'
  old rules become normal baseline-governed upstream-removed orphans.
- Docs/tests updated: entrypoints point to `.agent0/context/rules`, runtime-capabilities has a context
  injection row, memory-placement/harness-sync/harness-home reflect the cutover, README/site strings repointed.
- **Codex hooks.json migration shipped:** official Codex docs confirm `.codex/hooks.json` is a native hook
  source with the same event schema as inline `[hooks]`/`[[hooks.*]]` in `.codex/config.toml`; no capability
  loss is expected after removing inline hook blocks to avoid duplicate execution.
- **Spec 123 codex-hooks-json shipped and committed (`2038c4f`):** `.codex/hooks.json` is a
  tracked, consumer-safe project hook file; `.codex/config.toml.example` and local `.codex/config.toml` no
  longer carry inline Agent0 hook blocks; `sync-harness` includes `.codex/hooks.json`; docs/tests point at
  the tracked hooks surface. Local validation passed, and founder-opened fresh Codex TUI dogfood returned:
  `PASS; injected block present: yes; event value(s): SessionStart, UserPromptSubmit; mode value(s):
  index, prompt-selected; source_dir value(s): .agent0/context/rules; selected: language
  user-prompt-framing spec-driven session-handoff runtime-capabilities harness-sync memory-placement`.
- **Codex config wording follow-up accepted:** `.codex/config.toml.example` now explicitly says it is
  "Codex MCP recipes only", not a local config default. Spec 123 notes/spec match that contract.

Spec 121 multi-runtime-skills remains shipped: portable skills use `.agent0/skills/<slug>/` plus
`.claude/skills/<slug>` + `.agents/skills/<slug>` discovery symlinks. `cc-native` skills stay in
`.claude/skills/`.

Pre-existing untracked `docs/specs/091-sdd-debate-runner/` is unrelated (out of scope).

## Active Work

- _None in flight._ Specs 122/123 and the Codex MCP wording follow-up are complete locally.

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
4. **Optional: rebuild `site/dist/`** — source strings changed; dist not rebuilt.

## Decisions & Gotchas

- **Skill symlinks are relative + git-tracked (mode 120000).** `.claude/skills/<slug>` + `.agents/skills/<slug>`
  → `../../.agent0/skills/<slug>`. `find -type f` does NOT descend into them, so a migrated skill ships once
  (via `.agent0/skills`), never double via the `.claude/skills` symlink. Edit the canonical source only.
- **Rules are now context fragments, not Claude-native rules.** Do not reintroduce `.claude/rules/*.md` for
  Agent0 harness docs; add/update `.agent0/context/rules/*.md` and let `context-inject.sh` hydrate it.
- **New hook blocks are session-loaded.** Existing Claude/Codex sessions may not see changed hooks until
  restarted; Codex requires project/hook trust on first TUI launch after `.codex/hooks.json` changes.
- **Codex `exec` is not equivalent to TUI for this live proof.** In this run, `codex exec` did not expose
  `SessionStart`/`UserPromptSubmit` hook context to the model even with `--dangerously-bypass-hook-trust`;
  the positive runtime proof came from a fresh interactive Codex TUI session.
- **Codex `.codex/hooks.json` migration gotchas:** if both `.codex/hooks.json` and inline TOML hooks exist,
  Codex merges them and matching hooks can run twice; the local TOML has been cleaned. Moving source path
  resets hook trust hashes, so a fresh TUI must review/trust the changed hooks again. `propagation-advise.sh`
  stays absent from tracked `.codex/hooks.json` because that hook script is excluded from consumer sync.
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
