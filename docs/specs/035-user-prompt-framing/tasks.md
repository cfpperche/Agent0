# 035 — user-prompt-framing — tasks

_Generated from `plan.md` on 2026-05-17. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Draft `.claude/rules/user-prompt-framing.md`** — write the rule file. Required sections, in order:
  1. **Summary box** — the 3-question check (TASK / CONTEXT / DONE) and the threshold table (0 → act; 1 → act with explicit inference; 2+ → ask). Place it at the very top so the agent can re-find the operative rule mid-conversation without scrolling.
  2. **Skip categories** — path + simple verb; explicit command; factual repo question; short continuation (≤10 words, no new substantives); greeting / meta. One concrete example per category.
  3. **Exploratory carve-out** — opinion-shaped prompts ("o que você acha de…", "como podemos…", "qual a melhor forma de…") route to the 2-3-sentence-recommendation pattern from CLAUDE.md, NOT the framing check. One concrete example.
  4. **Pronoun-resolution carve-out** — pronouns resolved by the immediately prior turn are scored against the resolved meaning, not the literal text. One concrete example.
  5. **Override marker** — `# OVERRIDE: <reason ≥10 chars>` shape, mirroring the delegation / governance / secrets-scan gates; the agent acknowledges the override in its response.
  6. **Worked examples** — 5-7 annotated prompts (mix of substantive / skip / exploratory / pronoun / override cases), each tagged with which questions fail and what the right agent response is.
  7. **Gotchas** — at minimum: the actor IS the agent being disciplined (no external enforcement possible by construction); calibration unknown for v1; rule decay if not cross-referenced.
  8. **Cross-references** — link to `delegation.md`, `spec-driven.md` § *When SDD applies*, `feedback_speculative_observability.md`, and spec 035.
  Target size ~3-4 KB.

- [x] 2. **Insert `## User prompt framing` section in `CLAUDE.md`** — between `## Delegation` (currently ending around line 35) and `## Test-driven development` (currently starting around line 37). Follow the existing capacity-section convention: 2-3 sentences describing the discipline + closing pointer "See `.claude/rules/user-prompt-framing.md`." No emoji. Keep total length comparable to the surrounding sections (~3-5 lines of prose).

- [x] 3. **Bump spec status** — change `**Status:** draft` to `**Status:** in-progress` in `docs/specs/035-user-prompt-framing/spec.md` once tasks 1-2 are complete and verification (task 4) passes. After dogfood window decision (per Open Question #2), bump to `**Status:** shipped` or follow-up spec NNN (if v2 hook is warranted).

## Verification

- [x] 4. **Verify rule file is structurally complete** — `grep -E '^## ' .claude/rules/user-prompt-framing.md` returns ≥6 section headers covering: summary/threshold, skip categories, exploratory, pronoun, override, worked examples, gotchas. File size between 2 and 10 KB (sanity bounds — too small means content missing, too large means it bloated past the "60-second readable" target applied to the summary box; the worked-examples table is the largest content block and is kept by design per spec Open Question #1).

- [x] 5. **Verify CLAUDE.md section placement** — `grep -n '^## ' CLAUDE.md` shows `## User prompt framing` between `## Delegation` and `## Test-driven development` (line numbers in that strict order). The section body contains the literal string `.claude/rules/user-prompt-framing.md`.

- [ ] 6. **Manual dogfood pass** — exercise the discipline against ≥3 of the spec's behavioral scenarios on the next 1-2 real-work prompts (substantive-with-2-ambiguities, skip-category, exploratory at minimum). The scenarios are by construction not unit-testable; passing means the agent in the next session, after reading the new rule via the cross-reference path, applies it correctly. If the agent forgets, that's the calibration signal for Open Question #2.

## Notes

- This spec ships rule-only — no hook, no tests, no audit. Do not scope-creep into building a `UserPromptSubmit` hook here; that's deferred until the dogfood window surfaces ≥3 missed-clarification sessions (see spec Open Question #2 + plan § *Risks and unknowns*).
- Fork propagation is automatic via `sync-harness.sh` (manifest already covers `.claude/rules/*.md`). No manifest edit needed; mention in PR body that the next sync will surface the rule in downstream forks.
- The conversation that destilled the heuristic (2026-05-17, sessions `hooks` → `prompt`) contains a worked in-the-wild instance: "sim" responding to a two-option `AskUserQuestion` was correctly flagged by the agent and re-asked. Reference this in the worked-examples section of the rule file as the "real-data" example.
- After bumping spec status to `in-progress`, the spec will appear in `/sdd list --in-flight` output — useful for tracking the dogfood window's open status.
