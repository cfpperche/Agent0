# Propagation advisory

A runtime-neutral `PostToolUse` hook (`.agent0/hooks/propagation-advise.sh`) scans the new content of shipped-file edits for upstream-internal pointers and emits one `propagation-advisory:` line per finding — on **stderr for Claude, JSON stdout `additionalContext` for Codex** (Codex `PostToolUse` ignores plain exit-0 stdout/stderr; see § Maintenance / `codex-cli-hooks.md`). Fires on Claude `Edit|Write|MultiEdit` AND on Codex `apply_patch` (spec 113), sourcing `.agent0/hooks/_memory-hook-lib.sh` for the cross-runtime path/content extraction. Mirrors the `tdd-advisory:` / `lint-advisory:` / `typecheck-advisory:` family — always exits 0, never blocks. Fires for both parent AND sub-agent edits because the maintainer writing new rules is the most common author of fresh leaks. Maintainer-only: excluded from consumer shipping (see § Maintenance) — the Codex registration lives in the maintainer's own gitignored `.codex/config.toml`, NOT the shipped `.codex/config.toml.example` (a shipped block would dangle in consumers); activation steps are in `.agent0/memory/propagation-advisory-maintenance.md`.

The discipline this enforces is documented in `.agent0/memory/propagation-hygiene.md` (maintainer-binding; doesn't ship). The advisory is the mechanical companion that surfaces drift in real time instead of waiting for a periodic audit.

## What fires, what stays silent

- **Edit / Write / MultiEdit (Claude) or `apply_patch` (Codex) on a shipped path** → scan the edit's new content for 5 leak-pattern kinds: `spec-NNN` (concrete spec numbers), `docs/specs/NNN` (concrete spec dir paths), `anthill` (upstream design lineage), `personal-path` (absolute `/home/<user>/` paths), `memory-pointer` (concrete `.agent0/memory/<topic>.md` references).
- **Match on any pattern** → emit `propagation-advisory: <pattern-kind> in <relpath>:<line> — <truncated text>` per finding (capped at 5 per pattern to limit noise).
- **No matches** → silent exit 0.
- **Path outside shipped surface** (e.g. `docs/specs/`, `.agent0/memory/`) → silent exit 0 — those paths don't ship to consumer projects, so their content carries no propagation risk.

The pattern-kind name in the advisory line tells you which class fired; read your edit's new content and either remove the leak or apply the override marker below if the prose is genuinely upstream-only.

## Override marker

A line matching `^[[:space:]]*# OVERRIDE: propagation-exempt: <reason ≥10 chars>` in the edit content skips the scan entirely. Same grammar as the project's other gates (delegation, secrets-scan, governance, memory-index, image-gen). Mandatory ≥10-char reason — `skip`, `n/a` rejected by the length floor.

Legitimate use cases for the override:

- Historical-context prose that mentions a removed upstream feature by spec number
- A rule that intentionally documents anti-patterns by citing the canonical leak shape
- Test fixtures that carry the patterns deliberately

The override does NOT silence the advisory globally — it skips ONLY the specific edit's scan. The next edit to the same file re-runs the scan against its own content.

## Escape hatch

`CLAUDE_SKIP_PROPAGATION_ADVISE=1` short-circuits the hook before any scan. For throwaway scratch sessions where leak prose is acceptable. Do NOT set in a long-lived shell config — it permanently disables the discipline.

## Gotchas

- **Parent edits fire.** Unlike `tdd-advisory:` (sub-agent only), this hook fires on parent edits too. The maintainer writing new rules is the most common author of fresh leaks, so excluding parent would defeat the purpose. If parent-fire becomes noisy, the env-var escape hatch is the per-session opt-out.
- **Override marker requires ≥10-char reason.** `# OVERRIDE: propagation-exempt: skip` is rejected by the length floor; write a real reason a future reader can grep.

## Maintenance

Maintainer-binding surface (5-pattern regex table, shipped-surface set, audit-log promotion policy, deep gotchas about diff-scope semantics, pattern-volume cap, vendor exclusion mechanism) lives in `.agent0/memory/propagation-advisory-maintenance.md`.

## Cross-references

- `.agent0/memory/propagation-hygiene.md` — the maintainer-binding discipline this hook enforces
- `.agent0/memory/propagation-advisory-maintenance.md` — maintainer-binding companion (pattern table, shipped-surface set, deep gotchas)
- `.agent0/hooks/propagation-advise.sh` — implementation (runtime-neutral; sources `_memory-hook-lib.sh`)
- `.claude/tests/propagation-advisory/` — scenario tests (incl. Codex `apply_patch` scenarios 12–14)
- `.claude/rules/delegation.md` § *Advisories* — the `<kind>-advisory:` pattern this follows
- `.claude/rules/tdd.md` § *Reading the validator advisory* — the canonical advisory-handling convention
