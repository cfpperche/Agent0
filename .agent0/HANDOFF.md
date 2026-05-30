# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 125 — hook-context-visual-polish is shipped.** Additive flatten-safe `▸` marker in `startup-brief.sh`
(handoff sub-headers `- Heading:` → `▸ Heading:`) + `context-inject.sh` (capsule sep `---` → `▸ ---`). The
3-tier inline vocabulary survives the renderer's newline collapse. Both dogfood artifacts captured in
`docs/specs/125-*/notes.md` § Dogfood artifacts: 5a (CC) — founder confirms `▸` renders crisp, **no** ASCII
`>>` fallback needed; 5b (Codex raw-stdout) — no JSON envelope, 2293B/30L under budget, capsules parseable.
Green: context-injection 13/13 (incl. new `12-flatten-safe-markers.sh`), spec `Status: shipped`.

Spec 124 stays shipped (predecessor — fixed volume). Untracked `docs/specs/091-sdd-debate-runner/` still oos.

## Active Work

_No active parallel-work claims._

## Next Actions

1. **cc-only skill multi-runner arc — done (7 portable skills, spec 121); pilot live-Codex-confirmed.** A real
   Codex TUI `$vuln-audit` turn triggered the skill → read SKILL.md → ran `.agent0/tools/vuln-audit.sh`;
   `codex debug prompt-input` lists the 6 implicit skills (`image` suppressed by `allow_implicit_invocation:
   false`). Only `product` stays cc-native (CC `Agent`-tool orchestration, spec 106). Not a gap.
2. **vuln-audit smoke test** (reminder `r-2026-05-30-run-vuln-audit-once-against`) — `osv-scanner` is NOT
   installed (live `$vuln-audit` returned `status=unavailable`, degraded clean). Install
   (`go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest`), then scan `site/bun.lock` and
   confirm live V2 JSON parse. Open from spec 120.
3. **Optional:** rebuild `site/dist/` (122/123/124 changed source strings; dist not rebuilt).

## Decisions & Gotchas

- **Flatten-safe markers (spec 125).** `▸` (U+25B8) is the shipped hierarchy marker; confirmed crisp at the
  CC glass. If a future runtime renders it as tofu, the planned fallback is ASCII `>>` (plan Risks).
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
