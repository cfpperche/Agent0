---
name: Anthill archived
description: anthill (the skill/agent harness Agent0 ports content from) is archived as of 2026-05-13; no longer evolves; quality reference, not a moving target
metadata:
  type: project
---

`/home/goat/anthill` is archived. It will not receive further updates. Its skills proved high-quality content for product/SDLC pipelines (instruction depth, multi-artifact outputs, executable HTML prototypes, design tokens, etc.) and serve as the *quality benchmark* for what our own MCP-based ports should match or exceed.

**Why:** stated explicitly by user 2026-05-13 in the spec 026 Q3 conversation: "anthill foi arquivado, provou seu valor em relacao a qualidade das skills mas nao vai mais evoluir ... se alguma evolucao acontecer vai ser no nosso projeto Agent0 + mcps que vamos disponibilizar".

**How to apply:**
- Do NOT spend effort on drift-detection tooling against anthill upstream (versions won't change).
- Do NOT pin `source: anthill/<skill>@<version>` in template frontmatter as a tracking field — there's nothing to track against.
- DO use anthill skills as a quality floor when porting content to `packages/mcp-*` templates: the ported template should produce artifacts of equal-or-greater depth/category as the corresponding anthill skill.
- A `Step-to-skill mapping` table in plan.md or README is sufficient audit-trail when porting; per-template frontmatter pin is not needed.
- Once content is ported into our templates, it's ours — refinement, restructuring, voice changes are all valid; no "stay faithful to upstream" constraint applies.

Related: [[agent0-purpose.md]] (Agent0 is the template-forever base; anthill ports flow INTO `packages/mcp-*` of Agent0, not into the harness core).
