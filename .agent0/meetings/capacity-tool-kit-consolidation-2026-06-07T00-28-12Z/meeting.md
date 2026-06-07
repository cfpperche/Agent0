---
meeting: capacity-tool-kit-consolidation
topic: "Should Agent0 extract the duplicated capacity-tool plumbing into a shared lib/ kit (kernel + paid-media + local-utility sub-kits), now that 6 capacity tools (image/video/audio/sound/transcribe/diagram) re-implement the same shape? Measured duplication: emit_exit() in 5 tools, append_manifest() in 4, fail() in 4, have()/resolve_ffmpeg()/yaml-oracle-reader duplicated; precedent lib/managed-block.sh exists. Evidence of harm: two plumbing bugs (FAL_KEY leak in /audio doctor; pretty-vs-compact JSON in /sound) were skeleton bugs a once-tested kit would have prevented in both. Counter-force: self-contained .sh has real value (runtime-neutral, Codex/CI call directly, harness-sync portability, readability); a lib/ is a coupling point + more sync-managed files; paid vs local are genuinely different (avoid false unification). Decide: (1) extract now, defer as a reopen-trigger 'before the 7th tool', or skip? (2) the right shape — kernel-only vs kernel+2 sub-kits vs more; what is byte-identical-safe to extract vs must stay in the tool? (3) behavior-preservation contract: zero behavior change, all 6 offline suites pass identical after (test-protected refactor)? (4) the over-abstraction risk — how to scope so the kit doesn't force false unification or hurt readability/portability. Apply spec-149: blind openings, claim/evidence ledger, minority report."
created: 2026-06-07T00:28:12Z
convener: claude
mode: human-orchestrated
roster: claude,codex
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 3
next_speaker: claude
synthesis: accepted
---

# Meeting: Should Agent0 extract the duplicated capacity-tool plumbing into a shared lib/ kit (kernel + paid-media + local-utility sub-kits), now that 6 capacity tools (image/video/audio/sound/transcribe/diagram) re-implement the same shape? Measured duplication: emit_exit() in 5 tools, append_manifest() in 4, fail() in 4, have()/resolve_ffmpeg()/yaml-oracle-reader duplicated; precedent lib/managed-block.sh exists. Evidence of harm: two plumbing bugs (FAL_KEY leak in /audio doctor; pretty-vs-compact JSON in /sound) were skeleton bugs a once-tested kit would have prevented in both. Counter-force: self-contained .sh has real value (runtime-neutral, Codex/CI call directly, harness-sync portability, readability); a lib/ is a coupling point + more sync-managed files; paid vs local are genuinely different (avoid false unification). Decide: (1) extract now, defer as a reopen-trigger 'before the 7th tool', or skip? (2) the right shape — kernel-only vs kernel+2 sub-kits vs more; what is byte-identical-safe to extract vs must stay in the tool? (3) behavior-preservation contract: zero behavior change, all 6 offline suites pass identical after (test-protected refactor)? (4) the over-abstraction risk — how to scope so the kit doesn't force false unification or hurt readability/portability. Apply spec-149: blind openings, claim/evidence ledger, minority report.

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:6f8ba89b87c5ab71` (3552 bytes)
- commit codex — `sha256:ca63690a54dc4486` (2579 bytes)

### Turn 1 — claude (blind opening) (claude)

**Position (claude).** Extract now, test-protected, scoped to the proven-identical kernel + two thin sub-kits — but first *measure* the truly byte-identical surface, because the honest kill-risk is "the savings are too small to justify a new coupling point," and if so the answer is a template, not a library.

**(1) Timing — extract NOW, not "before the 7th."** Rule-of-three is exceeded (emit_exit ×5, append_manifest ×4, fail ×4). The two plumbing bugs (FAL_KEY leak in /audio doctor, pretty-vs-compact JSON in /sound) are concrete evidence of harm — skeleton bugs a once-tested kit prevents in all instances. Decisive factor: the 6 offline suites exist *now* as the safety net, and the duplication is fresh. "Defer to the 7th" risks the 7th being built as clone #7 before the trigger fires. Doing it now means the 7th is born from a proven kit.

**(2) Shape — kernel + 2 sub-kits, extract ONLY byte-identical plumbing.** Kernel (all 6): `cap_have`, `cap_sha256_*`, `cap_emit_exit` (status→exit ok=0/unavail=2/err=3), `cap_std_flags` (the --json/--exit-code/doctor/caps parse). Paid sub-kit (image/video/sound/audio-remote): the YAML tier-oracle reader (yget/ytop), cost-print, confirm-gate. Local sub-kit (transcribe/audio/diagram): the uvx/npx acquire-ladder + provenance-manifest envelope. **Tool-specific logic STAYS in the tool** (engine invocation, request-body build, arg semantics, manifest *fields*). Do NOT unify paid+local into one mold.

**(3) The sharpest design question — the `fail()` ↔ `append_manifest()` coupling.** `fail()` is byte-identical in shape but calls `append_manifest()`, which is NOT identical — each tool's manifest carries different *fields* (audio: engine/voice/lang; sound: kind/tier/cost; diagram: source/format). So `append_manifest` can't be one function; the shareable part is the *mechanics* (mkdir, `jq -cn` guard, one-line-per-call append, the `{ts,status,...}` envelope) while the caller supplies the fields. And `fail` must either take a manifest hook/callback or the envelope must be standardized enough that fail owns it. Resolving this cleanly is the whole ballgame — get it wrong and you've coupled 6 tools to a leaky abstraction.

**(4) Behavior-preservation = the hard contract + the over-abstraction guard.** Zero behavior change: all 6 offline suites must pass **byte-identical** after (run before+after, diff clean). This is a pure, test-protected refactor — if any suite output changes, the extraction is wrong. Over-abstraction guard: extract only what ≥3 tools use *verbatim*; the lib is **helpers, not a framework** — each tool still owns its own main control flow and stays independently readable. Keep the lib small + flat (no dispatch/inheritance magic). It becomes a sync-managed file like the existing `lib/managed-block.sh` (precedent — acceptable).

**Kill-risk to pressure-test (Codex, push here):** if the *genuinely byte-identical* surface turns out tiny (emit_exit + have ≈ a dozen lines) and everything else is "same shape, different content," then a sourced `lib/` buys little and adds a coupling point + sync surface for ~real cost. In that world the right move is a **documented reference skeleton / template in the rule** (template-over-library), not extraction. So the build's first task is to *measure the byte-identical extractable surface per function* and gate the whole refactor on it clearing a threshold (say, >~80 lines saved net across the 6, or it stays a template). I lean extract-now, but only if the measurement holds.

Next: codex


### Turn 2 — codex (blind opening) (codex)

Position: extract NOW, but narrowly. This is no longer theoretical DRY pressure: the shared skeleton already produced shipped bugs, and the repo already accepts sourced harness libs via `.agent0/tools/lib/managed-block.sh`, sourced by `sync-harness.sh` and sync-listed explicitly.

1. Timing: NOW, as a refactor-only spec before any 7th capacity tool. The duplicated invariant surface is visible in `.agent0/tools/audio.sh:131-147`, `.agent0/tools/sound.sh:110-127`, `.agent0/tools/transcribe.sh:191-236`, and `.agent0/tools/diagram.sh:125-138`: manifest append, `ok|unavailable|error`, `--exit-code`, and failure output. Deferring means the next tool will copy the same skeleton again.

2. Shape: kernel + small paid-media sub-kit, but not a full local-utility sub-kit yet.
Extract safely:
- `have`, hash helpers, secret state redaction (`set|unset`, never value)
- `status -> exit` mapping
- compact JSONL append helper so manifests are always one line
- `resolve_ffmpeg <override-env>`
- fixed YAML scalar/tier-field readers, parameterized for `tiers:` nesting
- paid helper around `FAL_KEY` presence, cost confirmation, and `fal-rest.sh` invocation

Keep in each tool:
- argument parsing and user-facing wording
- `doctor`/`caps` domain fields
- manifest record schema
- acquisition ladders: Kokoro/Piper, whisper.cpp, Mermaid/npx/Chrome differ materially
- fal body and response paths, except where the YAML oracle owns them
- storage policy: image draft/brand, video ledger, sound taste-judge, diagram keepers, transcribe transcripts

3. Behavior contract: “all 6 offline suites pass” is necessary, not sufficient. Add a golden refactor gate: same stdout/stderr/exit for stable fixture cases, JSON semantic equality for `--json`, compact one-line manifest entries, and same `--exit-code` mapping. Normalize timestamps/temp paths. Also run `bash -n`, relevant `run-all.sh` suites, `doctor.sh`, and `/skill validate` for touched skills. Add a harness-sync test: current `.agent0/tools|*.sh` glob misses `.agent0/tools/lib/*.sh` except the literal managed-block entry.

4. Over-abstraction risk: do not build a generic “capacity runner.” Source a small bash kit by relative path, fail clearly if missing, and leave each `.sh` readable as the domain contract. A documented skeleton still beats a library for future local acquisition flows, because those flows are policy-heavy and not byte-identical. But for exit semantics, compact JSONL, secret redaction, ffmpeg resolution, and tier field reads, a tested library is better than another pasted template.

Next: claude
## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| Library-vs-template decision must be GATED on a first-task MEASUREMENT of the per-function byte-identical surface; if the genuinely-identical kernel is tiny, prefer a documented template over a sourced lib. | unresolved | test:measure-byte-identical-surface |
| Over-abstraction guard: a small bash kit sourced by relative path that fails clearly if missing; each .sh stays readable as its own domain contract — NOT a generic capacity-runner/framework. | supported | path:.agent0/tools/lib/managed-block.sh |
| Behavior-preservation: 'all 6 offline suites pass' is necessary but NOT sufficient — add a golden refactor gate (stdout/stderr/exit parity on fixtures, JSON semantic equality for --json, compact one-line manifest, identical --exit-code mapping, normalized timestamps/temp paths) + bash -n + doctor + /skill validate. | unresolved | test:golden-refactor-gate |
| Harness-sync gap is REAL and load-bearing: .agent0/tools/*.sh is a maxdepth-1 glob (sync-harness.sh:197) that does NOT recurse into lib/; managed-block.sh syncs only as a literal (line 211). A new lib/ MUST be added to sync or every consumer's 6 tools break when they source a lib that did not propagate. | supported | path:.agent0/tools/sync-harness.sh |
| Shape = kernel + a small PAID-media sub-kit only; the local-utility acquisition flows (Kokoro/Piper vs whisper.cpp vs Mermaid/npx/Chrome) are policy-heavy and NOT byte-identical, so they stay a documented TEMPLATE, not a library (codex refinement; claude adopts, narrowing from the 2-sub-kit opening). | supported | path:.agent0/tools/transcribe.sh |
| Extract NOW as a refactor-only spec before any 7th capacity tool — both runtimes converged independently; rule-of-three exceeded (emit_exit ×5, append_manifest/fail/have ×4) + two shipped skeleton bugs as harm evidence + the accepted lib/managed-block.sh precedent. | supported | path:.agent0/tools/lib/managed-block.sh |

### Turn 3 — Claude Code (claude)

We converged independently on the spine: extract now, refactor-only, before the 7th tool; kernel + paid sub-kit; small sourced kit not a framework; behavior-preservation as the gate; template-beats-library for the policy-heavy parts. Three of codex's points are sharper than mine — I adopt all three and concede the one real divergence.

**Adopt 1 — the local sub-kit is a TEMPLATE, not a library (concede the divergence).** My opening proposed kernel + *two* sub-kits. Codex is right: the local acquisition flows are not byte-identical — `uvx --with kokoro` (audio) vs `uvx --from whisper.cpp-cli` (transcribe) vs `npx -p @mermaid-js/mermaid-cli mmdc` + system-Chrome (diagram) share only the *shape* "try, degrade to hint," not code. Extracting them would force false unification. So: **kernel + paid sub-kit as a library; local acquisition stays a documented reference skeleton.** The one local thing that IS byte-identical mechanics — the provenance-manifest append + status/exit + redaction — lives in the kernel, used by local and paid alike. Clean line.

**Adopt 2 — golden refactor gate (suites necessary, not sufficient).** Right and important. The offline suites assert *behaviors we thought to test*; a refactor can drift something untested. So the gate is: capture each tool's stdout/stderr/exit on a fixed fixture set BEFORE, run the same AFTER, diff must be clean (normalize timestamps + temp paths); JSON semantic-equality for `--json`; compact one-line manifest preserved; identical `--exit-code` mapping. Plus `bash -n`, every `run-all.sh`, `doctor.sh`, `/skill validate`. This is what makes "extract now" genuinely low-risk.

**Adopt 3 — the harness-sync gap is the load-bearing wiring fix (verified).** Confirmed: `.agent0/tools|*.sh` is maxdepth-1 (`sync-harness.sh:197`); `lib/managed-block.sh` syncs only as a literal (`:211`). Consequence is severe — once the 6 tools `source lib/capacity.sh`, a sync miss means **every consumer's tools break** (sourcing a file that didn't propagate). So the spec MUST add `.agent0/tools/lib|*.sh` as a glob (or list each lib literal) AND ship a harness-sync test proving the lib propagates. This raises the blast radius, which is itself the argument for the golden gate.

**The one thing I'll hold firm on — measure FIRST, library-vs-template is per-function and gated.** Both our openings hand-wave "extract the identical surface"; my crude awk measurement just now over-counted (it couldn't cleanly bound function bodies), which proves the point: the build's **task #1 is a real per-function byte-identity measurement** of `emit_exit`/`have`/hash/manifest-mechanics/`resolve_ffmpeg`/tier-reader across the tools. Each function clears the bar (≥3 verbatim users, non-trivial size) → kernel/sub-kit; else → template. If the net kernel is tiny, we ship a template and stop. I lean library (the bugs + the precedent argue for it), but the measurement is the gate, not our intuition.

Net: kernel(`have`/hash/`emit_exit`/`fail`-with-manifest-hook/compact-JSONL-append/secret-redaction/`resolve_ffmpeg`) + paid sub-kit(FAL_KEY-state/cost-confirm/tier-YAML-reader/`fal-rest` wrapper) as a sourced `lib/`; local acquisition = template; gated by measurement → golden parity → sync-propagation test. This is spec-ready. Recommend graduating to `/sdd refine`.

Next: claude

## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesized by:** claude (Claude Code). Decision-grade; convergence rests on the ledger (6 claims, **0 assertion-only**; 4 supported pass `check-anchors`, 2 deliberately-`unresolved` anchored to gates-to-build).

### Convergence (independent — from blind openings)
Both runtimes, blind, agreed on the spine:
- **Extract NOW**, as a **refactor-only** spec, **before any 7th capacity tool.** Rule-of-three exceeded (`emit_exit` ×5, `append_manifest`/`fail`/`have` ×4); two shipped *skeleton* bugs (FAL_KEY leak in `/audio` doctor; pretty-vs-compact JSON in `/sound`) are harm evidence a once-tested kit prevents across all instances; the accepted `lib/managed-block.sh` precedent shows sourced harness libs are an established pattern.
- **Shape = kernel + a small paid-media sub-kit**, as a sourced bash `lib/` (relative path, fails clearly if missing). **Not** a generic "capacity-runner" framework — each `.sh` stays readable as its own domain contract.
- **Template-beats-library for the policy-heavy parts** — extract only the genuinely byte-identical plumbing.
- **Behavior-preservation is the gate** for a pure refactor.

### Resolutions in critique (claude moved to codex on every open point)
- **The local-utility sub-kit is a TEMPLATE, not a library** (claude conceded its 2-sub-kit opening). The local acquisition flows are not byte-identical — `uvx --with kokoro` (audio) vs `uvx --from whisper.cpp-cli` (transcribe) vs `npx -p @mermaid-js/mermaid-cli mmdc` + system-Chrome (diagram) share only the *shape* "try → degrade to hint," not code. Extracting them would force false unification. The byte-identical mechanics they DO share (provenance-manifest append, status/exit, secret redaction) live in the kernel; the acquisition *policy* stays a documented reference skeleton.
- **Golden refactor gate** (codex): "all 6 offline suites pass" is necessary but **not sufficient** — add stdout/stderr/exit parity on a fixed fixture set (before vs after, normalize timestamps/temp paths), JSON semantic-equality for `--json`, compact one-line manifest preserved, identical `--exit-code` mapping; plus `bash -n`, every `run-all.sh`, `doctor.sh`, `/skill validate`.
- **Harness-sync gap is the load-bearing wiring fix** (codex, verified): `.agent0/tools|*.sh` is maxdepth-1 (`sync-harness.sh:197`) and does NOT recurse into `lib/`; `managed-block.sh` syncs only as a literal (`:211`). Once the 6 tools `source lib/capacity.sh`, a sync miss **breaks every consumer's tools** — so the spec MUST add `.agent0/tools/lib|*.sh` (or list each literal) AND ship a harness-sync test proving propagation. The raised blast radius is itself the argument for the golden gate.

### Minority / unresolved (preserved — gates, not agreements)
- **Measure-first (library-vs-template is per-function and gated):** the build's **task #1** is a real per-function byte-identity measurement across the tools (claude's crude awk over-counted — proving intuition is not enough). Each candidate clears the bar (≥3 verbatim users, non-trivial size) → kernel/sub-kit; else → template. If the net kernel is tiny, **ship a template and stop.** Lean is library (bugs + precedent), but the measurement is the gate.
- **Golden gate is unresolved until built** — it is the safety mechanism, not yet an artifact.

### Net v1 design
Kernel (`have`/hash/`emit_exit`/`fail`-with-manifest-hook/compact-JSONL-append/secret-redaction/`resolve_ffmpeg`) + paid sub-kit (FAL_KEY-state/cost-confirm/tier-YAML-reader/`fal-rest` wrapper) as a sourced `lib/`; local acquisition stays a template. Gated by: measure → golden parity → sync-propagation test. Zero behavior change.

### Recommended next step
**Graduate to `/sdd refine`** with this meeting as seed. Sharpest OQs to carry: (a) the `fail()`↔`append_manifest()` coupling (manifest hook/callback vs standardized envelope); (b) the exact sync-glob fix shape (`lib|*.sh` glob vs per-literal) + its test; (c) the golden-gate harness (where fixtures live, how parity is diffed); (d) the measurement threshold that decides library-vs-template per function. **Kill-condition:** if task-1 measurement shows the byte-identical kernel is trivially small, downgrade to a documented template (a reference skeleton in the rule) and close the spec.
