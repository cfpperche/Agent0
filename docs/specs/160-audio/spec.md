# 160 — audio

_Created 2026-06-06._

**Status:** shipped

<!-- Non-UI capacity (a CLI/skill utility). No visual-contract gate. -->
**UI impact:** none

## Intent

Add `/audio` — text-to-speech synthesis, **local-first and free by default** with an optional **paid upgrade** for higher-quality voices, with no tooling for the human to manage. It is the synthesis member of Agent0's audio family — the counterpart of the recognition-side `/transcribe` (shipped, spec 159) — and was shaped in the decision-grade meeting `.agent0/meetings/audio-transcribe-media-family-skills-2026-06-06T17-01-43Z/` (split by output ontology: synthesis produces a media asset; recognition produces text). Shipped as the dual shape `/audio` (skill) + `.agent0/tools/audio.sh` (runtime-neutral engine, Codex/CI call it directly). v1 is **TTS only** — music/SFX and voice cloning are deferred (see Non-goals). The founder's UX directive (carried from `/transcribe`): acquisition + operation are as automated and invisible as possible, degrading to a one-line hint when impossible.

## Acceptance criteria

- [ ] **Scenario: speak text locally, free, zero prior setup**
  - **Given** a fresh project with no TTS engine present
  - **When** the human runs `/audio "olá, mundo"` (or `bash .agent0/tools/audio.sh "olá, mundo"`)
  - **Then** the default local engine (**Kokoro**) + a default grade-A voice are auto-acquired as invisibly as possible, speech is synthesized **on-device**, an `mp3` is written to the gitignored draft dir, and a provenance line is appended to the hybrid JSONL manifest — result status `ok`, `stayed_local: true`

- [ ] **Scenario: pick the other local engine**
  - **Given** `--engine piper`
  - **When** the text is synthesized
  - **Then** Piper is used instead of Kokoro (both are first-class co-defaults; Kokoro is only the zero-flag default), acquired the same invisible way, with its own default voice

- [ ] **Scenario: paid upgrade via fal (opt-in)**
  - **Given** `--remote` and `FAL_KEY` set
  - **When** `/audio "<text>" --remote`
  - **Then** a per-character cost **estimate is printed before** the call (image-style, no hard gate), the paid tier→model resolves from `audio-tiers.yaml` (no model IDs in code), synthesis runs via the existing `fal-rest.sh`, and the manifest line carries the **cost fields** (provider, model, cost_estimate_usd, request_id) and `stayed_local: false` (text was sent to fal — stated honestly)

- [ ] **Scenario: two output classes (mirrors /image)**
  - **Given** the default (no `--asset`) vs `--asset`
  - **When** audio is produced
  - **Then** the default lands in the **gitignored draft** dir (throwaway preview) and `--asset` lands in the **tracked** voiceover dir (a kept asset) — the class is mechanical, independent of local/paid lane

- [ ] **Scenario: engine cannot be auto-acquired — honest degrade, never a crash**
  - **Given** no acquisition channel (and, for Kokoro, no `espeak-ng` system binary) and/or no network
  - **When** `/audio "<text>"`
  - **Then** result status is `unavailable` with a one-line actionable hint, reported distinctly from the process exit code (vuln-audit/transcribe model) — it reports, never blocks or throws opaque

- [ ] Default engine (zero `--engine`) is **Kokoro** (multilingual incl. pt-BR, Apache-2.0 weights, grade-A default voice); `--engine piper` switches to Piper (904 EN voices). Both are user-installed + **subprocess-invoked, never bundled** (GPL-via-subprocess = aggregation; the HyperFrames `npx` posture).
- [ ] Composable flags: `--engine kokoro|piper`, `--remote`, `--asset`, `--voice <name>`, `--lang <code>`, `--format mp3|wav` (default mp3), `--json`, `--exit-code` (`ok=0 unavailable=2 error=3`; default always exit 0).
- [ ] Manifest is a **cumulative gitignored hybrid JSONL**: provenance fields for the local lane (engine, voice, lang, model, `stayed_local`) + cost fields for the paid lane (provider, model, `cost_estimate_usd`, request_id); one line per call (success AND failure).
- [ ] `doctor`/`caps` report engine(s) + espeak-ng + ffmpeg + voice/model cache availability (tri-state, never fails the harness on absence); integrated into `.agent0/tools/doctor.sh`.
- [ ] The skill passes `/skill` agentskills.io compliance and declares a portability tier (`agentskills-portable`, matching `/transcribe`/`vuln-audit`).
- [ ] Forward-compat with `/transcribe`: shared `assets/` conventions, manifest style, `doctor`/`caps` + status-decoupling pattern, sibling capacity rule.

## Non-goals

- **Music / SFX generation** — paid-only, no light local engine, different acceptance standard; deferred with its own reopen-trigger.
- **Voice cloning** — deferred family-wide (fraud/impersonation risk + non-commercial local-engine license); on reopen: paid-only + a first-class `--consent-attested` gate.
- **A second paid provider beyond fal** — ElevenLabs-direct is deferred; fal already fronts ElevenLabs models, so v1 reuses `fal-rest.sh` rather than integrating a new provider.
- **SSML / fine prosody control** beyond what each engine exposes natively — thin passthrough; no prosody-authoring layer.
- **Streaming / real-time TTS** — batch synthesis only in v1.
- **Auto-detection of the input text's language** — TTS cannot infer it; language/voice is user-specified with a sensible default (don't fake detection).
- **Bundling / vendoring any engine or voice model** into the repo — always user-installed + subprocess, like `/transcribe`.
- **A hard cost gate or per-session budget counter** — TTS is cheap (per-character); cost-print only, matching `/image` (deliberately no counter, like `/image`/`/video` v1).

## Open questions

- [ ] **Exact acquisition channel per engine — and the espeak-ng wrinkle.** Kokoro (`pip install kokoro`) needs **espeak-ng**, a **system binary** (not a pip wheel), so `uvx` cannot make it fully self-contained the way it did for whisper.cpp in `/transcribe` — "invisible" likely degrades to an "install espeak-ng" hint on many systems. Piper (`piper-tts` / `piper1-gpl`) bundles its phonemizer differently. Resolve the real per-engine ladder at `/sdd plan` (research-before-proposing); the spec fixes intent (auto, invisible, degrade-to-hint), the plan fixes mechanism.
- [ ] **Exact FS paths** — draft dir (candidate `assets/generated/audio/`), tracked asset dir (candidate `assets/audio/`), manifest (candidate `assets/generated/.audio-manifest.jsonl`), engine/voice/model cache (`.agent0/.runtime-state/audio/`). Reconcile with `/image` (`assets/generated/mockups/` vs `assets/brand/`) and `/transcribe` conventions.
- [ ] **`audio-tiers.yaml` seed** — which fal TTS models/tiers (ElevenLabs-via-fal + alternatives), date-stamped + refreshable like `video-tiers.yaml`; verify current endpoints at plan/first-use.
- [ ] **Default voice per engine** — a specific grade-A Kokoro voice id + a Piper default voice; how `--lang` maps to voice selection.
- [ ] **mp3 encoding** — engines emit WAV; mp3 default needs ffmpeg (already a `/video`/`/transcribe` dep) — confirm the encode path and the wav-passthrough when `--format wav`.

## Context / references

- **Graduating meeting:** `.agent0/meetings/audio-transcribe-media-family-skills-2026-06-06T17-01-43Z/meeting.md` (decision-grade; the GPL-license constraint A — no local TTS engine is GPL-clean, resolved by user-installed-subprocess aggregation — is this spec's core posture).
- **Sibling spec (shipped):** `docs/specs/159-transcribe/` + `.agent0/context/rules/transcribe.md` — the dual-shape pattern, auto-acquisition ladder, status-decoupling, provenance manifest, gitignore discipline this spec mirrors.
- **Paid-media patterns:** `.agent0/context/rules/image-gen.md` (two output classes draft/brand, cost-print, manifest) + `.agent0/context/rules/video-gen.md` (`tiers.yaml` oracle, `fal-rest.sh` reuse).
- **Engines:** Kokoro https://github.com/hexgrad/kokoro (Apache-2.0 weights, 88 voices/9 langs incl. pt-BR; espeak-ng GPL-3.0 phonemizer — issue hexgrad/kokoro#247) · Piper https://github.com/OHF-Voice/piper1-gpl (GPL-3.0 successor, 904 EN voices).
- **Reused infra:** `.agent0/tools/fal-rest.sh` (paid lane).
