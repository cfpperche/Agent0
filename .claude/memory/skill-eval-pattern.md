---
name: Skill-eval pattern (observed externally)
description: 5 industry posts converged on the same skill-eval recipe in early 2026; not adopted in Agent0 yet — wait for rule-of-three regression demand before building
metadata:
  type: project
---

In early 2026 five industry posts converged on essentially the same recipe for evaluating Agent Skills (the SKILL.md format that emerged in 2025):

1. **Phil Schmid** ([philschmid.de/testing-skills](https://www.philschmid.de/testing-skills)) — eval harness: prompt set with success criteria → run via CLI → deterministic regex checks → optional LLM-as-judge. Case: Gemini Interactions API skill 66.7% → 100%.
2. **Langfuse** ([langfuse.com/blog/2026-02-26-evaluate-ai-agent-skills](https://langfuse.com/blog/2026-02-26-evaluate-ai-agent-skills)) — Dataset + tracing → failure-pattern analysis → iterate SKILL.md → re-run.
3. **LangChain** ([langchain.com/blog/evaluating-skills](https://www.langchain.com/blog/evaluating-skills)) — 4-step pipeline + LangSmith observability; public GitHub repo.
4. **OpenAI/Codex** ([developers.openai.com/blog/eval-skills](https://developers.openai.com/blog/eval-skills)) — `codex exec --json` traces + deterministic checks + `--output-schema` rubric grading.
5. **Hamel Husain** ([hamel.dev/blog/posts/evals-skills](https://hamel.dev/blog/posts/evals-skills/)) — meta-twist: publishes a *pack of skills* that teach an agent to conduct evals (error analysis, synthetic data, judge design, RAG assessment).

Anthropic's eval-tool ([platform.claude.com/docs/en/test-and-evaluate/eval-tool](https://platform.claude.com/docs/en/test-and-evaluate/eval-tool)) predates this wave — it evaluates *prompts* (Console CSV + 5-point grading), not skills. Different scope.

The recurring recipe across the 5: **success criteria first → prompt test set → run agent → deterministic check + LLM-judge → iterate the SKILL.md**. Schmid's and OpenAI's writeups are near-isomorphic; only the runner differs.

**Why this memo exists:** the pattern is real and applicable — Agent0 ships skills (`sdd`, `remind`, `simplify`, `update-config`, etc.) whose behavior is prompt-driven and output-verifiable. The 5 posts are the canonical reference if Agent0 ever needs to build skill-evals.

**Why Agent0 has NOT adopted it (2026-05-13):** bumps against [[feedback_speculative_observability]] — rule-of-three demand test before building eval/forensics/dashboard tooling. The current feedback loop for skills is dogfood-in-fork (qualitative, manual), and it has been working — the last shrnk-mono pass surfaced 3 fixable issues and closed them in hours. Building an eval framework now, without a concrete case of "a skill regressed silently and dogfood didn't catch it", is exactly the speculative-observability anti-pattern.

**How to apply:** when the third real regression case lands — a skill behavior degraded between commits and only surfaced after the fact — pull this memo and pick the runner closest to Agent0's stance. Schmid's CLI-harness shape (bash + jq + claude exec) fits Agent0's primitive style best; Hamel's "skill that teaches eval discipline" is the alternative if the gap is "agent doesn't know how to validate its own work" rather than "Agent0 doesn't know which skills regressed".

Until then: keep dogfood-in-fork as the primary feedback loop; don't pre-build the framework.
