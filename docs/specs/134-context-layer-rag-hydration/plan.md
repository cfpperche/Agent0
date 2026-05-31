# 134 — context-layer-rag-hydration — plan

_Created 2026-05-31._

**Status:** shipped

## Approach

Ship a conservative v1 context retrieval layer under `.agent0/`:

1. Add `context-retrieve.sh` plus a Python stdlib helper as an explicit CLI for deterministic lexical retrieval.
2. Model each candidate with separate `source_class` and `authority` fields so source type and trust semantics do not collapse into one enum.
3. Treat memory as a read-through adapter over existing memory artifacts: `MEMORY.md`, entry frontmatter metadata, and memory-query-compatible freshness concepts. Do not build a separate memory text index.
4. Integrate retrieval into `context-inject.sh` as a retrieval lane after deterministic floor selection. Existing keyword/path selected rule capsules are preserved first; retrieval candidates fill only the remaining fragment/byte budget.
5. Add diagnostics through CLI `--format debug` and the existing `AGENT0_CONTEXT_DIAGNOSTIC=1` path, without creating a new dashboard or hook output channel.
6. Document the capacity in a shipped context rule and runtime capabilities matrix. Reserve `.agent0/.context-index/` as gitignored generated state, but do not require persistent cache in v1.

## Files to touch

- `.agent0/tools/context-retrieve.sh` — shell entrypoint.
- `.agent0/tools/context-retrieve-helper.py` — deterministic lexical retriever.
- `.agent0/hooks/context-inject.sh` — bounded retrieval lane and diagnostics pointer.
- `.agent0/context/rules/context-retrieval.md` — shipped capacity documentation.
- `.agent0/context/rules/runtime-capabilities.md` — capability matrix row.
- `.agent0/tools/sync-harness.sh` — manifest includes the helper file.
- `.gitignore` — gitignore `.agent0/.context-index/`.
- `AGENTS.md` and `CLAUDE.md` — short first-contact pointer to the new explicit tool.
- `.agent0/tests/context-retrieval/` — focused tests for the new primitive.
- `.agent0/tests/context-injection/` — focused tests/updates for retrieval lane and capsule accounting.
- `docs/specs/134-context-layer-rag-hydration/*` — SDD artifacts and validation evidence.
- `.agent0/HANDOFF.md` — active work/closeout state.

## Design details

### Candidate contract

Each candidate has:

- `source_class`: `rule`, `memory`, `spec`, or `handoff`
- `authority`: `authoritative-capsule`, `evidence-pointer`, or `diagnostic-only`
- `path`: repo-relative source path
- `title` and optional `anchor`
- `score` and `reason`
- `freshness`
- `read_before_acting`
- short `snippet`, used for disambiguation only

### Retrieval corpus

- Rules: direct lexical scan of `.agent0/context/rules/*.md` title/frontmatter/body. Authority is `authoritative-capsule`.
- Memory: parse `.agent0/memory/MEMORY.md` projected bullets and entry frontmatter metadata. Authority is `evidence-pointer`. Do not scan memory bodies for ranking.
- Specs: scan `docs/specs/*/spec.md` title/status/intent/open headings. Authority is `evidence-pointer`.
- Handoff: scan `.agent0/HANDOFF.md` sections. Authority is `evidence-pointer`.

### Hydration integration

`context-inject.sh` keeps the current deterministic `SELECTED` rule list as a floor. After those capsules are appended, the hook calls `context-retrieve.sh` to fetch additional candidates excluding already-selected rule paths. Candidates are appended only while both fragment and byte budgets allow. If retrieval fails or dependencies are missing, the hook fails open and emits the existing deterministic context.

### Sync and cache policy

Mechanisms, docs, and tests are shipped by sync-harness. Generated retrieval state is not shipped and is ignored under `.agent0/.context-index/`. V1 does not need to write persistent cache; the path is reserved so future cache work has a documented home.

## Alternatives rejected

- **Semantic/vector v1:** rejected because it adds credentials/dependencies before the hydration contract proves useful.
- **Uniform index over every corpus:** rejected because memory already has projection/freshness machinery and a second memory text index would drift.
- **Additive hook block:** rejected because specs 124/125 intentionally reduced hook noise. Retrieval must improve selection inside the existing envelope.
- **Product-code corpus:** rejected for v1 because it explodes scope and risks indexing secrets or irrelevant source.

## Risks

- Lexical ranking may be weak. Mitigation: deterministic floor first, retrieval lane second, diagnostics for omitted candidates.
- Hook latency may increase. Mitigation: stdlib local search over bounded harness corpus only; fail open on errors.
- Memory adapter could accidentally become a second memory index. Mitigation: tests assert memory results are adapter/projection based and docs forbid body token indexing.
- Consumer sync could ship generated local state. Mitigation: `.gitignore`, sync manifest review, and tests.

## Validation plan

- Run new context-retrieval test suite.
- Run context-injection tests.
- Run memory multi-runtime tests.
- Run runtime-capabilities tests.
- Run harness-sync focused tests relevant to manifest/config propagation.
- Run `git diff --check`.
