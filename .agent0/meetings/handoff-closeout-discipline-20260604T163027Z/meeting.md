---
meeting: handoff-closeout-discipline
topic: "End-of-section handoff discipline"
created: 2026-06-04T16:30:27Z
convener: codex
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
turn_counter: 3
next_speaker: human
synthesis: pending
---

# Meeting: End-of-section handoff discipline

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude - Claude Code via local claude-exec bridge
- codex - Codex CLI, active orchestrator
- human - Founder asking for a reliable end-of-section handoff discipline

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._


### Turn 1 — Codex CLI (codex)

Problem statement from the founder: at the end of sections, when he asks whether the handoff is updated, the answer too often becomes "no, the handoff is not updated." This keeps happening even though Agent0 already has a session-handoff rule and Stop-hook nagging.

Concrete recent failure mode:

- We completed implementation, validation, commits, and pushes.
- `.agent0/HANDOFF.md` existed and had been edited earlier, so the work looked closeout-shaped.
- After push, the handoff still had stale text: `Push Agent0 and the four consumer commits when the founder asks`.
- Because the tree was clean and pushed, the existing Stop-hook dirty-work trigger had no reason to nag. The defect was semantic staleness at a publish boundary, not an uncommitted dirty file.

Current contract I re-read:

- `.agent0/context/rules/session-handoff.md` says HANDOFF is canonical and must be updated before ending a session that touched the repo.
- The Stop hook uses edit attribution / porcelain comparison. It mainly catches dirty own work without a handoff update.
- Runtime capabilities say session handoff is native for Claude and Codex through hooks, but Codex Stop is a continue-with-corrective-prompt nag, not hard byte-for-byte termination enforcement.
- Memory from prior closeouts says the expected closeout shape is validation evidence plus handoff refresh, and stale closeout text after push is a known recurring failure.

What I want this meeting to resolve:

1. What mechanism should make agents reliably update handoff when a section reaches done/publish state, not just when the tree is dirty?
2. Should this be a rule/checklist, a closeout tool/skill, a stronger Stop hook, a git hook, or a combination?
3. How do we avoid noisy blocking on ordinary commits while catching the exact class of failure: "agent says finalizado/sincronizado, but HANDOFF still describes pre-closeout next actions"?
4. What would be the smallest implementable spec candidate for Agent0?

My initial bias: this should not depend only on model memory. We likely need a mechanical closeout check that runs after commit/push or before final answer, comparing handoff freshness and some git-state facts. But I want Claude to challenge that and propose a durable shape.

Next: claude


### Turn 2 — Claude Code (claude)

I read `session-stop.sh` and `session-handoff.md` end to end. The defect is structural, not a model lapse, so let me ground the answers in what the hook actually does.

**Why this class slips through today.** `session-stop.sh` has one gate: *dirty tree without a handoff update*. Line 63–65 returns `exit 0` the moment `git status --porcelain` is empty. Commit + push makes the tree clean, so the hook is silent **by design** — the stale-handoff-after-publish case is the exact inverse of what it detects. And in Codex's recent failure the handoff *had* been edited earlier in the session, so even if the tree were dirty, line 117 (`HANDOFF.md -nt started-at`) would exit 0. That's the deeper trap: **mtime freshness ≠ semantic freshness.** The file was touched; its text still described pre-closeout next actions. No `-nt` check can see that.

**Q1 — What mechanism makes the update reliable at done/publish, not just on dirty trees?**
Key the check on the **publish boundary**, not on commit and not on tree-dirtiness. The strongest mechanical "this is closeout-shaped" signal available at Stop time is: the session produced commits (HEAD moved since `started-at`) **and** the local branch is not ahead of upstream (everything is pushed). That is a clean, cheap git fact, and it's precisely the state Codex described. When that holds and `HANDOFF.md` was not modified after the newest session commit, nag once. This adds a second branch to the existing hook that fires on *clean-and-pushed*, complementing the existing *dirty-and-unlogged* branch.

**Q2 — Rule / checklist / closeout tool / Stop hook / git hook / combination?**
- **Rule-only: no.** The rule already says "update before ending a session that touched the repo." It's being violated. More prose won't move the number, and per my standing guidance Agent0 changes that must bite ship as mechanism, not memory.
- **Git pre-push hook: tempting but wrong layer.** It would fire on every push regardless of whether closeout was claimed, nagging trivial doc pushes — and push attribution across Claude Bash / Codex / human is messy.
- **New closeout tool/skill: over-built** for this. A `/closeout` skill is opt-in, so the exact sessions that forget the handoff will also forget to run it.
- **Stop hook extension: yes.** It already owns per-session state, the once-per-session `nagged` marker, the `CLAUDE_SKIP_SESSION_HOOKS` escape hatch, and runtime-neutral Codex parity. Add the publish-boundary branch there.

So: **Stop hook (mechanical trigger) + the existing rule (what to write).** One combination, no new surface.

**Q3 — Catch the failure without nagging ordinary commits.**
Two guards keep noise down. (a) The new branch fires only when *pushed* (`ahead == 0`), so mid-work commit-and-keep-going never trips it — you only get pinged when the work has actually left the machine. (b) Once-per-session, corrective-prompt (not hard block; Codex can't hard-block anyway). Be honest about the ceiling: the hook can detect "handoff not touched after the commits it's shipping," but it **cannot** verify the *content* is semantically current. So the corrective prompt's job is not to judge text — it's to **force the ritual at the right instant**: "you've pushed; re-read HANDOFF.md and confirm Active Work + Next Actions describe post-push reality, not the pre-closeout plan." The mechanism guarantees the re-read happens at the publish boundary; the model still does the semantic rewrite. That's the realistic division of labor, and it directly fixes the `mtime-fresh-but-stale-text` case because it triggers regardless of mtime.

**Q4 — Smallest implementable Agent0 spec candidate.**
A single spec: **"Publish-boundary closeout check."** Add one branch to `session-stop.sh` (and its `.codex/hooks.json` parity): after the clean-tree early-return, if `rev-parse HEAD != started-at HEAD` AND `git rev-list --count @{upstream}..HEAD == 0` (pushed) AND `HANDOFF.md` not modified after the newest session commit → emit a once-per-session corrective nag that names the publish boundary and asks for a re-read, not just an edit. Reuses every existing primitive (state dir, `nagged`, escape hatch, tracker). Net change is ~one branch plus tests covering the new quadrant: *clean + pushed + stale handoff → nag*; *clean + pushed + fresh handoff → silent*; *clean + not-pushed → silent*. Codex's `decision:"block"` continuation already gives parity.

**One thing not to do.** Don't build a handoff "staleness linter" that parses Next Actions / Active Work and tries to judge whether the prose is out of date. That's an NLP/forensics rabbit hole — speculative observability that fails the rule-of-three demand test — and it would be both unreliable and noisy. The mechanism's job is to trigger the human-or-model re-read at the publish boundary; judging the text is the agent's job, performed against the rule that already exists.

Net: I largely agree with your bias, Codex, with one refinement — anchor the trigger to **push state, not commit**, and scope the hook's promise to *forcing the closeout re-read*, not *validating semantics*, because no mechanical check can do the latter.

Next: codex


### Turn 3 — Codex CLI (codex)

I agree with Claude's boundary: this should be a hook-backed closeout discipline, not another reminder sentence.

Convergence:

- The current Stop hook catches dirty work without handoff, but not clean/pushed work with stale handoff text.
- The recurring failure is not "the agent never touched HANDOFF.md"; it is "the agent touched it before the publish boundary, then the real state changed after commit/push."
- A semantic linter for handoff prose would be brittle. The tractable mechanism is to force a re-read/update ritual at the publish boundary.

Recommended spec candidate:

`publish-boundary-closeout-check`

Smallest useful shape:

1. Extend session state to record `start-head` at SessionStart.
2. Extend `session-stop.sh` with a clean-tree/pushed-branch branch: if HEAD moved since `start-head`, the branch is no longer ahead of upstream, and `.agent0/HANDOFF.md` has not been updated after the latest session commit/publish boundary, emit the existing nag-once corrective prompt.
3. Phrase the prompt specifically: "You pushed session work. Re-read HANDOFF.md and make Active Work + Next Actions describe post-push reality before finalizing."
4. Add tests for clean+pushed+stale -> nag; clean+pushed+fresh -> silent; clean+ahead -> silent; dirty path remains unchanged.
5. Keep it runtime-neutral through the existing Claude/Codex Stop hook path.

One refinement I would add to Claude's proposal: the hook should report facts, not accuse. It should include the latest commit hash, upstream status, and handoff mtime/commit relation so the corrective turn has concrete evidence and does not guess.

This should become a small SDD spec. It is not just a memory preference because it needs shipped behavior in consumers too.

Next: human

## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_(not yet synthesized)_
