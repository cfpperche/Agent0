# 120 — vuln-audit — debate

_Created 2026-05-29._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-05-29

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

**Intent.** vuln-audit is the positive replacement for the supply-chain capacity removed in spec 112. The founder's framing is explicit: *don't gate lib usage at install time; detect vulnerable installed libs and act.* So this capacity answers one narrow, high-signal question — "does a dependency I already lock have a published advisory with a fixed version?" — from the project's lockfiles, across whatever ecosystems the project actually has (stack-aware), identically under Claude Code and Codex (multi-runner, per the 106–113 arc). It reports and proposes; it never auto-upgrades and never blocks a commit or an install. The design north star is *intelligent + stack-aware without over-engineering*: lean on one good multi-ecosystem engine rather than building a scanner matrix, an SBOM pipeline, or a standing audit log.

**Top 3 acceptance scenarios** (most load-bearing):

1. **Stack-aware scan reports vulnerable installed deps** — Given recognised lockfiles (`package-lock.json`, `poetry.lock`, `go.sum`, `Cargo.lock`, `composer.lock`, …); When the audit runs on demand; Then per-finding output = package, installed version, advisory/CVE id, severity, fixed version (if any), plus the list of ecosystems actually covered.
2. **Scanner absent degrades to an advisory, never a hard failure** — Given the scanner binary isn't installed; When invoked; Then a one-line advisory with the install command + the ecosystems it *would* have scanned, exit 0 — mirroring the `lint-advisory:` / `typecheck-advisory:` / `tdd-advisory:` non-blocking family.
3. **Findings carry a proposed remediation, not an auto-fix** — Given a finding with a published fixed version; When surfaced; Then the upgrade target is named but no manifest/lockfile is modified — contract-not-promise.

**Top 3 open questions** (where the spec is deliberately unresolved):

1. **Engine** — osv-scanner-only (one static binary, 19+ ecosystems, OSV DB, call-graph FP reduction) vs osv-scanner + native fallback (`npm audit` / `pip-audit` when absent)? Lean osv-scanner-only; the fallback matrix may be over-engineering. (Trivy explicitly rejected — March-2026 supply-chain compromise, DB updates suspended.)
2. **Trigger surface** — on-demand `/vuln-audit` skill only in v1, or skill + opt-in `/routine` for recurring cadence? Lean skill-only for v1, routine deferred.
3. **Exit-code contract** — always exit 0 (advisory family) or expose an opt-in `--exit-code` for consumers who want to own a CI gate? Lean: 0 by default, `--exit-code` opt-in — but confirm this doesn't smuggle gating back in.

**Where I want pushback (reviewing agent, focus here):**

- **Is osv-scanner-only actually the right "no over-engineering" call, or a single-point-of-failure?** The ~60–65% cross-tool overlap finding cuts both ways: one engine is simpler but provably misses ~35% of what a second engine would catch. Is "intelligent" satisfied by one good scanner, or does it demand at least a second source? Where's the honest line between resilient and over-engineered here?
- **Is the on-demand-skill trigger enough to be useful?** A vuln that lands the day *after* I run the audit is invisible until I next remember to run it. Without a routine or some recurring nudge, does "detect + act" degrade to "detect when I happen to look"? Is deferring the routine a false economy?
- **Non-goals — am I scoping out something load-bearing?** Specifically: is excluding transitive-only findings' *reachability* (call-graph) from v1 acceptance a mistake, given FP-noise is the usual reason these tools get ignored? And is "no audit log" defensible, or will the founder actually want a diff-over-time ("what's new since last scan") that implies *some* persisted state?

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

1. **"Covered ecosystems" needs a sharper contract before the engine choice is safe.** The spec's first acceptance scenario says the audit "reports which ecosystems were actually covered," and the scanner-absent scenario says it names ecosystems it *would* have scanned. That implies Agent0 maintains its own lockfile-to-ecosystem support map, not just delegates discovery to osv-scanner. The open question on stack detection mentions thin pre-detection, but there is no acceptance case for unsupported-but-present lockfiles, mixed supported/unsupported projects, or a stale support map. I would accept osv-scanner-only more readily if v1 explicitly reports three buckets: lockfiles found, lockfiles covered by the chosen scanner, and lockfiles skipped/unsupported. Otherwise "stack-aware" can silently become "whatever the scanner happened to notice."

2. **The current per-finding fields are not quite actionable for transitive vulnerabilities.** The acceptance scenario requires package, installed version, advisory/CVE, severity, and fixed version. For a transitive-only finding, "upgrade package X to Y" is often not the thing the human can edit; the actionable target is the direct dependency/path that brings it in, or an explicit "no direct remediation path known." This is also where the debate's reachability question matters. I would add "direct/transitive/path when available, otherwise unknown" to the output contract, and make reachability a pass-through field only when the scanner provides it, not a v1 analysis promise.

3. **The exit/status model is underspecified for incomplete scans.** I agree with no commit/install gate, and default exit 0 for findings is consistent with the advisory family. But "scanner absent exits 0" plus "clean project reports no findings" creates a risk that unavailable, failed, partially parsed, or offline scans look too similar to clean scans. The spec should define result statuses separately from process exit: clean, findings, unavailable, failed/incomplete. Then `--exit-code` can be narrowly specified as consumer-owned CI behavior, with defaults that never wire into Agent0 gates.

4. **On-demand-only may be acceptable for v1, but the spec should not pretend it fully satisfies "detect + act."** The initiating position correctly asks whether a vulnerability published tomorrow is invisible until the human remembers. I would not force a full routine implementation into v1, but I would make the v1 decision explicit: either add an opt-in routine recipe/documented invocation as an acceptance item, or record routine cadence as a deferred follow-up with the known limitation. Otherwise the trigger-surface open question is doing too much work for a core usefulness concern.

5. **"No audit log" is defensible, but "no stable machine-readable output" would be a mistake.** The non-goal rejects a standing JSONL audit trail/dashboard, which fits the rule-of-three rationale. That should not preclude a one-shot JSON output mode or deterministic structured text from the runtime-neutral tool. Without a stable shape, tests, Codex/Claude parity, and agent-generated remediation summaries will be brittle. I would accept "no persisted log" while adding an output-format acceptance point: human-readable default plus a stable machine-readable mode for tests and wrappers.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

Strong critique — 4 of 5 points expose real ambiguities I left in `spec.md`. Classifying each, with the concrete delta I'd carry into synthesis.

**1. Three-bucket coverage contract (found / covered / skipped-unsupported) — ACCEPT.** This is the right sharpening, and it's load-bearing: without it, "stack-aware" silently degrades to "whatever the scanner noticed," which is exactly the failure I claimed to prevent. The thin pre-detection in OQ-4 was always meant to enable an honest coverage report; you've correctly noted the spec never made that a *verifiable* contract. Delta: rewrite acceptance scenario 1 so the coverage report emits three explicit buckets, and add a scenario for a mixed supported/unsupported project (e.g. a repo with both `package-lock.json` and a lockfile the engine doesn't support) asserting the unsupported one lands in "skipped" with a reason, never silently dropped. The "stale support map" risk you raise is real but I'd keep the map *thin* — it lists only what we surface as a coverage bucket, not a parallel re-implementation of osv-scanner's matcher; OQ-4 already leans "delegate matching to osv-scanner."

**2. direct/transitive/path field + reachability as pass-through-only — ACCEPT (with one scope guard).** Correct that "upgrade X to Y" is useless when X is transitive and the human can only edit the direct dep that pulls it in. Delta: add `dependency kind (direct | transitive)` + `path-to-direct-dependency when available, else "no direct remediation path known"` to the per-finding output contract in scenario 1. On reachability: ACCEPT as a **pass-through field surfaced only when osv-scanner's output already carries it** — and I want to *reject* the adjacent over-reach explicitly in the spec: v1 builds no reachability/call-graph normalization layer of its own. That keeps it honest about "no over-engineering" while not throwing away signal the engine already computes. This resolves my own pushback point on FP-noise.

**3. Result-status model decoupled from process exit — ACCEPT.** This is the best catch. I conflated two axes. "Scanner absent → exit 0" and "clean → exit 0" being indistinguishable is a genuine defect. Delta: define four **result statuses** as a first-class output field — `clean | findings | unavailable | failed` — orthogonal to the process exit code. Default process exit stays 0 for all four (advisory family). `--exit-code` (consumer-owned, opt-in) maps statuses → non-zero codes; the spec will state it never wires into any Agent0 `PreToolUse`/pre-commit path. I'll fold the old exit-code open question (OQ-3) into this, since the status model subsumes it.

**4. Make the v1 trigger decision explicit instead of hiding it in an open question — ACCEPT, but REJECT adding a routine recipe as a v1 acceptance item.** You're right that OQ-2 was doing too much work for a core usefulness concern. Delta: *resolve* OQ-2 in the spec rather than leave it open — v1 is on-demand-skill-only, and Intent/Non-goals will state the **staleness limitation in plain words** ("a vuln published after your last run is invisible until you next run it") and name `/routine` as the documented deferred path. I reject promoting a routine *recipe* into v1 acceptance: that pulls the exact scope we're deferring back across the line, and `/routine` is already a generic capacity that can invoke the skill with zero new code. The honest move is naming the limitation, not half-building the mitigation.

**5. No persisted log ≠ no machine-readable output — ACCEPT (bounded to the `/sdd list --json` precedent).** Correct and important: the rule-of-three rejection was about a *standing JSONL audit trail*, not about structured output. A multi-runner capability with parity tests across Claude + Codex genuinely needs a deterministic shape. Delta: add an acceptance point — human-readable default plus a `--json` one-shot structured mode (statuses + findings). One guard I'll write into the spec: this is **shape-only convenience, not a versioned wire contract** — same posture as `/sdd list --json` ("the field set may evolve; no schema-version key, deliberately"). That gives tests and wrappers something stable to bind to today without committing us to API-grade compatibility.

**Net:** all five accepted in substance; two carry narrow scope-guards (no self-built reachability layer in #2; no routine recipe in v1 in #4; output is convenience-shape not wire-contract in #5). The engine question (osv-scanner-only as SPOF given ~35% miss) is still genuinely open — your critique didn't push on it, and I'd value a Round 2 read: does the three-bucket coverage contract (point 1) make single-engine acceptable *because coverage is now honest*, or is a second source still warranted for the ~35% the OSV DB alone misses?

---

## Round 2 — reviewing agent (critique)

Mostly converged. I would synthesize after this turn rather than force Round 3.

On the remaining engine question: the three-bucket coverage contract makes **osv-scanner-only acceptable for v1**, but only if the spec is honest about what that contract proves. The buckets prove lockfile/support coverage (`found`, `covered`, `skipped/unsupported`); they do **not** prove advisory-corpus completeness. The likely ~35% cross-tool miss set is about source/database/scanner differences, not whether Agent0 noticed the lockfile. So the synthesis should add one explicit line: v1 reports "known vulnerabilities found by the selected OSV-backed engine," not "all vulnerabilities known anywhere."

I would still reject a default second source in v1. Adding `npm audit` / `pip-audit` as fallback or parallel corroboration immediately creates the scanner matrix the spec is trying to avoid: divergent severity models, package identity normalization, duplicated findings, network/auth behavior, and ecosystem-specific remediation semantics. That complexity belongs behind observed demand, not in the first runtime-neutral tool.

Concrete synthesis delta: resolve the engine OQ to "osv-scanner-only for v1"; add the source-completeness caveat above; and defer second-source comparison as a follow-up trigger if real Agent0 projects produce missed advisories that OSV lacks or if a consumer explicitly wants an owned CI gate. If you keep `--exit-code`, it should apply only to the selected engine's result statuses, not imply multi-source assurance.

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged — all five Round 1 critique points accepted in substance; the lone open axis (engine SPOF) was resolved in Round 2 (osv-scanner-only for v1, with a source-completeness caveat). No unresolved disagreements.

**Proposed spec changes:**

- **§ Acceptance, scenario 1 (coverage) — rewrite to a three-bucket contract.** The coverage report must emit three explicit buckets: `lockfiles found`, `covered by the selected engine`, `skipped/unsupported (with reason)`. Add a new scenario for a **mixed supported/unsupported project** (e.g. `package-lock.json` + a lockfile the engine doesn't support) asserting the unsupported lockfile lands in "skipped" with a reason, never silently dropped. _(Critique 1.)_
- **§ Acceptance, scenario 1 (per-finding fields) — extend the output contract.** Add `dependency kind (direct | transitive)` and `path-to-direct-dependency when available, else "no direct remediation path known"`. Reachability/call-graph data is surfaced **only as a pass-through field when the engine already provides it** — v1 builds no reachability normalization of its own. _(Critique 2 + my scope guard.)_
- **§ Acceptance — new scenario: result-status model decoupled from process exit.** Define four first-class result statuses — `clean | findings | unavailable | failed` — orthogonal to the process exit code. Default process exit is `0` for all four (advisory family). An opt-in `--exit-code` maps statuses → non-zero codes for consumer-owned CI; the spec states it never wires into any Agent0 `PreToolUse`/pre-commit path, and that it reflects **only the selected engine's statuses, not multi-source assurance**. This subsumes and removes old OQ-3. _(Critique 3 + Codex Round 2 guard.)_
- **§ Acceptance — new scenario: machine-readable output.** Human-readable default plus a `--json` one-shot structured mode (statuses + findings). Bound it in-spec as **shape-only convenience, not a versioned wire contract** — same posture as `/sdd list --json` (field set may evolve; no schema-version key, deliberately). _(Critique 5, bounded.)_
- **§ Intent + § Non-goals — add the source-completeness caveat (load-bearing).** State plainly: v1 reports *"known vulnerabilities found by the selected OSV-backed engine,"* NOT *"all vulnerabilities known anywhere."* The three buckets prove lockfile/support coverage, not advisory-corpus completeness; the ~35% cross-tool miss is a source/DB difference. _(Codex Round 2 — the sharpest single addition.)_
- **§ Open questions — resolve, don't leave hanging.** OQ-1 (engine) → **osv-scanner-only for v1**; OQ-2 (trigger) → **on-demand skill only for v1**, with the staleness limitation stated in Intent ("a vuln published after your last run is invisible until you next run it") and `/routine` named as the documented deferred path (no v1 acceptance item — a routine recipe would re-import the deferred scope). OQ-3 folded into the result-status model. OQ-4/OQ-5 retained (thin pre-detection for the coverage report; severity-floor as a flag not a default). _(Critique 4 + my reject of a v1 routine recipe.)_
- **§ Non-goals — add two explicit exclusions.** (a) No self-built reachability/call-graph normalization layer in v1 (pass-through only). (b) No default second scanner source — adding `npm audit`/`pip-audit` as fallback or parallel corroboration creates the exact scanner matrix the spec avoids (divergent severity models, package-identity normalization, duplicate findings, per-ecosystem remediation semantics); deferred to observed-demand follow-up. _(Codex Round 2.)_

**Unresolved disagreements:** none — converged.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

Synthesis accepted by the founder (2026-05-30) — no further debate round. All proposed changes applied to `spec.md`, plus 2 deltas surfaced by the founder's monorepo questions (PHP+Node / bun-only):

- `spec.md` § Acceptance — scenario 1 rewritten to the three-bucket coverage contract (`found`/`covered`/`skipped-unsupported`) + extended per-finding fields (`dependency kind`, `path-to-direct-dependency`).
- `spec.md` § Acceptance — new scenario: mixed supported/unsupported lockfiles, using `bun.lock` (covered) vs `bun.lockb` (skipped + migrate hint) as the canonical example.
- `spec.md` § Acceptance — new scenario: result-status model (`clean`/`findings`/`unavailable`/`failed`) decoupled from process exit; `--exit-code` opt-in, consumer-owned, never an Agent0 gate.
- `spec.md` § Acceptance — new scenario: `--json` stable machine-readable output (shape-only, per `/sdd list --json` precedent).
- `spec.md` § Intent — added source-completeness caveat ("known vulns found by the selected OSV-backed engine", not "all vulns known anywhere") + on-demand-only trigger & staleness limitation.
- `spec.md` § Open questions — resolved OQ-1 (osv-scanner-only), OQ-2 (skill-only v1), OQ-3 (folded into status model); retained OQ-4 (thin detection map) + OQ-5 (severity floor) as plan-time.
- `spec.md` § Non-goals — added: no default second source (incl. native `bun audit` for `bun.lockb`-only — deferred behind demand); no self-built reachability layer; clarified no-persisted-log ≠ no-`--json`.
