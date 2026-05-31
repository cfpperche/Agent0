# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 132 — video-skill: SHIPPED** (`288f17e` skill + `42d0891` sync-manifest gitkeeps). New `/video`,
sibling of `/image`, required `--mode=code|generative`. **code** = pinned HyperFrames npm engine renders
HTML→MP4 locally ($0 inference; source tracked, MP4 gitignored, render fingerprint in manifest; owned authoring
layer). **generative** = fal.ai queue REST, fire-and-forget ledger (submit/poll), hard `--confirm-cost-usd` gate;
tiers in refreshable `video-tiers.yaml` (no model IDs in body). Built via full SDD + Claude↔Codex debate. Code
mode validated with a REAL render; generative dry-validated only (no paid call). 5-test sweep green.

**Spec 133 — image-fal-rest-migration: SHIPPED** (`69cdf2c`). Extracted `.agent0/tools/fal-rest.sh` (spec 132) is
now shared: added a synchronous `run` subcommand; `/image gen.sh exec` delegates its POST+download to the lib
(image-specific body/`.images[0].url`/dim-reconciliation stay local). Fixed the stale "delegates to the MCP" /
"opt-in MCP recipe" wording in `/image SKILL.md` + `image-gen.md` (generation is REST-only since spec 088; MCP is
optional discovery). image-gen + video suites green; exec delegation proven via a real 401 routed through the lib.

**Prior shipped (git log):** 131 project-core mirror (`606fcf0`); 130 baseline relocate; 129 claude-exec; 128
codex-exec. Untracked `docs/specs/091-sdd-debate-runner/` is pre-existing, out of scope (never staged this session).

## Active Work

_None — 132 + 133 shipped and committed._

## Next Actions

1. **Optional paid validations** (need a real `FAL_KEY` + spend, user-authorized): a real `/video --mode=generative`
   clip (submit→poll→download), and a real `/image --tier=draft` to confirm the migrated `exec` success path.
2. **Decoupled follow-up is DONE** (was 133) — `/image` is on `fal-rest.sh`; no remaining fal-REST duplication.
3. **Spec 126 OQ5 (optional)** bolder visual/brand; **deploy site** (GitHub Pages `cfpperche.github.io/Agent0/`).

## Decisions & Gotchas

- **`harness-sync-baseline.json` is CONSUMER-side + auto-maintained by `sync-harness.sh --apply` — never edited in
  Agent0** (it isn't even present in the Agent0 tree). The registration surface for new shipped files is the
  **manifest** (`COPY_CHECK_*` arrays in `sync-harness.sh`). `/video` skill/rule/tests/fal-rest.sh were already in
  scope (recursive/glob); only the `assets/video/*` gitkeeps needed adding (`42d0891`).
- **`fal-rest.sh` = the one fal REST impl:** sync `run` (fal.run) + async `submit`/`status`/`result`/`download`
  (queue.fal.run); model-agnostic. `/image` (sync) + `/video` generative (async) both consume it. Post-133, `/image`'s
  failure receipt reports `http_code:0` with the real fal error on stderr (minor, documented).
- **`/video` design (132 debate):** own the authoring layer (no upstream agent-skill install); ledger async not
  blocking; cost gate binds to cost/model/duration; NO drift-checker v1; tiers refreshable.
- **HyperFrames lint is LINE-BASED (pre-1.0):** no comment immediately before `<div id="root">`, keep `#root`
  `data-*` on one line, else false `root_missing_*`. Shipped template lints 0/0.
- **Skill homes:** edit canonical `.agent0/skills/<slug>/` only (`.claude/skills`+`.agents/skills` are symlinks).
- **Env gotchas:** gitleaks pre-commit active; governance blocks `rm -rf` (combined `-r`+`-f`) + blanket `git add`;
  secrets-preflight blocks compound `git add && git commit` (stage + commit as separate calls); commits user-gated.
