# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 126 — site-refactor: shipped (19/19 tasks, all 5 phases).** The Claude×Codex debate reversed the original
premise → resolved to an **OSS-project landing for developers** (harness framing is honest, no consultancy pivot).
Implemented in `site/`: capacities.ts rewritten to the real 23-capacity set (count now derives from
`CAPACITIES.length`), multi-runtime truth (Claude + Codex), stale refs fixed (SESSION.md→HANDOFF.md, removed-cap
mentions), og:image PNG generated + wired, instant root redirect (was 2s). Build green, 3 locales lockstep, zero
stale strings. Spec `Status: shipped`. **Only OQ5 stays open** (bolder visual/brand direction — user-owned,
non-blocking); the design system criterion is met by the existing token architecture + a hero brand-accent.

**Spec 125 — hook-context-visual-polish remains shipped.** `▸` is the accepted flatten-safe marker in
`startup-brief.sh` and `context-inject.sh`; context-injection tests were green 13/13. Spec 124 stays shipped
as predecessor.

Existing untracked `docs/specs/091-sdd-debate-runner/` remains out of scope.

## Active Work

_No active parallel-work claims. Spec 126 is planned and awaiting implementation._

## Next Actions

1. **Spec 126 OQ5 (optional, user-owned):** decide bolder visual/brand direction — align to a `/product` or
   `/image` brand artifact, or run visual discovery — then iterate `site/` visuals. Non-blocking; current site
   is coherent and shipped.
2. **Deploy:** the GitHub Pages action publishes `site/` (`cfpperche.github.io/Agent0/`); confirm the next
   push/CI run picks up the 126 changes. Capture live Lighthouse numbers there (Chrome wouldn't connect in WSL).

## Decisions & Gotchas

- **Spec 126 premise reversal (the headline).** The refactor was opened as "lead with outcomes, demote the
  harness"; the debate + user gate resolved it to an **OSS-project developer landing** — "harness" is the honest
  category, consultancy/outcomes pivot is now an explicit non-goal (PR desc must lead with this reversal).
  Inventory is stale (copy "Eighteen" vs ~14 in data vs 20+ real) → make multi-runtime-true (Claude + Codex,
  spec 121). No lead capture v1; capability/expertise claims only.
- **`/sdd debate` identity fix shipped (`ca20476`).** Debate identity now derives from the real runtime, not a
  hardcoded `Claude Code` literal — validated live (Codex correctly self-ID'd as `Codex CLI`). Cross-runtime
  debates via symlink-shared skills now work with plain `$sdd debate`.
- **Flatten-safe markers (spec 125).** `▸` (U+25B8) shipped + confirmed crisp; tofu fallback is ASCII `>>`.
- **Rules are context fragments.** Do not reintroduce `.claude/rules/*.md`; prompt capsules require the agent to
  read `.agent0/context/rules/<slug>.md` when omitted detail matters.
- **Startup readouts are aggregated.** `startup-brief.sh` is the only registered model-visible `SessionStart`;
  `session-start.sh`, reminders/routines/memory readouts remain helper/direct-debug scripts.
- **Skill symlinks:** edit canonical `.agent0/skills/<slug>/` only; `.claude/skills` + `.agents/skills` are
  relative discovery symlinks. `${CLAUDE_SKILL_DIR}` remains a detection token in the skill meta-tool.
- **Codex hooks:** `.codex/hooks.json` + inline TOML hooks run twice; trust may need reset after source moves.
  `codex exec` is not a faithful `SessionStart` proof; use TUI for live confirmation.
- **Known env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` and blanket `git add`;
  secrets-preflight blocks compound `git add && git commit`; commits are user-gated.
