# 180 — debate-tier-source-of-truth

_Created 2026-06-09._

**Status:** shipped

**Closure:** 2026-06-09 — shipped (local, uncommitted at write time); 3-file doctrine reconciliation (`spec-driven.md`, `meeting.md`, `.agent0/skills/sdd/SKILL.md`); verify `doctor` 24 ok/0 broken (spec-verify 1/1, logged to notes.md); refined via a dogfooded decision-grade `/sdd debate` (blind commit/reveal + ledger 4/4 + minority report). Residual: consumer sync is a separate post-ship closeout (see § Post-ship closeout); the hard-fail-vs-degraded minority report is recorded for a future rule-of-three.

**UI impact:** none

## Intent

The doctrine "a `/sdd debate` is **always decision-grade**" is asserted in three places that have drifted into contradiction. `meeting.md:85-87` owns the spec-149 tier model (`light` vs `decision-grade`) and the decision-grade *mechanics*. `spec-driven.md:42` repeats "always decision-grade", and its workflow step 1.5 (`:50`) correctly scopes the *opt-in* axis (run a debate only on high-leverage specs). But `SKILL.md:170` undermines the doctrine: it keeps the legacy position-first Round 1 as a **discretionary fallback "when the blind flow isn't run"** — i.e. a non-decision-grade execution path you can simply choose. If a debate is *always* decision-grade, no such choosable lighter path can exist. This spec resolves the contradiction by assigning a single source of truth per concern: **`meeting.md` defines the *mechanics* of the decision-grade tier; SDD (`spec-driven.md`) decides that `/sdd debate` always *uses* that tier** (meeting.md does not own the SDD-specific mandate). It reclassifies the position-first scaffold as a *degraded mode* permitted **only after an attempted `meeting.sh` invocation actually fails** (binary missing / corrupted state / runtime cannot exec it) — an objective gate, never a discretionary choice. A Claude×Codex review (read-only, 2026-06-09; transcript under `.agent0/.runtime-state/codex-exec/20260609T141623Z-sdd-debate-tier/`) converged on this division; both runtimes rejected making the Claude `SKILL.md` the source because it is one runtime port among several (Codex/Cursor/Aider), and a port owning cross-runtime doctrine invites exactly the drift the rule layer exists to prevent.

## Acceptance criteria

- [x] **Scenario: SDD doctrine has one home**
  - **Given** the "`/sdd debate` is always decision-grade" claim
  - **When** a reader looks for the authoritative statement
  - **Then** `spec-driven.md` is the sole source of the *policy* (a debate, when run, is always the decision-grade tier), and it adds one sentence stating the legacy position-first Round 1 is degraded-mode-only and must be explicitly labelled when used

- [x] **Scenario: meeting.md owns mechanics, not the SDD mandate**
  - **Given** `meeting.md:85-87` describing the de-biased decision-grade protocol
  - **When** it references `/sdd debate`
  - **Then** it keeps ownership of the *mechanics* (blind commit/reveal, ledger, minority report), states it defines "the mechanics of the decision-grade tier", and points `/sdd debate`'s *mandatory tier* back to `spec-driven.md` — it must NOT assert the SDD-specific mandate "`/sdd debate` is always decision-grade" itself

- [x] **Scenario: SKILL.md defers and reclassifies the fallback**
  - **Given** `SKILL.md` Step 4 + the line at `:170`
  - **When** the skill describes Round 1
  - **Then** the blind Round 1 is stated as **required** for a normal `/sdd debate` (not merely "preferred"), and the position-first scaffold is renamed to a legacy/degraded path that defers to `spec-driven.md` for the policy

- [x] **Scenario: degraded mode has an objective gate (not discretion)**
  - **Given** a `/sdd debate` invocation
  - **When** the position-first path is taken
  - **Then** it is permitted **only after an attempted `meeting.sh commit`/`reveal` actually fails** (binary missing / corrupted state / runtime cannot exec it) — "I chose not to run blind" is never sufficient; the wording across all three files says **"attempted-and-failed"**, not "unavailable/blocked"

- [x] **Scenario: degraded state is verifier-visible with a fixed string**
  - **Given** a debate that fell back to position-first
  - **When** the transcript and synthesis are written
  - **Then** the transcript carries a literal `debate-degraded:` line AND the `## Synthesis` metadata carries a degraded marker (e.g. `**Resolution:** … (degraded — not full-confidence decision-grade)`), so the degraded state cannot be silently lost

- [x] **Scenario: no new lighter SDD tier is introduced**
  - **Given** the resolution
  - **When** reviewing the three files afterward
  - **Then** there is no `--tier light` (or equivalent) for `/sdd debate`; the `light` tier remains exclusive to exploratory `/meeting`

- [x] The edits are confined to the doctrine/procedure junctions (`spec-driven.md:42`, `meeting.md:87`, `SKILL.md` Step 4 / `:170`); the full protocol is not duplicated across files (each file references rather than restates the others' concern)
- [x] **No shared-surface contradiction:** after the edits, none of the runtime-neutral/shared surfaces (`spec-driven.md`, `meeting.md`, and the symlink-shared `SKILL.md`) still teaches position-first as a discretionary tier (per-runtime *prose* in non-Claude ports is out of scope — see Non-goals)
- [x] `bash .agent0/tools/doctor.sh` reports 0 broken after the edits (dogfood verify)

## Non-goals

- Changing the *opt-in* axis (when to run a debate at all) — step 1.5's "high-leverage specs only / skip mechanical / skip low-stakes" guidance stays as-is; this spec only touches the *rigor-when-run* axis.
- Re-engineering the `meeting.sh` mechanics, the blind commit/reveal flow, or the ledger/minority-report machinery — only the *pointers* and tier-ownership wording change.
- Adding a real lighter debate tier or any `--tier` flag to `/sdd debate`.
- Porting the wording change into non-Claude skill ports (Codex/Cursor/Aider own their ports); they conform to the rule, which is the point of choosing the rule as source.
- Touching the legacy-metadata inference logic (Step 2 fallbacks, Evals 9/10) — orthogonal to the tier contradiction.

## Open questions

- [x] **Hard-fail vs degraded-with-label** (Codex minority report): when `meeting.sh` is genuinely unavailable, is a *hard refusal* cleaner for decision-grade doctrine than any labelled degraded path? Even objectively gated, the degraded path still ships a lower-confidence artifact under the decision-grade banner. Lean: degraded-with-objective-gate (the attempted-and-failed gate makes it safe, and a hard-fail strands the user when `meeting.sh` is briefly broken) — but this is a live tension, not settled. **Rule-of-three check first:** has "meeting.sh unavailable" ever actually occurred? If never, the honest fix may be to *delete* position-first entirely rather than ceremonially label a path that never fires. Decide at plan time.
- [x] `debate-degraded:` emit mechanics: skill-emitted at fallback time (mirrors the existing `debate-advisory:`/`debate-blocked:` family) — confirm exact wording at plan time. (Its *existence* as a required marker is now an acceptance criterion, not an open question.)
- [x] Does the degraded path still attempt the ledger/minority-report where possible, or skip them entirely? Lean: attempt-where-possible (Codex's suggestion) — a partial de-bias beats none. Confirm wording at plan time.

## Context / references

- `.agent0/context/rules/spec-driven.md:42` + `:50` — the two debate mentions (doctrine + opt-in axis)
- `.agent0/context/rules/meeting.md:85-87` — spec-149 tier model (de-biased deliberation), the mechanics owner
- `.claude/skills/sdd/SKILL.md` Step 4 + `:170` — the position-first fallback wording (the contradiction site)
- Spec 149 — original de-biased deliberation / anti-confirmation-bias protocol
- Claude×Codex review transcript: `.agent0/.runtime-state/codex-exec/20260609T141623Z-sdd-debate-tier/last-message.md`
- Related: [[feedback_no_persona_role_prompting]] (the protocol is structural, not persona-based — preserve that framing)
- Debate artifact: `debate.md` — decision-grade dogfood (blind commit/reveal, ledger 4/4 supported, minority report preserved); both runtimes converged blind on the ownership split

## Post-ship closeout (not acceptance)

_Propagation is separate from the doctrine fix (Codex pushback c). After the three-file edit ships and `doctor` is green:_

- Sync the change to the 3 active consumers as harness-only (`spec-driven.md` + `meeting.md` are tracked rules; `SKILL.md` is symlink-shared), expecting no customization refusals.
