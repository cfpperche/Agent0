# Step 7 — Schema (required sections)

## Required sections

- screens-with-tokens
- copy-with-voice
- state-coverage
- patterns-applied

## Recommended additional sections

- flow-changes — if v2 differs from v1's user flow, document the deltas with reasoning
- token-gaps — design-system gaps surfaced while applying tokens (forwarded back to step 6 for next iteration)

## Section content guidance

- **screens-with-tokens** — per screen, list of components used (with variant) + token references for color/typography/spacing. Replace v1's prose with explicit references.
- **copy-with-voice** — all user-facing strings on each screen, written in brand voice. Error messages, button labels, empty states, modals. Concrete strings, not placeholders.
- **state-coverage** — per component on each screen, name how its states render (loading skeleton, empty state, error, success, disabled).
- **patterns-applied** — walk-through showing where step 6's named patterns appear in the prototype. If any pattern from step 6 is unused, flag it.
