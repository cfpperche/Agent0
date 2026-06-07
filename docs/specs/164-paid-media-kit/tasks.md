# 164 — paid-media-kit — tasks

_Generated from `plan.md` on 2026-06-07. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Capture golden BEFORE.** Run `bash .agent0/tests/capacity-kit/golden.sh capture` (snapshots current `sound`/`audio`/`transcribe`/`diagram` deterministic surface). Keep the baselines untouched until verify.
- [x] 2. **Write `.agent0/tools/lib/paid-media.sh`** — four pure helpers, no emit/no exit: `pm_yaml_top` (= sound `ytop`), `pm_yaml_tier_field` (= sound `yget`), `pm_has_fal_key` (predicate), `pm_fal_key_state` (`set|unset`). Header: pure, companion to `capacity.sh`, sync via `lib|*.sh`. `bash -n` clean.
- [x] 3. **Migrate `sound.sh`** — source `lib/paid-media.sh` below the help range (beside capacity source); replace `yget`/`ytop` bodies with calls to `pm_yaml_tier_field $TIERS`/`pm_yaml_top $TIERS` (or delete locals + sed-swap call sites); FAL_KEY presence → `pm_has_fal_key`; caps/doctor FAL_KEY state → `pm_fal_key_state`; add the `missing kit library lib/paid-media.sh` guard. `bash -n` clean.
- [x] 4. **Migrate `audio.sh`** — source `lib/paid-media.sh` below the help range (beside capacity source ~line 69); replace inline `default_tier` awk → `pm_yaml_top`, `model`/`price_per_1k_chars` awk → `pm_yaml_tier_field`; FAL_KEY check → `pm_has_fal_key`; caps/doctor FAL_KEY state → `pm_fal_key_state`; add the missing-kit guard. `bash -n` clean.
- [x] 5. **Write `.agent0/tests/capacity-kit/paid-golden.sh`** — capture/verify of `sound`+`audio` `caps`/`doctor` under BOTH `FAL_KEY=` (unset) and `FAL_KEY=x` (set). (Capture its baseline AFTER the migration is byte-correct OR capture-before-on-a-clean-tree — since it is a NEW gate, capture its baseline against the migrated tools and assert the FAL_KEY-state outputs are the expected `set`/`unset` strings + unchanged structure; cross-check the unset/ambient case against golden.sh's existing baseline for equality.)
- [x] 6. **Extend `missing-kit-guard.sh`** — add a paid-media case: copy `sound.sh` + `lib/capacity.sh` (but NOT `paid-media.sh`) to a temp dir, assert `caps` exits 70 with "missing kit library lib/paid-media.sh".
- [x] 7. **Docs** — `capacity-kit.md` paid sub-kit section deferred→shipped (name the 4 helpers, image/video reopen-trigger); `CLAUDE.md` Capacity kit sentence deferred→shipped; fill `notes.md` (empirical byte-identical proof, `music_length_ms` left as-is, source-below-help re-applied).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] **Golden parity** — `bash .agent0/tests/capacity-kit/golden.sh verify` → byte-identical before vs after (maps to "golden parity gate proves the whole pass").
- [x] **`sound` suite** — `bash .agent0/tests/sound/run-all.sh` all green (maps to "`sound` migrates with zero behavior change").
- [x] **`audio` suite** — `bash .agent0/tests/audio/run-all.sh` all green (maps to "`audio --remote` reader migration is behavior-preserving").
- [x] **paid-golden** — `bash .agent0/tests/capacity-kit/paid-golden.sh verify` green (FAL_KEY set+unset states pinned).
- [x] **sync-propagation** — `bash .agent0/tests/capacity-kit/sync-propagation.sh` green (paid-media.sh propagates).
- [x] **missing-kit-guard** — `bash .agent0/tests/capacity-kit/missing-kit-guard.sh` green (capacity + paid-media guards).
- [x] **bash -n** — clean on `paid-media.sh`, `sound.sh`, `audio.sh`.
- [x] **doctor** — `bash .agent0/tools/doctor.sh` stays 22 ok / 0 / 0.
- [x] **FAL_KEY never leaked** — grep the lib: no helper echoes `$FAL_KEY`; state helper emits only `set|unset`.

## Notes

_Populated during execution → folded into notes.md._

- Codex is the build peer per founder direction — cross-review the lib interface + the two migrations before the gate runs.
