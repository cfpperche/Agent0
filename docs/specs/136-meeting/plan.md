# 136 — meeting — plan

_Drafted from `spec.md` on 2026-06-02. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build `/meeting` as an **`agentskills-portable` skill** (runtime-neutral — any runtime can be the active orchestrator) whose body is thin conversational orchestration over a **deterministic state-machine script** plus an existing transport (the `codex-exec`/`claude-exec` subprocess bridges). The one Claude-only affordance, the synthesis human gate, degrades from `AskUserQuestion` to a plain-prose question in runtimes without it — so the skill is not locked to Claude Code despite being authored from it. The split honors the debate's central resolution: *turn legality and meeting state live in explicit machine-readable state, not in prose*. So the design has three layers:

1. **State layer (`scripts/meeting.sh`)** — owns the `meeting.md` YAML front-matter header (participant registry, `turn_counter`, `next_speaker`, `synthesis` status). Subcommands `init | state | next | check | advance | append-turn` are pure, testable bash. This is what makes the "fresh runtime reads the header alone and knows whose turn is legal" and "single-owner write per turn" criteria mechanical and unit-testable.
2. **Transport layer (reused)** — when the next speaker is a *peer* runtime, the active runtime invokes it via `codex-exec.sh` / `claude-exec.sh` (read-only sandbox), receives `last-message.md` (structured turn text only), and the **active runtime appends it** via `append-turn`. When the next speaker IS the active runtime, it generates its turn inline and appends — no subprocess. Symmetric: the same SKILL.md works whether Claude Code or Codex CLI is the active orchestrator, by comparing the speaker to the runtime's own identity (the `debate.md` self-identity pattern).
3. **Skill body (`SKILL.md`)** — parses `$ARGUMENTS`, runs the `start | turn | synthesize` workflow, composes turn prompts, calls the script, and drives the human gates (synthesize → accept/redirect/end; graduate → `/sdd refine` seed context). Human-orchestrated only in v1; LLM-as-orchestrator is documented as a deferred experimental mode, not implemented.

**Artifact lifecycle + location decision (resolves the open question):** meetings are **git-tracked, project-local, and NOT propagated to consumers**, stored under `.agent0/meetings/<slug>-<ts>/meeting.md`. Rationale (corrected during review): the distinguishing axis is not propagate-vs-not (memory, routines, reminders are all durable + project-local + non-propagated yet live in `.agent0/`), but *artifact nature* — meeting transcripts are **skill-operated structured state** (a machine-readable header driven turn-by-turn), the same profile as `.agent0/routines/`, and they are ideation-pipeline artifacts whose sibling `/brainstorm` also lives under `.agent0/`. Only the *formal* pipeline output (a spec) belongs in `docs/`. Non-propagation is achieved the same way as memory/routines: the path is deliberately excluded from the sync-harness `COPY_CHECK_*` manifest, and only a `.gitkeep` ships so a fresh consumer gets the empty dir. Differs from `/brainstorm` only in being git-tracked (durable) rather than gitignored (ephemeral). No auto-commit.

Build order: state script + tests first (red→green, the only mechanical surface), then the template, then the SKILL.md body, then the rule + index blocks, then validation.

## Files to touch

**Create:**
- `.agent0/skills/meeting/SKILL.md` — the skill (frontmatter cc-native; subcommands `start | turn | synthesize`; argument parsing; turn orchestration; human gates).
- `.agent0/skills/meeting/scripts/meeting.sh` — deterministic state-machine over the `meeting.md` YAML header (`init | state | next | check | advance | append-turn`).
- `.agent0/skills/meeting/templates/meeting.md.tmpl` — transcript scaffold: YAML header + body skeleton (`# Meeting`, turn-section convention, `## Synthesis`).
- `.agent0/skills/meeting/references/turn-prompt.md` — the prompt template the active runtime fills when invoking a peer participant via the exec bridge (context = topic + transcript-so-far + this-turn instruction + optional `--web`/`Sources:` requirement).
- `.agent0/context/rules/meeting.md` — the canonical rule: format/header schema, workflow contract, transport semantics, research-backed turns, graduation-to-spec, files, discipline, gotchas, cross-references; plus a `## Notes` consumer-extension section.
- `.agent0/tests/meeting/` — `_lib.sh`, `run-all.sh`, and numbered tests (`01-init`, `02-check-legality`, `03-advance-roundrobin`, `04-append-turn-single-writer`, `05-state-readout`, `06-synthesis-status`).
- `.claude/skills/meeting` → `../../.agent0/skills/meeting` (symlink; Claude discovery).
- `.agents/skills/meeting` → `../../.agent0/skills/meeting` (symlink; Codex discovery — the skill is symmetric).
- `.agent0/meetings/.gitkeep` — ships the empty meetings dir to a fresh consumer (mirrors `.agent0/routines/.gitkeep`); transcript *content* is project-local and not propagated.

**Modify:**
- `CLAUDE.md` — add `## Meeting` section inside the `<!-- AGENT0:BEGIN/END -->` managed block (between `## Product skill` and `## Routines`).
- `AGENTS.md` — add the parallel `## Meeting` section inside its managed block.
- `.agent0/tools/sync-harness.sh` — add `.agent0/meetings/` to the project-local non-propagated comment block and add `.agent0/meetings/.gitkeep` to `COPY_CHECK_FILES` (so the empty dir ships but transcripts stay local), mirroring `.agent0/routines/`.
- `.gitignore` — no change needed (transcripts are git-tracked under `.agent0/meetings/`, not gitignored).

**Delete:** none.

## Alternatives considered

### Generalize `debate.md` / `/sdd debate` in place instead of a new skill

Rejected (founder decision 2026-06-02): the placement question was resolved in favor of a dedicated `/meeting` skill. Overloading `/sdd debate` would force its strict two-role turn-prerequisite gating to absorb N-party + free-topic + intermittent-human semantics, breaking the very property (deterministic two-slot legality) that makes it reliable. A separate skill reuses the *pattern* (shared file + self-identity role detection) without contaminating the debate contract.

### Pure-prose `meeting.md` (no state script), legality inferred from round headers like `debate.md`

Rejected per the Codex debate (Round 1 critique #3): prose-header inference works at exactly two roles but does not survive N>2 (no placeholder belongs uniquely to one runtime; a fresh runtime cannot tell whose turn is legal, whether a run is mid-orchestration, or whether a subprocess wrote-then-failed). An explicit machine-readable header carried by a tested script is the resolution the debate converged on.

### Persistent broker/daemon coordinating live multi-agent chat (AutoGen GroupChatManager style)

Rejected: violates the spec's no-new-persistent-infra constraint and Agent0's anti-runaway posture. AutoGen/AG2's own docs frame large-group speaker control as hard; the value of multi-agent *debate* (Du et al.) comes from bounded rounds, which the turn-based subprocess model already delivers without a daemon.

### Child subprocess writes `meeting.md` directly

Rejected per debate Round 1 critique #6 + Round 2 accept: the exec bridges default to read-only and are bounded, not persistent peers. Letting the child write needs write-grants, conflict rules, and attribution. Instead the child returns structured turn text and the single active runtime appends — single-owner write per turn, auditable failures.

## Risks and unknowns

- **YAML parsing in bash.** We control the header format, so a small `awk`/`sed` parser is adequate — but it must be robust to quoted topic strings with colons. Mitigation: keep header values simple; quote the topic; test with a colon-bearing topic.
- **Symmetric runtime identity.** The skill must detect "am I the active runtime, and is the next speaker me or a peer?" using the runtime's own identity (not a hardcoded literal), mirroring the `debate.md` skill. Risk: a port that hardcodes "Claude Code" breaks for Codex. Mitigation: document the self-identity determination explicitly in SKILL.md, same wording as the debate skill.
- **Header field schema (still open).** Exact field names/format are decided here (YAML front-matter); if dogfood reveals a missing field (e.g. per-turn `web` flag record), extend the template + script together and re-test.
- **`append-turn` atomicity.** A turn append + header advance should not half-apply. Mitigation: `append-turn` does body-append then header-advance in one script invocation; on any failure it exits nonzero before mutating the header.
- **Propagation-advisory hook.** SKILL.md and the rule file are shipped surfaces — must not contain concrete spec-dir paths, spec numbers, personal paths, or memory pointers, or the hook emits advisories. Mitigation: keep both self-contained; reference capabilities, not the spec dir.

## Research / citations

- Group-chat orchestration & speaker selection: [AutoGen/AG2 Group Chat](https://docs.ag2.ai/latest/docs/user-guide/advanced-concepts/groupchat/groupchat/), [AutoGen group chat design pattern](https://microsoft.github.io/autogen/stable//user-guide/core-user-guide/design-patterns/group-chat.html).
- Multi-agent debate value/convergence: [Du et al. 2023, arXiv:2305.14325](https://arxiv.org/abs/2305.14325), [Roundtable Policy, arXiv:2509.16839](https://arxiv.org/pdf/2509.16839).
- Internal conventions consulted: the `/brainstorm` skill (state-file + subcommand shape), the `/sdd debate` skill (self-identity role detection, shared-file-as-state), the `codex-exec`/`claude-exec` skills (transport signatures), the skill portability-tier reference, the harness-sync managed-block + symlink-discovery convention, and the `codex-exec-skill` test harness (`_lib.sh` fake-runtime + `run-all.sh` shape). Full cross-model review in this spec's `debate.md`.
