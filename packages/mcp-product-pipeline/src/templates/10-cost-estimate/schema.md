# Step 10 — Schema (required sections)

## Required sections

- pricing-model
- build-cost
- run-cost
- break-even

## Recommended additional sections

- revenue-projection — ARR estimates at 100/1000/10000 users at conservative paid conversion rates (revenue-generating products only)
- unit-economics — per-user run cost vs per-user revenue, CAC placeholder, payback period back-of-envelope
- sensitivity-callouts — assumptions whose small changes materially change the model

## Section content guidance

- **pricing-model** — declared model (free / freemium / one-time / subscription / usage-based / hybrid / not-for-profit) + one paragraph rationale tied to PRD audience.
- **build-cost** — range estimate for v1 scope. Dev-time-in-weeks + $/hr × hours = $-range. Mark `[Estimated]`.
- **run-cost** — per-month line items at v1 scale assumption. Each line: vendor name, tier, monthly cost. Total. Use current vendor pricing where available; mark scale-extrapolated numbers `[Estimated]`.
- **break-even** — at what user count revenue covers run cost. State assumption (paid conversion rate, average price) used.
