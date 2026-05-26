# 093 — runtime-capability-registry — debate

_Created 2026-05-26._

**Initiating agent:** Codex CLI
**Reviewing agent:** Claude Code
**Initiated by:** Codex CLI session 2026-05-26

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — ...` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

### Intent

Agent0 now has two runtime-facing foundations: spec 090 gave Codex its native `AGENTS.md` entrypoint alongside `CLAUDE.md`, and spec 092 moved live handoff state to `.agent0/HANDOFF.md`. The proposed 093 adds the missing control-plane artifact: a canonical runtime-capability registry that tells users and agents which Agent0 capacities are native, manual/convention-only, read-only, planned, or unsupported for Claude Code, Codex CLI, and future runtimes. The registry should make the roadmap transparent before we port MCP, SDD, hooks, or subagents.

### Top 3 acceptance scenarios

1. **Users can inspect one canonical capability matrix** — a single registry covers at least instruction entrypoints, handoff, SDD, debate, hooks, runtime introspect, delegation/subagents, MCP recipes, image generation, memory, harness sync, and customization/sync surfaces for Claude Code and Codex CLI.
2. **Runtime entrypoints point at the registry instead of duplicating roadmap claims** — `CLAUDE.md` and `AGENTS.md` keep bootstrap guidance but defer detailed capability status to the canonical matrix.
3. **Registry ownership does not conflict with handoff ownership** — the path/sync decision explicitly respects spec 092's rule that `.agent0/HANDOFF.md` is per-project state and `.agent0/**` is not sync-by-default.

### Top 3 open questions

1. Should the registry live at `.agent0/capabilities.md`, `.claude/rules/runtime-capabilities.md`, or another path?
2. Should the status vocabulary reuse today's `AGENTS.md` tier names or move to provider-neutral states like `native`, `convention`, `read-only`, `planned`, and `unsupported`?
3. Should the Codex Capability Tiers table stay in `AGENTS.md` as a bootstrap summary, or move almost entirely into the new registry?

### Where the initiating agent wants pushback

- Push hard on the path choice. A neutral `.agent0/` path is attractive, but spec 092 intentionally made `.agent0/**` per-project state unless a future spec opts a file into sync. Mixing handoff state and Agent0 policy in the same directory may be a bad precedent.
- Push on whether a markdown matrix is enough. I prefer markdown v1 to keep this cheap, but drift checks may become brittle if they need to parse support states from a human table.
- Push on whether this is the right next spec before MCP. My view is yes: MCP becomes one row in the matrix, not an isolated special case. If that delays useful MCP parity too much, say so.

---

## Round 1 — reviewing agent (critique)

The proposal is correctly scoped (control-plane map, not runtime parity) and the §Non-goals block is unusually disciplined — "no broker, no daemon, no lock server, no machine API in v1" is exactly the right posture. The acceptance set, however, has six concrete weaknesses that the spec edits should address before tasks land. I take the reviewer's mandate to push hardest where the initiator asked for pushback.

### 1. Path choice — `.agent0/capabilities.md` is wrong on the merits

The initiator's framing acknowledges the tension but treats it as one option among three. It isn't: spec 092 was explicit about the meaning of `.agent0/**`. Quoting verbatim from `docs/specs/092-multi-runtime-handoff/spec.md` §Non-goals: _"`.agent0/HANDOFF.md` and the entire `.agent0/**` tree are per-project state, NOT in `sync-harness.sh`'s manifest in v1. Future neutral-namespace files must opt into sync explicitly via a follow-up spec — sync-by-default is rejected as scope creep."_ And: _"Project-local handoff content is not copied over fork-owned work by `sync-harness.sh`; any sync change must preserve that handoff is per-project state, not Agent0-managed policy."_

A capability registry is Agent0-managed policy by construction — it ships from upstream, forks inherit, drift checks enforce it. Putting Agent0-managed policy at `.agent0/capabilities.md` directly contradicts the meaning 092 just established for that namespace. The 093 spec's OQ4 ("should `sync-harness.sh` gain a single-file exception for it") acknowledges the conflict but proposes resolving it by making `.agent0/` mean *two semantically incompatible things at once*: "per-project state EXCEPT for these N listed files which are upstream-managed". That's exactly the namespace-blurring failure mode 092 was written to prevent.

The cleaner shapes the spec doesn't enumerate:

- **`docs/runtime-capabilities.md`** — `docs/` is already neutral, already git-tracked, already accessible to both runtimes, and unambiguously project-documentation territory. The registry IS documentation that has authority. Cost: needs a sync-harness manifest addition for a new top-level docs path (vs `.claude/rules/*` which is already covered).
- **Root `AGENT0.md`** — sibling to `AGENTS.md` / `CLAUDE.md`, signals "Agent0-the-framework's own contract", visible at root next to the two entrypoint files. Cost: another root-level uppercase file.
- **`.claude/rules/runtime-capabilities.md`** — pragmatic: existing sync glob covers it, existing drift-check tooling lives next door, no manifest edits. Cost: the spec's own OQ2 critiques this exact path as "Claude-namespace baggage that 090 was trying to escape". Real cost, but smaller than it sounds — the rule's *content* is provider-neutral; only the directory is Claude-named. And `.claude/rules/session-handoff.md` itself documents Codex behavior today without anyone arguing it should move.

My recommendation: `.claude/rules/runtime-capabilities.md` for v1. The `.claude/` directory name is a propagation/discovery convention (it's where Agent0 keeps its harness-managed stuff that ships to forks); it is not a Claude-runtime exclusivity claim. The cost of moving it later if the namespace gets renamed is a one-line `mv` plus updating references. The cost of polluting `.agent0/**` semantics is paid forever.

Spec edit needed: OQ1 should narrow to two options (the third "or somewhere else?" leaves the door open to `.agent0/` which the body of the same spec already flagged as risky), and the option list should call out the precedent conflict with 092 explicitly. OQ4 becomes moot if `.agent0/` is dropped.

### 2. Status vocabulary — neither current option survives Scenario 3

Acceptance Scenario 3 demands "provider-neutral and testable, avoiding runtime-specific labels such as 'Claude-only' as the primary state". OQ2 then offers reusing current tiers — which include the literal string `Claude-only-until-follow-up` — as one of two options. The OQ contradicts the scenario it sits next to.

Beyond the naming problem, the current tier set fails to separate **two independent dimensions** that the matrix has to express:

| Dimension | Question | Example |
|---|---|---|
| Native to runtime? | Does the runtime have a primitive that consumes this capacity? | Hooks: native to Claude, not to Codex. |
| Activation cost to user? | Even if native, does the user have to opt in? | MCP recipes: native-but-opt-in (need `.mcp.json` copy). Image gen: native-but-opt-in (needs FAL_KEY). |

Today's tier vocabulary flattens dimension 2 into dimension 1 silently. The provider-neutral set in OQ2 (`native | convention | read-only | planned | unsupported`) handles dimension 1 cleanly but still drops dimension 2. A row like "MCP recipes" reads as `native` for Claude, but in practice it's `native-opt-in` — the registry needs to surface that or Codex users will assume it works on clone.

Recommended v1 cell vocabulary (independent per-runtime cell):

- `native` — runtime has a primitive that consumes this; works on clone.
- `native-opt-in` — runtime has the primitive but user must enable it (env var, config copy, credential).
- `convention` — no primitive, but the entrypoint instructs the agent to perform the capacity manually following a documented rule.
- `read-only` — agent can read the artifacts the capacity produces but cannot invoke or extend it.
- `planned` — explicitly scoped for a future spec; should carry that spec's slug or "untracked" if no spec exists.
- `unsupported` — no path forward declared; future spec may move it to `planned`.

Drop the trailing `-now` everywhere — it added time-ambiguity ("now" relative to what?) and brought no signal vs the absence of `-planned`.

Spec edit needed: Scenario 3 narrows the OQ — name the proposed vocabulary set as the v1 default and let the debate move it only if a concrete reason emerges. The current "reuse vs replace" framing invites a vocabulary-design tangent that should not be a v1 open question.

### 3. The two-tier-vocabulary collision the spec doesn't acknowledge

`.claude/skills/skill/references/portability-tiers.md` already defines a tier vocabulary for skills: `cc-native | agentskills-portable | runtime-agnostic`. That's a *different axis* (portability of skill code) from the registry's runtime-support axis, but the spec never mentions the existing model. Two consequences:

- Forks reading the registry and a SKILL.md frontmatter encounter two competing tier vocabularies, both authoritative-looking. Without explicit reconciliation, this is the canonical conditions-for-drift setup.
- The skill-tier vocabulary already encodes part of the registry information for skills specifically. A skill marked `cc-native` is unambiguously `Claude-only-until-follow-up` in current AGENTS.md terms. The registry could either reference skills' own tier declarations (single source of truth, registry derives) or repeat them (two sources, drift risk).

Spec edit needed: add a §Context reference to `portability-tiers.md` and a §Non-goal or Acceptance scenario clarifying the relationship — either "registry reuses skill-tier vocabulary verbatim for skill rows" or "registry is independent of skill tiers; skills declare both". The current silence guarantees confusion.

### 4. Drift enforcement is asserted but not designed (Scenario 7 + criterion 9)

Scenario 7 says "drift checks protect the new source of truth"; criterion 9 says "every future spec that changes runtime support for a capability must update the registry in the same change". Together they assert enforcement without naming the mechanism. The existing `.claude/tools/check-instruction-drift.sh` does exactly one thing today: byte-compare the managed block between `CLAUDE.md` and `AGENTS.md`. Extending it to enforce registry coverage requires:

- Parsing the managed block to extract capacity names (currently done by shape-of-the-block, not by capacity-name extraction).
- Parsing the registry table to extract capacity names + cells.
- Asserting set equality.

A markdown table parser is not free, and the spec's OQ5 ("data shape") implicitly asks whether the table is reliably parseable. The two questions are coupled and the spec treats them separately. If the answer to OQ5 is "markdown only", the answer to OQ7-enforcement is "best-effort grep heuristics that will break the first time a row wraps onto two lines". If the answer is "tiny structured sidecar", drift checks become trivial.

My take: a 20-line YAML sidecar (`capabilities.yaml` next to the markdown) with the markdown table generated from it by a script *is the right v1 shape*. It costs ~50 LOC of bash + jq/yq, gives every drift check a real schema, lets the markdown stay as the human-readable view, and follows the established pattern in this repo (sync-harness manifest, runtime-state probe, reminders.yaml, routines state — all structured under a human surface).

But — and this is where I want pushback from the initiator — a sidecar requires deciding which file is canonical (YAML edited by humans, markdown generated? or markdown is canonical and YAML is asserted to match by a check?). Each direction has costs. If the answer is markdown-canonical, drop the sidecar; if YAML-canonical, the markdown becomes a generated artifact that PR reviewers can't trivially edit. This trade-off should be resolved in the debate, not deferred.

Spec edit needed: Scenarios 7 and 9 should each name a concrete mechanism (a script path that will exist, an event trigger). "Existing drift checks are extended" is too vague to verify against during tasks.

### 5. AGENTS.md bootstrap — keep less than the initiator suggests

The current AGENTS.md tier table is 13 lines including the header. The initiator's question is "stay as bootstrap summary, or move entirely?". A third path is sharper: **collapse to two lines**.

```
For non-trivial work, consult `<registry-path>` before assuming any `.claude/*` capacity is Codex-native. Default skeptical: assume `convention` or `planned` until the registry's runtime column says otherwise.
```

The current tier table doubles as Codex orientation AND as the source-of-truth for tier definitions. Splitting those roles is the entire point of this spec — let the registry own definitions and let AGENTS.md own the orientation. Any in-AGENTS.md tier rows or vocabulary become guaranteed drift.

Spec edit needed: Scenario 2 should explicitly say "AGENTS.md retains only a pointer + skeptical-default instruction; tier definitions, capacity rows, and vocabulary live exclusively in the registry". The "minimal runtime-specific bootstrap guidance" phrase in the current scenario is too soft — it permits the table to stay.

### 6. Sequencing — registry-before-MCP is correct, but the spec doesn't earn it

The initiator's §pushback request asks whether this should ship before MCP parity. Yes — but for a stronger reason than "MCP becomes one row, not isolated special case". The real reason: the MCP-parity spec will surface design pressure that the registry's abstractions need to absorb (per-runtime activation cost, distinct config files, credential-bearing recipes). Building the registry first means designing the abstractions in advance of the validating case, which is the canonical premature-abstraction failure mode.

The fix: include MCP parity as a **non-implementation worked example** in this spec. Walk one row (the MCP row, with current state, owner files, follow-up target) through the v1 vocabulary in §Context or in a debate synthesis output, BEFORE locking the vocabulary. If the worked example forces a vocabulary change, that's signal the abstractions need it. If the row fits cleanly, that's evidence the registry is well-shaped. The cost is a 20-line worked-example block in this spec; the cost of NOT doing it is shipping a registry whose first real row (the MCP one in spec 094 or whatever) forces a v2 redesign.

Spec edit needed: add a §Worked-example or §Validation section that walks the MCP recipe row through the proposed vocabulary and column shape. If it doesn't fit, the spec changes before shipping.

### 7. Smaller issues (one-liners)

- Criterion 8 ("owner-file references for each row") needs to allow a list, not single owner — `delegation` is gate + validator + audit + rule + tests. Single-file references are a misleading simplification.
- §Non-goals correctly excludes "porting Claude hooks to Codex" but doesn't exclude "documenting which Codex primitives could replace which Claude hooks". That documentation work belongs to follow-up specs, not this registry; the boundary deserves an explicit non-goal.
- Scenario 8 mentions runtime columns `Cursor` and `Aider` as placeholders. The spec should also acknowledge `Hermes Agent` (active in the project's reminder set: r-2026-05-17-why-i-run-hermes) — picking a forward-looking placeholder list signals which futures this registry expects to cover. If Hermes is intentionally out-of-scope, say so.
- The §Intent paragraph says the registry must answer "what is still planned?". Criterion 9 ("every future spec that changes runtime support must update the registry") makes the registry retrospective. The forward-planned use case needs an explicit slot — does a `planned` cell carry a future spec slug, or just "planned"? Without that, the registry is read-only history; with it, the registry is also the roadmap of record.

### Summary — what should change in spec.md before tasks land

1. OQ1 narrows: drop `.agent0/capabilities.md`, name the actual viable options.
2. Scenario 3 + OQ2 collapse: name the v1 vocabulary explicitly; let the debate move it only with a concrete reason. Add a `native-opt-in` cell value.
3. Add a §Context reference to `portability-tiers.md` + a non-goal or scenario clarifying the relationship.
4. Scenarios 7 + 9 name concrete drift-check mechanisms (script path, trigger).
5. Scenario 2 hardens: AGENTS.md keeps a pointer + skeptical default only.
6. Add a worked-example validation against the MCP row before locking vocabulary.
7. Criterion 8 allows owner-file lists; non-goals exclude "documenting Codex equivalents for Claude hooks"; add Hermes (or explicitly exclude it); decide whether `planned` carries a future-spec slug.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

### Classification per critique point

1. **accept — do not put the v1 registry under `.agent0/`.** The critique is right that `.agent0/capabilities.md` would blur the namespace contract spec 092 just established. A capability registry is Agent0-managed policy, while `.agent0/HANDOFF.md` and `.agent0/**` are currently per-project state unless a future spec opts a file into sync. For v1, I accept `.claude/rules/runtime-capabilities.md` as the pragmatic canonical path: it is already in the harness-managed rule surface, sync behavior is known, drift tooling lives nearby, and the content can be provider-neutral despite the directory name. The spec should remove `.agent0/capabilities.md` and make OQ4 moot rather than introduce a single-file exception.

2. **accept — replace the current tier vocabulary with provider-neutral cell states, including activation cost.** Reusing `Claude-only-until-follow-up` contradicts the provider-neutral acceptance scenario. I accept the proposed v1 vocabulary: `native`, `native-opt-in`, `convention`, `read-only`, `planned`, `unsupported`. `native-opt-in` earns its place because MCP and image generation are not "works on clone" even when the runtime has the primitive. `planned` should carry a future spec slug where one exists, or `planned: untracked` when it is only a roadmap intent.

3. **accept — explicitly reconcile skill portability tiers with runtime support states.** The registry must not silently compete with `.claude/skills/skill/references/portability-tiers.md`. Spec should add that reference and state the relationship: skill frontmatter / portability-tiers remain the source of truth for *skill body portability* (`cc-native`, `agentskills-portable`, `runtime-agnostic`); the new registry is the source of truth for *runtime support for Agent0 capabilities*. For skill rows, the registry may cite the skill tier as evidence, but it should not become a second per-skill portability database.

4. **accept the enforcement gap; reject YAML sidecar as v1 default.** The critique is right that "extend drift checks" is too vague and must become a concrete task/check. I do not accept a YAML-generated markdown sidecar in v1 unless a later round proves markdown cannot support the checks we need. Two canonical files for one registry would add the same drift risk we are trying to reduce. Better v1: markdown is canonical, with lightweight checks that verify (a) the registry file exists, (b) `AGENTS.md` and `CLAUDE.md` point to it, (c) the old `AGENTS.md` tier table is gone, (d) the documented vocabulary is present, and (e) required capability row labels exist exactly once. That is enough to protect the load-bearing claims without parsing every cell. If future specs need machine reads, promote a schema then.

5. **accept — collapse `AGENTS.md` bootstrap to pointer + skeptical default.** The current Codex tier table should not survive as a second source of definitions. `AGENTS.md` should keep only the runtime-specific instruction: consult the registry before assuming `.claude/*` capacity is Codex-native; default skeptical unless the Codex column says otherwise. `CLAUDE.md` can similarly point at the registry from the managed block without duplicating status definitions. The spec should harden Scenario 2 to say vocabulary and capacity rows live exclusively in the registry.

6. **accept — add an MCP worked example before locking the abstraction.** Registry-before-MCP is still the right order, but the critique sharpens why: MCP is the immediate pressure test for `native-opt-in`, owner-file lists, credentials, and per-runtime activation shape. The spec should require a non-implementation worked example row for MCP recipes using the proposed vocabulary and owner files. If that example does not fit cleanly, the registry vocabulary changes before plan/tasks.

7. **accept with scoped wording — all smaller issues are material enough for spec edits.** Owner references should be lists, not singular files. Add an explicit non-goal: documenting Codex equivalents/replacements for Claude hooks belongs to follow-up parity specs, not this registry. Add `Hermes Agent` to future-runtime examples, but do not add a runtime column in v1 or assert support. Define `planned` cells as carrying a future spec slug or `untracked` so the registry can act as a roadmap without becoming vague aspiration.

### Tally

- **Accepts:** 6 full accepts + 1 scoped accept.
- **Rejects:** YAML/sidecar as the default v1 canonical shape; keep markdown canonical with targeted drift checks.
- **Defers:** none required before synthesis, unless the reviewing agent wants to challenge the markdown-only enforcement shape in Round 2.

### Proposed synthesis direction

If the reviewing agent agrees, the synthesis should update `spec.md` toward this contract:

- Canonical path: `.claude/rules/runtime-capabilities.md`.
- Registry format: markdown canonical, no structured sidecar in v1.
- Vocabulary: `native`, `native-opt-in`, `convention`, `read-only`, `planned`, `unsupported`.
- Entrypoints: pointers + skeptical/default guidance only; no duplicated tier table.
- Drift checks: concrete lightweight assertions in `check-instruction-drift.sh` or a nearby helper/test, scoped to required rows and pointers.
- MCP: required worked-example row, not implementation.
- Skill portability: explicitly separate axis, cited as context, not replaced.

---

## Round 2 — reviewing agent (critique)

**Convergence reached.** The Round 2 counter resolves every concrete spec-edit request from my Round 1 critique, including the partially-rejected one. The single remaining nit is a sharpening of the proposed enforcement model, not a new disagreement. I recommend the human invoke synthesis next; no Round 3 needed.

### On the markdown-canonical rejection — accepted

The counter's reasoning is the right argument and I withdraw the YAML sidecar proposal for v1. Two specific points in the counter make the rejection sound:

1. **"Two canonical files for one registry would add the same drift risk we are trying to reduce."** This is the killer rebuttal. The spec exists to consolidate authoritative claims into one place; introducing a YAML/markdown pair reintroduces the exact failure mode the spec is built to prevent. Mea culpa for not seeing that in my Round 1 framing — I was thinking about parsing fragility, not about the spec's own teleology.

2. **The five-check enforcement model (a-e) sidesteps the parsing-fragility concern entirely.** My original objection was "drift checks against a human markdown table are fragile because they need to parse cells". The counter's checks don't parse cells — they verify *anchors* (file existence, entrypoint pointers, vocabulary block presence, deletion of the old AGENTS.md tier table, required row labels). Anchor checks are grep-stable; they don't break when rows wrap or columns reorder. That model is genuinely sufficient for v1 protection without a structured sidecar.

For the record on the trade I was worried about: a sidecar would have bought "every cell value belongs to the documented vocabulary" and "every row has a value in every column" as automated checks. The first is achievable on markdown via a vocabulary-regex sweep over the table region. The second is a soft check whose absence is visible in PR review; not worth a second canonical file. Both fall away.

If future specs surface real machine-read pressure (e.g. the MCP parity spec needing programmatic access to "which recipes are `native-opt-in` for which runtime"), the right move is to promote *then*, with a real validating case. The counter's "If future specs need machine reads, promote a schema then" captures that correctly — it's a deferred-until-needed posture, not a permanent rejection.

### One refinement to the enforcement check list

Check (e) as worded — "required capability row labels exist exactly once" — needs one clarifying word in the spec edit. The check should enforce a **minimum** capacity set (the rows enumerated in Scenario 1: instruction entrypoints, handoff, SDD, debate, hooks, runtime introspect, delegation/subagents, MCP recipes, image generation, memory, harness sync, customization/sync surfaces), but **must not** assert "no extra rows" — the whole point of the registry is to grow as new capacities ship. As stated, "exists exactly once" could be read as "no duplicates AND no additions beyond the listed set", which would freeze the registry on day one.

Suggested wording for the spec edit (tasks-flavor, since the check itself lives in the implementation): _"required capability row labels (per Scenario 1's enumeration) each appear at least once; duplicate labels are an error; rows for unlisted capacities are permitted and not asserted by this check."_

This is a one-line clarification, not a re-debate. I flag it here so the synthesis carries it forward into spec.md (Scenarios 7/9 wording or a §Drift enforcement subsection, whichever the synthesizer prefers).

### Tally on convergence

| Critique point | R1 ask | R2 counter | R2 reviewer verdict |
|---|---|---|---|
| 1. Path | drop `.agent0/`, pick `.claude/rules/runtime-capabilities.md` | accept | converged |
| 2. Vocabulary | provider-neutral 6-state set incl. `native-opt-in`, drop `-now` | accept | converged |
| 3. Skill-tier collision | add §Context ref + relationship statement | accept | converged |
| 4. Drift enforcement | name concrete mechanism (YAML sidecar was one proposal) | accept the gap; reject sidecar; propose 5-check anchor model | **converged** — I withdraw the sidecar; anchor model is sufficient. One wording nit on check (e). |
| 5. AGENTS.md bootstrap | collapse to pointer + skeptical default only | accept | converged |
| 6. MCP worked example | non-implementation row before locking vocabulary | accept | converged |
| 7. Smaller issues (owner lists, Codex-equivalents non-goal, Hermes, planned-slug) | seven sub-edits | scoped accept of all seven | converged |

### Recommendation to the human

Invoke synthesis next ("synthesize" / "wrap up"). The synthesis should:

- Carry the seven spec edits in my Round 1 §Summary forward, with the Round 2 counter's classifications applied.
- Add the check (e) clarification above to the drift-enforcement section it produces.
- Mark Round 3 slots empty/N-A so the audit trail shows the debate closed at Round 2 by convergence, not by cap.

Either of us can perform synthesis; whichever the human asks. Both runtimes hold the same final position now.

---

## Round 3 — initiating agent (counter)

_N/A — debate converged at Round 2; see Synthesis._

---

## Round 3 — reviewing agent (critique)

_N/A — debate converged at Round 2; see Synthesis._

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

**Proposed spec changes:**

- **Intent** — sharpen the second paragraph to say this spec creates an Agent0-managed control-plane registry before MCP parity, with `.claude/rules/runtime-capabilities.md` as the v1 canonical path. Explicitly say the registry is provider-neutral in content even though it lives in the existing `.claude/rules/` sync-managed surface.
- **Acceptance criteria / Scenario: users can inspect one canonical capability matrix** — update the status vocabulary in the `When` clause to the converged v1 cell states: `native`, `native-opt-in`, `convention`, `read-only`, `planned`, and `unsupported`. Add that `planned` cells carry a future spec slug where known, otherwise `planned: untracked`.
- **Acceptance criteria / Scenario: runtime entrypoints point at the registry** — harden the `Then` clause: `AGENTS.md` and `CLAUDE.md` keep only bootstrap pointers and skeptical-default guidance; tier definitions, capability rows, and status vocabulary live exclusively in the registry. `AGENTS.md` should no longer keep the current Codex Capability Tiers table as a second source of truth.
- **Acceptance criteria / Scenario: status vocabulary is provider-neutral and testable** — replace the soft "avoiding runtime-specific labels" wording with an explicit vocabulary definition and operational meanings: `native` works on clone, `native-opt-in` requires user activation or credentials, `convention` is manual behavior from instructions, `read-only` means artifacts can be inspected but not invoked, `planned` requires a follow-up marker, and `unsupported` has no declared path.
- **Acceptance criteria / Scenario: MCP parity has an obvious next-step shape** — require a non-implementation worked-example row for MCP recipes inside the registry so the vocabulary is pressure-tested before MCP parity work starts. The row should include current owner files (`.claude/rules/mcp-recipes.md`, `.mcp.json.example`, `.claude/hooks/mcp-recipes-hint.sh`) and mark Claude support as `native-opt-in` rather than plain `native`.
- **Acceptance criteria / Scenario: registry ownership does not conflict with handoff ownership** — resolve the path decision: the v1 registry lives at `.claude/rules/runtime-capabilities.md`. Remove the `.agent0/<file>` exception option; `.agent0/HANDOFF.md` and `.agent0/**` stay per-project state per spec 092, with no sync-harness exception introduced by this spec.
- **Acceptance criteria / Scenario: drift checks protect the new source of truth** — name the concrete lightweight enforcement shape: extend `check-instruction-drift.sh` or a nearby helper/test to verify the registry file exists, both entrypoints point to it, the old `AGENTS.md` tier table is gone, the vocabulary terms exist in the registry, and required capability row labels from the minimum set appear without duplicates. Extra rows are allowed; duplicate required labels are errors.
- **Acceptance criteria / static facts** — update the runtime placeholder criterion to mention `Hermes Agent` alongside `Cursor` and `Aider` as future/unknown examples, while still limiting v1 concrete columns to `Claude Code` and `Codex CLI`.
- **Acceptance criteria / static facts** — change "owner-file references" to "owner-file reference lists" because several capabilities span rules, hooks, tools, tests, and specs.
- **Acceptance criteria / static facts** — add that every future spec changing runtime support must update `.claude/rules/runtime-capabilities.md` in the same change, and if it adds a new capability row the drift check may allow it without requiring a test update unless it becomes part of the minimum required set.
- **Non-goals** — add "Documenting Codex equivalents for Claude hooks/skills/subagents" as out of scope; parity design belongs in follow-up specs.
- **Non-goals** — keep "no machine API in v1" but clarify that markdown is canonical; a structured schema/sidecar is deferred until a future spec has a real machine-read use case.
- **Open questions** — resolve the current five open questions: path = `.claude/rules/runtime-capabilities.md`; vocabulary = six provider-neutral states; entrypoint shape = pointer + skeptical default only; sync behavior = no `.agent0/` exception; data shape = markdown canonical, no sidecar in v1.
- **Context / references** — add `.claude/skills/skill/references/portability-tiers.md` and state its relationship: skill portability tiers remain the source for skill-body portability; the registry covers runtime support for Agent0 capabilities and may cite skill tiers as evidence without replacing them.

**Unresolved disagreements:** (only if cap-reached or abandoned)

None. The debate converged at Round 2. Claude Code withdrew the YAML sidecar proposal after Codex argued that a second canonical file would recreate drift risk; both agents accept markdown canonical v1 with anchor-based drift checks.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

All 14 synthesis bullets applied to `spec.md` on 2026-05-26:

- **§Intent** — added second-paragraph sentence naming `.claude/rules/runtime-capabilities.md` as v1 canonical path; clarified directory name is a propagation convention, registry content is provider-neutral.
- **§Acceptance criteria / Scenario: users can inspect one canonical capability matrix** — replaced `When` clause vocabulary with the six v1 cell states; added `planned: <spec-slug>` / `planned: untracked` semantics to the `Then` clause.
- **§Acceptance criteria / Scenario: runtime entrypoints point at the registry** — hardened `Then` clause: pointer + skeptical-default guidance only, current AGENTS.md tier table removed in the same change.
- **§Acceptance criteria / Scenario: status vocabulary is provider-neutral and testable** — replaced soft wording with explicit definitions of all six states (`native`, `native-opt-in`, `convention`, `read-only`, `planned`, `unsupported`); banned `Claude-only-until-follow-up` style labels.
- **§Acceptance criteria / Scenario: MCP parity has an obvious next-step shape** — replaced `When` clause with v1-ship; required a non-implementation worked-example row using `native-opt-in` for Claude; named the three current owner files; vocabulary-pressure-test clause added.
- **§Acceptance criteria / Scenario: registry ownership does not conflict with handoff ownership** — resolved path to `.claude/rules/runtime-capabilities.md`; dropped the `.agent0/<file>` exception option.
- **§Acceptance criteria / Scenario: drift checks protect the new source of truth** — replaced soft "extend drift checks" with the five concrete anchor-level invariants (a)-(e); added the minimum-set-only enforcement clarification from Round 2 (extra rows allowed; duplicates are errors).
- **§Acceptance criteria / static-fact criteria** — added `Hermes Agent` to runtime placeholder list; changed "owner-file references" to "owner-file reference **list**"; rewrote update rule to name the canonical path and decouple minimum-required-labels growth from new-row addition.
- **§Non-goals** — added "Documenting Codex equivalents for Claude hooks/skills/subagents" non-goal; expanded the machine-API non-goal to explicitly name the rejected YAML/JSON sidecar and cite the debate's reasoning.
- **§Open questions** — all five OQs flipped to `[x] ~~...~~ → **resolved**: ...` inline (matching spec 092's style).
- **§Context / references** — added `.claude/skills/skill/references/portability-tiers.md` (separate axis statement) and `docs/specs/093-runtime-capability-registry/debate.md` (debate provenance).
