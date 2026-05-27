# 095 — harness-consumer-vocab

_Created 2026-05-27._

**Status:** shipped

## Intent

"Fork" is the wrong vocabulary for projects that consume Agent0. Agent0 is positioned as a **harness/framework** (plugin-shaped capacity bundle) that downstream projects install via `sync-harness.sh`; the relationship is **unidirectional** (upstream Agent0 → consumer project), not bidirectional like a git-fork. The current word "fork" appears across rules, hooks, tools, the sync script's CLI flag name, tests, and audit messages — and every occurrence reinforces a mental model of bidirectional change-flow that the harness actively rejects (sync is one-way; consumer projects don't propagate back upstream).

This spec renames the consumer-of-harness vocabulary from "fork" → "consumer project" (or chosen variant) across the **fork-bound surface** — i.e. the files that actually ship to consumer projects via `sync-harness.sh`. The downstream effect is clearer onboarding for new consumer projects (the architecture is named honestly), reduced friction explaining Agent0 to outsiders, and alignment with the framing already adopted by spec 092 (multi-runtime) which speaks of "runtimes" instead of "agents-that-fork-the-config".

The motivation surfaced during the session that scaffolded this spec (2026-05-27): the maintainer noticed `.claude/rules/hook-chain-latency.md` was being shipped to "forks" but the rule's "Adding a new PreToolUse(Bash) hook" section binds only the upstream maintainer — making the word "fork" doubly wrong (relationship is consumer, AND the consumer doesn't author hooks). The hook-chain-latency rule was split (spec 094 follow-up, committed in the same session); the vocabulary rename is the broader hygiene this spec tracks.

## Acceptance criteria

- [ ] **Scenario: a consumer project reading any shipped rule sees consumer-vocabulary**
  - **Given** a freshly synced consumer project at `<consumer-path>`
  - **When** any contributor opens `<consumer-path>/.claude/rules/*.md` or `<consumer-path>/CLAUDE.md`
  - **Then** no occurrence of "fork" describes the consumer-of-harness relationship (the word "fork" may still appear in genuine git-operation contexts — "fork the Agent0 repo on GitHub to contribute upstream" is correct)

- [ ] **Scenario: sync-harness.sh CLI exposes the renamed vocabulary**
  - **Given** a developer runs `bash .claude/tools/sync-harness.sh --help`
  - **When** reading usage text, flag descriptions, and the positional arg name
  - **Then** the positional arg is named `<consumer-path>` (or chosen replacement), and the `--force-except` flag doc references "consumer customization" instead of "fork customization"

- [ ] **Scenario: AGENTS.md and CLAUDE.md frame Agent0 as a harness**
  - **Given** a fresh contributor opens `AGENTS.md` or `CLAUDE.md` (either upstream or in a consumer project)
  - **When** reading the § Runtime entrypoints + § Harness sync sections
  - **Then** language frames Agent0 as a harness/framework consumed by projects, not as a repo to be forked

- [ ] **Scenario: propagation-advisory's "fork-bound surface" terminology stays internally consistent**
  - **Given** the propagation-advisory hook emits an advisory on a shipped-file edit
  - **When** the advisory message mentions the surface
  - **Then** the wording matches the chosen replacement (e.g. "consumer-bound surface" or "shipped surface"), and the corresponding `.claude/rules/propagation-advisory.md` documentation agrees

- [ ] A single canonical glossary (in either `.claude/rules/harness-sync.md` or a new short rule) defines: "harness", "consumer project", "shipped surface" (replacement of "fork-bound surface"), and explicitly names the contexts in which "fork" still legitimately applies (git operation, GitHub UI verb).

- [ ] `.claude/tests/harness-sync/*` test fixtures and assertions are updated to use the renamed CLI arg + vocabulary; the test suite passes.

- [ ] Sync-harness drift-check (`bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 <consumer-path>`) against a real consumer project (mei-saas or codexeng) reports clean drift after the rename PR lands + the consumer syncs (no spurious `customized-refused` because of vocabulary in places consumers haven't touched).

## Non-goals

- **Renaming "fork" in `.claude/memory/*.md`** — those files are project-local, not shipped to consumer projects. Clean up opportunistically as those memories are touched; not in scope here.
- **Rewriting historical `docs/specs/*` content** — specs are immutable design memory (rule: `.claude/rules/spec-driven.md` § *Workflow* step 5 — "the spec dir stays — it's the historical record"). The vocabulary they used at scaffold time is part of that record.
- **Backward-compat deprecation shim for `<fork-path>`** — a one-rename of the sync-harness positional arg is enough; the script is not consumed by external tooling that would break on rename. Skip the shim.
- **Renaming any concept beyond "fork"** — the words "harness", "framework", "runtime", "skill", etc. stay as-is. Don't relitigate adjacent vocabulary.
- **Renaming git-fork in genuine git-operation contexts** — "if you fork the Agent0 repo on GitHub to contribute upstream" is correct usage and stays.
- **Renaming the directory `.claude/tests/harness-sync/`** — "harness-sync" is the capacity name (the tool being tested), not the consumer relationship.

## Open questions

- [x] **Exact replacement term.** ~~Candidates: `consumer project`, `consumer`, `downstream project`, `harnessed project`.~~
  - **Decision 2026-05-27:** three forms of the `consumer` root. `consumer project` in prose, `consumer` as adjective (`consumer customization`, `consumer-bound`, `consumer-specific`), `<consumer-path>` as the CLI positional arg. Rationale: matches the spec slug (`harness-consumer-vocab`), bate com framing de plugin/harness, remove ambiguidade git.
- [x] **Rename "fork-bound surface" to what?** ~~Candidates: `shipped surface`, `consumer-bound surface`, `harness-shipped surface`.~~
  - **Decision 2026-05-27:** `shipped surface`. Rationale: describes MECHANISM (shipa via manifest) instead of destination, which desacopla do `consumer` rename — future rename of "consumer→outra coisa" não puxa rename do conceito de surface. Shorter than alternatives.
- [x] **Update `propagation-hygiene.md` (memory, not shipped)?** ~~The maintainer-binding memory uses "fork-bound" heavily. Editing project-local memory is technically out of scope per Non-goal #1, but the rule it pairs with (`.claude/rules/propagation-advisory.md`) will be renamed — leaving the memory using old terms creates a doc-sync gap.~~
  - **Decision 2026-05-27:** include the paired memory in scope. Rationale: `propagation-hygiene.md` and `propagation-advisory.md` are an explicit doc-pair with mutual cross-refs; divergent vocabulary breaks the pair. Cost ~5 min; win is no doc-sync gap. This is a special case carve-out from Non-goal #1, which still applies to all other `.claude/memory/*.md` files (clean opportunistically as touched).
- [x] **Coordinated PR vs. incremental?** ~~A single PR mass-renaming ~50 occurrences is reviewable but disruptive; an incremental rename across 3-5 PRs is gentler but leaves the codebase in mixed-vocabulary state for weeks.~~
  - **Decision 2026-05-27:** single PR mass-rename. Empirical scope (audit 2026-05-27) is **494 occurrences across ~85 files** — larger than the original ~50 estimate but still tractable as one diff if grouped commit-by-category. Incremental was rejected: leaves codebase in mixed-vocabulary state for weeks; new contributors hit both terms; sync-baseline would churn N times; coordination cost with deferred consumer syncs multiplies. The single-PR review burden is one-time and reviewable per commit-category.
- [x] **Sync timing relative to spec 093 + 094 propagation.** ~~This spec was created mid-session while specs 093 + 094 were pending sync to consumer projects. Order: (a) sync 093 + 094 with old vocabulary, then rename, then re-sync; (b) rename first, then sync everything in one consumer-project pull. (b) is fewer drift cycles but blocks 093 + 094 propagation on this rename's completion. Decide in `plan.md`.~~
  - **Decision 2026-05-27:** option (b) — defer sync to consumer projects until 095 rename ships. Rationale: consumers never see old vocabulary; single sync cycle once rename lands. Cost: 093 + 094 propagation blocked on 095 timeline. Acceptable because no consumer project urgently needs those capacities; mei-saas + codexeng are dogfood targets, not external dependencies.

## Context / references

- Conversation 2026-05-27 — maintainer raised: "essa rule hook-chain-latency.md é shipada para forks? talvez a nomenclatura forks está errado, nao sao forks ... temos que tratalos como consumidores do nosso plugin/framework Agent0 é um harness"
- `.claude/rules/harness-sync.md` — primary surface carrying "fork" vocabulary
- `.claude/rules/memory-placement.md` — uses "shipped to forks" repeatedly in the 3-bucket table
- `.claude/rules/propagation-advisory.md` — uses "fork-bound surface" as a load-bearing term
- `.claude/memory/propagation-hygiene.md` — sibling maintainer-binding memory; uses "fork-bound files" (project-local, scope decision pending — see Open question #3)
- `.claude/tools/sync-harness.sh` — CLI carries `<fork-path>` positional arg
- `.claude/tests/harness-sync/*` — test fixtures + assertions referencing "fork"
- Spec 092 (multi-runtime handoff) — already uses "runtime" framing without "fork"; precedent for vocabulary-precise renames in this repo
- Spec 094 (hook-chain-latency) + its follow-up split (commit `83a4ed7`) — the immediate trigger that surfaced the vocabulary mismatch
