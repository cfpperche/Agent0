# 134 — context-layer-rag-hydration — notes

_Created 2026-05-31._

## Design decisions

### 2026-05-31 — parent — v1 retrieval boundary

The Claude/Codex debate converged on context retrieval + hydration rather than semantic RAG. V1 ships deterministic lexical retrieval only, preserves existing files as source of truth, and uses retrieval as a bounded selector inside the current `AGENT0_CONTEXT_INJECTION` envelope. Semantic/vector retrieval, product-code indexing, background indexing, and cross-project retrieval stay deferred.

### 2026-05-31 — parent — memory adapter boundary

Memory participates in v1 as a read-through adapter over `MEMORY.md` and entry metadata. The retriever must not build a second token/text index over `.agent0/memory/*.md`; tests pin that body-only memory text does not rank unless projected through the memory index.

## Deviations

### 2026-05-31 — parent — no persistent cache in v1

The spec reserves `.agent0/.context-index/` as the future gitignored generated-state home, but the implementation searches live files and writes no persistent retrieval cache. This keeps v1 simpler and avoids stale generated state.

## Tradeoffs

### 2026-05-31 — parent — retrieval default is on but fail-open

`context-inject.sh` enables the retrieval lane by default so prompt hydration actually exercises the feature. It preserves deterministic rule capsules as a floor and fails open to the previous deterministic behavior if the tool is missing or errors. `AGENT0_CONTEXT_RETRIEVAL=0` disables the lane for local debugging.

### 2026-05-31 — parent — Claude Code live dogfood result

Claude Code real-session dogfood passed after an initial inconclusive turn. The inconclusive turn proved the hook and retrieval lane were live (`retrieval: enabled`) but floor saturation used all 5 fragments. A follow-up prompt with `floor_fragments=3` left two slots for retrieval and Claude reported two live retrieval pointers with `source_class: spec`, `authority: evidence-pointer`, `reason`, `freshness`, `anchor`, and non-authoritative snippets. This closes the live Claude-side evidence gap; previous validation already covered tests/fixtures and Codex live hook output.

## Open questions

None remaining for v1. Future specs can revisit semantic/vector retrieval, persistent cache format, product-code corpus, and optional provider configuration.
