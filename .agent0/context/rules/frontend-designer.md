---
paths:
  - ".agent0/skills/frontend-designer/**"
  - ".claude/skills/frontend-designer"
  - ".agents/skills/frontend-designer"
---

# Frontend designer

`/frontend-designer` is the build-time **craft loop** — the "artist" that designs or refines a *real, runnable* frontend with taste. It fills the implementation gap between `/product` (docs-first planning; no runnable app) and the spec-155 **visual-contract acceptance gate** (proves built UI by driving it). It graduated from a decision-grade `/meeting` (Claude + Codex) and is built as spec `docs/specs/158-frontend-designer-skill/`. (spec 158)

## When to use vs siblings

| Tool | Role |
|---|---|
| `/product` | product *planning* — concept→PRD→design-system doc→design-time visual contract; **no runnable app** |
| `/frontend-designer` | build-time *craft* — research references, ground in domain, reuse the DS, implement/refine UI, prove by driving |
| visual-contract gate (spec 155) | *acceptance* — proves a built UI works; `/frontend-designer` reuses it as done-proof |

## Load-bearing constraints (from the meeting synthesis)

- **Three modes, explicit contracts.** `create` (greenfield UI slice in the project's stack), `refine` (improve existing UI in its stack — bounded diff, before/after evidence, preserved behavior), `explore` (research + design-direction only, no code; narrow, not `/product`-lite).
- **No frozen stack opinions.** Stack resolves via a project-derived ladder (existing stack+DS → `/product` system-design → user hint → research+record-decision); never a bundled skeleton/default. Existing design systems are reused, not reinvented. (project memory `feedback_no_shipped_stack_opinions`)
- **Reference research is mandatory + artifacted** — a git-tracked `reference-research.md` + `design-direction.md` pair per surface (active SDD spec dir, else `docs/design/<surface>/`). Mechanisms are free, local+remote: web search/fetch + `agent-browser.sh` screenshots + `rg` repo scan.
- **Done-proof reuses spec 155** — browser-renderable output ⇒ `UI impact` + green `agent-browser verify-contract` `report.json`. **`agent-browser` unavailable is a BLOCKER, never a pass** (`scripts/frontend-designer.sh verify` exits rc 4). Native-only surfaces use a project web harness if present, else honest, **labeled** native build/test evidence — never a false visual-contract claim, and **no new native visual tooling** (rule-of-three demand test).
- **The "artist" is context-engineering, not a persona** (project memory `feedback_no_persona_role_prompting`). Taste comes from grounding + the see-and-critique loop, bounded by explicit stop criteria + a max-iteration cap.
- **Dependency footprint is tiny:** shell, `rg`, `jq`, the project package manager, `agent-browser.sh`; everything else detect-don't-impose. No global design dashboard / reference cache (harness-drift).

## Files

Skill canonical: `.agent0/skills/frontend-designer/` (`SKILL.md`, `scripts/frontend-designer.sh`, `templates/`, `references/{craft-loop,stack-ladder,reference-research,done-proof}.md`, `tests/`), discovered via `.claude/skills/frontend-designer` + `.agents/skills/frontend-designer` symlinks. Deterministic mechanics: `scripts/frontend-designer.sh` (`caps | detect | artifacts-dir | scaffold-docs | verify`).
