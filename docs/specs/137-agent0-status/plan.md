# 137 — agent0-status — plan

_Drafted from `spec.md` on 2026-06-02. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build in three layers, bottom-up, each independently testable. **(1) Extract** the composition logic currently inlined in `.agent0/hooks/startup-brief.sh` into a new sourced library `.agent0/hooks/_brief-compose.sh` (mirroring the existing `_memory-hook-lib.sh` precedent) — the `summarize_handoff*`, `summarize_reminders`, `summarize_routines`, `summarize_memory_decay`, `githooks_advisory`, and the `section_body`/`helper_output` helpers move into the lib; the runtime-specific `emit_context`, truncation (`trim_lines`/`trim_bytes`), and `init_session_state` stay in `startup-brief.sh`. The lib must source `_memory-hook-lib.sh` itself (it needs `memory_project_dir`/`memory_runtime`). `startup-brief.sh` is refactored to source the lib and keep byte/line behaviour byte-for-byte identical (regression-guarded). **(2) Build** `.agent0/tools/status.sh` and `.agent0/tools/doctor.sh` as pure-shell consumers: `status.sh` sources the lib, prints the full untruncated composition plus a git-dirty block and a heuristic "next commands" block; `doctor.sh` runs independent health checks with a tri-state rollup and severity-based exit code. **(3) Surface + register**: a portable `/status` skill (canonical `.agent0/skills/status/SKILL.md` + dual symlinks, no `openai.yaml`), a `host status / doctor` row in `runtime-capabilities.md`, and managed-block index entries in `CLAUDE.md` + `AGENTS.md`.

Order matters: layer 1 is the riskiest (touches a live SessionStart hook), so it ships first with a characterization test that pins the current brief output before refactor and re-asserts it after. Layers 2–3 are additive and cannot regress the hook.

The three open questions resolve here:
- **Next-commands block** → heuristic, derived: surface handoff "Next Actions" verbatim (top N) + any pending routines (`/routine run <slug>`) + due reminders count (`/remind list`). No static hint list — it reflects real state or prints "(nothing queued)".
- **`doctor --json`** → deferred (not in v1). No agent consumer needs it yet; rule-of-three. `doctor` is human/agent-readable text + exit code only.
- **Lib placement** → `.agent0/hooks/` (next to `startup-brief.sh`, its origin and primary consumer; mirrors `_memory-hook-lib.sh` living in `hooks/`). The tools source it by absolute path resolved from repo root.
- **`doctor` skill?** → tool-only (no skill). `doctor` is occasional/diagnostic; only `status` earns the everyday skill surface.

## Files to touch

**Create:**
- `.agent0/hooks/_brief-compose.sh` — shared composition library (handoff/reminders/routines/decay/githooks summarizers); emit-neutral, sources `_memory-hook-lib.sh`.
- `.agent0/tools/status.sh` — on-demand full work-state cockpit; sources the lib + adds git-dirty + next-commands blocks; always exit 0.
- `.agent0/tools/doctor.sh` — harness health check; tri-state per check (`ok`/`advisory`/`broken`), rollup, non-zero exit on any `broken`.
- `.agent0/skills/status/SKILL.md` — thin portable skill; invokes `status.sh`, relays output, zero composition logic.
- `.claude/skills/status` — symlink → `../../.agent0/skills/status` (Claude discovery).
- `.agents/skills/status` — symlink → `../../.agent0/skills/status` (Codex discovery).
- `.agent0/context/rules/agent0-status.md` — capability rule (what status/doctor are, when to run, multi-runtime invocation, anti-drift scope).
- `.agent0/tests/agent0-status/` — test dir: characterization test for the brief refactor + behavioural tests for status/doctor (partial-harness degradation, doctor exit codes, lib emit-neutrality).

**Modify:**
- `.agent0/hooks/startup-brief.sh` — source `_brief-compose.sh`; delete the now-extracted function bodies; keep `emit_context`/`trim_*`/`init_session_state`. Output must stay byte-identical.
- `.agent0/context/rules/runtime-capabilities.md` — add a `host status / doctor` capability row (Claude `native` / Codex `native-opt-in`, owner files, notes).
- `CLAUDE.md` — managed-block index entry (`## Status & doctor`).
- `AGENTS.md` — mirror the managed-block index entry (baseline-tracked).
- `.agent0/harness-sync-baseline.json` — register the new tracked files so sync reconciliation knows about them (verify mechanism at task time).

**Delete:**
- None.

## Alternatives considered

### `status.sh` independent of the brief (no shared lib)
Rejected — the user explicitly chose the shared-lib path, and it is correct: duplicating handoff/reminders/routines composition guarantees drift the first time the handoff format changes. The DRY refactor costs one characterization test up front and removes a whole class of future divergence. The only real cost (touching a live hook) is contained by the pin-output test.

### One tool with a `--mode=status|doctor` flag
Rejected — explicit spec guard-rail. "Show me my work state" and "is the harness wired right" are different mental actions with different exit-code semantics (status always 0; doctor fails on broken). A mode flag couples them and muddies the exit contract. Two small tools sharing a lib is cleaner.

### `doctor --json` in v1
Rejected for v1 — no consumer needs machine-readable health yet. Adding it now is speculative surface (rule-of-three). Trivial to add later behind the same checks if an agent or CI consumer materializes.

### Browser/daemon cockpit (literal Sentinel port)
Rejected — this is the speculative-observability anti-pattern Agent0's rules reject outright. Captured as the spine of the spec's Non-goals, not re-litigated here.

## Risks and unknowns

- **Brief regression** — extracting functions from a live SessionStart hook risks subtly changing boot output (whitespace, section order, truncation boundaries). Mitigation: capture `startup-brief.sh` output on a fixture repo BEFORE refactor, diff AFTER — must be byte-identical.
- **Sourcing path resolution** — tools run from arbitrary CWD (human `!`, Codex, Claude) must locate the lib reliably. Mitigation: resolve repo root via `git rev-parse --show-toplevel` (already the `_memory-hook-lib.sh` pattern), fall back to `BASH_SOURCE` dirname.
- **`helper_output` env contract** — the brief calls readouts with `env -u CLAUDE_PROJECT_DIR AGENT0_PROJECT_DIR=...`; the lib must preserve that exact invocation so reminders/routines resolve the right project dir under all three runtimes.
- **Symlink-hostile checkouts** — discovery symlinks can break on some filesystems; `sync-harness` materializes copies as the known fallback (spec 121). Note in the skill, don't solve here.
- **doctor false "broken"** — over-strict checks (e.g. flagging optional `gitleaks`/`osv-scanner` absence as broken) would cry wolf. Mitigation: required-vs-optional binary tiers — optional absence is `advisory` (exit 0), only structural breakage (missing core file, unwired required hook) is `broken`.

## Research / citations

- `.agent0/hooks/startup-brief.sh` — read in full; source of the composition being extracted (handoff/reminders/routines/decay/githooks functions + emit/truncation boundary).
- `.agent0/hooks/_memory-hook-lib.sh` — precedent for a sourced shared lib under `.agent0/hooks/` (repo-root resolution, function-only library).
- `.agent0/skills/vuln-audit/` + `.claude/skills/vuln-audit` / `.agents/skills/vuln-audit` symlinks — precedent for a read-only portable skill with NO `openai.yaml`.
- `.agent0/skills/image/agents/openai.yaml` — shape reference for when `openai.yaml` IS needed (paid/side-effecting); confirms `/status` does NOT need one.
- `.agent0/context/rules/runtime-capabilities.md` rows for `vuln-audit`, `harness sync`, `skills (delivery surface)` — the discovery/registration model this spec mirrors.
- Codex cross-model analysis: `.agent0/.runtime-state/codex-exec/20260602T144057Z-sentinel-insights/last-message.md` — independent recommendation of the `status`/`doctor` text-first layer.
