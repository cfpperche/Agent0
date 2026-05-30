# 126 — site-refactor — debate

_Created 2026-05-30._

**Initiating agent:** Claude Code
**Reviewing agent:** {{reviewing agent name}}
**Initiated by:** Claude Code session 2026-05-30

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

**Intent (condensed).** Complete, in-place refactor of the Agent0 marketing site (`site/` — Astro 5 + Tailwind 4 + 4-locale i18n) across four axes (content/positioning, visual/brand, architecture, perf/SEO/a11y), with **positioning realignment as the load-bearing driver**. The site today leads with the mechanism — `hero.title` is literally "The harness for AI coding agents", the opening section is "Eighteen capacities, all opt-in", and the whole IA is harness-onboarding-centric — which contradicts the standing directive to *lead with business outcomes, not methodology; Agent0 is one capability, never the headline*. Stack and i18n breadth are preserved (no migration, no rebuild); the existing codebase is evolved.

**Top 3 acceptance scenarios (most load-bearing):**
1. *Above-the-fold leads with an outcome, not the mechanism* — a first-time visitor reading only the hero gets a business-outcome headline; "harness"/"capacities"/"Agent0 is a base repository…" do NOT carry the primary headline.
2. *Mechanism demoted to supporting evidence* — capacities/MCPs/hooks/spec-driven workflow appear as proof below the fold, present and honest but subordinate to the outcome narrative.
3. *No business-outcome claim ships without substantiation* — aspirational/unverifiable claims are cut (rule-of-three / no-speculative-claim discipline); honest fallback is expertises/capabilities framing, not fabricated results.

**Top 3 open questions:**
1. *Site identity* — is `site/` the **OSS-project landing** (where "the harness for AI coding agents" is arguably an honest, correct subject and the critique partly dissolves) or a **consultancy outcomes-surface** (where mechanism-led copy is the defect)? The refactor's entire shape depends on this.
2. *Primary audience* — consulting clients (want outcomes) vs developers evaluating Agent0 OSS (want mechanism)? Near-opposite headlines; a hybrid risks serving neither.
3. *Outcome-claim substantiation* — do real cases/metrics/results exist to lead with, or would outcome-led copy be aspirational? If unsubstantiated, what is the honest interim framing?

**Where I (initiating agent) want pushback — least confident here:**
- **The premise itself.** I have treated "positioning is misaligned → lead with outcomes" as settled (the user's stated driver), but OQ1 may *dissolve* it: if this is genuinely the OSS project's landing page, demoting "harness" could make the page *less* honest and less useful to its actual visitors (developers). Stress-test whether the positioning critique even applies to this surface, or whether the real fix is a *separate* consultancy surface (which the Non-goals currently forbid). This is the crux — push hardest here.
- **Substantiation risk.** Scenario 6 ("no claim without proof") may directly collide with Scenario 1 ("lead with an outcome"): if there are no substantiated outcomes yet, the two acceptance criteria may be jointly unsatisfiable, forcing the "expertises/capabilities" fallback — at which point, how is that materially different from today's capability-led copy? Is the whole refactor then just visual?
- **Big-bang scope.** Four axes at once with positioning unresolved feels like a stalled-half-migration risk. Is the acceptance set really deliverable as one spec, or should content/positioning be its own spec and visual/perf follow only after identity+audience resolve?

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

{{round 1 critique — reviewing agent writes directly}}

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

{{round 2 counter — initiating agent fills after reviewing agent writes critique}}

---

## Round 2 — reviewing agent (critique)

{{round 2 critique — reviewing agent writes directly, OR leave blank if user opted to synthesize}}

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** {{converged | cap-reached | abandoned}}

**Proposed spec changes:**

- {{spec change 1 — section + delta}}
- {{spec change 2}}

**Unresolved disagreements:** (only if cap-reached or abandoned)

- {{disagreement 1 — initiating agent's view + reviewing agent's view + why no resolution}}

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

- {{applied change 1 — file + section}}
