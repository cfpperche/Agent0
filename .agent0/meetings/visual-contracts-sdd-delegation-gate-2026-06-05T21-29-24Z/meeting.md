---
meeting: visual-contracts-sdd-delegation-gate
topic: "Incorporate visual contracts into SDD acceptance + the delegation gate (spec-152 follow-up #2): treat an agent-browser verify-contract/audit pass as an acceptance artifact for UI-producing specs/tasks, and require it in the delegation 5-field DONE_WHEN/DELIVERABLE. Visual contracts must cover not just static visual rendering but also navigation, interactive exploration of screen functionality, and flow traversal. Core tension: scope the 'UI-producing' trigger so it gates real UI work without over-gating non-UI work."
created: 2026-06-05T21:29:30Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 2
next_speaker: human
synthesis: accepted
---

# Meeting: Incorporate visual contracts into SDD acceptance + the delegation gate (spec-152 follow-up #2): treat an agent-browser verify-contract/audit pass as an acceptance artifact for UI-producing specs/tasks, and require it in the delegation 5-field DONE_WHEN/DELIVERABLE. Visual contracts must cover not just static visual rendering but also navigation, interactive exploration of screen functionality, and flow traversal. Core tension: scope the 'UI-producing' trigger so it gates real UI work without over-gating non-UI work.

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — human (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:1989bb5ce0029408` (3492 bytes)
- commit codex — `sha256:5ef12c3cb5767be6` (3272 bytes)

### Turn 1 — claude (blind opening) (claude)

**Framing (claude, blind opening).** The proposal has two plug-in points and one hard problem. Keep them separate or the discussion blurs.

**The two plug-in points**
1. **SDD acceptance** — a UI-producing spec carries a *visual contract* as a first-class acceptance artifact, authored at `plan`/`tasks` time (like fixtures), not retrofitted at review. "Done" for that spec includes a green `agent-browser.sh verify-contract`/`audit` pass.
2. **Delegation gate** — when a sub-agent task produces UI, the 5-field handoff's `DONE_WHEN`/`DELIVERABLE` must name the verify-contract pass as the deliverable proof, so the `SubagentStop` verify step can check it.

**What "visual contract" must mean here.** The user's addition is the important part: this is *not* a pixel/screenshot diff. The contract is an **interaction trace** with at least three layers, each opt-in deeper than the last:
- **render** — the screen mounts and the primary content/CTA is present (cheap, the default floor);
- **navigation** — the screen is *reachable* and you can move between the screens the flow touches;
- **exploration/flow** — controls respond (click/type/submit/state change) and a named user flow traverses end-to-end.
`agent-browser` already does observe+act, so the mechanism exists. The open design work is the *contract format* (how a spec author declares "this flow, these reachable screens, these responsive controls") and keeping the floor cheap enough that it actually gets written.

**The hard problem — the "UI-producing" trigger.** Three shapes:
- **Declarative** — author sets `produces_ui: true` in spec frontmatter / task metadata. Honest and simple; relies on self-declaration (forgotten or gamed).
- **Detected** — heuristic over changed-file globs (`*.tsx`, `app/`, `components/`, `*.css`, route files). Automatic but noisy: over-gates a types-only edit in a component dir, under-gates UI reached from a non-obvious path.
- **Hybrid-advisory** — detection *proposes* the gate; the author can attest "non-UI" to waive it, and the waiver is recorded. Detection never silently blocks; declaration makes it hard.

**My prior (stated as a prior, to be argued against, not as a conclusion).** Agent0's consistent pattern for a new discipline is a *non-blocking advisory* first — `tdd-advisory`, `lint-advisory`, `typecheck-advisory` — that earns a hard gate only by the rule-of-three demand test. A mandatory browser-verification gate that over-fires will get rubber-stamped or disabled, which is worse than no gate. So my prior is: **v1 = hybrid-advisory trigger + a cheap render-floor contract, with navigation/flow depth opt-in per spec; hard `DONE_WHEN` enforcement only for tasks that *declare* UI.** Argue me out of it if the advisory route just becomes drift.

**Questions to resolve**
- **Q1 — trigger:** declarative, detected, or hybrid-advisory? If hybrid, what is the detection glob set and where is the waiver recorded?
- **Q2 — contract depth:** is the render-floor the mandatory bar with navigation/flow opt-in, or should flow traversal be required whenever a flow exists in the spec?
- **Q3 — gate hardness:** blocking gate vs Agent0-style advisory for v1? Does the delegation `SubagentStop` verifier *fail closed* on a missing contract for a declared-UI task, or only warn?
- **Q4 — authoring burden & flakiness:** who writes the interaction trace, and how do we keep interactive (flakier) verification from making the gate unreliable?

Next: codex


### Turn 2 — codex (blind opening) (codex)

Preferred design: hybrid trigger, advisory v1.

Use an explicit SDD field, backed by a diff heuristic:

`UI impact: none | render | interaction | flow`

Declared intent is the source of truth. The heuristic only catches likely omissions: route/page/layout/component/template/CSS/token/nav/form/modal/focus/copy changes in rendered browser surfaces. Backend-only, CLI, docs, tests, specs, migrations, and harness plumbing stay `none` unless they directly change a browser surface.

For `render`, require page load proof: `verify-contract` required roles/names, screenshot, console budget, responsive overflow, structure via `audit`. For `interaction`, add control exploration: click/fill/keyboard on named controls, expected state changes, validation/errors, focus behavior. For `flow`, add traversal: start route, fixture data/auth precondition, ordered actions, expected URLs/screen states at each step, terminal assertion, screenshots/report per step. This should not become pixel-perfect mock comparison; screenshots are review artifacts, while the gate asserts semantic DOM/a11y/console/route/state conditions.

Plug-in points:

In `spec.md`, add visual acceptance only when `UI impact != none`: contract fixture path, base URL, routes, states, viewports, named flows, auth/fixture preconditions, expected evidence outdir. Reconcile `/product` by treating screen-atlas/fixture-spec as design-time source material; SDD visual acceptance is the implementation evidence that the built UI satisfies it.

In `plan.md`, name how the app is served, how fixture/auth state is created, and which `agent-browser.sh verify-contract`/`audit` commands produce evidence.

In `tasks.md`, verification tasks must run those commands and record `report.json`, screenshots, and any flow transcript. If `agent-browser` is unavailable, that is not a pass; it is an explicit unavailable result with risk noted.

In delegation, UI-producing briefs must carry the visual proof in the existing fields, not add a sixth field:
`CONTEXT`: spec visual acceptance + fixture paths.
`CONSTRAINTS`: no done claim from static code review alone.
`DELIVERABLE`: evidence bundle path/report summary.
`DONE_WHEN`: exact `agent-browser.sh verify-contract`/`audit`/flow command passes.

For v1, keep it non-blocking: emit `visual-contract-advisory` when declared/detected UI work lacks visual evidence. This matches `tdd/lint/typecheck` precedent and avoids brittle first-pass gates. Harden only after rule-of-three evidence, probably first for self-declared `UI impact: flow`, where false positives are lowest and missed proof is most costly.

Strongest alternative: a hard declarative gate from day one for any spec/task marked UI-producing. It wins if early dogfood shows agents ignore advisories, UI misses recur, `agent-browser` is reliably installed, and the fixture schema is stable enough that hard failures are mostly true positives.

Strongest objection to my path: advisory hybrid may be too soft and too fuzzy; the exact class of failure this proposal targets is agents saying “looks fine” without driving the UI. If advisories are routinely ignored, the design should graduate faster and narrower: hard-block declared `flow` tasks before trying to hard-block all visual changes.

Next: human
## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| Whether v1 stays purely advisory or hard-blocks declared 'flow' tasks from day one — rests on dogfood evidence not yet collected (whether agents ignore advisories) | unresolved | (none) |
| /product already emits a design-time visual contract; SDD visual acceptance must reconcile as implementation-evidence, not duplicate it | supported | path:.claude/skills/product |
| SDD spec tree (spec/plan/tasks) is where visual acceptance attaches when UI impact != none | supported | path:.agent0/context/rules/spec-driven.md |
| The delegation gate is already a 5-field handoff; UI proof maps into existing CONTEXT/CONSTRAINTS/DELIVERABLE/DONE_WHEN, no 6th field | supported | path:.agent0/context/rules/delegation.md |
| agent-browser already provides the observe+act mechanism (verify-contract/audit) the contract needs; no new primitive required | supported | path:.agent0/tools/agent-browser.sh |
| Advisory-first for a new discipline is an established Agent0 pattern (tdd/lint/typecheck), so a non-blocking visual-contract-advisory in v1 is grounded, not novel | supported | path:.agent0/context/rules/tdd.md |
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesizing runtime:** claude (Claude Code).

**Protocol note.** Both openings were authored under blind commit/reveal — neither model saw the other before committing (hashes verified at reveal). The two independent designs converged on nearly the same shape. Per spec 149, that agreement is *signal, not proof*: every convergent point below is recorded in the ledger against a deterministically-verified `path:` anchor (5/5 anchors `ok`, 0 assertion-only), so the convergence rests on repo facts, not on the two models agreeing.

### Convergence (anchored)

1. **Trigger = hybrid, declaration-first.** A single declared field is the source of truth; a changed-file heuristic only *flags likely omissions*, never silently gates. Codex's concrete proposal — fold trigger **and** depth into one 4-valued field **`UI impact: none | render | interaction | flow`** — is adopted as the working shape (claude's separate trigger+depth axes collapse into it cleanly).
2. **Contract = interaction trace, three opt-in depths**, honoring the human's requirement that it cover navigation + interactive exploration + flow, not static rendering:
   - `render` — page mounts, required roles/names present, console budget, responsive overflow (via `verify-contract`/`audit`);
   - `interaction` — adds named-control exercise (click/fill/keyboard), expected state changes, validation/focus;
   - `flow` — adds ordered traversal from a start route under a fixture/auth precondition, expected URL/state at each step, terminal assertion, per-step evidence.
   The gate asserts **semantic** DOM/a11y/console/route/state conditions; screenshots are review artifacts, **not** a pixel-diff bar.
3. **Plug-in points.** `spec.md` carries visual acceptance only when `UI impact != none` (contract/fixture path, base URL, routes, states, viewports, named flows, preconditions, evidence outdir). `plan.md` names how the app is served + how fixture/auth state is created + which `agent-browser.sh` commands produce evidence. `tasks.md` verification tasks run those commands and record `report.json` + screenshots + flow transcript.
4. **Delegation reuses the existing 5 fields — no 6th.** For a UI-producing brief: `CONTEXT` = spec visual acceptance + fixture paths; `CONSTRAINTS` = no "done" from static code review alone; `DELIVERABLE` = evidence bundle path/report summary; `DONE_WHEN` = the exact `agent-browser.sh verify-contract`/`audit`/flow command passes. The `SubagentStop` verifier checks for that evidence.
5. **`agent-browser` unavailable ≠ pass.** Fail-closed (spec 152/153): an absent binary/Chrome yields an explicit `unavailable` result with risk noted, never a silent green.
6. **Reconcile with `/product`.** `/product`'s visual contract is *design-time source material* (moods, screen-atlas, fixture-spec); SDD visual acceptance is the *implementation evidence* that the built UI satisfies it — distinct artifacts, one feeds the other.
7. **v1 ships as a non-blocking `visual-contract-advisory`**, matching the `tdd/lint/typecheck` advisory precedent; it earns a hard gate only by rule-of-three demand evidence.

### Minority report (preserved verbatim, NOT smoothed into consensus)

Codex raised — against its own preferred path — that advisory-hybrid may be **too soft and too fuzzy** for the exact failure this targets: an agent claiming "looks fine" without ever driving the UI. If advisories are routinely ignored in dogfood, the design should **graduate faster and narrower** — hard-block declared `UI impact: flow` tasks *first* (lowest false-positive rate, highest cost of a miss), before attempting to hard-block all visual changes. This is logged as the one **unresolved** ledger point: the advisory-vs-hard trajectory rests on dogfood evidence not yet collected, so v1-advisory is adopted *provisionally* with `flow` as the pre-identified first hard-gate candidate.

### Recommended next step

**Graduate to a spec.** Hand this synthesis to `/sdd refine` as seed context for its interview (it does not bypass the interview). The spec's open questions should center the unresolved point (advisory→hard trajectory + the `flow`-first hardening trigger) and the still-undesigned detail: the exact detection glob set, the contract/fixture file format, and how the `SubagentStop` verifier locates the evidence bundle. Link this `meeting.md` from the new spec's `## Context / references`.
