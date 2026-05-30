# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 128 — codex-exec-skill: shipped and committed (`f4938a7`).** Adds portable `codex-exec` skill at
`.agent0/skills/codex-exec/`, discovery symlinks in `.claude/skills/` + `.agents/skills/`, wrapper
`scripts/codex-exec.sh`, Codex metadata with `allow_implicit_invocation: true`, and focused tests under
`.agent0/tests/codex-exec-skill/`.

Spec 128 validation passed: fake-Codex test suite, `validate.sh`, `check-rubric.sh`, `bash -n`,
multi-runtime skill suite, Codex discovery via `codex debug prompt-input`, live Codex smoke, Claude positive
dogfood, and Claude negative `--output` containment dogfood. The dogfood-discovered `--output` escape was fixed:
explicit output paths now resolve under `.agent0/.runtime-state/codex-exec` / `CODEX_EXEC_STATE_DIR` and fail
closed before invoking Codex when outside that state dir.

**Specs 126 and 127 remain shipped.** Spec 126 OQ5 (bolder visual/brand direction) is still optional/user-owned.

Existing untracked `docs/specs/091-sdd-debate-runner/` remains out of scope.

## Active Work

_No active parallel-work claims._

## Next Actions

1. **Spec 126 OQ5 (optional):** bolder visual/brand direction if desired — current site is coherent and shipped.
2. **Deploy site when ready:** GitHub Pages publishes `site/` (`cfpperche.github.io/Agent0/`); confirm CI picks up
   the shipped site work and capture live Lighthouse numbers there.

## Decisions & Gotchas

- **Spec 126 premise reversal.** Debate + user gate resolved the site to an **OSS-project developer landing**;
  "harness" is the honest category, consultancy/outcomes pivot is an explicit non-goal.
- **`/sdd debate` identity fix shipped (`ca20476`).** Debate identity now derives from the real runtime, not a
  hardcoded `Claude Code` literal — validated live (Codex correctly self-ID'd as `Codex CLI`). Cross-runtime
  debates via symlink-shared skills now work with plain `$sdd debate`.
- **Flatten-safe markers (spec 125).** `▸` (U+25B8) shipped + confirmed crisp; tofu fallback is ASCII `>>`.
- **Skill symlinks:** edit canonical `.agent0/skills/<slug>/` only; `.claude/skills` + `.agents/skills` are
  relative discovery symlinks. `${CLAUDE_SKILL_DIR}` remains a detection token in the skill meta-tool.
- **`codex-exec` bridge:** it is a subprocess bridge, not native shared-memory delegation. Default sandbox is
  `read-only`; write-capable runs require explicit `--sandbox workspace-write` or `danger-full-access`.
  `--output` is intentionally state-dir-contained after Claude dogfood found the escape hatch.
- **Codex hooks:** `.codex/hooks.json` + inline TOML hooks run twice; trust may need reset after source moves.
  `codex exec` is not a faithful `SessionStart` proof; use TUI for live confirmation.
- **Known env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` and blanket `git add`;
  secrets-preflight blocks compound `git add && git commit`; commits are user-gated.
