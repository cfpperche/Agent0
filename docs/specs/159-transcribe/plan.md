# 159 — transcribe — plan

_Drafted from `spec.md` on 2026-06-06. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build `/transcribe` as a faithful clone of the **`vuln-audit` dual shape**: a thin `.agent0/skills/transcribe/SKILL.md` (Claude Code entry, agentskills.io-compliant, runtime-agnostic tier) over a single runtime-neutral engine `.agent0/tools/transcribe.sh` that does all the work, so Codex CLI / CI invoke the exact same path. The engine is a deterministic pipeline: **detect → auto-acquire (engine + model + ffmpeg, maximally invisibly) → transcode → transcribe (whisper.cpp) → write native formats → append provenance** — with a `result status` (`ok` / `unavailable` / `error`) reported **distinctly from the process exit code** (vuln-audit's load-bearing pattern: it reports, never blocks).

The one genuinely researched decision is **engine acquisition**, and the honest answer is a **deterministic ladder**, macOS/Linux-first (consistent with Agent0's bash-hook harness already being POSIX-first; Windows-native is best-effort, documented, not the auto path in v1):

1. **Already present** — a `whisper-cli`/`whisper`/`main` binary on `PATH` or in the project's gitignored engine cache → use it (zero acquisition).
2. **`uvx`/`uv` present** — run the prebuilt-wheel CLI **`whisper.cpp-cli`** (Astral/Charlie Marsh; pip wheels bundle the actual compiled CLI for macOS+Linux, **no compiler needed**) via `uvx`, cached. This is the primary invisible path.
3. **`pipx` / `pip --user` present** — install `whisper.cpp-cli` to a cached venv.
4. **`brew` present (macOS)** — `brew install whisper-cpp` (formula exists).
5. **Build from source** — only if a C/C++ toolchain + the repo are fetchable; last resort because compile time on first run is not "invisible".
6. **None possible** — `unavailable` + a single-line actionable hint (uv is itself a one-line curl install), never a crash.

Models are fetched on first use from the canonical HF repo `ggerganov/whisper.cpp` (default `ggml-base.bin`, ~142 MiB) into a gitignored cache; ffmpeg follows the same detect-then-acquire stance (it's already a `/video` dependency). Build order: scaffold-compliant skill → engine core (parse/caps/doctor first, then acquire/transcode/transcribe/write/manifest) → offline tests with a fake-bin stub → harness wiring (doctor, gitignore, CLAUDE/AGENTS index, rule) → validate → real dogfood (audio + video).

## Files to touch

**Create:**
- `.agent0/skills/transcribe/SKILL.md` — skill entry; scaffold via `/skill new transcribe --tier runtime-agnostic` so frontmatter is compliant by construction. Documents the surface: `/transcribe <file> [--format ...] [--model base] [--lang auto] [--output <dir>] [--quiet]`, plus `doctor`/`caps`. Thin — delegates to the tool.
- `.agent0/tools/transcribe.sh` — the engine. Subcommands `transcribe` (default) / `doctor` / `caps`. Owns: arg parse; the acquisition ladder above; ffmpeg transcode-to-16kHz-WAV for audio+video inputs; whisper invocation with native `-o*` format passthrough (`txt,srt,vtt,json,json-full,csv,lrc`; `-owts` excluded); output to the gitignored transcripts dir + `txt` stdout echo (`--quiet` suppresses); cumulative JSONL manifest append (success AND failure); `result status` decoupled from exit code.
- `.agent0/context/rules/transcribe.md` — capacity rule (sibling of `vuln-audit.md`/`image-gen.md`): on-demand-only, single-engine, local-first, the paid-STT/diarization reopen-trigger, the `stayed_local` privacy contract, the `/audio` forward-compat note. This is the **propagation vehicle** to consumers.
- `.agent0/tests/transcribe/` — offline smoke suite with a **fake whisper-cli + fake ffmpeg stub** (the visual-contract/vuln-audit fake-bin pattern): per-format "file exists + minimal parse" tests, the `unavailable` degrade path, manifest-line shape, exit-code-vs-status decoupling, `--quiet`. No network / no real model in CI.
- Symlinks `.claude/skills/transcribe` + `.agents/skills/transcribe` → `../../.agent0/skills/transcribe` (created by `/skill new`).

**Modify:**
- `.agent0/tools/doctor.sh` — add a tri-state check for the whisper engine / ffmpeg / default-model cache (reuse `_brief-compose.sh` conventions; never fail the harness on absence).
- `.gitignore` — the dedicated transcripts dir (candidate `assets/transcripts/`), the manifest (candidate `assets/generated/.transcribe-manifest.jsonl`), and the engine+model cache dir.
- `CLAUDE.md` + `AGENTS.md` — add a `## Transcribe` managed-index block (parity, both runtimes).
- `.agent0/harness-sync-baseline.json` — regenerated so the new files propagate to consumers (the skill is consumer-facing; picked up on next `sync-harness.sh --apply`).

**Delete:** none.

## Alternatives considered

### Build-from-source as the primary acquisition channel

Rejected as primary. It is the most universal (any platform with a compiler) but the **least invisible** — a first-run `cmake`/`make` costs tens of seconds to minutes and assumes a toolchain. It survives only as the last ladder rung before `unavailable`, not the default.

### `pywhispercpp` (Python binding) as the engine interface

Rejected as the interface. It has the broadest wheel coverage, but it is a Python **binding** requiring a Python entry script — pulling the skill toward a standing Python/runtime dependency, the exact pattern the meeting deferred `faster-whisper` to avoid for the *first* STT skill. The CLI-wheel (`whisper.cpp-cli`) or a native binary preserves the pure shell-tool shape. `pywhispercpp` is acceptable only as a deep fallback rung, never the contract.

### Vendoring / bundling a whisper.cpp binary into the repo

Rejected. Platform-specific, bloats the harness, "binary in git" smell, and fights harness propagation — and it contradicts the meeting's explicit "never bundle; user-installed + invoked" posture (the HyperFrames `npx` aggregation model).

### One combined `/audio` + `/transcribe` tool

Rejected — meeting decision (`audio-transcribe-media-family-skills-…`): synthesis and recognition have different output ontologies (media asset vs text transform); one CLI cannot give both a coherent contract.

## Risks and unknowns

- **Cross-platform acquisition is genuinely messy.** `whisper.cpp-cli` wheels are macOS/Linux only; Windows-native auto-acquisition is best-effort (official `whisper-bin-x64.zip`), documented but not in the v1 auto ladder. Consistent with Agent0's POSIX-first harness, but must be stated honestly in the rule.
- **"Invisible" first run is still not instant.** A first `/transcribe` pays a one-time engine fetch (uvx/pip) + a ~142 MiB model download. The engine must emit a clear "first-run setup…" signal so it is not perceived as a hang, and the manifest should mark the run.
- **Exact console-script entrypoints** for `whisper.cpp-cli` / `pywhispercpp` need impl-time verification (binary name, flag parity with upstream `whisper-cli`). The `-o*` flag set and `-ojf`/`--dtw` behavior were confirmed via the Codex consult but pin them against the actually-acquired build.
- **ffmpeg is a second invisible-acquisition target** (same ladder, smaller). Most dev machines already have it; the degrade path must still be clean.
- **Offline test fidelity** — the fake-bin stub proves wiring/contract but not real transcription quality; real e2e lives only in dogfood (needs network + model + a sample audio/video).
- **FS-location reconciliation** with `/image`/`/video` `assets/` conventions and the future `/audio` skill (the forward-compat note) — picked here as candidates, finalize at impl.

## Research / citations

- whisper.cpp project + releases (prebuilt binaries, model README): https://github.com/ggml-org/whisper.cpp · https://github.com/ggml-org/whisper.cpp/releases
- `whisper.cpp-cli` — prebuilt pip wheels of the CLI for macOS/Linux (Astral/Charlie Marsh): https://github.com/charliermarsh/whisper.cpp-cli · https://pypi.org/project/whisper.cpp-cli/
- `pywhispercpp` — multi-platform Python-binding wheels: https://pypi.org/project/pywhispercpp/
- Model weights host: https://huggingface.co/ggerganov/whisper.cpp
- Output-format + default-model second opinion (Codex consult, this session): `.agent0/.runtime-state/codex-exec/20260606T173205Z-transcribe-output-formats/last-message.md`
- Architectural model: `docs/specs/120-vuln-audit/` + `.agent0/context/rules/vuln-audit.md`
- Graduating meeting: `.agent0/meetings/audio-transcribe-media-family-skills-2026-06-06T17-01-43Z/meeting.md`
