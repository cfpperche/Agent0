# 172 - settings-hook-removal-sync - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Extend the harness sync baseline with a structured settings-hook ownership set. The set is derived from Agent0's current `.claude/settings.json` at apply time and stores hook identities using the same semantics as the existing settings dedupe key, plus the event name: `event|matcher|ordered inner commands`.

During `merge_settings_json`, read the previous baseline's settings-hook identities. A consumer hook is pruned only when its identity existed in the previous Agent0-owned set and is absent from the current Agent0-owned set. Consumer-only hooks remain untouched because they never appear in the Agent0-owned baseline set. If the previous baseline lacks the new metadata, prune nothing; the first apply seeds ownership for future removals.

## Files to touch

**Create:**
- `.agent0/tests/harness-sync/44-settings-removes-agent0-hook.sh` - regression for upstream hook removal.
- `.agent0/tests/harness-sync/45-settings-no-baseline-no-prune.sh` - regression for safe pre-baseline ambiguity.
- `docs/specs/172-settings-hook-removal-sync/` - spec artifacts.

**Modify:**
- `.agent0/tools/sync-harness.sh` - derive/write baseline settings hook identities and prune removed Agent0-owned hooks during settings merge.
- `.agent0/context/rules/harness-sync.md` - document ownership metadata and removal behavior.
- `.agent0/tests/harness-sync/run-all.sh` - include the new tests if the suite is enumerated.
- `.agent0/HANDOFF.md` - refresh session state.

**Delete:**
- None.

## Alternatives considered

### Permanent tombstone list

Rejected as the primary mechanism because it handles only known retired commands and can accidentally block a later intentional re-registration of the same script unless someone remembers to remove the tombstone. Tombstones are useful for one-off migrations, but the harness needs a general ownership mechanism for future removals.

### Replace settings with Agent0 source when stale

Rejected because `.claude/settings.json` intentionally preserves consumer-local permissions, env, model, statusLine, and custom hooks. Plain overwrite would violate the existing consumer contract.

## Risks and unknowns

- Existing consumers whose baseline lacks `settings_hooks` cannot be classified retroactively. This is intentional: the current manually fixed consumers will seed metadata on their next sync, and future removals will be safe.
- Identity matching follows existing dedupe semantics. If a consumer edits an Agent0 hook entry, the identity changes and it is treated as consumer-owned rather than pruned.

## Research / citations

- `.agent0/tools/sync-harness.sh` lines around `merge_settings_json` and `write_baseline`.
- `.agent0/context/rules/harness-sync.md` § settings.json merge strategy.
