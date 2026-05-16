# 031 — brainstorm — plan

_Drafted from `spec.md` on 2026-05-16. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship `/brainstorm` as a **prompt-driven skill** (no hooks, no validators, no settings.json changes), modelled on the structure of `.claude/skills/sdd/` — the closest existing analogue. The skill's behaviour is encoded in `SKILL.md` prose; Claude interprets it on invocation and conducts the session using ordinary tool calls (`Write` for state file, `Read` for techniques reference, `Write` for final HTML). Divergence discipline is enforced *socially* via SKILL.md instructions ("offer 3 branches at every checkpoint", "do not converge prematurely"), not via a `UserPromptSubmit` hook that intercepts every turn — the [MadeByTokens path](https://github.com/MadeByTokens/claude-brainstorm) was rejected because hook-driven enforcement is heavy infra for a capability whose value is the *conversation*, not the policing of it.

Implementation order is bottom-up to keep validation cheap: techniques reference first (data), then HTML template (rendering), then SKILL.md (orchestration that uses both), then `.gitignore` (one-line addition). Each artefact is independently testable — SKILL.md without the template would still parse and accept invocation; the template with mock data renders standalone in a browser. The final integration test is one real end-to-end session: invoke `/brainstorm start "test"`, contribute a few ideas, apply one lens, run `/brainstorm done`, open the HTML and verify the visualisations render. State JSON is written by Claude directly via `Write`/`Edit` after each substantive turn — no sidecar script (decided as Open Q3 default in spec.md).

## Files to touch

**Create:**

- `.claude/skills/brainstorm/SKILL.md` — frontmatter (`description` + `argument-hint`), subcommands (`start <topic>` / `list` / `resume <slug-or-filename>` / `done`), behavioural rules (divergence discipline, classification taxonomy, checkpoint cadence, lens-application protocol, render protocol). Mirrors `.claude/skills/sdd/SKILL.md` structure (~250-400 lines of markdown)
- `.claude/skills/brainstorm/templates/render.html.tmpl` — single self-contained HTML page; sections: header (topic + timestamp + counts), tabs nav (Exploration always; one per applied lens; Timeline), Exploration tab body (markmap mindmap + kanban-cards grouped by tag + open-questions list + quotes), lens-tab bodies (lens-specific structure), Timeline tab (chronological turn-by-turn rendered as mermaid timeline), footer with `Copy as markdown for /sdd new` button. Inline CSS (vanilla — preferred for offline-fidelity), inline JS (tab switching, markmap+mermaid init, markdown-export clipboard handler over the embedded state JSON), two `<script>` tags for CDN libs: `markmap-autoloader` (mindmap) and `mermaid` (timeline). Placeholders use double-curly Mustache-ish style (`{{TOPIC}}`, `{{IDEAS_JSON}}`, etc.) — substituted by Claude via `Write`, not a templating engine
- `.claude/skills/brainstorm/references/techniques.md` — per-lens spec: short description, when-to-apply heuristic, protocol Claude follows (questions to ask, ways to walk existing ideas through the lens, outputs to capture). Four lenses v1: SCAMPER, Six Thinking Hats, Reverse Brainstorm, Crazy 8s. Each section ~30-60 lines

**Modify:**

- `.gitignore` — append one line: `.claude/.brainstorm-state/` (alongside existing `.claude/.runtime-state/`, `.claude/.browser-state/`, `.claude/.delegation-state/`, `.claude/.rule-load-debug.jsonl` if present — verify current state via `grep .claude .gitignore` during implementation)

**Delete:** none.

**Runtime-created (not in repo):**

- `.claude/.brainstorm-state/<topic-slug>-<ISO-ts>.json` — state file per session (gitignored)
- `.claude/.brainstorm-state/<topic-slug>-<ISO-ts>.html` — rendered output per session (gitignored)

## Alternatives considered

### Alt 1 — Hook-driven enforcement (the MadeByTokens shape)

Reject. A `UserPromptSubmit` hook + `PreToolUse` auto-approval to "force" divergent mode adds two hooks, settings.json mutation, and a kill-switch concept (`/brainstorm:done` as the only escape) to the harness. The Agent0 ethos (see `.claude/rules/delegation.md` § *Gotchas*, the 011-runtime-introspect and 013-lint-validator specs) is to keep hooks for cross-cutting governance and policy gates — discovery / ideation / authoring behaviours are SKILL.md scope. Hook noise also leaks into every conversation in the project, not just brainstorm sessions, which would degrade signal in unrelated work. Cost of policing far exceeds the leak risk we are guarding against ("Claude converges too early") which can be addressed by SKILL.md prose alone.

### Alt 2 — Pure markdown output (no HTML render)

Reject. The user explicitly asked for HTML that "pode ser servido com servidor local para visualização do humano" — visual review is part of the value. Markdown would degrade to ad-hoc bullet lists indistinguishable from a long chat scrollback, which is exactly the gap the skill exists to fill. The MadeByTokens prior art outputs only `.md` and feels weaker for this reason.

### Alt 3 — Live-rendered HTML with auto-refresh (Design C from the conversation)

Reject. Already analysed and discarded in the design discussion preceding spec.md: backgrounded server, websocket or polling, render-on-every-turn latency, browser-launch portability (WSL2 specifically), and modes-of-failure (port collision, dropped websocket, partial-render UI artefacts). Violates the "don't add features the task doesn't require" stance in CLAUDE.md. Single-shot render on `/done` is sufficient.

### Alt 4 — Build the skill as part of `/sdd` (a `/sdd brainstorm` subcommand)

Reject. SDD is explicitly *convergent*: produce a spec. Brainstorm is *divergent*: surface more material. Co-locating them would force one of them to compromise its discipline. The two skills are **adjacent**, not nested — `/brainstorm` outputs HTML; if the user wants to promote brainstorm material into a spec, they call `/sdd new <slug>` manually and reference the HTML as input.

### Alt 5 — Sidecar shell script to manage state JSON

Reject. Adding `.claude/tools/brainstorm-state.sh` to serialise state would introduce a dependency between SKILL.md and a script + a new failure mode (script crash). Claude already has `Write` and `Edit` that can update JSON files atomically. Documented as Open Q3 default in spec.md.

### Alt 6 — Use markmap instead of mermaid for the mindmap (re-decided 2026-05-16)

**Accepted, reversing earlier rejection.** A brainstorm that accumulates 8 ideas × the 7 SCAMPER axes is already ~56 nodes in one section; real sessions could push 100+. [mermaid `mindmap`](https://mermaid.js.org/syntax/mindmap.html) renders that as a cramped graph; [markmap](https://markmap.js.org/) handles it natively with collapse/expand. Markmap also consumes markdown directly — which Claude already produces fluently — so the state→render transform is shorter. The price (one extra CDN script via `markmap-autoloader`) is negligible since we are keeping mermaid anyway for the Timeline tab's chronological flow. Net: markmap for the mindmap, mermaid for the timeline, both via one `<script>` tag each.

## Risks and unknowns

- **Risk: SKILL.md ends up too long to be read in full each invocation.** `/sdd/SKILL.md` is already 220+ lines and the agent reads it on every invocation. Adding lens protocols inline would push brainstorm past 500 lines. Mitigation: keep SKILL.md focused on the orchestration; offload lens details to `references/techniques.md`, loaded on demand only when a lens is applied (same lazy-read pattern `/sdd refine` uses for `references/question-bank.md`).
- **Risk: State JSON file diverges from rendered HTML over a long session.** If Claude updates state after every turn but renders only on `/done`, a crash mid-session leaves orphaned state and no HTML. Mitigation: `/brainstorm resume` reads state directly and continues; final HTML can always be re-rendered. Acceptable failure mode.
- **Risk: User invokes `/brainstorm start` twice for the same topic and clobbers the timestamp-based filename.** Practically impossible (ISO timestamp to the second); but two sessions started within the same second would collide. Mitigation: timestamp to milliseconds, or append a 4-char nonce. Defer until real collision observed.
- **Risk: HTML render fails silently on a browser quirk (markmap or mermaid fails to load, kanban CSS misrenders, clipboard API rejected without https/localhost).** Hard to validate from CLI; needs at least one manual visual check during implementation. Mitigation: implementation includes one end-to-end test (start → ideas → lens → done → open via `python3 -m http.server` so the page is on a localhost origin → verify all sections present AND the `Copy as markdown` button writes to clipboard). `file://` opens may degrade clipboard access on some browsers; the printed instruction defaults to the http.server one-liner.
- **Risk: Claude misclassifies user turns (treats a question as an idea, or vice versa).** Possible. Classification taxonomy in SKILL.md needs explicit examples. Acceptable v1 — user can correct via "actually that was a question" and skill updates the JSON.
- **Risk: `/brainstorm list` becomes useless when state dir has 50+ files.** Mitigation: defer to v2; if needed, add `--last <N>` flag analogous to `/sdd list`.
- **Unknown: Should the JSON be append-only JSONL or rewritten whole each turn?** Whole-file rewrite is simpler (one `Write` call), JSONL is more append-friendly. Default v1: whole-file rewrite. JSONL is the v2 upgrade if we hit perf issues — implausible in interactive sessions.
- **Unknown: How does `Skill` tool invocation interact with `/brainstorm start` having a quoted arg containing spaces?** Need to verify `$ARGUMENTS` parsing handles `start "bolsa de startups"`. Mitigation: SKILL.md will explicitly parse `$ARGUMENTS` like `/sdd` does (split on first whitespace, treat the rest as topic). Verify during implementation.
- **Unknown: Will the harness-sync diff cleanly to forks?** New skill dir under `.claude/skills/` should sync transparently. Worth a smoke test (`bash .claude/tools/sync-harness.sh /tmp/fake-fork --check`) after implementation.

## Research / citations

**Prior art on brainstorm skills / plugins:**

- [MadeByTokens/claude-brainstorm](https://github.com/MadeByTokens/claude-brainstorm) — `UserPromptSubmit` hook approach; subcommand naming (`start`/`done`); divergent-mode discipline. Rejected hook implementation, kept subcommand vocabulary and divergence framing.
- [scottd3v Brainstorming Skill gist](https://gist.github.com/scottd3v/1880ed0e96d5d7c6b1981fa3cb5767ef) — design-conversation-before-code; one-question-per-message discipline. Influence: "challenge the idea twice" carry-over from `sdd refine`.
- [EveryInc compound-engineering-plugin](https://github.com/everyinc/compound-engineering-plugin) — big-picture ideation + critical evaluation routing. Influence: lens-application protocol (lenses revisit ideas rather than restart).
- [ckelsoe/prompt-architect](https://github.com/ckelsoe/prompt-architect) — 7 prompt-engineering frameworks (CO-STAR, RISEN, etc.). Confirms the "library of techniques the agent picks from" pattern is established.

**Brainstorming framework references:**

- [SCAMPER guide — Designorate](https://www.designorate.com/a-guide-to-the-scamper-technique-for-creative-thinking/) — canonical 7-step expansion technique.
- [Six Thinking Hats — Juuzt](https://juuzt.ai/knowledge-base/prompt-frameworks/the-six-thinking-hats-framework/) — de Bono's 6 perspectives.
- [Reverse Brainstorm + Crazy 8s — Conceptboard](https://conceptboard.com/blog/brainstorming-techniques-templates/) — divergence-forcing variants.
- [Creative Sprint mental model — MindMax](https://www.mindmax.me/mental-models/scenes/creative-sprint/) — 2.5h Reverse → 6 Hats → SCAMPER pipeline; informs the lens-chaining option.

**Render technology references:**

- [markmap](https://markmap.js.org/) — chosen for the mindmap render (handles 100+ nodes, native collapse/expand, markdown-in).
- [markmap-autoloader](https://markmap.js.org/docs/packages--markmap-autoloader) — one-script-tag drop-in used by the template.
- [mermaid timeline syntax](https://mermaid.js.org/syntax/timeline.html) — chosen for the Timeline tab chronology.

**Internal references this plan rests on:**

- `.claude/skills/sdd/SKILL.md` — skill structure pattern (frontmatter, subcommand parsing, `templates/` + `references/` dirs).
- `.claude/skills/remind/SKILL.md` — state-file pattern (subcommands operating on a single state artefact).
- `.claude/rules/spec-driven.md` — where brainstorm sits in the ideation→spec pipeline.
- `.claude/rules/harness-sync.md` — confirms `.claude/skills/` is in sync scope; `.claude/.brainstorm-state/` is not.
- `.claude/rules/memory-placement.md` — confirms this is a behaviour capacity that ships to forks via rules+skills (memory `feedback_agent0_changes_ship_via_rules_not_memory.md`).
