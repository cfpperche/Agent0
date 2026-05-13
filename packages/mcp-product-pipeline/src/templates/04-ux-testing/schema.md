# Step 4 — Schema (required sections)

## Required sections

- validation-mode
- evidence
- verdict
- post-launch-signal

## Required line (regex-extracted by MCP)

The artifact body MUST contain a line matching the pattern:

```
validation_mode: <tested|intuition|not-applicable>
```

Case-insensitive on the key, case-sensitive on the value. Place it near the top of the document so the MCP's regex finds it reliably. `product_step_submit` extracts the value and stores it in `.state.json.validation_mode` for downstream steps.

## Section content guidance

- **validation-mode** — name the declared mode plus 1-2 sentences justifying the choice.
- **evidence** — content depends on mode:
  - `tested`: recruit profile, test tasks, key observations, count of users
  - `intuition`: the articulated bet (segment + comparables + differentiation), with at least 2 named comparable products
  - `not-applicable`: why testing as conventionally defined doesn't fit this product class
- **verdict** — for `tested` mode: PROCEED / PIVOT / KILL plus reasoning. For `intuition`: "PROCEED on bet, validate post-launch via <signal>". For `not-applicable`: "PROCEED to identity phase; validation deferred to post-launch via <signal>".
- **post-launch-signal** — what observable signal (metric, behavior, market response) will retroactively confirm or refute the validation choice. Required for all modes (even `tested` benefits from a confirming signal). Be concrete: "DAU > 100 in week 4", "PyPI downloads > 200 in month 1", "5 unsolicited inbound demo requests".
