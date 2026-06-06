# 161 — sound — plan

_Drafted from `spec.md` on 2026-06-06. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Clone the `/audio` **paid lane** (it already has the exact pieces: `fal-rest.sh run`, a tiers oracle, cost-print, hybrid manifest, draft/asset classes) and drop the local lanes entirely — `/sound` is paid-only by nature. Thin `.agent0/skills/sound/SKILL.md` over a runtime-neutral `.agent0/tools/sound.sh`; status (`ok|unavailable|error`) decoupled from exit code.

**The researched decision — make the oracle data-driven, not the engine.** The fal model pages confirm body shapes AND output paths **differ per model**:
- ElevenLabs SFX v2 (`fal-ai/elevenlabs/sound-effects/v2`): body `{text}`, output `audio.url`, **$0.002/sec**.
- CassetteAI Music (`cassetteai/music-generator`): body `{prompt, duration}`, output **`audio_file.url`** (not `audio.url`), **$0.02/min**.
- ElevenLabs Music (premium, candidate `fal-ai/elevenlabs/music`): body ~`{prompt}` (+duration?), output likely `audio.url` — **verify at first call**.

So `sound-tiers.yaml` carries, per tier, everything the engine needs to be model-agnostic: `model` (endpoint), `prompt_field` (`text`|`prompt`), `duration_field` (or none), `output_url_path` (jq path, e.g. `.audio.url` or `.audio_file.url`), `price`, `price_unit` (`per_second`|`per_minute`|`per_gen`). `sound.sh` reads those, builds the body generically, computes `cost = price × duration_in_unit`, and extracts the URL via the per-tier jq path. New models = a yaml edit, no code change. (This is the lesson from `/audio`, where a fixed `.audio.url // .audio_url // .url` extraction would have silently missed CassetteAI's `audio_file.url`.)

**Cost gate (hybrid):** print `cost` before every call; require `--confirm-cost-usd ≥ cost` only when `cost > $0.25` (env-overridable `AGENT0_SOUND_CONFIRM_THRESHOLD`). SFX ($0.002/s → a 5s clip $0.01) and CassetteAI music flow; ElevenLabs Music ($0.80/min) confirms.

**Acceptance (taste-judged):** one generation → draft (gitignored) → human listens → `--asset` promotes to the tracked dir, or regenerate (new cost-printed call). No automated quality gate; offline tests prove the *contract* (cost math, gate, manifest, url extraction, kind-required, no-key degrade) with a fake `fal-rest`, never audio quality.

Build order: engine skeleton (parse/caps/doctor) → tiers oracle + data-driven body/url/cost → cost-print + hybrid confirm gate → fal call + download + draft/asset placement + hybrid manifest → offline tests (fake fal-rest) → SKILL/rule/symlinks → wiring → validate → dogfood (a real ~$0.01 SFX).

## Files to touch

**Create:**
- `.agent0/skills/sound/SKILL.md` — skill entry (`/skill new sound --tier agentskills-portable`); surface `/sound "<prompt>" --kind music|sfx [--tier standard|premium] [--duration <sec>] [--asset] [--format mp3|wav] [--confirm-cost-usd <n>] [--json] [--exit-code]` + `doctor`/`caps`.
- `.agent0/tools/sound.sh` — engine: arg parse (`--kind` required), tier resolve from yaml, generic body build (`prompt_field`/`duration_field`), `cost = price × duration_in_unit`, hybrid gate, `fal-rest.sh run` → per-tier `output_url_path` extraction → `fal-rest.sh download`, draft/asset placement, ffmpeg mp3 encode (wav passthrough), hybrid manifest, status/exit decoupling.
- `.agent0/skills/sound/references/sound-tiers.yaml` — date-stamped per-tier oracle with the data-driven fields above (music standard=CassetteAI, premium=ElevenLabs Music; sfx=ElevenLabs SFX v2). `stale_after_days`, `confirm_threshold_usd: 0.25`.
- `.agent0/context/rules/sound.md` — capacity rule (paid-only creative audio, `/image brand` analog, hybrid gate, taste-judged human-in-loop, data-driven oracle, `stayed_local:false` always, non-goals, reopen-triggers).
- `.agent0/tests/sound/` — offline suite with a fake `fal-rest.sh`: sfx-flows-no-confirm, music-above-threshold-refused-then-confirmed, draft-vs-`--asset`, `--kind` required, no-`FAL_KEY` degrade, per-tier url-path extraction (incl. CassetteAI `audio_file.url`), cost math per unit, manifest cost fields + key-never-recorded.
- Symlinks `.claude/skills/sound` + `.agents/skills/sound`.

**Modify:**
- `.agent0/tools/doctor.sh` — `sound` check (FAL_KEY presence + tiers file; tri-state, never fails harness).
- `.gitignore` — draft `assets/generated/sound/*` (+`.gitkeep`) + manifest `assets/generated/.sound-manifest.jsonl`; tracked `assets/sound/` gets a `.gitkeep` (NOT ignored — kept creative assets are committable, like `assets/brand/`).
- `CLAUDE.md` + `AGENTS.md` — `## Sound` managed-index block (parity).
- `.agent0/tools/sync-harness.sh` `COPY_CHECK_FILES` — add `assets/sound/.gitkeep` + `assets/generated/sound/.gitkeep` (the audio-shim lesson: dirs/files the skill needs must be in the manifest).
- `.agent0/harness-sync-baseline.json` — regenerated.

**Delete:** none.

## Alternatives considered

### Hardcode per-model body/url branches in sound.sh

Rejected. Body shapes and output paths drift per model and per provider (CassetteAI `audio_file.url` vs ElevenLabs `audio.url` already differ). Hardcoding `if model==X then ...` branches puts volatile vendor quirks in code; the refreshable `sound-tiers.yaml` is the right home (same reasoning as `video-tiers.yaml` holding model IDs out of code). The engine stays generic; the oracle absorbs drift.

### Fold into `/audio` as `--kind music|sfx`

Rejected (the trade-off discussion's core finding). `/audio` is local-first utility; `/sound` is paid-only creative, taste-judged, human-in-loop — different lane model, cost shape, and acceptance. Bolting them together makes `/audio` incoherent. Separate skill keeps both honest. (Spec § Intent.)

### A local generation lane (MusicGen, etc.)

Rejected for v1. No light/CPU-friendly local music/SFX engine exists (MusicGen is heavy/GPU). Forcing one would betray the "invisible/local-first" bar that worked for TTS. `/sound` is openly paid-only — the `/image brand` analog — and says so.

## Risks and unknowns

- **ElevenLabs Music (premium) endpoint + body unverified** — `fal-ai/elevenlabs/music` is a candidate; the real endpoint/body/url-path + duration handling are confirmed at first call. Mitigated: the oracle is the single edit point, and the cheap tiers (CassetteAI music, ElevenLabs SFX) are confirmed, so the skill works even if premium needs a one-line yaml fix.
- **Per-unit cost math** — SFX is per-second, music per-minute; the `price_unit` field must drive the formula or estimates mislead the gate. Covered by an offline test per unit.
- **Taste quality is not offline-testable** — tests prove the contract only; quality is a human listen in dogfood (a ~$0.01 SFX suffices to prove the pipeline end-to-end).
- **Duration semantics differ** — some models take `duration`, others infer from prompt or cap it; `duration_field: null` in the oracle means "omit". Verify per model at first call.
- **Generated-audio licensing** — provider terms govern commercial use of output; a one-line note in the rule, not a blocker.

## Research / citations

- ElevenLabs Sound Effects v2 on fal — endpoint `fal-ai/elevenlabs/sound-effects/v2`, input `text`, output `audio.url`, $0.002/sec: https://fal.ai/models/fal-ai/elevenlabs/sound-effects/v2
- CassetteAI Music Generator on fal — endpoint `cassetteai/music-generator`, input `prompt`+`duration`, output `audio_file.url`, $0.02/min: https://fal.ai/models/cassetteai/music-generator
- ElevenLabs Music on fal (premium candidate) + pricing $0.80/min: https://fal.ai/elevenlabs · https://blog.fal.ai/elevenlabs-audio-suite-next-generation-voice-and-audio-ai-now-on-fal/
- Reused infra + patterns: `.agent0/tools/fal-rest.sh`; `.agent0/context/rules/{audio,image-gen,video-gen}.md`
- Sibling shipped spec: `docs/specs/160-audio/` (paid lane, tiers oracle, hybrid manifest, draft/asset, doctor/caps, status-decoupling)
