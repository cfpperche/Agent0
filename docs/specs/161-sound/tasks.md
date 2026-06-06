# 161 — sound — tasks

_Generated from `plan.md` on 2026-06-06. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **`sound-tiers.yaml` oracle** (`.agent0/skills/sound/references/`) — date-stamped, per-tier data-driven fields: `model`, `prompt_field`, `duration_field` (or null), `output_url_path` (jq), `price`, `price_unit` (`per_second|per_minute|per_gen`), `note`. Tiers: music `standard`=CassetteAI, `premium`=ElevenLabs Music; `sfx`=ElevenLabs SFX v2. Top-level `confirm_threshold_usd: 0.25`, `stale_after_days`, `snapshot_date`.
- [x] 2. **`sound.sh` engine** (`.agent0/tools/`) — arg parse (`--kind music|sfx` required; `--tier`, `--duration`, `--asset`, `--format`, `--confirm-cost-usd`, `--json`, `--exit-code`); resolve tier→fields from yaml (sfx maps to its own block, music to standard/premium); generic body build (`prompt_field`/`duration_field`); `cost = price × duration_in_unit` per `price_unit`; hybrid gate (print always, hard-require `--confirm-cost-usd ≥ cost` when `cost > threshold`); `fal-rest.sh run` → per-tier `output_url_path` extraction → `download`; draft/asset placement; ffmpeg mp3 encode (wav passthrough); hybrid manifest (one line/call, success AND failure, key never recorded, `stayed_local:false`); status `ok|unavailable|error` decoupled from exit; `doctor`/`caps`.
- [x] 3. **SKILL.md + symlinks** — `.agent0/skills/sound/SKILL.md` (tier `agentskills-portable`) surfacing the flags; `.claude/skills/sound` + `.agents/skills/sound` symlinks.
- [x] 4. **`sound.md` rule** (`.agent0/context/rules/`) — paid-only creative audio, `/image brand` analog, hybrid gate, taste-judged human-in-loop, data-driven oracle, `stayed_local:false` always, two output classes, non-goals + reopen-triggers, licensing note.
- [x] 5. **Offline tests** (`.agent0/tests/sound/`) — fake `fal-rest.sh`: sfx-flows-no-confirm, music-above-threshold-refused-then-confirmed, draft-vs-`--asset`, `--kind` required, no-`FAL_KEY` degrade, per-tier url extraction (incl. CassetteAI `audio_file.url`), cost math per unit, manifest cost fields + key-never-recorded.
- [x] 6. **Wiring** — `.gitignore` (draft `assets/generated/sound/*` + `.gitkeep`, manifest `assets/generated/.sound-manifest.jsonl`, tracked `assets/sound/.gitkeep`); `doctor.sh` sound check; `CLAUDE.md`+`AGENTS.md` `## Sound` block (parity); `sync-harness.sh` `COPY_CHECK_FILES` gitkeeps; baseline regen.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] sfx cheap → cost printed, no confirm, draft mp3, manifest `stayed_local:false` (AC 1)
- [x] music premium above threshold → refused without `--confirm-cost-usd`, proceeds with it (AC 2)
- [x] draft-by-default, `--asset` promotes to tracked dir, no auto-done (AC 3)
- [x] missing `--kind` errors naming `music`/`sfx` (AC 4)
- [x] no `FAL_KEY` → status `unavailable` + hint, decoupled from exit (AC 5)
- [x] per-tier url extraction works for both `.audio.url` and `.audio_file.url` (oracle)
- [x] `/skill validate sound` exit 0; `doctor` reports sound tri-state; full test suite green

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Build order per plan: oracle → engine → SKILL/rule/symlinks → tests → wiring → validate → dogfood (~$0.01 SFX).
