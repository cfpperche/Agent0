# 121 — multi-runtime-skills — plan

_Drafted from `spec.md` on 2026-05-30 (post-debate synthesis). Update if implementation reveals the plan is wrong._

## Approach

Establish the canonical-source + discovery-symlink model and prove it on the `vuln-audit` pilot, then
teach `sync-harness.sh` to propagate it (with a symlink-hostile fallback). The model:

- **Canonical source:** `.agent0/skills/<slug>/SKILL.md` (+ bundled `scripts/`/`references/`/`assets/`,
  optional `agents/openai.yaml`).
- **Discovery registration (relative symlinks):** `.claude/skills/<slug>` → `../../.agent0/skills/<slug>`
  (Claude) and `.agents/skills/<slug>` → `../../.agent0/skills/<slug>` (Codex).
- **Logic stays neutral:** heavy work in `.agent0/tools/*.sh` (vuln-audit already does this).

`cc-native` skills that can't shed Claude-only primitives stay PHYSICALLY in `.claude/skills/<slug>`
(no `.agent0/skills` entry, no `.agents/` symlink). So the rule is simple: **every dir under
`.agent0/skills/` is a portable skill that gets both discovery links; everything else in
`.claude/skills/` is Claude-only.**

sync-harness changes are additive: keep `.claude/skills` recursive coverage (picks up real cc-native
files; `find -type f` does not descend into symlinked dirs, so migrated skills aren't double-counted),
add `.agent0/skills` as a recursive source, and append a post-apply pass that (re)creates the two
discovery symlinks per `.agent0/skills/<slug>` on the consumer — detecting symlink-hostile checkouts
and falling back to materialized copies + advisory.

## Files to touch

**Create:**
- `.agent0/skills/vuln-audit/SKILL.md` — relocated canonical source (moved from `.claude/skills/`).
- `.claude/skills/vuln-audit` → symlink `../../.agent0/skills/vuln-audit`.
- `.agents/skills/vuln-audit` → symlink `../../.agent0/skills/vuln-audit`.
- `.agent0/skills/.gitkeep` — so the canonical dir ships empty to consumers (like `.agent0/memory/`).
- `.agents/skills/.gitkeep` — so the Codex discovery dir exists in a fresh clone.
- `.agent0/tests/multi-runtime-skills/` — scenarios (`run-all.sh` + numbered):
  - `01-canonical-source-exists.sh` — `.agent0/skills/vuln-audit/SKILL.md` is a real file.
  - `02-claude-symlink-resolves.sh` — `.claude/skills/vuln-audit` is a symlink resolving to the canonical SKILL.md.
  - `03-agents-symlink-resolves.sh` — `.agents/skills/vuln-audit` likewise.
  - `04-single-source.sh` — both links resolve to the SAME inode/realpath (one source of truth).
  - `05-skill-still-validates.sh` — the relocated SKILL.md passes the agentskills validator.
  - `06-no-claude-skill-dir-dep.sh` — the portable skill body has no `${CLAUDE_SKILL_DIR}` reference.
  - `07-sync-creates-links.sh` — sync-harness apply into a temp consumer creates both discovery symlinks pointing at the canonical source.
  - `08-sync-symlink-hostile-fallback.sh` — with symlinks forced off (`git config core.symlinks false` / probe fails), sync materializes copies + emits a `skills-advisory:` instead of leaving a broken stub.

**Modify:**
- `.agent0/tools/sync-harness.sh` — add `.agent0/skills` to `COPY_CHECK_RECURSIVE`; add `.agent0/skills/.gitkeep`, `.agents/skills/.gitkeep` to `COPY_CHECK_FILES`; append `sync_skill_discovery_links()` post-apply pass (symlink create + hostile-checkout detection + copy fallback + advisory).
- `.claude/rules/runtime-capabilities.md` — add a **skills** capability row.
- `.claude/rules/harness-sync.md` — document the canonical-source + symlink model, the discovery-link propagation, and the hostile-checkout fallback.
- `.agent0/memory/harness-home.md` — update the deferred-skills disposition → `.agent0/skills` is the shared source; `.claude/skills` + `.agents/skills` are registration surfaces.
- `.claude/skills/skill/references/portability-tiers.md` — note the `.agent0/skills` relocation as the mechanical home for `agentskills-portable` skills + the per-skill migration runbook (or add the runbook here).
- `CLAUDE.md` / `AGENTS.md` — only if a managed-block line needs to mention the skills home (verify; likely a one-liner under an existing section, not a new section).

**Delete:**
- `.claude/skills/vuln-audit/SKILL.md` (the physical file — replaced by the symlinked dir). Done via the move.

## Alternatives considered

### `.claude/skills` stays the source; symlink only into `.agents/skills`
Rejected — keeps the "shared" artifact under a Claude-named home, contradicting the harness-home
principle (location neutral). Codex proved it follows a symlink to a neutral target; making
`.agent0/skills` the source is the consistent move and reads correctly to future runtimes.

### Copy SKILL.md into both homes (sync-on-write, no symlinks)
Rejected as the DEFAULT — two physical files drift. BUT it is exactly the **fallback** for
symlink-hostile checkouts (Windows without `core.symlinks`), where it's the only option; there it's
acceptable because sync re-materializes from the one canonical source on every run + warns.

### Use `.codex/skills` instead of `.agents/skills`
Rejected — `.agents/skills` is the official documented Codex repo path; `.codex/skills` is left to a
deliberate future spec (both are discovered, but one contract at a time).

## Risks and unknowns

- **Symlink-hostile checkouts (the elevated risk).** Windows without Developer Mode / `core.symlinks=false`
  materializes committed symlinks as text stubs → discovery silently breaks. Mitigation: sync-harness
  probes symlink capability and falls back to copy-materialization + a loud `skills-advisory:`; a test
  forces the hostile condition. Our own repo (Linux/WSL2) supports symlinks, so the committed links work here.
- **`find -type f` + symlinked dirs.** The manifest must not double-count a migrated skill (once as
  `.agent0/skills` source, once via `.claude/skills` symlink). `find -type f` does not descend into a
  symlinked dir, so the symlink is invisible to the recursive file walk — verified assumption, asserted by test 04/07.
- **harness-sync regression.** sync-harness is well-tested; the change is additive (new function + array
  entries). The existing `.agent0/tests/harness-sync/` suite must stay green — run it as part of validation.
- **Consumer deletion pass.** A skill relocated upstream (was `.claude/skills/x`, now `.agent0/skills/x`)
  could orphan the old consumer path. The deletion pass + the new link step must converge; covered by test 07.

## Research / citations

- Codex skills discovery + format: https://developers.openai.com/codex/skills ; agentskills.io standard: https://agentskills.io
- Local runtime proof (symlink discovered by both Codex 0.135.0 + Claude 2.1.158): `docs/specs/121-multi-runtime-skills/debate.md` § Round 1 critique + Synthesis.
- `harness-home.md` principle; `.agent0/tools/sync-harness.sh` COPY_CHECK arrays + apply pass.
