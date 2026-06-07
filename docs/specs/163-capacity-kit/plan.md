# 163 — capacity-kit — plan

_Drafted from `spec.md` on 2026-06-06. Update if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Behavior-preserving, test-protected refactor. Build the **golden parity harness FIRST** (capture each tool's stdout/stderr/exit + `--json` + manifest on a fixed fixture set), then extract the kit, then prove parity holds. Order is deliberate: the gate must exist before the change so "zero behavior change" is *verified*, not asserted.

**The kit shape (measured):**
- `.agent0/tools/lib/capacity.sh` — **kernel**, sourced by all 6 tools. Verbatim-identical funcs: `cap_have`, `cap_sha256_str`/`cap_sha256_file`, `cap_emit_exit` (status→exit ok=0/unavail=2/err=3). Parameterized mechanics: `cap_manifest_append <manifest-path> <jsonl-line>` (mkdir + `jq -cn` guard + one-line append; caller builds the fields object), `cap_fail` (status + json/text + a **manifest hook**), `cap_resolve_ffmpeg <env-override-name>`, `cap_redact` (secret state set|unset).
- `.agent0/tools/lib/paid-media.sh` — **paid sub-kit**, sourced by image/video/audio(remote)/sound. `pm_tier_get`/`pm_tier_top` (the YAML block-scan, parameterized), `pm_fal_key_state`, `pm_cost_print`, `pm_confirm_gate <est> <threshold> <confirm>`, `pm_fal_run <model> <body>` (thin `fal-rest.sh` wrapper).
- **Local acquisition = template** (a reference skeleton in `.agent0/context/rules/`), NOT a lib — the ladders differ materially.

**The central design call (`fail`↔`manifest`):** `cap_fail` takes a **manifest-hook** — each tool defines a `_manifest_append()` closure capturing its own fields; `cap_fail status msg` calls the hook then emits + exits. This keeps the manifest *schema* in the tool while the *mechanics* (append discipline, jq guard, exit mapping) live in the kit. The golden gate proves the indirection changed nothing.

**Sync fix:** add `".agent0/tools/lib|*.sh"` to `COPY_CHECK_GLOBS` (future-proof; auto-carries paid-media.sh + any future lib), keep the managed-block literal for safety, and add a harness-sync test asserting `lib/capacity.sh` + `lib/paid-media.sh` appear in a synced consumer.

**Missing-kit guard:** each tool, right after resolving `HERE`, sources the kit with a clear failure: `. "$HERE/lib/capacity.sh" 2>/dev/null || { echo "tool: missing kit library lib/capacity.sh" >&2; exit 70; }` (the managed-block precedent).

Build order: (1) golden harness + capture BEFORE baselines for all 6 → (2) write `lib/capacity.sh` → (3) migrate one tool (diagram, smallest) end-to-end, prove its suite + golden parity → (4) migrate the rest → (5) `lib/paid-media.sh` + migrate image/video/audio/sound paid lanes → (6) sync-glob fix + sync test → (7) full gate: 6 suites + golden parity + `bash -n` + doctor + `/skill validate`.

## Files to touch

**Create:**
- `.agent0/tools/lib/capacity.sh` — the kernel.
- `.agent0/tools/lib/paid-media.sh` — the paid sub-kit.
- `.agent0/tests/capacity-kit/` — golden parity harness (before/after capture + diff, ts/temp normalization) + the sync-propagation test + missing-kit-guard test.
- `.agent0/context/rules/capacity-kit.md` — the kit contract + the local-acquisition reference template + "how to build the 7th tool as config" guide.

**Modify:**
- `.agent0/tools/{audio,sound,diagram,transcribe}.sh` (+ image/video tools in skill dirs) — `source` the kit; delete the now-shared local copies; keep tool-specific logic.
- `.agent0/tools/sync-harness.sh` — add `.agent0/tools/lib|*.sh` to `COPY_CHECK_GLOBS`.
- `CLAUDE.md` + `AGENTS.md` — a `## Capacity kit` managed-index line (it is harness machinery, like managed-block).
- `docs/specs/163-capacity-kit/squad.json` — the fail-closed done-gate.

**Delete:** none (functions move, files stay).

## Alternatives considered

### Documented template instead of a sourced library

The kill-condition. Rejected by the measurement: `have`/`emit_exit`/`sha256_str` ARE byte-identical across 3–4 tools (real verbatim kernel), and the same-shape functions (`fail`/`append_manifest`/`resolve_ffmpeg`/tier-reader) are where the two shipped bugs lived — parameterizing them in one tested place has clear value a copy-paste template cannot give. Template stays the right answer for the *local acquisition ladders* only (policy-heavy, not byte-identical) — adopted there.

### Extract everything into one big kit (incl. local acquisition)

Rejected (meeting). The acquire ladders share only shape, not code; unifying them forces false abstraction and hurts readability. Kernel + paid sub-kit only; local = template.

### Defer to "before the 7th tool"

Rejected. The 6 offline suites exist NOW as the safety net and the duplication is fresh; deferring risks the 7th shipping as another clone first. Extract now so the 7th is born from a proven kit.

### Solo refactor instead of /squad

The founder chose `/squad` (Claude ↔ Codex) — apt here: two runtimes parameterize + adversarially cross-review the `fail`↔manifest interface, with a crisp external done-gate (golden parity + suites + sync test) as the only closer.

## Risks and unknowns

- **Leaky abstraction at `fail`↔manifest** — the central risk; mitigated by the manifest-hook design + the golden gate catching any drift.
- **Sync miss breaks consumer tools** — once tools `source` the kit, a propagation gap is fatal; mitigated by the glob fix + a dedicated sync-propagation test (the spec's load-bearing AC).
- **`transcribe` variants** — its `emit_exit`/`resolve_ffmpeg` differ; the parity gate decides reconcile-to-kernel vs keep-compatible-variant.
- **Golden-gate false confidence** — suites + golden fixtures only cover thought-of cases; mitigated by `bash -n` + doctor + `/skill validate` + per-tool live smoke during migration.
- **image/video tools live in skill dirs, not `.agent0/tools/`** — confirm their paths + that they can source `../../tools/lib/` (or relative); may scope the paid sub-kit migration to the `.agent0/tools/` four first if path resolution is awkward.

## Research / citations

- Measurement (2026-06-06, this session): `have` identical ×4, `emit_exit` identical ×3, `sha256_of_str` ×2; `fail`/`append_manifest`/`resolve_ffmpeg`/tier-reader same-shape-different-content. ~987 lines across the 4 `.agent0/tools/` capacity scripts.
- Sync gap verified: `sync-harness.sh:197` (maxdepth-1 glob) + `:211` (managed-block literal).
- Precedent: `.agent0/tools/lib/managed-block.sh`.
- Graduating meeting: `.agent0/meetings/capacity-tool-kit-consolidation-2026-06-07T00-28-12Z/meeting.md`.
