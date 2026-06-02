# 137 — agent0-status

_Created 2026-06-02._

**Status:** shipped

## Intent

Give Agent0 an on-demand, text-first cockpit over its own live harness state — the transferable kernel of the "Sentinel" host-operations platform (`opus-domini/sentinel`) ported to Agent0's actual surface (specs, handoff, reminders, routines, memory, hooks) instead of tmux/systemd/host metrics. Today that state is only assembled at SessionStart by `.agent0/hooks/startup-brief.sh`, truncated to 6000 bytes / 80 lines and emitted as hook context; mid-session there is no way for a human or agent to ask "where does my work stand?" or "is this harness wired correctly?". This spec adds two sibling shell tools — `.agent0/tools/status.sh` (work state) and `.agent0/tools/doctor.sh` (harness health) — both composing a shared library extracted from the startup brief, plus a **portable** `/status` skill (canonical `.agent0/skills/status/`, dual-symlinked into `.claude/skills/` + `.agents/skills/` per spec 121) so Claude invokes `/status` and Codex invokes `$status`, both falling through to the same neutral tool. The capability is multi-runtime by construction: the tools are pure POSIX-ish shell, the extracted library carries composition only (no runtime-specific emit), and `doctor` inspects both `.claude/settings.json` and `.codex/hooks.json` wiring. Explicitly NOT a browser dashboard, daemon, metrics layer, or new observability store: that literal Sentinel port is the speculative-observability anti-pattern Agent0 already rejects (see [[feedback_speculative_observability]], `.agent0/context/rules` rule-of-three). The value is making *existing* state visible, checkable, and actionable from one command — runtime-neutral, zero new persistent state.

## Acceptance criteria

- [x] **Scenario: `status` renders full work state on demand**
  - **Given** a repo with a populated `.agent0/HANDOFF.md`, pending reminders, and a pending routine
  - **When** a human or agent runs `bash .agent0/tools/status.sh`
  - **Then** it prints the handoff summary (Current State / Active Work / Next Actions), due/unscheduled reminders, pending routines, memory-decay readout, current git dirty state, and a "suggested next commands" block — **untruncated** (no 6000-byte / 80-line cap)

- [x] **Scenario: `status` reuses the brief composition, not a fork of it**
  - **Given** the startup-brief composition logic has been extracted into a shared library (e.g. `.agent0/hooks/_brief-compose.sh`)
  - **When** `status.sh` and `startup-brief.sh` both run
  - **Then** both source the same library functions for handoff/reminders/routines/decay; the hook applies its byte/line truncation, `status.sh` does not; changing the handoff-summary logic in one place updates both

- [x] **Scenario: the extracted library is runtime-emit-neutral**
  - **Given** the shared composition library
  - **When** it is sourced by `status.sh`, `doctor.sh`, or `startup-brief.sh`
  - **Then** the library contains only composition functions (handoff / reminders / routines / decay summarizers) and NO runtime-specific emit — `startup-brief.sh` keeps its own `emit_context` (Claude hook-JSON vs Codex plain-text) and truncation wrapper; the tools print plain text directly

- [x] **Scenario: capability is discoverable from both runtimes**
  - **Given** the tools and skill are shipped
  - **When** a `status` / `doctor` row is added to `.agent0/context/rules/runtime-capabilities.md` and a managed-block index entry is added to both `CLAUDE.md` and `AGENTS.md`
  - **Then** Claude discovers `/status` + the tools and Codex discovers `$status` + the tools, mirroring the `vuln-audit` discovery model

- [x] **Scenario: `doctor` reports harness health with a tri-state verdict**
  - **Given** an Agent0 repo
  - **When** a human or agent runs `bash .agent0/tools/doctor.sh`
  - **Then** it checks required harness files exist + are executable, hook wiring is present (`.claude/settings.json` / `.codex/hooks.json` reference expected hooks), `core.hooksPath` activation state, and required/optional binaries (`jq`, `python3`, optional `gitleaks`, optional `osv-scanner`), and reports each as `ok` / `advisory` / `broken` with a final rollup status

- [x] **Scenario: `doctor` exit code reflects severity**
  - **Given** a harness with at least one `broken` check
  - **When** `doctor.sh` runs (default, no flags)
  - **Then** it exits non-zero on any `broken` check and zero when all checks are `ok` or `advisory` (advisories never fail the exit code)

- [x] **Scenario: `/status` is a thin, portable skill**
  - **Given** the portable skill at `.agent0/skills/status/SKILL.md` with discovery symlinks `.claude/skills/status` + `.agents/skills/status` (no `agents/openai.yaml` — read-only and safe to auto-fire, mirroring `vuln-audit`)
  - **When** the user invokes `/status` (Claude) or `$status` (Codex)
  - **Then** the skill invokes `.agent0/tools/status.sh` and relays its output, carrying no independent composition logic of its own

- [x] **Scenario: tools degrade cleanly on a partial harness**
  - **Given** a repo missing `.agent0/HANDOFF.md` or with no reminders/routines
  - **When** `status.sh` runs
  - **Then** it prints a clear "(missing)" / "(none)" marker for each absent surface and still exits zero — never errors out

- [x] Both tools are runtime-neutral pure shell, invocable by Claude Code, Codex CLI, or a human via `! bash .agent0/tools/<tool>.sh`
- [x] `status.sh` and `doctor.sh` are two separate tools sharing the library — NOT one tool behind a `--mode` flag
- [x] Neither tool writes new persistent state, starts a daemon, opens a port, or emits a browser/HTML surface

## Non-goals

- Any browser UI, WebSocket stream, daemon, or long-running process (the literal Sentinel port — explicit anti-pattern per [[feedback_speculative_observability]])
- Host-level metrics (CPU / memory / disk), alert timelines, tmux/service control, or recovery snapshots — Sentinel's host-ops domains that do not transfer to a repo harness
- A new persistent audit log, JSONL event stream, or history store (`status`/`doctor` are stateless point-in-time reads; git history is the existing audit trail)
- A generic runbook execution engine or per-step job tracking — deferred until multiple routines demonstrably need it (rule-of-three)
- Replacing or auto-running the SessionStart hook — `startup-brief.sh` keeps its boot role; `status` is the on-demand sibling, not a replacement
- Auto-remediation in `doctor` — it reports and proposes, never fixes (mirrors `vuln-audit` discipline)

## Open questions

- [x] Next-commands block → **heuristic/derived**: handoff Next Actions (presence) + pending routines (`/routine run <slug>`) + due-reminder count (reusing `summarize_reminders`' due filter) + working-tree-dirty hint, else `(nothing queued)`. No static hint list.
- [x] `doctor --json` → **deferred** (not in v1). No consumer needs it; rule-of-three. Text + exit code only.
- [x] Shared library placement → **`.agent0/hooks/_brief-compose.sh`** (next to `startup-brief.sh`, its origin; mirrors `_memory-hook-lib.sh`). Tools locate it relative to their own path, not the inspected project.
- [x] `doctor` skill → **tool-only**, no skill. Only `status` earns the everyday skill surface.

## Context / references

- `opus-domini/sentinel` — source inspiration; "Your terminal watchtower", single-binary host-ops platform. The transferable kernel is observe/control/procedure/recover unified in one low-friction local surface; only observe (partial) + a `doctor`-style health check transfer to Agent0.
- `.agent0/hooks/startup-brief.sh` — the existing SessionStart composition this spec extracts a library from and mirrors on-demand.
- Sibling readouts reused: `.agent0/hooks/reminders-readout.sh`, `routines-readout.sh`, `memory-decay-readout.sh`.
- Codex cross-model analysis of this idea: `.agent0/.runtime-state/codex-exec/20260602T144057Z-sentinel-insights/last-message.md` (read-only run, 2026-06-02) — independently recommended exactly this `status`/`doctor` text-first layer over a browser cockpit.
- [[feedback_speculative_observability]] — the standing rule-of-three guard this spec is deliberately scoped against; `vuln-audit` (`.agent0/context/rules/vuln-audit.md`) is the precedent for "report + propose, never gate, never store".
