# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 132 — video-skill: implemented + validated, UNCOMMITTED.** New `/video` skill, sibling of `/image`,
required `--mode=code|generative`. **code** = HyperFrames npm engine renders HTML→MP4 locally, $0 inference, source
tracked / MP4 gitignored / render fingerprint in manifest. **generative** = fal.ai queue REST, fire-and-forget
ledger (submit→poll), hard `--confirm-cost-usd` gate. Built via full SDD (spec→cross-model debate w/ Codex→plan→
tasks→build). Files: `.agent0/skills/video/`, `.agent0/tools/fal-rest.sh` (shared REST lib), `.agent0/context/
rules/video-gen.md`, symlinks, `.agent0/tests/video/` (5 tests green), CLAUDE.md/AGENTS.md/runtime-capabilities/
.gitignore touched. **Code mode validated with a REAL render** (1920×1080 h264 MP4 + manifest). Generative dry-
validated only (gate/tier/envelope/ledger); live paid submit/poll NOT exercised (needs real FAL_KEY + spend).

**Prior shipped (in git log):** 130 baseline relocate (`.claude/`→`.agent0/harness-sync-baseline.json`; note: that
file is mid-relocation/absent now per 130/131). 129 claude-exec, 128 codex-exec (subprocess bridges, siblings not
clones). 126/127 site. mei-saas consumer fully synced. Untracked `docs/specs/091-sdd-debate-runner/` out of scope.

## Active Work

_None — spec 132 complete, awaiting commit decision._

## Next Actions

1. **Commit spec 132 (user-gated).** Suggested split: `feat(132): /video skill — code+generative modes` + a
   separate commit for the SDD artifacts, or all-in-one. Nothing committed this session.
2. **Register 132's new managed files in `harness-sync-baseline.json`** once specs 130/131 settle its location
   (the baseline file is mid-relocation — absent from the tree right now, so no registration target exists yet).
3. **Decoupled follow-up spec:** migrate `/image` onto `.agent0/tools/fal-rest.sh` + fix `/image`'s stale
   "delegates to MCP" frontmatter wording (real contract is REST; Codex debate catch).
4. **Spec 126 OQ5 (optional)** bolder visual/brand; **deploy site** (GitHub Pages `cfpperche.github.io/Agent0/`).

## Decisions & Gotchas

- **`/video` design (spec 132 debate, converged w/ Codex):** own the authoring layer (do NOT install upstream
  `heygen-com/hyperframes` agent-skill — depend on the pinned npm *engine* only); ledger async not blocking; cost
  gate binds to cost/model/duration; NO drift-checker in v1 (speculative-observability discipline); tiers live in
  refreshable `references/video-tiers.yaml` (zero model IDs in skill body).
- **HyperFrames lint is LINE-BASED (pre-1.0 gotcha).** A comment immediately before `<div id="root">`, or `#root`
  `data-*` attrs wrapped across lines → false `root_missing_composition_id`/`dimensions`. Render still succeeds; the
  shipped template lints 0/0. Documented in template + `authoring.md` + `video-gen.md`.
- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are discovery
  symlinks). Invalid `SKILL.md` fixtures under `.agent0/tests/.../fixtures/`, never below `.agent0/skills/*`.
- **Relocations sweep docs too:** a `.claude/→.agent0/` move must grep `CLAUDE.md`/`AGENTS.md`/rules for stale refs.
- **Bridges (`codex-exec`/`claude-exec`):** subprocess, siblings not clones. codex-exec default sandbox read-only;
  claude-exec `--permission-mode` required + `--allow-writes` gate. Both audit to gitignored `.agent0/.runtime-state/`.
- **Env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` + blanket `git add`; secrets-preflight
  blocks compound `git add && git commit`; commits are user-gated.
