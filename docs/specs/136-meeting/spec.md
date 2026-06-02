# 136 — meeting

_Created 2026-06-02._

**Status:** shipped

_Implemented + validated 2026-06-02 (full SDD cycle: spec → cross-model debate → plan → tasks → build → validate). 48/48 unit tests pass; the real peer-turn transport seam was exercised end-to-end with a live Codex turn via `codex-exec`. See `plan.md`, `tasks.md`, `debate.md`._

## Intent

`/meeting` is a new Agent0 skill for multi-party, multi-model deliberation — a structured, turn-based conversation between a human (intermittently present), Claude Code, and Codex CLI, convened to think through a project topic or a still-vague idea. It is the *collaborative* sibling of the two single-perspective tools that already exist: `/brainstorm` (one agent diverging) and `/sdd debate` (two agents adversarially reviewing a *locked* `spec.md`). The irreducible job neither of those covers: **N-party cross-model deliberation on an unanchored topic where the human is intermittent** — e.g. Claude and Codex argue out a vague idea while the human is away, then the human reacts to a synthesis.

The primary deliverable of v1 is a **`meeting.md` format + a `/meeting start | turn | synthesize` workflow contract**, **human-orchestrated**. The architectural bet is constrained: **no new *persistent* infra** — no daemon, no broker process, no API key or MCP beyond what `codex-exec`/`claude-exec` already require. Coordination is **per-turn and owned by the single active runtime**: a subprocess participant returns structured turn text, and the active human-facing runtime appends it to `meeting.md` (single-owner write per turn, auditable failures). The shared-file-as-state pattern is borrowed from `debate.md`, but turn legality is carried by an **explicit machine-readable metadata header**, not by prose round structure.

v1 wires exactly two model runtimes (Claude Code + Codex CLI) plus the intermittent human; the `meeting.md` format is *designed for* N parties, but v1 is honestly "2 models + human," not N-party. Any participant may take a **research-backed turn** that cites its sources. Output is a git-tracked transcript plus a synthesis that can become seed context for `/sdd refine`.

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan._

- [x] **Scenario: Convene a meeting on a free topic**
  - **Given** the user invokes `/meeting start "<topic>"` with no pre-existing spec
  - **When** the skill scaffolds the meeting
  - **Then** a `meeting.md` is created with a machine-readable metadata header (topic, convener runtime, participant registry, mode=`human-orchestrated`, turn counter, `next_speaker`/`human_decides`, synthesis status) plus an opening contribution from the convening runtime, and the user is told how to take the next turn

- [x] **Scenario: Human-orchestrated turn (the v1 core loop)**
  - **Given** an in-flight `meeting.md` whose header names the next legal speaker
  - **When** the user invokes `/meeting turn --speaker <runtime|human>`
  - **Then** that participant's contribution is appended to `meeting.md`, the turn counter increments, and the header's `next_speaker` advances — no turn is written for a speaker that is not the next legal one

- [x] **Scenario: Subprocess participant returns text; active runtime owns the write**
  - **Given** the active runtime is Claude Code and the next speaker is Codex CLI
  - **When** the turn runs
  - **Then** Codex is invoked via `codex-exec` and returns **structured turn text only** (it does not write `meeting.md` itself), and the active Claude Code runtime appends that text — exactly one writer per turn

- [x] **Scenario: Fresh runtime resolves turn legality from the header alone**
  - **Given** an in-flight `meeting.md`
  - **When** any runtime reads only the metadata header (not the prose body)
  - **Then** it can report whose turn is legal, the current mode, and whether synthesis is pending — the no-broker property is carried by explicit state, not prose

- [x] **Scenario: Research-backed turn cites sources**
  - **Given** a participant takes a turn with the research opt-in (`--web` / "research-backed turn")
  - **When** the contribution is appended
  - **Then** it MUST contain a `Sources:` block listing the URLs used; a research-backed turn without a `Sources:` block fails the check

- [x] **Scenario: Human reacts only to the synthesis**
  - **Given** a meeting that ran several turns without the human speaking
  - **When** the user asks any participant to "synthesize the meeting"
  - **Then** a `## Synthesis` section is written naming the synthesizing runtime, the convergence, the recorded disagreements, and a recommended next step; the human can accept / redirect / end, and each choice writes a defined outcome to the artifact

- [x] **Scenario: Graduate to a spec as seed context**
  - **Given** a synthesized meeting whose recommended next step is "spec candidate"
  - **When** the user accepts
  - **Then** the synthesis is handed to `/sdd refine` as **seed context for its interview** (it does not bypass the interview nor silently produce a finished spec), and `meeting.md` is linked from the resulting spec's `## Context / references`

- [x] `.agent0/skills/meeting/SKILL.md` exists and passes the agentskills.io frontmatter spec (`/skill validate meeting`)
- [x] The `meeting.md` format + location convention are documented in a new `.agent0/context/rules/meeting.md` rule, and `CLAUDE.md` carries a managed index block for it
- [x] The capacity adds **no** new persistent broker/daemon, API key, or MCP dependency beyond what `codex-exec`/`claude-exec` already require

## Non-goals

_What this change explicitly does NOT do. Future scope or adjacent problems that look similar but aren't in this spec._

- **LLM-as-orchestrator autonomy in v1.** v1 is human-orchestrated only. A future experimental mode (`/meeting run --turns N --orchestrator <runtime> --confirm-cost`, gated on hard turn/cost/permission limits) is deferred until manual alternation is shown to be the bottleneck across ≥3 real meetings (rule-of-three). This honors the user's "any LLM can orchestrate" intent as a roadmap, not a v1 contract.
- **Real-time / concurrent multi-session chat.** Turn-based, mediated by subprocess bridges; no live websocket room, no simultaneous typing.
- **More than two wired runtimes in v1.** v1 wires Claude Code + Codex CLI (the runtimes with existing exec bridges). The format must not *preclude* a third, but adding one is future scope.
- **Theatrical personas.** Participants are not assigned role-play identities ("the skeptic", "the PM"). **In scope, distinct from this:** explicit *contribution briefs* ("take a security-review lens", "argue the cost angle") — task framing is context-engineering, not persona-prompting.
- **A live HTML/GUI view.** No `/brainstorm`-style HTML parity in v1; the human scans the plain-markdown transcript (the metadata header gives a quick state read; the body is chronological). A rendered view may come later.
- **Replacing `/brainstorm` or `/sdd debate`.** Neither is deleted. `/meeting` reuses their primitives where it can.
- **Autonomous unbounded LLM-to-LLM looping.** No fire-and-forget swarm; the v1 loop has a human at every turn boundary.

## Open questions

_Unknowns to resolve before `plan.md` can be locked. Each should have an owner (who decides) or a path to resolution._

- [ ] **Artifact lifecycle & location.** Git-tracked design memory (like `debate.md`/specs) or gitignored throwaway state (like `.brainstorm-state/`)? Lean: git-tracked under the spec/topic it serves, since a meeting can graduate to a spec and is a decision record — but confirm with founder. (Owner: founder; decide at `/sdd plan`.)
- [ ] **Metadata header schema detail.** The *decision* is made (explicit machine-readable header); the exact fields/format (YAML front-matter vs a fenced block, participant-ID scheme, `Sources:` block shape) are a `plan.md` design task. (Resolution: `/sdd plan`.)

### Resolved during the Codex debate (see `debate.md`)

- **Capacity boundary** — RESOLVED: `/meeting` ships as a **new skill** (founder decision, 2026-06-02). The contract is identical whether hosted as a new skill or an extension, and the founder chose a dedicated skill.
- **Orchestration model** — RESOLVED: **human-orchestrated v1**; LLM-orchestrator autonomy deferred to a cost-gated experimental mode (see Non-goals).
- **Transcript schema** — RESOLVED (design): turn legality lives in an **explicit metadata header**, not prose round structure; field-level detail deferred to `plan.md`.
- **Speaker selection** — moot for v1 (human picks the speaker per turn); revisits only if the experimental orchestrator mode is built.
- **Convergence / stop semantics** — RESOLVED: human-decided (like `/sdd debate`); no auto-stop in v1.

## Context / references

_Links to related specs, prior art, issues, docs, conversations._

- Cross-model review of this spec: `docs/specs/136-meeting/debate.md` (initiating: Claude Code; reviewing: Codex CLI; resolution: converged).
- Existing Agent0 capacities this builds on / overlaps: `/sdd debate` (`.agent0/skills/sdd/SKILL.md` § Subcommand debate; `docs/specs/` debate.md pattern), `/brainstorm` (`.agent0/skills/brainstorm/`), `codex-exec` (spec 128, `.agent0/skills/codex-exec/`), `claude-exec` (spec 129, `.agent0/skills/claude-exec/`).
- Prior art — group-chat orchestration & speaker selection: [AutoGen / AG2 Group Chat patterns](https://docs.ag2.ai/latest/docs/user-guide/advanced-concepts/groupchat/groupchat/) (AutoPattern / RoundRobin / Random / Manual speaker selection), [AutoGen Group Chat design pattern](https://microsoft.github.io/autogen/stable//user-guide/core-user-guide/design-patterns/group-chat.html) (manager loop: select speaker → respond → broadcast).
- Prior art — multi-agent debate value & convergence: [Du et al., Improving Factuality and Reasoning through Multiagent Debate (arXiv:2305.14325)](https://arxiv.org/abs/2305.14325), [MIT News summary](https://news.mit.edu/2023/multi-ai-collaboration-helps-reasoning-factual-accuracy-language-models-0918), [Roundtable Policy: confidence-weighted consensus (arXiv:2509.16839)](https://arxiv.org/pdf/2509.16839), [Sparse Communication Topology for debate (arXiv:2406.11776)](https://arxiv.org/html/2406.11776v1).
- Project rules in scope: `.agent0/context/rules/spec-driven.md`, `.agent0/context/rules/runtime-capabilities.md`, `.agent0/context/rules/harness-sync.md`, `.claude/skills/skill/` (skill-compliance toolkit).
