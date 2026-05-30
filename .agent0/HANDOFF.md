# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 124 — hook-context-noise-control is implemented, locally validated, and live-dogfooded.**
It replaces the five model-visible `SessionStart` readouts with one `.agent0/hooks/startup-brief.sh`
registration in `.claude/settings.json` + `.codex/hooks.json`, keeps `UserPromptSubmit` on
`.agent0/hooks/context-inject.sh`, and changes prompt context from full rule bodies to bounded capsules.

Founder screenshots confirmed live runtime behavior: `STARTUP_BRIEF=yes`, `STARTUP_MODE=summary`,
`PROMPT_MODE=prompt-capsules`, `FULL_RULE_BODY_VISIBLE=no`, `SELECTED=spec-driven artifact-budgets`.
The second screenshot showed one startup brief + one capsule block, not full rule bodies.

Validation passed: context-injection, readout-parse, session-handoff, harness-sync, runtime-capabilities
suites + `jq empty` on hook configs + synthetic probes. Specs 121/122/123/124 shipped.
Pre-existing untracked `docs/specs/091-sdd-debate-runner/` remains unrelated/out of scope.

## Active Work

- _None in flight._

## Next Actions

1. **Optional spec 125 candidate: hook-context visual polish.** Spec 124 fixed content volume, but the live UI
   still displays `hook context` flattened into long lines. Investigate whether either runtime can preserve
   readable newlines or hide the block while keeping model-visible context; otherwise reduce startup text further.
2. **cc-only skill multi-runner arc — essentially complete.** `image` (6th) + `brainstorm` (7th) migrated under
   spec 121; 7 portable skills total. `brainstorm`'s error-prone `done` HTML render was extracted to
   `scripts/render.py` (deterministic pure `state.json→HTML`; first test surface at `.agent0/tests/brainstorm/`).
   Only `product` stays **cc-native** by design (`AskUserQuestion` ×7) — not a gap. Arc done unless a new candidate appears.
3. **Live-Codex confirm spec 121** (reminder `r-2026-05-30-live-codex-confirm-spec-121`) — fresh Codex:
   `codex debug prompt-input` lists a migrated skill from `.agents/skills`; `$<slug>` runs it.
4. **vuln-audit smoke test** (reminder `r-2026-05-30-run-vuln-audit-once-against`) — real osv-scanner vs
   `site/bun.lock`, confirm live V2 JSON parse. Open from spec 120.
5. **Optional:** rebuild `site/dist/` (122/123/124 changed source strings; dist not rebuilt).

## Decisions & Gotchas

- **Rules are context fragments.** Do not reintroduce `.claude/rules/*.md`; prompt capsules require the agent to
  read `.agent0/context/rules/<slug>.md` when omitted detail matters.
- **Startup readouts are aggregated.** `startup-brief.sh` is the only registered model-visible `SessionStart`;
  `session-start.sh`, reminders/routines/memory readouts remain helper/direct-debug scripts.
- **Spec 124 solved volume, not UI cosmetics.** Flattened hook-context lines are follow-up UX polish, not a
  context-contract failure.
- **Skill symlinks:** edit canonical `.agent0/skills/<slug>/` only; `.claude/skills` + `.agents/skills` are
  relative discovery symlinks. `${CLAUDE_SKILL_DIR}` remains a detection token in the skill meta-tool.
- **`agents/openai.yaml`:** `image` ships the first one (paid skill → `allow_implicit_invocation: false` + fal-ai
  MCP dep). Reference template for future skills-with-MCP. Codex-only metadata; Claude ignores it.
- **Codex hooks:** `.codex/hooks.json` + inline TOML hooks run twice; trust may need reset after source moves.
  `codex exec` is not a faithful `SessionStart` proof; use TUI for live confirmation.
- **Known env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` and blanket `git add`;
  secrets-preflight blocks compound `git add && git commit`; commits are user-gated.
