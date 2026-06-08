# 172 - settings-hook-removal-sync

_Created 2026-06-08._

**Status:** shipped
**UI impact:** none

## Intent

Teach `sync-harness.sh` to propagate removals of Agent0-owned Claude hook registrations in `.claude/settings.json` without deleting consumer-owned hooks. The immediate bug surfaced when `UserPromptSubmit` was removed from Agent0 settings: `.codex/hooks.json` propagated through the baseline path, but `.claude/settings.json` uses a structural union merge and kept the stale `context-inject.sh` registration in consumers. The fix should add enough ownership memory to the settings merge to remove old Agent0 entries safely.

## Acceptance criteria

- [x] **Scenario: Removed Agent0 settings hook is pruned**
  - **Given** a consumer baseline records an Agent0-owned hook identity from the previous sync
  - **When** Agent0's current `.claude/settings.json` no longer contains that identity
  - **Then** `sync-harness.sh --apply` removes that stale hook entry from the consumer settings merge.

- [x] **Scenario: Consumer-owned hook is preserved**
  - **Given** the consumer `.claude/settings.json` contains a hook identity that is not recorded as Agent0-owned in the previous baseline
  - **When** `sync-harness.sh --apply` merges current Agent0 settings
  - **Then** the consumer-owned hook remains present.

- [x] **Scenario: Pre-baseline ambiguity is safe**
  - **Given** a consumer baseline lacks settings hook ownership metadata
  - **When** `sync-harness.sh --apply` merges settings
  - **Then** no hook is pruned solely by guessing ownership from command text.

- [x] `.agent0/harness-sync-baseline.json` records current Agent0 `.claude/settings.json` hook identities on apply.

- [x] The settings merge documentation explains that removals propagate only for identities previously recorded as Agent0-owned.

## Non-goals

- Replacing the entire `.claude/settings.json` merge with plain hash comparison.
- Deleting consumer hooks that merely look similar to Agent0 hooks but were not recorded in the Agent0-owned baseline set.
- Solving all structured-merge removals for future top-level settings keys.
- Re-introducing prompt-time context injection.

## Open questions

- [ ] None.

## Context / references

- `.agent0/tools/sync-harness.sh` - `merge_settings_json`, `write_baseline`, baseline load/write.
- `.agent0/context/rules/harness-sync.md` - current settings merge strategy and limitations.
- `docs/specs/171-context-injection-reformulation/` - the prompt-hook pause that exposed the propagation gap.
