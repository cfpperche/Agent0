# 161 — sound — notes

_Created 2026-06-06._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building**._

## Design decisions

### 2026-06-06 — parent — Data-driven oracle validated LIVE (the headline decision)

The whole point of `sound-tiers.yaml` carrying `prompt_field` / `duration_field` / `output_url_path` / `price` / `price_unit` (not just `model`) is that body shapes AND output url paths **differ per model**. The dogfood proved this against the real fal API, not just offline fakes:

- **ElevenLabs SFX v2** (`fal-ai/elevenlabs/sound-effects/v2`): body `{text, duration_seconds}` → url at **`.audio.url`**. Real 3s call ($0.006) → 48 KB mp3 (ID3 MPEG layer III, 64 kbps stereo). ✓
- **CassetteAI music** (`cassetteai/music-generator`): body `{prompt, duration}` → url at **`.audio_file.url`** (≠ `.audio.url`). Real 10s call ($0.0033) → 161 KB mp3. ✓ — the exact case a fixed `.audio.url` extraction would silently miss (the `/audio` build's near-miss). The generic engine + per-tier jq path handled both with zero code branching.

Total dogfood spend: **~$0.0093** (under a cent), founder-authorized cheap dogfood.

### 2026-06-06 — parent — `--tier` is music-only; kind/tier mismatch caught

sfx forces its single `sfx` tier (ignores `--tier`). Music defaults to `standard` (CassetteAI). A `--kind music --tier sfx` mismatch errors — each tier carries a `kind` field that must equal `--kind`. Keeps the surface honest without a combinatorial flag matrix.

## Deviations

### 2026-06-06 — parent — `--json` / `caps` emit COMPACT JSON (not pretty)

Plan didn't specify. Chose `jq -nc` (compact, one-line) over `audio.sh`'s `jq -n` (pretty) — consistent with the JSONL manifest and better for pipe/grep. The only mid-build correction (the test suite caught the pretty-vs-compact mismatch).

### 2026-06-06 — parent — No Agent0 self-baseline to regenerate

Plan listed "baseline regen" as a wiring step. In fact `.agent0/harness-sync-baseline.json` is written into the *consumer* on `--apply`; Agent0's source repo has none. The `COPY_CHECK_FILES` gitkeep additions (`assets/sound/.gitkeep`, `assets/generated/sound/.gitkeep`) are what makes the new dirs travel; consumers pick up `/sound` (skill dir, tool glob, rule, tests all already covered by recursive globs) on next harness-sync.

## Tradeoffs

### 2026-06-06 — parent — `request_id` empty for the sync lane (accepted)

`fal-rest.sh run` (synchronous `fal.run/<model>`) returns the model output directly with **no** `request_id` (only the async `submit`/`status`/`result` queue carries one). Both SFX and CassetteAI returned none. Kept the manifest field present-but-empty rather than switching `/sound` to the async queue just to capture an id — sync is simpler and the clips are fast/small. Not a bug.

## Open questions

### 2026-06-06 — parent — ElevenLabs Music premium is live-unverified (gated, acceptable)

`fal-ai/elevenlabs/music` (~$0.80/min): endpoint + body (`{prompt, music_length_ms}` guess) + url path (`.audio.url` guess) are **not** verified against the live API — not worth $0.80 to dogfood. It's gated behind the hard `--confirm-cost-usd` (>$0.25), and the oracle is the single edit point if the first real premium call needs a fix. Duration-unit caveat: `duration_field: music_length_ms` currently receives a *seconds* value as-is (latent unit mismatch, flagged in the oracle note) — first premium call resolves it with a one-line yaml/engine fix. **Owner:** whoever makes the first real premium call. The two everyday tiers (SFX + music standard) are live-proven, so the skill ships sound without this.

---

**Family position:** audio media family now COMPLETE — `/transcribe` (159, STT, local) + `/audio` (160, TTS, local-first + optional paid) + `/sound` (161, music/SFX, paid-only creative). Split by output ontology + lane model. Consumer-facing → next harness-sync.

**Validation:** offline suite 58 assertions / 6 scenarios PASS; `/skill validate` rc 0 (description trimmed to ≤1024); `doctor` 21 ok / 0 advisory / 0 broken.
