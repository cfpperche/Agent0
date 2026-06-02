# 140 — meeting-context-driven-speaker-selection

_Created 2026-06-02._

**Status:** shipped

## Intent

The `/meeting` skill (spec 136) enforces a mandatory **round-robin rotation**: `meeting.sh` stores a `rotation` CSV and `append-turn`→`advance` moves `next_speaker` to the *rotation successor* (`csv_successor`), so every meeting is forced into a `claude→codex→claude→codex` ping-pong of essay-shaped turns. In a real test meeting (the AG-Antecipa investigation, 5 turns) this produced a sequence of coordinated monologues rather than a conversation — the same rigidity as `/sdd debate`, which is exactly what `/meeting` was meant to be the looser sibling of. There is no way for one participant to ask another a short direct question and get *that* answered, to request a focused report, or for the human to drop a one-line reaction without consuming a rotation slot.

This spec makes turn flow **context-/addressing-driven** instead of round-robin: `next_speaker` becomes a *suggestion derived from who the last turn addressed*, not a mechanically-enforced order, and `--speaker` becomes the **normal** way to direct who speaks rather than an out-of-order "override". The addressing signal is an **explicit machine-readable trailing directive** — the last non-empty line of a turn may be `Next: <roster-id>`, parsed by exact roster-id match — never natural-language parsing of the turn body (prose `@codex` / "Codex, …" mentions never affect state). Turn *shape* is also loosened — a turn may be a directed question, an answer, a report-on-request, or a short reaction, not only "one substantive contribution". This is precisely the **"context-driven speaker selection"** that spec 138 (meeting-bounded-autopilot) explicitly named as "a later, separate question". Two invariants are **deliberately preserved unchanged**: (1) **single-writer-per-turn** — the active runtime is the sole writer, peers are fetched read-only through the exec bridges; and (2) **human-orchestration / one-turn-per-invocation** — there is no auto-chaining and no autonomous loop (that remains the gated v2 of spec 138). The fluidity comes only from *who* speaks next and *what shape* the turn takes, never from removing the human's hand on each turn.

## Acceptance criteria

- [ ] **Scenario: a trailing `Next:` directive suggests its addressee as next speaker**
  - **Given** an in-flight meeting where the last turn (by `claude`) has `Next: codex` as its **last non-empty line**
  - **When** the user runs `/meeting turn` with no `--speaker`
  - **Then** the resolved default speaker is the marked roster id (`codex`), not a round-robin successor, and exactly one turn is written. Prose `@codex` / "Codex, …" mentions elsewhere in the body do **not** affect state.

- [ ] **Scenario: marker validation contract**
  - **Given** a turn being appended
  - **When** it has **no** trailing `Next:` line → no addressed participant; the default precedence (below) resolves the speaker
  - **And When** it has a trailing `Next: <id>` where `<id>` ∉ roster → `append-turn` **fails before any body/header mutation** (nothing written, counter unchanged)
  - **And When** its final line does not begin with `Next:` (malformed) → treated as "no marker"

- [ ] **Scenario: `--speaker` directs freely without an "out-of-order" warning**
  - **Given** an in-flight meeting with any `next_speaker` suggestion
  - **When** the user runs `/meeting turn --speaker <id>` for any participant in the roster
  - **Then** that participant takes the turn and the skill does **not** label it "(human override — out of rotation order)" — directed speaking is the normal path, not an exception

- [ ] **Scenario: a turn may be a short directed exchange, not only an essay**
  - **Given** an in-flight meeting
  - **When** a participant takes a turn that is a focused question, a requested report, or a brief reaction
  - **Then** the appended turn is accepted as-is — the SKILL/rule prose that currently says "one substantive contribution, not a summary" is **edited** to permit short directed turns; any `--kind question|answer|report|reaction` is an *optional* metadata/prompt-shaping hint (recorded in the turn header or fed to the peer prompt), never a required taxonomy or content gate

- [ ] **`check` contract demoted:** `meeting.sh check <file> <speaker>` validates **roster membership only** — rotation-order is no longer enforced and no "out of rotation order" warning is emitted; comments/help text/tests stop describing it as "legal next speaker"
- [ ] **Default-speaker precedence** is exactly: `--speaker` > explicit `Next:` marker in the last appended turn > existing `next_speaker` header value > first model in `rotation` (fallback order) > convener. The resolved speaker is always **reported**, and **every source is roster-validated** — a stale/invalid value (e.g. a legacy `next_speaker` no longer in roster) is skipped, never used as a hidden default

- [ ] **Scenario: single-writer invariant is unchanged**
  - **Given** `next_speaker`/`--speaker` resolves to a peer model
  - **When** that peer's turn is taken
  - **Then** the peer is invoked read-only through its exec bridge, returns turn text only, and the **active runtime** appends it — the peer never edits `meeting.md` (identical to spec 136 behavior)

- [ ] **Scenario: human-orchestration / no auto-chain is unchanged**
  - **Given** any meeting state
  - **When** `/meeting turn` is invoked
  - **Then** exactly one turn is written and the skill stops — it never chains a second turn or selects speakers autonomously (spec 138 autopilot stays deferred and untouched)

- [ ] `meeting.sh state`/`friction` continue to emit the autopilot-friction signal (`model_turns` / `max_consecutive_model_turns` / `current_model_streak`) so spec 138's demand test stays measurable
- [ ] **Backward compatibility:** existing `rotation:` headers are honored as **fallback order**, and `state` / `friction` / `list` are unaffected on old transcripts (e.g. the AG-Antecipa meeting). The `Next:` directive is left **visible** in the canonical `meeting.md` transcript in v1 (part of the audit trail; `meeting.sh` does not silently strip it — cosmetic hiding deferred)

## Non-goals

- **Autonomous LLM-to-LLM looping / auto-chaining turns.** Stays the gated v2 of spec 138; this spec keeps human-orchestration exactly as today.
- **LLM speaker-selection authority** (a model deciding who speaks next on its own). The *suggestion* is derived mechanically from addressing; the *decision* stays with the human via `--speaker`.
- **The spec-140 ↔ spec-138 boundary (load-bearing):** a **deterministic, transcript-addressed default speaker is in scope** — the human triggered exactly one turn, and the selection is mechanical (exact `Next: <id>` match) and visible in the header. **Out of scope** are the active model *semantically inferring* the "right" next speaker, and any multi-turn auto-chain; those remain the gated v2 of spec 138. Deterministic transcript directive → yes; semantic speaker choice or auto-loop → no.
- **Standing personas / role-play identities.** Participants remain distinct model runtimes; a per-turn contribution brief is fine, a persistent persona is not (unchanged from spec 136).
- **Changing the transport** — exec bridges, read-only peer invocation, git-tracked transcript location, and the state-vs-content split all stay as in spec 136.
- **A broker/daemon or any new persistent infra.**

## Open questions

_All resolved in the `/sdd debate` with Codex CLI (see `debate.md`, converged in 2 rounds)._

- [x] **Addressing derivation** → RESOLVED: explicit trailing `Next: <roster-id>` directive on the last non-empty line, parsed by exact match only (never NLP of prose). Dissolves the false choice between prose-parsing and deriving-nothing.
- [x] **Fate of the `rotation` field** → RESOLVED: retained, demoted from "legal order" to "fallback order"; not removed (removal would make backward-compat the hard part of a fluidity change).
- [x] **`check` semantics** → RESOLVED: demoted to roster-membership-only; rotation-order no longer enforced.
- [x] **Turn-shape signaling** → RESOLVED: prose wording is edited to permit short turns; `--kind` is optional metadata/prompt-shaping only, never a content gate.
- [x] **Backward compatibility** → RESOLVED: legacy `rotation:` honored as fallback order; `state`/`friction`/`list` unaffected; `Next:` left visible in the transcript.
- [x] **Default-speaker fallback** → RESOLVED: explicit precedence (`--speaker` > `Next:` marker > existing `next_speaker` > first `rotation` model > convener), every source roster-validated, resolved speaker reported.

**Deferred (non-blocking, not part of this spec):**
- Cosmetic rename `rotation` → `fallback_order` — its own future change, to avoid transcript-migration churn here.
- Cosmetic hiding of the `Next:` directive in a future presentation/rendered view (canonical transcript keeps it).

## Context / references

- `.agent0/context/rules/meeting.md` — spec 136 rule body; § "Turn transport & single-writer rule", § "State vs content split", § "Autopilot demand test".
- `.agent0/skills/meeting/SKILL.md` — current loop (the "🔓 Medium freedom: the v1 core loop" turn subcommand; the rotation + `--speaker` override prose).
- `.agent0/skills/meeting/scripts/meeting.sh` — `cmd_advance` / `csv_successor` (the round-robin mechanism this spec replaces); `init --rotation` requirement.
- `docs/specs/136-meeting/` — base meeting spec.
- `docs/specs/138-meeting-bounded-autopilot/spec.md` — explicitly defers "context-driven speaker selection" as "a later, separate question" (this spec) and keeps the autonomous loop gated.
- `.agent0/meetings/investigacao-empresa-agantecipa-2026-06-02T19-42-49Z/meeting.md` — the test meeting that surfaced the rigidity (5 essay-shaped round-robin turns).
- Memory: `feedback_anthill_port_smart_not_rigid` — "make the process smarter and less rigid"; same anti-rigidity lesson.
