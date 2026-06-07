---
meeting: cross-dir-capacity-sourcing
topic: "skill-dir tools sourcing tools/lib: the cross-dir cable + honest video/image scope"
created: 2026-06-07T13:27:06Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 3
next_speaker: claude
synthesis: accepted
---

# Meeting: skill-dir tools sourcing tools/lib: the cross-dir cable + honest video/image scope

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — Carlos (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:b8a55044f3edbdcc` (4027 bytes)
- commit codex — `sha256:baa275bd6a870dbe` (3741 bytes)

### Turn 1 — claude (blind opening) (claude)

**Position (claude, independent opening).** The measurement collapses the "cross-dir cable" risk the 164 minority report imagined. Two facts change the picture:

1. **The `$PROJECT_DIR` anchor already exists and is already used.** Both `video/scripts/gen.sh:23-28` and `image/scripts/gen.sh:25-28` set `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"` and already reference `$PROJECT_DIR/.agent0/tools/fal-rest.sh`. So a skill-dir tool reaching into `tools/` is NOT a new pattern — it's the *established* one. The only delta is **sourcing** a lib (`. "$PROJECT_DIR/.agent0/tools/lib/paid-media.sh"`) vs **invoking** a tool (`bash "$FAL_REST"`). Same anchor, proven robust. There is no brittle `../../../` — I reject that framing; `$PROJECT_DIR` is the right anchor because it's what the file already trusts.
2. **Skill-dir scripts already propagate + the libs already ship.** The 2026-06-07 sync showed `video/gen.sh` and `image/gen.sh` already "up to date" in cognixse, and we verified `lib/capacity.sh` + `lib/paid-media.sh` landed in both consumers this session. `$PROJECT_DIR` resolves to the consumer's own toplevel, so a consumer's video sourcing `$PROJECT_DIR/.agent0/tools/lib/...` finds the synced lib.

**So the genuinely-new risk surface is small** — exactly what the smoke test must pin: (a) a skill-dir script sourcing `$PROJECT_DIR/.agent0/tools/lib/<lib>.sh` resolves in the repo, (b) resolves in a synced-consumer layout (PROJECT_DIR=consumer root, lib present), (c) fails CLEAN if the lib is absent (exit code + message, like `missing-kit-guard`). That's the prerequisite the 164 minority report named — and it's a half-day, not a week.

**Scope, measured:**
- **`video`**: reads only `model`/`price_usd_per_second`/`max_duration_seconds` (tier) + `snapshot_date`/`stale_after_days` (top). I proved all of them **byte-identical** between video's `resolve_tier_field`/`yaml_top` and `pm_yaml_tier_field`/`pm_yaml_top` over the real `video-tiers.yaml` before this meeting. So video → `pm_yaml_*` is behavior-preserving by evidence (the 164 audio lesson, repeated). Plus its FAL_KEY check (`die_no_fal_key`) → `pm_has_fal_key` (video keeps its own multi-line `die` — the pure-helper contract, same as sound/audio).
- **`image`**: its tiers are a **pipe-delimited `TIER_TABLE` string, not YAML** (`gen.sh:40-42`). It **cannot** consume `pm_yaml_*`. What it CAN share is the FAL_KEY state: `pm_has_fal_key`/`pm_fal_key_state` (it has two `die_no_fal_key` call sites). So image gets the FAL_KEY helpers only.

**The one question I want pressure-tested — and it's exactly where the founder is watching for a rationalized punt.** Is leaving image's pipe-table as a pipe-table a *loose end I'm creating*, or a *pre-existing separate choice*? My claim: it's pre-existing and separate, NOT a followup of THIS work. Reasoning: the cross-dir cable lets image adopt the FAL_KEY helpers; it does **not** require image to become YAML. Image's pipe-table works, is deliberate, and is read by image's own `resolve_tier` — nothing is left half-done if I wire the FAL_KEY helpers and stop. Converting pipe→YAML is a *different* refactor (image's tier-system redesign), with its own behavior-preservation surface and ~zero incremental dedup value (one tool, one table). The founder's directive is "don't park followups THIS work creates" — and this work creates none for image; the pipe-table predates it and survives it intact. Codex: tell me if that's honest, or if I'm using "separate concern" as the exact excuse the founder just called out. If you think image-to-YAML must be in this loop, make the case.

Second question: should the smoke test live as a new `tests/capacity-kit/cross-dir-source.sh`, or extend `missing-kit-guard.sh` / `sync-propagation.sh`? My lean: a dedicated new test (the concern is distinct — PROJECT_DIR-anchored sourcing + consumer-layout resolution — and deserves its own named gate), but reuse the sync-propagation harness pattern.


### Turn 2 — codex (blind opening) (codex)

**Blind Opening**

My decision: source `paid-media.sh` from `$PROJECT_DIR/.agent0/tools/lib/paid-media.sh`, not from a `BASH_SOURCE` relative path. Both skill scripts already define `PROJECT_DIR` and use it to cross into `.agent0/tools/fal-rest.sh`; that is the established consumer-root anchor, including temp-project tests that set `CLAUDE_PROJECT_DIR` while invoking the script from Agent0 (`.agent0/skills/video/scripts/gen.sh:23-28`, `.agent0/skills/image/scripts/gen.sh:25-28`, `test:.agent0/tests/video/02-generative-cost-gate.sh:15-20`, `test:.agent0/tests/image-gen/01-draft-tier-workflow.sh:22-29`). Sync also ships both sides of this relationship: `.agent0/skills` recursively and `.agent0/tools/lib|*.sh` explicitly (`.agent0/tools/sync-harness.sh:183-199`).

The guard should match the kit precedent: source through a small loader and fail `exit 70` with `missing kit library lib/paid-media.sh` when a paid path needs it (`path:.agent0/tests/capacity-kit/missing-kit-guard.sh:15-24`, `.agent0/tools/sound.sh:60-63`, `.agent0/tools/audio.sh:67-71`). I would not source unconditionally at file load for image/video, because their help/noargs dispatch currently works without loading any lib (`.agent0/skills/video/scripts/gen.sh:276-294`, `.agent0/skills/image/scripts/gen.sh:435-464`). Use `load_paid_media` inside paid subcommands: video `prepare/submit/poll`; image `prepare/exec`. That preserves help/noargs/record behavior.

The smoke should be a new dedicated test, not a bolt-on to `sync-propagation.sh`. Existing sync only proves the lib ships (`path:.agent0/tests/capacity-kit/sync-propagation.sh:34-38`); existing missing-kit only proves tools-dir failure. The new smoke should pin: repo-root resolution, `CLAUDE_PROJECT_DIR`/consumer-root resolution, and absent-lib clean failure. It should include a sentinel consumer lib to prove the skill script sources `$PROJECT_DIR/.agent0/tools/lib/paid-media.sh`, plus a no-lib lane proving `exit 70` on paid subcommands while `--help` still works.

Honest scope: migrate video to `pm_yaml_top`/`pm_yaml_tier_field` plus `pm_has_fal_key`; migrate image only to the FAL_KEY predicate. Leaving image’s pipe table alone is honest, not a rationalized punt. The shared YAML helpers are explicitly a fixed `*-tiers.yaml` scalar oracle (`.agent0/tools/lib/paid-media.sh:30-57`). Video already has the matching YAML reader and reads model/price/max-duration/top staleness from `video-tiers.yaml` (`.agent0/skills/video/scripts/gen.sh:61-85`, `.agent0/skills/video/scripts/gen.sh:122-125`, `.agent0/skills/video/references/video-tiers.yaml:13-24`). Image is a different data model: inline pipe rows with model/output-dir/cost/ext plus a separate aspect table (`.agent0/skills/image/scripts/gen.sh:31-51`, `.agent0/skills/image/scripts/gen.sh:113-127`). Converting that to YAML would create a new oracle file and documentation/test surface, not retire duplication created by this pass.

Behavior preservation needs the 164 discipline plus one cross-dir addition: prove source resolution under consumer layout. Keep video wrappers (`resolve_tier_field`/`yaml_top`) as binders over `pm_yaml_*`, like sound did, to minimize call-site churn (`docs/specs/164-paid-media-kit/notes.md:25-26`). Keep image `die_no_fal_key` and video `die_no_fal_key` messages local and call them via `pm_has_fal_key || die_no_fal_key` (`.agent0/skills/video/scripts/gen.sh:47-55`, `.agent0/skills/image/scripts/gen.sh:76-89`). Verification should include before/after deterministic surfaces, video suite, image-gen suite, new source/sync smoke, missing-lib guard, `sync-propagation`, `bash -n`, and a sentinel FAL_KEY leak check analogous to paid-golden (`test:.agent0/tests/capacity-kit/paid-golden.sh:27-48`).

### Turn 3 — Claude Code (claude)

Full independent convergence again, and you caught two things I had wrong/underspecified. Accepting both, locking the design.

**Accepted — lazy-load, not file-top source.** My opening implied sourcing the lib like sound/audio do (at file top). You're right that's a behavior change for `video`/`image`: their `--help`/`noargs`/`record` paths work today with NO lib loaded, so a top-level `. "$lib" || exit 70` would make `--help` fail (exit 70) whenever the lib is absent. The fix is a `load_paid_media` guard called **inside the paid subcommands only** — video `prepare`/`submit`/`poll`, image `prepare`/`exec` — so help/noargs/record keep working lib-absent. This is the cross-dir-specific behavior-preservation point; tools-dir tools could source at top because they're paid-from-the-first-line, but skill-dir tools have non-paid lanes. Locked.

**Accepted — image stays pipe-table; the reasoning is the anti-punt proof, not an excuse.** The precise argument (yours, sharper than mine): converting image pipe→YAML would **create** a new oracle file + doc/test surface — it does **not retire duplication this pass introduces**. The shared helpers are a fixed `*-tiers.yaml` scalar oracle; image is a genuinely different data model (inline pipe rows + a separate aspect table). So image gets the FAL_KEY predicate only, and that leaves **no loose end from this work** — the pipe-table predates it and survives intact. That is exactly the distinction the founder's directive turns on: "don't park followups THIS work creates." This work creates none for image. (If we ever WANT image on YAML, it's its own spec with its own value case — not a thread dangling off this one.)

**Locked design (both converged):**
- **Pattern:** `. "$PROJECT_DIR/.agent0/tools/lib/paid-media.sh"` — the anchor both scripts already use for `fal-rest.sh`; robust in repo AND consumer (where `$PROJECT_DIR` = consumer root). No `../../../`.
- **Loader:** a small `load_paid_media` that sources once and, when absent, fails `exit 70` + `missing kit library lib/paid-media.sh` (the kernel precedent). Called inside paid subcommands only.
- **video:** `resolve_tier_field`/`yaml_top` → 1-line binders over `pm_yaml_tier_field`/`pm_yaml_top` (proven byte-identical over `video-tiers.yaml`; the sound pattern); `die_no_fal_key` stays local, called via `pm_has_fal_key || die_no_fal_key`.
- **image:** the two `die_no_fal_key` sites → `pm_has_fal_key || die_no_fal_key`; pipe-table untouched.
- **smoke test:** new dedicated `tests/capacity-kit/cross-dir-source.sh` — pins (a) repo-root resolution, (b) `CLAUDE_PROJECT_DIR`/consumer-root resolution via a sentinel consumer lib, (c) absent-lib → `exit 70` on a paid subcommand WHILE `--help` still works. Reuses sync-propagation's temp-consumer pattern.
- **gate:** golden BEFORE → migrate → prove deterministic surfaces byte-identical + video suite + image-gen suite + new smoke + missing-lib guard + sync-propagation + bash -n + a sentinel FAL_KEY leak check (paid-golden-style). Zero behavior change.

No open disagreements. I'll ledger and synthesize.

## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| Gate: golden BEFORE + deterministic-surface parity + video suite + image-gen suite + new smoke + missing-lib guard + sync-propagation + bash -n + sentinel FAL_KEY leak check | supported | test:.agent0/tests/capacity-kit/paid-golden.sh |
| New dedicated smoke test pins repo-root + CLAUDE_PROJECT_DIR/consumer-root resolution + absent-lib exit 70 on paid subcommand while --help works | supported | path:.agent0/tests/capacity-kit/sync-propagation.sh |
| image stays pipe-table; gets pm_has_fal_key only — NOT a punt: converting pipe->YAML CREATES new oracle/doc/test surface, does not retire duplication this pass introduces | supported | path:.agent0/skills/image/scripts/gen.sh |
| video keeps die_no_fal_key local, called via pm_has_fal_key // die_no_fal_key (pure-helper contract) | supported | path:.agent0/skills/video/scripts/gen.sh |
| video reader -> pm_yaml_* proven byte-identical over video-tiers.yaml for all read fields (model/price/max_duration + snapshot/stale) | supported | path:.agent0/skills/video/references/video-tiers.yaml |
| Loader fails exit 70 + 'missing kit library lib/paid-media.sh' when absent (kernel precedent) | supported | path:.agent0/tests/capacity-kit/missing-kit-guard.sh |
| Lazy-load: a load_paid_media guard called INSIDE paid subcommands only (video prepare/submit/poll, image prepare/exec) — NOT file-top — so help/noargs/record keep working lib-absent | supported | path:.agent0/skills/image/scripts/gen.sh |
| Cross-dir pattern = source via $PROJECT_DIR/.agent0/tools/lib/paid-media.sh (the anchor both skill scripts already use for fal-rest); robust in repo + consumer | supported | path:.agent0/skills/video/scripts/gen.sh |
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesizing runtime:** claude. **Ledger:** 8 claims, 0 assertion-only, all anchored (`ledger-check` + `check-anchors` green). **Tier:** decision-grade.

**Convergence (independent, from sealed openings).** Both runtimes opened blind and landed on the same design. The 164 minority report's "cross-dir cable is a big new concern" framing was **overstated by the measurement**: both skill-dir tools already anchor on `$PROJECT_DIR` and already cross into `tools/` (they invoke `$PROJECT_DIR/.agent0/tools/fal-rest.sh`). The only genuinely-new bit is *sourcing* a lib vs *invoking* a tool — a small delta on a proven anchor.

- **Pattern:** source via `. "$PROJECT_DIR/.agent0/tools/lib/paid-media.sh"` (the anchor both scripts already trust). No brittle `../../../`. Robust in repo and in a synced consumer (`$PROJECT_DIR` = consumer root).
- **Lazy-load (the key cross-dir-specific correctness point, Codex's catch):** a `load_paid_media` guard called **inside paid subcommands only** (video `prepare`/`submit`/`poll`; image `prepare`/`exec`), NOT at file top. video/image have non-paid lanes (`--help`/`noargs`/`record`) that today work with no lib loaded; a top-level source would make `--help` fail (exit 70) when the lib is absent — a behavior change. Lazy-load preserves those lanes. (Tools-dir sound/audio source at top because they're paid from the first line; skill-dir tools are not.)
- **Loader fails clean:** `exit 70` + `missing kit library lib/paid-media.sh` (kernel precedent) when absent, on the paid path only.
- **video scope:** `resolve_tier_field`/`yaml_top` → 1-line binders over `pm_yaml_tier_field`/`pm_yaml_top` (proven **byte-identical** over `video-tiers.yaml` for every field video reads, before this meeting — the 164 audio lesson repeated); `die_no_fal_key` stays local, called via `pm_has_fal_key || die_no_fal_key`.
- **image scope:** the two `die_no_fal_key` sites → `pm_has_fal_key || die_no_fal_key`; the **pipe-table is untouched**.
- **smoke test:** a new dedicated `tests/capacity-kit/cross-dir-source.sh` pinning (a) repo-root resolution, (b) `CLAUDE_PROJECT_DIR`/consumer-root resolution (sentinel consumer lib), (c) absent-lib → `exit 70` on a paid subcommand WHILE `--help` still works. Reuses sync-propagation's temp-consumer harness.
- **gate:** golden BEFORE → migrate → deterministic-surface parity + video suite + image-gen suite + new smoke + missing-lib guard + sync-propagation + `bash -n` + a sentinel FAL_KEY leak check. Zero behavior change.

**Recorded disagreements:** none. The only corrections were to claude's opening — both accepted: (1) lazy-load over file-top source; (2) the sharpened image-scope argument.

**Minority report / the founder's anti-punt test (answered head-on):** Is leaving image's pipe-table a rationalized punt? **No — and the reasoning is falsifiable, not convenient.** This work's job is to wire skill-dir tools to the shared libs. For image that means adopting the FAL_KEY predicate; it does NOT entail a data-model change. Converting image pipe→YAML would **create** net-new surface (a new oracle file + its docs + its tests) — it would not **retire** any duplication *this* pass introduces. So image is left with **zero loose ends from this work**; the pipe-table predates it and survives intact. A pipe→YAML conversion, if ever wanted, is its own spec with its own value case (one tool, one table — ~zero dedup value today). This is the precise line the founder's directive draws: resolve followups THIS work creates (none for image), don't import adjacent refactors.

**Recommended next step: GRADUATE** to `/sdd` spec 165, seeded by this synthesis.
