# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 120 vuln-audit fully implemented this session (NOT yet committed — tree dirty, user-gated).**
The capacity replaces the removed supply-chain gate (spec 112). Built via the full SDD flow including a
2-round cross-model debate (Claude ↔ Codex, `docs/specs/120-vuln-audit/debate.md`, converged):
- **Engine:** osv-scanner-only (Trivy rejected — Mar-2026 supply-chain compromise; no second-source
  matrix). Stack-aware via a **three-bucket coverage report** (found/covered/skipped) so partial
  coverage is never reported as clean. Source-completeness caveat documented (OSV corpus ≠ all-known).
- **Trigger:** on-demand only (`/vuln-audit` skill + runtime-neutral `.agent0/tools/vuln-audit.sh`).
  NO install/commit gate (zero `settings.json` registration). Result status
  `clean|findings|unavailable|failed` decoupled from exit code (default 0; opt-in `--exit-code` for
  consumer CI). Reports + proposes upgrades, never auto-fixes.
- **Tests:** `.agent0/tests/vuln-audit/` — 10 scenarios / 48 asserts, ALL PASS, offline via a fake-osv
  stub. Skill validates (exit 0). Docs: CLAUDE.md + AGENTS.md managed blocks + runtime-capabilities row.

Prior context: consolidation arc 117→118→119 shipped+pushed at `4ffabb7`; all hooks in `.agent0/hooks/`.
Pre-existing untracked `docs/specs/091-sdd-debate-runner/` is unrelated (out of scope).

## Active Work

- _None in flight._ (Spec 120 complete in the working tree, awaiting user commit.)

## Next Actions

1. **Commit spec 120** — review the diff and commit (user-gated). New: `.agent0/tools/vuln-audit.sh`,
   `.agent0/tests/vuln-audit/`, `.claude/rules/vuln-audit.md`, `.claude/skills/vuln-audit/`,
   `docs/specs/120-vuln-audit/`. Modified: `CLAUDE.md`, `AGENTS.md`,
   `.claude/rules/runtime-capabilities.md`. Suggested: `feat(120): vuln-audit capacity`.
2. **Post-merge smoke test** (reminder `r-2026-05-30-run-vuln-audit-once-against`) — run the tool with
   the REAL osv-scanner binary against a real project (e.g. `site/` has `bun.lock`) to confirm the JSON
   parse matches live V2 output (severity / fixed_version / source.path extraction). CI uses an offline stub.
3. **Optional: rebuild `site/dist/`** — spec 118 changed `site/src/i18n/strings.ts`; only source changed.

## Decisions & Gotchas

- **vuln-audit JSON parse is pinned to osv-scanner V2 fields, verified only against crafted fixtures.**
  Severity = `database_specific.severity` (word) else bucketed from `groups[].maxSeverity` (CVSS num);
  fixed = first `affected[].ranges[].events[].fixed`; covered = basenames of `results[].source.path`.
  If live V2 output differs, the defensive parse degrades (severity→`unknown`, no-fix→"no fix published")
  rather than crashing — but the smoke-test reminder exists to confirm against the real binary.
- **`direct|transitive` is a cheap npm-only enrichment** (membership in package.json dep keys); other
  ecosystems report `unknown` + "no direct remediation path known". osv-scanner base JSON has no
  reliable dependency-path, so this is honest-by-design, not a gap to close.
- **bun coverage:** osv-scanner parses text `bun.lock` (Bun ≥1.2) but NOT binary `bun.lockb` → latter
  lands in `skipped` with a migrate hint. Repo's own `site/bun.lock` is the live dogfood target.
- **Pre-existing UNRELATED failure:** `typecheck-advisory/08-globs-nested-workspace.sh` (Node-24
  compile-cache). Fix = `NODE_DISABLE_COMPILE_CACHE=1` or gitignore.
- **Env:** gitleaks pre-commit active; governance gate blocks `rm -rf` + blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (commit standalone); `sleep`-chained Bash is
  blocked (use Monitor). Commits are user-gated.
