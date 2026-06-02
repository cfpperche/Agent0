# 140 — meeting-context-driven-speaker-selection — debate

_Created 2026-06-02._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-06-02

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time._

**Intent.** The `/meeting` skill (spec 136) forces a mandatory round-robin rotation (`meeting.sh` stores a `rotation` CSV; `append-turn`→`advance` moves `next_speaker` to the `csv_successor`), so every meeting is a `claude→codex→claude` ping-pong of essay-shaped turns — as rigid as `/sdd debate`, which `/meeting` was meant to be the looser sibling of. A real test meeting (AG-Antecipa, 5 turns) produced coordinated monologues, not a conversation. This spec makes turn flow **context-/addressing-driven**: `next_speaker` becomes a *suggestion derived from who the last turn addressed*, `--speaker` becomes the **normal** way to direct (not an out-of-order "override"), and turn *shape* loosens (directed question / answer / report-on-request / short reaction — not only "one substantive contribution"). Two invariants stay **unchanged on purpose**: single-writer-per-turn, and human-orchestration / one-turn-per-invocation (no auto-chain; autonomous looping remains the gated v2 of spec 138). This is exactly the "context-driven speaker selection" spec 138 named as "a later, separate question".

**Top 3 acceptance scenarios.**
1. *Directed question suggests its addressee as next speaker* — last turn ends "Codex, me traz o status cadastral…"; `/meeting turn` with no `--speaker` resolves default = the addressed participant, not a round-robin successor.
2. *`--speaker` directs freely without an "out-of-order" warning* — `/meeting turn --speaker <id>` for any roster member just takes the turn; no "(human override — out of rotation order)" label.
3. *Single-writer invariant unchanged* — peer resolved → invoked read-only via exec bridge, returns text only, **active runtime** appends; peer never edits `meeting.md`.

**Top 3 open questions (where I most want pushback).**
1. **Addressing derivation** — (a) appending runtime detects addressee at append time and writes `next_speaker`; (b) `meeting.sh` parses last turn body for a roster-id mention; (c) keep `next_speaker` purely advisory, derive nothing, rely on `--speaker`. Robustness vs. magic/brittleness.
2. **Fate of the `rotation` field** — remove entirely, or retain as an *optional fallback* used only when nothing is addressed and no `--speaker` given? Clean vs. deterministic-default + backward-compat.
3. **Default-speaker fallback** — when nothing addressed and no `--speaker`: error-and-ask, or deterministic default (convener / first roster model / last-non-speaker)?

**Where I want pushback most:** I lean toward option (c) for derivation (no parsing — `next_speaker` advisory, human directs via `--speaker`) because (a)/(b) reintroduce brittle NLP into a shell state machine and risk the very "magic" that made it feel automated. But I'm not confident that's *fluid enough* — the user's mental model is "Claude asks Codex → Codex naturally answers" without the human having to type `--speaker` each time. Push hard on whether advisory-only actually delivers the felt fluidity, or whether some lightweight derivation is worth the brittleness. Also pressure-test the turn-shape question: is a `--kind` hint useful structure or just rigidity by another name?

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

I think option (c) for **Addressing derivation** undercuts the spec's own first acceptance scenario. § Intent says "`next_speaker` becomes a suggestion derived from who the last turn addressed", and § Acceptance says `/meeting turn` with no `--speaker` resolves to the addressed participant. If the implementation derives nothing and relies on `--speaker`, the human still has to translate "Claude asked Codex" into `--speaker codex` every time. That removes the rotation warning, but it does not deliver the felt fluidity the spec claims.

The false choice is "parse arbitrary prose" vs "derive nothing". Use an explicit, deterministic addressing convention in the turn artifact: for example, the appending runtime may include a final machine-readable line like `Next: codex` / `Addressed-to: codex` / `@codex` from the roster. `meeting.sh` parses only that exact marker, never natural language like "Codex, me traz...". Then `append-turn` can set `next_speaker` to the marked roster id, and `/meeting turn` with no `--speaker` naturally fetches that participant. That gives the user's mental model without NLP brittleness. The marker also makes the acceptance mechanically testable.

The spec also needs to decide whether `next_speaker` is still legality or only a hint. Current `.agent0/skills/meeting/scripts/meeting.sh` makes it legality: `check` rejects a model speaker that differs from `next_speaker`, and `append-turn` always calls `advance`, whose `cmd_advance` sets `next_speaker` to `csv_successor(rotation, speaker)`. § Acceptance says `--speaker` should direct freely without an out-of-order warning, but it does not explicitly say `check <file> <speaker>` should become "roster membership only" or be replaced by a new `validate-speaker` command. That is not an implementation detail; it is the state-machine contract.

On **`rotation`**, I would not remove the field in v1 of this change. Existing transcripts and the template/header/rule body all expose it, and spec 138's friction signal was dogfooded on those transcripts. Removing it makes backward compatibility the hard part of a spec whose real goal is turn fluidity. Keep `rotation` as a legacy/fallback field for now, but demote its meaning: no longer "legal order", only "deterministic fallback order when no explicit address marker and no `--speaker` exist". If the name is too misleading, add a future migration to `fallback_order`; do not combine that migration with this behavioral change unless the spec wants to pay for transcript migration/tests.

The **default-speaker fallback** is currently too vague to verify: "a sensible default" is not a contract. I would choose this precedence explicitly: `--speaker` > explicit address marker from the last appended turn > existing `next_speaker` header value > first model in `rotation`/fallback order > convener if no model exists. Error-and-ask is safer philosophically, but it reintroduces friction on the exact path the spec is trying to smooth, and it behaves differently across runtimes. What matters is that the fallback is reported and deterministic, not that it is conversationally smart.

The optional **`--kind`** hint is useful only if it is metadata/prompt-shaping, not validation. § Acceptance says a turn may be "a focused question, a requested report, or a brief reaction", but the current skill prose still says "one substantive contribution, not a summary". If `--kind question|answer|report|reaction` exists, it should only be recorded in the turn header or fed into the peer prompt so a short question is acceptable. It must not become a required taxonomy or a content gate, or this spec recreates the rigidity it is trying to remove.

I am not convinced the two preserved invariants are untouched without sharper language. **Single-writer** is fine if peer turns remain read-only and the active runtime alone appends. **Human-orchestration/no-auto-chain** is more subtle: `/meeting turn` with no `--speaker` selecting Codex from an address marker means the human triggered exactly one turn, but did not manually choose the speaker on that invocation. That is acceptable if the selection is deterministic from transcript state and visible in the header; it is not acceptable if the active model infers the "right" speaker semantically. The line between this spec and spec 138 should be: deterministic transcript-addressed default is allowed; autonomous model speaker choice and multi-turn loops are not.

Weak acceptance points to tighten before planning:

- "ends addressing a specific participant" needs a precise syntax, otherwise it is not mechanically verifiable.
- "sensible default" needs a concrete precedence order.
- "accepted as-is" for short turns needs the skill prompt/rule wording changed, because the current core loop explicitly pushes "one substantive contribution".
- "Existing meetings ... remain readable and resumable" should name the expected behavior for legacy `rotation` headers, not leave it entirely to an open question.

The load-bearing open questions are (1) deterministic addressing syntax/state update, and (2) whether `rotation` is retained as fallback versus migrated away. The default fallback follows from those two; `--kind` is secondary and should not block the core design.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

Codex's central move resolves the design. I'll classify each point.

**1. Deterministic address marker instead of option (c) — ACCEPT (this is the design).** Codex is right that my option (c) contradicts the spec's own Scenario 1 and Intent ("derived from who the last turn addressed"): advisory-only forces the human to type `--speaker codex` every turn, which is not the felt fluidity claimed. And he's right that the real choice was never "NLP-parse prose" vs "derive nothing" — a third option dominates both: **an explicit machine-readable marker the appending runtime emits as the last line of a turn** (e.g. `Next: codex`), which `meeting.sh` parses by *exact roster-id match only*, never natural language. `append-turn` reads that marker and sets `next_speaker` to the marked id; `/meeting turn` with no `--speaker` then naturally fetches that participant. This is deterministic, mechanically testable, and gives the user's mental model ("Claude asks Codex → Codex answers") without brittleness. This becomes the answer to open question 1. (Bikeshed deferred: exact marker token — `Next:` vs `@id` vs `Addressed-to:`. I lean `Next: <id>` as an explicit trailing directive distinct from prose `@`-mentions; settle at plan time.)

**2. `next_speaker`: legality vs. hint is a state-machine contract, not an impl detail — ACCEPT.** Codex correctly flags that `check` currently *rejects* a model speaker ≠ `next_speaker` and `advance` always recomputes via `csv_successor`. The spec must state the new contract explicitly. New contract: **`next_speaker` is a derived default (from the marker), not legality.** `check` is demoted to **roster-membership only** (in-roster → ok; not-in-roster → refuse); rotation-order is no longer enforced. `advance`/`append-turn` set `next_speaker` from the marker (or the fallback precedence) instead of `csv_successor`. I'll add an acceptance criterion pinning this.

**3. Keep `rotation`, demote its meaning; don't bundle a rename migration — ACCEPT.** Agreed and this corrects my open question 2. Removing the field makes backward-compat the hard part of a spec whose real goal is fluidity, and spec 138's friction signal was dogfooded on transcripts that carry it. Decision: **retain `rotation` as a demoted *fallback order* field** (used only when no marker and no `--speaker`); its meaning changes from "legal order" to "deterministic fallback order". A future cosmetic rename to `fallback_order` is **deferred** to its own change (it would force transcript migration + test churn). This kills open question 2.

**4. Default-speaker precedence must be a concrete contract, not "sensible default" — ACCEPT.** Codex's precedence is right and I'll adopt it verbatim into the spec: **`--speaker` > explicit address marker in the last appended turn > existing `next_speaker` header value > first model in `rotation`/fallback order > convener.** The resolved speaker is always **reported**. This kills open question 3 and replaces the vague "a sensible default" criterion.

**5. `--kind` is metadata/prompt-shaping only, never a content gate — ACCEPT, and it stays secondary.** Agreed it must only be recorded in the turn header / fed to the peer prompt so a short turn is acceptable — never a required taxonomy. Crucially, Codex caught that the spec loosens turn shape in § Acceptance but the **skill prose still says "one substantive contribution, not a summary"** — that wording must actually be edited or the change is cosmetic. I'll add a criterion that the SKILL/rule wording is updated. `--kind` itself stays optional and non-blocking for the core design.

**6. Sharpen the two preserved invariants — ACCEPT, this is the load-bearing line.** Codex's framing is the cleanest statement of the spec-140 vs spec-138 boundary and I'll lift it into the spec verbatim: **a deterministic, transcript-addressed default speaker is allowed (the human still triggered exactly one turn, and the selection is mechanical + visible in the header); what stays forbidden is the *active model semantically inferring* the "right" next speaker, and any multi-turn auto-chain.** That line is what keeps this from quietly sliding into spec 138's gated autonomy. I'll make § Non-goals and the human-orchestration criterion say exactly this.

**7. Tighten the four weak acceptance points before planning — ACCEPT all four.** (a) "ends addressing a specific participant" → replace with the precise marker syntax from point 1; (b) "sensible default" → the precedence from point 4; (c) "accepted as-is" → add the explicit SKILL/rule wording-change criterion from point 5; (d) "remain readable and resumable" → name the legacy-`rotation` behavior (honored as fallback order; `state`/`friction`/`list` unaffected) instead of leaving it to an open question.

**Net:** I accept essentially the whole critique. All three of my open questions are now answered (marker / keep-rotation-as-fallback / explicit precedence), so the design is converging. Nothing deferred except the cosmetic `rotation`→`fallback_order` rename (its own future change) and the exact marker-token bikeshed (plan-time). Remaining genuine question for you before I synthesize: **do you agree the marker should be an explicit trailing directive (`Next: <id>`) rather than overloading prose `@id`-mentions?** If yes, I think we're at convergence.

---

## Round 2 — reviewing agent (critique)

I agree: use an explicit trailing directive, `Next: <id>`, not prose `@id` mentions. The parser should inspect only the last non-empty line of the just-appended turn, with exact shape `Next: <roster-id>`; `@codex`, "Codex, ..." and `Next:` examples elsewhere in the body are discussion text and never affect state. That avoids handle collisions, quoted examples, and accidental steering from normal prose.

For invalid or missing markers, make the contract precise:

- no trailing `Next:` line -> no addressed participant; use the accepted default precedence.
- trailing `Next: <id>` where `<id>` is not in `roster` -> append fails before body/header mutation, because the author emitted an explicit bad directive.
- trailing malformed `Next:` -> same failure; a final line that does not begin with `Next:` is simply no marker.

Leave the directive visible in `meeting.md` and in the rendered transcript for v1. It is part of the audit trail and makes the selected default explainable. A future presentation view may hide it cosmetically, but `meeting.sh` should not silently strip it from the canonical transcript.

Convergence check: I do not see anything wrong in the Round 2 accepts. Demoting `check` to roster-membership-only is the correct contract as long as comments/help/tests stop calling it "legal next speaker"; `rotation` as fallback-only keeps legacy compatibility; and the spec-140/spec-138 boundary is now crisp: deterministic transcript directive yes, semantic speaker choice or auto-chain no. The only synthesis guardrail I would add is roster-validation for every source of a default (`Next:`, existing `next_speaker`, fallback order, convener) so stale legacy header values are skipped or refused instead of becoming a hidden invalid default.

converged

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

Both agents converged in 2 rounds. The design crystallized around an **explicit trailing `Next: <id>` directive** (Codex's move that dissolved the initiator's false choice between NLP-parsing prose and deriving nothing), with `next_speaker` demoted from legality to a derived-and-reported default. All three original open questions are answered; nothing material remains unresolved.

**Proposed spec changes:**

- **§ Intent** — add one sentence naming the mechanism: the addressing signal is an explicit machine-readable trailing directive (`Next: <id>`) parsed by exact roster-id match, not natural-language parsing of the turn body.
- **§ Acceptance, Scenario 1** — replace the vague "ends addressing a specific participant (e.g. 'Codex, me traz…')" with the precise contract: the turn's **last non-empty line is `Next: codex`**; `/meeting turn` with no `--speaker` resolves the default to that roster id. Prose `@codex` / "Codex, …" mentions never affect state.
- **§ Acceptance — new scenario: marker validation contract** — (a) no trailing `Next:` line → no addressed participant, fall through to the default precedence; (b) trailing `Next: <id>` where `<id>` ∉ roster → `append-turn` **fails before any body/header mutation**; (c) a final line not beginning `Next:` is simply "no marker" (malformed = no marker).
- **§ Acceptance — new criterion: `check` contract demoted** — `meeting.sh check <file> <speaker>` validates **roster membership only**; rotation-order is no longer enforced and no "out of rotation order" warning is emitted. Comments/help text/tests must stop describing it as "legal next speaker".
- **§ Acceptance — new criterion: default-speaker precedence** — resolution order is exactly: `--speaker` > explicit `Next:` marker in the last appended turn > existing `next_speaker` header value > first model in `rotation` (fallback order) > convener. The resolved speaker is always **reported**, and **every source is roster-validated** — a stale/invalid value (e.g. a legacy `next_speaker` no longer in roster) is skipped, never used as a hidden default. Replaces the prior "a sensible default" criterion.
- **§ Acceptance — sharpen the turn-shape criterion** — the SKILL/rule prose that currently says "one substantive contribution, not a summary" must actually be **edited** to permit short directed turns (question / answer / report / reaction). `--kind` stays an *optional* metadata/prompt-shaping hint (recorded in the turn header or fed to the peer prompt), never a required taxonomy or content gate.
- **§ Acceptance — backward-compat criterion** — name the legacy behavior explicitly: existing `rotation:` headers are honored as **fallback order**, and `state` / `friction` / `list` are unaffected on old transcripts. The `Next:` directive is left **visible** in the canonical `meeting.md` transcript in v1 (part of the audit trail; cosmetic hiding deferred). Replaces "remain readable and resumable (open question)".
- **§ Non-goals** — add the crisp spec-140-vs-138 boundary line: a **deterministic, transcript-addressed default speaker is in scope** (human triggered exactly one turn; selection is mechanical + visible in the header); **out of scope** are the active model *semantically inferring* the "right" next speaker and any multi-turn auto-chain (those remain the gated v2 of spec 138).
- **§ Open questions** — mark all three resolved (marker / keep-rotation-as-fallback / explicit precedence). Record two **deferred, non-blocking** items: the cosmetic `rotation`→`fallback_order` rename (its own future change, to avoid transcript-migration churn here) and the exact marker-token bikeshed (settled as `Next: <id>` by this debate).

**Unresolved disagreements:** none — converged.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md`._

User accepted all proposed changes (2026-06-02). Applied to `spec.md`:

- **§ Intent** — added the trailing-`Next: <id>`-directive mechanism sentence (explicit marker, exact roster-id match, no NLP of prose).
- **§ Acceptance, Scenario 1** — rewritten from "ends addressing a specific participant" to the precise contract: last non-empty line `Next: codex`; prose mentions never affect state.
- **§ Acceptance** — added **Scenario: marker validation contract** (no marker → default precedence; non-roster id → append fails before mutation; malformed → no marker).
- **§ Acceptance, Scenario 3 (turn shape)** — sharpened: the "one substantive contribution, not a summary" prose must be edited; `--kind` is optional metadata only, never a gate.
- **§ Acceptance** — added **`check` contract demoted** criterion (roster-membership-only; no rotation-order; comments/help/tests stop saying "legal next speaker").
- **§ Acceptance** — added **default-speaker precedence** criterion (explicit order; every source roster-validated; resolved speaker reported). Removed the prior vague "a sensible default" criterion.
- **§ Acceptance** — rewrote the backward-compat criterion (legacy `rotation:` honored as fallback order; `state`/`friction`/`list` unaffected; `Next:` left visible in transcript).
- **§ Non-goals** — added the load-bearing spec-140↔138 boundary line (deterministic transcript directive in scope; semantic speaker inference + auto-chain out of scope).
- **§ Open questions** — marked all six resolved with their resolutions; recorded two deferred non-blocking items (`rotation`→`fallback_order` rename; cosmetic `Next:` hiding).
