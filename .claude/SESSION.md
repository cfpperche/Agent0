# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 033 (skill-compliance-toolkit) shipped this session.** Hermes Agent deep-research → audit risk #1 → `/skill` meta-skill end-to-end. New under `.claude/skills/skill/`: SKILL.md (5 subcommands), `scripts/validate.sh` (bash, zero-dep, defers to `skills-ref` when present), `scripts/port-frontmatter.sh` (idempotent, body-bytes-preserving), 3 templates, 4 reference files (frozen agentskills.io spec, 3-tier policy, best-practices, validator rules), 8 fixtures + harness (8/8 pass). The 3 first-party skills (`remind`/`sdd`/`brainstorm`) ported — bodies byte-identical (5664/14779/14454 bytes), all `cc-native`. CLAUDE.md gained `## Skill compliance`. REMINDERS.md +1 (quarterly re-snapshot due 2026-08-17).

**Parallel sibling-session work (claude-core repo, separate concern):** `cfpperche/claude-core` (https://cfpperche.github.io/claude-core/) has 5 surfaces × 3 locales (EN/PT/ES). Routing Class added. Cheatsheet PT/ES intentionally partial (chrome only — CLI flag tables stay EN).

Working tree: this session's spec 033 + sibling session's claude-core extraction artifacts + unrelated pre-existing carryover (brainstorm template mod, 2 PNGs, spec 032 dir). 1 commit ahead of origin (older).

## WIP (in flight)

**Memory-layer research (sibling session, not me).** Two background sub-agents dispatched (sonnet) on Honcho+Mnemosyne adoption and CC extension-surface menu. Not yet returned at last handoff. Next session: read outputs, synthesize PT options (likely MCP-wrapping-Honcho + SessionStart fallback). Possible deliverable: new claude-core Memory Class OR Agent0 capacity spec `NNN-memory-layer-bridge`.

## Next steps

1. **Review + commit spec 033.** Suggested split: `.claude/skills/skill/` + ported SKILL.md files + spec 033 dir + CLAUDE.md. Single bundled commit also defensible. User decides.
2. **REMINDERS #2 unblocked** — `mcp-product-pipeline` as agentskills.io-compatible skill is now feasible E2E (scaffolder + validator + porter exist). Cross-runtime test (Hermes/Codex/Cursor) is the empirical proof; not done here.
3. **Distribution announcement** — claude-core 5-surface, 3-locale; Routing Class is the headline.
4. **Memory-layer research** — wait on sibling-session sub-agents.
5. **Spec 026 Phase C/D** — still pending.

## Decisions & gotchas

- **gawk reserves `close` as a builtin.** First-pass `validate.sh` used `-v close=...` and failed silently; soft warnings broken. Caught only by stderr spot-check (harness checks exit codes only). Fixed by `-v cl=...`. Future enhancement: stderr-matching in `validate.test.sh`.
- **Phase C decisions (locked in `.claude/skills/skill/references/portability-tiers.md`):** tier metadata key is `agent0-portability-tier` (kebab-namespaced, defensive); `argument-hint:` stays at top-level of frontmatter (CC reads it only there per official docs, porter does NOT migrate).
- **Audit divergence from spec scenario:** `/skill audit` operates on `.claude/skills/*/SKILL.md` only — CC-marketplace externals have no on-disk SKILL.md to inspect. Spec updated to reflect (Open Q #3 resolved).
- **CC harness picks up new SKILL.md live** — writing `.claude/skills/skill/SKILL.md` caused the next system-reminder to surface `skill` in available-skills. Useful confirmation that frontmatter is the discovery surface in real time.
- **claude-core locale URL pattern**: `<surface>/{pt,es}/<page>/` (landing exception is `/{pt,es}/`); `LanguageSwitcher` takes 3 URLs per page; Astro `i18n` intentionally NOT used.
- **Routing Class facts to keep straight:** config path is `~/.claude-code-router/config.json` (NOT `~/.config/...`). 6 routes (`default + background + think + longContext + webSearch + image-beta`). `CCR_VERSION` pinned `1.0.x` — third-party, fast-moving; verify before paste.

## Carryover (orthogonal lanes, not active)

- 1 commit ahead of origin (older session).
- Pre-existing dirty: `.claude/skills/brainstorm/templates/render.html.tmpl`, `banner-4-atos.png`, `next-steps-tab.png`, `docs/specs/032-pipeline-industry-alignment/`, `.claude/memory/forks-ephemeral-dogfood.md`.
- Spec 026 Phase B bench artifacts: `/tmp/bench/026-dogfood-step{11,12,13}/`.
- Hermes Agent insights from this session's research live in transcript only (not memorialized — external-framework observations aren't project-factual reference per consultancy-positioning memo).
