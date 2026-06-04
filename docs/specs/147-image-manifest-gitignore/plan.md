# 147 — image-manifest-gitignore — plan

_Drafted from `spec.md` on 2026-06-04. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Make the policy source-of-truth explicit in Agent0's `.gitignore`, then remove the already-tracked Agent0 manifest from the git index while preserving the local file. Update the live image-generation rule and skill so they describe the manifest as local audit state. Finally, run targeted verification in Agent0 and apply `sync-harness.sh` to consumers so the additive `.gitignore` merge carries the new ignore line.

## Files to touch

**Create:**
- `docs/specs/147-image-manifest-gitignore/` — spec record for the policy change.

**Modify:**
- `.gitignore` — ignore `assets/generated/.manifest.jsonl`.
- `.agent0/context/rules/image-gen.md` — update storage policy and gotchas.
- `.agent0/skills/image/SKILL.md` — update invocation flow and helper notes.
- `AGENTS.md` / `CLAUDE.md` — clarify the entrypoint summary if needed.
- `.agent0/HANDOFF.md` — closeout state if the change ships.

**Delete/untrack:**
- `assets/generated/.manifest.jsonl` — remove from git index only; keep local file on disk.

## Alternatives considered

### Seed an empty tracked manifest in every consumer

Rejected because the sync manifest would need special handling to avoid copying Agent0's real prompt/cost history into consumers. A zero-content seed path is more machinery than this audit log deserves.

### Keep the manifest tracked as originally documented

Rejected because the founder clarified the desired policy: the file should be gitignored in consumers and Agent0. The manifest is operational audit state, not durable project content.

## Risks and unknowns

- Existing consumers may already have an untracked manifest. `gitignore` fixes future status noise; no deletion is needed.
- A consumer that deliberately committed a manifest will need `git rm --cached` locally if it wants to untrack existing history; sync cannot safely rewrite consumer-owned tracked content outside Agent0's manifest.

## Research / citations

- `.agent0/context/rules/image-gen.md` storage policy before this change.
- `.agent0/context/rules/harness-sync.md` `.gitignore` additive merge behavior.
- User decision on 2026-06-04: gitignore the image manifest in consumers and Agent0.
