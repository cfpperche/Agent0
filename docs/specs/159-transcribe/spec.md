# 159 — transcribe

_Created 2026-06-06._

**Status:** shipped

<!-- Non-UI capacity (a CLI/skill utility). No visual-contract gate. -->
**UI impact:** none

## Intent

Add `/transcribe` — a local-first speech-to-text skill that turns an audio **or video** file into a transcript without sending the content to any cloud service and without the human managing any tooling. It is the highest-demand, zero-ethics, zero-inference-cost member of Agent0's audio family (decided in the decision-grade meeting `.agent0/meetings/audio-transcribe-media-family-skills-2026-06-06T17-01-43Z/`). Engine is **whisper.cpp** (MIT). Deliberately **not** a paid-media-family skill: it is a local utility in the `vuln-audit` class — provenance manifest, no cost apparatus, no tiers oracle, no fal queue. Shipped as the dual shape `/transcribe` (skill, Claude Code wrapper) + `.agent0/tools/transcribe.sh` (runtime-neutral engine, Codex/CI call it directly), so Claude Code and Codex CLI reach it identically. The founder's load-bearing UX directive: acquisition and operation must be **as automated and invisible to the human as possible** — `/transcribe call.mp3` just works on first run, acquiring the engine + a default model itself, degrading to a one-line instruction only when auto-acquisition is genuinely impossible.

## Acceptance criteria

- [ ] **Scenario: transcribe an audio file, zero prior setup**
  - **Given** a fresh project with whisper.cpp not yet present
  - **When** the human runs `/transcribe call.mp3` (or `bash .agent0/tools/transcribe.sh call.mp3`)
  - **Then** the engine + the default `base` multilingual model are auto-acquired (maximally invisibly), the audio is transcribed locally, a `txt` transcript is written to the dedicated gitignored transcripts dir and echoed to stdout, and a provenance line is appended to the gitignored JSONL manifest — with result status `ok`

- [ ] **Scenario: video input — audio track is extracted**
  - **Given** a video file `screencast.mp4`
  - **When** `/transcribe screencast.mp4`
  - **Then** ffmpeg extracts/transcodes the audio track to 16 kHz WAV transparently and the transcript is produced exactly as for an audio file (no separate human step)

- [ ] **Scenario: multiple native output formats, thin contract**
  - **Given** `--format txt,srt,json`
  - **When** the file is transcribed
  - **Then** each requested native whisper.cpp format is produced by flag passthrough (no schema normalization, no caption rewrapping), each is recorded as an `outputs[]` entry in the manifest, and a smoke test for each asserts "file exists + minimal parse/signature"

- [ ] **Scenario: engine cannot be auto-acquired — honest degrade, never a crash**
  - **Given** no compiler/binary channel and/or no network on first run
  - **When** `/transcribe call.mp3`
  - **Then** result status is `unavailable` with a one-line actionable acquisition instruction, and the result status is reported distinctly from the process exit code (per the vuln-audit model) — it reports, it never blocks or throws an opaque error

- [ ] **Scenario: audio never leaves the machine**
  - **Given** any local transcription run
  - **When** it completes
  - **Then** the only network egress is the one-time model-weights fetch (from the model host) — the **audio/video content itself is never uploaded** — and the manifest line records `stayed_local: true` for the content

- [ ] Default model is `base` (multilingual, ~142 MiB); `--model` overrides; `base.en`/`*.en` variants are used only behind an explicit English-only choice (non-English audio is never silently degraded).
- [ ] Default output format is `txt`; the full native transcript set is selectable: `txt, srt, vtt, json, json-full, csv, lrc`. `-owts` (karaoke video script) is **excluded** (not a transcript format).
- [ ] Language is auto-detected by default; `--lang <code>` forces it.
- [ ] Transcripts default to a **dedicated gitignored dir**; `txt` is also echoed to stdout, suppressible with `--quiet` for sensitive content.
- [ ] The provenance manifest is a **cumulative gitignored JSONL**, one line per run (success and failure): input path + content hash, duration, engine + version, model, language, `outputs[]`, `stayed_local`, timestamp, status.
- [ ] `doctor` (and `.agent0/tools/doctor.sh` integration) reports engine + ffmpeg + model availability with a tri-state, never failing the harness on absence.
- [ ] The skill passes `/skill` agentskills.io frontmatter compliance and declares a portability tier (target: runtime-agnostic, like `vuln-audit`).
- [ ] `spec.md`/rule carry a forward-compat note for `/audio` (shared `assets/` location, manifest style, doctor pattern conventions) so the two skills don't grow incompatible CLIs.

## Non-goals

- **Paid STT lane** (Deepgram/fal/OpenAI). Named reopen-trigger: **diarization** (speaker labels) — bar = three real Agent0 transcriptions unusable locally specifically for lack of it; Deepgram is the documented candidate backend. Not built in v1.
- **Diarization / speaker attribution** — whisper.cpp does not do it cleanly; it is the headline paid-lane reopen-trigger, not a v1 feature.
- **Real-time / streaming transcription** — batch-file only in v1.
- **Token-level timestamps** — `json-full` (`-ojf`) is included as raw native JSON, but per-token timestamps (which need `--dtw` setup + tests) are **not promised** in v1. This is the one format with real marginal cost; deferred cleanly (flag-owned, not a whole follow-up spec).
- **Audio editing / cleanup / denoising** — input transform only.
- **TTS / speech synthesis / music / SFX** — that is the sibling `/audio` spec, deferred and separate (split by output ontology).
- **Voice cloning** — deferred family-wide with its own reopen-trigger (fraud risk + non-commercial local-engine license).
- **Broadcast-quality subtitle rewrapping / `--max-len` tuning guarantees** — subtitles are clean segment-level passthrough; readability tuning is not a v1 promise.
- **`faster-whisper` adapter** — documented as the strongest future engine adapter, NOT implemented in v1 (avoids dragging Python/CTranslate2/CUDA packaging into the first STT skill).
- **Cost apparatus** (tiers oracle, cost-gate, cost-bearing manifest fields) — structurally absent; this is a local utility, not paid media.

## Open questions

- [ ] **Exact engine auto-acquisition channel(s)** — prebuilt whisper.cpp release binary vs `pywhispercpp`/`uvx` vs a present package manager (brew/apt), per-platform. Resolve at `/sdd plan` via the stack-aware research discipline (`research-before-proposing.md`). The spec fixes the *intent* (auto, invisible, degrade-to-instruction); the plan fixes the *mechanism*.
- [ ] **Exact filesystem locations** — the dedicated gitignored transcripts dir (candidate `assets/transcripts/`) and the manifest path (candidate `assets/generated/.transcribe-manifest.jsonl` or under `.agent0/.runtime-state/`). Reconcile with `/image`/`/video` `assets/` conventions and the `/audio` forward-compat note.
- [ ] **Model-weights host + cache location** — confirm the download source and a gitignored cache path; verify the `base` multilingual footprint and first-run download time stay inside the "invisible" budget.
- [ ] **`doctor` integration depth** — standalone `transcribe.sh doctor`/`caps` subcommand vs a check folded into `.agent0/tools/doctor.sh` (likely both, mirroring existing tools).

## Context / references

- **Graduating meeting:** `.agent0/meetings/audio-transcribe-media-family-skills-2026-06-06T17-01-43Z/meeting.md` (decision-grade; blind openings; 8-row anchored ledger; minority report — local-only v1 is hypothesized demand, diarization trigger watches for the flip).
- **Output-format + default-model second opinion (Codex):** `.agent0/.runtime-state/codex-exec/20260606T173205Z-transcribe-output-formats/last-message.md` — ship all native transcript formats (thin contract), default `txt`; default model `base`; `json-full`/`--dtw` is the one real-cost trap.
- **Architectural model:** `docs/specs/120-vuln-audit/` + `.agent0/context/rules/vuln-audit.md` (on-demand, single-engine, result-status decoupled from exit code, runtime-neutral, reports-never-blocks).
- **Sibling patterns:** `.agent0/context/rules/image-gen.md` (gitignored local manifest, activation/doctor); `.agent0/context/rules/video-gen.md` (ffmpeg dependency already present; `assets/` storage conventions).
- **Sibling spec (forward-compat):** `/audio` (synthesis, TTS-only v1) — second spec in the family, not yet scaffolded.
- whisper.cpp: https://github.com/ggml-org/whisper.cpp (CLI README + models README cited in the Codex consult).
