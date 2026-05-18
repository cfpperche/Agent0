# 046 — sdd-in-flight-notes — plan

_Drafted from `spec.md` on 2026-05-18. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add a **fourth optional artifact** `notes.md` to the SDD scaffold. The shape is deliberately minimal — one new template file, three small rule edits, one one-line CLAUDE.md update, one new line in the `/sdd new` cp list. No hook, no validator integration, no CLI subcommand to read or write notes; the file is just markdown the agent and human edit in-band. This matches the v1 shape of spec 035 (rule-only, dogfood-first, hook deferred until rule-of-three demand surfaces).

Lock the three "decided at plan time" open questions here, leave the other two open for the dogfood window:

| Question | Decision | Why |
|---|---|---|
| Extension `.md` vs `.html`? | **`.md`** | `git diff` legibility, parity with `spec.md`/`plan.md`/`tasks.md`, lower friction in CLI workflows. Travis Fischer's `.html` choice was for browser preview; we live in the terminal. |
| Entry shape: free / titled / schema? | **Titled** — `### YYYY-MM-DD — <author> — <one-line title>` heading + free-prose body | Balance between auditability (date + author makes the entry greppable) and friction (no required key/value fields). Author is one of `parent` or `<subagent_type>` (e.g. `general-purpose`, `Explore`) so the boundary stays visible. |
| Location: spec root vs `artifacts/`? | **Spec root** — `docs/specs/NNN-<slug>/notes.md` | Parity with the other three artifacts. `artifacts/` is for renders, screenshots, tombstones — material *adjacent to* the spec, not *of* the spec. Notes is canonical, not adjacent. |

The four-section structure is fixed by the template — `## Design decisions`, `## Deviations`, `## Tradeoffs`, `## Open questions` — to give writers a routing rubric. A decision made under ambiguity goes in §1; an intentional departure from `plan.md` goes in §2; an alternative weighed and chosen goes in §3; a question surfaced mid-build goes in §4. Sections may be empty; the rubric is a guide, not a quota.

Meta-dogfood: this spec creates its own `notes.md` at scaffold time AND populates at least one entry before `tasks.md` is checked-out done. The first entry is essentially this paragraph's "why we locked extension = .md" decision, demonstrating the pattern on the spec that introduces it.

## Files to touch

**Create:**

- `.claude/skills/sdd/templates/notes.md.tmpl` — four-section template skeleton with `{{NNN}}`/`{{SLUG}}`/`{{DATE}}` placeholders + a short header explaining the file's purpose and the entry shape. Mirrors the discipline of the other three `.tmpl` files (same placeholder set, same explanatory comment posture).
- `docs/specs/046-sdd-in-flight-notes/notes.md` — meta-dogfood; the spec's own in-flight notes file, populated during implementation with at least one entry to demonstrate the pattern.

**Modify:**

- `.claude/skills/sdd/SKILL.md` — extend Subcommand `new <slug>` Step 3's `cp` block to include the fourth template copy; update the short list in Step 5's report shape to mention four files instead of three; tiny adjustment to the description-line file-list reference (`{spec,plan,tasks}.md` → `{spec,plan,tasks,notes}.md`).
- `.claude/rules/spec-driven.md` — rename `## The three artifacts` heading to `## The four artifacts`; add a fourth bullet for `notes.md` (purpose, when to append, four-section structure, append-only convention, entry shape) directly after the `tasks.md` bullet; one-sentence cross-reference to `.claude/rules/delegation.md` § *The 5-field handoff*.
- `.claude/rules/delegation.md` — add one paragraph in or directly after § *The 5-field handoff* documenting that when CONTEXT references a spec dir, DELIVERABLE should include the canonical phrase about appending entries to `notes.md`. No grammar change to the 5-field gate itself — just documentation of the integration.
- `CLAUDE.md` — change `{spec,plan,tasks}.md` to `{spec,plan,tasks,notes}.md` in § *Spec-driven development*. One-liner.
- `.claude/REMINDERS.md` — append: "Spec 046 dogfood gate — review next 3-5 specs scaffolded after 046; if `notes.md` is non-empty AND cited in ≥3 PRs by 2026-07-01, promote to mandatory; if empty in all, revert template + rule edit. See spec 046 § Open questions Q2." with `--due 2026-07-01`.

**Delete:**

- None.

## Alternatives considered

### Alternative A — Append in-flight log inside `plan.md` under a new `## Implementation log` section

Rejected because it would change `plan.md`'s lifecycle. Today `plan.md` is the **pre-flight engineering judgment** — written once, edited only when "implementation reveals the plan is wrong" (per the template header). A running in-flight log inside the same file conflates two distinct mental modes: deliberate planning (slow, structured) and reactive recording (fast, append-only). Keeping them separated preserves `plan.md`'s function as a stable reference document.

### Alternative B — Single free-form `journal.md` with no required sections

Rejected because lack of structure tends toward atrophy. The four canonical sections (Design decisions / Deviations / Tradeoffs / Open questions) function as a routing rubric — the writer thinks once about "which section?" and the reader scans a known shape. Free-form journals in adjacent projects (the SESSION.md history before this spec, internal scratch files) consistently devolved into either kitchen-sink dumps or empty files. Mild structure costs little and pays back on read.

### Alternative C — ADR-style structured per-decision files under `docs/specs/NNN-*/decisions/`

Rejected as over-engineered for v1. The pattern (one markdown file per decision with frontmatter, status, context, decision, consequences) is genuinely valuable for *architectural* decisions that persist across multiple specs — but the in-flight signal we're trying to capture is much smaller in scope: "while building this one spec, here's what we figured out". A single growing file matches that scope. If a specific decision deserves ADR treatment, the agent can later extract it from `notes.md` into a proper ADR — but most won't.

### Alternative D — Reuse `SESSION.md` for in-flight notes

Rejected because the lifecycles diverge. `SESSION.md` is **cross-session WIP handoff**, sized to ~2 KB, overwritten each session. `notes.md` is **per-spec design memory**, git-tracked, append-only, survives sessions and the work unit. A single decision recorded at session boundary in `SESSION.md` is gone the next session; the same decision in `notes.md` lives forever next to the spec. Different lifetimes need different files.

### Alternative E — Skip the artifact entirely; rely on commit messages + PR body

Rejected because that's the status quo we're trying to improve. Commit messages are fragmented (one decision spread across N commits' bodies; the synthesis is lost); PR bodies are terminal (written once at PR-open, edited rarely). Neither is consultable mid-build by a later sub-agent or session that needs to know "what did the previous worker decide about X". The artifact's whole point is *consultable in-flight context*; the alternatives can't provide it.

## Risks and unknowns

- **Atrophy risk.** If the rule mentions `notes.md` but no agent or human actually writes to it, the artifact becomes dead weight and the rule becomes noise. Mitigation: dogfood window of 3-5 specs, REMINDERS gate at 2026-07-01, willingness to revert (the changes are intentionally small and reversible — five files, no migration cost).
- **Sub-agent over-eagerness.** A sub-agent might log every micro-decision instead of judgment calls. Mitigation: the rule wording will use "non-trivial decision not pre-empted by spec/plan" as the threshold; reviewers prune at PR time. Acceptable to err on the side of over-logging in v1 — easier to trim later than to backfill.
- **Duplication with commit messages and PR body.** Intentional, but worth naming: `notes.md` is the **source material** the synthesis draws from. The PR body might quote or summarize an entry; the entry remains the canonical record. Reviewers should expect overlap, not be surprised by it.
- **Mandatory creep.** Documenting the artifact in a rule plus extending the scaffold tends to make agents treat it as required even though the rule says optional. Mitigation: the rule text explicitly says "optional in v1; populate when a decision wasn't pre-empted by spec/plan, not for every task". Watch for this in dogfood.
- **Path drift.** If a future spec uses `docs/specs/NNN-*/notes.md` for something unrelated (e.g. legacy notes-on-the-spec rather than in-flight implementation notes), the rubric breaks. Mitigation: the template's header explicitly names the four-section structure and the in-flight-during-implementation framing. Low risk because the convention is new and there's no legacy meaning attached to this filename in our `docs/specs/` history.
- **Unknown — promotion criteria.** Open question Q2 in `spec.md`. The current proposal — "≥3 of next 5 PRs cite notes.md AND ≥3 specs land with non-empty notes.md by 2026-07-01" — is a guess. Real signal might come from review feedback ("I read the notes file before reviewing the PR") rather than mechanical citation counts. The REMINDERS gate will surface the question; the answer is dogfood-empirical.
- **Unknown — `delegation-gate.sh` advisory integration.** Open question Q3. Whether to advise (not block) at gate time when CONTEXT names a spec dir and DELIVERABLE omits the notes.md phrase is a v2 decision. Deferred deliberately — the rule-only v1 lets us measure baseline compliance before adding any advisory pressure.

## Research / citations

- [@trq212 thread (via unrollnow)](https://unrollnow.com/status/2056415973125796184) — origin of the "implementation-notes" pattern; Travis Fischer's framing of "the model needs an out for ambiguity that keeps the human in the loop"
- `.claude/rules/spec-driven.md` § *The three artifacts* — the rule this plan extends
- `.claude/rules/delegation.md` § *The 5-field handoff* — DELIVERABLE field is the integration surface for sub-agent reporting
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test governing the v1 (rule-only) → v2 (advisory/hook) promotion gate
- `docs/specs/035-user-prompt-framing/` — sister "rule-only, hook deferred" v1 shape; canonical precedent for scope discipline of new rule-driven capacities
- `docs/specs/045-prototype-skill-pipeline-realign/artifacts/redogfood-comparison.md` — recent example of an in-flight discovery (sitemap-IA load-bearing fix) that would have naturally lived in a `notes.md` had it existed; cited as motivating evidence
- `.claude/skills/sdd/SKILL.md` § *Subcommand: `new <slug>`* — scaffold flow to extend
- `.claude/skills/sdd/templates/` — where the new `notes.md.tmpl` lands; existing three `.tmpl` files set the template style
- `CLAUDE.md` § *Spec-driven development* — one-line update target
- `.claude/REMINDERS.md` — dogfood gate timer lives here, due 2026-07-01
