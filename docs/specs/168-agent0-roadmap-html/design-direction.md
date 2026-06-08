# Design direction - agent0-roadmap

_Created 2026-06-08 by /frontend-designer. Git-tracked decision record._

## Stack & design-system resolution

- **Platform / framework:** standalone HTML/CSS/JS file.
- **Design system:** proposing local page tokens because root Agent0 has no resolved app design system.
- **Resolution rung:** user asked for an HTML page, and `frontend-designer.sh detect .` reported `framework: unknown`, `design_system: none`, `browser_renderable: no`.

## Tokens

- **Color:** warm off-white background, black text, ink borders, green shipped chips, amber deferred chips, red rejected chips, blue instrument-only chips, violet meta accents.
- **Type:** system UI for prose; monospace for spec IDs and rule paths.
- **Spacing / radius / elevation:** compact roadmap cards with 6px radius, dense grid spacing, thin connector lines, no nested cards.
- **Motion:** small hover/focus transitions only; no auto animation.

## Direction

The page should feel like a developer roadmap artifact, not a marketing page: dense, scannable, and explicit about status. It borrows roadmap.sh's category browsing and connected-node mental model while staying Agent0-specific: governance layers are the main rows, and every node is labeled as shipped, active, deferred, missing, or rejected.

## Surfaces & components

- Standalone roadmap page at `docs/agent0-roadmap.html`.
- Header with title, subtitle, snapshot date, and status summary.
- Filter chips for all/shipped/missing/deferred/security/context/runtime.
- Connected roadmap map grouped by governance layer.
- Side rail explaining "Hoje" and "Falta fazer".
- Legend and source list.

## Acceptance (done-proof)

- **UI impact:** render
- **Verify:** `bash .agent0/tools/agent-browser.sh verify-contract <url> docs/specs/168-agent0-roadmap-html/fixture-spec.json <outdir>` -> green `report.json`.
- **Stop criteria:** desktop and mobile render without text overlap; roadmap heading, filter controls, shipped/missing summaries, and source links are visible.
