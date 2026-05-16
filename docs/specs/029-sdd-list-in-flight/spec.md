# 029 — sdd-list-in-flight

_Created 2026-05-16._

**Status:** shipped

## Intent

`/sdd list` today produces a fragile signal of "what's in flight": of 27 spec dirs, 9 are reported as `tasks` but only **026** is genuinely in progress — the other 8 are shipped capacities whose `tasks.md` carries residual unchecked boxes (post-merge verification, dogfood follow-ups, Phase-D-gated steps). The status heuristic uses checkbox state as the sole source of truth, and that source has drifted in practice. Every session start pays the cost: 2-3 minutes of manual Bash reconstruction (git log + `/sdd list` + SESSION.md cross-check) to identify the genuine WIP, and a real risk of picking the wrong spec to resume.

This spec adds a small declared-truth layer on top of the existing heuristic: a `**Status:**` line in `spec.md.tmpl` (one of `draft | in-progress | shipped | superseded`), and an `/sdd list --in-flight` filter that reads it. The filter combines declared Status with the existing checkbox heuristic (declared overrides derived) and surfaces acceptance-criteria-unchecked counts — which ties the visualization to the spec's own DONE_WHEN contract, the same primitive `delegation.md` § *Why DONE_WHEN exists* names as the local materialization of `/goal`. A `--json` flag emits the same data shaped for agent consumption at `SessionStart` time. Consumer is dual (humano + agente) per round 1; root cause addressed is signal noise, not absence of a dashboard — and no dashboard is built (see Non-goals).

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts._

- [ ] **Scenario: declared status overrides derived heuristic**
  - **Given** a spec dir with unchecked boxes remaining in `tasks.md` and `**Status:** shipped` in `spec.md`
  - **When** `/sdd list` runs
  - **Then** the spec's status renders as `shipped`, not `tasks` — the declared truth wins over the checkbox heuristic

- [ ] **Scenario: --in-flight filters out shipped and superseded**
  - **Given** the current 27-spec repo state
  - **When** `/sdd list --in-flight` runs after `**Status:** shipped` has been added to specs that are in fact shipped
  - **Then** the output shows only specs whose Status is `draft` or `in-progress` (or no Status, falling back to the existing heuristic with checkbox + recency); specs explicitly marked `shipped` or `superseded` are excluded

- [ ] **Scenario: each in-flight row shows acceptance unchecked count + last activity**
  - **Given** any spec returned by `--in-flight`
  - **When** the row renders
  - **Then** the line includes `N/M acceptance unchecked` (counted from `spec.md` § Acceptance criteria checkboxes, not `tasks.md`) and `last activity Yd ago` (from `git log -1 --format=%ar -- <dir>`)

- [ ] **Scenario: --json emits the same data structurally**
  - **Given** any `/sdd list --in-flight` invocation
  - **When** `--json` is appended
  - **Then** stdout is parseable JSON: an array of objects with at minimum `nnn`, `slug`, `status`, `acceptance_unchecked`, `acceptance_total`, `last_activity_iso`, `h1`; the JSON shape is documented inline in `SKILL.md` but is explicitly NOT a versioned wire contract (see Non-goals)

- [ ] **Scenario: no bulk-edit of existing specs**
  - **Given** the 27 existing spec dirs at ship time of this spec
  - **When** spec 029 lands
  - **Then** no existing `spec.md` is modified to add `**Status:**` — migration is organic; specs gain the line only when they are next touched. The implementation must work correctly on a spec dir with no `Status:` line (falls back to derived heuristic + recency)

- [ ] `.claude/skills/sdd/templates/spec.md.tmpl` includes a `**Status:** draft | in-progress | shipped | superseded` line near the top
- [ ] `.claude/skills/sdd/SKILL.md` § Subcommand: list documents the `--in-flight` flag, the `--json` flag, the Status-overrides-heuristic rule, and the `--in-flight` row shape
- [ ] `.claude/rules/spec-driven.md` mentions the Status field once, in § The three artifacts, naming `draft | in-progress | shipped | superseded` as the legal values

## Non-goals

- **No dashboard.** No HTML, no web UI, no Grafana, no OTel sink. Terminal text + JSON only. This is explicit guard against `feedback_speculative_observability` (rule-of-three for audit/forensics/dashboard tooling) and `visibility-intent.md` (next visibility wedge is agent-self-debug, not humano dashboards).
- **No SessionStart hook injection** in v1. Agent reads `--json` on demand if it wants to; no auto-injection. Reconsider after 2 weeks of use if the manual-call ergonomics break down.
- **No metadata creep beyond `Status:`.** Specifically NOT adding `Owner:`, `Priority:`, `BlockedBy:`, `Effort:` to the template. Each is a classic scope-creep vector; the discipline `/sdd refine` already produces this kind of detail in the spec body when it matters.
- **No bulk-edit retrofit of the 27 existing specs.** Migration is organic. The fallback heuristic ensures correct behavior on Status-less specs.
- **No replacement of `SESSION.md`.** SESSION.md is cross-spec narrative (current state, gotchas, next steps); `--in-flight` is per-spec tabular. They coexist.
- **`--json` is not a versioned wire contract.** Shape may evolve; downstream consumers that hard-depend on the shape do so at their own risk. Documented inline in `SKILL.md`.

## Open questions

- [ ] **Hit #3 of rule-of-three was not nameable during refine.** If `/sdd list --in-flight` is not used after 2 weeks post-ship, revert the template change (one line, cheap to revert). _Owner: user, deadline 2 weeks after ship._
- [ ] Recency window for the heuristic fallback — how recent counts as "active"? Default to propose in `/sdd plan`: 14 days (≥ typical session-stretch). Alternative: read from `CLAUDE_SDD_IN_FLIGHT_RECENCY_DAYS` env var.
- [ ] Acceptance-criteria counting — count nested `Scenario:` sub-bullet `- [ ]` only, or count *all* `- [ ]` under § Acceptance criteria including plain static-fact bullets? Default to propose: all `- [ ]` directly under that section, no nesting depth filter. Resolve in `/sdd plan`.
- [ ] Should the SKILL.md § Subcommand: list update preserve the existing default behaviour byte-for-byte (just adding `--in-flight` and `--json` as opt-in flags), or also surface the new `shipped` recognition in the bare `/sdd list` output? Default: yes, surface it — `Status: shipped` becomes the truth even without `--in-flight`. Resolve in `/sdd plan`.
- [ ] `superseded` semantics — does `--in-flight` simply exclude it (default), or does it also exclude from bare `/sdd list` output (cleaner) at the cost of "hiding history"? Resolve in `/sdd plan`.

## Context / references

- `.claude/skills/sdd/SKILL.md` § Subcommand: list — the surface being extended.
- `.claude/skills/sdd/templates/spec.md.tmpl` — the template getting the new `Status:` line.
- `.claude/rules/spec-driven.md` § The three artifacts — gets the one-line Status mention.
- `.claude/rules/delegation.md` § *Why DONE_WHEN exists (the /goal connection)* — the primitive `--in-flight`'s acceptance-unchecked counter ties the visualization to. Recently edited 2026-05-16.
- `.claude/memory/visibility-intent.md` — explicit "next visibility wedge is agent-self-debug, not humano dashboards". This spec respects the constraint (dual-format: terminal text + agent-readable JSON, no dashboard).
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three test for audit/forensics/dashboard tooling. This spec is borderline; open question 1 captures the revert-if-unused condition.
- `.claude/memory/agent0-purpose.md` — Agent0 is a template-forever repo; this change ships to forks via sync-harness (`.claude/skills/`).
- `docs/specs/028-sdd-refine-interview/` — the prior spec; this one was produced *by* `/sdd refine` and is its first non-meta dogfood.
