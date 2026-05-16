# 029 — sdd-list-in-flight — plan

_Drafted from `spec.md` on 2026-05-16. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Documentation-only change. No new code, no hooks, no validators — the work lives entirely inside the `/sdd` skill, mirroring how spec 028 was built. Three edits, no new files.

**Sharp observation about the template:** `spec.md.tmpl` already contains `_Created {{DATE}}. Status: draft._` on line 3 — `Status:` exists as italic prose. The smallest move is therefore not "add a new field" but "promote the existing italic Status to a parseable `**Status:**` line with a closed-set of legal values". Line count unchanged; grep behaviour transformed.

Order of work: (1) update the template (the new specs that need the line going forward), (2) extend `SKILL.md` § Subcommand: list with `--in-flight` and `--json` instructions plus the Status-overrides-heuristic rule and the JSON shape doc, (3) add one sentence to `spec-driven.md` § The three artifacts naming the legal Status values. No retrofit of the 27 existing spec dirs (Acceptance criterion #5).

The 5 open questions from `spec.md` resolve as follows: **(Q1)** rule-of-three caveat stays in spec's Open questions — user-owned 2-week revert condition, no plan action; **(Q2)** recency window for fallback heuristic = **14 days** (matches typical session-stretch length), tunable via `CLAUDE_SDD_IN_FLIGHT_RECENCY_DAYS` env var; **(Q3)** acceptance-criteria counting = **all `- [ ]` bullets directly under `## Acceptance criteria` regardless of nesting depth** — both scenario sub-bullets and plain static-fact bullets count toward unchecked total, which matches the spec.md.tmpl shape; **(Q4)** bare `/sdd list` ALSO honours `Status: shipped` (declared truth overrides derived everywhere, not only under `--in-flight` — a Status-less spec falls back to today's heuristic byte-for-byte); **(Q5)** `superseded` is excluded from `--in-flight`, kept in bare `/sdd list` output (preserves history; rendering shows `[superseded]` as a distinct fifth state alongside spec/plan/tasks/done).

## Files to touch

**Create:**
- _None._

**Modify:**
- `.claude/skills/sdd/templates/spec.md.tmpl` — replace line 3 `_Created {{DATE}}. Status: draft._` with two lines: `_Created {{DATE}}._` and `**Status:** draft` (separated by a blank line for grep-friendliness). Document the four legal values (`draft | in-progress | shipped | superseded`) in a brief comment above, or rely on `spec-driven.md` § The three artifacts as the canonical doc — choose latter to keep template lean.
- `.claude/skills/sdd/SKILL.md` — extend § Subcommand: list with: (a) the Status-recognition rule (declared overrides heuristic, applies to bare output too); (b) a new "Status semantics" sub-section enumerating the 5 status states (4 declared + 1 derived fallback) and what each implies for `--in-flight`; (c) the `--in-flight` flag definition with its filter rule (Status ∈ {draft, in-progress} OR Status-absent AND derived ∈ {spec, plan, tasks} AND recent); (d) the `--in-flight` row shape (`NNN-<slug>  [status]  N/M acceptance unchecked  last activity Yd ago  — <h1>`); (e) the `--json` flag with its emitted shape documented inline (object schema: `nnn`, `slug`, `status`, `acceptance_unchecked`, `acceptance_total`, `last_activity_iso`, `h1`); (f) the recency window default (14 days) with env-var override name; (g) the explicit note that `--json` is shape-only, not a versioned wire contract.
- `.claude/rules/spec-driven.md` — in § The three artifacts, append one sentence under the `spec.md` bullet: "The `**Status:**` line near the top declares lifecycle: `draft` (not started), `in-progress` (work begun), `shipped` (acceptance criteria satisfied), `superseded` (replaced by a later spec, slug named inline)."

**Delete:**
- _None._

## Alternatives considered

### Adding a new `**Status:**` line below the existing italic Status reference

Rejected. The template already has `Status: draft` as italic prose on line 3. Adding a second `**Status:**` line creates redundancy and conflicting sources of truth — readers and parsers would have to choose which one wins. Promoting the existing italic prose to bold-parseable is strictly better: same information, one source, line count unchanged.

### YAML frontmatter (`status: draft`) at top of `spec.md`

Rejected. No other markdown in this repo (rules, memories, session, specs) uses frontmatter — only the skill `SKILL.md` files do. Introducing frontmatter for one field misaligns with the project's "convention-light, cheap markdown" ethos (`spec-driven.md`), adds visual noise for human readers, and demands more careful parsing than a single `**Status:**` line. The bold-line approach achieves the parseability benefit without the markup overhead.

### New `.claude/.sdd-state.json` index file maintained by hooks

Rejected. Duplicates the source of truth (spec.md becomes derivative); introduces a sync problem identical to the one this spec is trying to solve at a different layer; and goes against `.claude/memory/feedback_speculative_observability.md` (audit/forensics/dashboard tooling without rule-of-three demand). The bold-line lives where the author already edits at ship time — single source, zero drift.

### Bash helper script `tools/sdd-list.sh` (replace skill instructions with a script)

Rejected. The current `/sdd` skill is instruction-driven — the agent executes by reading SKILL.md and running primitive commands (find, grep, git log) inline. That pattern works; introducing a script adds an artefact that needs maintenance and shipping rules separate from the skill. If `--json` ever becomes load-bearing for an external hook or tool, revisit; until then, keep it skill-side.

## Risks and unknowns

- **`Status:` field rot at ship time.** The discipline failure mode is identical to the checkbox rot the spec is fixing. Mitigation: the derived-heuristic fallback stays as the safety net; a missing `Status:` line is silently OK. The expectation is that *authors* of new specs (created post-this-spec) will set Status because the template prompts them; legacy specs gain Status organically when next touched.
- **`--json` accidental wire-contract.** If a hook or external tool starts depending on the JSON shape without versioning, future evolution becomes harder. Mitigation: anti-goal explicit in spec.md; inline disclaimer in SKILL.md when the JSON shape is documented; the field list deliberately omits a `version:` key to discourage hard-coded depends.
- **Backward compatibility of bare `/sdd list` output.** The new `[shipped]` state appears in the bare output (per Q4 resolution). Anyone parsing the terminal output today expects 5 states (spec/plan/tasks/done/empty); this adds 2 (`shipped`, `superseded`). Mitigation: nobody is known to be parsing this output (it's human-only by intent). Worth naming explicitly in the SKILL.md edit so future readers of the surface know it changed.
- **Acceptance counting in `spec.md`** assumes a sibling-section structure. If the spec author renames `## Acceptance criteria` to something else (e.g. `## Acceptance scenarios`), the count breaks silently. Mitigation: the SKILL.md instructions for `--in-flight` should grep for the canonical `^## Acceptance criteria` header (matching template) and emit `acceptance_unchecked: null` (not 0) when the section is missing or malformed — keep the null distinguishable from zero in JSON.
- **Unknown: real-world adoption.** Open question 1 (rule-of-three caveat) is honest about this — if nobody uses `--in-flight` two weeks after ship, the right move is revert, not iterate. Schedule the check explicitly via `.claude/REMINDERS.md` at ship time.

## Research / citations

- `.claude/skills/sdd/SKILL.md` § Subcommand: list — the surface being extended (current 5 status states).
- `.claude/skills/sdd/templates/spec.md.tmpl` line 3 — current italic `Status: draft` prose that gets promoted to bold.
- `.claude/rules/spec-driven.md` § The three artifacts — where the one-sentence Status legal-values doc lands.
- `.claude/rules/delegation.md` § *Why DONE_WHEN exists (the /goal connection)* (edited 2026-05-16) — primitive the acceptance-unchecked counter ties the visualization to.
- `.claude/memory/visibility-intent.md` — explicit "next visibility wedge is agent-self-debug, not humano dashboards"; satisfied here by dual-format output (terminal text + agent-readable JSON, no dashboard).
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test; satisfied with caveat (revert condition in Open Q1).
- `.claude/memory/agent0-purpose.md` — Agent0 ships to forks via sync-harness `.claude/skills/` glob; this change propagates automatically.
- Recent commit `4050de9` (feat(026): Phase B task 12 — step 3 spec port) — illustrates a spec dir that would benefit from `Status: in-progress` even with many unchecked boxes remaining in `tasks.md`.
- `docs/specs/028-sdd-refine-interview/` — the prior skill-edit spec; same pattern (documentation-only, in-place SKILL.md edits, no new code).
