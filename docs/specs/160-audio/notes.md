# 160 — audio — notes

_Created 2026-06-06._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, open questions surfaced while building. Append-only._

## Design decisions

### 2026-06-06 — parent — Kokoro via first-party shim; Piper via native CLI

Piper ships a real `piper` CLI (uvx-able, self-contained phonemization) so it's called directly. Kokoro is a library + needs espeak-ng, so it's driven by a ~40-line first-party shim `audio-kokoro.py` (run via `uvx --with kokoro --with soundfile python`), NOT an un-vetted third-party CLI. Paid tiers are ElevenLabs-only (local already gives Kokoro free).

## Deviations

_None — followed plan.md._

## Tradeoffs

### 2026-06-06 — parent — Two engines co-default (founder choice) — accepted surface cost

The founder chose both Kokoro+Piper as first-class co-defaults over one-default-one-documented. Accepted cost: two acquisition ladders, two default-voice schemes, ~double the test surface. Mitigated by sharing the encode/output/manifest path across both.

## Open questions

### 2026-06-06 — parent — DOGFOOD FINDING — the zero-flag default (Kokoro) fails out-of-box without espeak-ng

The real dogfood confirmed the plan's headline risk on the dev host: **`espeak-ng` is absent here, so the default engine (Kokoro) returns `unavailable`** (honest hint + Piper fallback suggestion, exit 0). Piper, by contrast, worked end-to-end with zero prior setup (uvx fetched `piper-tts`, voice auto-downloaded, real ~5s mp3 in 4.3s). So on a fresh machine the *quality* default is the *less* available one. **Decision for the founder:** keep Kokoro-default (quality/pt-BR, accept the first-run espeak-ng install step) vs make **Piper the zero-flag default** (works out-of-box; Kokoro opt-in via `--engine kokoro`). Logged, not silently changed — the founder picked Kokoro-default explicitly. The plan named this exact reconsideration trigger; it has now fired in dogfood.

### 2026-06-06 — parent — RESOLVED — paid lane proven with a real fal call (founder consent)

The founder approved one real call. `--remote --tier standard` → endpoint `fal-ai/elevenlabs/tts/turbo-v2.5` is real, body `{"text":...}` (no voice) was accepted, a real ElevenLabs mp3 (44.1kHz, 17KB) downloaded, cost printed before ($0.05), manifest carried the cost fields (`lane:paid, provider:fal, model, cost_estimate_usd:0.05, stayed_local:false`) and **no key leak**. Note: `request_id` is empty because the SYNC `run` endpoint returns none (only `submit` does) — not a bug. The tiers.yaml endpoints + body shape are confirmed; the dogfood test mp3 was removed from the tracked asset dir (it was a throwaway, not a project asset).

### 2026-06-06 — parent — RESOLVED in build — two real bugs caught before commit

(1) **Secret leak:** `doctor` printed `${FAL_KEY:-unset}` which expands to the *value* when set — leaked the real key. Fixed to a safe `set`/`unset` label + added a regression test (06) asserting the key value never appears in doctor output. (2) **Piper voice URL:** HF `rhasspy/piper-voices` layout is nested (`<fam>/<locale>/<name>/<quality>/`), not flat — fixed the URL builder; real voice download then worked. (3) `AUDIO_ESPEAK_OK=0` now means *forced-absent* so the degrade test is host-deterministic.
