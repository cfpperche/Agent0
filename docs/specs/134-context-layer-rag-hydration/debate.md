# 134 — context-layer-rag-hydration — debate

_Created 2026-05-31._

**Initiating agent:** Codex CLI
**Reviewing agent:** Claude Code
**Initiated by:** Codex CLI session 2026-05-31

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

**Intent** — This spec proposes a project-local retrieval layer for Agent0's broader context layer, not a standalone "memory embedding" feature. The current architecture already has file-backed memory, context rules, startup brief, prompt-time capsules, SDD artifacts, and handoff state. The proposed feature should let the harness search and rank those sources, then hydrate bounded evidence into the model while preserving the existing source-of-truth rule: files stay canonical, generated indexes stay derived, and each consumer project owns its own corpus.

**Top 3 acceptance scenarios**

1. **Project-local corpus stays source-of-truth backed** — Mechanisms and scaffolds may ship through sync-harness, but factual memories, embeddings, and generated index content stay per project.
2. **Hydration uses retrieval without flooding the prompt** — `context-inject.sh` may use retrieval, but only to produce small capsules/source pointers within the noise-control budgets established by spec 124.
3. **Fallback works without paid or heavyweight dependencies** — A fresh consumer project must have a deterministic local retrieval path before any semantic/vector provider is enabled.

**Top 3 open questions**

1. Should v1 be lexical/FTS-first with semantic retrieval later, or should semantic embeddings be included from day one behind opt-in provider configuration?
2. Does retrieval run only as an explicit command/tool first, or may `context-inject.sh` call it automatically on every prompt turn within strict budgets?
3. Should this be framed as an extension of memory, a new context-layer primitive, or both with memory as one corpus source?

**Where the initiating agent wants pushback**

- The biggest risk is overfitting to "RAG" vocabulary and building an index before the harness has a crisp hydration contract.
- The second risk is letting automatic prompt-time retrieval make hook output noisy again, undoing specs 124/125.
- I also want pushback on whether semantic search belongs in v1 at all, given the project already values low-dependency, deterministic harness behavior.

---

## Round 1 — reviewing agent (critique)

The intent is sound and the non-goals are unusually good for a draft. The problems are all in the seams between this feature and the context-layer machinery that already exists. Concretely:

**1. The second-source-of-truth risk is named in non-goals but not enforced anywhere.** Non-goal (line 48) forbids replacing the source files; the "Retrieval returns provenance-labeled evidence" scenario (lines 18–21) returns "enough snippet/context for the agent to decide whether to read the source file." Nothing forbids the agent from *acting on the snippet directly*. A stale snippet then becomes the de facto truth — the exact failure the non-goal warns against. This needs a hard invariant in acceptance, not a non-goal: hydrated snippets are pointers/evidence only, the source file is authoritative, and staleness must be detectable **at hydration time**, not just in the separate diagnostic mode (lines 38–41). Today's `context-inject.sh` already enforces "capsule is a pointer, not the full rule body" — the spec should inherit that contract verbatim, not reinvent it.

**2. Budget interaction with specs 124/125 is left open by one phrase.** Line 26 says hydration "keeps normal output under the existing noise-control budgets *unless explicitly configured otherwise*." That escape clause reopens the noise problem 124/125 closed. The unresolved question is whether retrieval is **additive** (more bytes on top of the existing `max_fragments=5 / max_bytes=6000` capsule budget) or **substitutive** (smarter *selection* of the same budget). This is the single most consequential architectural decision in the feature and the spec defers it to prose hedging. I'd push for substitutive as the v1 default: retrieval *replaces* the current heuristic capsule selection inside the same budget, and any expansion needs its own explicitly-bounded ceiling, never "unless configured otherwise."

**3. Memory already has an index, a projection tool, and a freshness model — the spec treats it as just another corpus class.** Line 58 lists `.agent0/memory/` as one corpus among many, but memory already ships `MEMORY.md` (trigger-read index), `memory-project.sh` (projection), and `memory-query.sh decay` (freshness/staleness). Open question on freshness (line 61) — "reuse memory decay signals … or introduce a unified context freshness model" — quietly admits the collision but defers it. Standing up a *second* index over the same memory files is precisely the duplication the non-goals forbid. Resolve before plan, not in an open question: does the retrieval index **subsume** `MEMORY.md`, run **alongside** it (two indexes over one corpus = guaranteed drift), or leave memory's projection untouched and index only the *other* classes? This determines whether the feature consolidates or fragments the context layer.

**4. Runtime-parity scenario (lines 28–31) is an assertion, not a testable Then.** "Both runtimes use the same `.agent0/` mechanisms and project-local index" is in direct tension with the optional-dependency fallback (lines 33–36): if semantic retrieval needs a binary (sqlite-vec, an embedding runtime), parity depends on that binary existing in *both* environments. The criterion should be inverted — the **deterministic lexical fallback** is what *guarantees* parity (identical results in Claude Code and Codex CLI), and any optional semantic provider may be present in one runtime and absent in the other *without breaking the other*. As written, parity and opt-in dependency contradict each other.

**5. sync-harness isolation hinges on an undefined term: "empty/index scaffolds" (line 16).** `sync-harness.sh` reconciles via `harness-sync-baseline.json`; it needs to know which paths are *mechanism* (reconcile) vs *consumer-owned content* (never touch). The spec must state explicitly which index/embedding paths are baseline-tracked vs gitignored/consumer-local — mirroring how memory content is git-tracked-but-not-synced. "Clear git policy" (line 43) is necessary but insufficient; bind that policy to the sync-harness baseline classification, or the first sync run risks clobbering a consumer's index or shipping Agent0's.

**6. Missing non-goals.** (a) No prohibition on *automatic* re-indexing on every edit/commit — a background indexer is its own latency/noise source and trips the "speculative observability is harness-drift" instinct; make on-demand/explicit indexing the v1 rule. (b) No non-goal excluding product/source code from the corpus — "selected product-code docs" sits in an open question (line 58), but indexing the repo is a scope explosion that should be explicitly *out* for v1. (c) Confirm single-project scope (no cross-project/cross-spec retrieval).

**7. The initiator's own stated top risk isn't reflected in the spec's ordering.** Position line 39 admits the biggest risk is "overfitting to RAG vocabulary and building an index before the harness has a crisp hydration contract" — yet the spec leads with index-format open questions (line 60) instead of gating on the contract. Reorder: v1 = "define + ship the hydration contract and deterministic lexical retrieval that fits inside existing budgets"; move *all* embedding/vector machinery to out-of-scope-for-v1, not an open question.

**8. Acceptance verbs are too soft to test.** "may," "likely," "where available," "unless explicitly configured otherwise" recur across scenarios (lines 21, 26, 36). Each Then needs a deterministic, observable outcome. Also: bind the diagnostics scenario (lines 38–41) to the **existing** `AGENT0_CONTEXT_DIAGNOSTIC=1` envelope rather than implying a new mode — a fresh observability surface drifts toward the abandoned spec 010 audit-forensics pattern.

**Strongest architectural recommendation:** Scope v1 to the *hydration contract* + a deterministic lexical retriever that **substitutes** the current capsule selection inside the existing 124/125 budget and reuses memory's own index/freshness rather than building a second one — deferring all embedding/vector machinery — so the feature consolidates the context layer instead of becoming a parallel source of truth.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

I accept the critique's main architectural direction: v1 should be a context-layer consolidation, not "RAG infra". The v1 shape should be:

1. **Hydration contract first** — define what a hydrated item is, what authority it has, how stale state is detected, and how the agent is expected to use it.
2. **Deterministic lexical retriever second** — provide a local retriever that ranks source-backed evidence without API keys or vector dependencies.
3. **Prompt-time substitution, not addition** — use retrieval to choose the same bounded capsules/pointers that `context-inject.sh` already emits, rather than adding another context block.
4. **Semantic/vector retrieval explicitly deferred** — keep it as a future opt-in extension only after the lexical/hydration contract proves useful.

Point-by-point:

**1. Accept — second-source-of-truth invariant must be acceptance-level.** The spec should say hydrated snippets are non-authoritative evidence, never instructions or final truth. A retrieval result may include a small snippet for disambiguation, but the source path/anchor is the contract. If the agent needs to act on the content, it must read the source file unless the hydrated item is explicitly a rule capsule already generated from `.agent0/context/rules/`. Freshness should be computed at retrieval time from file hash/mtime/index metadata, and stale hits should either be omitted or labeled.

**2. Accept — budget must be substitutive by default.** The phrase "unless explicitly configured otherwise" is too loose. v1 should preserve the spec-124/125 normal prompt budget: retrieval selects which capsules enter `AGENT0_CONTEXT_INJECTION`; it does not append a second retrieval dump. Any maintainer-only diagnostic expansion belongs behind `AGENT0_CONTEXT_DIAGNOSTIC=1` or a similarly explicit command, not normal hook output.

**3. Accept with refinement — memory remains a first-class source, but not via a second memory index.** The retrieval layer should not replace `MEMORY.md`, `memory-project.sh`, `memory-query.sh`, or memory decay. For v1, memory can contribute through its existing projected index and entry files. A separate retrieval cache may store derived tokens/rank metadata across all corpora, but it must be invalidated by source hashes and must not become the canonical listing of memory entries. If this is still too easy to drift, the narrower v1 can index only context rules/specs/handoff and call `memory-query.sh` as an adapter for memory.

**4. Accept — lexical fallback is the parity guarantee.** Runtime parity should be rephrased as: the default retriever has identical behavior in Claude Code and Codex CLI given the same checkout and toolchain floor. Optional semantic providers may improve ranking locally, but their absence cannot break hook hydration or explicit search. A semantic provider should be marked native-opt-in at most, not part of the `native` core context layer.

**5. Accept — sync-harness classification must be explicit.** Proposed policy:

- Mechanism shipped and baseline-managed: `.agent0/tools/context-retrieve.sh`, helper scripts, tests, context rule docs, maybe `.agent0/context/sources.json` as a starter config.
- Consumer/project-owned, never shipped as Agent0 content: `.agent0/context/index/` or `.agent0/.context-index/` generated caches, embeddings, and per-project corpus manifests when they contain discovered local facts.
- Source files stay where they are: `.agent0/memory/*.md`, `.agent0/context/rules/*.md`, `docs/specs/*`, `.agent0/HANDOFF.md`.

I lean toward a gitignored generated index under `.agent0/.context-index/`, because generated retrieval state is runtime cache like `.agent0/.runtime-state/`, while the source corpus remains git-tracked where appropriate.

**6. Accept — missing non-goals should be added.** V1 should explicitly exclude background daemons, automatic re-index-on-every-edit hooks, whole-repo product-code indexing, cross-project retrieval, and cloud/vector requirements. Indexing should be explicit or lazy-on-demand with cheap hash invalidation, not a constant hook tax.

**7. Accept — reorder the spec around hydration, not index format.** The architecture section should start with "hydrated evidence contract", then "source adapters", then "retrieval/ranking", then "hook integration", then "diagnostics". Index format is an implementation detail after the contract. This also avoids importing Anthill/Formica's RAG architecture too literally before Agent0's context layer needs it.

**8. Accept — tighten acceptance wording and reuse diagnostics.** Replace soft words with deterministic outcomes. Diagnostics should extend the existing `AGENT0_CONTEXT_DIAGNOSTIC=1` path or an explicit `context-retrieve --debug` command that emits the same data shape, not invent a dashboard or new model-visible channel.

**Proposed v1 feature boundary**

- New primitive: `context-retrieve` returns ranked, provenance-labeled source candidates from configured Agent0 context corpora.
- New contract: hydrated context items are typed as `rule-pointer`, `memory-hit`, `spec-hit`, `handoff-hit`, or `diagnostic-only`, each with authority and read-before-acting expectations.
- Hook integration: `context-inject.sh` may call retrieval as a selector, but still emits the same `AGENT0_CONTEXT_INJECTION` block and obeys current `MAX_FRAGMENTS`/`MAX_BYTES`.
- Source adapters: memory adapter uses existing memory index/query; rules adapter uses frontmatter paths + keyword selection; specs adapter indexes spec titles/status/sections; handoff adapter indexes the four handoff sections.
- Storage: generated cache is gitignored and hash-invalidated; source files remain canonical.
- Deferred: embeddings, sqlite-vec, provider config, product-code corpus, background indexing, cross-project memory.

This counter converges with Claude more than it disagrees. The remaining live design choice is whether memory participates in v1 through a lightweight adapter to `memory-query.sh` or stays out of v1 until the non-memory corpus path is proven.

---

## Round 2 — reviewing agent (critique)

The direction has converged: hydration contract first, deterministic lexical retriever, substitutive budget, embeddings deferred. I won't relitigate that. But the Round 2 counter reached "accept all eight" by introducing two mechanisms that quietly reopen the risks they were meant to close. Synthesis has to resolve these, not inherit the hedging.

**1. "Substitutive" without an eviction floor is *more* dangerous than addition.** We both agreed retrieval *selects* which capsules fill the existing `max_fragments=5 / max_bytes=6000` envelope rather than appending a second block. But today's `context-inject.sh` selects capsules deterministically (this very turn: `spec-driven delegation runtime-capabilities harness-sync memory-placement`). If retrieval *ranking* now decides which five survive, ranking quality becomes load-bearing for correctness — a weak lexical score can silently **evict** a rule the agent needed (a delegation gate, a runtime-capability constraint). Addition was only a noise risk; substitution is a correctness risk, and it fails *silent*. v1 must encode a **must-include floor**: a deterministic set retrieval may reorder but never drop, with retrieval competing only for the remaining budget. This is the single thing the Round 2 counter's "selector mode" glossed over.

**2. The "retrieval cache across all corpora" reintroduces the second-index drift that point 3 accepted away.** Codex resolved the *canonical-listing* drift (cache won't replace `MEMORY.md`) but then proposed a cache that "stores derived tokens/rank metadata across all corpora" — which, for memory, is a second tokenization of the same files, hash-invalidated or not. That is drift surface by another name. The sharp fork synthesis must pick: does the cache index memory's **text** (re-tokenize → drift), or only memoize `memory-query.sh`'s **output** (rank metadata keyed by query, zero re-tokenization)? Corpora should not be treated uniformly — memory is queried *through* its adapter; rules/specs/handoff are indexed *by* the new retriever. One uniform token cache over everything is exactly the consolidation failure we're trying to avoid.

**3. On the "remaining live design choice" — memory is in v1, but only as a read-through adapter.** Codex framed it binary: lightweight `memory-query.sh` adapter, or memory out of v1 until the other corpus path proves out. Reject "out of v1." Memory is the one corpus that *already models freshness/decay* — it is the natural proving ground for the hydration freshness invariant (point 1), not the riskiest one to defer. Excluding it makes v1 a toy that indexes rules and specs (which barely drift) while skipping the corpus where staleness actually bites. The binding condition: the memory adapter is **read-only over memory's own artifacts** (`MEMORY.md` projection + `memory-query.sh decay`), never a token index over `.agent0/memory/*.md`. That satisfies point 3's no-second-index *and* gives the freshness contract something real to test.

**4. Automatic per-turn selection and "no background work" only reconcile because of the floor.** Codex point 6 banned daemons and auto-reindex; the feature boundary still has `context-inject.sh` "call retrieval as a selector" every prompt turn — the exact thing the initiator's own Round 1 risk #2 flagged. These are consistent *only* because selection is substitutive and bounded, which makes #1's floor non-negotiable rather than optional: automatic per-turn selection is safe precisely because a bad rank cannot evict a required capsule. Synthesis should state the coupling explicitly — per-turn selector mode is permitted **iff** the must-include floor holds — instead of listing them as independent accepts.

**5. One cheap contract fix.** The five item types (`rule-pointer / memory-hit / spec-hit / handoff-hit / diagnostic-only`) fold two orthogonal axes — *source class* and *authority* — into one enum. A `rule-pointer` is an authoritative-capsule; a `memory-hit` is evidence-read-source; either could also be diagnostic-only. Encode authority as a **separate field** (`authoritative-capsule | evidence-pointer | diagnostic-only`) over a source-class tag, or every new corpus forces a new type name and the read-before-acting rule gets re-litigated per type. Costs nothing to fix now, expensive after the contract ships.

The debate has converged on *shape*. What remains is three load-bearing encodings — the eviction floor, the cache granularity, and memory-as-read-through-adapter — plus one cheap contract cleanup. None of these are "more rounds" material; they are precisely the decisions a synthesis must nail rather than restate as accepted prose.

**Recommendation for synthesis:** Adopt the converged v1 (hydration contract + deterministic lexical retriever + substitutive budget, embeddings deferred), and explicitly encode three things the counter left soft — a must-include eviction floor that retrieval may reorder but never drop, memory as a read-through adapter *in* v1 (not deferred) that never re-tokenizes memory files, and per-corpus cache granularity that memoizes `memory-query.sh` output rather than indexing memory text.

---

## Round 3 — initiating agent (counter)

Converged. I accept Claude's Round 2 corrections as synthesis requirements, not optional refinements.

**1. Accept — substitutive retrieval needs a must-include floor.** The original "retrieval selects the capsules" framing was incomplete. The selector must preserve deterministic hard matches from today's `context-inject.sh` path for safety/routing-critical fragments, then let retrieval rank the remaining budget. A reasonable first contract is:

- hard floor: direct path/frontmatter/keyword matches for capability rules that the prompt explicitly names or that the current deterministic selector already treats as load-bearing;
- retrieval lane: ranked evidence candidates compete only for the leftover fragment/byte budget;
- diagnostics: omitted candidates include whether they lost to floor reservation, score, or byte cap.

This keeps retrieval from silently evicting runtime-capability, delegation, memory-placement, or other governance fragments when the lexical score is weak.

**2. Accept — memory is in v1 as a read-through adapter.** Claude is right that deferring memory would make v1 avoid the corpus where freshness actually matters. The corrected stance: memory participates in v1, but the retriever does not tokenize `.agent0/memory/*.md` into its own memory index. It calls or mirrors existing memory primitives: projected `MEMORY.md`, `memory-query.sh search/list/decay`, and entry metadata. If a cache is used, memory cache entries are query-output memoization keyed by source hashes and query parameters, not a second textual index.

**3. Accept — cache granularity is per corpus.** Rules/specs/handoff may be indexed directly because they do not already have a projection/freshness subsystem. Memory does have one, so it is adapter-backed. The spec should reject "one uniform token cache for every corpus" in v1.

**4. Accept — per-turn automatic use is conditional.** Prompt-time retrieval is allowed only under the floor + budget contract. Without the floor it should remain explicit-command-only. This should be encoded as an acceptance criterion so implementation cannot accidentally turn retrieval into a noisy or unsafe always-on hook.

**5. Accept — authority must be separate from source class.** Use at least two fields:

- `source_class`: `rule`, `memory`, `spec`, `handoff`, maybe later `routine`/`reminder`;
- `authority`: `authoritative-capsule`, `evidence-pointer`, `diagnostic-only`.

This prevents every new corpus from redefining read-before-acting semantics.

I see no need for another critique round unless the user wants one. The debate has enough agreement to synthesize and rewrite `spec.md`: v1 is a conservative context-layer feature, not semantic RAG. The implementation-ready spec should make "lexical first, retrieval as bounded selector, memory as adapter, no second source of truth" non-negotiable.

---

## Round 3 — reviewing agent (critique)

_Skipped. Claude's Round 2 critique stated the remaining points were synthesis decisions, not material for another critique round._

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

**Proposed spec changes:**

1. **Reframe the feature name/scope from generic RAG to context retrieval + hydration.**
   - `spec.md` should keep "RAG" as prior-art vocabulary only. The v1 feature is a context-layer primitive that retrieves source-backed evidence and feeds the existing hydration envelope.
   - Add a clear v1 thesis: hydration contract first, deterministic lexical retrieval second, semantic/vector retrieval deferred.

2. **Add a hydration item contract.**
   - Each result/hydrated item must carry `source_class`, `authority`, `path`, optional line/section anchor, reason/score, freshness status, and read-before-acting expectation.
   - `authority` is separate from source class: `authoritative-capsule`, `evidence-pointer`, `diagnostic-only`.
   - Snippets are non-authoritative by default. Source files remain canonical.

3. **Make retrieval substitutive with a must-include floor.**
   - `context-inject.sh` integration must preserve a deterministic floor of routing/governance capsules selected by explicit prompt/path/keyword matches.
   - Retrieval may rank/reorder candidates only inside the remaining `MAX_FRAGMENTS`/`MAX_BYTES` budget.
   - Normal prompt output must remain one `AGENT0_CONTEXT_INJECTION` block, not a second retrieval dump.

4. **Put memory in v1 only as a read-through adapter.**
   - Memory retrieval uses existing memory artifacts and commands: `MEMORY.md`, entry metadata, `memory-query.sh`, decay output.
   - V1 must not build a second token/text index over `.agent0/memory/*.md`.
   - A cache may memoize adapter outputs keyed by query and source hashes; it may not become the canonical memory listing.

5. **Define per-corpus indexing/cache rules.**
   - Rules/specs/handoff can be indexed directly by the new retriever.
   - Memory is adapter-backed.
   - Generated retrieval cache should be gitignored, likely under `.agent0/.context-index/`; mechanisms/config/tests live under `.agent0/` and are sync-harness managed.

6. **Tighten non-goals.**
   - No embeddings/vector DB in v1.
   - No hosted retrieval service, API-key requirement, or paid default path.
   - No background daemon, automatic re-index-on-every-edit hook, or commit-time indexing.
   - No whole product-code corpus indexing in v1.
   - No cross-project retrieval or memory sharing.
   - No human dashboard.

7. **Tighten diagnostics.**
   - Diagnostics reuse `AGENT0_CONTEXT_DIAGNOSTIC=1` and/or an explicit `context-retrieve --debug` command.
   - Debug output must show query, selected corpus adapters, floor reservations, ranking reasons, omitted candidates, byte/fragment caps, and freshness/staleness labels.

8. **Replace soft acceptance wording with testable scenarios.**
   - Remove "may", "likely", "where available", and "unless explicitly configured otherwise" from normative criteria.
   - Acceptance should prove runtime parity through the deterministic lexical fallback, not through optional semantic providers.

**Unresolved disagreements:** (only if cap-reached or abandoned)

- None material. The remaining design work is implementation detail for `plan.md`: exact lexical ranking algorithm, cache file shape, and how much of the current `context-inject.sh` selector becomes shared library code.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

- Applied synthesis to `spec.md`: reframed v1 as context retrieval + hydration, not semantic RAG.
- Added acceptance criteria for provenance-labeled retrieval, memory read-through adapter, bounded substitutive hydration, deterministic floor preservation, diagnostics, runtime-neutral parity, cache/git policy, sync propagation, and focused tests.
- Marked semantic/vector retrieval, hosted services, product-code indexing, background indexing, cross-project retrieval, dashboarding, and second memory index as non-goals.
- Resolved open questions for v1 and marked the spec shipped after validation.
