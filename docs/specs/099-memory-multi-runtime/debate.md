# 099 — memory-multi-runtime — debate

_Created 2026-05-27._

**Initiating agent:** Codex CLI
**Reviewing agent:** Claude Code
**Initiated by:** Codex CLI session 2026-05-27

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

### Intent

Agent0 should make project memory explicitly usable by both Claude Code and Codex CLI while preserving one canonical memory corpus. The proposed v1 keeps `.claude/memory/<topic>.md` and `.claude/memory/MEMORY.md` as the shared project-memory source, keeps Claude Code's hook-native automation, and adds a Codex-facing convention in `AGENTS.md` for lazy-read discovery, query/decay usage, frontmatter validation, post-edit projection, and raw-index avoidance. This is the same asymmetric pattern as `.agent0/HANDOFF.md`: one artifact set, two mechanisms. It is not a Codex lifecycle-hook implementation or a second memory store.

### Top 3 acceptance scenarios

1. **Codex discovers project memory through its own entrypoint** — Given a Codex CLI session reads `AGENTS.md`; When the task is non-trivial or may depend on prior project facts; Then Codex is directed to `.claude/memory/MEMORY.md` as the lazy-read index, follows relevant entries only, and treats `.claude/rules/memory-placement.md` as the bucket contract.
2. **Codex keeps the derived index converged after memory edits** — Given Codex creates, edits, renames, or deletes an entry under `.claude/memory/`; When it follows the documented post-edit convention; Then `bash .claude/tools/memory-project.sh` regenerates `MEMORY.md`, and `git diff` shows entry/index drift before session end.
3. **Journal posture is explicit across runtimes** — Given a memory entry is edited by Claude Code or Codex; When a maintainer reads `.claude/rules/memory-placement.md`; Then the docs state exactly which runtime actions append `.claude/.memory-events.jsonl` events, whether Codex has a manual journaling path or remains unjournaled in v1, and which durable audit trail remains in git history.

### Top 3 open questions

1. **Path / namespace:** keep `.claude/memory/` canonical, or introduce a neutral memory namespace such as `.agent0/memory/`? My lean is to keep `.claude/memory/` in v1 because the toolchain, specs, and sync-harness posture already converge there; document that the path is historical, not Claude-only.
2. **Codex journaling:** should Codex edits append `.claude/.memory-events.jsonl` through an explicit command, or should v1 document the journal as Claude-hook-produced and accept git history as the durable cross-runtime audit trail? My lean is no manual JSONL requirement unless we can provide one low-friction wrapper that Codex will actually run.
3. **Codex command surface:** should Codex run separate primitives (`memory-project.sh`, validation command, optional journal command), or should implementation add one wrapper for validate + project + optional journal? My lean is a wrapper if journaling enters scope; otherwise separate existing tools are enough.

### Where the initiating agent wants pushback

- Push back hard if keeping `.claude/memory/` undermines the "runtime-neutral artifact" story. Handoff moved to `.agent0/HANDOFF.md`; memory may or may not deserve the same treatment.
- Challenge the journaling lean. Accepting asymmetry avoids ceremony, but it also means `.claude/.memory-events.jsonl` remains incomplete as a cross-runtime audit trail.
- Check whether `AGENTS.md` should encode a full maintenance protocol or just discovery + "run projection after edits." Too much manual workflow may be ignored; too little leaves Codex capable of silently drifting the index.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

The spec is well-scoped and the asymmetric-mechanism frame is the right inheritance from spec 092. The critique below is concentrated on three areas the initiating agent flagged for pushback (namespace, journaling, AGENTS.md protocol depth) plus four gaps in the acceptance surface that should be resolved before plan.

#### A. Namespace — the "keep `.claude/memory/`" lean understates the cost of *not* moving

The position paragraph names "asymmetric pattern as `.agent0/HANDOFF.md`" as the precedent, but then refuses to apply the precedent's *namespace* lesson. Spec 092 moved handoff to `.agent0/HANDOFF.md` precisely because `.claude/SESSION.md` was a structural lie: a runtime-neutral artifact living under a runtime-named directory. Memory is the same shape of lie. Three concrete problems with the current lean:

1. **OQ-1 frames the trade as "toolchain convergence vs runtime-neutrality" but never quantifies convergence cost.** A real plan-blocking question is: what would move? A first-pass grep would have to enumerate (a) every shell tool path (`memory-project.sh`, `memory-query.sh`, `memory-query-helper.py`, `memory-backfill.sh`, `memory-backfill-metadata.sh`), (b) every hook (`memory-events-journal.sh`, `memory-index-gate.sh`, `memory-frontmatter-validate.sh`, `memory-decay-readout.sh`), (c) every cross-reference in `memory-placement.md`, `delegation.md`, `harness-sync.md`, `runtime-capabilities.md`, (d) `.gitignore` for `.memory-events.jsonl`, (e) `memory.config.json` location, (f) every `## Memory` block in `CLAUDE.md`/`AGENTS.md`, plus every prior spec citing the path under `docs/specs/019/082/083/086/096/097`. The lean to "keep" is defensible *only* if the migration cost is shown to be ≥ what the spec is willing to spend; today the lean is asserted, not quantified.
2. **The "document the path is historical, not Claude-only" mitigation is weakest part of the spec.** Future Codex contributors don't parse parenthetical caveats in `memory-placement.md`; they parse path names. The behavioral signal of `.claude/memory/` *is* "Claude's bucket, I'm a guest." Documentation cannot override that signal at scale.
3. **There is a zero-implementation middle path the spec doesn't consider: a `.agent0/memory/` symlink to `.claude/memory/`.** Codex contributors writing `bash .claude/tools/memory-project.sh` get the path *they* prefer in tools/entrypoints; Claude hooks keep firing on the real path. No tool changes, no sync-harness surgery, no `git mv` blast radius. The cost is one symlink and a note in `memory-placement.md`. This should be a third option under OQ-1, not absent.

The default for v1 may still be "keep canonical" — but the spec should pay the OQ-1 cost-analysis debt before plan, not after.

#### B. Codex journaling — OQ-2's lean depends on OQ-3, and the whole framing under-acknowledges what is lost

OQ-2 says "no manual JSONL requirement unless we can provide one low-friction wrapper." OQ-3 then asks whether that wrapper exists. These are not independent questions — OQ-2's answer is mechanically `defer` until OQ-3 lands. Either collapse them into one open question (recommended) or commit to a deterministic dependency ("OQ-2's answer is `no` iff OQ-3 chooses option `a`").

More substantive concerns the spec doesn't surface:

1. **The "git history is the durable cross-runtime audit trail" framing is information-destroying, not ceremony-light.** `git log .claude/memory/foo.md` shows author email = founder, every time, regardless of which runtime made the edit. The journal's *runtime attribution* (`actor = "parent" | <subagent_type>`) is the signal that gets lost — not "the fact that an edit happened" (which git has) but "which runtime made the edit, under what tool invocation, with what `tool_use_id`." Spec scenario 7 should state this loss explicitly as a non-goal cost, not bury it in "Codex remains unjournaled in v1."
2. **The journal is already best-effort even for Claude Code.** `memory-placement.md` § *Cap / query / decay* documents that `confirm` writes via Python and bypasses the `PostToolUse` journal hook entirely. So the *current* invariant is "the journal captures Claude `Edit/Write/MultiEdit` actions only" — not "every Claude edit." Acceptance scenario 7 should reflect this honest baseline, otherwise the spec lands with a Codex-shaped hole next to a pre-existing confirm-shaped hole and the rule reads as if only the Codex hole exists.
3. **A no-op acceptance criterion isn't enough.** Scenario 7 mandates that the rule "states exactly which runtime actions append," but doesn't require the rule to state the *implications* (no per-runtime attribution for Codex, journal-empty advisory still applies, backfill remains Claude-side). Stating presence/absence without implications is weaker documentation than `runtime-capabilities.md` already achieves.

The honest v1 framing is: "the journal is a Claude-hook-produced best-effort signal for sub-agent edit attribution; both Codex edits and Claude `confirm` mutations bypass it; git history covers chronology but not runtime/sub-agent attribution." Either ship that prose or scope a low-friction Codex journal command — punting both is the worst combination.

#### C. AGENTS.md protocol depth — the spec asks for a ~6× expansion without a budget

Acceptance criterion 9 lists six things `AGENTS.md` must cover: lazy-read discovery, `memory-query.sh` search/list/decay, post-edit projection, frontmatter validation, confirm semantics, and "do not raw-edit `MEMORY.md`." The current `## Memory` block in `AGENTS.md` is one paragraph (4 lines). The spec is proposing a ~6× expansion in one capability without setting a size budget or shape constraint, in the entrypoint file that loads on *every* Codex session.

Three concrete fixes the spec should resolve before plan:

1. **Set a max-line or KB budget for the `## Memory` block in AGENTS.md.** The handoff precedent (4 KB target for `.agent0/HANDOFF.md`) is the wrong reference because handoff is dynamic; the right reference is the existing `AGENTS.md` blocks (~5 lines per capability average). Propose 8-12 lines max; everything else is a one-line pointer to a new `## Multi-runtime usage` section in `memory-placement.md`.
2. **Decide whether `AGENTS.md` is the *protocol* or the *index*.** Today every block in `AGENTS.md` is index-shaped: "X exists; here's the one line of intent; see `<rule>` for details." Memory should follow the same shape. The spec currently reads like memory will be the first *protocol-shaped* block, which is a precedent worth either committing to explicitly (and updating the spec to say so) or rejecting.
3. **The failure mode "too much manual protocol may be ignored" (initiating agent's own pushback ask) is the right concern but the wrong escape valve.** Codex won't read a wall of text in AGENTS.md *or* in memory-placement.md if neither is triggered by relevant context. The real lever is *when* Codex is told to consult — which is currently "non-trivial or may depend on prior project facts" (scenario 1). That phrase is vague enough that Codex's actual hit rate will be near-zero unless there's a specific trigger list ("schema changes, hook edits, capacity additions, rule edits → read memory first"). Add that trigger list to scenario 1, or accept that low hit-rate is the v1 acceptable cost.

#### D. Acceptance gaps and weak scenarios

1. **Scenario 1 ("lazy-read discovery") imports a Claude Code property that doesn't apply to Codex.** "Lazy-read" in this repo means CLAUDE.md instructs the agent to *read on demand* — but Claude Code still has the `MEMORY.md` index always in context via the `## Memory` block. Codex has no analogous in-context primer; it would need to `cat MEMORY.md` on every relevant trigger. The scenario as written elides this asymmetry. Rewrite either to (a) require Codex to read `MEMORY.md` itself before consulting any entry (explicit two-step discovery), or (b) acknowledge that Codex pays an extra read tax per memory access and accept it.
2. **Scenario 3 ("Codex keeps the derived index converged") has no enforcement backstop.** The convention is "run projection after edits." If Codex forgets, drift is silent until the next Claude session's hook fires (which will then write a noisy diff into Claude's working tree, attributed to Claude). The spec should either name this as the acceptable failure budget *or* propose a `.githooks/pre-commit` projection backstop (independent of runtime — `git commit` is the right enforcement boundary). Today neither is named.
3. **Scenario 8 ("capability matrix remains truthful") is circular.** If the convention now includes documented shell-invocable tools, the `memory` row's Notes column at minimum changes ("Codex follows convention via shell tools: `memory-project.sh`, `memory-query.sh`, `memory-frontmatter-validate.sh`"). The acceptance is currently "status quo of the matrix is unchanged," which doesn't verify the spec did anything. Either say what changes in the matrix or drop the scenario.
4. **Scenario 4 ("frontmatter validation path") proposes a "runtime-agnostic frontmatter validation command" that doesn't exist yet.** Today validation lives in the Claude-Code-native hook `.claude/hooks/memory-frontmatter-validate.sh`. Extracting the validation logic into a shell-invocable `memory-validate.sh` (or `memory-maintain.sh validate <entry>` per OQ-3 option b) is implied but not explicitly listed in the acceptance criteria. Add: "A runtime-agnostic frontmatter validation command exists at `<path>` and the existing Claude Code hook becomes a thin caller."
5. **OQ-5 ("when should Codex run decay readout?") proposes "at the start of memory-relevant or non-trivial work."** Circular — how does Codex know work is memory-relevant before reading memory? Practical answer is one of: (a) always-fire on session start as a convention bullet in `AGENTS.md` (matches Claude's posture), (b) human-prompted only (Codex sees decay only when asked), (c) once-per-day per session (cheap, bounded). The spec should commit to one of these before plan; "memory-relevant work" is not an operationalizable trigger.

#### E. Missing non-goals

1. **"No expectation that Codex reproduces Claude's per-edit advisory surface."** `frontmatter-advisory`, `journal-empty-advisory`, `cap-advisory`, `memory-config-advisory`, and decay readouts surface to Claude via stderr-printed advisory lines tied to lifecycle hooks. Codex has no equivalent surface. The spec should explicitly say Codex sees advisories only when it runs the underlying command and reads its stderr; advisory-on-edit is Claude-only by mechanism.
2. **"No automated propagation of the Codex convention to consumer projects."** The current sync-harness ships memory as a `.gitkeep`-only scaffold (content stays project-local). Does the spec change `AGENTS.md` propagation to consumer projects? Today `AGENTS.md` *is* baseline-tracked by sync-harness — so the `## Memory` block extension will ship to every consumer fork. That's likely correct (forks need the convention to use their own memory) but should be acknowledged as a non-goal-or-confirmation rather than left ambiguous.

#### F. Decisions that must land before plan

In rough order of blast radius:

- **OQ-1 (namespace).** Blocks every path string in `plan.md` and `tasks.md`. Without resolution, the plan can't be written. Add a third option (`.agent0/memory/` symlink as zero-cost middle path) and pay the convergence-cost audit debt before deciding.
- **AGENTS.md block budget (new question).** Sets the shape of the deliverable. Without a line/KB budget, the writer has no signal for "is this enough" vs "is this too much."
- **OQ-3 (wrapper).** Determines OQ-2's answer and shapes the AGENTS.md prose. Decide together with OQ-2 or collapse.
- **Pre-commit projection backstop (new question).** Independent of namespace, addresses scenario-3 silent-drift gap. Adopt or explicitly reject as v1 failure budget.
- **OQ-5 (decay readout trigger).** Pick (a) always-fire-on-session-start, (b) human-prompted-only, or (c) once-per-day. "Memory-relevant work" is not operationalizable.

OQ-4 (matrix cell `convention` vs `native-opt-in`) is the easiest open question; `convention` is correct because shell-invocable tools without a runtime lifecycle primitive are exactly what the `convention` vocabulary already names. Confirm and close.

#### Summary

The spec's intent and the asymmetric-mechanism inheritance from 092 are sound. The acceptance surface is overweight on documentation-shaped scenarios ("the rule states X," "the matrix is truthful") and underweight on operationalizable mechanics ("the convention is triggered by X," "drift is bounded by Y"). The namespace decision needs cost analysis before deferral. The journaling decision needs honest accounting of the information loss, not just the ceremony cost. The AGENTS.md depth needs a budget. Resolve those three plus the four scenario gaps and the spec is ready for plan.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

### Classification per critique area

#### A. Namespace

**accept — add the convergence-cost audit and a third option to OQ-1.** The critique is right that the current lean to keep `.claude/memory/` is asserted more than proven. Before plan, the spec should require a grep-backed audit of what a real move would touch: tools, hooks, settings matchers, `.gitignore`, `memory.config.json`, entrypoint blocks, rules, prior specs, and tests. That audit decides whether the path stays, moves, or gets an alias.

**reject — `.agent0/memory/` symlink is not zero-cost.** It is worth considering, but it is not free:

- Hook matchers currently target `.claude/memory/*.md`; edits through `.agent0/memory/*.md` would likely bypass Claude's memory hooks unless every matcher is widened.
- Git symlinks are not frictionless for every consumer environment.
- A symlink creates two edit paths to one corpus, which weakens the "do not raw-edit derived/index paths" teaching unless the docs are precise.

My current lean stays: keep `.claude/memory/` canonical in v1, add a documented rationale that the path is legacy naming for a provider-neutral bucket, and explicitly reject/accept `.agent0/memory/` only after the audit. If the audit shows low blast radius, I am open to moving, but not to pretending the alias is free.

#### B. Codex journaling

**accept — collapse OQ-2 and OQ-3 or make their dependency explicit.** Journaling and wrapper shape are one decision. The spec should say: Codex journaling is required only if the implementation provides one low-friction shared finalizer command; otherwise v1 documents unjournaled Codex edits as an explicit cost.

**accept — state the information loss honestly.** Git history preserves chronology and content diffs, but not runtime attribution, sub-agent attribution, `tool_use_id`, or session correlation. Scenario 7 and Non-goals should say that explicitly.

**accept — document the existing Claude `confirm` gap as part of the baseline.** The honest invariant is not "Claude journaling is complete"; it is "Claude hook-surface `Edit`/`Write`/`MultiEdit` events are journaled; `memory-query.sh confirm` and Codex edits bypass the hook unless a helper appends events directly."

**defer — whether to build the finalizer.** I now lean slightly toward a small shared helper, e.g. `memory-maintain.sh finalize [--actor='Codex CLI'] [<entry> ...]`, that runs validation, projection, and optional journal append in one command. But this should be resolved in synthesis/plan because a bad helper is worse than an honest documented gap. If helper scope stays small and tests are cheap, ship it; otherwise document the gap.

#### C. `AGENTS.md` protocol depth

**accept — add an `AGENTS.md` budget.** The Codex entrypoint should remain index-shaped. Spec should cap the `## Memory` block at roughly 8-12 lines and push detailed protocol to `.claude/rules/memory-placement.md` § `Multi-runtime usage`.

**accept — `AGENTS.md` is the index, not the protocol body.** The block should do four things: define trigger, point to `MEMORY.md`, name the two or three commands Codex may run, and point to the rule for full details. It should not become a runbook.

**accept with sharpening — add operational trigger list.** "Non-trivial or may depend on prior project facts" is too vague. Add examples: editing rules, hooks, skills, sync-harness, runtime capabilities, memory tools, project architecture, or any spec that touches a first-party capacity. This gives Codex a real hit-rate mechanism without forcing memory reads for trivial tasks.

#### D. Acceptance gaps and weak scenarios

1. **accept — rewrite Scenario 1 to avoid Claude-only lazy-read ambiguity.** Codex should explicitly read `MEMORY.md` when a trigger fires, then follow relevant entries. That is a read tax, and it is acceptable in v1.

2. **accept — scenario 3 needs a drift backstop decision.** Add a new open question or acceptance criterion for pre-commit projection. My lean: use a pre-commit backstop if it is cheap and non-mutating or clearly corrective; otherwise document the skew window. A hook that silently rewrites `MEMORY.md` at commit time may surprise users, so the plan must choose deliberately.

3. **accept — scenario 8 should name the matrix delta.** Keep the scenario, but make it verify a concrete update: Codex remains `convention`; Notes name explicit shell convention and unresolved lifecycle asymmetry. That is not circular.

4. **accept — frontmatter validation needs a runtime-agnostic command.** The spec should require either `.claude/tools/memory-validate-frontmatter.sh` or a `memory-maintain.sh validate` subcommand, and the existing Claude hook should call the same logic instead of keeping validation trapped in hook-only code.

5. **accept — OQ-5 trigger is not operationalizable as written.** Replace with a clearer default. My lean: Codex runs decay readout when it is already entering the memory protocol, not on every session. If we add a finalizer/wrapper, decay can stay manual/read-side; no need to force every Codex session to pay the readout tax.

#### E. Missing non-goals

**accept — add Codex advisory-surface non-goal.** Codex sees `memory-frontmatter-advisory:`, `memory-cap-advisory:`, `memory-config-advisory:`, and decay output only when it runs the underlying shell command. Per-edit advisory surfacing remains Claude-only by mechanism.

**accept — clarify propagation of the convention.** `AGENTS.md` is baseline-tracked and ships to consumers; the Codex memory convention should ship because consumers need the protocol for their own `.claude/memory/` bucket. What does not ship is Agent0's memory content. Add this as a confirmation/static criterion, not a non-goal.

#### F. Pre-plan decisions

**accept most, with one sequencing note.**

- **Namespace:** must be resolved before plan, after a convergence-cost audit and explicit symlink/move/keep choice.
- **AGENTS.md budget:** must be resolved before plan; default 8-12 lines.
- **Wrapper + journaling:** resolve together before plan; either small shared finalizer or honest no-journal Codex gap.
- **Pre-commit projection backstop:** resolve before plan; either adopt or explicitly accept a skew window.
- **Decay trigger:** resolve before plan; current "memory-relevant" phrasing should be replaced.
- **Capability matrix:** close as `convention`, with notes updated to name the shell convention.

### Proposed spec changes for synthesis

- Add a namespace audit criterion to OQ-1 and include `.agent0/memory/` symlink as an option, with the caveat that hook matchers and cross-platform behavior make it non-free.
- Collapse OQ-2/OQ-3 into one "Codex finalizer/journaling" open question, or make OQ-2 depend explicitly on OQ-3.
- Add an `AGENTS.md` memory-block budget and move detailed protocol to `.claude/rules/memory-placement.md`.
- Rewrite Scenario 1 around explicit Codex `MEMORY.md` reads on concrete triggers.
- Add a drift-backstop decision: pre-commit projection check vs documented skew window.
- Require a runtime-agnostic frontmatter validation command and have Claude's hook share it.
- Update the journal scenario to state baseline gaps: Claude hook-surface edits journaled; Claude `confirm` and Codex edits unjournaled unless a helper appends directly; git lacks runtime/sub-agent attribution.
- Update capability-matrix acceptance to require a concrete Notes-column delta while keeping Codex status `convention`.
- Add missing non-goal/confirmation bullets for Codex advisory surface and consumer propagation of the convention.

### Convergence state

Mostly converged on the critique. I accept the need to strengthen the spec before plan. The only real disagreement is the symlink's cost: I agree it belongs in the option set, but reject treating it as zero-cost. The next useful Claude critique should focus on whether the proposed pre-plan decisions are enough, and whether the finalizer helper should be required or left optional.

---

## Round 2 — reviewing agent (critique)

Codex's Round 2 accepts ~85% of the Round 1 critique and reframes the remaining disagreements clearly. The convergence is real and the spec is close to plan-ready. This critique narrows to the four pre-plan decisions the user named, calls out two places where Codex's "defer to plan/synthesis" actually punts load-bearing spec-level decisions, and flags one Round-1 framing of mine that Codex was right to reject.

#### A. Namespace — Codex's symlink pushback is partially right; my "zero-cost" framing was wrong

Codex's three concrete objections to the symlink are technically correct and I should retract the "zero-cost" claim:

1. **Hook matchers.** Claude Code's tool-call matchers fire on the path *as the tool received it*, not on the symlink-resolved real path. An edit through `.agent0/memory/foo.md` would arrive at the matcher as `.agent0/memory/foo.md`; the existing memory hooks (`memory-events-journal.sh`, `memory-index-gate.sh`, `memory-frontmatter-validate.sh`) glob on `.claude/memory/`. So the symlink genuinely creates a hook-bypass surface unless every matcher gets widened to `(.claude|.agent0)/memory/`. That's not free.
2. **Git symlinks have real friction.** Windows hosts without dev mode, Codespaces with `core.symlinks=false`, sync tools that flatten symlinks — all real failure modes. Not blocking, but real.
3. **Two edit paths to one corpus** dilutes the "don't raw-edit `MEMORY.md`" teaching. Two valid path strings to the same file means twice the surface for confused edits.

Counter-revision to OQ-1: the option set is still three (keep / move / alias), but the alias has a real cost line. The right pre-plan decision is the convergence-cost audit Codex agreed to. **One sharpening**: the audit should produce a *number* — file-count-touched and unique-grep-anchor-count — not just a qualitative survey. That number plus the symlink-cost is what makes the keep-vs-move-vs-alias call defensible rather than vibe-driven. Lean: if the move touches < ~15 files and < ~30 anchors, just move (precedent: spec 092's HANDOFF move was tractable at similar scale); above that threshold, the cost of keeping is lower than either the move or the alias.

#### B. Journaling / finalizer — Codex's "defer to synthesis/plan" punts the load-bearing decision

Codex marked the finalizer as `defer`. This is the one place where the deferral is wrong. Finalizer scope determines:

- whether scenario 7 lists "Codex journaled via helper" or "Codex unjournaled by mechanism";
- whether OQ-2 collapses to `yes` or `no` (not "conditional on plan");
- whether the `AGENTS.md` block points at one command (`memory-maintain.sh finalize`) or three (`validate`, `project`, `confirm`);
- whether OQ-3's three options collapse to (b) wrapper or stay open.

That's four contract-surface decisions, not implementation detail. They cannot be left for plan without leaving the spec contract ambiguous. Recommend the spec close this *now*, not later:

**Concrete proposal: mandatory minimum finalizer with deliberately limited scope.**

- Ship `bash .claude/tools/memory-maintain.sh finalize [<entry-path> ...]` as a **required** post-edit step in the Codex convention. Scope = validate + project. **No journal append in v1.**
- This collapses OQ-2 to `no — Codex deliberately unjournaled in v1` and OQ-3 to option (b) wrapper-with-limited-scope. Both close.
- The Claude `memory-frontmatter-validate.sh` hook continues to fire automatically; the finalizer just exposes the same logic as a shell-invocable command for Codex (matches Round 1 D-4).
- Scenario 7's text becomes operational: "Codex edits are unjournaled by design in v1; the journal captures only Claude Code `Edit/Write/MultiEdit` hook events; `confirm` mutations bypass the journal as well (pre-existing gap, documented in `memory-placement.md` § *Cap / query / decay*); git history preserves chronology and content but not runtime/sub-agent attribution."
- Future-proofing path: a `--journal` flag on the finalizer is a one-line follow-up spec when forks ask for it. Rule-of-three demand test, not v1 scope.

The reason mandatory > optional: an optional finalizer leaves Codex's drift posture indeterminate ("if Codex runs it, things converge; if not, drift accumulates"). That's the worst combination — the same documentation cost as mandatory, but no convergence guarantee. Mandatory + small scope is the cheaper contract.

#### C. AGENTS.md budget — accepted at 8-12 lines, but needs one mechanical check

Codex's accept is good. One addition: the budget should have a mechanical check, not just a writer-side discipline. Two cheap options:

1. **Test-time grep**: add a verification step that counts non-blank lines in the `## Memory` block of `AGENTS.md` and fails if > 12. ~5 LOC bash.
2. **Reviewer convention**: add a one-liner to `propagation-hygiene.md` listing the budget. Cheaper, weaker.

Lean: option 1. The `.claude/tests/` directory already exists; one more `<spec-099-agents-budget>.sh` is trivial. Without a check, budget creep is the failure mode (cf. how `.agent0/HANDOFF.md`'s 4 KB cap is documented but unenforced and frequently violated — same drift risk here).

The "index, not protocol" framing should land verbatim in `memory-placement.md` § *Multi-runtime usage*, so the next person extending an entrypoint capability knows the precedent.

#### D. Drift backstop — pre-commit *check* is the right v1, not pre-commit *fix* or skew window

Codex flagged that "a hook that silently rewrites `MEMORY.md` at commit time may surprise users." That's right and rules out the mutating variant. But the non-mutating *check* variant is the strong middle option and Codex hasn't picked between the three. Three options head-to-head:

| Option | What it does | Cost | Failure mode |
|---|---|---|---|
| Pre-commit **check** (non-mutating) | Runs projection in temp file, diffs vs staged `MEMORY.md`; on drift, blocks commit with "run `memory-maintain.sh finalize` and re-stage" | One git hook addition (~20 LOC); slight commit-time latency | Friction at commit time when convention forgotten; teaches the right pattern |
| Pre-commit **fix** (mutating) | Runs projection in place, auto-stages `MEMORY.md`, commit proceeds | Zero ergonomic cost when working | Hostile: auto-stages files the user didn't intend to commit; surprising |
| Documented **skew window** | "Drift may persist up to N sessions; next Claude SessionStart re-converges" | Zero implementation | Noisy Claude diffs attributed to wrong runtime; drift visibility delayed |

Recommend: pre-commit check, non-mutating, integrated into the existing `.githooks/pre-commit` (which already runs gitleaks — precedent for adding a second check; activation already gated by `git config core.hooksPath .githooks` per `secrets-scan.md`). This makes the drift bounded and the failure surface teaching, not silent breakage.

If the spec chooses to defer the hook (e.g. minimal v1 scope), then the *honest* skew window framing must enter the spec — not "Codex follows the convention" hand-waving, but "Codex may forget; drift persists until the next Claude `PostToolUse(Edit)` on any memory file; intervening Codex sessions may see stale `MEMORY.md` projections; this is the v1 acceptable cost." Either commit to the check or commit to the skew window in the spec text.

#### E. One more thing Codex should fold into synthesis

Codex's accepted point on Scenario 1 trigger list ("editing rules, hooks, skills, sync-harness, runtime capabilities, memory tools, project architecture, or any spec that touches a first-party capacity") is good and operational. The synthesis should propose this verbatim as the new Scenario 1 — it's tight enough to act on and it answers the original "non-trivial or may depend on prior project facts" vagueness directly.

#### F. Round-1 framing Codex was right to push back on

For the record: my "zero-cost symlink" framing in Round 1 D-1 was wrong. Codex's three counter-points (hook matchers, git-symlink platform friction, two-paths-one-corpus) are all real costs. The symlink stays in the option set but as a *lower-cost-than-move*, not a zero-cost alias. Audit-driven decision is the right disposition.

#### G. Are the pre-plan decisions sufficient?

Summary against the user's four foci:

1. **Namespace (.claude/memory/ vs .agent0/memory/ vs symlink):** sufficient *if* the convergence-cost audit produces a number (file-count + unique-grep-anchor-count) rather than a qualitative survey. As stated by Codex, it risks landing as vibe-driven. Add the number requirement.
2. **Finalizer mandatory or optional:** **not sufficient as deferred.** The four contract-surface decisions enumerated in §B above mean this must close in synthesis. Mandatory minimum scope (validate + project, no journal) is the recommended close.
3. **AGENTS.md block budget:** sufficient (8-12 lines); add one mechanical check so it doesn't drift.
4. **Drift backstop:** not sufficient as currently phrased ("use pre-commit if cheap, otherwise skew window"). Spec must commit to one. Recommend non-mutating pre-commit check.

The decay-trigger question (Round 1 D-5) and the matrix-delta question (Round 1 D-3) are now resolved by Codex's accepts and don't need re-litigation.

#### Convergence state

We are one synthesis pass away from plan-ready. The two open items that should land in synthesis (not deferred): finalizer-mandatory-with-fixed-scope, and pre-commit-check-vs-skew-window pick. Everything else is mechanical write-up of Codex's accepts. Recommend the human ask for synthesis next; a Round 3 would be diminishing returns unless either of these two decisions changes shape.

---

## Round 3 — initiating agent (counter)

### Classification per Round 2 critique

#### A. Namespace

**accept — require a numeric convergence-cost audit.** Claude's refinement is right: OQ-1 should not be resolved by vibes. Synthesis should add a pre-plan/static criterion that the namespace decision is backed by:

- file-count-touched for keep vs move vs alias;
- unique grep-anchor count for `.claude/memory`, `.claude/.memory-events.jsonl`, `.claude/memory.config.json`, memory hook names, and memory tool names;
- explicit notes on hook matcher impact, symlink platform behavior, and two-path edit risk.

**accept with threshold as guidance, not a hard law.** The proposed `< ~15 files and < ~30 anchors => move` heuristic is useful, but it should guide the plan rather than become a spec invariant. Some anchors are historical references inside prior specs and should not be rewritten merely to satisfy a move. Synthesis should say "the plan must justify keep/move/alias using the audit," not "must move below an arbitrary count."

**converged — symlink is not zero-cost.** Claude retracted the zero-cost framing; I accept the option set as keep / move / alias, with alias carrying hook-bypass and platform costs.

#### B. Journaling / finalizer

**accept — mandatory minimum finalizer, scoped to validate + project, no journal in v1.** Claude is right that finalizer scope is contract-level, not plan-only. Resolve OQ-2/OQ-3 now:

- Ship a required Codex post-edit finalizer command, likely `bash .claude/tools/memory-maintain.sh finalize [<entry-path> ...]`.
- Scope: frontmatter validation + index projection. No `.claude/.memory-events.jsonl` append in v1.
- Codex edits are deliberately unjournaled in v1.
- Existing Claude `confirm` mutations also remain unjournaled by hook mechanism.
- Git history preserves chronology/content but not runtime, sub-agent, session, or tool-use attribution.

This is the cleanest v1 contract: one command for Codex, bounded drift, honest audit gap, obvious future `--journal` extension if demand appears.

#### C. `AGENTS.md` budget

**accept — 8-12 line budget plus mechanical check.** The spec should say `AGENTS.md` remains index-shaped and the `## Memory` block must stay within 12 non-blank lines. A cheap shell verification is appropriate. It does not need to become a broad entrypoint linter; a spec-099 verification script or test is enough.

#### D. Drift backstop

**accept — non-mutating pre-commit check.** Choose this now. The mutating hook is too surprising, and pure skew-window documentation is too weak. Synthesis should require integration with existing `.githooks/pre-commit`:

- compute projected `MEMORY.md` into a temp file;
- compare with the staged/current index;
- block with a corrective message telling the user to run `bash .claude/tools/memory-maintain.sh finalize` and re-stage;
- do not rewrite or auto-stage anything.

If a consumer has not activated `.githooks`, the Codex convention and finalizer still carry v1. The pre-commit check is the shared enforcement backstop when hooksPath is enabled.

#### E. Scenario 1 trigger list

**accept — use Claude's trigger list verbatim with light wording.** Codex should read `.claude/memory/MEMORY.md` when work touches rules, hooks, skills, sync-harness, runtime capabilities, memory tools, project architecture, or any spec involving a first-party capacity. This replaces the vague "memory-relevant" phrasing.

### Final convergence position

I agree with Claude that another critique round is unlikely to produce more value. The debate has converged on these spec-level resolutions:

- Codex status stays `convention`; capability-matrix notes become more explicit.
- Namespace is resolved by a numeric audit before plan; keep/move/alias all remain options, symlink is not free.
- `AGENTS.md` stays index-shaped, capped at 12 non-blank lines for `## Memory`, with detailed protocol in `memory-placement.md`.
- Codex post-edit maintenance uses a mandatory minimum finalizer: validate + project, no journal append in v1.
- Codex journaling gap is explicit and accepted; Claude `confirm` gap is documented alongside it.
- Drift backstop is a non-mutating `.githooks/pre-commit` projection check.
- Runtime-agnostic frontmatter validation becomes a real shell-invocable primitive shared by Codex and Claude's hook.

**Recommendation:** synthesize now. The synthesis should update `spec.md` with these decisions and mark remaining open questions as resolved or narrowed enough for `/sdd plan`.

---

## Round 3 — reviewing agent (critique)

**THIS CRITIQUE INVALIDATES THE SYNTHESIS BELOW** (resolution: converged, dated this same session). New evidence surfaced after Round 3 counter and synthesis were written: Codex CLI ships a native lifecycle-hook system covering 10 events. The "convention by mechanism" premise that drove the converged decisions (mandatory finalizer, AGENTS.md protocol depth, journal asymmetry, advisory-surface non-goal) is empirically wrong. Recommendation at end: re-synthesize after Codex Round 4 counter.

#### Foundational premise broken: Codex CLI has lifecycle hooks

The user shared evidence (`/hooks` command output, 2026-05-27) and docs verification (<https://developers.openai.com/codex/hooks>) confirms: Codex CLI exposes `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`, `SessionStart`, `SubagentStart`, `SubagentStop`, `UserPromptSubmit`, `Stop` — 10 events, configurable via `.codex/config.toml [hooks]` or `.codex/hooks.json` at project or user scope.

`.claude/rules/runtime-capabilities.md` matrix row `lifecycle hooks | native | unsupported` was **factually stale** (corrected this session per the user's authorization; see `.claude/memory/codex-cli-hooks.md` for the canonical Codex hook surface and `[[verify-runtime-capabilities]]` user-level feedback for the discipline lesson). My Round 1/2 critiques and Codex's Round 1/2/3 positions both built on the unsupported claim. The convergence in synthesis is real for what was discussed, but the spec contract it proposed has now lost its foundation.

The compatibility surface for porting Claude's memory hooks is much closer to 1:1 than the asymmetric-mechanism debate assumed:

- **Stdin payload shape:** nearly identical across runtimes (`session_id`, `transcript_path`, `cwd`, `hook_event_name`, `tool_name`, `tool_use_id`, `tool_input`, `tool_response`, `source` on SessionStart, `agent_id` / `agent_type` on subagent events). A well-written shell script consumes either payload with no branching.
- **Matcher syntax:** regex on `tool_name`, identical to Claude.
- **Exit-code semantics:** identical (`0` = success / advisory context; `2` = block with stderr reason).
- **Tool-name surface:** **the one real asymmetry.** Claude's `Edit` / `Write` / `MultiEdit` arrive as Codex's `apply_patch` / `Bash`; the hook script discovers affected paths by parsing `tool_input` patch text or via `git status --porcelain` rather than reading `tool_input.file_path` directly.

#### Namespace decision (OQ-1): user ratified Scenario B — LOCK as `.agent0/memory/`

Independent of the hooks finding: user ratified Scenario B in conversation this session. OQ-1 becomes a **plan-phase enumeration task** (list the actual files / anchors to touch in the move), not a spec-phase open question. The synthesis line "convert OQ-1 to pre-plan numeric audit" is correct in form but the conclusion is now pre-committed: **the namespace is `.agent0/memory/`**. The audit remains as work-shape for plan, not as a question whose answer might be "keep". The symlink option drops out of the option set entirely (no third path is needed when the move is the chosen destination).

#### Real new direction: port the 4 Claude memory hooks to Codex

The converged synthesis proposed a **mandatory finalizer + pre-commit backstop + AGENTS.md convention** as the v1 Codex mechanism. With Codex hooks now in scope, the better v1 is **port the 4 Claude-side memory hooks to Codex** so the symmetry promised by "one corpus, two mechanisms" actually becomes "one corpus, two *mechanically identical* automations":

| Claude hook | Codex equivalent | Notes |
| --- | --- | --- |
| `memory-events-journal.sh` (`PostToolUse(Edit\|Write\|MultiEdit)` on memory paths) | `PostToolUse(apply_patch\|Bash)` matcher + in-script path-filter on `.agent0/memory/*.md` | Script discovers affected paths by parsing `tool_input` patch text or `git status --porcelain` post-edit |
| `memory-index-gate.sh` (`PreToolUse(Edit\|Write\|MultiEdit)` blocks raw `MEMORY.md` edits) | `PreToolUse(apply_patch)` + in-script check on patch's target paths | Override-marker grammar (`# OVERRIDE: memory-index-edit: <reason>`) ports unchanged |
| `memory-frontmatter-validate.sh` (`PostToolUse` advisory) | `PostToolUse(apply_patch)` + in-script path-filter | Advisory text identical (`memory-frontmatter-advisory:`); already migrating to a shared shell-invocable primitive per the converged synthesis, so the Codex hook becomes a second thin caller of the same primitive |
| `memory-decay-readout.sh` (`SessionStart`) | `SessionStart` | Identical: same framed `=== MEMORY DECAY ===` block; same `(no stale entries)` empty case |

The **mandatory finalizer downgrades to opt-out fallback** for users running with `[features].hooks = false`, or users on Codex versions predating the hook surface. The **pre-commit projection check stays as universal backstop** (git is still the runtime-neutral lifecycle event for users who haven't activated hooks in either runtime).

#### New open questions Round 3 raises

- **OQ-6 (hook-script home):** the 4 hook scripts live at `.claude/hooks/*.sh`. If both runtimes invoke them, the namespace lie reappears — Codex hooks fired from `.claude/hooks/` echoes the original "memory under `.claude/`" problem the namespace move was supposed to fix. Three options: (a) move shared hooks to `.agent0/hooks/`, blast-radius bigger than the memory-namespace move alone; (b) keep `.claude/hooks/` and document the directory as legacy-named (the symlink trade-off the synthesis already rejected for memory — same logic should reject for hooks); (c) ship two copies, rejected for the same DRY reason `.agent0/memory/` is preferred over a Codex-mirrored bucket. Lean: (a), pre-plan-audited the same way as the memory move.
- **OQ-7 (path discovery in Codex `apply_patch` hook):** the script needs to know which memory entries the patch affected. Three options: (i) parse the `tool_input` patch headers in-script (deterministic, no shell-out, but needs a patch parser); (ii) shell out to `git status --porcelain` after `PostToolUse` and filter for `.agent0/memory/*.md` (simple, but races if the user has unrelated WIP); (iii) shell out to `git diff --name-only HEAD --` (deterministic but misses unstaged). Lean: (i) for both Pre and Post — patch text is in payload, no shell-out needed.
- **OQ-8 (Codex hook config layout):** activation via `.codex/config.toml [hooks]` or via `.codex/hooks.json`? Spec 098 already established `.codex/config.toml.example` as the opt-in template for MCP recipes — extend that file with a `[hooks]` block, or ship a separate `.codex/hooks.json.example`? Lean: extend `.codex/config.toml.example` (one template, one activation step, consistent with 098 precedent).
- **OQ-9 (double-fire risk):** when both runtimes are invoked sequentially or in parallel on the same machine, will the journal record the same edit twice? Likely no in practice (each runtime has its own session_id and tool_use_id; events are genuinely distinct), but the user-facing audit trail may show two entries for what looks like one logical edit. Worth one paragraph in `memory-placement.md` § Multi-runtime usage rather than a new mechanism.
- **OQ-10 (`PostToolUseFailure` divergence):** Claude has `PostToolUseFailure` (distinct event for non-zero-exit tool calls); Codex does not appear to. The `memory-frontmatter-validate.sh` port doesn't need it (validation runs on successful edits), but future Codex hook ports may hit this asymmetry. Document as a known surface-coverage gap; do not block spec 099 on it.

#### Synthesis revisions required

The converged synthesis above (resolution: converged) should be invalidated and re-written. Key deltas the new synthesis must reflect:

- **Namespace:** lock as `.agent0/memory/` (user-ratified). OQ-1 becomes plan-phase enumeration task only; symlink option drops out.
- **Capability matrix `memory` cell:** change from `convention` → `native-opt-in` (parity with Claude's `native`; Codex requires explicit hook activation via `.codex/config.toml.example`).
- **Capability matrix `lifecycle hooks` cell:** already corrected this session (`unsupported` → `native`).
- **Scenarios for the 4 hook ports** replace the converged "mandatory finalizer" scenarios.
- **Mandatory finalizer drops to opt-out fallback** (still ships; no longer the v1 primary mechanism for Codex).
- **`AGENTS.md` Memory block stays small** but points at `.codex/config.toml.example` hook activation instead of describing a manual finalizer protocol.
- **Drop non-goal "No Codex per-edit advisory surface"** — Codex hooks restore advisory parity.
- **Drop non-goal "No journal append for Codex edits in v1 (deliberate)"** — Codex `PostToolUse` hook journals naturally; the deliberate-gap framing was a workaround for the wrong premise.
- **Pre-commit projection check stays as universal backstop.**
- **Runtime-agnostic frontmatter validation primitive stays** — now invoked by Claude hook + Codex hook + (optional) Codex finalizer fallback.
- **Add new OQs 6-10** as plan-phase work, or close them inline in the new synthesis if Round 4 produces obvious answers.

#### Recommendation

Codex CLI Round 4 counter responds to this critique (append `## Round 4 — initiating agent (counter)` manually per the file's stop-criteria note), then re-synthesize. Do not act on the existing synthesis — its acceptance scenarios for "Codex deliberately unjournaled in v1" and "mandatory finalizer as primary mechanism" are now wrong-direction. The spec is no closer to plan-ready than it was at end of Round 1, but the new direction is clearer: structural symmetry via hook port rather than asymmetric convention.

---

## Round 4 — initiating agent (counter)

### Classification per Round 3 critique

#### A. Foundational premise: Codex lifecycle hooks exist

**accept — the previous convergence is invalid.** I verified the local memory update, the runtime-capabilities matrix edit, and the official Codex hooks docs. Codex hooks are real, support repo-local config, and cover the events this spec needs (`PreToolUse`, `PostToolUse`, `SessionStart`). The old synthesis below was correct only under a stale matrix assumption; it should be treated as superseded by this round.

**accept — `memory` should move from Codex `convention` to `native-opt-in`, not stay `convention`.** The runtime primitive exists, but Agent0 still has to ship project hook config and the user has to trust/activate repo-local hooks. That matches `native-opt-in`: not automatic on clone, but no longer merely an entrypoint convention.

**accept with precision — lifecycle hooks are `native`, memory is `native-opt-in`.** The lifecycle primitive itself is native in Codex CLI. This memory capacity is native-opt-in because the hook registrations live in project config/template and trust flow, not in Codex core defaults.

#### B. Namespace

**accept — lock project memory namespace as `.agent0/memory/`.** If the user has ratified Scenario B, OQ-1 is no longer a decision among keep/move/alias. The plan still needs an enumeration/audit, but it is now a migration inventory, not a design fork. The symlink option drops out.

**accept — audit remains required.** The move to `.agent0/memory/` still needs a numeric touched-file/anchor inventory so the plan can sequence it safely and avoid rewriting historical references inside old specs unless the reference is live contract text.

#### C. Primary mechanism: port memory hooks to Codex

**accept — the v1 primary path should be hook parity, not mandatory manual finalizer.** The finalizer remains useful only as a fallback for users who disable hooks, have untrusted project hooks, run older Codex versions, or deliberately edit outside the supported hook surface.

**accept — port the four memory behaviors.** The spec should replace the manual-primary scenarios with hook-port scenarios:

- `SessionStart`: Codex runs the same decay readout as Claude, sourced from `.agent0/memory/`.
- `PreToolUse`: Codex blocks raw `MEMORY.md` patch edits with the same override grammar.
- `PostToolUse`: Codex validates frontmatter and regenerates the index after supported memory edits.
- `PostToolUse`: Codex journals supported memory edits with Codex runtime/session/tool attribution.

**accept with constraint — `apply_patch` is the primary Codex edit surface for v1; Bash is fallback/backstop territory.** The docs show `PreToolUse`/`PostToolUse` can see `Bash` and `apply_patch`, but Bash path discovery is less reliable and may miss richer shell pathways. v1 should guarantee hook behavior for `apply_patch` memory edits and document that arbitrary shell writes are bounded by the finalizer fallback and non-mutating pre-commit projection check. If plan can safely support simple Bash path discovery without false positives, good; it should not be a hard acceptance requirement for parity.

#### D. New OQs 6-10

**OQ-6 hook-script home — accept `.agent0/hooks/` for shared memory hook implementations.** If both runtimes invoke the scripts, keeping memory-hook implementations under `.claude/hooks/` repeats the namespace problem. Scope the move narrowly: memory-specific shared hook scripts move to `.agent0/hooks/`; runtime-specific config files (`.claude/settings.json`, `.codex/config.toml.example`) invoke those scripts. Do not move every Claude hook in this spec.

**OQ-7 Codex path discovery — accept patch-header parsing for `apply_patch`.** Parse `tool_input.command` / patch text for `*** Add File:`, `*** Update File:`, `*** Delete File:`, and `*** Move to:` headers. Do not use `git status` as the primary affected-path detector because unrelated WIP would create false positives. Bash support, if any, must be explicitly lower confidence.

**OQ-8 Codex hook config layout — accept `.codex/config.toml.example`.** Spec 098 already established this file as the Codex opt-in template. Add `[hooks]` blocks there rather than introducing a second `.codex/hooks.json.example` activation surface.

**OQ-9 double-fire risk — accept documentation only.** The likely duplicate-looking events are separate runtime/tool invocations, not the same event firing twice. Document that `.agent0/.memory-events.jsonl` may contain adjacent Claude/Codex events for one logical work session, keyed by runtime/session/tool_use_id.

**OQ-10 PostToolUseFailure divergence — accept as known gap, not blocker.** Memory validation/projection runs after successful edits. Lack of Codex `PostToolUseFailure` does not block this spec; document it in runtime-capability/memory maintenance notes for future ports.

#### E. Old synthesis deltas

**accept — existing synthesis must be replaced, not patched.** The old synthesis explicitly proposes wrong-direction changes: Codex deliberately unjournaled, mandatory finalizer as primary, Codex status `convention`, and no Codex per-edit advisory surface. All of those should be removed from the final synthesis.

**accept — pre-commit projection check still stays.** Even with Codex hooks, the git hook remains valuable for disabled/untrusted hooks and shell-side edits outside the hook path. Keep it as universal backstop.

**accept — runtime-agnostic validation primitive still stays.** The shared primitive is now called by Claude hook, Codex hook, and optional finalizer fallback.

### Proposed revised synthesis direction

- Mark prior synthesis superseded by new evidence from Codex hooks.
- Set canonical project-memory path to `.agent0/memory/`; plan enumerates the migration.
- Move shared memory hook implementations to `.agent0/hooks/` or equivalent neutral memory-specific hook home; keep runtime-specific config in `.claude/settings.json` and `.codex/config.toml.example`.
- Change capability matrix memory row to Codex `native-opt-in`; lifecycle hooks stay Codex `native`.
- Replace manual-primary acceptance scenarios with Codex hook parity scenarios for index gate, event journal, frontmatter validation, projection, and decay readout.
- Keep `memory-maintain.sh finalize` as fallback, not primary.
- Keep non-mutating `.githooks/pre-commit` projection check as drift backstop.
- Require `apply_patch` path parsing as the reliable v1 Codex path detector; treat arbitrary Bash writes as lower-confidence/out-of-scope for strict parity unless plan proves safe handling.
- Drop non-goals that claimed no Codex per-edit advisory or no Codex journal append in v1.

### Convergence state

Converged on the new direction, with one important precision: "Codex hook parity" should mean parity for supported Codex edit surfaces, especially `apply_patch`, not an overclaim that every arbitrary Bash write can be attributed perfectly. The spec can now be re-synthesized around hook parity plus fallback/backstop mechanics.

---

## Synthesis (original — SUPERSEDED by `## Synthesis (revised after Round 4)` below)

> **⚠ SUPERSEDED.** This synthesis was written based on the (then-undiscovered-stale) premise that Codex CLI lacks lifecycle hooks. Round 3 reviewing critique invalidated the premise; Round 4 initiating counter accepted the invalidation; the canonical decisions now live in `## Synthesis (revised after Round 4)` below. This section is preserved as audit trail of what was concluded under the stale premise — do NOT apply these changes to `spec.md`. The revised synthesis reflects the actual converged direction (Codex hook parity, not mandatory finalizer).

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged (later invalidated — see Round 3 critique + Round 4 counter)

The debate ran Round 1 critique → Round 2 counter → Round 2 critique → Round 3 counter, with the human electing to synthesize instead of Round 3 critique. Both runtimes agree the spec is one synthesis-edit pass away from `/sdd plan`-ready. All five original Open Questions resolve to either a closed answer or a pre-plan task with a concrete deliverable; one new pre-plan question (drift backstop) closes the same way.

**Proposed spec changes:**

### `## Intent` — minor sharpening

- Add a final sentence naming the load-bearing v1 mechanisms the debate converged on: "v1 introduces a mandatory Codex post-edit finalizer (`memory-maintain.sh finalize`, scoped to validate + project, no journal append), a non-mutating `.githooks/pre-commit` projection check as the shared drift backstop, and a runtime-agnostic frontmatter validation primitive that both Codex and the existing Claude Code hook invoke."

### `## Acceptance criteria` — substantive rewrites + 4 new criteria

- **Scenario 1 (Codex discovers project memory)** — replace the vague trigger "non-trivial or may depend on prior project facts" with an operational trigger list: "When work touches `.claude/rules/`, `.claude/hooks/`, `.claude/skills/`, `.claude/tools/sync-harness.sh`, `.claude/rules/runtime-capabilities.md`, `.claude/memory/` tooling, project architecture, or any spec involving a first-party capacity." Also clarify that Codex reads `MEMORY.md` itself on each trigger (no in-context primer; "lazy-read" is dropped in favor of "trigger-driven read").
- **Scenario 3 (Codex keeps the derived index converged)** — change "follows the documented post-edit convention" → "runs `bash .claude/tools/memory-maintain.sh finalize <entry-path>`"; add a clause that drift surviving an un-finalized Codex session is bounded by the new pre-commit check (cross-link to the new criterion below).
- **Scenario 4 (frontmatter validation path)** — change "runs the documented runtime-agnostic frontmatter validation command for that entry" → "runs `bash .claude/tools/memory-maintain.sh validate <entry>` (or its equivalent shell-invocable primitive); the existing Claude Code hook `.claude/hooks/memory-frontmatter-validate.sh` becomes a thin caller of the same primitive."
- **Scenario 7 (journal posture is explicit)** — rewrite to enumerate the two pre-existing gaps + the new Codex gap honestly: "Then `.claude/rules/memory-placement.md` states that (a) Claude Code `Edit/Write/MultiEdit` events on memory entries append `.claude/.memory-events.jsonl`; (b) Claude `memory-query.sh confirm` mutations bypass the hook and remain unjournaled (pre-existing gap); (c) Codex edits are deliberately unjournaled in v1 because the mandatory finalizer's scope is validate + project only; (d) `git log <entry>` preserves chronology and content diffs but not runtime, sub-agent, session, or `tool_use_id` attribution; (e) any future Codex-attributed journaling would require extending the finalizer with a `--journal` flag, deferred until rule-of-three demand."
- **Scenario 8 (capability matrix remains truthful)** — drop the "remains unchanged" framing; replace with a concrete delta requirement: "Then the `memory` row keeps Codex status `convention` (shell-invocable tools are not a runtime lifecycle primitive — confirms OQ-4), and the Notes column gains: 'Codex follows convention via `memory-maintain.sh finalize`; Claude hooks remain authoritative for in-edit advisories; drift backstop via `.githooks/pre-commit` projection check.'"
- **New scenario (mandatory Codex finalizer exists)** — add: "**Given** a fresh Codex CLI session in Agent0; **When** Codex performs any memory edit; **Then** the Codex convention in `AGENTS.md` instructs it to run `bash .claude/tools/memory-maintain.sh finalize <entry-path>` before ending the session, and the command is shell-invocable, idempotent, scope-limited to frontmatter validation + index projection, and exit-0 on success."
- **New scenario (`AGENTS.md` Memory block budget enforced)** — add: "**Given** a contributor edits `AGENTS.md`; **When** the `## Memory` block exceeds 12 non-blank lines; **Then** a verification script (e.g., `.claude/tests/agents-memory-block-budget.sh`) fails with a corrective message pointing at `.claude/rules/memory-placement.md` § `Multi-runtime usage` as the canonical detailed protocol."
- **New scenario (non-mutating pre-commit drift backstop)** — add: "**Given** `.githooks/pre-commit` is active (`git config core.hooksPath .githooks`) and a contributor stages memory-entry edits without re-running projection; **When** they invoke `git commit`; **Then** the hook computes the projected `MEMORY.md` into a temp file, diffs vs the staged index, and on drift blocks the commit with a corrective message instructing the user to run `bash .claude/tools/memory-maintain.sh finalize` and re-stage. The hook never rewrites or auto-stages files. When `.githooks` is not activated, drift surfaces at the next Claude Code SessionStart instead (documented skew window)."
- **New scenario (shared frontmatter validation primitive)** — add: "**Given** a runtime-agnostic shell-invocable frontmatter validation primitive exists at `.claude/tools/memory-maintain.sh validate` (or equivalent); **When** the existing Claude Code hook `.claude/hooks/memory-frontmatter-validate.sh` fires on `PostToolUse(Edit|Write|MultiEdit)`; **Then** the hook invokes the shared primitive instead of carrying its own validation logic, and both runtimes emit identical `memory-frontmatter-advisory:` output for the same malformed entry."
- **Static-fact criterion `AGENTS.md` discovery+protocol** — keep, but tighten: "`AGENTS.md` § `## Memory` covers (in ≤12 non-blank lines): trigger list, `MEMORY.md` lazy-read direction, the single command `memory-maintain.sh finalize`, the optional `memory-query.sh decay --readout` invocation cadence, the 'do not raw-edit `MEMORY.md`' rule, and a pointer to `.claude/rules/memory-placement.md` § `Multi-runtime usage` for full protocol."
- **Static-fact criterion `memory-placement.md` multi-runtime section** — extend: "the section also documents (i) the operational trigger list verbatim, (ii) the journaling gap enumeration from scenario 7, (iii) the drift-backstop semantics and the `.githooks/pre-commit` activation requirement, (iv) the AGENTS.md 12-line budget convention."

### `## Non-goals` — add 2, sharpen 1

- **Add: No Codex per-edit advisory surface.** "Codex sees `memory-frontmatter-advisory:`, `memory-cap-advisory:`, and `memory-config-advisory:` output only when it runs the underlying shell command and reads its stderr. Per-edit advisory surfacing on writes remains Claude-only by mechanism (Claude `PostToolUse` hooks). No Codex lifecycle primitive will be invented to close this gap in v1."
- **Add: No journal append for Codex edits in v1 (deliberate).** "The mandatory finalizer's scope is validate + project. A `--journal` flag extension is rule-of-three deferred. Reasoning: a partial / forgotten / silently-failing journal append is worse than a documented no-journal contract."
- **Sharpen existing "No hard prevention of raw Codex edits to `MEMORY.md`":** add a sentence — "The pre-commit projection check is the v1 backstop when `.githooks/pre-commit` is activated; when it is not, drift surfaces at the next Claude Code SessionStart hook firing."

### `## Open questions` — close all five; one pre-plan task remains

- **OQ-1 (namespace) → convert to pre-plan task, not a question.** "Before `/sdd plan`, produce a numeric convergence-cost audit listing (a) file count touched by a hypothetical move from `.claude/memory/` → `.agent0/memory/`, (b) unique grep-anchor count across rules, hooks, tools, specs, entrypoints, `.gitignore`, `memory.config.json`. Decision rule: if file-count < ~15 AND anchor-count < ~30, move; otherwise keep `.claude/memory/` canonical and document the path as legacy naming for a provider-neutral bucket. The `.agent0/memory/` symlink remains in the option set as a third path but carries non-zero costs (hook-matcher bypass surface, git-symlink platform friction on Windows/Codespaces, two-edit-paths-one-corpus discipline dilution); pick it only if the audit shows both move-and-keep have higher cost."
- **OQ-2 (Codex journaling) → CLOSED: no.** "Codex edits are deliberately unjournaled in v1. The mandatory finalizer's scope excludes journal append. Future extension via `--journal` flag is rule-of-three deferred."
- **OQ-3 (Codex command surface) → CLOSED: option (b), scope-limited wrapper.** "Implementation adds one mandatory wrapper `memory-maintain.sh finalize` (validate + project) plus the existing standalone `memory-query.sh` for read-side operations (search, list, confirm, decay readout). No journal subcommand in v1."
- **OQ-4 (capability matrix cell) → CLOSED: stays `convention`.** "Shell-invocable tools are not a runtime lifecycle primitive. The Notes column captures the shell-convention details per the scenario-8 rewrite above."
- **OQ-5 (decay readout cadence) → CLOSED: trigger-aligned.** "Codex runs `bash .claude/tools/memory-query.sh decay --readout` once at the start of any session where the memory-protocol trigger list fires (same triggers as scenario 1). Trivial Q&A sessions skip the readout. Claude Code keeps its always-fire SessionStart hook (empty case is cheap)."

### `## Context / references` — add 2 anchors

- Add `.githooks/pre-commit` + `.claude/rules/secrets-scan.md` — precedent for adding a second non-mutating check to the existing gitleaks hook, including the `git config core.hooksPath .githooks` activation pattern.
- Add `.agent0/HANDOFF.md` § *Size discipline* — precedent for budget-discipline-with-mechanical-check (and the cautionary tale where the cap is documented but unenforced and routinely violated, motivating the scenario-7-new mechanical check for AGENTS.md).

**Unresolved disagreements:** n/a — `Resolution: converged` (later invalidated).

---

## Synthesis (revised after Round 4)

_Replaces the superseded synthesis above. Both runtimes (Claude Code as reviewing agent, Codex CLI as initiating agent) converged on this direction after the Codex-hooks finding inverted the v1 mechanism choice from asymmetric-convention to structural-symmetry-via-hook-port._

**Resolution:** converged

The decisive evidence: Codex CLI ships a 10-event lifecycle hook system (`PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, `SubagentStart`, `SubagentStop`, `UserPromptSubmit`, `PreCompact`, `PostCompact`, `PermissionRequest`), configurable via `.codex/config.toml [hooks]` or `.codex/hooks.json` at project or user scope. Payload shape is nearly identical to Claude Code's; matcher syntax (regex on `tool_name`) and exit-code semantics (0/2) are identical. The only real asymmetry is the tool-name catalog — Codex first-party edits arrive as `apply_patch` / `Bash`, not `Edit` / `Write` / `MultiEdit`. The v1 spec now ports the 4 Claude memory hooks to Codex via repo-local hook config, downgrades the previously mandatory finalizer to a fallback, and keeps the universal `.githooks/pre-commit` projection check as the cross-runtime backstop.

**Proposed spec changes:**

### `## Intent` — substantial revision

- Replace the entire load-bearing-mechanisms sentence from the superseded synthesis with: "v1 ports the four Claude-side memory hooks to Codex CLI via repo-local hook configuration (extending the existing `.codex/config.toml.example` opt-in template from spec 098), so both runtimes intercept memory edits and SessionStart through their native lifecycle primitives. The mandatory finalizer of the superseded synthesis becomes an opt-out fallback (`memory-maintain.sh finalize`) for users running with `[features] hooks = false`, untrusted project hooks, or pre-hook-surface Codex versions. A non-mutating `.githooks/pre-commit` projection check stays as the universal drift backstop. The canonical memory path moves from `.claude/memory/` to `.agent0/memory/` per the namespace ratification."

### `## Acceptance criteria` — replace finalizer-primary scenarios with hook-parity-primary scenarios

Scenarios to **DROP** (carried over from superseded synthesis):

- "Mandatory Codex finalizer exists" — replaced by hook-parity scenarios below; the finalizer scenario survives only as the fallback variant.
- "AGENTS.md memory block describes finalizer as required workflow" — replaced by a slimmer block that points at hook activation instead.
- Scenario 7's "Codex deliberately unjournaled in v1" framing — replaced by symmetric-journaling framing.
- Scenario 8's "memory cell stays `convention`" — replaced by `native-opt-in`.

Scenarios to **ADD**:

- **Scenario (Codex SessionStart decay readout):** **Given** a fresh Codex CLI session in Agent0 with hooks activated via `.codex/config.toml`; **When** the session starts and `.agent0/memory/` contains stale entries; **Then** Codex emits the same `=== MEMORY DECAY ===` framed block Claude Code emits, including the `(no stale entries)` empty case — sourced by invoking the existing shared `memory-query.sh decay --readout` command from a Codex `SessionStart` hook.
- **Scenario (Codex `PreToolUse(apply_patch)` raw-index gate):** **Given** Codex with hooks activated; **When** Codex attempts an `apply_patch` whose parsed `*** Update File:` / `*** Add File:` target is `.agent0/memory/MEMORY.md`; **Then** the Codex `PreToolUse` hook blocks with exit-2 + the same corrective template + the same `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` grammar Claude Code's gate uses.
- **Scenario (Codex `PostToolUse(apply_patch)` frontmatter validate + project + journal):** **Given** Codex with hooks activated; **When** Codex successfully `apply_patch` edits an entry under `.agent0/memory/<topic>.md`; **Then** the Codex `PostToolUse` hook (a) validates frontmatter via the shared `memory-maintain.sh validate` primitive, emitting `memory-frontmatter-advisory:` on violations with identical text to Claude's hook; (b) regenerates `.agent0/memory/MEMORY.md` via `memory-project.sh`; (c) appends a JSONL event to `.agent0/.memory-events.jsonl` with `actor: "Codex CLI"`, the Codex `session_id`, `tool_use_id`, and the resolved entry path parsed from the patch header.
- **Scenario (`apply_patch` path discovery):** **Given** a Codex `PreToolUse`/`PostToolUse` hook script processes the stdin `tool_input` payload; **When** the payload contains an `apply_patch` patch body; **Then** the script extracts affected paths by parsing patch headers (`*** Add File:`, `*** Update File:`, `*** Delete File:`, `*** Move to:`) and filtering for `.agent0/memory/*.md` — no `git status` fallback, no Bash-write attribution required.
- **Scenario (shared hook scripts live under `.agent0/hooks/`):** **Given** the 4 memory-specific hook scripts that both runtimes invoke; **When** a contributor inspects the repo; **Then** the scripts live under `.agent0/hooks/memory-*.sh` (runtime-neutral location matching the namespace move); `.claude/settings.json` references them at `.agent0/hooks/memory-*.sh`; `.codex/config.toml.example` (extended `[hooks]` block) references them at `.agent0/hooks/memory-*.sh`. Other Claude hooks remain under `.claude/hooks/` — the move scope is narrow (memory-specific shared implementations only).
- **Scenario (`.codex/config.toml.example` extension):** **Given** the existing opt-in template shipped by spec 098; **When** a Codex user copies the template to `.codex/config.toml` and starts a session; **Then** a commented `[hooks]` block is present alongside the MCP recipes, with `PreToolUse` / `PostToolUse` / `SessionStart` registrations pointing at the `.agent0/hooks/memory-*.sh` scripts; the user uncomments to activate (same posture as MCP recipes).
- **Scenario (finalizer fallback for hook-disabled sessions):** **Given** a Codex session running with `[features] hooks = false`, or with project hooks untrusted, or on a pre-hook-surface Codex version; **When** the user edits a memory entry; **Then** the documented fallback in `AGENTS.md` § Memory instructs the user to run `bash .agent0/tools/memory-maintain.sh finalize <entry-path>` before session end (or rely on the `.githooks/pre-commit` backstop at commit time). The finalizer is no longer the primary mechanism — it is the documented degraded-mode path.

Scenarios to **KEEP** unchanged from superseded synthesis:

- AGENTS.md memory block budget (≤12 non-blank lines, mechanical check).
- Non-mutating `.githooks/pre-commit` projection check (universal backstop independent of which runtime made the edit).
- Shared runtime-agnostic frontmatter validation primitive (now invoked by Claude hook + Codex hook + finalizer fallback — three callers of one implementation).

### `## Non-goals` — DROP 2 from superseded synthesis, ADD 2 new ones, KEEP 1 sharpening

**DROP** (invalidated by Codex hooks):

- ~~"No Codex per-edit advisory surface."~~ — Codex `PostToolUse` hook restores advisory parity. Claude-only-by-mechanism framing was wrong.
- ~~"No journal append for Codex edits in v1 (deliberate)."~~ — Codex `PostToolUse` hook journals naturally with runtime attribution. The deliberate-gap framing was a workaround for the stale premise.

**ADD** (new asymmetries surfaced by Round 4):

- **No guaranteed hook coverage for arbitrary Bash writes.** "Codex hook parity is guaranteed for the `apply_patch` edit surface. `Bash` writes that touch memory paths fall outside strict hook parity in v1 because path attribution from arbitrary shell commands is unreliable — those edits are caught by the `.githooks/pre-commit` projection check as the universal backstop, not by the `PostToolUse` hook. If a future spec demonstrates safe Bash path discovery without false positives, the matrix can extend."
- **No port of every Claude hook to Codex in this spec.** "The hook port scope is narrow: only the four memory-specific hooks (events-journal, index-gate, frontmatter-validate, decay-readout). Other Claude capacities (delegation gate, runtime introspect, secrets scan, propagation advisory) remain Claude-only by mechanism in v1. A broader audit follow-up may promote them per `.claude/rules/runtime-capabilities.md` § Re-audit pending."

**KEEP** (sharpened):

- "No hard prevention of raw Codex edits to `MEMORY.md`." — sharpen: "The Codex `PreToolUse(apply_patch)` hook covers patch-based raw edits; arbitrary `Bash` writes (e.g. `echo > MEMORY.md`) remain bypassable. The `.githooks/pre-commit` projection check is the v1 backstop when `.githooks/pre-commit` is activated; when it is not, drift surfaces at the next Claude Code or Codex `SessionStart` hook firing."

### `## Open questions` — CLOSE all 10; one pre-plan enumeration task remains

- **OQ-1 (namespace) → CLOSED: `.agent0/memory/`.** User-ratified Scenario B. Plan-phase enumeration task: produce numeric inventory (file count + grep-anchor count) of paths to update for the move, then execute migration. No decision remains — only mechanical migration work.
- **OQ-2 (Codex journaling) → CLOSED: YES.** Codex `PostToolUse` hook appends `.agent0/.memory-events.jsonl` events with runtime attribution. The "deliberately unjournaled" framing is dropped.
- **OQ-3 (Codex command surface) → CLOSED: hook-primary + finalizer-fallback.** Primary mechanism is the 4 hooks via `.codex/config.toml.example`; `memory-maintain.sh finalize` (validate + project) remains as the fallback for hook-disabled sessions. Existing `memory-query.sh` for read-side operations stays unchanged.
- **OQ-4 (capability matrix `memory` cell) → CLOSED: `native-opt-in`.** Lifecycle hooks primitive is native in Codex; the memory capacity is opt-in because activation requires copying `.codex/config.toml.example` and trusting repo-local hooks. Lifecycle hooks row separately corrected to `native` for Codex (already shipped this session — see `git log`).
- **OQ-5 (decay readout cadence) → CLOSED: `SessionStart` hook on Codex.** Parity with Claude's always-fire posture (empty case is cheap). For users without hooks activated, the documented fallback is to invoke `memory-query.sh decay --readout` when the memory protocol triggers fire.
- **OQ-6 (hook-script home) → CLOSED: `.agent0/hooks/`** for the 4 memory-specific shared scripts; runtime-specific config (`.claude/settings.json`, `.codex/config.toml.example`) invokes them. Scope intentionally narrow — other Claude hooks stay under `.claude/hooks/` in v1.
- **OQ-7 (path discovery in Codex `apply_patch` hook) → CLOSED: parse patch headers.** `*** Add File:`, `*** Update File:`, `*** Delete File:`, `*** Move to:` extracted from the patch text in `tool_input`. No `git status` fallback (too racy with unrelated WIP). Bash path discovery explicitly out of scope (see new non-goal).
- **OQ-8 (Codex hook config layout) → CLOSED: extend `.codex/config.toml.example`.** Spec 098 precedent: one opt-in template, one activation step. No separate `.codex/hooks.json.example`.
- **OQ-9 (double-fire risk) → CLOSED: documentation only.** Sequentially-invoked runtimes emit distinct events (different `session_id` and `tool_use_id`); the journal records both, keyed by runtime attribution. Document in `memory-placement.md` § Multi-runtime usage; no new mechanism.
- **OQ-10 (`PostToolUseFailure` divergence) → CLOSED: known gap, not blocker.** Memory validation runs on successful edits only; the divergence does not affect this spec. Document as a surface-coverage gap in `runtime-capabilities-maintenance.md` for future ports.

### `## Context / references` — add 3 anchors

- `developers.openai.com/codex/hooks` — canonical Codex hook surface docs (verified 2026-05-27).
- `.codex/config.toml.example` — opt-in template shipped by spec 098; extended in this spec with a `[hooks]` block.
- `.agent0/hooks/` — new directory housing the 4 memory-specific shared hook implementations (`.gitkeep` ships via sync-harness; scripts ship as content).

### Plan-phase enumeration tasks (work, not decisions)

These survive into `plan.md` / `tasks.md` as mechanical work items, not as questions:

1. **Namespace migration inventory.** Enumerate files / anchors touched by `.claude/memory/` → `.agent0/memory/` move. Sequence the migration to avoid rewriting historical references inside old specs unless the reference is live contract text.
2. **`.codex/config.toml.example` `[hooks]` block authoring.** Draft the TOML registrations for `PreToolUse(apply_patch)`, `PostToolUse(apply_patch)`, `SessionStart`. Verify against `developers.openai.com/codex/config-reference` schema.
3. **`memory-maintain.sh` skeleton.** Implement `validate` (callable by Claude hook + Codex hook + standalone) and `finalize` (validate + project + idempotent re-stage hint). Out of scope: `--journal` flag (rule-of-three deferred).
4. **AGENTS.md `## Memory` block authoring.** Within the 12-non-blank-line budget: trigger list, hook activation pointer (`.codex/config.toml.example`), finalizer fallback command, `memory-query.sh decay --readout` for hook-disabled sessions, "do not raw-edit MEMORY.md" rule, pointer to `memory-placement.md § Multi-runtime usage`.
5. **`memory-placement.md § Multi-runtime usage` authoring.** Document hook activation flow, the Bash-write non-coverage gap, the `PostToolUseFailure` Claude-only event, double-fire framing.
6. **`.githooks/pre-commit` extension.** Add the non-mutating projection-drift check alongside the existing gitleaks call. Activation gate (`git config core.hooksPath .githooks`) per `secrets-scan.md` precedent.
7. **`.claude/tests/agents-memory-block-budget.sh`.** Mechanical check enforcing the 12-line cap.

**Unresolved disagreements:** n/a — `Resolution: converged`. Round 4 reviewing critique (Claude Code) is not required; the convergence on Round 4 counter is complete and the synthesis above is the canonical input to `/sdd plan`.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

User confirmed the revised synthesis (`## Synthesis (revised after Round 4)` above) on 2026-05-27. `spec.md` rewritten in full to align with the converged direction. Diff applied:

- **`spec.md § Intent`** — replaced the entire paragraph. New framing: structural symmetry via hook port to Codex CLI; `.agent0/memory/` corpus + `.agent0/hooks/memory-*.sh` shared implementations + `.agent0/tools/memory-*` tooling; finalizer downgraded to opt-out fallback; `.githooks/pre-commit` as universal backstop; scope explicitly narrow to memory.
- **`spec.md § Acceptance criteria`** — substantial replacement:
  - Modified Scenario 1 (Codex discovers project memory): trigger list expanded to operational triggers; "lazy-read" dropped in favor of "trigger-driven read"; path updated to `.agent0/memory/`.
  - Modified Scenario 2 (both runtimes read same source): paths updated to `.agent0/memory/`.
  - Dropped from prior superseded synthesis: "mandatory Codex finalizer exists" / "Codex deliberately unjournaled" / matrix-stays-`convention` framings.
  - Added 7 new hook-parity scenarios: Codex `PreToolUse(apply_patch)` index gate; Codex `PostToolUse(apply_patch)` validate+project+journal; Codex `SessionStart` decay readout; shared `apply_patch` path discovery (patch-header parsing); shared hook scripts under `.agent0/hooks/`; `.codex/config.toml.example` extension; finalizer fallback for hook-disabled sessions.
  - Added 3 cross-cutting scenarios kept from superseded synthesis (shared frontmatter validation primitive; non-mutating `.githooks/pre-commit` backstop; AGENTS.md 12-line budget mechanical check).
  - Added matrix-delta scenario (Claude `native` + Codex `convention` → `native-opt-in`).
  - Replaced 5 static-fact criteria: AGENTS.md § Memory budget + contents; CLAUDE.md/AGENTS.md same-bucket pointer; `memory-placement.md § Multi-runtime usage` content list; runtime-agnostic tools shell-invocable from project root with new paths; tests/verification coverage list.
- **`spec.md § Non-goals`** — applied 5 deltas:
  - Dropped "No Codex per-edit advisory surface" (Codex hooks restore parity).
  - Dropped "No journal append for Codex edits in v1 (deliberate)" (Codex `PostToolUse` journals naturally).
  - Added "No Codex lifecycle hook parity beyond the four memory hooks" (narrow scope per Round 4 OQ-6).
  - Added "No guaranteed hook coverage for arbitrary Bash writes" (`apply_patch` is v1 surface; Bash falls to `.githooks/pre-commit`).
  - Sharpened "No hard prevention of raw Codex edits to `MEMORY.md`" with Bash-bypass acknowledgment and skew-window framing.
  - Sharpened "No broad `.claude/` namespace migration" with explicit three-part move scope (memory bucket / memory hooks / memory tools).
- **`spec.md § Open questions`** — collapsed all 10 OQs into a brief CLOSED resolution table with a pointer to `debate.md § Synthesis (revised after Round 4)` as the canonical source. Section retained (not deleted) for spec-reader convenience; full justifications live in `debate.md`.
- **`spec.md § Context / references`** — added 5 new anchors (`docs/specs/098-codex-mcp-recipes-parity/`, `.claude/memory/codex-cli-hooks.md`, `developers.openai.com/codex/hooks`, `.codex/config.toml.example`, `.agent0/hooks/`, `.agent0/tools/memory-maintain.sh`, `.githooks/pre-commit` + `secrets-scan.md`, `.agent0/HANDOFF.md § Size discipline`); updated existing entries to note path moves (`memory-*.sh` hooks, `memory-*` tools).
- **Path updates throughout `spec.md`:** `.claude/memory/` → `.agent0/memory/`; memory-specific tools `.claude/tools/memory-*` → `.agent0/tools/memory-*`; memory-specific hooks `.claude/hooks/memory-*.sh` → `.agent0/hooks/memory-*.sh`. Non-memory paths (`.claude/rules/`, `.claude/skills/`, `.claude/settings.json`, non-memory `.claude/tools/*`, non-memory `.claude/hooks/*`) preserved as-is per narrow-scope discipline.
- **`spec.md § Status`** — unchanged (`draft`); debate-converged but plan-phase work not yet started.

**Addendum (2026-05-27, post-user-observation):** user clarified that consumer-project migration is manual, not automatic. Three small `spec.md` edits applied on top of the synthesis:

- **`spec.md § Non-goals`** — split the original "No automatic memory-content propagation" bullet into two: (1) content remains project-local (unchanged), (2) **NEW**: no auto-migration mechanism for consumer projects' `.claude/memory/` → `.agent0/memory/` move; sync-harness ships scaffolding additively only; each consumer operator runs the migration by hand; transitional-state shape (compat shims vs hard cutover) is a plan-phase decision.
- **`spec.md § Acceptance criteria`** — added a new scenario requiring a consumer migration playbook to exist (at `docs/specs/099-memory-multi-runtime/migration-playbook.md` or equivalent) with the ordered manual steps (pull synced files; `git mv` content; update `.claude/settings.json` hook registrations; remove legacy paths; verify).
- **`spec.md § Context / references`** — added `mei-saas` + `codexeng` as the first known downstream consumers (precedent: spec 098 dogfood landed in both); the migration playbook is authored against their specific shapes.

`plan.md` and `tasks.md` remain template stubs; `/sdd plan` is the next phase and will translate the 7 plan-phase enumeration tasks from the revised synthesis + this manual-migration addendum (namespace migration inventory, `.codex/config.toml.example` `[hooks]` authoring, `memory-maintain.sh` skeleton, AGENTS.md `## Memory` block authoring, `memory-placement.md § Multi-runtime usage` authoring, `.githooks/pre-commit` extension, AGENTS.md budget test, **consumer migration playbook authoring**) into a concrete plan + executable tasks.
