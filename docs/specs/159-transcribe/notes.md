# 159 — transcribe — notes

_Created 2026-06-06._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building**. Append-only by convention._

## Design decisions

### 2026-06-06 — parent — Auto-acquisition = ephemeral `uvx`, not a destructive install

The founder's directive was "maximally invisible". The honest reconciliation: the only genuinely invisible AND safe channel is `uvx --from whisper.cpp-cli` (ephemeral, no compiler, no persistent install, no sudo). Everything heavier (brew install, source build) is a printed one-line hint in the `unavailable` status, not an auto-action. So `/transcribe` never runs a destructive auto-install; it auto-acquires only via the ephemeral uvx path and otherwise degrades to a hint.

### 2026-06-06 — parent — Default language is `-l auto`, not whisper's `-l en`

whisper.cpp's own CLI default is `-l en`. Passing no `-l` would silently assume English and punish non-English audio — contradicting the meeting decision. The engine therefore always passes `-l "${LANG:-auto}"` so the default is genuine auto-detect.

## Deviations

_None — implementation followed plan.md (vuln-audit dual shape, uvx ladder, thin format passthrough)._

## Tradeoffs

### 2026-06-06 — parent — Always transcode via ffmpeg, even for 16k WAV input

Rather than branch on input format/sample-rate, the engine always routes through ffmpeg to a 16 kHz mono WAV (audio AND video uniformly). Cost: a redundant WAV→WAV copy for already-conformant input. Benefit: one code path, no format-sniffing, video "just works". Worth it for simplicity; ffmpeg is cheap and already required for the general case.

## Open questions

### 2026-06-06 — parent — RESOLVED in dogfood — whisper.cpp-cli entrypoint name

`plan.md` flagged the `whisper.cpp-cli` console-script name as impl-verify. The joint dogfood resolved it: the package (`whisper.cpp-cli`, normalized `whisper-cpp-cli`) exposes the executable **`whisper-cpp`**, NOT `whisper-cli` (the initial guess). Default `TRANSCRIBE_UVX_SCRIPT` corrected to `whisper-cpp`; `whisper-cpp --help` confirmed identical flags (`-m -f -of -otxt -osrt -l`). This is exactly why the dogfood is run before committing — the offline fake-bin tests could not have caught it. Dogfood result: jfk.wav → correct transcript in ~4s, txt+srt+json, manifest `stayed_local:true`, model cached (147 MB, gitignored).
