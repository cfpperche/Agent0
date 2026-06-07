---
paths:
  - ".agent0/tools/lib/capacity.sh"
  - ".agent0/tools/lib/paid-media.sh"
  - ".agent0/tools/audio.sh"
  - ".agent0/tools/sound.sh"
  - ".agent0/tools/transcribe.sh"
  - ".agent0/tools/diagram.sh"
---

# Capacity kit

`.agent0/tools/lib/capacity.sh` is the shared **kernel** for Agent0's capacity tools — the plumbing the 6 capacity tools (`image`/`video`/`audio`/`sound`/`transcribe`/`diagram`) used to hand-copy, extracted once + tested once so the **7th tool is config, not a clone**. A small, flat helper lib (NOT a framework): each tool still owns its own main control flow, arg parsing, `doctor`/`caps` domain fields, manifest *schema*, engine invocation, and storage policy. Precedent: `lib/managed-block.sh`. Spec: `docs/specs/163-capacity-kit/` (graduated from the decision-grade meeting `.agent0/meetings/capacity-tool-kit-consolidation-2026-06-07T00-28-12Z/`).

## What the kernel provides

Source it right after resolving the script dir, **below the `--help` line range** (several tools print their own source via `sed -n 'A,Bp' "$0"` — inserting inside that range drifts `--help`), with a clear missing-kit guard:

```bash
. "$HERE/lib/capacity.sh" 2>/dev/null || { echo "<tool>: missing kit library lib/capacity.sh" >&2; exit 70; }
CAP_TOOL="<tool>"
```

- `cap_have <bin>` — `command -v` predicate (verbatim-identical across tools).
- `cap_sha256_str <s>` / `cap_sha256_file <f>` — sha256 helpers.
- `cap_emit_exit <status>` — status→exit mapping (`ok=0 unavailable=2 error=3`); reads global `USE_EXIT_CODE`; default exit 0 (the advisory-family contract).
- `cap_manifest_append <path> <jsonl-line>` — the one-line-per-call append *mechanics* (mkdir + append; empty line = no-op so the caller's `jq` guard is preserved). The tool builds the line (its own schema) via `jq`.
- `cap_fail <status> <msg>` — unified failure (status + compact JSON `{status,message}` / text + the optional `_cap_on_fail` manifest hook + exit). Reads `OUT_JSON` + `CAP_TOOL`.
- `cap_resolve_ffmpeg <env-override-name>` — sets `FFMPEG_BIN`; the env name differs per tool, passed as `$1`.

**Convention (the tool sets, the kernel reads):** `USE_EXIT_CODE`, `OUT_JSON`, `CAP_TOOL`. **Hook (optional):** define `_cap_on_fail <status>` (your `append_manifest`) and `cap_fail` records via it.

## Extract only what is byte-identical or cleanly parameterizes

The discipline that keeps the kit honest (and behavior-preserving):
- **Use `cap_fail` only if the tool's failure JSON is the compact `{status,message}` shape.** A tool with a *richer* failure JSON keeps its **local `fail()`** (e.g. `transcribe` emits `{status,input,message,outputs}`; `audio` emits *pretty* `jq -n` — a pre-existing inconsistency, NOT normalized here because that would be a behavior change → a separate intentional follow-up). Such a local `fail` still uses `cap_emit_exit` + `cap_manifest_append` for the shared mechanics.
- The tool's `append_manifest` keeps its own **fields** (schema differs per tool) and routes the append through `cap_manifest_append`.
- Tool-specific acquisition ladders stay in the tool (see below).

## Paid-media sub-kit (`lib/paid-media.sh`) — deferred follow-up

The paid lane (`fal-rest` wrapper, the `tiers.yaml` block-scan reader `yget`/`ytop`, `cost-print`, `--confirm-cost-usd` gate) is shared by `image`/`video`/`audio --remote`/`sound`. It is a **separable second extraction** (smaller, only ~2 first-class tools today) and was **deferred** from the v1 kernel pass to keep the refactor's blast radius bounded. The placeholder is referenced in the spec; build it when the next paid tool lands or when the duplication bites again.

## Local acquisition stays a TEMPLATE, not a library

The local acquire ladders are **policy-heavy and not byte-identical** — `uvx --with kokoro` (audio) vs `uvx --from whisper.cpp-cli` (transcribe) vs `npx -p @mermaid-js/mermaid-cli mmdc` + system-Chrome (diagram) share only the *shape* "try → degrade to an honest hint," not code. Forcing them into a library would be false unification. Keep each in its tool; the shared mechanics they DO have (manifest/status/redaction) come from the kernel. Reference skeleton for a new tool: copy the nearest sibling's resolve-ladder and adapt.

## Building the 7th capacity tool (config, not clone)

1. `source lib/capacity.sh` (below `--help`), set `CAP_TOOL`, set `USE_EXIT_CODE`/`OUT_JSON` from args.
2. Define `append_manifest` with your fields → `cap_manifest_append`; define `_cap_on_fail` if you use `cap_fail`.
3. Use `cap_have`/`cap_sha256_*`/`cap_emit_exit`; use `cap_fail` if your failure JSON is compact, else keep a local `fail`.
4. Keep your engine/acquisition/storage/doctor-caps in the tool.
5. Add an offline suite + golden fixtures; the lib propagates via the `.agent0/tools/lib|*.sh` sync glob.

## Sync propagation (load-bearing)

`.agent0/tools|*.sh` is a maxdepth-1 glob — it does NOT recurse into `lib/`. The kit propagates via a dedicated **`.agent0/tools/lib|*.sh`** glob in `sync-harness.sh`'s `COPY_CHECK_GLOBS` (spec 163; the `managed-block.sh` literal was retired in favor of it). Without this, a consumer's tools would `source` a lib that never shipped and break. Guarded by `.agent0/tests/capacity-kit/sync-propagation.sh`.

## Behavior-preservation gate

This was a **pure, test-protected refactor** — zero behavior change. The gate: every tool's offline suite green **+** `.agent0/tests/capacity-kit/golden.sh verify` clean (captures each tool's `caps`/`doctor`/`--help`/usage/bad-flag stdout+stderr+exit, before vs after) **+** the sync-propagation test **+** `bash -n` **+** `doctor`. Run `golden.sh capture` BEFORE any future kit change, `verify` after.
