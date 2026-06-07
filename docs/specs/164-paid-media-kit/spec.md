# 164 — paid-media-kit

_Created 2026-06-07._

**Status:** shipped

<!-- Optional — declare when this spec produces UI; drives the visual-contract acceptance gate (spec 155). Omit or keep `none` for non-UI work. See .agent0/context/rules/visual-contract.md -->
**UI impact:** none

## Intent

The deferred second layer of spec 163 (`capacity-kit`). The kernel pass shipped `.agent0/tools/lib/capacity.sh` (hash/exit/manifest/fail/ffmpeg) and migrated the four `.agent0/tools/` capacity tools onto it. This pass extracts the **paid-domain** plumbing still duplicated across the PAID tools into a sibling sourced lib `.agent0/tools/lib/paid-media.sh`, so the paid concerns live + are tested once instead of being hand-copied. A decision-grade `/meeting` (claude+codex, blind openings converged independently — `.agent0/meetings/paid-media-kit-honest-scope-2026-06-07T01-33-04Z/`) re-scoped the handoff's optimistic 5-target plan down to the **honest** surface a kill-gate measurement supports: only the byte-identical-or-cleanly-parameterized plumbing is extracted; everything that is genuine per-tool variance stays local. The result is a **tiny, pure, side-effect-free** helper lib (four functions), consumed by `sound` + `audio --remote` — the two `.agent0/tools/` paid tools that already source the kernel. Behavior is preserved by contract and proven by a golden parity gate, exactly as the 163 kernel pass was.

## Acceptance criteria

- [x] **Scenario: the paid sub-kit ships as a separate sourced lib**
  - **Given** `lib/capacity.sh` is the neutral local/free+paid kernel
  - **When** the paid plumbing is extracted
  - **Then** it lives in a *new* `.agent0/tools/lib/paid-media.sh` (NOT folded into `capacity.sh`), containing only the four pure helpers `pm_yaml_top`, `pm_yaml_tier_field`, `pm_has_fal_key`, `pm_fal_key_state`

- [x] **Scenario: helpers are pure — never emit, never exit**
  - **Given** the tools have divergent failure contracts (`sound` compact `cap_fail`, `audio` local pretty `fail`)
  - **When** a helper is called
  - **Then** it only returns a value / status code; it never prints a status line and never calls `exit` — the calling tool keeps its own failure path

- [x] **Scenario: `sound` migrates with zero behavior change**
  - **Given** `sound.sh` defines local `yget`/`ytop` and inline FAL_KEY checks
  - **When** `sound` is migrated to `pm_yaml_tier_field`/`pm_yaml_top` + `pm_has_fal_key`/`pm_fal_key_state`
  - **Then** `caps`/`doctor`/`--help`/usage/bad-flag output and every `tests/sound/` scenario are byte-identical before vs after

- [x] **Scenario: `audio --remote` reader migration is behavior-preserving**
  - **Given** `audio.sh` reads tiers via inline per-field awk (`default_tier`, `model`, `price_per_1k_chars`)
  - **When** those reads are replaced by the shared `pm_yaml_*` helpers
  - **Then** the helpers return byte-identical values for `audio-tiers.yaml` (proven empirically: `default_tier`, standard/premium `model` + `price_per_1k_chars` all match) and every `tests/audio/` scenario passes unchanged

- [x] **Scenario: golden parity gate proves the whole pass**
  - **Given** a golden snapshot of the deterministic paid surface captured BEFORE extraction
  - **When** `golden verify` runs after extraction
  - **Then** the `sound`/`audio` caps/doctor/--help/usage/bad-flag bytes are identical before vs after

- [x] **Scenario: the new lib propagates to consumers**
  - **Given** the sync glob `.agent0/tools/lib|*.sh` (added in 163)
  - **When** `sync-propagation` runs
  - **Then** `paid-media.sh` is carried to consumers (a tool sourcing it never finds it missing), and the `missing-kit-guard` covers it

- [x] FAL_KEY is never printed — `pm_fal_key_state` returns only `set|unset`, `pm_has_fal_key` returns only 0/1; no helper echoes `$FAL_KEY`
- [x] `bash -n` clean on `paid-media.sh`, `sound.sh`, `audio.sh`; `doctor` stays green (22 ok / 0 / 0)
- [x] `paid-media.sh` is sourced **below** each tool's `--help` `sed` line-range (the 163 gotcha) so `--help` does not drift

## Non-goals

- **No cost-print / cost-gate / cost-formula extraction.** Cost formula (B) differs four ways and tests pin the bytes; the `--confirm-cost-usd` gate (C) is conflicting *policy* — `sound` hybrid-threshold vs `video` hard-confirm vs `audio`/`image` none. They stay local.
- **No `pm_fal_run` / `pm_fal_download` wrappers.** fal invocation is already consolidated at `fal-rest.sh`; a passthrough can't carry the divergent local failure tails (`|| cap_fail` vs `|| fail`), so it adds indirection without consolidation.
- **No `pm_require_fal_key`** — a require helper that fails internally can't honor the per-tool failure contracts; only the pure predicate + state string are extracted.
- **`image` is out** — it uses a pipe-delimited table, not YAML, and a different prepare/exec/record three-stage contract.
- **`video` is out** — migrating its YAML reader would make a *skill-dir* tool (`.agent0/skills/video/scripts/gen.sh`) take on a new cross-dir `source .../tools/lib/...` dependency, a separate portability/sync concern the 163 pass never validated. Recorded as a named, anchored reopen-trigger (its own source/sync smoke test), NOT a vague "later".
- **No model-body semantic fixes** — `sound`'s `DURATION`/unverified `music_length_ms` is left exactly as-is; changing units mid-refactor would violate zero-behavior-change.

## Open questions

- [x] Separate lib vs fold into `capacity.sh`? → **Separate** (cohesion; sync glob already carries a second lib → zero new plumbing). Resolved in meeting.
- [x] Is `audio`'s inline-awk → shared-reader normalization behavior-preserving? → **Yes**, proven empirically byte-identical for `audio-tiers.yaml`. Resolved.
- [x] Are `image`/`video` in scope? → **No** (see Non-goals). Resolved in meeting.
- [x] Keep `pm_fal_run`/`pm_fal_download`? → **No**, dropped. Resolved in meeting.

## Context / references

- `.agent0/meetings/paid-media-kit-honest-scope-2026-06-07T01-33-04Z/meeting.md` — decision-grade meeting (blind openings, 11-claim ledger all anchored, minority report); the seed for this spec
- `docs/specs/163-capacity-kit/` — the kernel pass this extends; same behavior-preserving discipline + golden template
- `.agent0/tools/lib/capacity.sh` — the kernel the paid lib sits beside (header already names `lib/paid-media.sh` as the companion)
- `.agent0/context/rules/capacity-kit.md` — the rule (frames the paid sub-kit as the deferred follow-up)
- `.agent0/tools/sound.sh` (`yget`/`ytop` ~65-80; FAL_KEY ~88-147), `.agent0/tools/audio.sh` (inline awk ~177-184; FAL_KEY ~109-174) — the migration targets
- `.agent0/tests/capacity-kit/golden.sh`, `sync-propagation.sh`, `missing-kit-guard.sh` — the gate to extend
