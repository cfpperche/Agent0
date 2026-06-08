# 168 - agent0-roadmap-html - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build a single standalone page at `docs/agent0-roadmap.html` with inline CSS and a small inline script for filtering roadmap nodes. Use a roadmap.sh-inspired information architecture: header, category chips, grouped roadmap nodes, status legend, and clear "today vs missing" states. Keep it visually distinct enough to avoid copying roadmap.sh branding or assets.

Use `/frontend-designer` discipline without adding a stack: write `reference-research.md`, `design-direction.md`, and a render-tier fixture. Verify with `agent-browser` against the static HTML file.

## Files to touch

**Create:**
- `docs/agent0-roadmap.html` - standalone roadmap page.
- `docs/specs/168-agent0-roadmap-html/spec.md` - intent and acceptance criteria.
- `docs/specs/168-agent0-roadmap-html/plan.md` - implementation plan.
- `docs/specs/168-agent0-roadmap-html/tasks.md` - execution checklist.
- `docs/specs/168-agent0-roadmap-html/notes.md` - in-flight design memory.
- `docs/specs/168-agent0-roadmap-html/reference-research.md` - frontend-designer reference research.
- `docs/specs/168-agent0-roadmap-html/design-direction.md` - frontend-designer direction.
- `docs/specs/168-agent0-roadmap-html/fixture-spec.json` - render-tier visual-contract fixture.

**Modify:**
- `.agent0/HANDOFF.md` - refresh current state after delivery.

**Delete:**
- None.

## Alternatives considered

### Add an Astro route under `site/src/pages`

Rejected for v1 because the user asked for an HTML page "here in Agent0". A standalone file is easier to inspect, avoids site build churn, and does not add a dependency on the Astro site being the canonical doc surface.

### Generate the roadmap from specs/rules

Rejected for v1 because the content taxonomy is still being shaped. Manual curation is the right first artifact; generation can be considered after repeated updates prove the schema.

### Copy roadmap.sh visual treatment closely

Rejected because the goal is to imitate the roadmap pattern, not clone branding or assets. The page borrows high-level patterns only: categories, roadmap cards, connected nodes, and status labels.

## Risks and unknowns

- The page may become stale if specs advance and the roadmap is not updated.
- Too much visual density can make the page less useful than a simple table.
- Manual status labels need to stay honest: "missing" should mean deferred/not-built, not implicitly approved.
- Static file verification must not rely on a dev server remaining alive.

## Research / citations

- `https://roadmap.sh/`
- `https://roadmap.sh/roadmaps/?g=Web+Development`
- `.agent0/context/rules/agent0-governance-doctrine.md`
- `.agent0/context/rules/scope-admission-governance.md`
- `.agent0/context/rules/runtime-capabilities.md`
- `.agent0/HANDOFF.md`
