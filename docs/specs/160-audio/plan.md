# 160 — audio — plan

_Drafted from `spec.md` on 2026-06-06. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Clone the `/transcribe` dual shape: thin `.agent0/skills/audio/SKILL.md` over a runtime-neutral `.agent0/tools/audio.sh` engine that does everything (detect → auto-acquire → synthesize → encode → output → hybrid manifest), with result status (`ok|unavailable|error`) decoupled from exit code. The one researched decision is **per-engine acquisition + interface**, and the research surfaced an asymmetry the spec flagged: the quality default (Kokoro) is the *less* self-contained engine.

**Local lane — two engines, asymmetric acquisition (honest):**
- **Piper** (`--engine piper`) — `pip install piper-tts` ships a native `piper` CLI and **embeds espeak-ng phonemization** (piper-phonemize); voices are self-contained ONNX from HF `rhasspy/piper`. Fully `uvx`-able: `uvx --from piper-tts piper …`, voice fetched to a gitignored cache on first use. The *more* invisible engine.
- **Kokoro** (zero-flag default) — `pip install kokoro soundfile` is a **library, not a CLI**, and phonemization needs **espeak-ng as a system binary** (`apt-get install espeak-ng` / `brew install espeak-ng`), which `uvx` cannot provide. Two consequences: (1) invoke it via a tiny **first-party shim** `.agent0/tools/audio-kokoro.py` (a few lines of `KPipeline` → WAV) run through `uvx --with kokoro --with soundfile python <shim>` — we do NOT depend on an un-vetted third-party Kokoro CLI; (2) if `espeak-ng` is absent, acquisition degrades to a one-line `apt/brew install espeak-ng` hint (status `unavailable`), NOT a crash. Kokoro stays the quality/multilingual (pt-BR) default per the founder; the acquisition asymmetry is documented, and Piper is the more-self-contained alternative.

**Paid lane (`--remote`):** reuse `fal-rest.sh`; tier→model from a date-stamped `audio-tiers.yaml` (no model IDs in code, mirrors `video-tiers.yaml`). The paid tiers offer what local **can't** — ElevenLabs expressiveness — not paid-Kokoro (local already gives Kokoro free). Seed: `standard` → ElevenLabs Turbo v2.5 (~$0.05/1k chars), `premium` → ElevenLabs v3 (~$0.10/1k chars, 70+ langs). Cost = `ceil(chars/1000) × rate`, **printed before** the call (image-style, no hard gate).

**Output + manifest:** WAV from the engine → `--format mp3` (default) encodes via ffmpeg (already a dep), `wav` passes through. Two classes (mirrors `/image`): draft (gitignored) default vs `--asset` (tracked). Hybrid JSONL manifest: provenance for local (`stayed_local:true`) + cost for paid (`stayed_local:false`).

Build order: engine skeleton (parse/caps/doctor) → Piper lane (clean CLI, prove the pipeline) → Kokoro shim + espeak-ng degrade → output classes + ffmpeg encode + hybrid manifest → paid fal lane + tiers.yaml + cost-print → offline tests (fake `piper`, fake kokoro-shim, fake fal) → harness wiring → validate → dogfood (local Kokoro pt-BR + Piper EN + one paid call).

## Files to touch

**Create:**
- `.agent0/skills/audio/SKILL.md` — skill entry; scaffold via `/skill new audio --tier agentskills-portable`. Surface: `/audio "<text>" [--engine kokoro|piper] [--remote] [--asset] [--voice <name>] [--lang <code>] [--format mp3|wav] [--json] [--exit-code]` + `doctor`/`caps`.
- `.agent0/tools/audio.sh` — the engine. Owns: arg parse; per-engine resolve+acquire ladder (Piper uvx CLI / Kokoro uvx+shim with espeak-ng detect-or-hint); WAV synthesis; ffmpeg mp3 encode; two output classes; paid lane via `fal-rest.sh` + cost-print; hybrid manifest; status/exit decoupling.
- `.agent0/tools/audio-kokoro.py` — tiny first-party Kokoro shim (`KPipeline` → WAV at a given path/voice/lang); the only Python in the tool, invoked via uvx. Pin `kokoro` version (pre-1.0 API drift).
- `.agent0/skills/audio/references/audio-tiers.yaml` — date-stamped paid tier→fal-model oracle (seed: ElevenLabs Turbo v2.5 / v3), refresh discipline mirroring `video-tiers.yaml`.
- `.agent0/context/rules/audio.md` — capacity rule (propagation vehicle): local-first two-engine, the espeak-ng acquisition asymmetry, the paid-offers-what-local-can't framing, `stayed_local` honesty per lane, music/SFX + clone reopen-triggers, `/transcribe` forward-compat.
- `.agent0/tests/audio/` — offline suite (fake `piper`, fake kokoro-shim, fake `fal-rest.sh`/curl): local-ok (both engines), engine switch, paid cost-print + manifest cost fields, two output classes, unavailable degrade (incl. Kokoro-no-espeak-ng), `--quiet`/`--exit-code`.
- Symlinks `.claude/skills/audio` + `.agents/skills/audio`.

**Modify:**
- `.agent0/tools/doctor.sh` — audio check: engine(s) + espeak-ng + ffmpeg + voice cache (tri-state, never fails harness).
- `.gitignore` — draft audio dir (`assets/generated/audio/*`), manifest (`assets/generated/.audio-manifest.jsonl`), cache (`.agent0/.runtime-state/audio/`); tracked asset dir (`assets/audio/`) gets a `.gitkeep`.
- `CLAUDE.md` + `AGENTS.md` — `## Audio` managed-index block (parity).
- `.agent0/harness-sync-baseline.json` — regenerated (new files propagate to consumers).

**Delete:** none.

## Alternatives considered

### Piper as the zero-flag default (more invisible)

Rejected as default (kept as first-class alternative). Piper acquires more cleanly (self-contained `piper` CLI, embedded phonemization), so it would be the "easier invisible" default. But it is English-heavy (904 EN voices) and the founder explicitly chose Kokoro for multilingual/pt-BR + quality. We take the harder acquisition for the better default, and document the asymmetry honestly — Piper is the fallback when Kokoro's espeak-ng dep can't be met.

### A third-party Kokoro CLI (e.g. `kokoro-tts`)

Rejected. Several community CLIs wrap Kokoro, but depending on an un-vetted, separately-versioned CLI is a second discovery surface (the same reasoning that made `/video` ship its own HyperFrames composition rather than the upstream agent-skill). A ~10-line first-party `audio-kokoro.py` shim over the official `kokoro` package is smaller, vetted, and version-pinnable.

### Paid lane offering paid-Kokoro-on-fal

Rejected. fal hosts Kokoro at $0.02/1k, but the local lane already gives Kokoro **free**. Paying for it adds nothing; the paid lane's job is to offer what local can't — ElevenLabs expressiveness/70+-langs. Tiers seed ElevenLabs only.

### ElevenLabs-direct integration

Rejected (deferred). fal already fronts ElevenLabs, so `--remote` reuses `fal-rest.sh` rather than integrating a second provider's REST/key. ElevenLabs-direct stays a documented future if fal's fronting proves limiting.

## Risks and unknowns

- **Kokoro auto-acquisition is not fully invisible** (the headline risk): espeak-ng is a system binary `uvx` can't install, so first run on a bare system degrades to an install hint. Mitigated by honest `unavailable` + hint, and Piper as the self-contained fallback. (If this friction bites in dogfood, reconsider Piper-default.)
- **Kokoro shim couples to the pre-1.0 `kokoro` package API** (`KPipeline`); pin the version, expect occasional drift.
- **Two engines** = two acquisition ladders + two default voices + roughly double the test surface (the founder's accepted "both co-default" cost).
- **fal TTS endpoint IDs / prices drift** — `audio-tiers.yaml` refresh discipline + a staleness advisory (mirror `video-tiers.yaml`).
- **mp3 encode** assumes ffmpeg present (already a `/video`/`/transcribe` dep); `wav` passthrough is the no-ffmpeg fallback.
- **Default voice ids** — pick a grade-A Kokoro voice (e.g. an `af_*`/`pf_*` for pt) + a Piper default per language; finalize at impl against the actually-acquired packages.

## Research / citations

- Piper: https://github.com/OHF-Voice/piper1-gpl · https://pypi.org/project/piper-tts/ (embeds espeak-ng phonemization; `piper` CLI; HF `rhasspy/piper` voices)
- Kokoro: https://pypi.org/project/kokoro/ (library + `pip install kokoro soundfile`; espeak-ng system dep — `apt-get install espeak-ng` / `brew install espeak-ng`) · https://github.com/hexgrad/kokoro · GPL phonemizer issue hexgrad/kokoro#247
- fal TTS pricing/endpoints: https://fal.ai/models/fal-ai/elevenlabs/tts/eleven-v3 · https://fal.ai/models/fal-ai/kokoro/american-english (Kokoro $0.02/1k; ElevenLabs Turbo v2.5 ~$0.05/1k; ElevenLabs v3 ~$0.10/1k)
- Reused infra: `.agent0/tools/fal-rest.sh`; patterns from `.agent0/context/rules/{image-gen,video-gen,transcribe}.md`
- Graduating meeting: `.agent0/meetings/audio-transcribe-media-family-skills-2026-06-06T17-01-43Z/meeting.md`
- Sibling shipped spec: `docs/specs/159-transcribe/`
