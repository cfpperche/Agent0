# 180 — debate-tier-source-of-truth — plan

_Drafted from `spec.md` on 2026-06-09. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Pure doctrine/wording reconciliation across three existing files — no new tool, no code. Assign one owner per concern and remove the only contradiction (the discretionary position-first fallback):

1. **`spec-driven.md` § debate (line 42)** — becomes the sole owner of the *policy* "a `/sdd debate`, when run, is always decision-grade." It references `meeting.md` for the *mechanics* (does not restate them) and adds the degraded-mode clause: position-first is allowed only after an attempted `meeting.sh` command *actually fails*, emits `debate-degraded:`, and a degraded debate cannot be cited as the decision-grade convergence gate.
2. **`meeting.md` § De-biased deliberation (line 87)** — keeps ownership of the decision-grade *mechanics* but stops asserting the SDD-specific mandate; it points the "`/sdd debate` always uses this tier" claim back to `spec-driven.md`. The `light` tier stays meeting-only.
3. **`.claude/skills/sdd/SKILL.md` Step 4 + line 170** — restructured so the blind commit/reveal flow is the **required** Round 1 procedure for a normal debate (not "preferred"), and the position-first scaffold is demoted to a degraded sub-case gated on an attempted-and-failed `meeting.sh`, emitting `debate-degraded:` and marking synthesis not full-confidence. Defers the policy to `spec-driven.md`.

Order: edit the two rules first (they are the source the skill defers to), then the skill, then validate with `doctor` and a shared-surface grep, then the post-ship consumer sync (separate from acceptance).

## Files to touch

**Modify:**
- `.agent0/context/rules/spec-driven.md` — line 42 doctrine sentence: SDD owns the policy; reference meeting.md for mechanics; add degraded-mode (attempted-and-failed gate + `debate-degraded:` + not-citable-as-gate).
- `.agent0/context/rules/meeting.md` — line 87: define "mechanics of the decision-grade tier"; point the `/sdd debate`-always-decision-grade *mandate* to `spec-driven.md`; do not assert it here.
- `.claude/skills/sdd/SKILL.md` — Step 4 heading + body + the anti-confirmation-bias paragraph (≈159-170): blind = required; position-first = degraded fallback only on attempted-and-failed `meeting.sh`; emit `debate-degraded:`; mark synthesis degraded; defer policy to spec-driven.md.

**Create / Delete:** none.

## Alternatives considered

### Hard-fail when `meeting.sh` is unavailable (delete position-first entirely)

Rejected — but it is the preserved **minority report** (Codex), not a dismissed idea. Rule-of-three check: `meeting.sh` *is* genuinely unavailable in real configs — macOS lacks `sha256sum` (ships `shasum`), and a consumer can sync the `sdd` skill without the `meeting` skill. A hard-fail would strand those users with no debate at all. Keeping a loud, objectively-gated degraded path that *cannot be cited as a decision-grade gate* preserves availability without the false-confidence Codex warned about. If a later rule-of-three shows `meeting.sh` is universally available (e.g. after a portability hardening of the script), deletion returns to the table.

### Make `meeting.md` own both the tier model and the SDD mandate ("meeting owns all tiers")

Rejected (Codex pushback a) — forces `meeting.md` to encode an SDD-specific mandate, recreating the cross-domain coupling this spec removes. SDD policy belongs with SDD.

### Make `SKILL.md` the source of truth (the original human inclination)

Rejected — both runtimes converged (blind) against it: a skill is one runtime port among several (Codex/Cursor/Aider); a port owning cross-runtime doctrine is the exact drift vector the rule layer exists to prevent.

## Risks and unknowns

- **Risk:** the `debate-degraded:` marker is wording-only in v1 (no validator surface), so a degraded debate that omits the line won't be mechanically caught. Accepted for v1 — the degraded path is rare and human-driven; a validator advisory is a possible later increment, not this spec.
- **Risk:** `SKILL.md` is symlink-shared across runtimes; the Step 4 rewrite must stay runtime-neutral (no Claude-only assumptions) so Codex/Cursor ports inherit it cleanly.
- **Unknown:** exact `debate-degraded:` emit point in the skill flow — resolved at implementation as "emit at the moment the attempted `meeting.sh` command fails and the skill falls back."

## Research / citations

- `debate.md` (this spec) — decision-grade dogfood: blind commit/reveal, ledger 4/4 `supported`, minority report preserved; both runtimes converged blind on the ownership split.
- `.agent0/context/rules/spec-driven.md:42,50`, `.agent0/context/rules/meeting.md:85-87`, `.claude/skills/sdd/SKILL.md:151-171` — read in place 2026-06-09.
- Spec 149 — de-biased deliberation origin; `[[feedback_no_persona_role_prompting]]` (structural, not persona); `[[feedback_speculative_observability]]` (rule-of-three applied to the hard-fail question).
