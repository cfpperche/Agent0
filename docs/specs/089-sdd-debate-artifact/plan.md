# 089 — sdd-debate-artifact — plan

_Drafted from `spec.md` on 2026-05-25. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Three coordinated edits ship this capacity:

1. **One new template file** (`templates/debate.md.tmpl`) — canonical structure of `debate.md`: header (slug + date + broker + stop criteria), 3 round placeholders (`### Round N — <actor> (position|critique|counter)`), `## Synthesis` section, `## Applied changes` section.
2. **One SKILL.md amendment** — frontmatter (`description`, `argument-hint`) gains `debate`; body gains a new `## Subcommand: debate` section between `tasks` and `list`, plus an Eval Scenario. Argument parsing reuses the existing `$ARGUMENTS` split convention.
3. **One rule amendment** — `.claude/rules/spec-driven.md`: rename § The four artifacts → § The artifacts (5 entries), add the `debate.md` paragraph, add optional step 1.5 to § Workflow with the same opt-in framing as `refine` (step 0).

Mechanical re-use throughout: the `debate` subcommand mirrors `plan` / `tasks` for target selection (latest `NNN-*` dir unless ambiguous), refusal logic (refuse if `spec.md` still has `{{` placeholders), and exit shape (report path + next-step instruction). The only novel logic is the broker loop — and that's prose discipline inside the skill body, not new code.

Because v1 is broker-human, there is **zero new state file**, **zero new hook**, **zero new env var**, **zero new dependency**. The skill instructs Claude to manage the round counter and convergence call as in-conversation logic; `debate.md` itself is the persistence layer (git-tracked with the spec). This is the smallest shape that delivers the feature.

## Files to touch

**Create:**
- `.claude/skills/sdd/templates/debate.md.tmpl` — canonical debate artifact template; placeholders for `{{NNN}}`, `{{SLUG}}`, `{{DATE}}`, and round bodies
- `docs/specs/089-sdd-debate-artifact/{spec,plan,tasks,notes}.md` — this spec (already scaffolded; spec + plan + tasks filled, notes empty until implementation surfaces in-flight decisions)

**Modify:**
- `.claude/skills/sdd/SKILL.md` — frontmatter `description` adds `debate` to the subcommand list; `argument-hint` adds `| debate`; body adds `## Subcommand: debate — 🔓 Medium freedom: scaffold + orchestrate broker loop` between `tasks` and `list`; § Unknown subcommand usage hint updated; § Eval Scenarios gains "Eval 4: debate happy path"
- `.claude/rules/spec-driven.md` — § The four artifacts → § The artifacts (rename + add debate.md entry); § Workflow gains optional step 1.5 with cross-reference to skill; status semantics unchanged (debate.md does NOT affect status resolution)

**Delete:** none.

## Alternatives considered

### Direct OpenAI API integration (broker-script)

Rejected for v1: adds an `OPENAI_API_KEY` requirement, a new shell script under `.claude/skills/sdd/scripts/`, and a new external dependency (`curl` + JSON parsing). The cost is real (per-round API cost) and the value is unproven — no evidence yet that cross-model debate routinely produces spec edits worth the friction. The broker-human path tests the hypothesis at zero infra cost; if ≥3 real debates produce spec changes, that's the rule-of-three trigger to promote.

### MCP server for OpenAI / GPT-5

Rejected for v1: opt-in MCP recipes are already a documented pattern (`.claude/rules/mcp-recipes.md`), but no mature OpenAI MCP is currently in the project's recipe list. Adding one introduces a new dependency surface and requires per-fork opt-in. Same hypothesis-first rationale as the API path.

### Auto-apply spec edits from synthesis

Rejected: violates contract-not-promise discipline (`.claude/rules/delegation.md` § Why DONE_WHEN exists). The synthesis section can confidently propose changes; only the human can confidently accept them. Auto-apply would also make the debate harder to dogfood (no clean rollback after a bad synthesis). Manual confirmation costs ~10 seconds; the safety it buys is real.

### Stop criterion = "no new critique" only (no hard cap)

Rejected: a model that keeps generating critiques because it's instructed to "find issues" will never converge. The 3-round hard cap matches the loop-budget discipline (`.claude/rules/delegation.md` § Post-edit validator loop, default 5; debate gets a tighter 3 because each round is human-mediated and the per-round cost is higher). Convergence-OR-cap is the canonical shape.

### Separate `.claude/.debate-state/` directory

Rejected: `debate.md` IS the state. It's git-tracked alongside the spec, lives in the spec dir, survives session boundaries, and reads as documentation. A per-machine state cache would split the audit trail across two locations for zero benefit at v1 scale. If autonomous (Phase 2) execution ever ships, that's when a per-machine state file becomes worth considering.

## Risks and unknowns

- **Broker friction kills usage.** The user has to manually copy-paste twice per round. If this proves too high-friction, the discipline gets skipped exactly when it would be most useful (large/complex specs). Mitigation: track "did this debate produce a spec edit?" as the rule-of-three signal. After 3 successful debates, revisit broker-script vs MCP options with real evidence.
- **Convergence call is Claude's judgment.** No diff-counting heuristic — Claude decides "this round added no new critique points → synthesize". Risk: Claude calls convergence too early to avoid the friction of another round. Mitigation: the 3-round hard cap is upper-bound; explicit user "continue/synthesize/stop" prompt after every round is the lower-bound human-in-loop check.
- **Pre-population scope.** If Round 1 is the full spec.md body, paste payload may exceed external model's UI input limit on large specs (rare but possible). Default is structured summary (intent + top 3 scenarios + top 3 open questions). Marked as Open question in spec; revisit if paste size becomes a real problem.
- **Status declaration unchanged.** `debate.md` does NOT affect `**Status:**` resolution in `/sdd list`. A spec can be `in-progress` with or without a debate. This is deliberate — debate is opt-in even after the rule documents it.

## Research / citations

- `.claude/rules/spec-driven.md` § The four artifacts — existing 4-artifact shape and § Workflow step ordering; debate slots in as step 1.5 to mirror the optional `refine` (step 0) framing
- `.claude/skills/sdd/SKILL.md` § Subcommand: `plan` / `tasks` — target-selection and refusal-on-placeholder patterns to mirror for `debate`
- `.claude/rules/delegation.md` § Post-edit validator loop — 3-round hard cap inspired by the consecutive-failure cap discipline (CLAUDE_DELEGATION_LOOP_BUDGET=5; debate uses 3 because per-round cost is human-mediated)
- `.claude/rules/reminders.md` § Discipline — "audit-in-band" model (state lives in the artifact itself, no separate cache) directly informs the "no `.claude/.debate-state/`" decision
- Conversation 2026-05-25 — design exchange that converged on broker-human-only v1
