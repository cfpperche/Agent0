# 089 — sdd-debate-artifact

_Created 2026-05-25._

**Status:** shipped

## Intent

Add a 5th artifact `debate.md` to the SDD pipeline and a `/sdd debate` subcommand that orchestrates a cross-model review of `spec.md` between the live Claude session and **another tool-calling CLI agent** (separate session — Codex CLI, Cursor, Aider, etc., each porting its own equivalent of this skill). Both agents read and write `debate.md` **directly** via their native file tools; the human alternates which agent is active and decides when to ask for synthesis. The goal is to catch spec ambiguities, hidden assumptions, and weak acceptance criteria that a single model misses — productive disagreement before `plan.md` is locked, when the cost of change is still markdown-cheap.

Posture is **dual-agent, zero-infra-in-this-session**: no API key, no MCP server, no script — the cross-model boundary is bridged by the human running two CLI agent sessions side-by-side, not by code in either skill. The file `debate.md` is the only shared state. Either agent can be asked to write the synthesis when the human signals the debate is done.

## Acceptance criteria

- [x] **Scenario: scaffold debate.md from active spec**
  - **Given** a spec dir `docs/specs/NNN-<slug>/` exists with a filled `spec.md` (no `{{` placeholders)
  - **When** the user invokes `/sdd debate`
  - **Then** `docs/specs/NNN-<slug>/debate.md` is created from the template, `{{SLUG}}` / `{{NNN}}` / `{{DATE}}` substituted, and Round 1 (Claude's position) is pre-populated with a structured summary of `spec.md` key claims (intent, top 3 acceptance scenarios, top 3 open questions)

- [x] **Scenario: refuse on missing or empty spec**
  - **Given** the target spec dir has `spec.md` still containing `{{` placeholders, OR no spec dir is in flight
  - **When** the user invokes `/sdd debate`
  - **Then** the skill refuses with a clear message ("fill spec.md first" or "no spec dir in flight"), does NOT create `debate.md`, and exits

- [x] **Scenario: emit dual-agent handoff instruction after Round 1**
  - **Given** `debate.md` exists with Round 1 (Claude position) populated
  - **When** the skill completes the scaffold + Round 1 step
  - **Then** the user sees a handoff message telling them to switch to the other CLI agent session and ask it to read `debate.md` and write the next critique directly into the file — no copy-paste mentioned

- [x] **Scenario: re-invocation on in-flight debate writes next Claude slot**
  - **Given** `debate.md` has the most recent critique slot filled (by the other agent) and the next Claude-side counter slot empty
  - **When** the user re-invokes `/sdd debate`
  - **Then** Claude reads `debate.md`, identifies the empty `{{round N counter}}` placeholder, fills it with accept/reject/defer classifications of each critique point, and reports — does NOT refuse re-invocation

- [x] **Scenario: synthesis is user-triggered, not auto**
  - **Given** the debate has any number of rounds populated
  - **When** the user explicitly asks "synthesize the debate" (or equivalent)
  - **Then** Claude writes the `## Synthesis` section with Resolution + proposed spec changes + unresolved disagreements, and asks the user to accept / edit / reject — no auto-convergence detection, no round-count auto-cap

- [x] **Scenario: human-controlled stopping cadence**
  - **Given** an in-flight debate at any round (1, 2, 3, or beyond)
  - **When** the user re-invokes `/sdd debate` and the file shows no pending Claude slot (all Claude-side slots filled, no new critique yet)
  - **Then** Claude reports "waiting on the other agent for next critique, OR ask me to synthesize when ready" — does NOT force a stop or self-declare convergence

- [x] `.claude/skills/sdd/templates/debate.md.tmpl` exists with the canonical structure: header (slug, date, broker, stop criteria), 3 round placeholders, synthesis section, applied-changes section

- [x] `.claude/skills/sdd/SKILL.md` § Subcommand: `debate` exists with the full handler protocol (steps 1-N), parsing rule, refusal cases, broker instructions, stop criteria, and at least one Eval Scenario

- [x] `.claude/rules/spec-driven.md` § The four artifacts is renamed § The artifacts and lists 5 entries (spec / plan / tasks / notes / debate); § Workflow gains an optional step 1.5 (`debate` between spec and plan) with the same opt-in framing as `refine`

- [x] `.claude/skills/sdd/SKILL.md` frontmatter `description` and `argument-hint` updated to include `debate` as a subcommand

- [x] Dogfood: invoking `/sdd debate` against the spec dir created by this very spec successfully scaffolds `debate.md` with Round 1 pre-populated from this spec.md

- **Direct OpenAI/Anthropic cross-model API integration** — bridging is done by the human running two CLI agent sessions; neither skill calls the other agent's API
- **MCP server for cross-model bridging** — out of scope; same rationale
- **Auto-applied spec changes** — the active agent proposes diffs in the synthesis section; the human confirms before `spec.md` is edited
- **Debate of `plan.md` or `tasks.md`** — v1 scopes debate to `spec.md` only (the *what*); plan/tasks debate is a future capacity if v1 proves out
- **Per-debate audit log / JSONL** — `debate.md` IS the audit trail (git-tracked alongside the spec); no separate `.claude/.debate-state/` file
- **Auto-convergence detection** — the human decides when the debate ends by explicitly asking for synthesis; no diff-counting heuristic, no per-round Claude self-judgment that auto-stops
- **Round-count cap** — no hard cap; the human runs as many rounds as useful. Template ships 3 round slots; more can be appended manually
- **Concurrency control** — assume turn-based orchestration by the human (one agent at a time); no file-lock, no merge-conflict resolution. Race conditions are a Phase 2 question if two-at-once becomes a real workflow
- **Codex CLI's port of this skill** — out of scope here; the user maintains the equivalent skill in their other agent's runtime

## Open questions

- [ ] Should Round 1 pre-population be the full `spec.md` body or a structured summary (intent + top scenarios + top open questions)? **Default: structured summary** to keep the round digestible for paste; revisit if external model responses show it missed important detail.
- [ ] Should the synthesis section auto-apply spec edits or always require human confirmation? **Default: always confirm** — matches contract-not-promise discipline; auto-apply is too easy to misjudge.
- [ ] Position in pipeline — strictly between `spec` and `plan`, or any time? **Default: any time, but recommended between spec and plan**. Rule documents the recommendation; skill does not block.

## Context / references

- `.claude/rules/spec-driven.md` — the rule being amended; current § The four artifacts becomes § The artifacts (5 entries)
- `.claude/skills/sdd/SKILL.md` — the skill being extended with a 6th subcommand
- `.claude/rules/delegation.md` § Why DONE_WHEN exists — contract-not-promise discipline that motivates the no-auto-apply default
- `.claude/rules/reminders.md` § Discipline — soft-delete + audit-in-band model that informs "no separate state file" decision
- Conversation 2026-05-25 — design exchange that produced this spec (broker-human chosen over API/MCP for v1 simplicity)
