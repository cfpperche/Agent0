# 164 — paid-media-kit — notes

_Created 2026-06-07._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building**._

## Design decisions

### 2026-06-07 — parent — Readers are sound's `yget`/`ytop` moved verbatim; `sound` migration is byte-identical by construction
`pm_yaml_top`/`pm_yaml_tier_field` are sound's old `ytop`/`yget` bodies, parameterized only over `$TIERS` (file). `sound` keeps 1-line local binders (`yget(){ pm_yaml_tier_field "$TIERS" "$1" "$2"; }`) so its call sites are untouched and the awk body is identical → byte-identical output proven by golden. Only `audio`'s reader is a true *substitution* (its inline per-field awk → the shared readers).

### 2026-06-07 — parent — The one real risk (audio reader normalization) was retired with evidence BEFORE writing code
The meeting flagged: replacing audio's inline awk is behavior-preserving only if the shared reader returns byte-identical values for `audio-tiers.yaml`. Verified empirically pre-plan: `default_tier`, standard/premium `model` + `price_per_1k_chars` all matched exactly. Subtleties that could have differed but didn't: audio's block-exit `/^  [a-z]/` vs the shared `/^  [^ ]/` (equivalent for the lowercase tier names actually present), and audio's `default_tier` not stripping trailing comments (none present). The audio suite + golden are the standing proof.

### 2026-06-07 — parent — Helpers are PURE (no emit / no exit); FAL_KEY stays a predicate, not a require
The kernel pass extracted `cap_fail`; the paid pass deliberately did NOT extract a `pm_require_fal_key`. The tools' failure contracts diverge (`sound` compact `cap_fail`, `audio` local pretty `fail`), so a helper that fails internally can't serve both. Extracted only `pm_has_fal_key` (predicate) + `pm_fal_key_state` (`set|unset`); each tool keeps its own `|| cap_fail` / `|| fail` tail. caps JSON stays byte-identical (the `${FAL_KEY:+set}`→boolean idiom became `--argjson fk "$(pm_has_fal_key && echo true || echo false)"`).

## Deviations

### 2026-06-07 — parent — Made `golden.sh` FAL_KEY-hermetic (a 163-artifact change, surfaced by 164)
Codex's adversarial review caught that `golden.sh verify` inherited ambient `FAL_KEY` — so the committed baselines (captured by 163's author with FAL_KEY *set*) and a no-key runner disagreed. Fix (in scope — 164 is the FAL_KEY-state pass): `run_one` now runs each fixture under `env -u FAL_KEY`, pinning the hermetic *unset* state; the *set* state is pinned separately by the new `paid-golden.sh`. Re-captured the baselines (now unset-state) and proved `verify` passes under BOTH ambient `FAL_KEY=set` and unset.

## Tradeoffs

### 2026-06-07 — parent — Local 1-line reader binders in `sound` instead of swapping all call sites
Kept `sound`'s `yget`/`ytop` as 1-line wrappers binding `$TIERS` rather than rewriting every `yget "$TIER" model` call to `pm_yaml_tier_field "$TIERS" "$TIER" model`. Cost: a 1-line indirection survives. Benefit: zero call-site churn → the duplicated awk *body* is gone (the actual goal) while the migration stays trivially byte-identical. Worth it.

### 2026-06-07 — parent — Codex as build peer via adversarial review, not /squad ping-pong
Founder directed "you and codex do the sdd and implementation." SDD was genuinely collaborative (decision-grade meeting, blind openings). For the tiny, well-bounded implementation, used Codex for an adversarial diff review (verdict FIX-FIRST → 2 findings, both fixed + proven) rather than the autonomous squad loop — faster for this size, and the golden+suite gate is the external closer regardless of who typed it (the 163 precedent).

## Open questions

_None outstanding — all 4 spec OQs were resolved in the meeting (see spec.md)._

---

**Gotchas worth remembering:**
- **`--help` source-below-range (163 redux):** sound's help is `sed -n '3,22p'`, audio's `sed -n '3,30p'`. The new `source lib/paid-media.sh` was inserted at the existing capacity-source line (sound ~62, audio ~70), below both ranges — no `--help` drift. Verified by golden.
- **Don't "fix" model-body semantics mid-refactor:** `sound` still sends `DURATION` under the oracle's `duration_field`; the unverified `music_length_ms` premium note (`sound-tiers.yaml`) is left exactly as-is. Changing units during a behavior-preserving extraction is out of bounds — it stays a possible future bug, untouched here.

**Build outcome:** `lib/paid-media.sh` (4 pure helpers) + `tests/capacity-kit/paid-golden.sh` created; `sound`/`audio` migrated; `golden.sh` made FAL_KEY-hermetic; `missing-kit-guard.sh` extended (paid-media absence → exit 70); `sync-propagation.sh` already covered the lib. **Gate GREEN:** golden verify (hermetic, both ambient states) + paid-golden verify + sound suite (9×N) + audio suite + sync-propagation (4/4) + missing-kit-guard (2/2) + `bash -n` (3 scripts + 2 tests) + doctor (22 ok/0/0). Zero behavior change. Decision-grade meeting: `.agent0/meetings/paid-media-kit-honest-scope-2026-06-07T01-33-04Z/`.
