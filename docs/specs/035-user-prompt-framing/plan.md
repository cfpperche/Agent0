# 035 — user-prompt-framing — plan

_Drafted from `spec.md` on 2026-05-17. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship the discipline as a single rule file (`.claude/rules/user-prompt-framing.md`) plus a one-paragraph pointer added to `CLAUDE.md`. No hook, no audit log, no tests — the actor being disciplined is the main agent itself, so external enforcement is impossible by construction, and the speculative-observability discipline argues against building a hook before drift is observed. The rule file is structured to be readable in 60 seconds: a short summary box up top (3-question check + threshold table) so the agent can re-find the operative rule mid-conversation, then five sections — skip categories, exploratory carve-out, pronoun resolution, override marker, gotchas — each ≤200 words, with concrete prompt examples annotated by which questions fail and what the right response is (resolving spec Open Question #1 toward "yes, include examples — calibration matters more than rot-resistance for a brand-new discipline").

Placement of the CLAUDE.md section follows the topical-proximity convention: right after `## Delegation` and before `## Test-driven development`, because user-prompt-framing is the user→main mirror of the main→sub delegation gate. Forks pick the rule up automatically via `sync-harness.sh` because `.claude/rules/*.md` is already in its manifest; this resolves spec Open Question #4 toward "ship" — the discipline is universally useful and the `# OVERRIDE:` marker handles per-prompt opt-out for any fork's idiosyncratic prompt style. No new files in `.claude/hooks/`, `.claude/tools/`, or `scripts/`; the rule is the entire capacity.

## Files to touch

**Create:**

- `.claude/rules/user-prompt-framing.md` — the discipline document; sections: summary box (3-question rule + threshold table), skip categories with examples, exploratory carve-out with examples, pronoun resolution carve-out, override marker grammar, worked examples table (5-7 annotated prompts), gotchas, cross-references to `delegation.md` / `spec-driven.md` / `feedback_speculative_observability.md`. Target ~5-8 KB — initial draft landed at ~8 KB; worked-examples table + skip-categories-as-table account for the density, both kept because the "60-second readable" target applies to the summary box at the top, not the entire file.

**Modify:**

- `CLAUDE.md` — insert a new `## User prompt framing` section between `## Delegation` (line 33-35) and `## Test-driven development` (line 37-39). One paragraph describing the discipline + pointer to the rule file. Section header text follows the existing convention (no emoji, two-three sentence body, ends with "See `.claude/rules/user-prompt-framing.md`.").

**Delete:** none.

## Alternatives considered

### `UserPromptSubmit` hook in v1

Rejected. The CC `UserPromptSubmit` event can inject `additionalContext` before the agent processes a prompt — technically viable as a nudge channel. But (a) the agent would still be the one applying the discipline (the hook cannot block the agent from acting); (b) building observability before a demand pattern exists is exactly the `feedback_speculative_observability` antipattern (the canonical case is spec 010 audit-forensics, abandoned). The right v2 path — if drift is observed during the 3-week dogfood window — is a hook that injects a one-line reminder + audit-log row, but only after rule-of-three demand. Until then, no.

### New `/frame` slash command

Rejected. A slash command inverts the default to opt-in: the user invokes `/frame` when they already know their prompt is vague. This misses the entire failure mode the spec is targeting — cases where the user doesn't know they should have framed. The discipline must run on every turn by default, which is what a rule + agent compliance achieves and a slash command does not.

### Extend `.claude/rules/delegation.md` to cover the user→main boundary

Rejected. Symmetry is conceptual (5-field handoff applies both at user→main and main→sub) but enforcement model differs sharply: delegation is hook-blocked, framing is agent-disciplined. Conflating them in one rule would either over-promise enforcement (readers expect hook semantics from a rule file shared with delegation) or under-document framing (the carve-outs — skip categories, exploratory, pronoun — are specific to the user-side surface and don't apply to sub-agent dispatches). Separate file, cross-referenced.

### One-line addition to CLAUDE.md without a separate rule

Rejected. The discipline has enough operative content (3-question rule, threshold table, 5 skip categories, exploratory bucket, pronoun rule, override marker, gotchas) that fitting it into a CLAUDE.md paragraph would either lose detail (and not be applicable) or balloon CLAUDE.md (which is already ~95 lines of capacity inventory). Existing precedent: every other capacity ships as a `.claude/rules/<topic>.md` plus a CLAUDE.md pointer. Follow the convention.

### Memory file under `.claude/memory/` instead of `.claude/rules/`

Rejected. Per `.claude/rules/memory-placement.md` § decision tree, behavioral mandates go to `.claude/rules/`, not memory. Framing is behavioral ("the agent SHOULD do X when receiving a prompt"), not factual reference. Memory also doesn't ship to forks via sync-harness, which is the wrong propagation property for a discipline meant to apply repo-wide.

## Risks and unknowns

- **Friction risk.** Agent asks for clarification too often → user annoyed, discipline abandoned. Mitigated by: strict threshold (2+ ambiguities, not 1+), broad skip categories (path+verb, explicit command, factual question, short continuation, greeting), exploratory carve-out, override marker. If still too noisy after 1 week of dogfood, tighten the threshold or expand skip categories before deciding the discipline is broken.
- **False-negative risk.** Agent should have asked but didn't, drift happens silently. Detection requires retroactive session review during the dogfood window; no automatic signal in v1 (that's exactly what a v2 hook would provide).
- **Calibration unknown.** No prior data on how often the discipline fires in practice. The dogfood metric is "count of sessions where the agent forgot to apply on a prompt that retroactively should have triggered" (spec Open Question #2). Default decision criterion: ≥3 → spec a hook.
- **Rule decay risk.** Rule files that aren't cross-referenced from other docs rot — they stay correct but stop being read. Mitigated by cross-references from `delegation.md` (the symmetric upstream gate) and `spec-driven.md` § *When SDD applies* (overlapping trigger set).
- **Fork-calibration unknown.** Forks pick the rule up via sync-harness, but their users may have different prompt styles → calibration may differ. Default: ship with override marker; revisit if a fork reports the discipline doesn't fit their flow.
- **Example-table rot risk.** Worked examples in the rule may drift from real prompt patterns over time. Mitigated by keeping examples to a small, illustrative set (5-7 prompts) rather than an exhaustive catalogue.

## Research / citations

- `.claude/rules/delegation.md` — 5-field handoff structure that the discipline mirrors
- `docs/specs/002-delegation/` — design rationale for "contract, not promise" framing and DONE_WHEN as verifiable outcome
- `.claude/rules/spec-driven.md` § *When SDD applies* — overlapping trigger set ("vague request needing decomposition", "3+ files")
- `.claude/rules/memory-placement.md` — decision tree confirming `.claude/rules/` is the correct bucket
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand-test that gates the v1 hook decision
- `.claude/tools/sync-harness.sh` — manifest already covers `.claude/rules/*.md`, so fork propagation is automatic (no manifest edit needed)
- `CLAUDE.md` — capacity-section ordering and pointer-paragraph convention
- This conversation (2026-05-17, sessions named `hooks` → `prompt`) — heuristic was destilled live with worked examples ("sim" ambiguity after two-option question is the canonical in-conversation instance)

No external web research was needed; the design is fully internal to Agent0 conventions and re-uses primitives that already ship in the repo.
