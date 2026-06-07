# 164 — paid-media-kit — plan

_Drafted from `spec.md` on 2026-06-07. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Behavior-preserving extraction, identical discipline to the 163 kernel pass (the proven template). Order: **(1) capture golden BEFORE** any code change → **(2) write the new lib** `lib/paid-media.sh` (four pure helpers, no side effects) → **(3) migrate `sound`** (local `yget`/`ytop` → `pm_yaml_*`; inline FAL_KEY checks → `pm_has_fal_key`/`pm_fal_key_state`) → **(4) migrate `audio`** (inline per-field awk → `pm_yaml_*`; FAL_KEY → `pm_*`) → **(5) extend the gate** (paid-state golden pinning FAL_KEY set+unset; missing-kit-guard for paid-media.sh) → **(6) prove green** (golden verify byte-identical, both tool suites, sync-propagation, missing-kit-guard, bash -n, doctor) → **(7) docs** (rule + CLAUDE.md "deferred" → "shipped"; spec notes).

The shape is dictated by the kill-gate measurement, not preference: the helpers are pure because the tools' *failure contracts diverge* (`sound` compact `cap_fail`, `audio` local pretty `fail`) — a helper that emitted or exited could not serve both. The reader is the canonical `sound` `yget`/`ytop` logic (block-scan, quote+comment strip), moved verbatim; `audio`'s inline awk is *replaced* by it, which is behavior-preserving because the shared reader returns byte-identical values for `audio-tiers.yaml` (proven empirically before planning — `default_tier`, standard/premium `model` + `price_per_1k_chars` all match). `paid-media.sh` is sourced **below** each tool's `--help` `sed` line-range (the 163 gotcha: audio's help is `sed -n '3,30p'`, so source at the existing capacity-source point ~line 69; sound's help is `sed -n '3,22p'`, source at the existing capacity-source point ~line 61).

## Files to touch

**Create:**
- `.agent0/tools/lib/paid-media.sh` — the paid sub-kit. Four pure helpers: `pm_yaml_top <file> <key>` (top-level scalar, = sound's `ytop`), `pm_yaml_tier_field <file> <tier> <field>` (block-scan scalar w/ quote+comment strip, = sound's `yget`), `pm_has_fal_key` (predicate → 0/1), `pm_fal_key_state` (→ `set|unset`). Header documents: pure (no emit/no exit), companion to `capacity.sh`, propagated via the `lib|*.sh` glob.
- `.agent0/tests/capacity-kit/paid-golden.sh` — pins `sound`+`audio` `caps`/`doctor` byte-output under BOTH `FAL_KEY` unset AND set (the one state the ambient-env golden.sh doesn't pin). capture/verify modes, mirrors golden.sh.

**Modify:**
- `.agent0/tools/sound.sh` — source `lib/paid-media.sh` (beside the capacity source, below help range); `yget`→`pm_yaml_tier_field $TIERS`, `ytop`→`pm_yaml_top $TIERS`; the FAL_KEY presence check (`[ -n "${FAL_KEY:-}" ]` line 147) → `pm_has_fal_key`; caps `${FAL_KEY:+set}`/doctor `key_state` → `pm_fal_key_state`. Add the missing-kit guard line for paid-media.sh.
- `.agent0/tools/audio.sh` — source `lib/paid-media.sh` (beside capacity source ~line 69); inline `default_tier`/`model`/`price_per_1k_chars` awk → `pm_yaml_top`/`pm_yaml_tier_field`; FAL_KEY check (line 174) → `pm_has_fal_key`; caps/doctor FAL_KEY state → `pm_fal_key_state`. Add the missing-kit guard line.
- `.agent0/tests/capacity-kit/missing-kit-guard.sh` — add a case: a paid tool (copy `sound.sh` + `lib/capacity.sh` but NOT `paid-media.sh`) fails clean (exit 70, "missing kit library lib/paid-media.sh").
- `.agent0/context/rules/capacity-kit.md` — paid sub-kit section: "deferred follow-up" → "shipped (spec 164)"; name the four helpers + the honest scope (image/video out, reopen-trigger).
- `CLAUDE.md` — the Capacity kit section sentence "The paid-media sub-kit (…) is a deferred follow-up" → shipped, with the four-helper scope.
- `docs/specs/164-paid-media-kit/notes.md` — in-flight design memory (the empirical byte-identical proof; the `music_length_ms` left-as-is flag; the source-below-help gotcha re-applied).

**No change (already correct):**
- `.agent0/tests/capacity-kit/sync-propagation.sh` — already asserts `lib/paid-media.sh` propagates (163 added it preemptively). Re-run to confirm, don't edit.
- `.agent0/tools/sync-harness.sh` — the `.agent0/tools/lib|*.sh` glob already carries `paid-media.sh`. No edit.
- `.agent0/tests/capacity-kit/golden.sh` — already snapshots `sound`+`audio` caps/doctor/help/noargs/badflag; it is the before/after parity gate as-is. `paid-golden.sh` *adds* the FAL_KEY-state dimension it lacks.

## Alternatives considered

### Fold the helpers into `lib/capacity.sh` (no second lib)

Rejected because `capacity.sh` is the neutral local/free+paid kernel; `FAL_KEY` + a `*-tiers.yaml` oracle are a distinct paid cohesion cluster, and folding them pollutes the one abstraction the capacity family keeps clean. The sync glob already carries a second lib at zero plumbing cost. (Both meeting runtimes converged on separate independently.)

### Extract the cost-print, cost-gate, and a `pm_fal_run` wrapper too (the handoff's optimistic scope)

Rejected on the kill-gate measurement: cost formula differs four ways and tests pin the bytes; the `--confirm-cost-usd` gate is conflicting *policy* (`sound` hybrid-threshold vs `video` hard-confirm vs none); a fal passthrough can't carry the divergent `|| cap_fail` / `|| fail` tails. Extracting any of them would change behavior — forbidden.

### Pull `video` (and/or `image`) into this pass for completeness

Rejected because `image` uses a pipe-table not YAML (orthogonal), and `video` is a skill-dir tool whose migration introduces a *new* cross-dir `source .../tools/lib/...` dependency the 163 pass never validated — a separate portability/sync concern, not a deferred slice of the tools-dir extraction. Recorded as a named reopen-trigger with its own source/sync smoke requirement.

## Risks and unknowns

- **`audio` reader normalization changes implementation** — retired: proven byte-identical for `audio-tiers.yaml` before planning; the golden + `tests/audio/` suite are the standing proof. If any field ever diverged, the fallback is to keep `audio`'s inline awk local and migrate only its FAL_KEY state.
- **`--help` drift** (the 163 gotcha) — mitigated by sourcing `paid-media.sh` below each tool's help `sed` range, at the existing capacity-source line.
- **caps/doctor FAL_KEY-state output is env-dependent** — golden.sh captures only the ambient state; `paid-golden.sh` closes this by pinning both `FAL_KEY=` (unset) and `FAL_KEY=x` (set) explicitly.
- **Assumption:** `pm_yaml_top`/`pm_yaml_tier_field` reproduce `sound`'s `yget`/`ytop` semantics exactly (they are that code moved verbatim) — sound's migration is therefore byte-identical by construction; only audio's is a true substitution (proven).

## Research / citations

- `.agent0/meetings/paid-media-kit-honest-scope-2026-06-07T01-33-04Z/meeting.md` — decision-grade deliberation, 11-claim ledger (all anchored), minority report
- `docs/specs/163-capacity-kit/{notes,plan}.md` — the kernel-pass template + the source-below-help gotcha
- Empirical byte-identical check (this session) — shared reader vs `audio` inline awk over `audio-tiers.yaml`: `default_tier`, standard/premium `model` + `price_per_1k_chars` all matched
- `.agent0/tools/sound.sh:65-80,147` / `.agent0/tools/audio.sh:177-184,174` — the verbatim migration sources
