# 035 — user-prompt-framing

_Created 2026-05-17._

**Status:** shipped

## Intent

The delegation gate (spec 002) enforces a 5-field handoff on every `Agent` dispatch because under-specified briefs cause sub-agent drift. The same risk exists one level up — at the user→main-agent boundary — but currently goes ungoverned: the main agent accepts whatever shape the user submits, including vague prompts ("isso", "melhora aquilo", "faz como o outro"), and either invents a framing silently or charges ahead and produces drift. This spec introduces a **behavioral discipline** for the main agent: on receipt of a non-trivial prompt, internally map the user's request onto the 5-field shape (focusing on TASK / CONTEXT / DONE), and if 2+ fields are ambiguous, clarify with the user *before* acting. Rule-only in v1, no hook — observe drift first per the speculative-observability discipline; build enforcement only if a real demand pattern emerges.

## Acceptance criteria

- [ ] **Scenario: substantive prompt with multiple ambiguities triggers clarification**
  - **Given** the user submits a substantive prompt (action-shaped, not exploratory, not in a skip category)
  - **When** ≥2 of TASK / CONTEXT / DONE are unclear after the agent's mental mapping
  - **Then** the agent asks the user (ideally via `AskUserQuestion`) before performing any work-shaped action

- [ ] **Scenario: single ambiguity is handled by explicit inference**
  - **Given** the user submits a substantive prompt
  - **When** exactly 1 of TASK / CONTEXT / DONE is unclear
  - **Then** the agent proceeds with the work but names the inference in one line ("assuming X because Y") before or during the first acting tool call, so the user can correct mid-stream

- [ ] **Scenario: skip-category prompt receives immediate action**
  - **Given** the user submits a prompt matching a skip category (path + simple verb, explicit command, factual repo question, short continuation, greeting / meta)
  - **When** the agent processes the prompt
  - **Then** the agent acts without invoking the 3-question check or asking clarification questions

- [ ] **Scenario: exploratory prompt receives a recommendation, not framing**
  - **Given** the user submits an opinion-shaped prompt ("o que você acha de…", "como podemos…", "qual a melhor forma de…")
  - **When** the agent recognises the exploratory shape
  - **Then** the agent responds in 2-3 sentences with a recommendation + main tradeoff (per CLAUDE.md exploratory guidance), without triggering the framing check or starting implementation

- [ ] **Scenario: pronoun resolved by the immediately prior turn does not count as ambiguity**
  - **Given** the user's prompt contains a pronoun ("isso", "esse arquivo", "de novo")
  - **And** the pronoun has a clear antecedent in the immediately prior turn (last assistant artifact / tool result)
  - **When** the agent runs the 3-question check
  - **Then** the pronoun is treated as resolved — TASK / CONTEXT are scored against the resolved meaning, not the literal text

- [ ] **Scenario: explicit override bypasses the framing check**
  - **Given** the user's prompt contains a line `# OVERRIDE: <reason ≥10 chars>` (same shape as the delegation / governance / secrets-scan gates)
  - **When** the agent processes the prompt
  - **Then** the 3-question check is skipped and the agent proceeds with whatever inference it has; the override reason is acknowledged in the response

- [ ] `.claude/rules/user-prompt-framing.md` exists, documents the 3-question rule, the threshold (0 → act, 1 → act with explicit inference, 2+ → ask), the skip categories, the exploratory category, the pronoun-resolution carve-out, and the override marker

- [ ] `CLAUDE.md` gains a `## User prompt framing` section pointing at the rule, placed alongside the existing capacity sections (before `## Compact Instructions`)

## Non-goals

- **No `UserPromptSubmit` hook in v1.** The capacity ships rule-only — no automated enforcement, no `additionalContext` injection, no audit log. Adding observability before a demand pattern exists is the failure mode the `feedback_speculative_observability` memory exists to prevent.
- **No prompt-rephrasing-back-to-user.** The 5-field mapping happens internally in the agent's working memory; the agent does not echo "Aqui está seu prompt reformatado:" back at the user. That would be friction without information.
- **Not a replacement for `/sdd refine` or `/brainstorm`.** Refine is heavyweight discovery that produces `spec.md`; brainstorm is divergent ideation. This discipline is the always-on lighter layer that decides whether either of those heavier tools should be invoked in the first place.
- **No new slash command.** The discipline runs on every turn; introducing `/frame` would invert the default (opt-in instead of default-on) and miss the cases where the user doesn't know they should have framed.
- **No enforcement that the agent cannot disable.** Rules are advisory by design — the main agent is the one being disciplined, and the actor cannot be its own external verifier. The override marker is documentation, not the only escape.

## Open questions

- [ ] Should the rule include a small worked-example table (5-10 prompts annotated with which questions fail and what the right response is)? Argues for: agent calibration improves with concrete examples vs abstract rules. Argues against: example tables rot with practice and compete with the rule prose for authority.
- [ ] How long is the dogfood window before deciding whether to add a `UserPromptSubmit` hook? Suggested default: 3 weeks of active Agent0 work. Decision criterion: count of sessions where the agent forgot to apply the discipline on a prompt that retroactively should have triggered it. If ≥3 → spec a hook. If 0-2 → rule is sufficient.
- [ ] Does the discipline apply to the first user message of a session differently than mid-session? First message has less context to resolve pronouns against; mid-session has prior turns. Current draft treats them the same; revisit if drift is concentrated at session start.
- [ ] Should this discipline ship to forks via sync-harness (since it's a `.claude/rules/` file, the manifest will pick it up automatically), or should it stay Agent0-only? Default answer: ship — the discipline is universally useful and the override marker handles fork-specific opt-out — but flag for explicit confirmation before merging.

## Context / references

- `.claude/rules/delegation.md` — the upstream 5-field handoff that this spec mirrors at the user→main boundary
- `docs/specs/002-delegation/` — original design of the delegation gate and the rationale for verifiable outcomes
- `.claude/rules/spec-driven.md` § *When SDD applies* — overlaps with "substantive prompt" detection; some triggers are shared (3+ files, vague request needing decomposition)
- `.claude/skills/sdd/SKILL.md` § *Subcommand: `refine`* — heavyweight discovery counterpart; this discipline decides when to invoke it
- `.claude/memory/MEMORY.md` → `feedback_speculative_observability.md` — the rule-of-three demand-test that gates the v1 hook decision
- `CLAUDE.md` — exploratory-prompt guidance ("respond in 2-3 sentences with a recommendation and the main tradeoff") that the exploratory carve-out preserves
- This conversation (2026-05-17) — the heuristic was destilled live before scaffolding; the in-conversation example of "sim" being ambiguous after a two-option question is itself a worked instance the rule should handle
