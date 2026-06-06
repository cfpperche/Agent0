# 159 — transcribe — tasks

_Generated from `plan.md` on 2026-06-06. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Engine skeleton** — `.agent0/tools/transcribe.sh`: shebang, header doc (usage + statuses), `set -uo pipefail`, arg parse (`<file>`, `--format`, `--model`, `--lang`, `--output`, `--quiet`, `--json`, `--exit-code`, subcommands `doctor`/`caps`/`--help`). Env overrides for tests (`TRANSCRIBE_WHISPER_BIN`, `TRANSCRIBE_FFMPEG_BIN`, `TRANSCRIBE_MODEL_DIR`, `TRANSCRIBE_OUTPUT_DIR`, `TRANSCRIBE_MANIFEST`, `TRANSCRIBE_NO_ACQUIRE`).
- [x] 2. **Capability detection** — `resolve_whisper` (env → PATH names `whisper-cli|whisper-cpp|whisper|main` → cache → uvx ladder), `resolve_ffmpeg`, `resolve_model` (cache file `ggml-<model>.bin` → curl from HF if absent). `caps` (JSON) + `doctor` (human tri-state) print what's detected + available acquisition channels.
- [x] 3. **Acquisition ladder** — auto path = `uvx --from whisper.cpp-cli` (ephemeral, safe); else `unavailable` + one-line hint (brew/uv install). Overridable package/script via env. Never a destructive auto-install.
- [x] 4. **Transcode** — `ffmpeg -i <in> -ar 16000 -ac 1 -c:a pcm_s16le <tmp.wav>` for any audio OR video input; `unavailable` if ffmpeg absent and input not already 16k WAV.
- [x] 5. **Transcribe + format passthrough** — invoke whisper with `-m model -f wav -l <lang|auto> -of <prefix>` + the `-o*` flags for each requested format in `txt,srt,vtt,json,json-full,csv,lrc` (`-owts` excluded). Default `txt`. Outputs land in the gitignored transcripts dir.
- [x] 6. **Output + stdout echo** — echo `txt` content to stdout unless `--quiet`; report written file paths.
- [x] 7. **Provenance manifest** — append one JSONL line (success AND failure) to the gitignored manifest: `ts, status, input, input_sha256, duration, engine, model, lang, outputs[], stayed_local`.
- [x] 8. **Status / exit decoupling** — result status `ok|unavailable|error` always exit 0 by default; `--exit-code` maps `ok=0|unavailable=2|error=3` (vuln-audit pattern).
- [x] 9. **SKILL.md** — `.agent0/skills/transcribe/SKILL.md`, agentskills.io-compliant frontmatter, `agent0-portability-tier: runtime-agnostic` (or agentskills-portable to match vuln-audit), thin wrapper doc. Create `.claude/skills/transcribe` + `.agents/skills/transcribe` symlinks.
- [x] 10. **Capacity rule** — `.agent0/context/rules/transcribe.md`: on-demand/local-first, the `stayed_local` privacy contract, diarization paid-STT reopen-trigger, `/audio` forward-compat note, non-goals. Add a `paths:` front-matter trigger block.
- [x] 11. **Offline tests** — `.agent0/tests/transcribe/{_lib.sh,run-all.sh,NN-*.sh}` with fake whisper-cli + fake ffmpeg stubs injected via env. Scenarios: ok+default-txt, multi-format, video input, unavailable degrade, manifest line shape, `--quiet`, `--exit-code` mapping.
- [x] 12. **Harness wiring** — `.gitignore` (transcripts dir, manifest, model/engine cache); `.agent0/tools/doctor.sh` transcribe check (tri-state, never fails harness); `CLAUDE.md` + `AGENTS.md` `## Transcribe` managed-index block (parity).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] `bash .agent0/tests/transcribe/run-all.sh` green (covers: ok+formats thin-contract, video extract, unavailable honest-degrade, manifest shape, stdout/`--quiet`, exit-code decoupling) → maps to spec scenarios 1–4 + static facts.
- [x] `/skill validate transcribe` exits 0 (agentskills.io compliance).
- [x] `bash .agent0/tools/doctor.sh` reports the transcribe check tri-state and stays exit-0 when the engine is absent.
- [x] **Joint dogfood** (with the founder): real `/transcribe` of an actual audio file + a video file — proves auto-acquisition (uvx/whisper.cpp-cli), the `base` model fetch, transcript output, the `stayed_local` manifest line, and the "audio never leaves the machine" claim. Maps to spec scenarios 1, 2, 5.

## Notes

- The `whisper.cpp-cli` console-script entrypoint name is verified during the dogfood, not hard-coded — `resolve_whisper` tries several names and the uvx package/script are env-overridable, so a wrong guess never blocks.
- Offline tests prove wiring + contract only; real transcription quality is a dogfood concern (needs network + model + sample media).
- `json-full` ships as raw native JSON; per-token timestamps (`--dtw`) are explicitly NOT promised in v1 (the one real-cost format — see spec Non-goals).
