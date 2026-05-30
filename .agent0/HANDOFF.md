# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 127 — site-content-refactor: shipped (19/19 tasks, 5 phases).** Deep content-truth pass + IA expansion on
top of 126. `site/src/i18n/capacities.ts` is now a typed manifest (24 capacities: slug/theme/sourcePath/
historySpec/per-runtime status from `runtime-capabilities.md`); `site/scripts/check-currency.ts` gates `bun run
build` and FAILS on stale links / missing pages (proven red→green). Added 5 grouped-by-theme explanatory pages +
a how-it-works overview (en), card links re-pointed to on-site pages (never early specs), and the two Codex-caught
copy defects fixed across en/pt/es. Build green: 10 pages, currency check OK. Spec `Status: shipped`. **pt/es
parity for the new routes is the one tracked follow-up** (reminder `r-2026-05-30-spec-127-follow-up-translate`),
a documented exception to 126's no-locale-reduction.

**Spec 126 — site-refactor: shipped.** OSS-landing-for-developers; derived capacity count, multi-runtime copy,
og:image, instant redirect. OQ5 (bolder visual direction) stays open, user-owned. **Spec 125** stays shipped.

Existing untracked `docs/specs/091-sdd-debate-runner/` remains out of scope.

## Active Work

_No active parallel-work claims._

## Next Actions

1. **Spec 127 pt/es follow-up** (reminder `r-2026-05-30-spec-127-follow-up-translate`): translate the 5 theme
   pages + how-it-works to pt/es; widen `RESOLVED_LOCALES` in `check-currency.ts` to `[en,pt,es]` (it already
   supports it). Blocking exception to 126 until done.
2. **Spec 126 OQ5 (optional):** bolder visual/brand direction if desired — current site is coherent and shipped.
3. **Deploy:** GitHub Pages publishes `site/` (`cfpperche.github.io/Agent0/`); confirm CI picks up 126+127.
   Capture live Lighthouse numbers there (Chrome wouldn't connect in WSL).

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
