---
meeting: audio-transcribe-media-family-skills
topic: "Skill /audio (synthesis: TTS local-first + paid) e /transcribe (STT local-first) — duas skills da família de mídia, separadas por direção; voice clone adiado"
created: 2026-06-06T17:01:43Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 3
next_speaker: human
synthesis: accepted
---

# Meeting: Skill /audio (synthesis: TTS local-first + paid) e /transcribe (STT local-first) — duas skills da família de mídia, separadas por direção; voice clone adiado

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — Carlos (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:e898ab0936d5a90a` (3776 bytes)
- commit codex — `sha256:fe3ee3d251c5c8c6` (7747 bytes)

### Turn 1 — claude (blind opening) (claude)

## Opening — claude

**Frame.** We're deciding the shape of audio capacity for Agent0, a harness that already ships `/image` and `/video` as opt-in paid-media skills. The proposal: split audio by *direction* into `/transcribe` (recognition: audio→text) and `/audio` (synthesis: text→audio), defer voice clone. I'll commit my independent position on the four live questions, then argue the one I think is most likely to be gotten wrong.

**Q1 — Split by direction: YES, but for a sharper reason than "two directions."** TTS/music *produce* an artifact that lives in the repo (an `.mp3`/`.wav` asset, gitignored draft vs tracked brand — exactly `/image`'s storage model). Transcription produces *text*, which is not a media asset at all — it's an input transform, like running a linter or a parser over a file the user already has. They don't just run in opposite directions; they have different *output ontologies*. One spec cannot give both a coherent storage/manifest/cost contract. Split.

**Q2 — The load-bearing claim: `/transcribe` probably should NOT be a member of the paid-media family at all.** whisper.cpp (MIT) is mature, local, CPU-viable, zero-cost, zero-ethics. The honest default for transcription is *100% local, no paid dep ever*. If that's true, then the entire `/image`/`/video` apparatus — tiers.yaml oracle, cost-print, cost-gate, paid-manifest with `cost_estimate_usd` — is dead weight on `/transcribe`. It's closer to `.agent0/tools/vuln-audit.sh` (a local, runtime-neutral utility wrapping a vendored engine) than to a media-gen skill. **My position: `/transcribe` is a local-first utility; a paid STT fallback (Deepgram/fal/OpenAI) is a *nice-to-have that must clear its own rule-of-three demand test*, not a v1 requirement.** Shipping the paid lane "for symmetry with /image" is exactly the speculative-completeness smell the harness keeps killing. Start local-only; add paid STT when a real file whisper.cpp can't handle shows up.

**Q3 — `/audio` synthesis: local-first spine is real but asymmetric, and music is the weak limb.** Piper (MIT) / Kokoro (Apache-2.0) give a genuine free+local TTS floor → paid (ElevenLabs/fal) as a quality upgrade. That mirrors `/video`'s `code`-free / `generative`-paid two-tier cleanly. **But music/SFX has no viable lightweight local engine** (MusicGen is heavy), so it's generative-paid-only — a different cost shape from TTS. I'd question whether music even belongs in v1: it's the lowest-demand limb, paid-only, and bundling it forces the cost apparatus onto `/audio` from day one. Consider: `/audio` v1 = **TTS only** (local→paid), music as a deferred generative tier with its own demand gate. That keeps each skill's contract honest about what it actually does.

**Q4 — Voice clone deferred: AGREE, strongly.** Lowest real demand, highest fraud/impersonation risk, and the only viable local engine (XTTS/Coqui) ships a non-commercial license that breaks harness propagation to commercial consumers — the Remotion problem the repo already chose against once. Defer with a recorded reopen-trigger (spec-157 style); on reopen, paid-only + a first-class `--consent-attested` gate + manifest attribution.

**Sequence.** `/transcribe` first, standalone, local-only — it's the highest-demand, simplest, zero-ethics, zero-cost-apparatus skill. It can ship fast and prove the "audio family" is worth the second skill. `/audio` synthesis follows as its own spec once `/transcribe` validates the family.

**The thing I most want pressure-tested:** my Q2 claim that `/transcribe` should shed the paid-media apparatus entirely. If Codex thinks the paid STT lane is load-bearing in v1, I want the concrete consumer scenario that whisper.cpp local can't serve — not "symmetry with /image."


### Turn 2 — codex (blind opening) (codex)

My opening position: ship `/transcribe` first as a local utility, not as paid media; then ship `/audio` as speech synthesis only. Do not include paid STT, music, SFX, or clone lanes in v1. The split by direction is correct, but the two skills should not inherit the same apparatus just because they sit near each other semantically.

Q1. `/transcribe` should be local-only in v1, with `whisper.cpp` as the default spine.

`whisper.cpp` is the right first engine for an Agent0 harness wrapper: MIT licensed, plain C/C++, no heavy Python environment by default, broad platform support, CPU-only operation, quantized models, Apple Silicon/GPU paths, and a CLI-shaped integration surface. That fits Agent0 better than making the first STT skill a Python package manager problem.

I would document `faster-whisper` as the strongest future adapter, not implement it in v1. It is MIT and production-relevant, but it pulls the skill toward Python/CTranslate2/CUDA packaging concerns before the harness has proven it needs that lane.

Paid STT should not be in v1. A concrete paid lane would serve scenarios local Whisper does not solve cleanly: real-time streamed transcription at low latency, managed high concurrency, speaker diarization, keyterm boosting, smart formatting, PII redaction, and enterprise/compliance features. Deepgram’s public docs/pricing make that case clearly. OpenAI’s newer transcription models make a quality/fallback case too. But those are product scenarios, not the base harness utility.

Strongest alternative: ship Deepgram or OpenAI as a paid fallback now, because users often expect speaker labels, clean formatting, and better noisy-audio behavior from “transcribe.”

Evidence that would make the alternative win: three real Agent0 uses where `whisper.cpp` produces unacceptable output or runtime, and the blocker is specifically one of diarization, streaming latency, domain terms, noisy far-field audio, or scale. A single “it would be nice” is not enough.

Strongest objection to my view: local-only may underdeliver for meeting transcripts, where speaker attribution is often the difference between useful and cleanup-heavy. If the founder’s first real demand is “turn this multi-speaker meeting into usable notes,” paid STT may become justified faster than I am assuming.

Q2. `/transcribe` is not a paid-media-family skill in v1.

It should be closer to `vuln-audit`, `status`, or a scanner wrapper: deterministic input, local engine, text output, no inference bill, no model-tier oracle, no cost confirmation, no fal queue. The manifest should be provenance, not a cost ledger: input path/hash, duration, engine, model file, language, timestamps setting, output files, warnings, and whether audio stayed local.

If a paid STT backend is later added, add cost fields then. Do not pre-install the `/image`/`/video` cost apparatus into a local-only skill.

Strongest alternative: keep `/transcribe` inside the media family from day one so all media skills share tiers, manifests, and provider policy.

Evidence that would make the alternative win: an accepted v1 requirement for paid transcription, or a shared manifest helper that cleanly serves both provenance and cost without making local runs noisy.

Strongest objection to my view: provenance and cost are not enemies. `/image` and `/video` manifests are also audit trails. If `/transcribe` creates a separate manifest style, Agent0 may end up with avoidable schema drift across media skills.

Q3. `/audio` v1 should mean TTS only. Defer music and SFX.

The v1 spine should be speech synthesis: local first, paid upgrade second. I would be cautious about the local default. Piper’s original repo is MIT but archived; the maintained successor is GPL-3.0. That does not automatically forbid “call an installed binary,” but it does mean Piper should not be blindly treated as the propagation-safe default without a license posture. Kokoro is the better default candidate on paper because its repo/model posture is Apache-2.0 and it is lightweight, but the spec still needs a dependency audit around phonemization/eSpeak-style components before claiming clean redistribution.

Paid TTS belongs in v1 if `/audio` ships: ElevenLabs/fal-style providers are exactly where the existing paid-media discipline helps. Use hard cost confirmation, cost printing, manifest lines, redacted stderr, graceful fallback, and no auto-fire from downstream skills. Voice clone remains out.

Music/SFX should be deferred. They are not text-to-speech. They are text-to-sound/text-to-music, paid-only, licensing-sensitive, taste-sensitive, and likely to drag in a different acceptance standard. fal and ElevenLabs clearly expose music/SFX surfaces, so the mechanism exists, but existence is not demand.

Strongest alternative: put `--kind tts|sfx|music` in `/audio` v1 because the user-facing category “audio synthesis” naturally includes all three, and fal/ElevenLabs already sell them together.

Evidence that would make the alternative win: three real product/frontend/video tasks needing generated ambience, UI sounds, or background music where stock/local/simple authored audio is insufficient and the generated asset lands in a shipped artifact.

Strongest objection to my view: calling the skill `/audio` while only supporting speech is semantically narrow. If we keep the name, the docs must say “v1 synthesis means speech/TTS; music and SFX are deferred reopen triggers,” otherwise users will assume broader capability.

Q4. Sequence should be two specs: `/transcribe` first, `/audio` second.

`/transcribe` is simpler, higher-demand, and mostly local. It can establish the audio-file handling, output conventions, and provenance manifest without getting tangled in paid synthesis policy. Then `/audio` can reuse only what survived contact with a real skill.

A combined spec risks coupling unlike things: STT is recognition and utility-like; TTS is generation and media-like; music/SFX and cloning are separate reopen questions. One meeting can decide the family direction, but the implementation specs should be split.

Strongest alternative: one combined media-family spec to settle shared names, output directories, manifest schemas, and provider conventions once.

Evidence that would make the alternative win: if the implementation plan shows the two skills share enough machinery that splitting creates duplication, or if the first dogfood requires an end-to-end voice workflow where STT and TTS must ship together.

Strongest objection to my view: split specs can postpone shared interface decisions and accidentally produce two incompatible CLIs. To avoid that, the `/transcribe` spec should include a short “future `/audio` compatibility” note, but not implement `/audio`.

My proposed v1 cut:

`/transcribe`: local-only `whisper.cpp`; optional model download/check guidance; transcript formats like txt/srt/vtt/json if cheap; provenance manifest; no paid tier oracle.

`/audio`: second spec; TTS only; local Kokoro-first unless license audit says otherwise, Piper as explicit/user-installed adapter; paid ElevenLabs/fal TTS behind confirmation and manifest; no music/SFX; no clone.

Sources:
https://github.com/ggml-org/whisper.cpp
https://github.com/SYSTRAN/faster-whisper
https://deepgram.com/pricing
https://developers.deepgram.com/docs/diarization
https://developers.openai.com/api/docs/models/gpt-4o-transcribe
https://github.com/rhasspy/piper
https://github.com/OHF-Voice/piper1-gpl
https://github.com/hexgrad/kokoro
https://elevenlabs.io/docs/api-reference/text-to-speech/convert
https://elevenlabs.io/docs/overview/models
https://fal.ai/docs/documentation/model-apis/pricing
https://fal.ai/models/fal-ai/elevenlabs/music/api

### Turn 3 — Claude Code (claude)

Critique turn (claude, post-reveal). We converged independently on all four questions — and the convergence is anchored, not bare agreement. I concede one factual error in my own opening and then sharpen the two points where "we agree" is still hiding real work.

**Conceded (my error).** My opening called Piper the MIT propagation-safe default. Codex is right and I verified it: the MIT `rhasspy/piper` repo was archived Oct 2025; the maintained successor is `OHF-Voice/piper1-gpl`, **GPL-3.0**. My Q3 default claim was wrong as stated.

**Where we converge, with anchors (not assertion-only):**
- Q1 — `/transcribe` local-only v1, `whisper.cpp` (MIT) spine; `faster-whisper` documented as the future adapter, not built. Anchor: whisper.cpp MIT (github.com/ggml-org/whisper.cpp).
- Q2 — `/transcribe` is NOT a paid-media-family skill: vuln-audit-class local utility, **provenance manifest** (input hash, duration, engine, model, language, outputs, "stayed local") not a cost ledger; no tiers oracle / cost-gate / fal queue. Both of us reached this independently.
- Q4 — two specs, `/transcribe` first (simpler, higher-demand, establishes audio-file handling + output conventions + provenance manifest); `/audio` second, reusing only what survives contact. Each spec carries a short forward-compat note so we don't grow two incompatible CLIs.

**Sharpen #1 — Q3, the local-TTS-default is shakier than EITHER of us said, but the fix is a known harness pattern, not a kill.** I verified both viable local engines carry GPL exposure: Piper successor is GPL-3.0; Kokoro's Apache-2.0 weights still route phonemization through **espeak-ng (GPL-3.0)** (open issue hexgrad/kokoro#247). BUT this is not the XTTS/Coqui situation. That was a **model license** forbidding commercial *use of the model itself*. This is **GPL on a CLI you shell out to** — and GPL-via-subprocess of a user-installed binary is mere aggregation, the exact posture Agent0 already ships for HyperFrames (`npx hyperframes`, user-fetched, never bundled). So the refined Q3 position: local TTS CAN stay the default **iff** the engine is user-installed and invoked as a subprocess (never vendored/bundled into the consumer repo), with an explicit one-paragraph license posture in the spec. The `/audio` spec's first real task is that dependency-license audit (Kokoro+espeak-ng vs Piper-GPL vs paid-only) — it is not a `/transcribe` blocker, and it does not by itself force paid-first.

**Sharpen #2 — Q1, name the paid-STT reopen-trigger concretely instead of "add it when needed."** Codex's own strongest objection is the right one: the most *predictable* first real demand is multi-speaker audio where **diarization** (speaker labels) is the difference between usable notes and cleanup. whisper.cpp doesn't do diarization cleanly. So the `/transcribe` spec should record diarization (+ real-time streaming, domain-term boosting) as the **named reopen-trigger** for a paid lane (Deepgram is the concrete backend; developers.deepgram.com/docs/diarization), with the rule-of-three bar explicit: three real Agent0 transcriptions where local output is unusable specifically for that reason. That converts "paid STT later" from a vague maybe into a falsifiable trigger.

**Counterfactual on our shared position.** The strongest alternative to "local-only `/transcribe` v1" is "ship Deepgram from day one because users expect speaker labels." What would make it win: if the founder's *first* dogfood is a recorded multi-speaker meeting and local output is unusable. I still favor local-only v1 because the demand is hypothesized, not observed — but that's exactly why the named diarization trigger has to be in the spec, so we notice the moment it flips.

Net: nothing here reopens the four locked calls. Two implementation constraints get pinned — (a) `/audio` local-TTS default is conditional on a user-installed-subprocess license posture, audited in that spec; (b) `/transcribe` names diarization as the falsifiable paid-STT reopen-trigger. Recommend the human review and, if these land, graduate to two specs.

Next: human

## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| /transcribe spec names diarization (speaker labels) as the falsifiable paid-STT reopen-trigger (Deepgram backend); bar = three real Agent0 transcriptions unusable locally for that reason | supported | https://developers.deepgram.com/docs/diarization |
| /audio local-TTS default is viable iff engine is user-installed + subprocess-invoked (GPL-via-aggregation, the HyperFrames npx posture), never bundled; the /audio spec must do an explicit dependency-license audit. Not a /transcribe blocker, does not force paid-first | supported | https://github.com/OHF-Voice/piper1-gpl |
| Kokoro has Apache-2.0 weights but routes phonemization through espeak-ng (GPL-3.0) via misaki; GPL implications are an open question (issue 247) | supported | https://github.com/hexgrad/kokoro/issues/247 |
| Piper MIT repo (rhasspy/piper) archived Oct 2025; maintained successor OHF-Voice/piper1-gpl is GPL-3.0 — corrects claude's opening | supported | https://github.com/OHF-Voice/piper1-gpl |
| Two specs, /transcribe first then /audio second; each carries a forward-compat note to avoid two incompatible CLIs | supported | transcript: claude+codex blind openings converged |
| /audio v1 = TTS only; music/SFX deferred as lower-demand paid-only limb with its own reopen-trigger | supported | transcript: claude+codex blind openings converged |
| /transcribe is a local utility (vuln-audit class), NOT a paid-media-family skill: provenance manifest, no tiers oracle / cost-gate / fal queue — reached independently by both models | supported | transcript: claude+codex blind openings converged |
| /transcribe v1 is local-only with whisper.cpp (MIT) as the spine; faster-whisper documented as future adapter, not built | supported | https://github.com/ggml-org/whisper.cpp |
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesized by:** claude (Claude Code). Decision-grade; gated by the 8-row ledger above (`ledger-check`: 0 assertion-only — every convergence point carries an external anchor).

### Convergence (independent — blind-opening round)

Claude and Codex committed sealed openings, revealed only after both were locked, and agreed on all four questions without seeing each other's text. The blind round caught a real defect (claude's Piper-MIT claim) and forced it to an anchor.

1. **Split by direction holds, for an ontological reason, not just symmetry.** `/transcribe` outputs *text* (an input transform); `/audio` outputs a *media asset* (gitignored draft vs tracked, like `/image`). Different output ontologies ⇒ they cannot share one storage/manifest/cost contract.
2. **`/transcribe` is NOT a paid-media-family skill.** It is a local utility in the `vuln-audit.sh` class: `whisper.cpp` (MIT) spine, local-only v1, deterministic, zero inference bill. Its manifest is **provenance** (input hash, duration, engine, model file, language, outputs, "stayed-local") — *not* a cost ledger. No tiers oracle, no cost-gate, no fal queue. `faster-whisper` is documented as the future adapter, not built (avoids dragging Python/CTranslate2/CUDA packaging into the first STT skill).
3. **`/audio` v1 = TTS only.** Local-first spine → paid upgrade (ElevenLabs/fal) behind the existing paid-media discipline (cost print, hard confirm, manifest, redacted stderr, graceful fallback, no auto-fire from downstream skills). **Music/SFX deferred** (paid-only, no light local engine, different acceptance standard) with its own reopen-trigger. Voice clone stays deferred (founder premise).
4. **Two specs, `/transcribe` first** (simpler, higher-demand, mostly local — establishes audio-file handling + output conventions + provenance manifest); `/audio` second, reusing only what survived contact. Each spec carries a short forward-compat note so two incompatible CLIs don't grow.

### Two implementation constraints pinned (the "agreement still hiding work")

- **A — `/audio` local-TTS default is license-conditional.** Neither viable local engine is GPL-clean: Piper's maintained successor (`OHF-Voice/piper1-gpl`) is **GPL-3.0**; Kokoro's Apache-2.0 weights route phonemization through **espeak-ng (GPL-3.0)** via misaki (open issue hexgrad/kokoro#247). This is **not** the XTTS/Coqui case (that was a *model license* forbidding commercial use). GPL on a CLI you shell out to is *aggregation* — the exact posture Agent0 already ships for HyperFrames (`npx`, user-fetched, never bundled). **Resolution:** local TTS may remain the default **iff** user-installed + subprocess-invoked, never vendored/bundled into the consumer repo, with an explicit one-paragraph license posture. The `/audio` spec's first task is that dependency-license audit (Kokoro+espeak-ng vs Piper-GPL vs paid-only). It does **not** force paid-first and does **not** block `/transcribe`.
- **B — `/transcribe` names a falsifiable paid-STT reopen-trigger.** The most predictable first real demand is multi-speaker audio needing **diarization** (speaker labels), which `whisper.cpp` doesn't do cleanly. The spec records diarization (+ real-time streaming, domain-term boosting) as the named reopen-trigger for a paid lane (Deepgram backend), bar = **three** real Agent0 transcriptions unusable locally for that specific reason. Converts "paid STT later" into a rule-of-three gate.

### Minority report

No residual cross-model objection — both models converged. The single preserved dissent is **internal to the shared position, surfaced as each model's own strongest counterfactual:** the "local-only `/transcribe` v1" call is hypothesized demand, not observed. If the founder's *first* `/transcribe` dogfood is a recorded multi-speaker meeting and local output is unusable for lack of diarization, constraint B's trigger fires immediately and the paid lane is justified far sooner than v1 assumes. This is logged, not smoothed away — the named diarization trigger exists precisely so the flip is noticed.

### Recommended next step — GRADUATE (two specs)

Graduate to `/sdd refine` as seed context (does not bypass the interview):
1. **`/transcribe` first** — local-only `whisper.cpp`; transcript formats (txt/srt/vtt/json) if cheap; provenance manifest; no cost apparatus; diarization named as the paid-STT reopen-trigger; forward-compat note for `/audio`.
2. **`/audio` second** — TTS-only; opens with the dependency-license audit (local default conditional on user-installed-subprocess posture); paid ElevenLabs/fal TTS behind the paid-media discipline; music/SFX + clone deferred with reopen-triggers.

Link this `meeting.md` from each spec's `## Context / references`.
