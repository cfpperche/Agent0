# `packages/mcp-product-pipeline` — operational quirks

Project-factual knowledge about the product-pipeline MCP that future authors / dogfooders need but isn't load-bearing enough to live in a rule. Migrated from SESSION.md's cumulative gotchas (2026-05-15) per `.claude/rules/session-handoff.md` § Size discipline.

## `required_glob` "one of" pattern — char-class quantifier trap

To express "exactly one of `architecture.html` / `architecture.json`" in a `required_glob`, use:

```json
{ "pattern": "architecture.[hj][a-z]*", "min_count": 1 }
```

NOT `architecture.[hj]*`. `globToRegExp` (in `src/tools.ts`) treats a `*` immediately after a `]` as a **char-class quantifier** (the same code path that supports `[0-9]+`), so `[hj]*` compiles to the regex `[hj]*` (zero-or-more of h/j) — matches nothing useful, including `architecture.html` and `architecture.json`. The trailing `[a-z]*` is the actual wildcard; the `[hj]` then resolves correctly as a literal char class. Surfaced 2026-05-15 during spec 026 task 12 (step 3 spec port — three-artifact bundle with the html-or-json architecture diagram). Documented inline in `templates/03-spec/schema.md`.

## `extractRequiredSections` is greedy on bare-kebab bullets

The section-presence check (`src/tools.ts` `extractRequiredSections`) reads `schema.md` and treats **any** line matching `/^-\s+([a-z][a-z0-9-]*)\s*$/` as a required H2 section the submitted markdown must carry. Concretely: any bullet that is `- single-kebab-token` with nothing else after the token is captured — including bullets the author intended as informational under "Recommended additional sections", "See also", "Future considerations".

When authoring a `schema.md`, keep non-required bullets either:
- Multi-word: `- data model — informal entities + relationships`
- `**bold**`-prefixed: `- **data-model** — the entity sketch`
- Backtick-wrapped: `- \`data-model\` — the slug`

So they fail the regex. Surfaced 2026-05-15: the pre-deep-port `templates/03-spec/schema.md` had a latent bug where bare `- data-model`, `- auth-and-permissions`, `- integration-points` under "Recommended additional sections" were being silently enforced as required H2s on every submission. The rewrite for task 12 fixed it; the rewrite for any future schema.md should keep this in mind.

## Producer model selection for heavy templates — opus required

For step-2 Turn 1 / Turn 2 productions (heavy HTML mood-board / hi-fi screen rendering) and any future visual step, **opus is required as the sub-agent model**. Sonnet times out on templates of this size (the step-2 `prompt.md` alone is 27 KB; expected output is 30-45 KB of HTML per direction/screen with token discipline + DS citation + chart rendering). Empirically captured during spec 026 task 11 dogfood (refined v1→v4) and the spec 027 OD dogfood. Cost: roughly $5 per Producer run on opus, but the alternative is a sonnet timeout with no output. Specify `model: "opus"` explicitly in the Agent call when dispatching to step 2.
