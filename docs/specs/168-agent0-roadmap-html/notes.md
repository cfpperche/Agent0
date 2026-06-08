# 168 - agent0-roadmap-html - notes

## Design decisions

### 2026-06-08 - parent - Standalone HTML

The page is implemented as `docs/agent0-roadmap.html` instead of an Astro route. This keeps the artifact directly openable and avoids making the existing site build the owner of this governance visualization.

### 2026-06-08 - parent - Manual roadmap data

Roadmap data is curated manually from current rules/specs. Generation from specs can be reconsidered only after the page proves useful and the status taxonomy stabilizes.

## Deviations

None.

## Tradeoffs

### 2026-06-08 - parent - Inspired by roadmap.sh, not cloned

The layout borrows high-level roadmap patterns from roadmap.sh, but uses Agent0-specific copy, palette, and structure. No roadmap.sh assets or source code are copied.

## Open questions

None for this spec beyond the follow-up questions in `spec.md`.
