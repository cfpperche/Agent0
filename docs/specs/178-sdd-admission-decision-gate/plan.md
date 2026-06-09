# 178 — sdd-admission-decision-gate — plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Prose-only rewrite of the SDD admission gate in `spec-driven.md`, plus a one-sentence framing fix in `visual-contract.md`. No tooling, hook, validator, or gate is added — this is a calibration of a written convention that ships to consumers via `sync-harness`.

The three open questions from `spec.md` are resolved (founder-approved 2026-06-08):

- **OQ1 — form of the test: questions-primary, with high-cost surfaces *embedded inside* the questions** (a synthesis of Claude's "keep it tight" and Codex's surface-list catch, beating both pure positions). The gate becomes a fixed 5-question test; the costly-but-obvious surfaces (migration / auth / billing / permission / persisted data / feature flag) appear as inline *examples that make questions 2 and 4 bite*, **not** as a standalone enumerated catalog (which would rot and re-introduce over-trigger by literal match).
- **OQ2 — boundary-crossing: one example sentence, no formal definition.**
- **OQ3 — UI-proof recipient: list all three (PR body / `report.json` path / handoff) as acceptable, mandate none** — mandating one misfires across the consumer fleet (not all use PRs).

The canonical gate text (to be written into `§ When SDD applies`):

> SDD is owed when, before editing, **any one** of these questions lacks a short answer already determined by existing convention:
> 1. What observable behavior or contract changes? *(nothing visible outside this file → trivial)*
> 2. Who outside this local file/module depends on it? *(callers, another service, a consumer, a public route, persisted data)*
> 3. How will it be proven?
> 4. If it is wrong, how is it reverted or migrated? *(migrations, auth, billing, permissions, persisted data, feature flags rarely have a trivial answer here)*
> 5. Which approach was chosen among plausible alternatives? *(no real choice → trivial)*
>
> If every answer is trivial / already-determined / not-applicable → **skip SDD**, go straight to the edit. If even one needs explanatory writing → **write a spec**.
>
> Breadth (file count) is **not** a trigger. It is evidence only when it crosses independent boundaries — `API + client + persistence` crosses; `component + hook + test + stylesheet` does not.

`§ When to skip` is rewritten to make the wide-but-trivial cases explicit (mechanical multi-file renames; obvious-cause bugfixes even with test/fixture/doc churn; small UI tweaks that change no flow/state/permission/contract), and to state that **skipping SDD never waives proof**: if UI surfaces changed, the visual-contract obligation still holds and its evidence lives in PR body / `report.json` / handoff. The "when in doubt, write a spec" closer is replaced with "when in doubt, ask *which question a spec would answer* — if none, skip" (the file-count-free version of the same insurance instinct).

`visual-contract.md` needs only its opening framing sentence aligned: today line 3 reads "When a spec or a delegated task produces UI…", which implies proof is spec-coupled. The *mechanism* is already spec-independent — the path-based detector + validator advisory (line 62) fires on any changed UI surface in the working tree regardless of whether a spec exists. So the fix is to reword the framing to "When any change produces UI (with or without a spec)…" and add one clause naming the non-spec recipient for the evidence. No mechanism change.

## Files to touch

**Modify:**
- `.agent0/context/rules/spec-driven.md` — rewrite `§ When SDD applies` (remove file-count trigger; install the 5-question test + boundary-crossing example sentence) and `§ When to skip` (explicit wide-but-trivial skip cases; "skipping ≠ waiving proof" clause; replace the "when in doubt, write a spec" closer). Net length should stay roughly flat — the question block replaces, not supplements, the old bullet list.
- `.agent0/context/rules/visual-contract.md` — reword the opening framing sentence (line 3) so the UI-proof obligation is explicitly independent of a spec/task, and name the non-spec recipient (PR body / `report.json` / handoff). Single-sentence + one clause; mechanism (detector/advisory at line 62) untouched.

**Create:** none.

**Delete:** none.

## Alternatives considered

### Codex's enumerated-surface gate (standalone contract-surface list as a trigger)

Rejected as the *primary* mechanism. A standalone list ("spec required if it touches API/schema/permission/billing/telemetry/flag/persisted-data…") rots (someone always appends one more) and re-introduces over-triggering by literal match — a consumer adding a single analytics event would think it needs a spec. The surfaces are kept, but folded *into* questions 2 and 4 as examples that make those questions bite, so they prompt judgment instead of auto-firing. This captures Codex's real catch (costly-but-obvious changes must not skip) without the catalog's failure mode.

### Keep "3+ files" as a demoted safety-net tiebreaker

Rejected (this was Claude's first instinct; the founder and the Codex debate killed it). Mechanical breadth is the exact thing being removed — keeping it even as a tiebreaker preserves the misfire. Boundary-crossing fully replaces it: it is breadth that *means something* (crossing contracts/ownership), which is already captured by question 2.

### Rewrite the visual-contract mechanism to be explicitly spec-independent

Rejected as unnecessary. The detector/advisory (line 62) is already path-based and spec-independent; only the prose framing implies coupling. Touching the mechanism would be scope creep into spec 155's territory for zero behavior gain.

## Risks and unknowns

- **Subjectivity risk:** "is the answer trivial?" is a judgment call. Mitigation: the 5 questions are concrete and the inline examples anchor the high-cost cases; this is strictly less subjective than the status quo (which was *also* a judgment call, just keyed on a misleading proxy). Accept residual subjectivity — a written gate cannot be fully mechanical without re-introducing bad proxies.
- **Consumer drift on sync:** the rule is consumer-customizable in principle; `sync-harness` will flag it `!! customized` for any consumer that edited it. Mitigation: none needed — that is the intended 3-way reconciliation behavior; document nothing special.
- **No mechanical verification:** acceptance is "the rule text reads correctly and a human applying it to the four scenarios gets the right skip/spec verdict." There is no test harness for a prose gate (and adding one would violate the spec's own non-goal). Verification is a human read-through against the four acceptance scenarios — appropriate for a reversible prose change (per the project's match-rigor-to-reversibility doctrine).
- **Unknown:** whether `flow`-tier UI proof without a spec is well-served by the three recipients. Low stakes — flow-tier changes almost always *do* carry a spec (they are decision-heavy by nature), so the no-spec path is dominated by render/interaction tweaks where `report.json` suffices.

## Research / citations

- Adversarial Claude×Codex debates via `codex-exec.sh` (read-only, high reasoning): `.agent0/.runtime-state/codex-exec/sdd-debate-out.md` and `.agent0/.runtime-state/codex-exec/sdd-threshold-out.md` — source of the 5-question test and the boundary-crossing reframe.
- `.agent0/context/rules/visual-contract.md` line 3 (framing) + line 62 (path-based detector) — establishes that the proof mechanism is already spec-independent.
- Consumer spec-count evidence (2026-06-08): Agent0 166 vs ~48 across 7 consumers — calibration target is the consumer, not Agent0.
- `.agent0/context/rules/agent0-governance-doctrine.md` / `scope-admission-governance.md` — scope classification below.

## Scope-admission classification (governance doctrine)

Per `spec-driven.md` § Relationship to other rules, a change to a consumer-facing harness convention is classified before tasks:

- **Layer:** governance convention (rule doc), not a capacity/tool/hook/gate.
- **Ownership boundary:** Agent0-owned shared rule; ships to consumers via `sync-harness`; consumer may override (flagged `!! customized`).
- **Evidence:** two adversarial-debate transcripts + consumer spec-count data; the misfire is concretely demonstrated (wide-but-trivial rename, UI tweak).
- **v1 posture:** prose-only, advisory-only ecosystem unchanged; no new blocking behavior.
- **Blast radius:** changes *when contributors write specs* across all consumers — meaningful, hence the spec (this change passes its own revised bar: it crosses the Agent0↔consumer boundary). Reversible: it is rule prose; revert is a `git revert`.
- **Validation:** human read-through against the four acceptance scenarios; `doctor.sh` stays green (no mechanism touched).
- **Non-goals:** enumerated in `spec.md` § Non-goals (no quota, no Agent0-local discipline, no tooling, no mechanism rewrite).
