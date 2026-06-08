# 172 - settings-hook-removal-sync - notes

_Created 2026-06-08._

_In-flight design memory for this spec._

## Design decisions

### 2026-06-08 - parent - Baseline ownership over tombstone guessing

Use previous baseline ownership metadata to classify removable Agent0 hooks. This makes deletion propagation general while preserving consumer hooks. When no metadata exists, prune nothing rather than guessing.

### 2026-06-08 - parent - Claude review accepted

Claude review via `claude-exec` run `20260608T162949Z-settings-hook-baseline-review` found real risks in the initial plan. Accepted fixes: bump baseline tool version, include `settings_hooks` in idempotency, preserve prior settings metadata when settings merge is skipped or source settings are missing/unparseable, and use structured JSON-string identities `[event, matcher, ordered commands]` instead of separator-concatenated strings.

## Deviations

_None yet._

## Tradeoffs

_None yet._

## Open questions

_None._
