# 136 — meeting — tasks

_Generated from `plan.md` on 2026-06-02. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create `.agent0/skills/meeting/` dir tree (`scripts/`, `templates/`, `references/`).
- [x] 2. Write `templates/meeting.md.tmpl` — YAML front-matter header (meeting, topic, created, convener, mode, participants[], turn_counter, next_speaker, synthesis) + body skeleton (`# Meeting`, turn-section convention, `## Synthesis`).
- [x] 3. Write `scripts/meeting.sh` with subcommands: `init` (scaffold from template + fill header), `state` (print parsed header as key=value), `next` (print next_speaker), `check <file> <speaker>` (exit 0 iff speaker is a registered participant and == next_speaker), `advance <file> --speaker <id> [--synthesis <status>]` (increment turn_counter, round-robin next_speaker over non-human participants), `append-turn <file> --speaker <id> --body-file <p> [--sources-file <p>]` (append turn section then advance; fail before mutating header on error).
- [x] 4. Write `.agent0/tests/meeting/_lib.sh` (ok/no/assert helpers, mirrors codex-exec-skill) + `run-all.sh`.
- [x] 5. Write tests `01-init.sh` … `06-synthesis-status.sh` covering: init scaffolds valid header; check accepts legal / rejects illegal speaker; advance round-robins and skips human; append-turn writes body+Sources and advances atomically; state readout is parseable by a "fresh" reader; synthesis status transitions (pending→written→accepted/rejected).
- [x] 6. Make `meeting.sh` and all test scripts executable (`chmod +x`); iterate red→green until `run-all.sh` is all-pass.
- [x] 7. Write `references/turn-prompt.md` — fill-in prompt template for invoking a peer participant via the exec bridge (topic + transcript-so-far + this-turn instruction + optional `--web`/`Sources:` requirement + "return turn text only, do not edit files").
- [x] 8. Write `SKILL.md` — frontmatter (name, description, argument-hint, license, compatibility cc-native canonical text, metadata.agent0-portability-tier=cc-native, version "0.1"); body: argument parsing; `start "<topic>" [--with <ids>]`; `turn [--speaker <id>] [--web]`; `synthesize`; the self-identity peer-vs-local decision; the human gates (synthesize accept/redirect/end; graduate to `/sdd refine` as seed context); unknown-subcommand usage; `## Notes` consumer-extension section. Keep self-contained (no spec-dir paths / spec numbers / memory pointers).
- [x] 9. Create discovery symlinks: `.claude/skills/meeting` and `.agents/skills/meeting` → `../../.agent0/skills/meeting`.
- [x] 10. Write `.agent0/context/rules/meeting.md` — overview + when-to-use-vs (`/brainstorm`, `/sdd debate`); header schema; workflow contract; transport + single-writer semantics; research-backed turns; graduation; files; discipline; gotchas; cross-references; `## Notes`. Self-contained.
- [x] 11. Add `## Meeting` section to `CLAUDE.md` (inside managed block, between Product skill and Routines) and the parallel section to `AGENTS.md` (inside its managed block).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] V1. `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/meeting` exits 0 (maps to "SKILL.md passes agentskills.io spec").
- [x] V2. `bash .agent0/tests/meeting/run-all.sh` is all-pass (maps to state-machine criteria: turn legality from header, single-writer append, round-robin advance, synthesis status).
- [x] V3. End-to-end smoke: `meeting.sh init` a temp meeting, `check` legal+illegal speakers, `append-turn` one turn with a `Sources:` block, `state` shows incremented counter + advanced next_speaker — mirrors the spec scenarios "convene", "fresh runtime resolves legality from header", "research-backed turn cites sources".
- [x] V4. Symlinks resolve: `.claude/skills/meeting/SKILL.md` and `.agents/skills/meeting/SKILL.md` both readable.
- [x] V5. `CLAUDE.md` + `AGENTS.md` each contain a `## Meeting` line inside the managed block; `.agent0/context/rules/meeting.md` exists (maps to "documented in a rule + CLAUDE.md index block").
- [x] V6. Grep confirms no new persistent broker/daemon/API/MCP dependency introduced (maps to the no-new-infra criterion).
- [x] V7. Check off every satisfiable box in `spec.md` § Acceptance criteria; for criteria that are runtime-conversational (the LLM-authored turn body, the graduate-to-refine seam), confirm the SKILL.md body specifies the behavior verifiably.

## Notes

- LLM-as-orchestrator scenario is intentionally NOT implemented in v1 (deferred per spec Non-goals); V7 treats it as out-of-scope, not a gap.
- Dogfood roadmap (the goal's final deliverable) is produced after V1–V7 pass.
