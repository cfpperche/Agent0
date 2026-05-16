# 031 — brainstorm

_Created 2026-05-16._

**Status:** shipped

## Intent

Add a `/brainstorm` skill to the Agent0 harness that conducts a structured-but-flexible ideation session with the user, then renders the captured material as a single self-contained HTML artifact for human review. Fills the gap between two existing capacities: ad-hoc chat (no structure, lost on `/clear`) and `/sdd refine` (forces convergence toward a spec). Brainstorm is explicitly *divergent* — its job is to surface more ideas, perspectives, and open questions, not to close them.

The skill is invoked when the user wants to explore an idea that is not yet a spec candidate — vague product ideas, strategic questions, "what if we…" prompts. Output is an HTML file the user opens locally and decides what to do with: drop it, use it as raw material for `/sdd new`, or just file it. Artefacts live under `.claude/.brainstorm-state/` (gitignored — does not pollute the repo).

The design is a hybrid: starts free-form (Design A — zero start friction, conversation-driven idea capture) and grows lenses (Design B — SCAMPER, Six Thinking Hats, Reverse, Crazy 8s) on demand once the material has matured. Lenses are applied *on top of* existing material, not as fixed phases the user walks through up front. The HTML output reflects this: one always-present "Exploration" tab plus one tab per applied lens.

## Acceptance criteria

- [x] `.claude/skills/brainstorm/SKILL.md` exists with frontmatter (description + argument-hint) and is invocable via `/brainstorm <subcommand>` and via the `Skill` tool
- [x] `.claude/skills/brainstorm/templates/render.html.tmpl` exists — single self-contained HTML file template (HTML + inline CSS + inline JS + two CDN scripts: markmap-autoloader for the mindmap, mermaid for the timeline)
- [x] `.claude/skills/brainstorm/references/techniques.md` exists — defines SCAMPER, Six Thinking Hats, Reverse Brainstorm, Crazy 8s as lenses the skill applies on demand
- [x] `.gitignore` contains an entry for `.claude/.brainstorm-state/` so generated state and HTML never reach git
- [x] **Scenario: start a free-form session**
  - **Given** the user invokes `/brainstorm start "<topic>"`
  - **When** the skill receives the topic
  - **Then** it creates `.claude/.brainstorm-state/<topic-slug>-<ISO-ts>.json` with `{topic, started_at, ideas: [], questions_open: [], quotes: [], connections: [], lenses_applied: []}` and opens the conversation with one grounding question — no technique chosen up front
- [x] **Scenario: free-form rounds capture material**
  - **Given** an active session with N turns so far
  - **When** the user contributes ideas, observations, or follow-up questions
  - **Then** the skill updates the JSON state file after each substantive turn, classifying entries as `ideas` (with tag in `{easy, risky, wild, unknown}`), `questions_open`, `quotes`, or `connections`
- [x] **Scenario: checkpoint after divergence**
  - **Given** 5–7 free-form turns have happened
  - **When** the next turn fires
  - **Then** the skill emits a one-line checkpoint summarising current counts (e.g. `12 ideas | 4 open questions | 0 lenses applied`) and offers three branches: continue free / apply lens / `/brainstorm done`
- [x] **Scenario: lens applied on demand**
  - **Given** an active session with ≥1 idea captured
  - **When** the user says "apply SCAMPER" (or "Black Hat", "reverso", "Crazy 8s", etc.) — or accepts a skill-initiated suggestion
  - **Then** the skill loads the lens definition from `references/techniques.md`, walks the existing ideas through that lens, captures derived ideas + critiques + new questions, and appends the lens name to `lenses_applied`
- [x] **Scenario: skill detects maturation and suggests a lens**
  - **Given** a session with ≥10 ideas and zero lenses applied, OR ideas clustered in a single tag (e.g. all `easy`, no `wild`)
  - **When** the next checkpoint fires
  - **Then** the skill names a specific suggested lens with the reason (e.g. "all ideas are `easy` — Reverse Brainstorm would force the wild quadrant"). The user accepts, declines, or names a different lens
- [x] **Scenario: render to HTML and report the local-serve command**
  - **Given** an active session
  - **When** the user invokes `/brainstorm done`
  - **Then** the skill (a) finalises the JSON state, (b) renders `<topic-slug>-<ISO-ts>.html` from the template populated with mindmap (markmap) + kanban cards + open questions + quotes + one tab per applied lens + timeline (mermaid), (c) prints both the absolute file path AND a copy-pasteable `python3 -m http.server 8765 -d .claude/.brainstorm-state` one-liner with the URL `http://localhost:8765/<filename>`
- [x] **Scenario: resume an existing session**
  - **Given** the user invokes `/brainstorm resume <topic-slug-or-filename>` after closing the chat
  - **When** the skill finds the matching `.json` in `.claude/.brainstorm-state/`
  - **Then** it loads the state, summarises current counts, and continues from where it left off — no re-asking what was already captured
- [x] **Scenario: HTML output is self-contained and openable offline**
  - **Given** a rendered HTML file
  - **When** the user opens it via `file://` directly OR serves it via `python3 -m http.server`
  - **Then** all visualisations render correctly without network access except the two CDN scripts (markmap-autoloader, mermaid.js) — acceptable trade-off for diagram quality vs file size
- [x] **Scenario: HTML offers a one-click markdown export for spec promotion**
  - **Given** a rendered HTML file open in a browser
  - **When** the user clicks the `Copy as markdown for /sdd new` button in the page footer
  - **Then** the clipboard receives a markdown block containing the topic, ideas grouped by tag, open questions, and lens summaries — shaped so the user can paste it as the starting point of a `docs/specs/NNN-<slug>/spec.md` body
- [x] **Scenario: `/brainstorm list` enumerates past sessions**
  - **Given** ≥1 session exists in `.claude/.brainstorm-state/`
  - **When** the user invokes `/brainstorm list`
  - **Then** the skill prints one line per session: `<topic-slug>  <ISO-ts>  N ideas  M lenses  <state: active | done>`

## Non-goals

- **Not a spec replacement** — `/brainstorm` does not produce `spec.md`, does not converge on acceptance criteria, does not enter the SDD lifecycle. If the user wants to promote brainstorm output into a spec, they do that manually via `/sdd new <slug>` and reference the HTML.
- **Not live-rendered** — the HTML is generated once on `/brainstorm done` (and re-runnable if added later). No live-reload, no WebSocket, no auto-refresh in the browser. Design C was explicitly rejected.
- **Not a multi-user / collaborative tool** — single user, single session at a time per topic. No shared state, no concurrent writers.
- **Not git-tracked** — state and rendered HTML live under `.claude/.brainstorm-state/`, gitignored. Brainstorm artefacts are ephemeral by design; promoting durable material is the user's call.
- **No bundled web framework** — render is a single HTML file with inline CSS/JS and two CDN script tags (markmap-autoloader for the mindmap, mermaid for the timeline). No React, no build step, no `bun install`.
- **No automatic browser launch** — the skill prints the URL; the user opens it (see Open Q1).

## Open questions

- [x] **Q1**: Should `/brainstorm done` open the browser automatically (via `xdg-open` / `open`) or just print the URL? **Recommended default: just print the URL.** Auto-open is platform-dependent (WSL2 in this repo's primary env needs Windows-side handling) and the user often wants the URL only when they need it.
- [x] **Q2**: Should lenses be composable in one turn (e.g. "SCAMPER through Black Hat lens")? **Recommended default v1: no** — apply one lens at a time; the user can manually chain (`SCAMPER → done → 6 Hats`). Composability adds combinatorial complexity to the prompt design.
- [x] **Q3**: How is the JSON state file written — by Claude (via Write/Edit each turn) or by a sidecar script? **Recommended default: by Claude directly.** Sidecar script adds a dependency and a failure mode the simpler path avoids.
- [x] **Q4**: Should there be a token/turn budget cap to prevent runaway sessions? **Resolved: no hard cap v1, but the checkpoint emitted every 5–7 turns is the soft budget** — it surfaces counts and offers `/brainstorm done` as one of the three branches, so the user has a natural exit pulse without an arbitrary cap. Revisit if real usage shows multi-hour sessions burning context.
- [x] **Q5**: Should the HTML render include a "download as markdown" button for promoting material into a spec? **Resolved: yes, v1.** The user's stated intent — *"usuário ao final decide o que fazer com os artefatos gerados do brainstorm"* — makes promotion into a spec a first-class flow. A `Copy as markdown for /sdd new` button costs ~15 lines of JS over the same state JSON; not worth deferring. Acceptance criterion added accordingly.

## Context / references

**Existing rules / capacities this builds on:**

- `.claude/rules/spec-driven.md` — `/brainstorm` sits *before* `/sdd refine` in the ideation→spec pipeline; brainstorm is divergent, refine is convergent
- `.claude/rules/research-before-proposing.md` — research findings on existing brainstorm skills cited below
- `.claude/skills/sdd/SKILL.md` — pattern for skill structure (frontmatter, subcommands, `templates/` + `references/` dirs)
- `.claude/skills/remind/SKILL.md` — pattern for state + subcommands; differs in that `.claude/REMINDERS.md` is git-tracked, while brainstorm state follows the gitignored-state pattern of `.runtime-state/`, `.browser-state/`, `.delegation-state/`
- `.claude/rules/harness-sync.md` — `.claude/skills/` is in sync-harness scope; the new skill propagates to forks automatically. The runtime state dir is NOT in sync scope by design (project-local data)
- `.claude/rules/memory-placement.md` — this is a behaviour capacity that ships to forks, consistent with memory `feedback_agent0_changes_ship_via_rules_not_memory.md`

**External research (research-before-proposing satisfied):**

- [MadeByTokens/claude-brainstorm](https://github.com/MadeByTokens/claude-brainstorm) — Claude Code plugin that forces divergent thinking via `UserPromptSubmit` hook; subcommands `start/fork/back/status/done`. Influence: subcommand naming (`start`/`done`); divergence-enforcement absorbed as soft guidance in SKILL.md prose rather than a hard hook (less infra)
- [scottd3v Brainstorming Skill gist](https://gist.github.com/scottd3v/1880ed0e96d5d7c6b1981fa3cb5767ef) — forces design conversation pre-code; 1 question per message. Influence: "challenge the idea twice" discipline carried over from `sdd refine`
- [Edward de Bono — Six Thinking Hats](https://juuzt.ai/knowledge-base/prompt-frameworks/the-six-thinking-hats-framework/) — White/Red/Black/Yellow/Green/Blue perspective lenses
- [SCAMPER guide](https://www.designorate.com/a-guide-to-the-scamper-technique-for-creative-thinking/) — Substitute / Combine / Adapt / Modify / Put to another use / Eliminate / Reverse
- [Reverse Brainstorm + Crazy 8s](https://conceptboard.com/blog/brainstorming-techniques-templates/) — divergence-forcing variants
- [markmap](https://markmap.js.org/) and [mermaid.js mindmap](https://mermaid.js.org/syntax/mindmap.html) — candidate render targets; mermaid wins for single-file embedding via one CDN script

**Originating conversation context:**

- Session "prosa" (2026-05-16) — user critiqued an earlier deliverable with *"isso não é uma spec, é um brainstorm"*, seeding this skill's existence. The hybrid A→B design (free-form first, lenses on demand) was chosen after the user explicitly asked for a mix between Design A (conversational) and Design B (framework-driven with phases). Design C (live render with auto-refresh server) was rejected as over-engineered.
