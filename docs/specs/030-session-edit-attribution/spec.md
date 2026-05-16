# 030 — session-edit-attribution

_Created 2026-05-16._

**Status:** shipped

## Intent

The Stop hook (`.claude/hooks/session-stop.sh`) decides "this session has uncommitted WIP" by comparing `git status --porcelain` between SessionStart and Stop (spec 023). That signal is **observation of the worktree**, not **attribution of edits** — a session that doesn't touch the repo but happens to be open while another session, an IDE, or an out-of-band script modifies files still gets blamed and nagged.

Canonical evidence (2026-05-16): the hermes-agent session (`95b868a2`) was open 13:23→13:27 doing research-only work. Sibling activity modified `09-system-design/{prompt,schema}.md` at 13:26 and 13:27; the parallel session `c0f47da9` started at 13:27:33 with those edits already captured in its own `start-porcelain.txt`. Hermes Stop fired at 13:27:48 — porcelain at Stop differed from the empty start-porcelain.txt at 13:23, so spec 023's compare flagged it, even though the hermes session transcript shows zero `Edit` / `Write` / `MultiEdit` tool calls.

Fix: attribute edits directly via `session_id` (which Claude Code passes in every hook payload) rather than inferring from worktree deltas. A new `PostToolUse(Edit|Write|MultiEdit|NotebookEdit)` hook appends each edited file path to `<state-dir>/edited-files.txt`; Stop reads that file as the primary signal — empty / absent → silent exit. Spec 023's porcelain-compare stays as fallback so Bash-driven edits (`sed -i`, `cat >`, etc.) and legacy sessions (started before this spec lands) still get reasonable coverage.

## Acceptance criteria

- [ ] **Scenario: parallel session bystander**
  - **Given** session A is open and has made zero Edit / Write / MultiEdit / NotebookEdit tool calls
  - **When** session B (parallel) modifies repo files during A's lifetime
  - **Then** when A reaches Stop, the nag does NOT fire

- [ ] **Scenario: own edits uncommitted**
  - **Given** session A called `Edit` on a tracked file `foo.ts` and didn't commit
  - **When** A reaches Stop without updating SESSION.md
  - **Then** the nag fires once

- [ ] **Scenario: own edits committed**
  - **Given** session A edited `foo.ts` and committed it
  - **When** A reaches Stop
  - **Then** the nag does NOT fire (path no longer in porcelain)

- [ ] **Scenario: own edits reverted**
  - **Given** session A edited `foo.ts` and ran `git restore foo.ts`
  - **When** A reaches Stop
  - **Then** the nag does NOT fire (path no longer in porcelain)

- [ ] **Scenario: Bash-driven edit in a tracker-enabled session (documented silent-miss)**
  - **Given** session A is tracker-enabled (SessionStart created empty `edited-files.txt`) and modified `bar.md` via `sed -i` (not via Edit/Write/MultiEdit)
  - **When** A reaches Stop
  - **Then** the block does NOT fire. The empty tracker file says "session edited nothing the tracker could see"; spec-023 fallback is bypassed (tracker present = primary path wins). This is the deliberate trade documented in § Non-goals: bystander quiet beats Bash-edit nag — users who edit via Bash must remember to update SESSION.md themselves.

- [ ] **Scenario: legacy session (pre-030)**
  - **Given** a session whose state-dir has no `edited-files.txt` at all (started before 030 deployed; SessionStart predates the touch line)
  - **When** Stop fires
  - **Then** behavior is byte-identical to spec 023 (porcelain-compare → mtime fallback). This is the only path that consults spec 023.

- [ ] **Scenario: block-once invariant preserved**
  - **Given** session A's nag has already fired once and `<state-dir>/nagged` exists
  - **When** A makes more edits and reaches Stop again
  - **Then** the block does NOT re-fire (existing `session-stop.sh:40-43` short-circuit still wins; 030 does NOT change cardinality, only accuracy)

- [ ] `.claude/hooks/session-track-edits.sh` exists, is executable, exits 0 on missing / malformed payloads (fails open — must never block a tool call)

- [ ] `.claude/settings.json` registers the new hook on `PostToolUse` for `Edit | Write | MultiEdit | NotebookEdit` matchers

- [ ] `.claude/rules/session-handoff.md` documents the new state file (`edited-files.txt`) under § *State files*, names this new signal as primary in § *Carryover discrimination* (spec 023 demoted to fallback), and adds a § *Edit attribution* subsection naming spec 030

## Non-goals

- **Track Bash-driven file edits.** `sed -i`, `cat > file`, `python -c "open(...)"`, IDE saves, and other non-Edit/Write/MultiEdit paths remain attribution-blind. In a tracker-enabled session they become **silent misses** (empty tracker → exit 0; spec-023 fallback is bypassed because the tracker is present). The user-facing cost: a session that edits exclusively via Bash and forgets SESSION.md exits silently. We accepted this trade because: (a) bystander quiet was the primary goal; (b) most agent file mutations go through Edit/Write/MultiEdit and DO get tracked; (c) Bash-arg parsing for file paths is unsafe (fragile regex on `sed -i`, redirections via `eval`, `find -exec`). Spec 023 only fires for legacy sessions (state dir without `edited-files.txt` at all).
- **Reduce hook firing frequency.** Stop still runs on every assistant turn. This spec changes the *accuracy* of the block decision, not the cardinality — block remains capped at 1 per `session_id`, same as today (`session-stop.sh:40-43`).
- **Sibling-session exclusion via `start-porcelain.txt` cross-reads.** Considered and rejected during planning: imprecise when 2 sessions touch the same file, still inferential rather than attributive. Per-session edit tracking is the direct primitive; nothing to add on top.
- **Per-edit audit log or analytics.** `edited-files.txt` is a per-session ephemeral signal under the existing 7-day cleanup, not a forensic trail.
- **Settings.json schema change for fork forks.** Adding a `PostToolUse` matcher block is additive; existing forks that adopt the harness sync pick it up via the standard `sync-harness.sh --apply` flow. No migration tooling needed.

## Open questions

- [ ] **Should `MultiEdit` and `NotebookEdit` matchers ship from day 1, or just `Edit | Write` and add the others on first observed gap?** Default proposal: ship all four, since the hook body is identical and tool selection is just matcher syntax. Marginal cost ≈ zero.
- [ ] **Path normalization: relative-to-`CLAUDE_PROJECT_DIR` or absolute?** Default proposal: relative — matches `git status --porcelain` output shape, simplifies the "is this path still dirty?" check in Stop. Edge case: edit to a path *outside* the project dir → log as-is (will never match porcelain, treated as no-op in Stop).
- [ ] **Concurrency primitive: `flock` or naive append?** Default proposal: `flock` on the file itself before append. Parallel tool calls in one session are real (`Agent` subagent dispatches), and naive append risks interleaved partial writes that break later parsing.

## Context / references

- `.claude/hooks/session-stop.sh` — current Stop hook, the one being extended.
- `.claude/hooks/session-start.sh` — companion that already writes `started-at` and `start-porcelain.txt` to the per-session state dir.
- `.claude/rules/session-handoff.md` — protocol doc, the canonical place to document the new signal and demote spec 023 to fallback.
- `docs/specs/017-session-state-isolation/` — established the per-`session_id` state-dir layout this spec extends.
- `docs/specs/023-session-stop-noop-aware/` — direct ancestor; spec 030 supersedes its decision-criteria primacy but keeps the porcelain-compare as fallback. (Spec 023 stays `shipped`, not `superseded` — its mechanism remains live for the legacy-session and Bash-edit paths.)
- Hermes-agent transcript (this project, 2026-05-16 session `95b868a2-...`) — concrete forensic evidence of the false-positive captured in `## Decisions & gotchas` of the current SESSION.md.
