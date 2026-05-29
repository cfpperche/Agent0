# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Specs 112 + 113 shipped and committed (not pushed).** Working tree clean except the pre-existing untracked `docs/specs/091-sdd-debate-runner/` (out of scope).

- **112** (`edbaaf1` feat + `624c46f` docs) — removed the supply-chain capacity entirely + the `secrets-advise.sh` hook; `propagation-advise` confirmed maintainer-only. vuln-audit is the replacement direction (detect vulnerable installed libs, never block installs).
- **113** (`08d5cfc` feat + `6a8d5fa` docs) — ported `propagation-advise.sh` to runtime-neutral `.agent0/hooks/`; fires on Claude `Edit|Write|MultiEdit` and Codex `apply_patch`, live-validated on both runtimes. Suite 14/14.

## Active Work

- _None in flight._

## Next Actions

1. **Continue the hook-migration arc — the runtime-introspect pair** (`.claude/hooks/runtime-capture.sh` + `runtime-pre-mark.sh`) → runtime-neutral `.agent0/`. This is the last of the original `.claude/hooks/*` migration; after it the arc is closed.
2. `git push` the 112 + 113 commits when ready (4 commits unpushed on `main`).
3. **vuln-audit** spec when prioritized (reminder `r-2026-05-29-spec-the-vuln-audit-capacity`): research osv-scanner vs npm/pip-audit + trigger surface.

## Decisions & Gotchas

- **Codex advisory hooks need JSON stdout, NOT stderr.** Codex drops a PostToolUse hook's exit-0 stderr; only `hookSpecificOutput.additionalContext` (JSON stdout) surfaces as developer context. Any advisory hook ported to Codex must branch the channel — stderr for Claude, JSON additionalContext for Codex. Canonical impl: `emit_one` in `propagation-advise.sh`; corrected table in `.agent0/memory/codex-cli-hooks.md` § Exit-code semantics.
- **Don't assume Codex wire-shape — verify it.** Spec 113 hit three assumption errors in a row (apply_patch Add-File raw content; exit-0 stderr dropped; plain stdout vs JSON additionalContext), each caught by live Codex dogfood, not by synthetic tests. `AGENT0_PROPAGATION_DEBUG=1` dumps the raw payload for diagnosis. Cross-model live dogfood before flipping shipped is load-bearing.
- **Maintainer-only hooks: no block in the shipped `.codex/config.toml.example`** (it ships verbatim → dangling ref). Register in the maintainer's own gitignored `.codex/config.toml`.
- **Env constraints:** gitleaks pre-commit is active (`core.hooksPath=.githooks`); the governance gate blocks `rm -rf` and blanket `git add` (`.`/`-A`/`-u`) — use explicit paths + `git rm` for deletions; commits are user-gated.
