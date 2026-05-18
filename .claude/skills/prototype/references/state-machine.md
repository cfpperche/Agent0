# State machine — `/prototype` v2

Defines `.state.json` shape, phase/step progression, gate semantics, and resume support via `--from-step=NN`. Spec source: `docs/specs/036-prototype-skill-refactor/`.

## `.state.json` shape

Written at `<out-dir>/.state.json`. Initialized by Phase 0, updated at each step boundary, finalized at Phase 4 close.

```json
{
  "version": 2,
  "slug": "claude-code-governance-dashboard",
  "idea": "Claude Code governance dashboard",
  "flags": {
    "stack": "next",
    "out": "/tmp/dogfood-v2",
    "from_step": null,
    "skip_brand": false,
    "skip_prd": false
  },
  "phase": 3,
  "step": 9,
  "step_label": "09-system-design",
  "started_at": "2026-05-18T14:30:00Z",
  "gates_passed": ["discovery", "identity"],
  "completed_steps": ["01-ideation", "02-prototype", "03-spec", "04-ux-testing", "05-brand", "06-design-system", "07-prototype-v2", "08-prd"],
  "blocked_steps": [],
  "iterations": {
    "discovery": 0,
    "identity": 1,
    "specification": 0
  },
  "completed_at": null
}
```

Field semantics:

- **`version`** — schema version of `.state.json` itself. Incremented when shape changes. Current: `2`. v1 was the spec-034 shape (single `phase` int from 0-5); v2 adds the 13-step tracking.
- **`slug`** — kebab-case product slug derived from `idea`. Computed once at Phase 0; immutable thereafter.
- **`idea`** — verbatim user input from `/prototype "<idea>"`. Immutable.
- **`flags`** — captured from invocation; `out` is required, others default. Immutable post-Phase 0 except `from_step` (cleared after resume completes).
- **`phase`** — current phase number (0-5). Updated at phase boundary.
- **`step`** — current step number (0 = Phase 0 setup, 1-13 = pipeline steps).
- **`step_label`** — human-readable step name matching bundled template dir name (e.g. `09-system-design`).
- **`started_at`** — UTC ISO-8601 timestamp from Phase 0.
- **`gates_passed`** — list of phase names with `continue` choice at gate. Order matters (cannot be in `specification` if not in `identity`).
- **`completed_steps`** — list of step labels that finished cleanly. Append-only.
- **`blocked_steps`** — list of objects `{step_label, reason, artifacts_partial?}` for steps that returned BLOCKED (per Q4 resolution: degrade gracefully + log + continue). Empty list when no blocks.
- **`iterations`** — count of `iterate` gate-pass choices per phase. Each `iterate` increments; `continue` does not. Used to cap runaway iteration (soft cap = 3 per phase; warn at 3, soft-abort at 5).
- **`completed_at`** — UTC ISO-8601 set when Phase 4 closes successfully. Null otherwise.

## Phase progression

```
Phase 0 (setup) → step 0
  ↓
Phase 1 (discovery) → steps 01-04
  ↓
  gate_discovery [AskUserQuestion: continue / iterate / abort]
    continue → Phase 2
    iterate  → re-dispatch failing step(s) within Phase 1, then re-gate
    abort    → exit; .state.json preserved for later resume
  ↓
Phase 2 (identity) → steps 05-07
  ↓
  gate_identity [AskUserQuestion: continue / iterate / abort]
  ↓
Phase 3 (specification) → steps 08-12
  ↓
  gate_specification [AskUserQuestion: continue / iterate / abort]
  ↓
Phase 4 (synthesis) → step 13
  ↓
  Phase 5 (handoff message)
  ↓
  completed_at set
```

Phase 0 has no gate (idempotency check is local). Phase 4 has no gate (final synthesis; `/sdd new` handoff is the implicit "next" gate).

## Step ordering within a phase

Within each phase, steps run **mostly in parallel** with two ordering constraints:

- **Phase 1 (Discovery):** Step 01 blocks (concept brief feeds all downstream). Steps 02 + 03 + 04 run in parallel (one Agent message with 3 calls) after Step 01 returns.
- **Phase 2 (Identity):** Step 05 (brand) → Step 06 (design-system, depends on brand-book) → Step 07 (prototype-v2, depends on tokens + audit findings from Phase 1 Step 04). Strict serial; no parallel.
- **Phase 3 (Specification):** Step 08 (PRD) blocks. Steps 09 + 10 + 11 + 12 run in parallel after Step 08 returns. (Step 09 system-design depends on PRD scope; Step 10 cost depends on system-design — relaxed at standard tier to "any reasonable ordering" since the deferred details outweigh the strict dependency).
- **Phase 4 (Synthesis):** Step 13 single sub-agent + per-route screen-writer fan-out (cap=5) for the atlas screens.

## Gate UX (per Q3 resolution)

At end of Phase 1, 2, 3:

1. Skill prints a per-phase summary: artifacts produced (file paths + sizes), blocked steps if any, iteration count if any.
2. Skill invokes `AskUserQuestion` with 3 options:
   - **`continue`** → next phase. Appends phase name to `gates_passed`.
   - **`iterate`** → user names which step(s) to re-dispatch (sub-prompt). Re-dispatches with augmented brief. Increments `iterations.<phase>` counter. Re-prompts gate after re-dispatch.
   - **`abort`** → exit cleanly. Sets `flags.from_step` = current step for resume hint. Prints `Run /prototype "<idea>" --from-step=<NN> --out=<same-path>` to resume.

Iteration soft cap: warn at `iterations.<phase> >= 3`, force-abort at `>= 5`. Prevents infinite loops.

## Resume via `--from-step=NN`

```bash
/prototype "Claude Code governance dashboard" --from-step=09 --out=/tmp/dogfood-v2
```

Behavior:

1. Phase 0 reads `.state.json` from `<out-dir>`.
2. Validates: `slug` matches argument-derived slug; `idea` matches verbatim (case-sensitive); `flags.stack` matches; if mismatch, abort with `state mismatch — clear --out dir or pick different --from-step`.
3. Jumps to step NN. All `completed_steps` entries with step number < NN remain trusted (artifacts on disk are used as inputs to downstream).
4. Continues from there through remaining steps + phases.
5. On clean completion, `flags.from_step` set back to `null` for next invocation.

**Edge case:** `--from-step=NN` where NN is past the user's actual progress. Skill detects (NN > current `step` value), warns, falls back to `step = current` (the actual current step, not requested).

## Failure handling (per Q4 resolution)

Sub-agent dispatch returns BLOCKED (DELIVERABLE not met OR sub-agent explicit can't-do):

- **Step 01 (concept brief) or Step 13 (atlas) blocks** → ABORT the run. These steps are upstream-of-everything (01) or final-deliverable (13); continuing without them produces incomplete artifacts the rest of the pipeline can't reason about.
- **Any other step blocks** → degrade gracefully:
  - Append `{step_label, reason, artifacts_partial: <list>}` to `blocked_steps`.
  - Log to REPORT.md `## Blocked steps` section.
  - Continue to next step. Downstream steps that depend on this one note the gap (e.g., Step 07 prototype-v2 with no Step 04 audit findings just omits the audit-fix-inline pass).

## Output dir collision (per Q5 resolution, matches v1)

Phase 0 checks if `<out-dir>` exists and is non-empty (any file present):

```
<out-dir> exists and is non-empty. Overwrite? (y/N) ▷
```

- `y` → `rm -r <out-dir>` (NOT `rm -rf` — governance-gate blocks combined flags); then `mkdir -p <out-dir>` + init `.state.json`.
- `n` / no answer / anything else → abort with `aborted; pick a different --out or rm the existing dir yourself`. Exit 0 (user-chosen abort, not error).

No `--force` flag; the prompt is the gate.

## Cross-references

- `pipeline-coverage.md` — what each step produces at standard tier
- `delegation-briefs.md` — sub-agent dispatch shape per step
- `quality-checklist.md` — per-step gate criteria the skill checks before declaring a step complete
- `SKILL.md` — orchestration body that operates this state machine
- `.claude/rules/delegation.md` — 5-field handoff discipline all sub-agent dispatches follow
- `docs/specs/036-prototype-skill-refactor/` — spec source
