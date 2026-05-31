# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 130 — harness-baseline-relocate: shipped (`67fec69`) + follow-up (`464976a`).** Baseline moved
`.claude/`→`.agent0/harness-sync-baseline.json` (last umbrella-102 holdout). `sync-harness.sh` reads the legacy
path as fallback, removes it on the migrating `--apply` (write-before-delete). Follow-up repointed two stale doc
refs in `CLAUDE.md`+`AGENTS.md` (baseline path + spec-119 `.claude/hooks/`); gotcha added to `harness-home.md`.

**mei-saas consumer: fully synced to Agent0, clean** (3 commits: `eb490c7` spec-129 migration+bridges, `5b801d8`
baseline relocate, `ffc3b35` doc-path fix). `.claude/` holds only legitimate files; ~1100 gitignored residue files
swept; sync `--check` exit 0. Leftover (out of scope): consumer preamble `CLAUDE.md:15` still says `.claude/rules/`
(sync never touches the preamble).

**Spec 129 — claude-exec: shipped.** Symmetric sibling of `codex-exec` — a non-Claude runtime (primarily Codex)
invokes `claude -p` as a bounded subprocess. Canonical `.agent0/skills/claude-exec/` + discovery symlinks; 50-test
suite green. **Not a clone** — required fail-closed `--permission-mode` pass-through, `jq` last-message extraction,
`session_id` for `--resume`, prompt via stdin. Codex bidirectional dogfood found the read-only "floor" was caller
discipline → fixed with the `--allow-writes` gate (write-capable modes refused; default/plan are the floor).

**Spec 128 — codex-exec: shipped.** Portable bridge; `--output` escape fixed (state-dir-contained, fail-closed).
**Specs 126/127 shipped.** Spec 126 OQ5 (bolder visual/brand) still optional. Fixture-loader fix: invalid
validator fixtures moved to `.agent0/tests/skill/fixtures/` (out of `.agent0/skills` discovery). Untracked
`docs/specs/091-sdd-debate-runner/` out of scope.

## Active Work

_No active parallel-work claims._

## Next Actions

1. **Spec 126 OQ5 (optional):** bolder visual/brand direction if desired — current site is coherent and shipped.
2. **Deploy site when ready:** GitHub Pages publishes `site/` (`cfpperche.github.io/Agent0/`); confirm CI picks up
   the shipped site work and capture live Lighthouse numbers there.

## Decisions & Gotchas

- **History:** site = OSS-project developer landing (126); `/sdd debate` identity detected not hardcoded (`ca20476`);
  flatten-safe `▸` markers (125, tofu fallback `>>`).
- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are discovery
  symlinks). Invalid `SKILL.md` fixtures go under `.agent0/tests/skill/fixtures/`, never below `.agent0/skills/*`
  (recursive loaders treat nested `SKILL.md` as discoverable skills).
- **Relocations sweep docs too (`harness-home.md` gotcha).** A `.claude/→.agent0/` move must grep `CLAUDE.md`/
  `AGENTS.md`/rules for stale path refs, not just fix code — else sync ships stale docs to consumers.
- **`codex-exec` / `claude-exec` bridges:** subprocess bridges, not native shared-memory delegation, and
  deliberately *siblings not clones*. codex-exec: default sandbox `read-only`, `--output` state-dir-contained.
  claude-exec: `--permission-mode` required (no default), `--allow-writes` gates write-capable modes (floor
  invariant), `jq` is a hard dependency, prompt always via stdin. Both audit to gitignored `.agent0/.runtime-state/`.
- **Codex hooks:** `.codex/hooks.json` + inline TOML hooks run twice; trust may need reset after source moves.
  `codex exec` is not a faithful `SessionStart` proof; use TUI for live confirmation.
- **Known env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` and blanket `git add`;
  secrets-preflight blocks compound `git add && git commit`; commits are user-gated.
