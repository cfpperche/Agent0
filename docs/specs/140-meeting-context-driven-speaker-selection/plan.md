# 140 — meeting-context-driven-speaker-selection — plan

_Drafted from `spec.md` on 2026-06-02. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Replace the mandatory round-robin with an **explicit, deterministic addressing marker**, keeping `meeting.sh` as the single state owner and preserving both load-bearing invariants (single-writer-per-turn; human-orchestration / one-turn-per-invocation). The mechanism: the last non-empty line of a turn body MAY be `Next: <roster-id>`. `meeting.sh` parses **only** that exact shape (never NLP of prose); the marker, when valid, becomes the new `next_speaker`. `next_speaker` is thereby demoted from *enforced legality* to a *derived, reported default*.

Concretely, four moving parts change. (1) **`meeting.sh`** gains marker parsing in `append-turn` (fail-before-write on a bad marker), `advance` stops auto-rotating via `csv_successor` and instead sets `next_speaker` only from an explicit `--next <id>` (else leaves it unchanged), `check` is demoted to roster-membership-only, and a new `resolve-speaker` subcommand makes the default-speaker precedence mechanically testable. `rotation` is retained as a *fallback order* field (used only when `next_speaker` is invalid/empty), not removed — so old transcripts and the spec-138 friction signal keep working. (2) **`SKILL.md`** turn loop calls `resolve-speaker`, drops the "(human override — out of rotation order)" labeling, documents the `Next:` marker, and loosens "one substantive contribution" to permit short directed turns; `--kind` is an optional, non-gating hint. (3) **`meeting.md`** rule body documents the addressing mechanism, the demoted `next_speaker`/`check`, the `rotation`-as-fallback semantics, and the crisp spec-140↔138 boundary. (4) **`turn-prompt.md`** tells peers they may end a turn with a `Next: <id>` line and may take a short directed turn. Tests are written/updated first (TDD): the existing `02-check-legality` and `03-advance-roundrobin` change to the new contract, and a new test covers markers + `resolve-speaker`.

## Files to touch

**Modify:**
- `.agent0/skills/meeting/scripts/meeting.sh` — add `_marker_from_body` helper; marker parse + fail-before-write in `cmd_append_turn`; `--next <id>` in `cmd_advance` and remove the `csv_successor` round-robin branch (and the now-dead `csv_successor` fn); demote `cmd_check` to roster-membership-only; add `cmd_resolve_speaker` + dispatch entry; update header comment block (drop "round-robin"/"legal" language, document marker + fallback order).
- `.agent0/skills/meeting/SKILL.md` — `turn` subcommand: resolve speaker via `resolve-speaker`, drop the out-of-order override label, document the `Next: <id>` marker as the addressing mechanism, loosen turn-shape wording + optional `--kind`; `start` + `state` + Notes: rotation = fallback order; add `resolve-speaker` to the helper subcommand list; update Eval scenarios that assert round-robin / override-label behavior.
- `.agent0/context/rules/meeting.md` — rewrite § "Turn transport & single-writer rule" and § "State vs content split" for marker-driven selection; add a short § "Addressing & speaker selection" (marker syntax, precedence, `check`/`rotation` demotion); add the spec-140↔138 boundary line; keep § "Autopilot demand test" intact.
- `.agent0/skills/meeting/references/turn-prompt.md` — allow a short directed turn; document the optional trailing `Next: <id>` line.
- `.agent0/skills/meeting/templates/meeting.md.tmpl` — front-matter prose: `rotation` is the *fallback order* (not "round-robin … legal by default"); `next_speaker` is the derived default.
- `.agent0/tests/meeting/02-check-legality.sh` — rewrite to the roster-membership-only contract (in-roster → exit 0; unknown → exit 3; no "next legal speaker" message).
- `.agent0/tests/meeting/03-advance-roundrobin.sh` — rewrite (rename intent): `advance --speaker X` with no `--next` leaves `next_speaker` unchanged; `advance --speaker X --next Y` sets it to Y; unknown `--next` id refused with no mutation.

**Create:**
- `.agent0/tests/meeting/08-addressing-marker.sh` — marker happy-path (body ending `Next: codex` sets next_speaker=codex), invalid marker (non-roster id) fails before write (counter unchanged, nothing appended), no-marker leaves next_speaker unchanged, malformed final line treated as no marker, marker line left visible in transcript; plus `resolve-speaker` precedence (`--speaker` wins; falls back through next_speaker → first rotation model → convener; stale/non-roster next_speaker skipped). Wire into `run-all.sh`.

## Alternatives considered

### Option (c) from the spec — `next_speaker` purely advisory, derive nothing, rely on `--speaker`

Rejected in the `/sdd debate` (Round 1, accepted in Round 2): it contradicts the spec's own Scenario 1 and Intent and forces the human to type `--speaker` every turn, so it does not deliver the felt fluidity ("Claude asks Codex → Codex answers"). The explicit `Next:` marker gives that fluidity deterministically without NLP.

### Natural-language parsing of the turn body for an addressee (option b)

Rejected: brittle (NLP in a shell state machine), non-deterministic, and would collide with quoted examples / `@`-mentions in discussion prose. The exact-shape trailing marker is the testable, collision-free middle path.

### Remove the `rotation` field entirely

Rejected: removal makes backward-compat the hard part of a fluidity change — existing transcripts, the template, the rule body, and spec-138's friction signal all reference it. Demoting it to a fallback-order field is cheaper and safe; a cosmetic rename to `fallback_order` is deferred to its own change.

## Risks and unknowns

- **Test churn is intentional, not a regression.** `02` and `03` encode the *old* round-robin contract; rewriting them is the red→green of this change, not breakage. Risk: a reviewer mistakes the rewrite for deleting coverage — mitigated by the new `08` test adding coverage for the new contract.
- **Marker edge cases.** Empty (`Next:`), multi-token (`Next: codex please`), or non-roster (`Next: gemini`) trailing lines are all "begins with `Next:` → explicit directive → fail-before-write"; only a final line *not* beginning with `Next:` is "no marker". Must be tested explicitly so the boundary is unambiguous.
- **`resolve-speaker` is new surface the SKILL depends on.** If the SKILL keeps reading `next_speaker` directly instead of calling `resolve-speaker`, the precedence/roster-validation won't actually run. Mitigation: the SKILL turn step must call `resolve-speaker`.
- **Stale legacy `next_speaker`.** Old transcripts may carry a `next_speaker` that is fine; none should be out-of-roster, but `resolve-speaker` roster-validates anyway and falls back, so a malformed legacy header degrades gracefully rather than producing an invalid default.

## Research / citations

- `docs/specs/140-meeting-context-driven-speaker-selection/debate.md` — the cross-model design debate (converged); source of the marker design, precedence order, and the 140↔138 boundary.
- `.agent0/skills/meeting/scripts/meeting.sh` — current `cmd_advance` / `cmd_check` / `cmd_append_turn` / `csv_successor` (the round-robin mechanism being replaced).
- `docs/specs/138-meeting-bounded-autopilot/spec.md` — names "context-driven speaker selection" as the separate question this spec answers; § Demand test friction signal that must keep working.
- `.agent0/context/rules/tdd.md` — red→green discipline (tests in the same diff).
