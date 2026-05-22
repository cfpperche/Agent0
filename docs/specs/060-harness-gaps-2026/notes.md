# 060 — harness-gaps-2026 — notes

_Created 2026-05-19._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-19 — parent — chose `umbrella` over `epic` as the type value

Considered `epic` (Agile/Jira), `tracking` (Rust/Kubernetes OSS convention), `umbrella` (informal Anthropic/OSS), and `meta-spec`. `epic` carries too much Jira baggage and implies multi-sprint ticket grouping; `tracking` aligns with OSS but is more issue-shaped than spec-shaped. `umbrella` is descriptive without baggage and matches how the team already references this kind of artifact informally. Documenting the convention in `.claude/rules/spec-driven.md` so it propagates to forks via sync-harness.

### 2026-05-19 — parent — chose `**Type:**` line over YAML frontmatter

Existing 59 specs use bolded inline `**Status:**` near the top — no YAML frontmatter anywhere in `docs/specs/`. Adopting frontmatter for the new field would force migrating 59 specs OR live with mixed shapes. The bolded line matches the existing convention, costs one line, is grep-able (`grep -l "Type: umbrella" docs/specs/*/spec.md`), and avoids parser dependencies.

### 2026-05-21 — parent — re-evaluation after 061 + 063 shipped (umbrella task 6)

061 and 063 shipped 2026-05-21 (062 was closed earlier). With the top-3 rows resolved, task 6 called for re-evaluating the still-`pending` rows and deciding the next batch. The live re-eval scope was A4-A8 + B4 + B8 — the original task-6 list also named §B1/B7, but both were already resolved (folded into 061/062). Outcomes, now recorded in § Gap matrix:

- **A8 → closed.** Delta-spec tracking (ADDED/MODIFIED/REMOVED) is already covered by the OpenSpec escalation path that `spec-driven.md` § Escalation path documents as the opt-in upgrade. Baking a half-version into Agent0 duplicates it.
- **A6 → closed.** Cost/token observability has no payload source — spec 061's empirical payload matrix shows `SubagentStop` carries neither cost nor token fields, so A6 is not the "S" effort the audit estimated. CC's native `/cost` covers the user-facing need; the forensic-audit angle is what `feedback_speculative_observability.md`'s rule-of-three flags. Marked `closed` rather than `deferred` because §A's acceptance scenario only admits →NNN or closed — "reopen via a fresh spec if real demand surfaces" is the standing escape hatch.
- **B8 → deferred.** `notes.md` enforcement is contingent on spec 046's 2026-07-01 dogfood gate — that gate decides whether `notes.md` becomes mandatory at all. Building enforcement now pre-empts the gate. §B admits `deferred`, so the row holds rather than closes.
- **A4 / A5 / A7 → kept pending.** All Média priority, no urgency; folded into the existing 2026-07-19 review-batch reminder. A7 (eval/golden-test harness) is the strongest of the three — ROI rises as `/product` gets real dogfood use.
- **B4 → recommended next spec.** Persona/SOUL.md per sub-agent: concrete, S effort, already user-flagged in REMINDERS.md. The standing recommendation for the next spec slot.

**No bulk-scaffold.** Task 6's literal "scaffold the next batch" is deliberately not executed as a sweep of empty draft specs — the 2026-05-19 § Tradeoffs entry already established that empty drafts rot and the umbrella matrix is the single source of truth for "what's pending." A follow-up spec is scaffolded only when it becomes the actively-worked next unit.

Progress: of the 7 rows re-evaluated, 3 reach a terminal/holding outcome (A6 + A8 closed, B8 deferred); A4/A5/A7 stay pending for the 07-19 batch; B4 is the recommended-next. The umbrella stays `draft` until every §A row is →NNN/closed and every §B row is →NNN/closed/deferred.

### 2026-05-22 — parent — B4 closed: subagent-personas (spec 074) killed on research grounds

B4 was the 2026-05-21 recommended-next-spec. It was scaffolded as spec 074 (`subagent-personas`); its `spec.md` was drafted twice — first voice-only, then reshaped after studying Anthill's 50-`soul.md` scheme into a fuller persona spec (Role/Personality/Rules + a named phase-2 evolution loop plugging into spec 061's `delegation-audit.jsonl` corpus). Before `plan.md` was written, the user pushed back: fast model progress means a static persona system risks staleness, disuse, and over-rigidifying the sub-agents. Web research (2026-05-22) confirmed it:

- *"When 'A Helpful Assistant' Is Not Really Helpful"* (EMNLP 2024) — 162 personas × 4 LLM families × 2410 questions: personas in system prompts do **not** improve performance, sometimes mildly hurt; a randomly chosen persona does as well as a domain-matched one.
- 2026 consensus: over-specified prompting that helped GPT-3-era models now *interferes* with capable ones — "instructions define how the model can think, limiting how it might want to think." The field moved from role-prompting to **context-engineering** (scope the information, constrain the output, free the process).
- Agent0's 5-field handoff is already a context-engineering instrument — `CONTEXT` scopes the info window, `DONE_WHEN` constrains the output. A persona system would be a regression toward role-prompting, the thing the research buries.
- Corroborating signal from the source itself: Anthill ships an `issue-425-pastiche-llm-voice-detection` plus a `[voice]` correction hook and corpus — i.e. its souls *caused* a generic-voice problem that needed a correction apparatus. The souls were the disease, not the cure.

The legitimate kernel — research/review/writing sub-agents want different output style — is real but small, and is already served by a per-dispatch `CONSTRAINTS` line. The persona-file apparatus (versioned files + attach mechanism + phase-2 evolution loop) was heavier than the problem. Spec 074 was deleted (never committed — zero git footprint); the originating `.claude/REMINDERS.md` item was dismissed. B4 → closed; this supersedes the "recommended-next" status from the 2026-05-21 entry above.

Sources: `aclanthology.org/2024.findings-emnlp.888` · `anthropic.com/engineering/effective-context-engineering-for-ai-agents` · `honeycomb.io/blog/if-it-wanted-to-it-would-bitter-lesson-llm-users`

## Deviations

_(none yet — spec was just scaffolded)_

## Tradeoffs

### 2026-05-19 — parent — close §A1 (→ 062) instead of redesigning with Stop-hook

When discussing 062's design (rule-only v1 vs revised v1 with Stop-hook enforcement), pre-flight verification of competitive landscape revealed CC 2.1.144 already ships `/goal` natively. Surface confirmed via `strings /home/goat/.local/bin/claude | grep -iE '^/goal'` — full command set (`/goal <condition>`, `/goal clear`, `/goal`), description "Set a goal — keep working until the condition is met", internal `goal-command-nudge` identifier suggesting built-in enforcement mechanism.

Three options weighed: (A) close 062 cleanly, defer to CC native; (B) thin wrapper `/contract` adding Agent0 audit + persistence; (C) alternative with stricter semantics. Chose A.

Reason for A over B: Agent0's framing principle is **discipline ON TOP of CC**, not replication of canonical CC primitives. A wrapper around a primitive whose internals we haven't probed (`goal-command-nudge` mechanism, feature flag gate `isHidden: !T6()`) would commit us to a design before dogfood reveals the gap. The marginal value of B (forensic audit of /goal usage) is exactly what `feedback_speculative_observability.md` flags as anti-pattern.

The hour spent yesterday scaffolding 062 wasn't wasted — it forced reading the design space sharply enough to ask "does CC already do this?" at the right moment. Pre-flight verification (Task 1 of the original tasks.md) was the load-bearing step that surfaced this.

Row A1 in § Gap matrix updated from `→ 062` to `closed: superseded by CC native /goal (2.1.144+)`. Spec 062 marked `superseded` with full Closure section in `spec.md`; design memory preserved (acceptance criteria, plan, tasks outline) as historical reference if a future spec targets a concrete gap CC's `/goal` proves insufficient for.

### 2026-05-19 — parent — scaffold top-3 follow-ups immediately, defer the rest

The user said "vamos abrindo specs refinadas de followup ... por ordem de prioridade". Two interpretations: (a) open ALL §A+§B follow-up specs now, (b) open the top priority ones now and iterate. Chose (b): scaffolds only specs 061/062/063 (the three alta-prioridade rows). Tradeoff accepted: §A4-A8 + §B medium-priority rows wait for explicit prioritization. Reason: stale draft specs rot and signal noise; scaffold-when-ready preserves the umbrella matrix as the single source of truth for "what's pending".

## Open questions

_(none yet — spec was just scaffolded)_
