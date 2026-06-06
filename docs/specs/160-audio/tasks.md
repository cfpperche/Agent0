# 160 — audio — tasks

_Generated from `plan.md` on 2026-06-06. Work top-to-bottom._

## Implementation

- [x] 1. **Engine skeleton** — `.agent0/tools/audio.sh`: header/usage, `set -uo pipefail`, arg parse (`<text>`, `--engine`, `--remote`, `--asset`, `--voice`, `--lang`, `--format`, `--quiet`, `--json`, `--exit-code`, subcommands `doctor`/`caps`). Test/override env (`AUDIO_PIPER_CMD`, `AUDIO_KOKORO_CMD`, `AUDIO_FFMPEG_BIN`, `AUDIO_FAL_REST`, `AUDIO_NO_ACQUIRE`, `AUDIO_DRAFT_DIR`, `AUDIO_ASSET_DIR`, `AUDIO_MANIFEST`, `AUDIO_TIERS`, `AUDIO_VOICE_CACHE`).
- [x] 2. **Kokoro shim** — `.agent0/tools/audio-kokoro.py`: minimal `KPipeline` → WAV(text, voice, lang, out). Version-pinned.
- [x] 3. **tiers oracle** — `.agent0/skills/audio/references/audio-tiers.yaml`: date-stamped paid tier→fal-model (standard=ElevenLabs Turbo v2.5 ~$0.05/1k, premium=ElevenLabs v3 ~$0.10/1k), `price_per_1k_chars`, `stale_after_days`.
- [x] 4. **Local lanes** — `resolve_piper` (uvx `piper-tts`/`piper` CLI), `resolve_kokoro` (uvx `--with kokoro --with soundfile python <shim>`; detect espeak-ng → else `unavailable` + apt/brew hint), default engine=kokoro. Synthesize → WAV; voice download to gitignored cache on first use.
- [x] 5. **Encode + output classes** — ffmpeg WAV→mp3 (default; `--format wav` passthrough); draft dir (gitignored, default) vs `--asset` (tracked dir).
- [x] 6. **Paid lane** — `--remote`: read tier model+rate from yaml, compute `ceil(chars/1000)*rate`, **print cost before**, call `fal-rest.sh run --model=<id> --body=<json>` → extract audio URL (jq) → `fal-rest.sh download`. Needs FAL_KEY (else `unavailable`).
- [x] 7. **Hybrid manifest** — gitignored JSONL, one line/call (success+failure): local→{engine,voice,lang,model,stayed_local:true}; paid→{provider,model,cost_estimate_usd,request_id,stayed_local:false}; shared {ts,status,text_sha256,chars,output,format,class}.
- [x] 8. **Status/exit decoupling** — `ok|unavailable|error`; default exit 0; `--exit-code` maps ok=0/unavailable=2/error=3. `caps`(JSON)+`doctor`(tri-state).
- [x] 9. **SKILL.md** — `.agent0/skills/audio/SKILL.md` (compliant, `agentskills-portable`) + `.claude`/`.agents` symlinks.
- [x] 10. **Rule** — `.agent0/context/rules/audio.md` (local-first two-engine, espeak-ng asymmetry, paid-offers-what-local-can't, stayed_local honesty, reopen-triggers, `/transcribe` forward-compat, `paths:` frontmatter).
- [x] 11. **Offline tests** — `.agent0/tests/audio/` fake `piper`, fake kokoro-shim, fake `fal-rest.sh`: local-ok both engines, engine switch, paid cost-print+manifest cost fields, two output classes, unavailable degrade (incl. Kokoro no-espeak-ng), `--quiet`/`--exit-code`.
- [x] 12. **Wiring** — `.gitignore` (draft dir, manifest, cache; tracked asset dir `.gitkeep`); `doctor.sh` audio check; `CLAUDE.md`+`AGENTS.md` `## Audio` block.

## Verification

- [x] `bash .agent0/tests/audio/run-all.sh` green → maps to spec scenarios (local, engine-switch, paid, two-class, degrade) + static facts.
- [x] `/skill validate audio` exit 0.
- [x] `bash .agent0/tools/doctor.sh` reports audio tri-state, stays exit-0 when engines absent.
- [x] **Dogfood** (real): Kokoro pt-BR + Piper EN local synthesis (proves auto-acquire, espeak-ng handling, mp3 output, stayed_local manifest); one paid `--remote` call if `FAL_KEY` present (else cost-print path verified offline). Maps to spec scenarios 1,2,3,5.

## Notes

- Paid body shape (ElevenLabs-on-fal fields) verified at first real `--remote` call; kept env/yaml-overridable so a wrong guess never blocks the local lanes.
- espeak-ng is the headline acquisition risk — if Kokoro's degrade bites in dogfood, the plan's documented fallback is reconsidering Piper-default.
