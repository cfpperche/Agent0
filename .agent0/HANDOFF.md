# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 129 — claude-exec: shipped.** The symmetric sibling of `codex-exec` — lets a non-Claude runtime
(primarily Codex) invoke the local Claude Code CLI via `claude -p`. Canonical source `.agent0/skills/claude-exec/`,
discovery symlinks in `.claude/skills/` + `.agents/skills/`, `scripts/claude-exec.sh`, Codex metadata with
`allow_implicit_invocation: true`, tests under `.agent0/tests/claude-exec-skill/` (50 assertions green).
**Not a clone** — native `--permission-mode` pass-through (required, fail-closed), `jq` last-message extraction
(Claude has no `--output-last-message`), `session_id` capture for `--resume`, prompt via stdin (variadic flags
would swallow positional). Validation: suite + `validate.sh` + `check-rubric.sh` + live smoke + Codex
bidirectional dogfood. Dogfood found the read-only "floor" was caller discipline not a bridge invariant →
fixed with the `--allow-writes` gate (write-capable modes refused without it; default/plan are the floor).

**Spec 128 — codex-exec: shipped.** Portable bridge; `--output` escape fixed (state-dir-contained, fail-closed).

**Specs 126 and 127 remain shipped.** Spec 126 OQ5 (bolder visual/brand direction) is still optional/user-owned.

**Skill fixture loader warning fixed.** Invalid validator fixtures moved out of discoverable skill trees:
`.agent0/skills/skill/tests/fixtures/` → `.agent0/tests/skill/fixtures/`; validation harness repointed and
multi-runtime regression added so `tests/*/SKILL.md` cannot leak through `.agent0/skills` discovery again.

Existing untracked `docs/specs/091-sdd-debate-runner/` remains out of scope.

## Active Work

_No active parallel-work claims._

## Next Actions

1. **Spec 126 OQ5 (optional):** bolder visual/brand direction if desired — current site is coherent and shipped.
2. **Deploy site when ready:** GitHub Pages publishes `site/` (`cfpperche.github.io/Agent0/`); confirm CI picks up
   the shipped site work and capture live Lighthouse numbers there.

## Decisions & Gotchas

- **Spec 126 premise reversal.** Site is an **OSS-project developer landing**; consultancy/outcomes pivot is a non-goal.
- **`/sdd debate` identity fix shipped (`ca20476`).** Runtime identity is detected, not hardcoded.
- **Flatten-safe markers (spec 125).** `▸` (U+25B8) shipped + confirmed crisp; tofu fallback is ASCII `>>`.
- **Skill symlinks:** edit canonical `.agent0/skills/<slug>/` only; `.claude/skills` + `.agents/skills` are
  relative discovery symlinks. `${CLAUDE_SKILL_DIR}` remains a detection token in the skill meta-tool.
- **Skill validator fixtures:** deliberately-invalid `SKILL.md` fixtures belong under `.agent0/tests/skill/fixtures/`,
  not below `.agent0/skills/*`, because recursive skill loaders treat nested `SKILL.md` files as discoverable skills.
- **`codex-exec` / `claude-exec` bridges:** subprocess bridges, not native shared-memory delegation, and
  deliberately *siblings not clones*. codex-exec: default sandbox `read-only`, `--output` state-dir-contained.
  claude-exec: `--permission-mode` required (no default), `--allow-writes` gates write-capable modes (floor
  invariant), `jq` is a hard dependency, prompt always via stdin. Both audit to gitignored `.agent0/.runtime-state/`.
- **Codex hooks:** `.codex/hooks.json` + inline TOML hooks run twice; trust may need reset after source moves.
  `codex exec` is not a faithful `SessionStart` proof; use TUI for live confirmation.
- **Known env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` and blanket `git add`;
  secrets-preflight blocks compound `git add && git commit`; commits are user-gated.
