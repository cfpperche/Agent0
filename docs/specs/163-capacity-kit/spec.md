# 163 — capacity-kit

_Created 2026-06-06._

**Status:** draft

<!-- Pure refactor of shell tooling. No UI. -->
**UI impact:** none

## Intent

Extract the duplicated plumbing shared across Agent0's **6 capacity tools** (`image`/`video`/`audio`/`sound`/`transcribe`/`diagram` under `.agent0/tools/` + skill dirs) into a small, sourced bash **kit** (`.agent0/tools/lib/`), so the **7th capacity tool is config, not a clone**. This is a **behavior-preserving, test-protected refactor** — not a feature. Driver: the same skeleton was hand-copied 4–6× (`emit_exit` ×5, `append_manifest`/`fail`/`have` ×4), and two *skeleton* bugs already shipped-then-got-caught (a `FAL_KEY` leak in `/audio`'s `doctor`; pretty-vs-compact JSON in `/sound`) — bugs a once-tested kit prevents across all instances. Decided in the decision-grade meeting `.agent0/meetings/capacity-tool-kit-consolidation-2026-06-07T00-28-12Z/` (blind openings converged independently; ledger 6 claims / 0 assertion-only; `synthesis: accepted`). The kit follows the accepted `.agent0/tools/lib/managed-block.sh` precedent (a sourced, harness-synced helper lib).

**Measurement (the meeting's gated task-1, done at plan time — kill-condition did NOT fire):** `have()` is byte-identical across all 4 measured tools; `emit_exit()` identical across 3; `sha256_of_str()` identical across 2 — a real verbatim kernel. The larger value is in **same-shape / different-content** functions (`fail`, `append_manifest`, `resolve_ffmpeg`, the tier-oracle reader) that need **parameterization** to share, NOT verbatim extraction — and these are exactly where the two bugs lived. So this is a library, but a **design refactor** (parameterize the shared interface), not a trivial lift.

## Acceptance criteria

- [ ] **Scenario: behavior is byte-identical after extraction (the gate)**
  - **Given** the 6 capacity tools refactored to `source` the kit
  - **When** each tool's offline suite + a golden fixture set are run
  - **Then** all 6 `run-all.sh` suites pass, AND golden parity holds: same stdout/stderr/exit per fixture (timestamps + temp paths normalized), JSON semantic-equality for `--json`, compact one-line manifest entries preserved, identical `--exit-code` mapping (`ok=0 unavailable=2 error=3`) — zero behavior change

- [ ] **Scenario: the kit propagates to consumers (the load-bearing wiring fix)**
  - **Given** the kit lives at `.agent0/tools/lib/*.sh` and the tools `source` it
  - **When** `sync-harness.sh` runs against a consumer
  - **Then** every `lib/*.sh` propagates (the current `.agent0/tools|*.sh` glob is maxdepth-1 and does NOT recurse into `lib/`; `managed-block.sh` syncs only as a literal at line 211) — a harness-sync test proves propagation, so a consumer's tools never `source` a lib that didn't ship

- [ ] **Scenario: a missing kit fails clearly, never silently**
  - **Given** a tool whose `lib/capacity.sh` is absent
  - **When** the tool runs
  - **Then** it fails with a clear "missing kit library" message (the `managed-block.sh` precedent), not a cryptic unbound-function error

- [ ] **Kernel (extract verbatim — measured byte-identical across ≥3 tools):** `have`, `sha256_*`, `emit_exit` (status→exit), a compact-JSONL manifest-append *mechanic* (caller supplies fields), secret redaction (`set|unset`, never the value), `resolve_ffmpeg <env-override>`.
- [ ] **Paid-media sub-kit:** the YAML tier-oracle reader (the `yget`/`ytop` block-scan, parameterized for `tiers:` nesting), `FAL_KEY`-presence/state, cost-print + `--confirm-cost-usd` gate, the `fal-rest.sh` invocation wrapper.
- [ ] **Local-utility acquisition stays a documented TEMPLATE, NOT a library** — the acquire ladders (`uvx --with kokoro` vs `uvx --from whisper.cpp-cli` vs `npx -p @mermaid-js/mermaid-cli` + system-Chrome) are policy-heavy and not byte-identical; only their shared mechanics (manifest/status/redaction) live in the kernel.
- [ ] **Stays in each tool (NOT extracted):** argument parsing + user-facing wording, `doctor`/`caps` domain fields, the manifest record *schema* (fields), engine invocation + request-body/response paths, storage policy (draft/asset/keeper/ledger), acquisition ladders.
- [ ] **Over-abstraction guard:** a small kit sourced by relative path; each `.sh` stays readable as its own domain contract; NOT a generic "capacity-runner" framework (no dispatch/inheritance). Extract only what ≥3 tools use verbatim or what cleanly parameterizes.
- [ ] All touched skills pass `/skill validate`; `doctor.sh` stays green; `bash -n` clean on every tool + lib.

## Non-goals

- **Any behavior change** — this is a pure refactor; a single changed stdout/exit/manifest byte means the extraction is wrong.
- **A local-utility acquisition library** — those flows stay per-tool / a documented skeleton (policy-heavy, not byte-identical).
- **A generic capacity-runner / framework** — the kit is helpers; each tool owns its own main control flow.
- **Refactoring tool-specific logic** (engine calls, manifest schemas, storage policy, arg semantics) — only shared plumbing moves.
- **Touching `fal-rest.sh`** — it is already the shared paid primitive; the sub-kit wraps it, doesn't replace it.
- **New capacity behavior or a 7th tool** — out of scope (the kit *enables* a cheaper 7th later).

## Open questions

- [ ] **The `fail()` ↔ `append_manifest()` coupling** — `fail` is same-shape but calls the tool-specific manifest. Resolve: does the kernel `cap_fail` take a manifest *hook/callback*, or is the manifest envelope standardized enough (`{ts,status,...}` + caller-supplied fields object) that `cap_fail` owns it? This is the central design call.
- [ ] **Sync-glob fix shape** — add a `.agent0/tools/lib|*.sh` glob to `COPY_CHECK_GLOBS`, or list each lib literal in `COPY_CHECK_FILES`? (Glob is future-proof; literal is explicit.) Plus the harness-sync test that proves it.
- [ ] **Golden-gate harness location + mechanics** — where the fixtures live, how before/after parity is captured + diffed (normalizing ts/temp paths), and whether it lives under `.agent0/tests/` as a cross-tool suite.
- [ ] **`emit_exit`/`resolve_ffmpeg` variants** — `transcribe`'s `emit_exit` (7-line) and `resolve_ffmpeg` (5-line) differ from the others; reconcile to the kernel form or leave transcribe on a compatible variant? (Behavior-parity gate decides.)

## Context / references

- **Graduating meeting:** `.agent0/meetings/capacity-tool-kit-consolidation-2026-06-07T00-28-12Z/meeting.md` — blind openings converged on extract-now/kernel+paid-sub-kit/local-is-template/golden-gate/sync-fix; ledger 6 claims / 0 assertion-only (4 supported anchored, 2 unresolved = gates-to-build); `synthesis: accepted`.
- **Precedent:** `.agent0/tools/lib/managed-block.sh` (the only existing sourced harness lib; synced as a literal at `sync-harness.sh:211`).
- **The 6 capacity tools:** `.agent0/tools/{audio,sound,transcribe,diagram}.sh` (+ `image`/`video` in skill dirs); shared primitive `.agent0/tools/fal-rest.sh`.
- **Sync gap (verified):** `sync-harness.sh:197` (`.agent0/tools|*.sh` maxdepth-1 glob) + `:211` (managed-block literal).
- **Test safety net:** the 6 offline suites under `.agent0/tests/{audio,sound,transcribe,diagram,...}/` — the refactor's protection.
- **Build mode:** founder directive — autonomous `/squad` (Claude ↔ Codex), externally gated on the golden-parity + suites + sync-propagation done-condition.
