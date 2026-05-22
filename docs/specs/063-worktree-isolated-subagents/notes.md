# 063 — worktree-isolated-subagents — notes

_Created 2026-05-19._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-19 — parent — empirical worktree surface capture + Option B redirect

Pre-flight applied the same rigor that closed spec 062: probed CC 2.1.144 for native worktree primitives before committing to the original design (6th `ISOLATION:` brief field). Findings:

**CC native worktree surface** (mapped via `strings /home/goat/.local/bin/claude` + `claude --help`):

- `Agent` tool accepts `isolation: "worktree"` in tool params — already in system-prompt tool description
- `EnterWorktree` / `ExitWorktree` are native tools the sub-agent invokes
- Sub-agent's system prompt is **automatically injected** with worktree instructions when `isolation: "worktree"` is set: _"Call EnterWorktree as your first action — before reading files or running commands — unless your cwd is already under `.claude/worktrees/`. If EnterWorktree fails, continue in place."_
- `.claude/worktrees/<name>/` is the standard convention path
- `--worktree [name]` is a CLI flag for whole-session worktree (with `--tmux` integration for parallel tmux panes)
- `settings.json.worktree` block: `bgIsolation` (worktree|none), `baseRef` (fresh|head), `sparsePaths`, `symlinkDirectories`
- `WorktreeCreate` / `WorktreeRemove` are hook events (per `cc-platform-hooks.md`; not yet used by Agent0)
- `CLAUDE_BG_ISOLATION` env var configures background session isolation

**The original premise was wrong.** We assumed the gate would need to mutate the `Agent` tool call payload to propagate isolation from the brief. CC's harness handles propagation directly — parent sets `isolation` on the tool call, sub-agent's system prompt is augmented to call EnterWorktree, sub-agent creates the worktree itself. The gate cannot (and doesn't need to) bridge brief → tool params.

**Three options weighed**:
- **A. Close 063** (defer entirely to CC native). Honest but loses the "audit + advisory + rule" disciplinary value Agent0 can add.
- **B. Redirect to minimal-viable scope**: drop brief field; audit `tool_input.isolation` in dispatch row; document discipline in rule; fix validator scoping. **Chosen.**
- **C. Keep original** (add 6th brief field as redundant intent declaration). Anti-pattern parallel to rejected 062 Option B.

B wins because:
- Two pés solidos: validator scoping is gain independent of isolation (mitigates cross-cwd validator issues in ANY sub-agent edit, not just worktree-isolated); audit gives forensic value at near-zero cost (one jq extraction + one field in audit row).
- Brief field would be redundant (parent already has canonical `tool_input.isolation`) and unenforceable (gate can't mutate tool params from brief — same constraint that made 062 Option B unattractive).
- Skip advisory in v1 per `feedback_speculative_observability.md` rule-of-three. Ship audit + rule; if observed drift later shows parents forget isolation when they should set it, add advisory in a follow-up spec targeted at the observed failure mode.

What dropped from the original design:
- 6th brief field `ISOLATION: worktree`
- State stamp file `.claude/.delegation-state/agents/<agent_id>/isolation` (audit row already records it)
- Validator-probe via `git rev-parse --show-toplevel` was already in the plan — promoted to a primary task (R2) since it's the most valuable single change

What was preserved as historical design memory:
- Original `spec.md` § Acceptance criteria (7 scenarios about brief field semantics) — most are obsolete
- Original `plan.md` § Approach + Alternatives considered — useful as comparison framework
- Original `tasks.md` 1-9 outline — superseded by R1-R5 above

The pattern across 061/062/063 is now clear: **pre-flight verify the competitive surface (Codex / CC native / other harnesses) before committing to design**. Three out of three pre-flights surfaced material findings (061: hook payload schema → gate extension; 062: CC native `/goal` → close; 063: CC native worktree → redirect). The discipline is paying for itself — saved roughly 80% of original spec 062 + ~50% of original spec 063 work via empirical pre-flight.

## Deviations

### 2026-05-21 — parent — spec closed by audit: all R-tasks were done-but-unclosed

A session audit found spec 063 sitting `in-progress` with `tasks.md` showing 0/29 checked, yet the capacity was already shipped. The 0/29 was a stale-checkbox artifact, not incomplete work — the Option B redesign tasks (R1–R5) never had their boxes flipped after the code landed. Verified each against the live tree:

- **R1** (gate captures `tool_input.isolation`) — `delegation-gate.sh:45` extracts it, `:239`/`:246` write it to the dispatch row. ✓
- **R2** (validator scoping) — `post-edit-validate.sh:30-42,86` derives `VALIDATOR_CWD` from the edit's git toplevel with a `$PROJECT_DIR` fallback. ✓
- **R3** (`## Worktree isolation` rule section) — present in `.claude/rules/delegation.md`. ✓
- **R4** (manual e2e) — the audit log carries `"isolation": ""` on real recent dispatch rows (additive schema: 10 of the last 200 rows have the key, older rows predate the gate change); the `"worktree"` value is the identical verbatim-passthrough path. Closed on this evidence rather than a contrived read-only worktree dispatch, which would itself violate § Worktree isolation's "when NOT to declare isolation" guidance.
- **R5** (commit + push) — R1–R3 were committed in an earlier session; the working tree was clean and in sync with `origin` at audit time.

The 29 original-outline tasks (`tasks.md` § Implementation (original)) were superseded by the 2026-05-19 Option B redesign and were never the live worklist — counting them as "0/29 incomplete" overstated the gap. spec 067 (`parallel-edit-validation`) later built tests that exercise R2's worktree-aware scoping with real git worktrees (2/2 PASS) — independent coverage that 063's own Option B scope never required.

Lesson: flip the checkboxes when the code lands. A spec left `in-progress` after shipping reads as unfinished work and invites a re-audit cost that the 30-second checkbox update would have prevented.

## Tradeoffs

_(none yet)_

## Open questions

_(none yet — see `spec.md` § Open questions for pre-flight unknowns)_
