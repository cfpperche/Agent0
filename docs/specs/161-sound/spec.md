# 161 — sound

_Created 2026-06-06._

**Status:** draft

<!-- Non-UI capacity (a CLI/skill utility). No visual-contract gate. -->
**UI impact:** none

## Intent

Add `/sound` — generation of **creative audio (music + sound effects)**, paid-only, taste-judged. There is no light local engine for music/SFX (unlike TTS's Kokoro/Piper), so this is deliberately the **paid creative-asset** member of the media family — the audio analog of `/image brand`, NOT of the local-first `/audio` utility. Products that the Agent0 harness serves need generated audio assets (UI SFX, a landing-video soundtrack, a demo sting, ambient beds) the same way they need brand visuals. Shipped as the dual shape `/sound` (skill) + `.agent0/tools/sound.sh` (runtime-neutral engine, Codex/CI call it directly), reusing the existing paid stack: `fal-rest.sh`, a `sound-tiers.yaml` oracle, cost-print, and the hybrid manifest. Decided in this session's trade-off discussion (graduating from the audio-family meeting's deferred music/SFX reopen-trigger): kept as a **separate skill** precisely so `/audio`'s local-first identity stays coherent.

## Acceptance criteria

- [ ] **Scenario: generate a sound effect (cheap, flows without confirm)**
  - **Given** `FAL_KEY` set and `--kind sfx`
  - **When** `/sound "door creak" --kind sfx`
  - **Then** the per-call cost estimate is printed, the estimate is below the $0.25 threshold so **no confirm is required**, the SFX is generated via `fal-rest.sh` (tier model from `sound-tiers.yaml`), an mp3 lands in the gitignored draft dir, and a manifest line records the cost fields + `stayed_local: false`

- [ ] **Scenario: generate music above the cost threshold (hard confirm required)**
  - **Given** `--kind music --tier premium` with an estimate above $0.25 (ElevenLabs Music ~$0.80/min)
  - **When** `/sound "lofi hip hop, 60s" --kind music --tier premium` **without** `--confirm-cost-usd`
  - **Then** the call is **refused** with the printed estimate and the required `--confirm-cost-usd ≥ estimate` hint; supplying `--confirm-cost-usd 0.80` (≥ estimate) lets it proceed

- [ ] **Scenario: taste-judged acceptance — draft by default, human promotes**
  - **Given** a generated clip (no `--asset`)
  - **When** it completes
  - **Then** it lands in the **gitignored draft** dir (a preview to listen to); the human promotes a keeper with `--asset` (writes to the tracked dir) or regenerates (a new, cost-printed call) — there is **no automated "done"** (quality is a human listen, like `/image brand`)

- [ ] **Scenario: --kind is required**
  - **Given** no `--kind`
  - **When** `/sound "something"`
  - **Then** it errors naming the two options (`music`/`sfx`) — music and SFX are distinct intents (mirrors `/image`'s required `--tier`)

- [ ] **Scenario: no key — honest degrade**
  - **Given** `FAL_KEY` unset
  - **When** `/sound "..." --kind sfx`
  - **Then** result status is `unavailable` with a one-line hint (set `FAL_KEY`), reported distinctly from the exit code — it reports, never crashes. (There is **no** free local fallback — this skill is paid-only by nature.)

- [ ] `--kind music|sfx` required; flags: `--duration <sec>`, `--tier standard|premium` (music), `--asset`, `--format mp3|wav` (default mp3), `--confirm-cost-usd <n>`, `--json`, `--exit-code` (`ok=0 unavailable=2 error=3`; default exit 0).
- [ ] Tier→model resolves from a date-stamped `sound-tiers.yaml` (no model IDs in code): music `standard`=CassetteAI (~$0.02/min), `premium`=ElevenLabs Music (~$0.80/min); sfx=ElevenLabs Sound Effects v2 (~$0.01/gen). Refresh discipline mirrors `video-tiers.yaml`/`audio-tiers.yaml`.
- [ ] Cost gate is **hybrid**: estimate printed before every call; a hard `--confirm-cost-usd ≥ estimate` is required only when the estimate exceeds the $0.25 threshold (env-overridable).
- [ ] Two output classes (mirrors `/image`/`/audio`): gitignored draft (`assets/generated/sound/`) default vs tracked asset (`assets/sound/`, `--asset`). Hybrid manifest (gitignored JSONL) records cost fields + prompt + kind + tier + `stayed_local:false`; one line per call (success AND failure). `FAL_KEY` never printed or recorded.
- [ ] `doctor`/`caps` report `FAL_KEY` presence + tiers file (tri-state, never fails the harness). Status decoupled from exit code.
- [ ] Passes `/skill` agentskills.io compliance; portability tier `agentskills-portable`. Sibling capacity rule `sound.md`.

## Non-goals

- **A local generation lane** — no light local music/SFX engine exists (MusicGen is heavy/GPU); this skill is **paid-only by nature**, the deliberate exception to the audio family's local-first default (it's an `/image brand` analog, not a `/audio` analog).
- **N-candidate fan-out** — one generation per call (taste curation via listen-and-regen, not auto-variants); N× cost contradicts the cost discipline.
- **Audio editing / mixing / mastering / stems / multitrack** — generation only, not a DAW.
- **Lyrics→sung-vocals music** — depends on the model; out of v1 scope (text prompt → instrumental/SFX).
- **Voice cloning** — deferred family-wide (the `/audio` family decision).
- **SSML / fine compositional control** beyond the prompt — thin passthrough.
- **A second paid provider beyond fal** — fal fronts CassetteAI + ElevenLabs + others; one provider surface in v1.
- **Automated quality acceptance** — "sounds good" is a human judgment; no offline quality gate (only contract tests).

## Open questions

- [ ] **Exact fal body shapes per model** — music (CassetteAI / ElevenLabs Music) vs sfx (ElevenLabs SFX v2) differ in params (duration field name, prompt key); verify at `/sdd plan` / first real call (kept yaml/flag-overridable so a wrong guess never blocks).
- [ ] **sfx tier provider** — ElevenLabs SFX v2 vs CassetteAI SFX ($0.01/gen); confirm the default at plan time.
- [ ] **Default duration per kind** — sfx (~a few sec) vs music (~30s?); and whether the model takes duration or infers from prompt.
- [ ] **Return content-type** — fal sound models likely return mp3; confirm + the wav path.
- [ ] **Confirm-threshold env var name** + exact FS paths (`assets/generated/sound/`, `assets/sound/`, manifest, `sound-tiers.yaml` location under `.agent0/skills/sound/references/`).

## Context / references

- **Graduating discussion:** this session's music/SFX trade-off (own skill, paid-only, taste-judged, `/image brand` analog) — itself the named reopen-trigger from the audio-family meeting `.agent0/meetings/audio-transcribe-media-family-skills-2026-06-06T17-01-43Z/meeting.md`.
- **Paid-stack reuse:** `.agent0/tools/fal-rest.sh`; patterns from `.agent0/context/rules/audio.md` (paid fal lane, hybrid manifest, two output classes), `.agent0/context/rules/image-gen.md` (draft/brand classes, cost-print), `.agent0/context/rules/video-gen.md` (`tiers.yaml` oracle + `--confirm-cost-usd` gate).
- **Sibling shipped specs:** `docs/specs/160-audio/` (the dual-shape + manifest + tiers patterns this mirrors), `docs/specs/159-transcribe/`.
- **fal models:** CassetteAI music/SFX (https://fal.ai/models/cassetteai/music-generator , .../sound-effects-generator), ElevenLabs Music + Sound Effects v2 (https://fal.ai/models/fal-ai/elevenlabs/sound-effects/v2). Prices per the 2026-06-06 lookup; verify via the oracle refresh.
