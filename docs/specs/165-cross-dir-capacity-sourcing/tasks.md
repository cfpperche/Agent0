# 165 — cross-dir-capacity-sourcing — tasks

_Generated from `plan.md` on 2026-06-07. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Golden capture BEFORE** — `golden.sh capture` + `paid-golden.sh capture` (sound/audio surface unaffected baseline). Also snapshot `video`/`image` `--help` + `noargs` output for before/after comparison (they're not in golden.sh's tool list).
- [x] 2. **Write `tests/capacity-kit/cross-dir-source.sh`** (the prerequisite, FIRST). Temp-consumer harness: sentinel `$CONSUMER/.agent0/tools/lib/paid-media.sh` + copied skill script, run with `CLAUDE_PROJECT_DIR=$CONSUMER`. Pin: (a) repo-root resolution (script finds the real lib), (b) consumer-root resolution (finds the sentinel), (c) absent-lib → a paid subcommand exits 70 + "missing kit library lib/paid-media.sh" WHILE `--help` exits 0. `bash -n` clean.
- [x] 3. **Map `load_paid_media` placement in `video`** — confirm where `staleness_advisory` (uses `yaml_top`) is reached; ensure `load_paid_media` runs before any `pm_*`/binder call on every paid path. Add `load_paid_media` (sources `$PROJECT_DIR/.agent0/tools/lib/paid-media.sh`, else exit 70 + message).
- [x] 4. **Migrate `video/gen.sh`** — `load_paid_media` atop `sub_prepare`/`sub_submit`/`sub_poll`; `resolve_tier_field`/`yaml_top` → binders over `pm_yaml_tier_field`/`pm_yaml_top`; FAL_KEY checks (118/172/238) → `pm_has_fal_key || die_no_fal_key`. `bash -n` clean. `--help`/`noargs` byte-identical.
- [x] 5. **Migrate `image/gen.sh`** — `load_paid_media` atop `sub_prepare`/`sub_exec`; FAL_KEY checks (189/272) → `pm_has_fal_key || die_no_fal_key`. TIER_TABLE untouched. `bash -n` clean. `--help`/`noargs` byte-identical.
- [x] 6. **Docs** — `capacity-kit.md` (video/image now consume the paid kit cross-dir + lazy-load; smoke gate; close the 164 reopen-trigger); `CLAUDE.md` Capacity kit sentence; fill `notes.md`.

## Verification

- [x] **cross-dir smoke** — `bash .agent0/tests/capacity-kit/cross-dir-source.sh` green (all three lanes).
- [x] **video suite** — `bash .agent0/tests/video/run-all.sh` all green.
- [x] **image-gen suite** — `bash .agent0/tests/image-gen/run-all.sh` (or its runner) all green.
- [x] **video/image `--help`/`noargs` byte-identical** before vs after (and still work with lib absent).
- [x] **golden + paid-golden verify** — sound/audio surface unchanged (FAL_KEY-hermetic).
- [x] **sync-propagation + missing-kit-guard** — still green.
- [x] **FAL_KEY leak check** — grep video/image: no echo of `$FAL_KEY`; caps/state via helpers only.
- [x] **bash -n** — video/gen.sh, image/gen.sh, cross-dir-source.sh. **doctor** green.

## Notes

- Codex is the build peer (decision-grade meeting done; adversarial diff review before the gate, like 164).
- Founder `/goal`: resolve any followup that surfaces in THIS loop — don't park new ones.
