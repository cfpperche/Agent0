# 158 — frontend-designer-skill — plan

_Drafted from `spec.md` on 2026-06-05. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build `frontend-designer` as an `agentskills-portable` skill (canonical at `.agent0/skills/frontend-designer/`, symlinked into `.claude/skills/` and `.agents/skills/`). The skill is **prompt-driven for the craft** (taste, design judgment, code) and **script-backed for the deterministic mechanics** (stack/design-system detection, artifact-path resolution, doc scaffolding, the verify-contract wrapper). This split keeps the agent free to be the "artist" while the boring/repeatable parts stay mechanical and testable.

Order of build: (1) scaffold via `/skill new --tier agentskills-portable`; (2) write the single helper script `frontend-designer.sh` with deterministic subcommands + a bats-free shell test; (3) author the SKILL.md body (modes, stack ladder, craft loop, artifacts, done-proof, native-honesty, deps); (4) author the `references/` deep-dive docs and `templates/`; (5) wire the capacity into `CLAUDE.md` + a context rule + memory + harness-sync baseline; (6) validate with `/skill validate`; (7) dogfood (separate task phase).

The done-proof deliberately **reuses** `agent-browser.sh verify-contract` (spec 155) — the skill writes the fixture-spec and calls the existing tool; it adds no acceptance machinery. The stack ladder and native-honesty rules are the two load-bearing anti-drift constraints from the meeting.

## Files to touch

**Create (skill body):**
- `.agent0/skills/frontend-designer/SKILL.md` — main skill doc (compliant frontmatter + body).
- `.agent0/skills/frontend-designer/scripts/frontend-designer.sh` — deterministic helper with subcommands: `detect <path>` (framework + design-system + `/product` artifacts + browser-renderable harness, emits JSON), `artifacts-dir <path> [--spec NNN] [--surface S]` (resolve the git-tracked doc location), `scaffold-docs <path> --surface S [--spec NNN]` (write the `reference-research.md` + `design-direction.md` pair from templates), `verify <url> <fixture> <outdir>` (thin wrapper over `agent-browser.sh verify-contract`, fail-closed when unavailable), `caps` (report hard-dep availability).
- `.agent0/skills/frontend-designer/templates/reference-research.md.tmpl`
- `.agent0/skills/frontend-designer/templates/design-direction.md.tmpl`
- `.agent0/skills/frontend-designer/templates/fixture-spec.json.tmpl` — a verify-contract fixture starter (render tier).
- `.agent0/skills/frontend-designer/references/craft-loop.md` — the research→direction→implement→drive→critique→refine loop + explicit stop criteria + max-iteration bound.
- `.agent0/skills/frontend-designer/references/stack-ladder.md` — the detection ladder + detect-don't-impose tool catalog (all free, local+remote).
- `.agent0/skills/frontend-designer/references/reference-research.md` — how to research references (web + agent-browser + rg) and the artifact contract.
- `.agent0/skills/frontend-designer/references/done-proof.md` — spec-155 reuse + native-honesty evidence rules.
- `.agent0/skills/frontend-designer/tests/01-detect-and-artifacts.sh` — shell test for the deterministic subcommands (TDD: red→green).

**Create (discovery + integration):**
- `.claude/skills/frontend-designer` → `../../.agent0/skills/frontend-designer` (symlink).
- `.agents/skills/frontend-designer` → `../../.agent0/skills/frontend-designer` (symlink).
- `.agent0/context/rules/frontend-designer.md` — the capacity rule (when to use vs `/product` vs visual-contract; the anti-drift constraints).

**Modify:**
- `CLAUDE.md` — add a `## Frontend designer` capacity-index block.
- `.agent0/harness-sync-baseline.json` — register the new tracked files (via the sync tool's regen, not hand-edit).
- `.agent0/memory/` + `MEMORY.md` — if a non-obvious project fact emerges (e.g. the boundary decision); only if it isn't already in the rule.

## Alternatives considered

### Make it a `/product` mode (`/product --implement`)
Rejected — `/product` is docs-first planning with a hard "no runnable app" boundary; bolting a build loop on it would blur the lifecycle the meeting explicitly kept separate (D1) and bloat an already-15-step pipeline.

### Pure prompt skill, no helper script
Rejected — stack/design-system detection, artifact-path resolution, and the verify wrapper are deterministic and benefit from a tested script; leaving them to free-form prompting invites drift and makes acceptance untestable. (The *craft* stays prompt-driven; only the mechanics are scripted.)

### Invent a "design quality score" / new acceptance gate
Rejected — spec 155 already proves UI by driving it; a parallel gate is harness-drift and fails the rule-of-three demand test. Reuse, don't reinvent.

### Ship per-platform starter templates (web/mobile/desktop)
Rejected — violates the repo's no-shipped-stack-opinions rule; the stack ladder + detection replaces frozen templates.

## Risks and unknowns

- **`agent-browser` availability on this machine** — the dogfood's web demos need it. Mitigation: `caps` subcommand reports availability; if absent, the skill (and the dogfood) treat browser visual proof as a blocker and the non-web demo's honest-fallback path still demonstrates value. Will verify availability before the dogfood phase.
- **`explore` mode scope creep** — risk it becomes `/product`-lite. Mitigation: spec'd narrow (research + direction, no code), flagged as the open question to re-evaluate after dogfood.
- **Native render evidence** — the no-DS non-web demo may not achieve real render evidence; spec already permits the honestly-labeled fallback. Accept.
- **Skill body size** — keep SKILL.md focused; push depth into `references/` (the 200 KB catastrophe cap is not a concern, but the agentskills frontmatter + a readable body are).

## Research / citations

- `.agent0/meetings/frontend-designer-skill-design-2026-06-06T01-30-48Z/meeting.md` — decision-grade synthesis (Claude + Codex), ledger path-anchored.
- `.agent0/context/rules/visual-contract.md`, `.agent0/tools/agent-browser.sh` — the reused done-proof primitive.
- `.claude/skills/skill/SKILL.md` §§ `new`/`validate`; `references/portability-tiers.md` — scaffolding + tier rules.
- `.claude/skills/product/SKILL.md` — the planning/craft boundary.
