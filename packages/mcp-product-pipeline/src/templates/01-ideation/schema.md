# Step 1 — Schema (required sections)

The submitted concept brief MUST contain a level-2 markdown heading (`## <Title>`) whose slug matches each of the entries below. Slugs are computed by lowercasing the title and replacing any non-alphanumeric run with a single dash. So `## Target Audience` slugifies to `target-audience` and matches.

`product_step_submit` rejects with `code: "schema-incomplete"` and the `missing` array listing the slugs you forgot. Add the missing headings and resubmit.

## Required sections

- concept
- target-audience
- differentiation
- risks
- sources

## Recommended additional sections (not required, but useful for downstream steps)

- comparables — 2-3 inspirations with what's borrowed from each
- hook — why someone signs up the first time
- retain — why they stay past month 3
- success-metric — what 6-month success looks like (number + behavior)
- assumptions — the single load-bearing assumption that kills the idea if wrong

These optional sections are NOT validated by the MCP. They are listed so a thorough agent has a structural target richer than the bare minimum. Downstream steps (2 prototype, 3 spec, 8 prd) will read them when present and skip when absent.

## Section content guidance

- **concept** — one sentence ("what is this?") + one paragraph elaborating. The sentence must work as a tweet; if it doesn't fit in 280 chars it needs sharpening.
- **target-audience** — name the persona by role + context, not by demographic. "A solo accountant who serves 30 small-business clients" beats "small business professionals". One or two paragraphs.
- **differentiation** — what makes this different from the closest existing option. Name the existing option(s). If the answer is "nothing exists yet", that's a red flag worth surfacing in `risks`.
- **risks** — 2-5 risks specific to this product. Generic ("market may not exist") is wrong; specific ("users won't pay for an AI co-pilot when ChatGPT is free — mitigation: ...") is right.
- **sources** — flat list of URLs / references used for any factual claim. If the brief has no factual claims requiring sources, the section may say "no external sources cited; founder-only synthesis".
