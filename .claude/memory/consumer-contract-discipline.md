---
name: consumer-contract-discipline
description: Producer templates must document the consumer-side contract for any artifact a downstream step consumes — not just the artifact shape, but who reads it and what shape they expect. The Agent0-port surfaced this insight by porting steps that had implicit cross-step contracts in anthill.
metadata:
  type: project
---

When a pipeline step produces an artifact that a downstream step consumes structurally (not just narratively), the **producer template must document the consumer contract IN the producer template** — not in a separate cross-cutting doc, not in the consumer's reading instructions, not in tribal knowledge.

## Why

Anthill skills (the quality-floor reference for the original MCP port — see [[anthill-archived]]) had this pattern only implicitly: anthill-prd produces a PRD that anthill-roadmap consumes for phasing, anthill-spec produces a spec that anthill-prd consumes for requirements, anthill-design-system produces tokens that anthill-prototype consumes for visual fidelity. None of the producer skills told the writer "this output will be consumed by X downstream with shape Y; if you change shape, X breaks silently."

Result: anthill consumers had to defensively parse upstream artifacts, often with regex hacks. When the producer drifted (e.g., changed user-story format), the consumer broke silently — the symptom appeared 2-3 steps downstream from the cause.

The MCP port (specs 025-027, now discontinued 2026-05-19) surfaced this pattern, and the `/product` skill (spec 048) carries it forward. Step 14 design-system says "step 15 atlas reads `tokens.css` verbatim; do not invent unnamed tokens." Step 04 audit says "frontmatter is consumed by step 14 (design-system fixes) + step 15 (atlas fixes); the contract is `findings[].fix_skill_hint`." Step 05 PRD says "user-story IDs (`US-NN`) are consumed by step 07 sitemap + step 15 atlas PRD-coverage scoring; renumbering breaks coverage silently." Each producer template carries its own consumer-contract block.

## When this applies

Use the discipline whenever:

1. **The producer emits structured data the consumer parses programmatically.** YAML frontmatter, table rows with stable shape, named CSS tokens, ID-prefixed sections (`US-NN`, `F-NN`, `step 4 F-NN`). Not when the consumer reads prose for general orientation.

2. **The consumer's behavior depends on the producer's shape stability.** "Step 7 reads step 6's tokens" is structural — consumer's CSS resolution fails if `--color-canvas` becomes `--color-bg`. "Step 9 reads step 8's PRD" can be narrative — system-design just needs human-readable requirements.

3. **The consumer is in a different step's template.** Within-template references (a section pointing at another section) don't need this — they live in the same file. Cross-step contracts need explicit producer-side documentation.

## What to write in the producer template

Add a short section near the artifact-emit instructions naming:

- **What downstream consumer reads this** (step N, step N+M)
- **What field / shape they parse** (the literal column name, ID prefix, YAML key)
- **What breaks if the producer drifts** (silent failure mode — coverage scoring breaks, token resolution fails, audit-routing drops findings)
- **The append-don't-renumber / shape-stability discipline** if applicable

Example shape (verbatim from step 8 prompt.md § 4):

> **The US-NN IDs are consumed by step 13's PRD-coverage scoring — stability matters.** IDs survive across PRD revisions — when adding a new story mid-life, append to the end (don't renumber existing IDs); when removing, leave the ID with a `~~`-strikethrough + removal note.

This is project-internal knowledge, not a behavioral rule. Future ports (steps 9-13) inherit the pattern naturally if they document their consumer contracts the same way; deviations need explicit reason.

## Cross-references

- [[anthill-archived]] — quality-floor reference; the absence of this discipline in anthill is what triggered the insight.
- [[feedback_anthill_port_smart_not_rigid]] — sibling discipline; smart-not-rigid evaluates the port; consumer-contract documents what the port should specifically NOT lose.

## Canonical examples in current codebase

- `.claude/skills/product/templates/pipeline/04-ux-testing/schema.md` § "Optional YAML frontmatter — structured findings handoff" — consumer contract for steps 08/14/15
- `.claude/skills/product/templates/pipeline/14-design-system/prompt.md` § tokens — tokens.css consumer contract for step 15 (screen atlas)
- `.claude/skills/product/templates/pipeline/05-prd/prompt.md` § user stories — US-NN consumer contract for step 07 (sitemap) + step 15 (screen atlas)

## Anti-pattern

A producer template that says "save the file" without naming who reads it next. Symptoms in downstream consumer: defensive parsing, regex hacks for non-standard shapes, comments like `// TODO: handle case where upstream uses old format`. When you see those, the missing consumer-contract documentation is the root cause — the consumer is fighting drift the producer never disciplined.
