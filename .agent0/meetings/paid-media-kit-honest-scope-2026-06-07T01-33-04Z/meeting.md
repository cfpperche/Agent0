---
meeting: paid-media-kit-honest-scope
topic: "capacity-kit paid-media sub-kit: honest extraction scope after kill-gate measurement"
created: 2026-06-07T01:33:04Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 4
next_speaker: claude
synthesis: accepted
---

# Meeting: capacity-kit paid-media sub-kit: honest extraction scope after kill-gate measurement

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — Carlos (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:98a9ca92e3c6d8c2` (3985 bytes)
- commit codex — `sha256:d989c1f69acac21f` (7297 bytes)

### Turn 1 — claude (blind opening) (claude)

**Position (claude, independent opening).** The kill-gate measurement of the paid surface forces an honest re-scope of the handoff's optimistic plan. The handoff named five extraction targets (tiers reader, cost-print, `--confirm-cost-usd` gate, FAL_KEY, `pm_fal_run`). Measured against the real tool bodies, only **two** survive the byte-identical-or-cleanly-parameterized bar the kernel pass (spec 163) set:

1. **FAL_KEY presence + leak-safe state** — every paid tool does `[ -n "${FAL_KEY:-}" ]` and reports state via the `${FAL_KEY:+set}` idiom (never the value). Identical. Risk zero.
2. **The YAML tiers block-scan oracle reader** — `sound`'s `yget`/`ytop` and `video`'s `resolve_tier_field`/`yaml_top` are the *same* awk block-scan over a 2-space/4-space `*-tiers.yaml`, parameterizable over (file, tier, field).

The other three are **genuine variants and must stay local** — extracting them would change behavior, which the refactor forbids:
- **`--confirm-cost-usd` gate**: `sound` is a *hybrid* threshold gate (auto-proceed ≤ $0.25), `video` is a *hard* always-confirm gate, `audio`/`image` have **no gate**. Conflicting policies, not one mechanism.
- **cost formula**: per-second vs per-1k-chars-ceiling vs table-lookup vs per-second-multiply. Four different computations.
- **fal invocation**: `sound`/`audio`/`image` are synchronous `run`→`download`; `video` is async `submit`→`status`→`result`. Plus per-model body shapes. Not one wrapper.

**My recommendation: ship a separate `lib/paid-media.sh`, do NOT fold into `lib/capacity.sh`.** Cohesion is the reason, not size. `capacity.sh` is the *local-free* kernel (its whole identity in the family is "no cost, no key, stays local"). `FAL_KEY` and a `*-tiers.yaml` oracle are *paid-domain* concerns — folding them into the free kernel pollutes the one abstraction the family is careful to keep clean. The sync glob `.agent0/tools/lib|*.sh` (added in 163) already carries a second lib for free, so a separate file costs zero new plumbing.

**Scope of THIS pass — the honest part.** The two clean `.agent0/tools/` paid tools that already `source capacity.sh` are `sound` and `audio`. They get migrated:
- `sound`: `yget`/`ytop` → `pm_yget`/`pm_ytop`; FAL_KEY check + state → `pm_*`.
- `audio`: its **inline per-field awk** (different field names — `price_per_1k_chars`, `default_tier`) reworked to the shared reader. This is the one spot needing care: it's a normalization, behavior-preserving only if the reader returns byte-identical field values. Prove it in the golden.

`image` and `video` are the open question I want pressure-tested. `image` uses a **pipe-delimited table, not YAML** — it literally cannot consume the YAML reader, so it gets FAL_KEY-state at most (marginal). `video` is **async + skill-dir + does not even source `capacity.sh`** — wiring it in is a bigger surface than the reader payoff. My lean: take `image`/`video` for **FAL_KEY-state only if cheap**, and do NOT contort the YAML reader to fit `image`'s table or rewire `video`'s sourcing in this pass — that's scope creep dressed as completeness. But the founder's directive is "don't let followups resolve everything in this loop," so if Codex sees a clean path to include them, I want it.

**Discipline (non-negotiable, the 163 template):** capture the golden BEFORE (extend `.agent0/tests/capacity-kit/golden.sh` to pin the deterministic paid surface — caps/--help/usage plus the cost-print and gate-refusal *text* of `sound`/`audio`), extract, then prove: `golden verify` byte-identical before-vs-after + every tool suite green + sync-propagation (lib ships) + `missing-kit-guard` + `bash -n` + `doctor`. Zero behavior change is the closer, not agent agreement.

**Two questions for the table:** (1) Separate lib vs fold-into-capacity.sh — is cohesion worth a 3-function file? (2) Are `image`/`video` in-scope for this pass, or is forcing them in exactly the over-prescription the kernel pass warned about?


### Turn 2 — codex (blind opening) (codex)

My opening view: build `lib/paid-media.sh`, but make it smaller than the deferred task list suggests. The honest surface is the paid-domain plumbing that is either scalar/predicate-level or already caller-parametric. Do not extract policy, output shape, or model body construction.

A clears, but only narrowly. `sound` has `yget`/`ytop` as fixed-format awk readers over simple YAML scalars (`.agent0/tools/sound.sh:65-80`), `video` has the same basic job with `resolve_tier_field`/`yaml_top` (`.agent0/skills/video/scripts/gen.sh:61-79`), and `audio` does inline block scans for `default_tier`, `model`, and `price_per_1k_chars` (`.agent0/tools/audio.sh:177-180`). A shared `pm_yaml_top <file> <key>` and `pm_yaml_tier_field <file> <tier> <field>` is a clean extraction if it remains a fixed 2-space/4-space scalar reader. It should not become a YAML parser, should preserve quote/comment stripping needed by `sound` (`sound-tiers.yaml:53` has an inline comment), and should be protected by before/after tests for `sound`, `audio --remote`, and `video prepare`.

D partially clears. A leak-safe `pm_fal_key_state` returning `set|unset` or boolean is safe: `sound caps/doctor` and `audio caps/doctor` already use the `${FAL_KEY:+set}`/state pattern (`.agent0/tools/sound.sh:88-95`, `.agent0/tools/audio.sh:109-112`, `.agent0/tools/audio.sh:125-126`). But a generic `pm_require_fal_key` does not clear unless it only returns success/failure. The user-facing failure contracts differ sharply: `sound` emits compact `cap_fail unavailable` text (`.agent0/tools/sound.sh:147`), `audio` uses its local pretty `fail` (`.agent0/tools/audio.sh:145-151`, `.agent0/tools/audio.sh:174`), and `image`/`video` print multi-line activation errors (`.agent0/skills/image/scripts/gen.sh:76-88`, `.agent0/skills/video/scripts/gen.sh:47-54`).

B should mostly stay local. The invariant is "cost prints before the call," but the actual formulas and exact lines differ: `sound` is price times duration/unit with 4 decimals (`.agent0/tools/sound.sh:166-173`), `audio` is ceil(chars/1000) with 4 decimals (`.agent0/tools/audio.sh:183-184`), `image` is a table lookup printed as `estimated:` (`.agent0/skills/image/scripts/gen.sh:202-228`), and `video` is per-second with 2 decimals plus a confirmed ceiling (`.agent0/skills/video/scripts/gen.sh:133-153`). A shared formatter would either be a vacuous `printf "$message"` wrapper or would normalize bytes that tests currently pin, for example image’s first-line estimate (`.agent0/tests/image-gen/01-draft-tier-workflow.sh:33-40`) and video’s estimate math (`.agent0/tests/video/02-generative-cost-gate.sh:40-47`).

C does not clear as a policy extraction. `sound` has a hybrid threshold gate and an env override (`.agent0/tools/sound.sh:171-179`; tested at `.agent0/tests/sound/02-music-above-threshold.sh:4-17` and `.agent0/tests/sound/06-json-format-wav.sh:18-20`). `video` has a hard always-confirm gate with exit 2 and stderr refusal text (`.agent0/skills/video/scripts/gen.sh:137-146`; tested at `.agent0/tests/video/02-generative-cost-gate.sh:30-38`). `audio` and `image` have no confirmation gate. At most, extract a pure numeric helper such as "confirm covers estimate"; keep the refusal policy and messages local.

E clears only at the already-existing `fal-rest.sh` layer, not much beyond it. The real shared primitive is already `.agent0/tools/fal-rest.sh`, which is intentionally model-agnostic and supports `run`, `submit`, `status`, `result`, and `download` (`.agent0/tools/fal-rest.sh:12-28`, `.agent0/tools/fal-rest.sh:81-113`, `.agent0/tools/fal-rest.sh:167-185`). `sound` and `audio` both do sync `run` then `download` (`.agent0/tools/sound.sh:192-198`, `.agent0/tools/audio.sh:186-191`), so a very thin `pm_fal_run`/`pm_fal_download` wrapper is acceptable only if it does not parse model output or call `fail`. A higher-level `run_download_and_extract_url` is already getting awkward: `sound` uses oracle-provided URL paths (`.agent0/tools/sound.sh:151-155`, `.agent0/tools/sound.sh:193-194`), `audio` has hard-coded fallback URL paths (`.agent0/tools/audio.sh:187-188`), `image` expects `.images[0].url` and emits JSON receipts (`.agent0/skills/image/scripts/gen.sh:319-333`, `.agent0/skills/image/scripts/gen.sh:372-373`), and `video` is async ledger/poll (`.agent0/skills/video/scripts/gen.sh:184-194`, `.agent0/skills/video/scripts/gen.sh:206-220`).

I would keep this as a separate `lib/paid-media.sh`, not fold it into `lib/capacity.sh`. `capacity.sh` is the neutral kernel for local/free and paid capacity tools: hashing, exit mapping, manifest append mechanics, compact fail, ffmpeg resolution (`.agent0/tools/lib/capacity.sh:21-69`). Paid concerns are a different cohesion cluster: FAL key state, fal REST call wrappers, and tier-oracle scalar reads. The rule file already frames the paid kit as a deferred companion (`.agent0/context/rules/capacity-kit.md:40-42`), and sync propagation already carries future lib files (`.agent0/tools/sync-harness.sh:192-199`; test anchor `.agent0/tests/capacity-kit/sync-propagation.sh:21-38`). Separate is fine if the file stays tiny and side-effect-free.

For scope, I would migrate `sound` and `audio --remote` first. They already source the capacity kernel (`.agent0/tools/sound.sh:60-62`, `.agent0/tools/audio.sh:67-70`), have focused offline suites, and are the only current first-class `.agent0/tools/` paid callers. `video` is partial scope at most: its YAML reader can move to `pm_yaml_*`, but its hard gate and async queue flow should stay local. `image` should be out of this pass unless the pass is explicitly broadened into an image tier-table redesign. It uses a pipe-delimited table, not YAML (`.agent0/skills/image/scripts/gen.sh:40-42`, `.agent0/skills/image/scripts/gen.sh:119-127`), and its prepare/exec/record workflow is a different contract (`.agent0/skills/image/scripts/gen.sh:13-16`, `.agent0/skills/image/scripts/gen.sh:253-374`, `.agent0/skills/image/scripts/gen.sh:379-429`).

The measurement misses a few migration risks. First, `audio`’s `--help` is source-line based and the capacity notes already call out that source insertion can drift help output (`docs/specs/163-capacity-kit/notes.md:37`); source `paid-media.sh` below the help range just like `capacity.sh`. Second, helper functions must not emit or exit, because `sound` uses compact `cap_fail` while `audio` intentionally keeps a local pretty `fail` (`docs/specs/163-capacity-kit/notes.md:15-16`). Third, do not "fix" model body semantics while extracting: `sound` currently sends `DURATION` directly under whatever `duration_field` the oracle names (`.agent0/tools/sound.sh:188-190`), even though the premium YAML note says `music_length_ms` is unverified (`.agent0/skills/sound/references/sound-tiers.yaml:51-58`). That may be a future bug, but changing units during a refactor would violate the zero-behavior-change bar.

Recommended decision: create `lib/paid-media.sh` with pure helpers only: `pm_yaml_top`, `pm_yaml_tier_field`, `pm_fal_key_state`/`pm_has_fal_key`, and maybe thin `pm_fal_run`/`pm_fal_download` passthroughs. Migrate `sound` and `audio --remote` under a new paid golden gate plus their suites. Treat `video` YAML migration as optional second step after green. Leave `image` local for now.

### Turn 3 — Claude Code (claude)

Strong independent convergence — we landed on the same shape from sealed openings. Recording it, accepting two of your sharpenings, and pressing the one point that's actually live.

**Converged (both, anchored):**
- **Separate `lib/paid-media.sh`, not folded into `capacity.sh`** — cohesion: `capacity.sh:21-69` is the neutral kernel (hash/exit/manifest/fail/ffmpeg); FAL_KEY + tier-oracle are a different cluster. Sync glob already carries a second lib (`sync-harness.sh:192-199`, `tests/capacity-kit/sync-propagation.sh:21-38`). Zero new plumbing.
- **The extraction surface is two pure readers + one state predicate**, nothing policy-bearing: `pm_yaml_top <file> <key>` + `pm_yaml_tier_field <file> <tier> <field>` (fixed 2-/4-space scalar reader, **preserves quote + inline-comment stripping** — `sound-tiers.yaml:53` has a trailing comment), and `pm_fal_key_state`/`pm_has_fal_key`.
- **B/C/E stay local.** Cost formula (B) differs four ways and tests pin the bytes. Cost gate (C) is conflicting policy — `sound` hybrid-threshold vs `video` hard-confirm vs none. fal invocation (E) is already shared at `fal-rest.sh`; per-model body + sync-vs-async live above it.

**Accepting your two corrections to my opening:**
1. **Helpers must be pure — never emit, never exit.** My "`pm_require_fal_key`, risk zero" was wrong on the *failure* path: `sound` fails via compact `cap_fail` (`sound.sh:147`), `audio` via its local pretty `fail` (`audio.sh:174`), `image`/`video` via multi-line activation text. So it's a **predicate** (`pm_has_fal_key` → 0/1) + a **state string** (`pm_fal_key_state` → `set|unset`); the tool keeps its own failure contract. Correct.
2. **Don't "fix" model-body semantics mid-refactor** — `sound`'s `DURATION` under the oracle's `duration_field` and the unverified `music_length_ms` note (`sound-tiers.yaml:51-58`) is a possible future bug, but changing units during a behavior-preserving extraction is out of bounds. Agreed — flag it in notes, touch nothing.

I'd also **drop** the `pm_fal_run`/`pm_fal_download` passthroughs unless they earn their place: `sound.sh:192-198` and `audio.sh:186-191` are a 2-line `run`→`download` each, and the `|| cap_fail`/`|| fail` tail is the tool's local failure. A passthrough that can't include the `||` tail (because the failure differs) saves almost nothing and adds an indirection. Lean: **skip them**, keep the two `pm_yaml_*` + `pm_has_fal_key`/`pm_fal_key_state` as the whole lib. Push back if you think the FAL_REST-path centralization alone justifies them.

**The live question — `video` scope, against the founder's "don't let followups resolve everything in this loop."** You scoped `video`'s YAML migration as an *optional second step after green*; I want to test whether the founder directive should pull it INTO this pass. Here's my concern, and it's not laziness: `sound`/`audio` are `.agent0/tools/` tools that **already source `capacity.sh`** (`sound.sh:60-62`, `audio.sh:67-70`). `video` is **skill-dir** (`.agent0/skills/video/scripts/gen.sh`) and **deliberately does NOT source the kernel** — the 163 pass left image/video out for exactly this reason. Migrating `video` to `pm_yaml_*` forces it to `source ../../../tools/lib/paid-media.sh` — a **new cross-dir sourcing dependency** from a skill-dir tool into `tools/lib/`, which is a *different architectural concern* than "finish the tools-dir paid extraction," and one whose sync/relative-path story the 163 pass never validated.

So my read of the directive: this loop should finish the **complete, clean** extraction for the real duplication — the `.agent0/tools/` paid surface (`sound` + `audio`), end to end, gated green, nothing deferred *within that surface*. `video`'s YAML reader migration isn't a deferred piece of *this* work; it's the **first instance of a separate question** (should skill-dir tools source `tools/lib/`?). Pulling it in is the over-prescription smell — completeness-as-scope-creep — the kernel pass warned against.

Two things I want from you, then I think we ledger and synthesize:
1. Do you agree `video`'s cross-dir sourcing is a genuinely separate concern (so deferring its YAML migration is *honest scoping*, not punting), or is the source line trivial enough (it has its own suite under `tests/video/`) that including it is clean and we should honor "don't defer"?
2. Confirm `image` is unambiguously OUT (pipe-table, not YAML; different prepare/exec/record contract) — agreed, no founder-directive tension there?

Next: codex


### Turn 4 — Codex CLI (codex)

I agree with claude on `video`: defer it as honest scoping, not punting.

Verified layout: `.agent0/skills/video/scripts/gen.sh:23-27` is a skill-dir helper that derives `PROJECT_DIR`, `SKILL_DIR`, `TIERS_FILE`, and an executable `FAL_REST`; its YAML readers are inline at `.agent0/skills/video/scripts/gen.sh:61-79`. By contrast, the tools-dir targets already source a library: `.agent0/tools/sound.sh:60-62` and `.agent0/tools/audio.sh:67-70`. So migrating `video` would introduce a new skill-dir -> `tools/lib` sourced dependency. The brittle `../../../` concern is avoidable by sourcing `$PROJECT_DIR/.agent0/tools/lib/paid-media.sh`, and sync propagation is already mostly covered by `.agent0/tools/sync-harness.sh:183-199` plus `test:.agent0/tests/capacity-kit/sync-propagation.sh:21-38`. But that still makes it a separate portability/dependency pattern, not just a reader extraction.

`video`’s tests make the later migration feasible, not free: `test:.agent0/tests/video/02-generative-cost-gate.sh:6-12` pins tier resolution and gate behavior, and `test:.agent0/tests/video/run-all.sh:10-13` runs the suite. They do not specifically prove a skill script sourcing a harness library. My decision: `video` is OUT for this pass; add a dedicated skill-script source/sync smoke when that concern is taken on.

`image` is unambiguously OUT. It is pipe-table based, not YAML: `.agent0/skills/image/scripts/gen.sh:40-42` and `.agent0/skills/image/scripts/gen.sh:113-127`. Its prepare/exec/record contract is a different three-stage shape, documented at `.agent0/skills/image/scripts/gen.sh:4-16` and implemented across `.agent0/skills/image/scripts/gen.sh:202-228`, `.agent0/skills/image/scripts/gen.sh:253-333`, `.agent0/skills/image/scripts/gen.sh:379-429`. No founder-directive tension there; deciding it out is resolving scope, not deferring hidden work.

I also agree to drop `pm_fal_run`/`pm_fal_download`. FAL centralization already exists at `.agent0/tools/fal-rest.sh:12-28`, with `run` at `.agent0/tools/fal-rest.sh:81-113` and `download` at `.agent0/tools/fal-rest.sh:167-185`. The callers still need local failure tails: `.agent0/tools/sound.sh:192-198` uses `cap_fail`, while `.agent0/tools/audio.sh:186-191` uses local `fail`. A passthrough that cannot carry those tails adds indirection without meaningful consolidation.

Recommended final decision: `lib/paid-media.sh` contains only pure helpers: `pm_yaml_top`, `pm_yaml_tier_field`, `pm_has_fal_key`, `pm_fal_key_state`. Migrate only `sound` and `audio --remote`; keep B/C/E local; record `image` and `video` as explicitly out of this pass.

Next: claude
## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| Discipline: golden BEFORE, extract, prove golden verify + suites + sync-propagation + bash -n + doctor; zero behavior change | supported | path:.agent0/tests/capacity-kit/golden.sh |
| Don't fix model-body semantics mid-refactor (sound DURATION/music_length_ms unverified) — flag in notes, change nothing | supported | path:.agent0/skills/sound/references/sound-tiers.yaml |
| image OUT — pipe-table not YAML, different prepare/exec/record contract | supported | path:.agent0/skills/image/scripts/gen.sh |
| video OUT — skill-dir gen.sh sourcing tools/lib is a separate cross-dir portability concern needing its own source/sync smoke | supported | path:.agent0/skills/video/scripts/gen.sh |
| Drop pm_fal_run/pm_fal_download passthroughs — cannot carry the local failure tails, no consolidation over fal-rest.sh | supported | path:.agent0/tools/fal-rest.sh |
| Cost-print (B), cost-gate (C), fal invocation (E) stay LOCAL — genuine variants; extraction would change behavior tests pin | supported | test:.agent0/tests/video/02-generative-cost-gate.sh |
| Helpers must be pure — never emit, never exit; the tool keeps its own failure contract | supported | path:docs/specs/163-capacity-kit/notes.md |
| FAL_KEY: extract only pure predicate pm_has_fal_key + state pm_fal_key_state; NOT a require helper (failure contracts differ) | supported | path:.agent0/tools/audio.sh |
| audio inline per-field awk (default_tier, price_per_1k_chars) reworked to the shared reader, behavior-preserving | supported | path:.agent0/tools/audio.sh |
| Extraction surface = two pure YAML readers (pm_yaml_top, pm_yaml_tier_field) preserving quote+inline-comment stripping | supported | path:.agent0/tools/sound.sh |
| Ship a separate lib/paid-media.sh; do NOT fold paid helpers into lib/capacity.sh (capacity.sh is the neutral kernel; FAL_KEY+tier-oracle are a paid cluster) | supported | path:.agent0/tools/lib/capacity.sh |
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesizing runtime:** claude. **Ledger:** 11 claims, 0 assertion-only, all anchored (`ledger-check` + `check-anchors` both green). **Tier:** decision-grade.

**Convergence (independent, from sealed openings).** Both runtimes opened blind and landed on the same shape — a strong signal it's the honest one, not an anchored one. The kill-gate measurement re-scopes the handoff's optimistic 5-target plan down to a **tiny, side-effect-free** `lib/paid-media.sh`:

- **A separate lib, not folded into `capacity.sh`.** `capacity.sh` is the neutral local/free+paid kernel (hash/exit/manifest/fail/ffmpeg); `FAL_KEY` + a `*-tiers.yaml` oracle are a distinct paid cohesion cluster. Folding them pollutes the kernel's clean identity. The sync glob `.agent0/tools/lib|*.sh` already carries a second lib → zero new plumbing.
- **The whole extraction surface is four pure helpers:** `pm_yaml_top <file> <key>`, `pm_yaml_tier_field <file> <tier> <field>` (fixed 2-/4-space scalar readers preserving quote + inline-comment stripping), `pm_has_fal_key` (predicate → 0/1), `pm_fal_key_state` (→ `set|unset`). **Helpers never emit and never exit** — the tool keeps its own failure contract (`sound` compact `cap_fail`, `audio` local pretty `fail`).
- **B / C / E stay LOCAL — genuine variants, not one mechanism.** Cost formula (B) differs four ways and tests pin the bytes; the cost gate (C) is conflicting *policy* (`sound` hybrid-threshold vs `video` hard-confirm vs none); fal invocation (E) is already consolidated at `fal-rest.sh`, with per-model body + sync-vs-async living above it. A `pm_require_fal_key` and `pm_fal_run`/`pm_fal_download` were both **rejected** — they can't carry the divergent local failure tails, so they'd add indirection without consolidation.
- **Scope of this pass: `sound` + `audio --remote` only** — the two `.agent0/tools/` paid tools that already source `capacity.sh`. `audio`'s inline per-field awk is reworked onto the shared reader (behavior-preserving, proven in golden). **`image` and `video` are explicitly OUT** (see minority report).
- **Discipline (the 163 template):** golden BEFORE → extract → prove `golden verify` byte-identical + every tool suite + sync-propagation + `missing-kit-guard` + `bash -n` + `doctor`. Zero behavior change is the closer.
- **Do NOT "fix" model-body semantics mid-refactor** (`sound`'s `DURATION`/unverified `music_length_ms`) — flag in notes, change nothing.

**Recorded disagreements:** none material. The only correction during the meeting was to claude's opening (`pm_require_fal_key` "risk zero" → wrong on the failure path; downgraded to a pure predicate + state string). Both runtimes accepted it.

**Minority report (preserved verbatim, not smoothed):**
1. **`video`'s YAML migration is honest-deferred, not vaporware.** `video`'s `resolve_tier_field`/`yaml_top` *could* move to `pm_yaml_*`, but `video` is a **skill-dir** tool (`.agent0/skills/video/scripts/gen.sh`) that deliberately does NOT source the kernel. Migrating it introduces a **new cross-dir `source $PROJECT_DIR/.agent0/tools/lib/...` dependency** — a separate portability/sync concern the 163 pass never validated, needing its own skill-script source/sync smoke test. It is a *distinct question*, not a deferred slice of the tools-dir extraction. Recording it as the named, anchored reopen-trigger (NOT a vague "later").
2. **`image` is unambiguously out** — pipe-delimited table, not YAML; a different prepare/exec/record three-stage contract. Resolving scope, not deferring hidden work.
3. **Thinness caveat:** a 4-helper lib invites the "too thin to justify a separate file" objection. Both judged cohesion worth it and the sync cost zero; recorded so a future reader sees the call was deliberate, not unconsidered.

**Recommended next step: GRADUATE.** Hand this synthesis to `/sdd refine` as seed context for spec 164 `paid-media-kit` (not a finished spec — seed for the interview). Link this `meeting.md` from the spec's `## Context / references`.
